import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../core/storage.dart';
import '../data/seed_data.dart';
import '../models/band_member.dart';
import '../models/band_member_query.dart';
import '../models/page_result.dart';
import 'band_member_repository.dart';

class InMemoryBandMemberRepository implements BandMemberRepository {
  InMemoryBandMemberRepository([SharedPreferences? prefs]) : _prefs = prefs {
    if (prefs == null) {
      _items = [...seedMembers];
      return;
    }
    final result = VersionedStore.read(
      prefs,
      'members',
      parse: (json) => BandMember.fromJson(json).toJson(),
      migrate: (json) => BandMember.fromJson(json).toJson(),
      seed: seedMembers.map((member) => member.toJson()).toList(),
    );
    _items = result.items.map(BandMember.fromJson).toList();
  }

  final SharedPreferences? _prefs;
  late final List<BandMember> _items;
  List<BandMember> get items => List.unmodifiable(_items);
  Future<void> Function(List<int> ids, bool hard)? deletionGuard;
  Future<void> Function(BandMember item)? saveGuard;
  Future<void> Function()? afterChange;

  Future<void> persistOnly() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await VersionedStore.write(
        prefs, 'members', _items.map((item) => item.toJson()).toList());
  }

  Future<void> persist() async {
    await persistOnly();
    await afterChange?.call();
  }

  void replace(BandMember item) {
    final index = _items.indexWhere((row) => row.id == item.id);
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index] = item;
    }
  }

  int _nextId() =>
      _items.fold<int>(0, (maxId, item) => item.id > maxId ? item.id : maxId) +
      1;
  @override
  Future<PageResult<BandMember>> find(BandMemberQuery q, {CancelToken? cancelToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (q.yearsFrom != null && q.yearsTo != null && q.yearsFrom! > q.yearsTo!) {
      throw ArgumentError('Стаж «от» больше стажа «до»');
    }
    var rows = _items.where((x) => q.includeDeleted || !x.isDeleted).toList();
    final n = q.search.trim().toLowerCase();
    if (n.isNotEmpty) {
      rows = rows
          .where((x) =>
              x.lastName.toLowerCase().contains(n) ||
              x.firstName.toLowerCase().contains(n) ||
              x.role.toLowerCase().contains(n))
          .toList();
    }
    if (q.role != null) {
      rows = rows.where((x) => x.role == q.role).toList();
    }
    if (q.yearsFrom != null) {
      rows = rows.where((x) => x.yearsInBand >= q.yearsFrom!).toList();
    }
    if (q.yearsTo != null) {
      rows = rows.where((x) => x.yearsInBand <= q.yearsTo!).toList();
    }
    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'role' => a.role.compareTo(b.role),
        'yearsInBand' => a.yearsInBand.compareTo(b.yearsInBand),
        'fee' => a.fee.compareTo(b.fee),
        _ => a.lastName.compareTo(b.lastName)
      };
      return q.sortAscending ? r : -r;
    });
    final total = rows.length,
        from = (q.page - 1) * q.size,
        to = (from + q.size) > total ? total : from + q.size;
    return PageResult(
        items: from >= total ? <BandMember>[] : rows.sublist(from, to),
        page: q.page,
        size: q.size,
        total: total);
  }

  @override
  Future<BandMember?> findById(int id) async {
    for (final x in _items) {
      if (x.id == id) return x;
    }
    return null;
  }

  @override
  Future<List<BandMember>> all({bool includeDeleted = false}) async => _items
      .where((item) => includeDeleted || !item.isDeleted)
      .toList();

  @override
  Future<BandMember> save(BandMember member) async {
    await saveGuard?.call(member);
    final email = member.email.trim().toLowerCase();
    final duplicate = _items.any((item) =>
        item.id != member.id &&
        !item.isDeleted &&
        item.email.trim().toLowerCase() == email);
    if (duplicate) {
      throw const FieldValidationException(
          'email', 'Участник с такой почтой уже есть');
    }
    final mask = member.maskCode.trim().toUpperCase();
    final maskTaken = _items.any((item) =>
        item.id != member.id &&
        !item.isDeleted &&
        item.maskCode.trim().toUpperCase() == mask);
    if (maskTaken) {
      throw const FieldValidationException(
          'maskCode', 'Такой код маски уже назначен');
    }
    final saved = member.id == 0
        ? BandMember(
            id: _nextId(),
            firstName: member.firstName.trim(),
            lastName: member.lastName.trim(),
            role: member.role.trim(),
            yearsInBand: member.yearsInBand,
            fee: member.fee,
            email: member.email.trim(),
            bio: member.bio.trim(),
            photoUrl: member.photoUrl.trim(),
            joinedYear: member.joinedYear,
            stageName: member.stageName.trim(),
            maskCode: mask,
            appointedOn: member.appointedOn.trim(),
            albumIds: member.albumIds,
            concertIds: member.concertIds,
          )
        : member.copyWith(
            firstName: member.firstName.trim(),
            lastName: member.lastName.trim(),
            role: member.role.trim(),
            email: member.email.trim(),
            bio: member.bio.trim(),
            photoUrl: member.photoUrl.trim(),
            stageName: member.stageName.trim(),
            maskCode: mask,
            appointedOn: member.appointedOn.trim(),
          );
    replace(saved);
    await persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    await deletionGuard?.call([id], false);
    final i = _items.indexWhere((x) => x.id == id);
    if (i < 0) throw StateError('Участник не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await deletionGuard?.call([id], true);
    _items.removeWhere((x) => x.id == id);
    await persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((x) => x.id == id);
    if (i < 0) throw StateError('Участник не найден');
    await save(_items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    await deletionGuard?.call(ids, false);
    var c = 0;
    for (final id in ids) {
      final i = _items.indexWhere((x) => x.id == id && !x.isDeleted);
      if (i >= 0) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        c++;
      }
    }
    await persist();
    return c;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    await deletionGuard?.call(ids, true);
    final before = _items.length;
    _items.removeWhere((x) => ids.contains(x.id));
    await persist();
    return before - _items.length;
  }
}
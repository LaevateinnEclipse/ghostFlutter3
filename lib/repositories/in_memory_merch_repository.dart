import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../core/storage.dart';
import '../data/seed_data.dart';
import '../models/merch_item.dart';
import '../models/merch_query.dart';
import '../models/page_result.dart';
import 'merch_repository.dart';

class InMemoryMerchRepository implements MerchRepository {
  InMemoryMerchRepository([SharedPreferences? prefs]) : _prefs = prefs {
    if (prefs == null) {
      _items = [...seedMerch];
      return;
    }
    final result = VersionedStore.read(
      prefs,
      'merch',
      parse: (json) => MerchItem.fromJson(json).toJson(),
      migrate: (json) => MerchItem.fromJson(json).toJson(),
      seed: seedMerch.map((item) => item.toJson()).toList(),
    );
    _items = result.items.map(MerchItem.fromJson).toList();
  }

  final SharedPreferences? _prefs;
  late final List<MerchItem> _items;
  List<MerchItem> get items => List.unmodifiable(_items);
  Future<void> Function(List<int> ids, bool hard)? deletionGuard;
  Future<void> Function(MerchItem item)? saveGuard;
  Future<void> Function()? afterChange;

  Future<void> persistOnly() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await VersionedStore.write(
        prefs, 'merch', _items.map((item) => item.toJson()).toList());
  }

  Future<void> persist() async {
    await persistOnly();
    await afterChange?.call();
  }

  void replace(MerchItem item) {
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
  Future<PageResult<MerchItem>> find(MerchQuery q, {CancelToken? cancelToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (q.stockFrom != null && q.stockTo != null && q.stockFrom! > q.stockTo!) {
      throw ArgumentError('Остаток «от» больше остатка «до»');
    }
    if (q.priceFrom != null && q.priceTo != null && q.priceFrom! > q.priceTo!) {
      throw ArgumentError('Цена «от» больше цены «до»');
    }
    var rows = _items.where((x) => q.includeDeleted || !x.isDeleted).toList();
    final n = q.search.trim().toLowerCase();
    if (n.isNotEmpty) {
      rows = rows
          .where((x) =>
              x.name.toLowerCase().contains(n) ||
              x.sku.toLowerCase().contains(n))
          .toList();
    }
    if (q.category != null) {
      rows = rows.where((x) => x.category == q.category).toList();
    }
    if (q.stockFrom != null) {
      rows = rows.where((x) => x.stock >= q.stockFrom!).toList();
    }
    if (q.stockTo != null) {
      rows = rows.where((x) => x.stock <= q.stockTo!).toList();
    }
    if (q.priceFrom != null) {
      rows = rows.where((x) => x.price >= q.priceFrom!).toList();
    }
    if (q.priceTo != null) {
      rows = rows.where((x) => x.price <= q.priceTo!).toList();
    }
    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'stock' => a.stock.compareTo(b.stock),
        'price' => a.price.compareTo(b.price),
        'category' => a.category.compareTo(b.category),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase())
      };
      return q.sortAscending ? r : -r;
    });
    final total = rows.length,
        from = (q.page - 1) * q.size,
        to = (from + q.size) > total ? total : from + q.size;
    return PageResult(
        items: from >= total ? <MerchItem>[] : rows.sublist(from, to),
        page: q.page,
        size: q.size,
        total: total);
  }

  @override
  Future<MerchItem?> findById(int id) async =>
      _items.where((x) => x.id == id).firstOrNull;
  @override
  Future<List<MerchItem>> all({bool includeDeleted = false}) async =>
      _items.where((item) => includeDeleted || !item.isDeleted).toList();

  @override
  Future<MerchItem> save(MerchItem item) async {
    await saveGuard?.call(item);
    final sku = item.sku.trim().toUpperCase();
    final duplicate = _items.any((row) =>
        row.id != item.id && !row.isDeleted && row.sku.toUpperCase() == sku);
    if (duplicate) {
      throw const FieldValidationException(
          'sku', 'Товар с таким артикулом уже есть');
    }
    final saved = item.id == 0
        ? MerchItem(
            id: _nextId(),
            name: item.name.trim(),
            sku: sku,
            category: item.category.trim(),
            stock: item.stock,
            price: item.price,
            sizeIds: item.sizeIds,
            albumId: item.albumId,
          )
        : item.copyWith(
            name: item.name.trim(),
            sku: sku,
            category: item.category.trim(),
          );
    replace(saved);
    await persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    await deletionGuard?.call([id], false);
    final i = _items.indexWhere((x) => x.id == id);
    if (i < 0) throw StateError('Товар не найден');
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
    if (i < 0) throw StateError('Товар не найден');
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

  @override
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false}) async =>
      _items
          .where((item) =>
              item.albumId == albumId && (includeDeleted || !item.isDeleted))
          .length;
}
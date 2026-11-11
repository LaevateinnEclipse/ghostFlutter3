import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../data/seed_data.dart';
import '../models/concert.dart';
import '../models/concert_query.dart';
import '../models/page_result.dart';
import 'concert_repository.dart';
import 'in_memory_repository.dart';

class InMemoryConcertRepository extends InMemoryRepository<Concert>
    implements ConcertRepository {
  InMemoryConcertRepository(SharedPreferences prefs)
      : super(
          prefs: prefs,
          name: 'concerts',
          parse: Concert.fromJson,
          encode: (concert) => concert.toJson(),
          seed: seedConcerts.map((concert) => concert.toJson()).toList(),
          migrate: _migrate,
        );

  static Map<String, dynamic> _migrate(Map<String, dynamic> json) =>
      Concert.fromJson(json).toJson();

  @override
  int rowId(Concert item) => item.id;
  @override
  bool rowDeleted(Concert item) => item.isDeleted;
  @override
  Concert rowWithDeletedAt(Concert item, DateTime? deletedAt) =>
      deletedAt == null
          ? item.copyWith(clearDeletedAt: true)
          : item.copyWith(deletedAt: deletedAt);

  @override
  Future<PageResult<Concert>> find(ConcertQuery query) async => page(
        pageNumber: query.page,
        pageSize: query.size,
        filter: (rows) {
          var result = rows.where((x) => query.includeDeleted || !x.isDeleted);
          final search = query.search.trim().toLowerCase();
          if (search.isNotEmpty) {
            result = result.where((x) =>
                x.city.toLowerCase().contains(search) ||
                x.venue.toLowerCase().contains(search) ||
                x.ticketCode.toLowerCase().contains(search));
          }
          if (query.status != null) {
            result = result.where((x) => x.status == query.status);
          }
          if (query.city != null) {
            result = result.where((x) => x.city == query.city);
          }
          final list = result.toList();
          list.sort((a, b) {
            final compared = switch (query.sortField) {
              'city' => a.city.compareTo(b.city),
              'ticketPrice' => a.ticketPrice.compareTo(b.ticketPrice),
              'status' => a.status.compareTo(b.status),
              _ => a.date.compareTo(b.date),
            };
            return query.sortAscending ? compared : -compared;
          });
          return list;
        },
      );

  @override
  Future<Concert> save(Concert concert) async {
    await saveGuard?.call(concert);
    final code = concert.ticketCode.trim().toUpperCase();
    final duplicate = items.any((x) =>
        x.id != concert.id &&
        !x.isDeleted &&
        x.ticketCode.toUpperCase() == code);
    if (duplicate) {
      throw const FieldValidationException(
          'ticketCode', 'Билет с таким кодом уже существует');
    }
    if (!Concert.statuses.contains(concert.status)) {
      throw const FieldValidationException(
          'status', 'Статус: plan, done или cancelled');
    }
    final saved = concert.id == 0
        ? Concert(
            id: nextId(),
            city: concert.city.trim(),
            venue: concert.venue.trim(),
            date: concert.date,
            ticketPrice: concert.ticketPrice,
            status: concert.status,
            albumId: concert.albumId,
            memberIds: concert.memberIds,
            ticketCode: code,
            contactEmail: concert.contactEmail.trim(),
          )
        : concert.copyWith(
            city: concert.city.trim(),
            venue: concert.venue.trim(),
            ticketCode: code,
            contactEmail: concert.contactEmail.trim(),
          );
    put(saved);
    await persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    await checkDeletion([id]);
    markDeleted(id);
    await persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await checkDeletion([id], hard: true);
    remove(id);
    await persist();
  }

  @override
  Future<void> restore(int id) async {
    final item = await findById(id);
    if (item == null) throw StateError('Концерт #$id не найден');
    await save(rowWithDeletedAt(item, null));
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    await checkDeletion(ids);
    var count = 0;
    for (final id in ids) {
      if (!items.any((x) => x.id == id && !x.isDeleted)) continue;
      markDeleted(id);
      count++;
    }
    await persist();
    return count;
  }

  @override
  Future<int> hardDeleteMany(List<int> ids) async {
    await checkDeletion(ids, hard: true);
    final before = items.length;
    for (final id in ids) {
      remove(id);
    }
    await persist();
    return before - items.length;
  }

  @override
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false}) async =>
      items
          .where((concert) =>
              concert.albumId == albumId &&
              (includeDeleted || !concert.isDeleted))
          .length;

  @override
  Future<int> countForMember(int memberId,
          {bool includeDeleted = false}) async =>
      items
          .where((concert) =>
              concert.memberIds.contains(memberId) &&
              (includeDeleted || !concert.isDeleted))
          .length;
}

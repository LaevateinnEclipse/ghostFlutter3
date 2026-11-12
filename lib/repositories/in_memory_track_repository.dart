import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/track.dart';
import '../models/track_query.dart';
import 'in_memory_repository.dart';
import 'track_repository.dart';

class InMemoryTrackRepository extends InMemoryRepository<Track>
    implements TrackRepository {
  InMemoryTrackRepository(SharedPreferences prefs)
      : super(
          prefs: prefs,
          name: 'tracks',
          parse: Track.fromJson,
          encode: (track) => track.toJson(),
          seed: seedTracks.map((track) => track.toJson()).toList(),
          migrate: _migrate,
        );

  static Map<String, dynamic> _migrate(Map<String, dynamic> json) =>
      Track.fromJson(json).toJson();

  @override
  int rowId(Track item) => item.id;
  @override
  bool rowDeleted(Track item) => item.isDeleted;
  @override
  Track rowWithDeletedAt(Track item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  Future<PageResult<Track>> find(TrackQuery query, {CancelToken? cancelToken}) async => page(
        pageNumber: query.page,
        pageSize: query.size,
        filter: (rows) {
          var result = rows.where((x) => query.includeDeleted || !x.isDeleted);
          final search = query.search.trim().toLowerCase();
          if (search.isNotEmpty) {
            result = result.where((x) =>
                x.title.toLowerCase().contains(search) ||
                x.genre.toLowerCase().contains(search));
          }
          if (query.albumId != null) {
            result = result.where((x) => x.albumId == query.albumId);
          }
          if (query.genre != null) {
            result = result.where((x) => x.genre == query.genre);
          }
          final list = result.toList();
          list.sort((a, b) {
            final compared = switch (query.sortField) {
              'trackNumber' => a.trackNumber.compareTo(b.trackNumber),
              'durationSeconds' => a.durationSeconds.compareTo(b.durationSeconds),
              'genre' => a.genre.compareTo(b.genre),
              _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            };
            return query.sortAscending ? compared : -compared;
          });
          return list;
        },
      );

  @override
  Future<Track> save(Track track) async {
    await saveGuard?.call(track);
    final duplicate = items.any((x) =>
        x.id != track.id &&
        !x.isDeleted &&
        x.albumId == track.albumId &&
        x.trackNumber == track.trackNumber);
    if (duplicate) {
      throw const FieldValidationException('trackNumber',
          'В этом альбоме уже есть трек с таким номером');
    }
    final saved = track.id == 0
        ? Track(
            id: nextId(),
            title: track.title.trim(),
            trackNumber: track.trackNumber,
            durationSeconds: track.durationSeconds,
            genre: track.genre.trim(),
            albumId: track.albumId,
          )
        : track.copyWith(title: track.title.trim(), genre: track.genre.trim());
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
    if (item == null) throw StateError('Трек #$id не найден');
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
          .where((track) =>
              track.albumId == albumId && (includeDeleted || !track.isDeleted))
          .length;
}

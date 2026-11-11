import 'package:shared_preferences/shared_preferences.dart';
import '../core/errors.dart';
import '../data/seed_data.dart';
import '../models/album.dart';
import '../models/album_query.dart';
import '../models/page_result.dart';
import 'album_repository.dart';
import 'in_memory_repository.dart';

class InMemoryAlbumRepository extends InMemoryRepository<Album>
    implements AlbumRepository {
  InMemoryAlbumRepository(SharedPreferences prefs)
      : super(
          prefs: prefs,
          name: 'albums',
          parse: Album.fromJson,
          encode: (album) => album.toJson(),
          seed: seedAlbums.map((album) => album.toJson()).toList(),
          migrate: _migrate,
        );

  static Map<String, dynamic> _migrate(Map<String, dynamic> json) =>
      Album.fromJson(json).toJson();

  @override
  int rowId(Album item) => item.id;
  @override
  bool rowDeleted(Album item) => item.isDeleted;
  @override
  Album rowWithDeletedAt(Album item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  Future<PageResult<Album>> find(AlbumQuery query) async {
    if (query.yearFrom != null &&
        query.yearTo != null &&
        query.yearFrom! > query.yearTo!) {
      throw ArgumentError('Год «от» больше года «до»');
    }
    return page(
      pageNumber: query.page,
      pageSize: query.size,
      filter: (rows) {
        var result = rows.where((x) => query.includeDeleted || !x.isDeleted);
        final search = query.search.trim().toLowerCase();
        if (search.isNotEmpty) {
          result = result.where((x) =>
              x.title.toLowerCase().contains(search) ||
              x.catalogCode.toLowerCase().contains(search) ||
              x.label.toLowerCase().contains(search));
        }
        if (query.albumType != null) {
          result = result.where((x) => x.albumType == query.albumType);
        }
        if (query.yearFrom != null) {
          result = result.where((x) => x.year >= query.yearFrom!);
        }
        if (query.yearTo != null) {
          result = result.where((x) => x.year <= query.yearTo!);
        }
        final list = result.toList();
        list.sort((a, b) {
          final compared = switch (query.sortField) {
            'year' => a.year.compareTo(b.year),
            'label' => a.label.compareTo(b.label),
            'albumType' => a.albumType.compareTo(b.albumType),
            _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          };
          return query.sortAscending ? compared : -compared;
        });
        return list;
      },
    );
  }

  @override
  Future<Album> save(Album album) async {
    await saveGuard?.call(album);
    final code = album.catalogCode.trim().toUpperCase();
    final duplicate = items.any((x) =>
        x.id != album.id && x.catalogCode.toUpperCase() == code && !x.isDeleted);
    if (duplicate) {
      throw const FieldValidationException(
          'catalogCode', 'Альбом с таким каталожным номером уже есть');
    }
    if (!Album.types.contains(album.albumType)) {
      throw const FieldValidationException(
          'albumType', 'Выберите тип: studio, live, EP или single');
    }
    final saved = album.id == 0
        ? Album(
            id: nextId(),
            title: album.title.trim(),
            catalogCode: code,
            albumType: album.albumType,
            year: album.year,
            label: album.label.trim(),
            coverUrl: album.coverUrl.trim(),
            memberIds: album.memberIds,
            trackIds: album.trackIds,
            concertIds: album.concertIds,
          )
        : album.copyWith(title: album.title.trim(), catalogCode: code, label: album.label.trim(), coverUrl: album.coverUrl.trim());
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
    if (item == null) throw StateError('Альбом #$id не найден');
    await save(rowWithDeletedAt(item, null));
  }

  @override
  Future<int> softDeleteMany(List<int> ids) async {
    await checkDeletion(ids);
    var count = 0;
    for (final id in ids) {
      final index = items.indexWhere((x) => x.id == id && !x.isDeleted);
      if (index < 0) continue;
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
}

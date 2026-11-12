import '../models/album.dart';
import '../models/album_query.dart';
import 'album_repository.dart';
import 'api_repository.dart';

/// [AlbumRepository] поверх REST API. Интерфейс тот же, что у памяти.
class ApiAlbumRepository extends ApiRepository<Album, AlbumQuery>
    implements AlbumRepository {
  ApiAlbumRepository(super.dio);

  @override
  String get collectionPath => '/albums';

  @override
  int get defaultSize => 10;

  @override
  Album fromJson(Map<String, dynamic> json) => Album.fromJson(json);

  @override
  Map<String, dynamic> toRequestBody(Album album) => {
        'title': album.title.trim(),
        'catalogCode': album.catalogCode.trim(),
        'albumType': album.albumType,
        'year': album.year,
        'label': album.label.trim(),
        'coverUrl': album.coverUrl.trim(),
      };

  @override
  Map<String, dynamic> toParameters(AlbumQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.albumType != null) 'albumType': query.albumType,
        if (query.yearFrom != null) 'yearFrom': query.yearFrom,
        if (query.yearTo != null) 'yearTo': query.yearTo,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': 'true',
      };

  @override
  AlbumQuery allQuery({bool includeDeleted = false}) => AlbumQuery(
        size: 100,
        includeDeleted: includeDeleted,
      );

  @override
  Future<Album> save(Album album) =>
      album.id == 0 ? create(album) : update(album.id, album);

  @override
  Future<void> restore(int id) async {
    await restoreRecord(id);
  }
}

import '../models/track.dart';
import '../models/track_query.dart';
import 'api_repository.dart';
import 'track_repository.dart';

class ApiTrackRepository extends ApiRepository<Track, TrackQuery>
    implements TrackRepository {
  ApiTrackRepository(super.dio);

  @override
  String get collectionPath => '/tracks';

  @override
  int get defaultSize => 10;

  @override
  Track fromJson(Map<String, dynamic> json) => Track.fromJson(json);

  @override
  Map<String, dynamic> toRequestBody(Track track) => {
        'title': track.title.trim(),
        'trackNumber': track.trackNumber,
        'durationSeconds': track.durationSeconds,
        'genre': track.genre.trim(),
        'albumId': track.albumId,
      };

  @override
  Map<String, dynamic> toParameters(TrackQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.albumId != null) 'albumId': query.albumId,
        if (query.genre != null) 'genre': query.genre,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': 'true',
      };

  @override
  TrackQuery allQuery({bool includeDeleted = false}) => TrackQuery(
        size: 100,
        includeDeleted: includeDeleted,
      );

  @override
  Future<Track> save(Track track) =>
      track.id == 0 ? create(track) : update(track.id, track);

  @override
  Future<void> restore(int id) async {
    await restoreRecord(id);
  }

  @override
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false}) =>
      count({
        'albumId': albumId,
        if (includeDeleted) 'includeDeleted': 'true',
      });
}

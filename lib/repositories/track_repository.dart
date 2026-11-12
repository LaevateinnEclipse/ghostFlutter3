import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/track.dart';
import '../models/track_query.dart';

abstract interface class TrackRepository {
  Future<PageResult<Track>> find(TrackQuery query, {CancelToken? cancelToken});
  Future<Track?> findById(int id);
  Future<List<Track>> all({bool includeDeleted = false});
  Future<Track> save(Track track);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false});
}

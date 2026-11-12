import 'package:dio/dio.dart';

import '../models/album.dart';
import '../models/album_query.dart';
import '../models/page_result.dart';

abstract interface class AlbumRepository {
  Future<PageResult<Album>> find(AlbumQuery query, {CancelToken? cancelToken});
  Future<Album?> findById(int id);
  Future<List<Album>> all({bool includeDeleted = false});
  Future<Album> save(Album album);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
}

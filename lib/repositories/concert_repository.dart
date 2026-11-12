import 'package:dio/dio.dart';

import '../models/concert.dart';
import '../models/concert_query.dart';
import '../models/page_result.dart';

abstract interface class ConcertRepository {
  Future<PageResult<Concert>> find(
    ConcertQuery query, {
    CancelToken? cancelToken,
  });
  Future<Concert?> findById(int id);
  Future<List<Concert>> all({bool includeDeleted = false});
  Future<Concert> save(Concert concert);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false});
  Future<int> countForMember(int memberId, {bool includeDeleted = false});
}

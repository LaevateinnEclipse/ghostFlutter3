import 'package:dio/dio.dart';

import '../models/merch_item.dart';
import '../models/merch_query.dart';
import '../models/page_result.dart';

abstract interface class MerchRepository {
  Future<PageResult<MerchItem>> find(
    MerchQuery query, {
    CancelToken? cancelToken,
  });
  Future<MerchItem?> findById(int id);
  Future<List<MerchItem>> all({bool includeDeleted = false});
  Future<MerchItem> save(MerchItem item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
  Future<int> countForAlbum(int albumId, {bool includeDeleted = false});
}
import 'package:dio/dio.dart';

import '../models/band_member.dart';
import '../models/band_member_query.dart';
import '../models/page_result.dart';

abstract interface class BandMemberRepository {
  Future<PageResult<BandMember>> find(
    BandMemberQuery query, {
    CancelToken? cancelToken,
  });
  Future<BandMember?> findById(int id);
  Future<List<BandMember>> all({bool includeDeleted = false});
  Future<BandMember> save(BandMember member);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> softDeleteMany(List<int> ids);
  Future<int> hardDeleteMany(List<int> ids);
}
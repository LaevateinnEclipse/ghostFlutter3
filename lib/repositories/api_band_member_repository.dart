import '../models/band_member.dart';
import '../models/band_member_query.dart';
import 'api_repository.dart';
import 'band_member_repository.dart';

class ApiBandMemberRepository extends ApiRepository<BandMember, BandMemberQuery>
    implements BandMemberRepository {
  ApiBandMemberRepository(super.dio);

  @override
  String get collectionPath => '/members';

  @override
  int get defaultSize => 10;

  @override
  BandMember fromJson(Map<String, dynamic> json) => BandMember.fromJson(json);

  @override
  Map<String, dynamic> toRequestBody(BandMember member) => {
        'firstName': member.firstName.trim(),
        'lastName': member.lastName.trim(),
        'role': member.role.trim(),
        'yearsInBand': member.yearsInBand,
        'fee': member.fee,
        'email': member.email.trim(),
        'bio': member.bio.trim(),
        'photoUrl': member.photoUrl.trim(),
        'joinedYear': member.joinedYear,
        'stageName': member.stageName.trim(),
        'maskCode': member.maskCode.trim(),
        'appointedOn': member.appointedOn.trim(),
        'albumIds': member.albumIds,
      };

  @override
  Map<String, dynamic> toParameters(BandMemberQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.role != null) 'role': query.role,
        if (query.yearsFrom != null) 'yearsFrom': query.yearsFrom,
        if (query.yearsTo != null) 'yearsTo': query.yearsTo,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': 'true',
      };

  @override
  BandMemberQuery allQuery({bool includeDeleted = false}) => BandMemberQuery(
        size: 100,
        includeDeleted: includeDeleted,
      );

  @override
  Future<BandMember> save(BandMember member) =>
      member.id == 0 ? create(member) : update(member.id, member);

  @override
  Future<void> restore(int id) async {
    await restoreRecord(id);
  }
}

import '../models/concert.dart';
import '../models/concert_query.dart';
import 'api_repository.dart';
import 'concert_repository.dart';

class ApiConcertRepository extends ApiRepository<Concert, ConcertQuery>
    implements ConcertRepository {
  ApiConcertRepository(super.dio);

  @override
  String get collectionPath => '/concerts';

  @override
  int get defaultSize => 10;

  @override
  Concert fromJson(Map<String, dynamic> json) => Concert.fromJson(json);

  @override
  Map<String, dynamic> toRequestBody(Concert concert) => {
        'city': concert.city.trim(),
        'venue': concert.venue.trim(),
        'date': concert.date.toIso8601String(),
        'ticketPrice': concert.ticketPrice,
        'status': concert.status,
        'albumId': concert.albumId,
        'memberIds': concert.memberIds,
        'ticketCode': concert.ticketCode.trim(),
        'contactEmail': concert.contactEmail.trim(),
      };

  @override
  Map<String, dynamic> toParameters(ConcertQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.status != null) 'status': query.status,
        if (query.city != null) 'city': query.city,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': 'true',
      };

  @override
  ConcertQuery allQuery({bool includeDeleted = false}) => ConcertQuery(
        size: 100,
        includeDeleted: includeDeleted,
      );

  @override
  Future<Concert> save(Concert concert) =>
      concert.id == 0 ? create(concert) : update(concert.id, concert);

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

  @override
  Future<int> countForMember(int memberId, {bool includeDeleted = false}) =>
      count({
        'memberId': memberId,
        if (includeDeleted) 'includeDeleted': 'true',
      });
}

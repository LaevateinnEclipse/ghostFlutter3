import '../models/merch_item.dart';
import '../models/merch_query.dart';
import 'api_repository.dart';
import 'merch_repository.dart';

class ApiMerchRepository extends ApiRepository<MerchItem, MerchQuery>
    implements MerchRepository {
  ApiMerchRepository(super.dio);

  @override
  String get collectionPath => '/merch';

  @override
  int get defaultSize => 10;

  @override
  MerchItem fromJson(Map<String, dynamic> json) => MerchItem.fromJson(json);

  @override
  Map<String, dynamic> toRequestBody(MerchItem item) => {
        'name': item.name.trim(),
        'sku': item.sku.trim(),
        'category': item.category.trim(),
        'stock': item.stock,
        'price': item.price,
        'sizeIds': item.sizeIds,
        'albumId': item.albumId,
      };

  @override
  Map<String, dynamic> toParameters(MerchQuery query) => {
        if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        if (query.category != null) 'category': query.category,
        if (query.stockFrom != null) 'stockFrom': query.stockFrom,
        if (query.stockTo != null) 'stockTo': query.stockTo,
        if (query.priceFrom != null) 'priceFrom': query.priceFrom,
        if (query.priceTo != null) 'priceTo': query.priceTo,
        'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
        'page': query.page,
        'size': query.size,
        if (query.includeDeleted) 'includeDeleted': 'true',
      };

  @override
  MerchQuery allQuery({bool includeDeleted = false}) => MerchQuery(
        size: 100,
        includeDeleted: includeDeleted,
      );

  @override
  Future<MerchItem> save(MerchItem item) =>
      item.id == 0 ? create(item) : update(item.id, item);

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

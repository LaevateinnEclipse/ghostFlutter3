class MerchQuery {
  static const _unset = Object();
  static const allowedSizes = [10, 25, 50];
  static const sortFields = ['name', 'stock', 'price', 'category'];
  final String search;
  final String? category;
  final int? stockFrom;
  final int? stockTo;
  final int? priceFrom;
  final int? priceTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  const MerchQuery(
      {this.search = '',
      this.category,
      this.stockFrom,
      this.stockTo,
      this.priceFrom,
      this.priceTo,
      this.sortField = 'name',
      this.sortAscending = true,
      this.page = 1,
      this.size = 10,
      this.includeDeleted = false});

  factory MerchQuery.fromUri(Uri uri) {
    final p = uri.queryParameters;
    final sort = (p['sort'] ?? '').split(',');
    final field = sortFields.contains(sort.first) ? sort.first : 'name';
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    return MerchQuery(
        search: p['search'] ?? '',
        category: p['category'],
        stockFrom: int.tryParse(p['stockFrom'] ?? ''),
        stockTo: int.tryParse(p['stockTo'] ?? ''),
        priceFrom: int.tryParse(p['priceFrom'] ?? ''),
        priceTo: int.tryParse(p['priceTo'] ?? ''),
        sortField: field,
        sortAscending: sort.length < 2 || sort[1] != 'desc',
        page: (int.tryParse(p['page'] ?? '') ?? 1).clamp(1, 9999).toInt(),
        size: allowedSizes.contains(size) ? size : 10,
        includeDeleted: p['includeDeleted'] == 'true');
  }
  Map<String, String> toQueryParameters() {
    final p = <String, String>{};
    if (search.trim().isNotEmpty) p['search'] = search.trim();
    if (category != null) p['category'] = category!;
    if (stockFrom != null) p['stockFrom'] = '$stockFrom';
    if (stockTo != null) p['stockTo'] = '$stockTo';
    if (priceFrom != null) p['priceFrom'] = '$priceFrom';
    if (priceTo != null) p['priceTo'] = '$priceTo';
    if (sortField != 'name' || !sortAscending) {
      p['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) p['page'] = '$page';
    if (size != 10) p['size'] = '$size';
    if (includeDeleted) p['includeDeleted'] = 'true';
    return p;
  }

  MerchQuery copyWith(
          {String? search,
          Object? category = _unset,
          Object? stockFrom = _unset,
          Object? stockTo = _unset,
          Object? priceFrom = _unset,
          Object? priceTo = _unset,
          String? sortField,
          bool? sortAscending,
          int? page,
          int? size,
          bool? includeDeleted}) =>
      MerchQuery(
          search: search ?? this.search,
          category: category == _unset ? this.category : category as String?,
          stockFrom: stockFrom == _unset ? this.stockFrom : stockFrom as int?,
          stockTo: stockTo == _unset ? this.stockTo : stockTo as int?,
          priceFrom: priceFrom == _unset ? this.priceFrom : priceFrom as int?,
          priceTo: priceTo == _unset ? this.priceTo : priceTo as int?,
          sortField: sortField ?? this.sortField,
          sortAscending: sortAscending ?? this.sortAscending,
          page: page ?? 1,
          size: size ?? this.size,
          includeDeleted: includeDeleted ?? this.includeDeleted);
  bool get hasActiveFilters =>
      search.isNotEmpty ||
      category != null ||
      stockFrom != null ||
      stockTo != null ||
      priceFrom != null ||
      priceTo != null ||
      includeDeleted;
}
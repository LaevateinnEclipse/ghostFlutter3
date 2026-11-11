class ConcertQuery {
  static const _unset = Object();
  static const allowedSizes = [10, 25, 50];
  static const sortFields = ['date', 'city', 'ticketPrice', 'status'];
  final String search;
  final String? status;
  final String? city;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  const ConcertQuery({
    this.search = '',
    this.status,
    this.city,
    this.sortField = 'date',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory ConcertQuery.fromUri(Uri uri) {
    final p = uri.queryParameters;
    final sort = (p['sort'] ?? '').split(',');
    final field = sortFields.contains(sort.first) ? sort.first : 'date';
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    return ConcertQuery(
      search: p['search'] ?? '',
      status: p['status'],
      city: p['city'],
      sortField: field,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: (int.tryParse(p['page'] ?? '') ?? 1).clamp(1, 9999).toInt(),
      size: allowedSizes.contains(size) ? size : 10,
      includeDeleted: p['includeDeleted'] == 'true',
    );
  }

  Map<String, String> toQueryParameters() {
    final p = <String, String>{};
    if (search.trim().isNotEmpty) p['search'] = search.trim();
    if (status != null) p['status'] = status!;
    if (city != null) p['city'] = city!;
    if (sortField != 'date' || !sortAscending) {
      p['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) p['page'] = '$page';
    if (size != 10) p['size'] = '$size';
    if (includeDeleted) p['includeDeleted'] = 'true';
    return p;
  }

  ConcertQuery copyWith({
    String? search,
    Object? status = _unset,
    Object? city = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) =>
      ConcertQuery(
        search: search ?? this.search,
        status: status == _unset ? this.status : status as String?,
        city: city == _unset ? this.city : city as String?,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? 1,
        size: size ?? this.size,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );

  bool get hasActiveFilters =>
      search.isNotEmpty || status != null || city != null || includeDeleted;
}

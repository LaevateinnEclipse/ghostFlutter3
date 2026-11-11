class AlbumQuery {
  static const _unset = Object();
  static const allowedSizes = [10, 25, 50];
  static const sortFields = ['title', 'year', 'label', 'albumType'];
  final String search;
  final String? albumType;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  const AlbumQuery({
    this.search = '',
    this.albumType,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory AlbumQuery.fromUri(Uri uri) {
    final p = uri.queryParameters;
    final sort = (p['sort'] ?? '').split(',');
    final field = sortFields.contains(sort.first) ? sort.first : 'title';
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    return AlbumQuery(
      search: p['search'] ?? '',
      albumType: p['albumType'],
      yearFrom: int.tryParse(p['yearFrom'] ?? ''),
      yearTo: int.tryParse(p['yearTo'] ?? ''),
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
    if (albumType != null) p['albumType'] = albumType!;
    if (yearFrom != null) p['yearFrom'] = '$yearFrom';
    if (yearTo != null) p['yearTo'] = '$yearTo';
    if (sortField != 'title' || !sortAscending) {
      p['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) p['page'] = '$page';
    if (size != 10) p['size'] = '$size';
    if (includeDeleted) p['includeDeleted'] = 'true';
    return p;
  }

  AlbumQuery copyWith({
    String? search,
    Object? albumType = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) =>
      AlbumQuery(
        search: search ?? this.search,
        albumType: albumType == _unset ? this.albumType : albumType as String?,
        yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
        yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? 1,
        size: size ?? this.size,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      albumType != null ||
      yearFrom != null ||
      yearTo != null ||
      includeDeleted;
}

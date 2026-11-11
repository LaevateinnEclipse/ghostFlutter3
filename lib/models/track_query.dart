class TrackQuery {
  static const _unset = Object();
  static const allowedSizes = [10, 25, 50];
  static const sortFields = ['title', 'trackNumber', 'durationSeconds', 'genre'];
  final String search;
  final int? albumId;
  final String? genre;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  const TrackQuery({
    this.search = '',
    this.albumId,
    this.genre,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory TrackQuery.fromUri(Uri uri) {
    final p = uri.queryParameters;
    final sort = (p['sort'] ?? '').split(',');
    final field = sortFields.contains(sort.first) ? sort.first : 'title';
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    return TrackQuery(
      search: p['search'] ?? '',
      albumId: int.tryParse(p['albumId'] ?? ''),
      genre: p['genre'],
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
    if (albumId != null) p['albumId'] = '$albumId';
    if (genre != null) p['genre'] = genre!;
    if (sortField != 'title' || !sortAscending) {
      p['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) p['page'] = '$page';
    if (size != 10) p['size'] = '$size';
    if (includeDeleted) p['includeDeleted'] = 'true';
    return p;
  }

  TrackQuery copyWith({
    String? search,
    Object? albumId = _unset,
    Object? genre = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) =>
      TrackQuery(
        search: search ?? this.search,
        albumId: albumId == _unset ? this.albumId : albumId as int?,
        genre: genre == _unset ? this.genre : genre as String?,
        sortField: sortField ?? this.sortField,
        sortAscending: sortAscending ?? this.sortAscending,
        page: page ?? 1,
        size: size ?? this.size,
        includeDeleted: includeDeleted ?? this.includeDeleted,
      );

  bool get hasActiveFilters =>
      search.isNotEmpty || albumId != null || genre != null || includeDeleted;
}

class BandMemberQuery {
  static const _unset = Object();
  static const allowedSizes = [10, 25, 50];
  static const sortFields = ['lastName', 'role', 'yearsInBand', 'fee'];
  final String search;
  final String? role;
  final int? yearsFrom;
  final int? yearsTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  const BandMemberQuery(
      {this.search = '',
      this.role,
      this.yearsFrom,
      this.yearsTo,
      this.sortField = 'lastName',
      this.sortAscending = true,
      this.page = 1,
      this.size = 10,
      this.includeDeleted = false});
  factory BandMemberQuery.fromUri(Uri uri) {
    final p = uri.queryParameters;
    final s = (p['sort'] ?? '').split(',');
    final field = sortFields.contains(s.first) ? s.first : 'lastName';
    final size = int.tryParse(p['size'] ?? '') ?? 10;
    return BandMemberQuery(
        search: p['search'] ?? '',
        role: p['role'],
        yearsFrom: int.tryParse(p['yearsFrom'] ?? ''),
        yearsTo: int.tryParse(p['yearsTo'] ?? ''),
        sortField: field,
        sortAscending: s.length < 2 || s[1] != 'desc',
        page: (int.tryParse(p['page'] ?? '') ?? 1).clamp(1, 9999).toInt(),
        size: allowedSizes.contains(size) ? size : 10,
        includeDeleted: p['includeDeleted'] == 'true');
  }
  Map<String, String> toQueryParameters() {
    final p = <String, String>{};
    if (search.isNotEmpty) p['search'] = search;
    if (role != null) p['role'] = role!;
    if (yearsFrom != null) p['yearsFrom'] = '$yearsFrom';
    if (yearsTo != null) p['yearsTo'] = '$yearsTo';
    if (sortField != 'lastName' || !sortAscending) {
      p['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) p['page'] = '$page';
    if (size != 10) p['size'] = '$size';
    if (includeDeleted) p['includeDeleted'] = 'true';
    return p;
  }

  BandMemberQuery copyWith(
          {String? search,
          Object? role = _unset,
          Object? yearsFrom = _unset,
          Object? yearsTo = _unset,
          String? sortField,
          bool? sortAscending,
          int? page,
          int? size,
          bool? includeDeleted}) =>
      BandMemberQuery(
          search: search ?? this.search,
          role: role == _unset ? this.role : role as String?,
          yearsFrom: yearsFrom == _unset ? this.yearsFrom : yearsFrom as int?,
          yearsTo: yearsTo == _unset ? this.yearsTo : yearsTo as int?,
          sortField: sortField ?? this.sortField,
          sortAscending: sortAscending ?? this.sortAscending,
          page: page ?? 1,
          size: size ?? this.size,
          includeDeleted: includeDeleted ?? this.includeDeleted);
  bool get hasActiveFilters =>
      search.isNotEmpty ||
      role != null ||
      yearsFrom != null ||
      yearsTo != null ||
      includeDeleted;
}
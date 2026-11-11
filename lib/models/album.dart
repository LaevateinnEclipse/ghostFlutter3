class Album {
  final int id;
  final String title;
  final String catalogCode;
  final String albumType;
  final int year;
  final String label;
  final String coverUrl;
  final List<int> memberIds;
  final List<int> trackIds;
  final List<int> concertIds;
  final DateTime? deletedAt;

  const Album({
    required this.id,
    required this.title,
    required this.catalogCode,
    required this.albumType,
    required this.year,
    required this.label,
    this.coverUrl = '',
    this.memberIds = const [],
    this.trackIds = const [],
    this.concertIds = const [],
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  static const types = ['studio', 'live', 'EP', 'single'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'catalogCode': catalogCode,
        'albumType': albumType,
        'year': year,
        'label': label,
        'coverUrl': coverUrl,
        'memberIds': memberIds,
        'trackIds': trackIds,
        'concertIds': concertIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: _asInt(json['id']),
        title: _asString(json['title']),
        catalogCode: _asString(json['catalogCode']),
        albumType: _asString(json['albumType'], fallback: 'studio'),
        year: _asInt(json['year'], fallback: 2010),
        label: _asString(json['label']),
        coverUrl: _asString(json['coverUrl']),
        memberIds: _asIntList(json['memberIds']),
        trackIds: _asIntList(json['trackIds']),
        concertIds: _asIntList(json['concertIds']),
        deletedAt: _asDate(json['deletedAt']),
      );

  Album copyWith({
    String? title,
    String? catalogCode,
    String? albumType,
    int? year,
    String? label,
    String? coverUrl,
    List<int>? memberIds,
    List<int>? trackIds,
    List<int>? concertIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      Album(
        id: id,
        title: title ?? this.title,
        catalogCode: catalogCode ?? this.catalogCode,
        albumType: albumType ?? this.albumType,
        year: year ?? this.year,
        label: label ?? this.label,
        coverUrl: coverUrl ?? this.coverUrl,
        memberIds: memberIds ?? this.memberIds,
        trackIds: trackIds ?? this.trackIds,
        concertIds: concertIds ?? this.concertIds,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );

  static int _asInt(Object? value, {int fallback = 0}) => switch (value) {
        int v => v,
        num v => v.toInt(),
        String v => int.tryParse(v) ?? fallback,
        _ => fallback,
      };
  static String _asString(Object? value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();
  static List<int> _asIntList(Object? value) {
    if (value is! List) return const [];
    return value.map(_asInt).where((id) => id > 0).toList();
  }

  static DateTime? _asDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

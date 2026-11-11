class Track {
  final int id;
  final String title;
  final int trackNumber;
  final int durationSeconds;
  final String genre;
  final int albumId;
  final DateTime? deletedAt;

  const Track({
    required this.id,
    required this.title,
    required this.trackNumber,
    required this.durationSeconds,
    required this.genre,
    required this.albumId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'trackNumber': trackNumber,
        'durationSeconds': durationSeconds,
        'genre': genre,
        'albumId': albumId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: _asInt(json['id']),
        title: _asString(json['title']),
        trackNumber: _asInt(json['trackNumber'], fallback: 1),
        durationSeconds: _asInt(json['durationSeconds'], fallback: 180),
        genre: _asString(json['genre'], fallback: 'Heavy metal'),
        albumId: _asInt(json['albumId']),
        deletedAt: _asDate(json['deletedAt']),
      );

  Track copyWith({
    String? title,
    int? trackNumber,
    int? durationSeconds,
    String? genre,
    int? albumId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      Track(
        id: id,
        title: title ?? this.title,
        trackNumber: trackNumber ?? this.trackNumber,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        genre: genre ?? this.genre,
        albumId: albumId ?? this.albumId,
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
  static DateTime? _asDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

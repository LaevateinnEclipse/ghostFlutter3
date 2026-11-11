class Concert {
  final int id;
  final String city;
  final String venue;
  final DateTime date;
  final int ticketPrice;
  final String status;
  final int albumId;
  final List<int> memberIds;
  final String ticketCode;
  final String contactEmail;
  final DateTime? deletedAt;

  const Concert({
    required this.id,
    required this.city,
    required this.venue,
    required this.date,
    required this.ticketPrice,
    required this.status,
    required this.albumId,
    this.memberIds = const [],
    required this.ticketCode,
    required this.contactEmail,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  static const statuses = ['plan', 'done', 'cancelled'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'city': city,
        'venue': venue,
        'date': date.toIso8601String(),
        'ticketPrice': ticketPrice,
        'status': status,
        'albumId': albumId,
        'memberIds': memberIds,
        'ticketCode': ticketCode,
        'contactEmail': contactEmail,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Concert.fromJson(Map<String, dynamic> json) => Concert(
        id: _asInt(json['id']),
        city: _asString(json['city']),
        venue: _asString(json['venue']),
        date: _asDate(json['date']) ?? DateTime.now(),
        ticketPrice: _asInt(json['ticketPrice']),
        status: _asString(json['status'], fallback: 'plan'),
        albumId: _asInt(json['albumId']),
        memberIds: _asIntList(json['memberIds']),
        ticketCode: _asString(json['ticketCode']),
        contactEmail: _asString(json['contactEmail']),
        deletedAt: _asDate(json['deletedAt']),
      );

  Concert copyWith({
    String? city,
    String? venue,
    DateTime? date,
    int? ticketPrice,
    String? status,
    int? albumId,
    List<int>? memberIds,
    String? ticketCode,
    String? contactEmail,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      Concert(
        id: id,
        city: city ?? this.city,
        venue: venue ?? this.venue,
        date: date ?? this.date,
        ticketPrice: ticketPrice ?? this.ticketPrice,
        status: status ?? this.status,
        albumId: albumId ?? this.albumId,
        memberIds: memberIds ?? this.memberIds,
        ticketCode: ticketCode ?? this.ticketCode,
        contactEmail: contactEmail ?? this.contactEmail,
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

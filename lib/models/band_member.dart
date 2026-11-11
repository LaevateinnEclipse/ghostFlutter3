class BandMember {
  final int id;
  final String firstName;
  final String lastName;
  final String role;
  final int yearsInBand;
  final int fee;
  final String email;
  final String bio;
  final String photoUrl;
  final int joinedYear;
  final String stageName;
  final String maskCode;
  final String appointedOn;
  final List<int> albumIds;
  final List<int> concertIds;
  final DateTime? deletedAt;

  const BandMember(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.role,
      required this.yearsInBand,
      required this.fee,
      this.email = '',
      this.bio = '',
      this.photoUrl = '',
      this.joinedYear = 0,
      this.stageName = '',
      this.maskCode = '',
      this.appointedOn = '',
      this.albumIds = const [],
      this.concertIds = const [],
      this.deletedAt});

  String get fullName => '$lastName $firstName';
  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'yearsInBand': yearsInBand,
        'fee': fee,
        'email': email,
        'bio': bio,
        'photoUrl': photoUrl,
        'joinedYear': joinedYear,
        'stageName': stageName,
        'maskCode': maskCode,
        'appointedOn': appointedOn,
        'albumIds': albumIds,
        'concertIds': concertIds,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory BandMember.fromJson(Map<String, dynamic> json) => BandMember(
        id: _asInt(json['id']),
        firstName: _asString(json['firstName']),
        lastName: _asString(json['lastName']),
        role: _asString(json['role']),
        yearsInBand: _asInt(json['yearsInBand']),
        fee: _asInt(json['fee']),
        email: _asString(json['email']),
        bio: _asString(json['bio']),
        photoUrl: _asString(json['photoUrl']),
        joinedYear: _asInt(json['joinedYear']),
        stageName: _asString(json['stageName']),
        maskCode: _asString(json['maskCode']),
        appointedOn: _asString(json['appointedOn']),
        albumIds: _asIntList(json['albumIds']),
        concertIds: _asIntList(json['concertIds']),
        deletedAt: _asDate(json['deletedAt']),
      );

  BandMember copyWith(
          {String? firstName,
          String? lastName,
          String? role,
          int? yearsInBand,
          int? fee,
          String? email,
          String? bio,
          String? photoUrl,
          int? joinedYear,
          String? stageName,
          String? maskCode,
          String? appointedOn,
          List<int>? albumIds,
          List<int>? concertIds,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      BandMember(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role ?? this.role,
        yearsInBand: yearsInBand ?? this.yearsInBand,
        fee: fee ?? this.fee,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        joinedYear: joinedYear ?? this.joinedYear,
        stageName: stageName ?? this.stageName,
        maskCode: maskCode ?? this.maskCode,
        appointedOn: appointedOn ?? this.appointedOn,
        albumIds: albumIds ?? this.albumIds,
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
    return value.map((item) => _asInt(item)).where((id) => id > 0).toList();
  }

  static DateTime? _asDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class MerchItem {
  final int id;
  final String name;
  final String sku;
  final String category;
  final int stock;
  final int price;
  final List<int> sizeIds;
  final int albumId;
  final DateTime? deletedAt;

  const MerchItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.stock,
    required this.price,
    required this.sizeIds,
    this.albumId = 0,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'category': category,
        'stock': stock,
        'price': price,
        'sizeIds': sizeIds,
        'albumId': albumId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory MerchItem.fromJson(Map<String, dynamic> json) => MerchItem(
        id: _asInt(json['id']),
        name: _asString(json['name']),
        sku: _asString(json['sku']),
        category: _asString(json['category']),
        stock: _asInt(json['stock']),
        price: _asInt(json['price']),
        sizeIds: _asIntList(json['sizeIds']),
        albumId: _asInt(json['albumId']),
        deletedAt: _asDate(json['deletedAt']),
      );

  MerchItem copyWith(
          {String? name,
          String? sku,
          String? category,
          int? stock,
          int? price,
          List<int>? sizeIds,
          int? albumId,
          DateTime? deletedAt,
          bool clearDeletedAt = false}) =>
      MerchItem(
        id: id,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        category: category ?? this.category,
        stock: stock ?? this.stock,
        price: price ?? this.price,
        sizeIds: sizeIds ?? this.sizeIds,
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
  static List<int> _asIntList(Object? value) {
    if (value is! List) return const [];
    return value.map(_asInt).where((id) => id > 0).toList();
  }

  static DateTime? _asDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

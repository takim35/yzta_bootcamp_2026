class OutfitItem {
  final String itemId;
  final String category;
  final String imageUrl;

  const OutfitItem({
    required this.itemId,
    required this.category,
    required this.imageUrl,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) {
    return OutfitItem(
      itemId: json['item_id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'category': category,
      'image_url': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutfitItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId;

  @override
  int get hashCode => itemId.hashCode;

  @override
  String toString() => 'OutfitItem(itemId: $itemId, category: $category)';
}

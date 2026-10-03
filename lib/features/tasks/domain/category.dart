class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final bool isDefault;
  final int sortOrder;
}
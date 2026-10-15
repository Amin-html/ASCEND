abstract interface class ProfileActions {
  /// Сохраняет имя. Пустая строка очищает имя.
  Future<void> setName(String name);
}
import 'package:ascend/features/tasks/domain/category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<void> upsert(Category category);
  Future<void> delete(String id);
}
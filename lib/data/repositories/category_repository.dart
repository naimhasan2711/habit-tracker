import '../database/database_helper.dart';
import '../models/models.dart';
import '../../services/database_service.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DatabaseService _dbService = DatabaseService();

  /// Get all categories
  Future<List<Category>> getCategories() {
    return _dbHelper.getCategories();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(String id) {
    return _dbHelper.getCategoryById(id);
  }

  /// Create new category
  Future<Category> createCategory({
    required String name,
    required int color,
    required String icon,
  }) async {
    final category = Category(
      id: _dbService.generateId(),
      name: name,
      color: color,
      icon: icon,
    );
    await _dbHelper.insertCategory(category);
    return category;
  }

  /// Update category
  Future<void> updateCategory(Category category) {
    return _dbHelper.updateCategory(category);
  }

  /// Delete category
  Future<void> deleteCategory(String id) {
    return _dbHelper.deleteCategory(id);
  }
}

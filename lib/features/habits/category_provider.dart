import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize provider - load data
  Future<void> initialize() async {
    await loadCategories();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getCategories();
    } catch (e) {
      _error = 'Failed to load categories: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new category
  Future<Category?> createCategory({
    required String name,
    required int color,
    required String icon,
  }) async {
    try {
      final category = await _categoryRepository.createCategory(
        name: name,
        color: color,
        icon: icon,
      );

      _categories.add(category);
      notifyListeners();
      return category;
    } catch (e) {
      _error = 'Failed to create category: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update a category
  Future<bool> updateCategory(Category category) async {
    try {
      await _categoryRepository.updateCategory(category);

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String id) async {
    try {
      await _categoryRepository.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get category by ID
  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

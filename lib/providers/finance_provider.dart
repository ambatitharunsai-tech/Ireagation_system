import 'package:flutter/material.dart';

import '../data/repositories/finance_repository.dart';
import '../database/daos/finance_dao.dart';
import '../services/local_cache_service.dart';

class FinanceProvider extends ChangeNotifier {
  final FinanceRepository _repo = FinanceRepository();
  final LocalCacheService _cache = LocalCacheService();

  List<Expense> _expenses = [];
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalExpenses =>
      _expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalRevenue =>
      _sales.fold(0, (sum, item) => sum + (item.quantity * item.price));
  double get profit => totalRevenue - totalExpenses;

  Future<void> loadData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _expenses = await _repo.getExpensesByUser(userId);
      _sales = await _repo.getSalesByUser(userId);

      // Update Cache
      await _cache.saveFinanceData(userId, {
        'expenses': _expenses.map((e) => e.toMap()).toList(),
        'sales': _sales.map((s) => s.toMap()).toList(),
      });
    } catch (e) {
      _error = 'Could not load finance data from server. Attempting offline cache...';
      debugPrint('FinanceProvider.loadData error: $e');

      // Fallback to cache
      final cached = await _cache.getFinanceData(userId);
      if (cached != null) {
        _expenses = (cached['expenses'] as List)
            .map((e) => Expense.fromMap(e))
            .toList();
        _sales = (cached['sales'] as List).map((s) => Sale.fromMap(s)).toList();
      } else {
        _error = 'No offline data available. Please check connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final saved = await _repo.insertExpense(expense);
      _expenses.insert(0, saved);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save expense.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSale(Sale sale) async {
    try {
      final saved = await _repo.insertSale(sale);
      _sales.insert(0, saved);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save sale.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _repo.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete expense.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

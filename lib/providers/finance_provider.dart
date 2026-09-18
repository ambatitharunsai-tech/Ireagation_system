import 'package:flutter/material.dart';

import '../database/daos/finance_dao.dart';

/// Manages finance state (expenses and sales) with error resilience.
class FinanceProvider extends ChangeNotifier {
  final FinanceDao _financeDao = FinanceDao();

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
      _expenses = await _financeDao.getExpensesByUser(userId);
      _sales = await _financeDao.getSalesByUser(userId);
    } catch (e) {
      _error = 'Could not load finance data.';
      debugPrint('FinanceProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final saved = await _financeDao.insertExpense(expense);
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
      final saved = await _financeDao.insertSale(sale);
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
      await _financeDao.deleteExpense(expenseId);
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

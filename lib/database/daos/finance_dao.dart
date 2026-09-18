import 'package:flutter/foundation.dart';

import '../local_database.dart';

/// Expense data model.
class Expense {
  final String id;
  final String userId;
  final String? cropId;
  String category;
  double amount;
  String date;
  String? notes;

  Expense({
    required this.id,
    required this.userId,
    this.cropId,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'crop_id': cropId,
      'category': category,
      'amount': amount,
      'date': date,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'crop_id': cropId,
      'category': category,
      'amount': amount,
      'date': date,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      cropId: map['crop_id'],
      category: map['category'] ?? '',
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : 0.0,
      date: map['date'] ?? '',
      notes: map['notes'],
    );
  }
}

/// Sale data model.
class Sale {
  final String id;
  final String userId;
  final String? cropId;
  double quantity;
  double price;
  String? buyer;
  String date;

  Sale({
    required this.id,
    required this.userId,
    this.cropId,
    required this.quantity,
    required this.price,
    this.buyer,
    required this.date,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'crop_id': cropId,
      'quantity': quantity,
      'price': price,
      'buyer': buyer,
      'date': date,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'crop_id': cropId,
      'quantity': quantity,
      'price': price,
      'buyer': buyer,
      'date': date,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      cropId: map['crop_id'],
      quantity: map['quantity'] != null
          ? (map['quantity'] as num).toDouble()
          : 0.0,
      price: map['price'] != null ? (map['price'] as num).toDouble() : 0.0,
      buyer: map['buyer'],
      date: map['date'] ?? '',
    );
  }
}

/// Data access object for finance operations using LocalDatabase.
class FinanceDao {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<Expense> insertExpense(Expense expense) async {
    return await _db.insertExpense(expense);
  }

  Future<List<Expense>> getExpensesByUser(String userId) async {
    return await _db.getExpensesByUser(userId);
  }

  Future<Sale> insertSale(Sale sale) async {
    return await _db.insertSale(sale);
  }

  Future<List<Sale>> getSalesByUser(String userId) async {
    return await _db.getSalesByUser(userId);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _db.deleteExpense(expenseId);
  }

  Future<void> deleteSale(String saleId) async {
    await _db.deleteSale(saleId);
  }
}

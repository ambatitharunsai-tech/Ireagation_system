import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/daos/finance_dao.dart';

class FinanceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Expense>> getExpensesByUser(String userId) async {
    final data = await _supabase.from('expenses').select().eq('user_id', userId).order('date', ascending: false);
    return data.map((json) => Expense.fromMap(json)).toList();
  }

  Future<Expense> insertExpense(Expense expense) async {
    final data = await _supabase.from('expenses').insert(expense.toInsertMap()).select().single();
    return Expense.fromMap(data);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _supabase.from('expenses').delete().eq('id', expenseId);
  }

  Future<List<Sale>> getSalesByUser(String userId) async {
    final data = await _supabase.from('sales').select().eq('user_id', userId).order('date', ascending: false);
    return data.map((json) => Sale.fromMap(json)).toList();
  }

  Future<Sale> insertSale(Sale sale) async {
    final data = await _supabase.from('sales').insert(sale.toInsertMap()).select().single();
    return Sale.fromMap(data);
  }

  Future<void> deleteSale(String saleId) async {
    await _supabase.from('sales').delete().eq('id', saleId);
  }
}

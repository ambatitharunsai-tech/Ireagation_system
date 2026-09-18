import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/daos/finance_dao.dart';
import '../../widgets/add_finance_dialog.dart';
import 'order_fertilizer_screen.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farm Finances'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
              Tab(icon: Icon(Icons.attach_money), text: 'Sales'),
              Tab(icon: Icon(Icons.science), text: 'Fertilizers'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Summary cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryCard(
                    'Expenses',
                    finance.totalExpenses,
                    Colors.red,
                    Icons.trending_down,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Revenue',
                    finance.totalRevenue,
                    Colors.green,
                    Icons.trending_up,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Profit',
                    finance.profit,
                    finance.profit >= 0 ? Colors.green : Colors.red,
                    finance.profit >= 0 ? Icons.thumb_up : Icons.thumb_down,
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _buildExpenseTab(context, finance),
                  _buildSalesTab(context, finance),
                  _buildFertilizerTab(context, finance),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Entry'),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final formatted = NumberFormat.compactCurrency(symbol: '\$')
        .format(amount.abs());
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                amount < 0 ? '-$formatted' : formatted,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseTab(BuildContext context, FinanceProvider finance) {
    if (finance.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No expenses recorded',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: finance.expenses.length,
      itemBuilder: (ctx, i) {
        final exp = finance.expenses[i];
        return Dismissible(
          key: Key(exp.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => finance.deleteExpense(exp.id),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(
                  _getCategoryIcon(exp.category),
                  color: Colors.red,
                  size: 20,
                ),
              ),
              title: Text(
                exp.category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                exp.date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              trailing: Text(
                '-\$${exp.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesTab(BuildContext context, FinanceProvider finance) {
    if (finance.sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No sales recorded',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: finance.sales.length,
      itemBuilder: (ctx, i) {
        final sale = finance.sales[i];
        final revenue = sale.quantity * sale.price;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.sell, color: Colors.green, size: 20),
            ),
            title: Text(
              sale.buyer ?? 'Sale',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${sale.quantity} units × \$${sale.price.toStringAsFixed(2)} • ${sale.date}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              '+\$${revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFertilizerTab(BuildContext context, FinanceProvider finance) {
    final fertilizerExpenses = finance.expenses
        .where((e) => e.category.toLowerCase().contains('fertilizer'))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderFertilizerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Order Fertilizers'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        if (fertilizerExpenses.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No fertilizer expenses recorded',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: fertilizerExpenses.length,
              itemBuilder: (ctx, i) {
                final exp = fertilizerExpenses[i];
                return Dismissible(
                  key: Key(exp.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => finance.deleteExpense(exp.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade50,
                        child: const Icon(
                          Icons.science,
                          color: Colors.purple,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        exp.category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        exp.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: Text(
                        '-\$${exp.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('seed')) return Icons.spa;
    if (lower.contains('fertilizer')) return Icons.science;
    if (lower.contains('labor') || lower.contains('wage')) return Icons.people;
    if (lower.contains('equipment') || lower.contains('machine'))
      return Icons.agriculture;
    if (lower.contains('fuel') || lower.contains('diesel'))
      return Icons.local_gas_station;
    if (lower.contains('water') || lower.contains('irrigation'))
      return Icons.water_drop;
    return Icons.receipt;
  }

  void _showAddDialog(BuildContext context) {
    AddFinanceDialog.show(context);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

import 'package:intl/intl.dart';

import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../database/daos/finance_dao.dart';

class OrderFertilizerScreen extends StatelessWidget {
  const OrderFertilizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    final products = [
      {
        'name': lang.t('Urea (Nitrogen 46%)'),
        'price': 25.0,
        'icon': Icons.science,
        'desc': lang.t('High nitrogen content for green growth'),
      },
      {
        'name': lang.t('NPK 10-26-26'),
        'price': 35.0,
        'icon': Icons.eco,
        'desc': lang.t('Balanced nutrients for roots and flowering'),
      },
      {
        'name': lang.t('Organic Compost'),
        'price': 15.0,
        'icon': Icons.park,
        'desc': lang.t('Natural soil enrichment'),
      },
      {
        'name': lang.t('DAP Fertilizer'),
        'price': 40.0,
        'icon': Icons.water_drop,
        'desc': lang.t('Excellent source of P and N for early stages'),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('Fertilizer Store'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (ctx, i) {
          final prod = products[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    prod['icon'] as IconData,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                ),
                title: Text(
                  prod['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      prod['desc'] as String,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${(prod['price'] as double).toStringAsFixed(2)} / ${lang.t('bag')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                trailing: FilledButton(
                  onPressed: () => _showPurchaseDialog(context, prod),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(lang.t('Buy')),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, Map<String, dynamic> product) {
    final quantityCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) {
        final lang = Provider.of<LanguageProvider>(ctx);
        return AlertDialog(
          title: Text('${lang.t('Order')} ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${lang.t('Price')}: \$${(product['price'] as double).toStringAsFixed(2)} ${lang.t('per bag')}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: lang.t('Quantity (Bags)'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final qty = int.tryParse(quantityCtrl.text) ?? 1;
                final total = qty * (product['price'] as double);

                final user = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).currentUser;
                if (user != null) {
                  Provider.of<FinanceProvider>(
                    context,
                    listen: false,
                  ).addExpense(
                    Expense(
                      id: '',
                      userId: user.id,
                      category: 'Fertilizer - ${product['name']}',
                      amount: total,
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    ),
                  );
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${lang.t('Successfully ordered')} $qty ${lang.t('bags for')} \$${total.toStringAsFixed(2)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(lang.t('Confirm Order')),
            ),
          ],
        );
      },
    );
  }
}

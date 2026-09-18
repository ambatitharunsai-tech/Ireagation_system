import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../database/daos/finance_dao.dart';

class AddFinanceDialog extends StatefulWidget {
  const AddFinanceDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddFinanceDialog());
  }

  @override
  State<AddFinanceDialog> createState() => _AddFinanceDialogState();
}

class _AddFinanceDialogState extends State<AddFinanceDialog> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _buyerCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Finance Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.money_off),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Sale'),
                  icon: Icon(Icons.sell),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (val) =>
                  setState(() => _isExpense = val.first),
            ),
            const SizedBox(height: 16),
            if (_isExpense) ...[
              TextField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Seeds, Fertilizer, Labor',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  hintText: 'e.g. 150.00',
                ),
              ),
            ] else ...[
              TextField(
                controller: _buyerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buyer Name',
                  hintText: 'e.g. Local Market',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'e.g. 100',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per Unit (\$)',
                  hintText: 'e.g. 5.00',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_isExpense) {
      if (_categoryCtrl.text.trim().isEmpty || _amountCtrl.text.isEmpty) return;
      finance.addExpense(
        Expense(
          id: '',
          userId: user.id,
          category: _categoryCtrl.text.trim(),
          amount: double.tryParse(_amountCtrl.text) ?? 0,
          date: today,
        ),
      );
    } else {
      if (_quantityCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
      finance.addSale(
        Sale(
          id: '',
          userId: user.id,
          quantity: double.tryParse(_quantityCtrl.text) ?? 0,
          price: double.tryParse(_priceCtrl.text) ?? 0,
          buyer: _buyerCtrl.text.trim().isEmpty ? null : _buyerCtrl.text.trim(),
          date: today,
        ),
      );
    }

    Navigator.pop(context);
  }
}

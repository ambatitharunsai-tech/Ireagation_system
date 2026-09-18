import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/farm_provider.dart';
import '../providers/auth_provider.dart';
import '../database/daos/task_dao.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddTaskDialog());
  }

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  String _selectedPriority = 'Medium';

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              hintText: 'e.g. Apply fertilizer to wheat',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Low', label: Text('Low')),
              ButtonSegment(value: 'Medium', label: Text('Medium')),
              ButtonSegment(value: 'High', label: Text('High')),
            ],
            selected: {_selectedPriority},
            onSelectionChanged: (val) {
              setState(() => _selectedPriority = val.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isEmpty) return;
            final user = Provider.of<AuthProvider>(
              context,
              listen: false,
            ).currentUser!;
            final farm = Provider.of<FarmProvider>(context, listen: false);

            farm.addTask(
              FarmTask(
                id: '',
                userId: user.id,
                title: _titleCtrl.text.trim(),
                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                priority: _selectedPriority,
                status: 'Pending',
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

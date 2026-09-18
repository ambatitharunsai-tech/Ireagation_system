import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/farm_provider.dart';
import '../providers/auth_provider.dart';
import '../database/daos/crop_dao.dart';

class AddCropDialog extends StatefulWidget {
  const AddCropDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (ctx) => const AddCropDialog());
  }

  @override
  State<AddCropDialog> createState() => _AddCropDialogState();
}

class _AddCropDialogState extends State<AddCropDialog> {
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _growthStage = 'Seedling';
  String _irrigationMethod = 'Drip';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Crop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Crop Name',
                hintText: 'e.g. Wheat, Rice, Tomato',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Area (acres)',
                hintText: 'e.g. 5.0',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _growthStage,
              decoration: const InputDecoration(labelText: 'Growth Stage'),
              items: [
                'Seedling',
                'Vegetative',
                'Flowering',
                'Fruiting',
                'Harvest Ready',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _growthStage = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _irrigationMethod,
              decoration: const InputDecoration(labelText: 'Irrigation Method'),
              items: [
                'Drip',
                'Sprinkler',
                'Flood',
                'Furrow',
                'Rain-fed',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _irrigationMethod = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks / Notes',
                hintText: 'e.g. Needs extra fertilizer next week',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) return;
            final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
            final farm = Provider.of<FarmProvider>(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(context);
            final name = _nameCtrl.text.trim();

            final success = await farm.addCrop(
              Crop(
                id: '', 
                userId: user.id,
                name: name,
                area: double.tryParse(_areaCtrl.text),
                growthStage: _growthStage,
                irrigationMethod: _irrigationMethod,
                sowingDate: DateTime.now().toIso8601String(),
                notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
              ),
            );

            if (mounted) {
              nav.pop();
              if (success) {
                messenger.showSnackBar(SnackBar(content: Text('$name added successfully!')));
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

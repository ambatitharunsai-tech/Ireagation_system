import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

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
    final lang = Provider.of<LanguageProvider>(context);

    return AlertDialog(
      title: Text(lang.t('Add New Crop')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: lang.t('Crop Name'),
                hintText: lang.t('e.g. Wheat, Rice, Tomato'),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.t('Area (acres)'),
                hintText: lang.t('e.g. 5.0'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _growthStage,
              decoration: InputDecoration(labelText: lang.t('Growth Stage')),
              items: [
                'Seedling',
                'Vegetative',
                'Flowering',
                'Fruiting',
                'Harvest Ready',
              ].map((s) => DropdownMenuItem(value: s, child: Text(lang.t(s)))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _growthStage = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _irrigationMethod,
              decoration: InputDecoration(labelText: lang.t('Irrigation Method')),
              items: [
                'Drip',
                'Sprinkler',
                'Flood',
                'Furrow',
                'Rain-fed',
              ].map((s) => DropdownMenuItem(value: s, child: Text(lang.t(s)))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _irrigationMethod = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                labelText: lang.t('Remarks / Notes'),
                hintText: lang.t('e.g. Needs extra fertilizer next week'),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.t('Cancel')),
        ),
        FilledButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) return;
            final user = Provider.of<AuthProvider>(
              context,
              listen: false,
            ).currentUser!;
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
                notes: _notesCtrl.text.trim().isNotEmpty
                    ? _notesCtrl.text.trim()
                    : null,
              ),
            );

            if (mounted) {
              nav.pop();
              if (success) {
                messenger.showSnackBar(
                  SnackBar(content: Text('${lang.t(name)} ${lang.t('added successfully!')}')),
                );
              }
            }
          },
          child: Text(lang.t('Save')),
        ),
      ],
    );
  }
}

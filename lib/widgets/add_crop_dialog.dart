import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/language_provider.dart';
import '../providers/farm_provider.dart';
import '../providers/auth_provider.dart';
import '../database/daos/crop_dao.dart';

class AddCropDialog extends StatefulWidget {
  final Crop? existingCrop;

  const AddCropDialog({super.key, this.existingCrop});

  static void show(BuildContext context, {Crop? crop}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddCropDialog(existingCrop: crop),
    );
  }

  @override
  State<AddCropDialog> createState() => _AddCropDialogState();
}

class _AddCropDialogState extends State<AddCropDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _varietyCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _notesCtrl;

  String _growthStage = 'Seedling';
  String _irrigationMethod = 'Drip';
  String _soilType = 'Other';
  String _status = 'Active';

  DateTime? _sowingDate;
  DateTime? _expectedHarvestDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCrop?.name ?? '');
    _varietyCtrl = TextEditingController(
      text: widget.existingCrop?.variety ?? '',
    );
    _areaCtrl = TextEditingController(
      text: widget.existingCrop?.area?.toString() ?? '',
    );
    _notesCtrl = TextEditingController(text: widget.existingCrop?.notes ?? '');

    _growthStage = widget.existingCrop?.growthStage ?? 'Seedling';
    _irrigationMethod = widget.existingCrop?.irrigationMethod ?? 'Drip';
    _soilType = widget.existingCrop?.soilType ?? 'Other';
    _status = widget.existingCrop?.status ?? 'Active';

    _sowingDate = widget.existingCrop?.sowingDate;
    _expectedHarvestDate = widget.existingCrop?.expectedHarvestDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _varietyCtrl.dispose();
    _areaCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isHarvest) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final initialDate = isHarvest
        ? (_expectedHarvestDate ?? (_sowingDate ?? DateTime.now()))
        : (_sowingDate ?? DateTime.now());

    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: lang.t(
        isHarvest ? 'Select Expected Harvest Date' : 'Select Sowing Date',
      ),
    );

    if (picked != null) {
      setState(() {
        if (isHarvest) {
          _expectedHarvestDate = picked;
        } else {
          _sowingDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isEdit = widget.existingCrop != null;

    return AlertDialog(
      title: Text(lang.t(isEdit ? 'Edit Crop' : 'Add New Crop')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Crop Name') + ' *',
                ),
                autofocus: !isEdit,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return lang.t('Crop name is required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _varietyCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Variety (Optional)'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: lang.t('Area (acres)') + ' *',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return lang.t('Area is required');
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return lang.t('Enter a valid area > 0');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (isEdit) ...[
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(labelText: lang.t('Status')),
                  items: ['Active', 'Harvested', 'Inactive']
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: Text(lang.t(s))),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _growthStage,
                decoration: InputDecoration(labelText: lang.t('Growth Stage')),
                items:
                    [
                          'Seedling',
                          'Vegetative',
                          'Flowering',
                          'Fruiting',
                          'Harvest Ready',
                        ]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(lang.t(s)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _growthStage = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _soilType,
                decoration: InputDecoration(labelText: lang.t('Soil Type')),
                items:
                    [
                          'Black Soil',
                          'Red Soil',
                          'Alluvial Soil',
                          'Sandy Soil',
                          'Loamy Soil',
                          'Clay Soil',
                          'Other',
                        ]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(lang.t(s)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _soilType = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _irrigationMethod,
                decoration: InputDecoration(
                  labelText: lang.t('Irrigation Method'),
                ),
                items:
                    [
                          'Drip',
                          'Sprinkler',
                          'Flood',
                          'Furrow',
                          'Rain-fed',
                          'Other',
                        ]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(lang.t(s)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _irrigationMethod = v);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _sowingDate != null
                              ? DateFormat.yMMMd().format(_sowingDate!)
                              : lang.t('Sowing Date'),
                        ),
                      ),
                      onPressed: () => _pickDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _expectedHarvestDate != null
                              ? DateFormat.yMMMd().format(_expectedHarvestDate!)
                              : lang.t('Harvest Date'),
                        ),
                      ),
                      onPressed: () => _pickDate(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: lang.t('Remarks / Notes'),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(lang.t('Cancel')),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveCrop,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(lang.t('Save')),
        ),
      ],
    );
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional date validation
    if (_sowingDate != null && _expectedHarvestDate != null) {
      if (_expectedHarvestDate!.isBefore(_sowingDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).t('Harvest date must be after sowing date.'),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser!;
    final farm = Provider.of<FarmProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final crop = Crop(
      id: widget.existingCrop?.id ?? '',
      userId: user.id,
      name: _nameCtrl.text.trim(),
      variety: _varietyCtrl.text.trim().isEmpty
          ? null
          : _varietyCtrl.text.trim(),
      status: _status,
      area: double.tryParse(_areaCtrl.text.trim()),
      areaUnit: 'acres', // Default unit
      growthStage: _growthStage,
      irrigationMethod: _irrigationMethod,
      soilType: _soilType,
      sowingDate: _sowingDate,
      expectedHarvestDate: _expectedHarvestDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.existingCrop?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = widget.existingCrop == null
        ? await farm.addCrop(crop)
        : await farm.updateCrop(crop);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t('Crop saved successfully.'))),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lang.t('Unable to save crop.'))));
      }
    }
  }
}

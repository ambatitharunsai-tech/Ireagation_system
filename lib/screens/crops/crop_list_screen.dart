import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/farm_provider.dart';
import '../../database/daos/crop_dao.dart';
import '../../widgets/add_crop_dialog.dart';

class CropListScreen extends StatelessWidget {
  const CropListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final farm = Provider.of<FarmProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('My Crops')),
        actions: [
          if (farm.crops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${farm.activeCropCount} ${lang.t('active')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: farm.crops.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grass, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    lang.t('No crops yet'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(lang.t('Tap + to add your first crop')),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => AddCropDialog.show(context),
                    icon: const Icon(Icons.add),
                    label: Text(lang.t('Add Crop')),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: farm.crops.length,
              itemBuilder: (context, i) {
                final crop = farm.crops[i];
                return _buildCropCard(context, crop, farm, lang);
              },
            ),
      floatingActionButton: farm.crops.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => AddCropDialog.show(context),
              icon: const Icon(Icons.add),
              label: Text(lang.t('Add Crop')),
            )
          : null,
    );
  }

  Widget _buildCropCard(BuildContext context, Crop crop, FarmProvider farm, LanguageProvider lang) {
    final isActive = crop.status == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCropDetails(context, crop, lang),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Crop icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.eco,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Crop info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crop.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang.t(crop.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _infoChip(
                          Icons.timeline,
                          crop.growthStage != null ? lang.t(crop.growthStage!) : lang.t('Unknown'),
                        ),
                        const SizedBox(width: 12),
                        if (crop.area != null)
                          _infoChip(Icons.square_foot, '${crop.area} ${lang.t('acres')}'),
                      ],
                    ),
                    if (crop.irrigationMethod != null) ...[
                      const SizedBox(height: 4),
                      _infoChip(Icons.water_drop, lang.t(crop.irrigationMethod!)),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDelete(context, crop, farm, lang);
                  } else if (val == 'edit') {
                    _showEditCropDialog(context, crop, farm, lang);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(lang.t('Edit'))),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(lang.t('Delete'), style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  void _showCropDetails(BuildContext context, Crop crop, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                crop.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(lang.t('Status'), lang.t(crop.status)),
              _detailRow(lang.t('Growth Stage'), crop.growthStage != null ? lang.t(crop.growthStage!) : lang.t('Not set')),
              _detailRow(
                lang.t('Area'),
                crop.area != null ? '${crop.area} ${lang.t('acres')}' : lang.t('Not set'),
              ),
              _detailRow(lang.t('Soil Type'), crop.soilType != null ? lang.t(crop.soilType!) : lang.t('Not set')),
              _detailRow(lang.t('Irrigation'), crop.irrigationMethod != null ? lang.t(crop.irrigationMethod!) : lang.t('Not set')),
              _detailRow(lang.t('Sowing Date'), crop.sowingDate ?? lang.t('Not set')),
              _detailRow(
                lang.t('Expected Harvest'),
                crop.expectedHarvestDate ?? lang.t('Not set'),
              ),
              if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  lang.t('Notes'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(crop.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Crop crop, FarmProvider farm, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('Delete Crop')),
        content: Text(
          '${lang.t('Are you sure you want to delete')} "${crop.name}"? ${lang.t('This action cannot be undone.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lang.t('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              farm.deleteCrop(crop.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${crop.name} ${lang.t('deleted')}',)));
            },
            child: Text(lang.t('Delete')),
          ),
        ],
      ),
    );
  }

  void _showEditCropDialog(BuildContext context, Crop crop, FarmProvider farm, LanguageProvider lang) {
    final nameCtrl = TextEditingController(text: crop.name);
    final areaCtrl = TextEditingController(text: crop.area?.toString() ?? '');
    final notesCtrl = TextEditingController(text: crop.notes ?? '');
    String growthStage = crop.growthStage ?? 'Seedling';
    String status = crop.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lang.t('Edit Crop')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: lang.t('Crop Name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: lang.t('Area (acres)')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: growthStage,
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
                            (s) => DropdownMenuItem(value: s, child: Text(lang.t(s))),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => growthStage = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: lang.t('Status')),
                  items: ['Active', 'Harvested', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(lang.t(s))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: lang.t('Remarks / Notes'),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.t('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                crop.name = nameCtrl.text.trim();
                crop.area = double.tryParse(areaCtrl.text);
                crop.growthStage = growthStage;
                crop.status = status;
                crop.notes = notesCtrl.text.trim().isNotEmpty
                    ? notesCtrl.text.trim()
                    : null;
                farm.updateCrop(crop);
                Navigator.pop(ctx);
              },
              child: Text(lang.t('Update')),
            ),
          ],
        ),
      ),
    );
  }
}

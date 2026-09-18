import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/farm_provider.dart';
import '../../database/daos/crop_dao.dart';
import '../../widgets/add_crop_dialog.dart';

class CropListScreen extends StatelessWidget {
  const CropListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Crops'),
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
                    '${farm.activeCropCount} active',
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
                    'No crops yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first crop'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => AddCropDialog.show(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Crop'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: farm.crops.length,
              itemBuilder: (context, i) {
                final crop = farm.crops[i];
                return _buildCropCard(context, crop, farm);
              },
            ),
      floatingActionButton: farm.crops.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => AddCropDialog.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Crop'),
            )
          : null,
    );
  }

  Widget _buildCropCard(BuildContext context, Crop crop, FarmProvider farm) {
    final isActive = crop.status == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCropDetails(context, crop),
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
                            crop.status,
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
                          crop.growthStage ?? 'Unknown',
                        ),
                        const SizedBox(width: 12),
                        if (crop.area != null)
                          _infoChip(Icons.square_foot, '${crop.area} acres'),
                      ],
                    ),
                    if (crop.irrigationMethod != null) ...[
                      const SizedBox(height: 4),
                      _infoChip(Icons.water_drop, crop.irrigationMethod!),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') {
                    _confirmDelete(context, crop, farm);
                  } else if (val == 'edit') {
                    _showEditCropDialog(context, crop, farm);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
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

  void _showCropDetails(BuildContext context, Crop crop) {
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
              _detailRow('Status', crop.status),
              _detailRow('Growth Stage', crop.growthStage ?? 'Not set'),
              _detailRow(
                'Area',
                crop.area != null ? '${crop.area} acres' : 'Not set',
              ),
              _detailRow('Soil Type', crop.soilType ?? 'Not set'),
              _detailRow('Irrigation', crop.irrigationMethod ?? 'Not set'),
              _detailRow('Sowing Date', crop.sowingDate ?? 'Not set'),
              _detailRow(
                'Expected Harvest',
                crop.expectedHarvestDate ?? 'Not set',
              ),
              if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
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

  void _confirmDelete(BuildContext context, Crop crop, FarmProvider farm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop'),
        content: Text(
          'Are you sure you want to delete "${crop.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              farm.deleteCrop(crop.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('${crop.name} deleted')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditCropDialog(BuildContext context, Crop crop, FarmProvider farm) {
    final nameCtrl = TextEditingController(text: crop.name);
    final areaCtrl = TextEditingController(text: crop.area?.toString() ?? '');
    final notesCtrl = TextEditingController(text: crop.notes ?? '');
    String growthStage = crop.growthStage ?? 'Seedling';
    String status = crop.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Crop'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Crop Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Area (acres)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: growthStage,
                  decoration: const InputDecoration(labelText: 'Growth Stage'),
                  items:
                      [
                            'Seedling',
                            'Vegetative',
                            'Flowering',
                            'Fruiting',
                            'Harvest Ready',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => growthStage = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Active', 'Harvested', 'Inactive']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Notes',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
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
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

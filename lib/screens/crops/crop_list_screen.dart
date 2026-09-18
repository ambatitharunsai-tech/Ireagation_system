import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/farm_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../database/daos/crop_dao.dart';
import '../../widgets/add_crop_dialog.dart';
import 'crop_detail_screen.dart';

class CropListScreen extends StatefulWidget {
  const CropListScreen({super.key});

  @override
  State<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends State<CropListScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortOption = 'Newest';

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context);

    // Apply Filters & Search
    List<Crop> displayedCrops = farm.crops.where((crop) {
      if (_filterStatus != 'All' && crop.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = crop.name.toLowerCase().contains(query);
        final matchVariety = (crop.variety ?? '').toLowerCase().contains(query);
        final matchSoil = (crop.soilType ?? '').toLowerCase().contains(query);
        return matchName || matchVariety || matchSoil;
      }
      return true;
    }).toList();

    // Apply Sorting
    displayedCrops.sort((a, b) {
      switch (_sortOption) {
        case 'Oldest':
          return (a.createdAt ?? DateTime.now()).compareTo(
            b.createdAt ?? DateTime.now(),
          );
        case 'Name A-Z':
          return a.name.compareTo(b.name);
        case 'Name Z-A':
          return b.name.compareTo(a.name);
        case 'Area':
          return (b.area ?? 0).compareTo(a.area ?? 0);
        case 'Expected Harvest':
          if (a.expectedHarvestDate == null && b.expectedHarvestDate == null)
            return 0;
          if (a.expectedHarvestDate == null) return 1;
          if (b.expectedHarvestDate == null) return -1;
          return a.expectedHarvestDate!.compareTo(b.expectedHarvestDate!);
        case 'Status':
          return a.status.compareTo(b.status);
        case 'Newest':
        default:
          return (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('My Crops')),
        actions: [
          if (farm.isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    lang.t('Offline'),
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCards(farm, lang),
                const SizedBox(height: 12),
                _buildSearchAndFilter(lang),
              ],
            ),
          ),
        ),
      ),
      body: farm.isLoadingCrops
          ? const Center(child: CircularProgressIndicator())
          : displayedCrops.isEmpty
          ? _buildEmptyState(lang)
          : RefreshIndicator(
              onRefresh: () async {
                if (auth.currentUser != null) {
                  await farm.loadCrops(auth.currentUser!.id);
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: displayedCrops.length,
                itemBuilder: (ctx, i) =>
                    _buildCropCard(context, displayedCrops[i], farm, lang),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'crops_fab',
        onPressed: () => AddCropDialog.show(context),
        icon: const Icon(Icons.add),
        label: Text(lang.t('Add Crop')),
      ),
    );
  }

  Widget _buildSummaryCards(FarmProvider farm, LanguageProvider lang) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            lang.t('Total Crops'),
            farm.crops.length.toString(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            lang.t('Active'),
            farm.activeCropCount.toString(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            lang.t('Harvested'),
            farm.harvestedCropCount.toString(),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(LanguageProvider lang) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: lang.t('Search crops...'),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          tooltip: lang.t('Filter'),
          onSelected: (val) => setState(() => _filterStatus = val),
          itemBuilder: (ctx) =>
              ['All', 'Active', 'Harvested', 'Inactive'].map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == _filterStatus ? Icons.check : Icons.circle,
                        size: 16,
                        color: s == _filterStatus
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Text(lang.t(s)),
                    ],
                  ),
                );
              }).toList(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: lang.t('Sort'),
          onSelected: (val) => setState(() => _sortOption = val),
          itemBuilder: (ctx) =>
              [
                'Newest',
                'Oldest',
                'Name A-Z',
                'Name Z-A',
                'Area',
                'Expected Harvest',
                'Status',
              ].map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(
                        s == _sortOption ? Icons.check : Icons.circle,
                        size: 16,
                        color: s == _sortOption
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Text(lang.t(s)),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grass, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            lang.t('No crops found'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('Add your first crop to start managing your farm.'),
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => AddCropDialog.show(context),
            icon: const Icon(Icons.add),
            label: Text(lang.t('Add Crop')),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(
    BuildContext context,
    Crop crop,
    FarmProvider farm,
    LanguageProvider lang,
  ) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Color statusColor = Colors.grey;
    if (crop.status == 'Active') statusColor = Colors.green;
    if (crop.status == 'Harvested') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCropDetails(context, crop, lang),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (crop.variety != null)
                          Text(
                            crop.variety!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      lang.t(crop.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        AddCropDialog.show(context, crop: crop);
                      } else if (val == 'delete') {
                        _confirmDelete(
                          context,
                          crop,
                          farm,
                          lang,
                          auth.currentUser!.id,
                        );
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(lang.t('Edit')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang.t('Delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _infoChip(
                    Icons.eco,
                    crop.growthStage != null
                        ? lang.t(crop.growthStage!)
                        : lang.t('Not set'),
                  ),
                  _infoChip(
                    Icons.square_foot,
                    crop.area != null
                        ? '${crop.area} ${lang.t(crop.areaUnit ?? 'acres')}'
                        : lang.t('Not set'),
                  ),
                  _infoChip(
                    Icons.water_drop,
                    crop.irrigationMethod != null
                        ? lang.t(crop.irrigationMethod!)
                        : lang.t('Not set'),
                  ),
                  _infoChip(
                    Icons.calendar_today,
                    crop.sowingDate != null
                        ? DateFormat.yMMMd().format(crop.sowingDate!)
                        : lang.t('Not set'),
                  ),
                  _infoChip(
                    Icons.event,
                    crop.expectedHarvestDate != null
                        ? DateFormat.yMMMd().format(crop.expectedHarvestDate!)
                        : lang.t('Not set'),
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
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }

  void _showCropDetails(
    BuildContext context,
    Crop crop,
    LanguageProvider lang,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
    );
  }

  void _confirmDelete(
    BuildContext context,
    Crop crop,
    FarmProvider farm,
    LanguageProvider lang,
    String userId,
  ) {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(lang.t('Delete Crop')),
          content: Text(
            '${lang.t("Are you sure you want to delete")} "${crop.name}"?\\n\\n${lang.t("This action cannot be undone.")}',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text(lang.t('Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      final success = await farm.deleteCrop(crop.id, userId);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${lang.t(crop.name)} ${lang.t('deleted successfully')}.',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang.t(
                                  'Crop was not deleted. Please try again.',
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(lang.t('Delete')),
            ),
          ],
        ),
      ),
    );
  }
}

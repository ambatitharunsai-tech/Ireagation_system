import '../local_database.dart';

/// Crop data model.
class Crop {
  final String id;
  final String userId;
  final String? farmId;
  final String? fieldId;
  String name;
  String? variety;
  String status;
  String? growthStage;
  DateTime? sowingDate;
  DateTime? expectedHarvestDate;
  double? area;
  String? areaUnit;
  String? soilType;
  String? irrigationMethod;
  String? seedSource;
  double? plantingDensity;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;

  Crop({
    required this.id,
    required this.userId,
    this.farmId,
    this.fieldId,
    required this.name,
    this.variety,
    this.status = 'Active',
    this.growthStage,
    this.sowingDate,
    this.expectedHarvestDate,
    this.area,
    this.areaUnit,
    this.soilType,
    this.irrigationMethod,
    this.seedSource,
    this.plantingDensity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'farm_id': farmId,
      'field_id': fieldId,
      'name': name,
      'variety': variety,
      'status': status,
      'growth_stage': growthStage,
      'sowing_date': sowingDate?.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
      'area': area,
      'area_unit': areaUnit,
      'soil_type': soilType,
      'irrigation_method': irrigationMethod,
      'seed_source': seedSource,
      'planting_density': plantingDensity,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'farm_id': farmId,
      'field_id': fieldId,
      'name': name,
      'variety': variety,
      'status': status,
      'growth_stage': growthStage,
      'sowing_date': sowingDate?.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
      'area': area,
      'area_unit': areaUnit,
      'soil_type': soilType,
      'irrigation_method': irrigationMethod,
      'seed_source': seedSource,
      'planting_density': plantingDensity,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    final m = toInsertMap();
    m['id'] = id;
    m['created_at'] = createdAt?.toIso8601String();
    m['updated_at'] = updatedAt?.toIso8601String();
    return m;
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        if (val.isEmpty) return null;
        return DateTime.tryParse(val);
      }
      return null;
    }

    return Crop(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      farmId: map['farm_id']?.toString(),
      fieldId: map['field_id']?.toString(),
      name: map['name']?.toString() ?? '',
      variety: map['variety']?.toString(),
      status: map['status']?.toString() ?? 'Active',
      growthStage: map['growth_stage']?.toString(),
      sowingDate: parseDate(map['sowing_date']),
      expectedHarvestDate: parseDate(map['expected_harvest_date']),
      area: map['area'] != null ? (map['area'] as num).toDouble() : null,
      areaUnit: map['area_unit']?.toString(),
      soilType: map['soil_type']?.toString(),
      irrigationMethod: map['irrigation_method']?.toString(),
      seedSource: map['seed_source']?.toString(),
      plantingDensity: map['planting_density'] != null
          ? (map['planting_density'] as num).toDouble()
          : null,
      notes: map['notes']?.toString(),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}

class Harvest {
  final String id;
  final String cropId;
  final String userId;
  final DateTime harvestDate;
  final double quantity;
  final String quantityUnit;
  final String? quality;
  final String? notes;
  final DateTime? createdAt;

  Harvest({
    required this.id,
    required this.cropId,
    required this.userId,
    required this.harvestDate,
    required this.quantity,
    this.quantityUnit = 'kg',
    this.quality,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'crop_id': cropId,
      'user_id': userId,
      'harvest_date': harvestDate.toIso8601String(),
      'quantity': quantity,
      'quantity_unit': quantityUnit,
      'quality': quality,
      'notes': notes,
    };
  }

  factory Harvest.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Harvest(
      id: map['id']?.toString() ?? '',
      cropId: map['crop_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      harvestDate: parseDate(map['harvest_date']),
      quantity: map['quantity'] != null
          ? (map['quantity'] as num).toDouble()
          : 0.0,
      quantityUnit: map['quantity_unit']?.toString() ?? 'kg',
      quality: map['quality']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class CropStageHistory {
  final String id;
  final String cropId;
  final String userId;
  final String? oldStage;
  final String newStage;
  final String? notes;
  final DateTime changedAt;

  CropStageHistory({
    required this.id,
    required this.cropId,
    required this.userId,
    this.oldStage,
    required this.newStage,
    this.notes,
    required this.changedAt,
  });

  factory CropStageHistory.fromMap(Map<String, dynamic> map) {
    return CropStageHistory(
      id: map['id']?.toString() ?? '',
      cropId: map['crop_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      oldStage: map['old_stage']?.toString(),
      newStage: map['new_stage']?.toString() ?? '',
      notes: map['notes']?.toString(),
      changedAt: map['changed_at'] != null
          ? DateTime.tryParse(map['changed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CropDao {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<Crop> insertCrop(Crop crop) async {
    return await _db.insertCrop(crop);
  }

  Future<List<Crop>> getCropsByUser(String userId) async {
    return await _db.getCropsByUser(userId);
  }

  Future<void> updateCrop(Crop crop) async {
    await _db.updateCrop(crop);
  }

  Future<void> deleteCrop(String cropId) async {
    await _db.deleteCrop(cropId);
  }
}

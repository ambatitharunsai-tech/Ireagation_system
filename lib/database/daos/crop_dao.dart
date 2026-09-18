import 'package:flutter/foundation.dart';

import '../local_database.dart';

/// Crop data model.
class Crop {
  final String id;
  final String userId;
  String name;
  String status;
  String? growthStage;
  String? sowingDate;
  String? expectedHarvestDate;
  double? area;
  String? soilType;
  String? irrigationMethod;
  String? notes;

  Crop({
    required this.id,
    required this.userId,
    required this.name,
    this.status = 'Active',
    this.growthStage,
    this.sowingDate,
    this.expectedHarvestDate,
    this.area,
    this.soilType,
    this.irrigationMethod,
    this.notes,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'status': status,
      'growth_stage': growthStage,
      'sowing_date': sowingDate,
      'expected_harvest_date': expectedHarvestDate,
      'area': area,
      'soil_type': soilType,
      'irrigation_method': irrigationMethod,
      'notes': notes,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'status': status,
      'growth_stage': growthStage,
      'sowing_date': sowingDate,
      'expected_harvest_date': expectedHarvestDate,
      'area': area,
      'soil_type': soilType,
      'irrigation_method': irrigationMethod,
      'notes': notes,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'status': status,
      'growth_stage': growthStage,
      'sowing_date': sowingDate,
      'expected_harvest_date': expectedHarvestDate,
      'area': area,
      'soil_type': soilType,
      'irrigation_method': irrigationMethod,
      'notes': notes,
    };
  }

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? 'Active',
      growthStage: map['growth_stage'],
      sowingDate: map['sowing_date'],
      expectedHarvestDate: map['expected_harvest_date'],
      area: map['area'] != null ? (map['area'] as num).toDouble() : null,
      soilType: map['soil_type'],
      irrigationMethod: map['irrigation_method'],
      notes: map['notes'],
    );
  }
}

/// Data access object for crop operations using LocalDatabase.
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

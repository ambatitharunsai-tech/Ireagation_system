import 'package:flutter/foundation.dart';
import '../database/local_database.dart';

/// User model for the application.
class AppUser {
  final String id;
  final String name;
  final String email;
  String? farmName;
  String? location;
  String? language;
  double? farmSize;
  String? soilType;
  String? profilePic;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.farmName,
    this.location,
    this.language,
    this.farmSize,
    this.soilType,
    this.profilePic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'farm_name': farmName,
      'location': location,
      'language': language,
      'farm_size': farmSize,
      'soil_type': soilType,
      'profile_pic': profilePic,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Farmer',
      email: map['email'] ?? '',
      farmName: map['farm_name'],
      location: map['location'],
      language: map['language'],
      farmSize: map['farm_size'] != null
          ? (map['farm_size'] as num).toDouble()
          : null,
      soilType: map['soil_type'],
      profilePic: map['profile_pic'],
    );
  }
}

/// Handles authentication operations using LocalDatabase.
class AuthService {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<AppUser?> login(String email, String password) async {
    return await _db.login(email, password);
  }

  Future<AppUser> register(String name, String email, String password) async {
    return await _db.register(name, email, password);
  }

  Future<void> updateProfile(AppUser user) async {
    await _db.updateProfile(user);
  }

  Future<void> logout() async {
    // Local DB has no active session state to clear
  }
}

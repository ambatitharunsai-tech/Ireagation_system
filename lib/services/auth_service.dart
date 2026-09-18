import 'package:supabase_flutter/supabase_flutter.dart';

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

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AppUser?> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      return await _fetchProfile(response.user!.id, email);
    }
    return null;
  }

  Future<AppUser> register(String name, String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final userId = response.user!.id;

    // Create profile
    final profile = AppUser(id: userId, name: name, email: email);
    await _supabase.from('profiles').insert(profile.toMap());

    return profile;
  }

  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return await _fetchProfile(user.id, user.email ?? '');
    }
    return null;
  }

  Future<AppUser> _fetchProfile(String userId, String email) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    final profile = AppUser.fromMap(data);
    return profile;
  }

  Future<void> updateProfile(AppUser user) async {
    await _supabase.from('profiles').update(user.toMap()).eq('id', user.id);
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}

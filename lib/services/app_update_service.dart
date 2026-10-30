import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String version;
  final String downloadUrl;
  final String releaseNotes;
}

class AppUpdateService {
  AppUpdateService._();

  static const _latestReleaseApi =
      'https://api.github.com/repos/ambatitharunsai-tech/Ireagation_system/releases/latest';
  static const _lastCheckKey = 'app_update_last_check_ms';
  static const _lastPromptedVersionKey = 'app_update_last_prompted_version';
  static const _checkInterval = Duration(hours: 12);

  /// Returns a newer public release, or null when no update is needed.
  /// Network failures are non-fatal and never block app startup.
  static Future<AppUpdate?> checkForUpdate() async {
    if (kIsWeb) return null;

    try {
      final preferences = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = preferences.getInt(_lastCheckKey);

      if (lastCheck != null &&
          now - lastCheck < _checkInterval.inMilliseconds) {
        return null;
      }

      final response = await http
          .get(
            Uri.parse(_latestReleaseApi),
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'Ireagation-System-Android',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        debugPrint('App update check returned HTTP ${response.statusCode}.');
        return null;
      }

      await preferences.setInt(_lastCheckKey, now);

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = release['tag_name'] as String?;
      if (tag == null) return null;

      final latestVersion = tag.replaceFirst(RegExp(r'^android-v'), '');
      final packageInfo = await PackageInfo.fromPlatform();

      if (!isNewerVersion(latestVersion, packageInfo.version)) {
        return null;
      }

      if (preferences.getString(_lastPromptedVersionKey) == latestVersion) {
        return null;
      }

      final assets = release['assets'] as List<dynamic>? ?? const [];
      final apkAsset = assets.whereType<Map<String, dynamic>>().firstWhere(
            (asset) => asset['name'] == 'app-release.apk',
            orElse: () => <String, dynamic>{},
          );
      final downloadUrl = apkAsset['browser_download_url'] as String?;

      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      return AppUpdate(
        version: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: (release['body'] as String? ?? '').trim(),
      );
    } catch (error) {
      debugPrint('Unable to check for app updates: $error');
      return null;
    }
  }

  static Future<void> markPrompted(String version) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastPromptedVersionKey, version);
  }

  /// Numeric comparison for version tags such as 1.0.35.
  @visibleForTesting
  static bool isNewerVersion(String latest, String current) {
    final latestParts = _numericParts(latest);
    final currentParts = _numericParts(current);
    if (latestParts.isEmpty || currentParts.isEmpty) return false;

    final count = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var index = 0; index < count; index++) {
      final latestPart = index < latestParts.length ? latestParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    return false;
  }

  static List<int> _numericParts(String version) => RegExp(r'\d+')
      .allMatches(version)
      .map((match) => int.parse(match.group(0)!))
      .toList();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ireagation_system/services/app_update_service.dart';

void main() {
  group('AppUpdateService.isNewerVersion', () {
    test('recognizes a newer patch release', () {
      expect(AppUpdateService.isNewerVersion('1.0.35', '1.0.34'), isTrue);
    });

    test('recognizes a newer minor release', () {
      expect(AppUpdateService.isNewerVersion('1.2.0', '1.1.9'), isTrue);
    });

    test('does not treat the same release as an update', () {
      expect(AppUpdateService.isNewerVersion('1.0.34', '1.0.34'), isFalse);
    });

    test('does not downgrade an installed version', () {
      expect(AppUpdateService.isNewerVersion('1.0.33', '1.0.34'), isFalse);
    });
  });
}

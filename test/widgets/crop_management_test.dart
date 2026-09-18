import 'package:flutter_test/flutter_test.dart';
import 'package:ireagation_system/database/daos/crop_dao.dart';

void main() {
  group('Crop Management Tests', () {
    test('Crop model parses correctly without missing fake data', () {
      final map = {
        'id': 'crop-1',
        'user_id': 'user-1',
        'name': 'Wheat',
      };
      
      final crop = Crop.fromMap(map);
      
      expect(crop.name, 'Wheat');
      expect(crop.area, isNull);
      expect(crop.growthStage, isNull);
      expect(crop.sowingDate, isNull);
      expect(crop.expectedHarvestDate, isNull);
    });

    test('Crop model does not use dummy values for missing area or dates', () {
      final map = {
        'id': 'crop-1',
        'user_id': 'user-1',
        'name': 'Wheat',
        'area': null,
        'sowing_date': null,
      };
      
      final crop = Crop.fromMap(map);
      expect(crop.area, isNull);
      expect(crop.sowingDate, isNull);
    });
    
    test('Crop toInsertMap formats dates properly', () {
      final crop = Crop(
        id: '1',
        userId: 'u1',
        name: 'Tomato',
        sowingDate: DateTime(2026, 1, 1),
      );
      
      final map = crop.toInsertMap();
      expect(map['sowing_date'], '2026-01-01T00:00:00.000');
      expect(map['name'], 'Tomato');
    });
  });
}

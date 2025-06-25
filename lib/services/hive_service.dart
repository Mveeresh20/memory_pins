import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// A service class to handle Hive database operations
class HiveService {
  /// Box names
  static const String locationBoxName = 'locationBox';
  static const String userBoxName = 'userBox';
  static const String settingsBoxName = 'settingsBox';

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);

      // Open boxes
      await Future.wait([
        Hive.openBox(locationBoxName),
        Hive.openBox(userBoxName),
        Hive.openBox(settingsBoxName),
      ]);
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Get the location box
  static Box getLocationBox() => Hive.box(locationBoxName);

  /// Get the user box
  static Box getUserBox() => Hive.box(userBoxName);

  /// Get the settings box
  static Box getSettingsBox() => Hive.box(settingsBoxName);

  /// Close all boxes
  static Future<void> closeBoxes() async {
    try {
      await Future.wait([
        Hive.box(locationBoxName).close(),
        Hive.box(userBoxName).close(),
        Hive.box(settingsBoxName).close(),
      ]);
    } catch (e) {
      print('Error closing Hive boxes: $e');
      rethrow;
    }
  }

  /// Save location data
  static Future<void> saveLocation(Map<String, dynamic> location) async {
    try {
      final box = getLocationBox();
      await box.put('lastLocation', location);
    } catch (e) {
      print('Error saving location: $e');
      rethrow;
    }
  }

  /// Get the last saved location
  static Map<String, dynamic>? getLastLocation() {
    try {
      final box = getLocationBox();
      return box.get('lastLocation') as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting last location: $e');
      return null;
    }
  }

  /// Delete the location box
  static Future<void> deleteLocationBox() async {
    try {
      final box = getLocationBox();
      await box.deleteFromDisk();
    } catch (e) {
      print('Error deleting location box: $e');
      rethrow;
    }
  }
}

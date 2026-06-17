import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'widget_snapshot.dart';

class IosWidgetService {
  static const _channel = MethodChannel('beerreal/widget');

  /// Pushes the full data set for all five home-screen widgets to the
  /// native side, which stores it in the shared app-group container and
  /// reloads every widget timeline.
  static Future<void> updateSnapshot(WidgetSnapshot snapshot) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod<void>('updateSnapshot', snapshot.toMap());
    } on MissingPluginException {
      // The native widget bridge only exists on iOS app builds.
    } on PlatformException catch (e) {
      debugPrint('[widget] updateSnapshot failed: ${e.message}');
    }
  }
}

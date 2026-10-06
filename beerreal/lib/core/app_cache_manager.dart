import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AppCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'pintAppImages';
  static final instance = AppCacheManager._();

  AppCacheManager._()
    : super(
        Config(
          _key,
          // Cache images for 30 days (maximum retention)
          stalePeriod: const Duration(days: 30),
          // Increase max cache size to 500 images
          maxNrOfCacheObjects: 500,
        ),
      );
}

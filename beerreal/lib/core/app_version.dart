const kAppVersion = '1.8';

const kIosTestFlightUrl = String.fromEnvironment(
  'IOS_TESTFLIGHT_URL',
  defaultValue: 'https://testflight.apple.com/join/sJ4c5Ks9',
);
const kAndroidPlayStoreUrl = String.fromEnvironment(
  'ANDROID_PLAY_STORE_URL',
  defaultValue:
      'https://play.google.com/store/apps/details?id=de.maxengl.zapfen.mobile',
);

import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static late SharedPreferences pref;

  static Future<void> initSharedPref() async {
    pref = await SharedPreferences.getInstance();
  }

  static Future<void> setOnboardingDone() async {
    await pref.setBool('onboardingDone', true);
  }

  static bool getOnboardingDone() {
    return pref.getBool('onboardingDone') ?? false;
  }
}

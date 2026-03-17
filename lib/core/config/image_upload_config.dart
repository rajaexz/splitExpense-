import 'imgbb_key.dart';

/// Free image hosting via ImgBB (https://imgbb.com/)
/// Get your FREE API key at: https://api.imgbb.com/
/// Sign up free, no credit card required.
class ImageUploadConfig {
  static String get imgbbApiKey => imgbbApiKeyValue;

  static bool get isConfigured => imgbbApiKey.isNotEmpty;
}

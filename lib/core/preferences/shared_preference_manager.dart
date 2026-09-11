import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/shared_preferences_constants.dart';
import '../../data/api/server_environment.dart';
import '../../models/responses/auth/entity_detail_response.dart';
import '../../models/requests/get_vehicle_types_request.dart';

class SharedPreferenceManager {
  final SharedPreferences _prefs;

  SharedPreferenceManager(this._prefs);

  static Future<SharedPreferenceManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferenceManager(prefs);
  }

  // Server Environment
  String getCurrentServer() {
    return _prefs.getString(SharedPreferencesConstants.keyServerEnvironment) ??
        ServerEnvironment.production.value;
  }

  Future<bool> setCurrentServer(String serverEnvironment) {
    return _prefs.setString(
      SharedPreferencesConstants.keyServerEnvironment,
      serverEnvironment,
    );
  }

  ServerEnvironment getServerEnvironment() {
    return ServerEnvironment.fromValue(getCurrentServer());
  }

  Future<bool> setServerEnvironment(ServerEnvironment environment) {
    return setCurrentServer(environment.value);
  }

  // Local Base URL (IP address for local development)
  String getLocalBaseUrl() {
    return _prefs.getString(SharedPreferencesConstants.keyLocalBaseUrl) ??
        '192.168.1.1';
  }

  Future<bool> setLocalBaseUrl(String baseUrl) {
    return _prefs.setString(
      SharedPreferencesConstants.keyLocalBaseUrl,
      baseUrl,
    );
  }

  // Authorization Token
  String? getAuthorization() {
    return _prefs.getString(SharedPreferencesConstants.keyAuthorization);
  }

  Future<bool> setAuthorization(String token) {
    return _prefs.setString(SharedPreferencesConstants.keyAuthorization, token);
  }

  Future<bool> removeAuthorization() {
    return _prefs.remove(SharedPreferencesConstants.keyAuthorization);
  }

  // Device Token
  String? getDeviceToken() {
    return _prefs.getString(SharedPreferencesConstants.keyDeviceToken);
  }

  Future<bool> setDeviceToken(String token) {
    return _prefs.setString(SharedPreferencesConstants.keyDeviceToken, token);
  }

  Future<bool> removeDeviceToken() {
    return _prefs.remove(SharedPreferencesConstants.keyDeviceToken);
  }

  // Is Logged In
  bool isLoggedIn() {
    return _prefs.getBool(SharedPreferencesConstants.keyIsLoggedIn) ?? false;
  }

  Future<bool> setLoggedIn(bool isLoggedIn) {
    return _prefs.setBool(SharedPreferencesConstants.keyIsLoggedIn, isLoggedIn);
  }

  // Language
  String getLanguage() {
    return _prefs.getString(SharedPreferencesConstants.keyLanguage) ?? 'en';
  }

  Future<bool> setLanguage(String language) {
    return _prefs.setString(SharedPreferencesConstants.keyLanguage, language);
  }

  // Theme
  String getTheme() {
    return _prefs.getString(SharedPreferencesConstants.keyTheme) ?? 'system';
  }

  Future<bool> setTheme(String theme) {
    return _prefs.setString(SharedPreferencesConstants.keyTheme, theme);
  }

  // Clear all preferences
  Future<bool> clearAll() {
    return _prefs.clear();
  }

  // Clear auth data only
  Future<void> signOut() async {
    await removeAuthorization();
    await setLoggedIn(false);
    await setEntity(null);
  }

  // Entity
  Entity? getEntity() {
    final entityJson = _prefs.getString(SharedPreferencesConstants.keyEntity);
    if (entityJson == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(entityJson);
      return Entity.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<bool> setEntity(Entity? entity) {
    if (entity == null) {
      return _prefs.remove(SharedPreferencesConstants.keyEntity);
    }
    final entityJson = jsonEncode(entity.toJson());
    return _prefs.setString(SharedPreferencesConstants.keyEntity, entityJson);
  }

  // Setting
  Setting? getSetting() {
    final settingJson = _prefs.getString(SharedPreferencesConstants.keySetting);
    if (settingJson == null) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(settingJson);
      return Setting.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<bool> setSetting(Setting? setting) async {
    if (setting == null) {
      await _prefs.remove(SharedPreferencesConstants.keySetting);
      return true;
    }
    final settingJson = jsonEncode(setting.toJson());
    await _prefs.setString(SharedPreferencesConstants.keySetting, settingJson);

    // Also save splash_path separately if available
    if (setting.splashScreen?.splashPath != null) {
      await setSplashPath(setting.splashScreen!.splashPath!);
    }

    return true;
  }

  // Splash Path
  String? getSplashPath() {
    return _prefs.getString(SharedPreferencesConstants.keySplashPath);
  }

  Future<bool> setSplashPath(String splashPath) {
    return _prefs.setString(
      SharedPreferencesConstants.keySplashPath,
      splashPath,
    );
  }

  // Recent Addresses
  List<DestinationAddress> getRecentAddresses() {
    final jsonStr = _prefs.getString(SharedPreferencesConstants.keyRecentAddresses);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((json) => DestinationAddress.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> setRecentAddresses(List<DestinationAddress> addresses) {
    final jsonStr = jsonEncode(addresses.map((a) => a.toJson()).toList());
    return _prefs.setString(SharedPreferencesConstants.keyRecentAddresses, jsonStr);
  }

  Future<bool> addRecentAddress(DestinationAddress address) {
    final addresses = getRecentAddresses();

    // Remove if already exists (by placeId or address)
    addresses.removeWhere((a) =>
        (a.placeId != null && a.placeId == address.placeId) ||
        (a.address != null && a.address == address.address));

    // Add to beginning with isRecentAddress flag
    final recentAddress = DestinationAddress(
      address: address.address,
      addressType: address.addressType,
      city: address.city,
      country: address.country,
      countryCode: address.countryCode,
      latitude: address.latitude,
      longitude: address.longitude,
      note: address.note,
      placeId: address.placeId,
      postalCode: address.postalCode,
      title: address.title,
      selectedId: address.selectedId,
      isRecentAddress: true,
      metadata: address.metadata,
      name: address.name,
      phone: address.phone,
      type: address.type,
    );
    addresses.insert(0, recentAddress);

    // Keep only last 2
    while (addresses.length > 2) {
      addresses.removeLast();
    }

    return setRecentAddresses(addresses);
  }
}

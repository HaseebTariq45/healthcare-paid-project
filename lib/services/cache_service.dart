import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  // Default cache time is 5 minutes (300,000 milliseconds)
  static const int defaultCacheTime = 300000;
  
  // Check if cached data exists and is valid
  static Future<bool> isCacheValid(String key, {int? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('${key}_timestamp');
    
    if (timestamp == null) return false;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = currentTime - timestamp;
    
    return cacheAge < (maxAge ?? defaultCacheTime);
  }
  
  // Get cached data if it exists and is valid
  static Future<Map<String, dynamic>?> getData(String key, {int? maxAge}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if cache is valid
    if (!await isCacheValid(key, maxAge: maxAge)) {
      return null;
    }
    
    final data = prefs.getString(key);
    if (data == null) return null;
    
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding cached data: $e');
      return null;
    }
  }
  
  // Save data to cache
  static Future<bool> saveData(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Save the data
      final success = await prefs.setString(key, json.encode(data));
      
      // Update timestamp
      if (success) {
        await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      }
      
      return success;
    } catch (e) {
      print('Error saving data to cache: $e');
      return false;
    }
  }
  
  // Clear specific cache
  static Future<bool> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    
    final dataRemoved = await prefs.remove(key);
    final timestampRemoved = await prefs.remove('${key}_timestamp');
    
    return dataRemoved && timestampRemoved;
  }
  
  // Clear all cache
  static Future<bool> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
} 
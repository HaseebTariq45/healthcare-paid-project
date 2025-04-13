import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CacheService {
  // Default cache time is 5 minutes (300,000 milliseconds)
  static const int defaultCacheTime = 300000;
  
  // Longer-lived cache time (1 day) for more stable data
  static const int longCacheTime = 86400000;
  
  // Singleton instance for better performance
  static SharedPreferences? _prefsInstance;
  
  // Initialize shared preferences instance
  static Future<SharedPreferences> get _prefs async {
    if (_prefsInstance == null) {
      _prefsInstance = await SharedPreferences.getInstance();
    }
    return _prefsInstance!;
  }
  
  // Check if cached data exists and is valid
  static Future<bool> isCacheValid(String key, {int? maxAge}) async {
    try {
      final prefs = await _prefs;
      final timestamp = prefs.getInt('${key}_timestamp');
      
      if (timestamp == null) return false;
      
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = currentTime - timestamp;
      
      return cacheAge < (maxAge ?? defaultCacheTime);
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
  }
  
  // Get cached data if it exists and is valid
  static Future<Map<String, dynamic>?> getData(String key, {int? maxAge}) async {
    try {
      final prefs = await _prefs;
      
      // Check if cache is valid
      if (!await isCacheValid(key, maxAge: maxAge)) {
        return null;
      }
      
      final data = prefs.getString(key);
      if (data == null) return null;
      
      try {
        return json.decode(data) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error decoding cached data: $e');
        // If data is corrupted, clear it
        await clearCache(key);
        return null;
      }
    } catch (e) {
      debugPrint('Error retrieving cache data: $e');
      return null;
    }
  }
  
  // Save data to cache
  static Future<bool> saveData(String key, Map<String, dynamic> data, {int? expiry}) async {
    try {
      final prefs = await _prefs;
      
      // Encode the data - use compute for larger datasets to avoid UI jank
      String encodedData;
      if (data.length > 100) {
        encodedData = await compute(_encodeJson, data);
      } else {
        encodedData = json.encode(data);
      }
      
      // Save the data
      final success = await prefs.setString(key, encodedData);
      
      // Update timestamp
      if (success) {
        await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
        
        // Set expiry if provided
        if (expiry != null) {
          await prefs.setInt('${key}_expiry', expiry);
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving data to cache: $e');
      return false;
    }
  }
  
  // Helper method to encode JSON in a separate isolate
  static String _encodeJson(Map<String, dynamic> data) {
    return json.encode(data);
  }
  
  // Clear specific cache
  static Future<bool> clearCache(String key) async {
    try {
      final prefs = await _prefs;
      
      final dataRemoved = await prefs.remove(key);
      final timestampRemoved = await prefs.remove('${key}_timestamp');
      await prefs.remove('${key}_expiry');
      
      return dataRemoved && timestampRemoved;
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      return false;
    }
  }
  
  // Clear all cache
  static Future<bool> clearAllCache() async {
    try {
      final prefs = await _prefs;
      return await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
      return false;
    }
  }
  
  // Get all cache keys
  static Future<List<String>> getAllCacheKeys() async {
    try {
      final prefs = await _prefs;
      return prefs.getKeys().where((key) => !key.endsWith('_timestamp') && !key.endsWith('_expiry')).toList();
    } catch (e) {
      debugPrint('Error getting cache keys: $e');
      return [];
    }
  }
  
  // Check cache size
  static Future<int> getCacheSize() async {
    try {
      final prefs = await _prefs;
      int totalSize = 0;
      
      for (String key in prefs.getKeys()) {
        if (!key.endsWith('_timestamp') && !key.endsWith('_expiry')) {
          final data = prefs.getString(key);
          if (data != null) {
            totalSize += data.length;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }
  
  // Remove expired cache entries
  static Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await _prefs;
      final now = DateTime.now().millisecondsSinceEpoch;
      final keys = prefs.getKeys().where((key) => !key.endsWith('_timestamp') && !key.endsWith('_expiry')).toList();
      
      for (String key in keys) {
        final timestamp = prefs.getInt('${key}_timestamp');
        if (timestamp != null) {
          final expiry = prefs.getInt('${key}_expiry') ?? defaultCacheTime;
          if (now - timestamp > expiry) {
            await clearCache(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired cache: $e');
    }
  }
} 
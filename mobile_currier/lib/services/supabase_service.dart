import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://bqbjtvdaajyzjxwkbhxj.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_GrEfXg3y0auXH-mkgk6iNg_9CdhoHAL';

  static final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  static Future<String?> uploadDeliveryPhoto(String filePath) async {
    try {
      debugPrint('[SupabaseService] Starting upload for file: $filePath');
      debugPrint('[SupabaseService] Is Web: $kIsWeb');

      Uint8List fileBytes;

      if (kIsWeb) {
        // Web: Blob URL - use http to fetch bytes
        debugPrint('[SupabaseService] Using web upload method');
        final response = await http.get(Uri.parse(filePath));
        fileBytes = response.bodyBytes;
        debugPrint('[SupabaseService] Web fetch successful, bytes length: ${fileBytes.length}');
      } else {
        // Mobile: Read file from path
        debugPrint('[SupabaseService] Using mobile file method');
        fileBytes = await File(filePath).readAsBytes();
        debugPrint('[SupabaseService] Mobile file read successful, bytes length: ${fileBytes.length}');
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getExtension(filePath);
      final fileName = '$timestamp$extension';

      debugPrint('[SupabaseService] Uploading to Supabase with filename: $fileName');

      // Upload to Supabase
      final response = await client.storage
          .from('delivery-photos')
          .uploadBinary(fileName, fileBytes);

      debugPrint('[SupabaseService] Upload response: $response');

      if (response != null) {
        // Get public URL
        final publicUrl = client.storage.from('delivery-photos').getPublicUrl(fileName);
        debugPrint('[SupabaseService] Public URL: $publicUrl');
        return publicUrl;
      }

      return null;
    } catch (e) {
      debugPrint('[SupabaseService] Upload failed: $e');
      return null;
    }
  }

  static String _getExtension(String filePath) {
    // Handle both mobile path and web Blob URL
    if (filePath.contains('.')) {
      final parts = filePath.split('.');
      if (parts.isNotEmpty) {
        return '.${parts.last.split('?').first}';
      }
    }
    return '.jpg'; // default extension
  }
}
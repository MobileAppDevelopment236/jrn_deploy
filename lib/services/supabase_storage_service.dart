// FIXED: supabase_storage_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SupabaseStorageService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // EXISTING FILE UPLOAD FUNCTIONALITY (UNCHANGED - KEEP AS IS)
  // ===========================================================================

  /// Upload a single document with enhanced error handling and timeout
  static Future<String> uploadDocument({
    required String fileName,
    required Uint8List fileBytes,
    required String applicationId,
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        debugPrint('🔄 Uploading document: $fileName (Attempt ${attempt + 1})');

        // Create unique file path with better naming
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeFileName = _sanitizeFileName(fileName);
        final filePath = 'applications/$applicationId/${timestamp}_${_generateUniqueId()}_$safeFileName';

        // Upload with timeout and better error handling
        final uploadFuture = _client.storage
            .from('VISA-DOCUMENTS')
            .uploadBinary(filePath, fileBytes);

        await uploadFuture.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            throw TimeoutException('Upload timed out for $fileName');
          },
        );

        // Get public URL with validation
        final String publicUrl = _client.storage
            .from('VISA-DOCUMENTS')
            .getPublicUrl(filePath);

        debugPrint('✅ Successfully uploaded: $fileName');
        debugPrint('📎 Download URL: $publicUrl');

        return publicUrl;
      } on TimeoutException catch (e) {
        debugPrint('⏰ Timeout uploading $fileName: $e');
        attempt++;
        if (attempt > maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on StorageException catch (e) {
        debugPrint('📦 Storage error uploading $fileName: $e');
        attempt++;
        if (attempt > maxRetries) {
          throw Exception('Storage error for $fileName: ${e.message}');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('❌ Error uploading $fileName: $e');
        attempt++;
        if (attempt > maxRetries) {
          throw Exception('Failed to upload $fileName after $maxRetries attempts: ${e.toString()}');
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Unexpected error in uploadDocument');
  }

  /// Enhanced upload with progress tracking and better error handling
  static Future<List<Map<String, dynamic>>> uploadMultipleDocuments({
    required List<Map<String, dynamic>> documents,
    required String applicationId,
    Function(int, int)? onProgress,
  }) async {
    final List<Map<String, dynamic>> uploadResults = [];
    int completed = 0;

    debugPrint('🚀 Starting bulk document upload for application: $applicationId');
    debugPrint('📁 Total documents to upload: ${documents.length}');

    for (final doc in documents) {
      try {
        // Update progress
        if (onProgress != null) {
          onProgress(completed, documents.length);
        }

        final downloadUrl = await uploadDocument(
          fileName: doc['fileName'] as String,
          fileBytes: doc['fileBytes'] as Uint8List,
          applicationId: applicationId,
        );

        uploadResults.add({
          'fileName': doc['fileName'],
          'downloadUrl': downloadUrl,
          'status': 'success',
        });

        completed++;
      } catch (e) {
        debugPrint('❌ Failed to upload ${doc['fileName']}: $e');
        uploadResults.add({
          'fileName': doc['fileName'],
          'downloadUrl': '',
          'status': 'failed',
          'error': e.toString(),
        });
        completed++;
      }

      // Small delay between uploads to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final successfulCount = uploadResults.where((r) => r['status'] == 'success').length;
    debugPrint('✅ Bulk upload completed. Successful: $successfulCount/${documents.length}');

    return uploadResults;
  }

  /// Helper method to sanitize file names
  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
  }

  /// Helper to generate unique ID for file naming
  static String _generateUniqueId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }

  /// Verify bucket access with better error reporting
  static Future<bool> verifyBucketAccess() async {
    try {
      await _client.storage.from('VISA-DOCUMENTS').list();
      debugPrint('✅ Visa documents bucket is accessible');
      return true;
    } catch (e) {
      debugPrint('❌ Cannot access VISA-DOCUMENTS bucket: $e');
      return false;
    }
  }

  /// Get file info including upload status
  static Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final files = await _client.storage.from('VISA-DOCUMENTS').list(
        path: filePath,
      );

      if (files.isNotEmpty) {
        final file = files.first;

        // 'size' is NOT a default property — we assume size is in metadata or unavailable
        return {
          'exists': true,
          'name': file.name,
          'size': file.metadata?['size'] ?? 'Unknown',
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting file info: $e');
      return null;
    }
  }

  /// Test method to verify bucket connectivity
  static Future<void> testBucketConnection() async {
    try {
      debugPrint('🔍 Testing connection to VISA-DOCUMENTS bucket...');
      
      // Test bucket access
      final canAccess = await verifyBucketAccess();
      if (canAccess) {
        debugPrint('✅ Bucket access verified successfully');
      } else {
        debugPrint('❌ Cannot access bucket - check permissions');
      }
      
      // Test small file upload
      final testBytes = Uint8List.fromList([65, 66, 67, 68]); // "ABCD"
      try {
        final testUrl = await uploadDocument(
          fileName: 'test_file.txt',
          fileBytes: testBytes,
          applicationId: 'test-connection',
          maxRetries: 1,
        );
        debugPrint('✅ Test upload successful: $testUrl');
        
        // Try to delete test file
        try {
          await _client.storage.from('VISA-DOCUMENTS').remove(['applications/test-connection/test_file.txt']);
          debugPrint('✅ Test file cleaned up');
        } catch (e) {
          debugPrint('⚠️ Test file cleanup failed: $e');
        }
      } catch (e) {
        debugPrint('❌ Test upload failed: $e');
      }
      
    } catch (e) {
      debugPrint('💥 Bucket connection test failed: $e');
    }
  }

  // ===========================================================================
  // UPDATED EMAIL FUNCTIONALITY - ADDED RECEIPT_URL PARAMETER
  // ===========================================================================

  /// Send visa application email using Supabase Edge Function
  static Future<bool> sendApplicationEmail({
    required String subject,
    required String body,
    required List<String> toEmails,
    required List<String> ccEmails,
    required String applicationId,
    String? receiptUrl, // NEW: Added receipt URL parameter
    
  }) async {
    try {
      debugPrint('🚀 STARTING EMAIL PROCESS...');
      debugPrint('📧 TO: ${toEmails.join(', ')}');
      debugPrint('📧 CC: ${ccEmails.join(', ')}');
      debugPrint('📋 SUBJECT: $subject');
      debugPrint('🆔 APPLICATION ID: $applicationId');
      if (receiptUrl != null) {
        debugPrint('🧾 RECEIPT URL: $receiptUrl');
      }

      // STEP 1: Try Edge Function First
      debugPrint('1️⃣ Attempting Edge Function...');
      final edgeFunctionResult = await _callEdgeFunction(
        subject: subject,
        body: body,
        toEmails: toEmails,
        ccEmails: ccEmails,
        applicationId: applicationId,
        receiptUrl: receiptUrl, // NEW: Pass receipt URL
      );

      if (edgeFunctionResult) {
        return true;
      }

      // STEP 2: Fallback to Device Email App
      debugPrint('2️⃣ Edge Function failed, trying device email app...');
      final deviceEmailResult = await _openDeviceEmailApp(
        subject: subject,
        body: body,
        toEmails: toEmails,
        ccEmails: ccEmails,
      );

      if (deviceEmailResult) {
        return true;
      }

      // STEP 3: Final Fallback - Log for Manual Sending
      debugPrint('3️⃣ All methods failed, logging for manual sending...');
      _logEmailForManualSending(subject, body, toEmails, ccEmails, applicationId, receiptUrl);
      return false;

    } catch (e) {
      debugPrint('💥 CRITICAL: All email methods failed: $e');
      _logEmailForManualSending(subject, body, toEmails, ccEmails, applicationId, receiptUrl);
      return false;
    }
  }

  /// FIXED: Call Supabase Edge Function for email sending
  static Future<bool> _callEdgeFunction({
    required String subject,
    required String body,
    required List<String> toEmails,
    required List<String> ccEmails,
    required String applicationId,
    String? receiptUrl, // NEW: Added receipt URL parameter
  }) async {
    try {
      debugPrint('📡 Calling Edge Function: send-visa-email');
      
      // Prepare request body with all parameters
      final Map<String, dynamic> requestBody = {
        'subject': subject,
        'body': body,
        'to_emails': toEmails,
        'cc_emails': ccEmails,
        'application_id': applicationId,
      };
      
      // Add receipt_url only if provided
      if (receiptUrl != null && receiptUrl.isNotEmpty) {
        requestBody['receipt_url'] = receiptUrl;
      }

      final response = await _client.functions.invoke(
        'send-visa-email',
        body: requestBody,
      );

      if (response.status == 200) {
        debugPrint('✅ SUCCESS: Edge Function sent email');
        return true;
      } else {
        debugPrint('❌ FAILED: Edge Function returned status ${response.status}');
        debugPrint('Error details: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ERROR: Edge Function call failed: $e');
      return false;
    }
  }

  /// Fallback: Open device email app
  static Future<bool> _openDeviceEmailApp({
    required String subject,
    required String body,
    required List<String> toEmails,
    required List<String> ccEmails,
  }) async {
    try {
      debugPrint('📱 Opening device email app...');
      
      final mailtoUri = Uri(
        scheme: 'mailto',
        path: toEmails.join(','),
        queryParameters: {
          'cc': ccEmails.join(','),
          'subject': subject,
          'body': body,
        },
      ).toString();

      if (await canLaunchUrl(Uri.parse(mailtoUri))) {
        await launchUrl(Uri.parse(mailtoUri));
        debugPrint('✅ SUCCESS: Device email app opened');
        return true;
      } else {
        debugPrint('❌ FAILED: Cannot launch device email app');
        return false;
      }
    } catch (e) {
      debugPrint('❌ ERROR: Device email app failed: $e');
      return false;
    }
  }

  /// Final fallback: Log email content for manual sending
  static void _logEmailForManualSending(
    String subject,
    String body,
    List<String> toEmails,
    List<String> ccEmails,
    String applicationId,
    String? receiptUrl, // NEW: Added receipt URL parameter
  ) {
    debugPrint('=' * 70);
    debugPrint('📧 MANUAL EMAIL SENDING REQUIRED');
    debugPrint('=' * 70);
    debugPrint('TO: ${toEmails.join(', ')}');
    debugPrint('CC: ${ccEmails.join(', ')}');
    debugPrint('APPLICATION ID: $applicationId');
    if (receiptUrl != null) {
      debugPrint('RECEIPT URL: $receiptUrl');
    }
    debugPrint('SUBJECT: $subject');
    debugPrint('BODY CONTENT:');
    debugPrint(body);
    debugPrint('=' * 70);
    debugPrint('Please copy the above content and send manually to:');
    debugPrint('TO: srinuk236@gmail.com, srinuk236.anna@gmail.com');
    debugPrint('CC: sreeniielts@gmail.com, gayatrilakshmibhavani@gmail.com');
    debugPrint('=' * 70);
  }
}
// lib/services/database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ===========================================================================
  // APPLICATION METHODS
  // ===========================================================================

  /// Create new application in database
  static Future<Map<String, dynamic>> createApplication({
    required String applicationId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String visaType,
    required String destinationCountry,
    required DateTime? travelDate,
    required DateTime? returnDate,
    required int totalPassengers,
    required String? previousRefusal,
    required String? refusalDetails,
  }) async {
    try {
      final response = await _client
          .from('applications')
          .insert({
            'application_id': applicationId,
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone': phone,
            'visa_type': visaType,
            'destination_country': destinationCountry,
            'travel_date': travelDate?.toIso8601String(),
            'return_date': returnDate?.toIso8601String(),
            'total_passengers': totalPassengers,
            'previous_refusal': previousRefusal,
            'refusal_details': refusalDetails,
            'status': 'submitted',
            'current_stage': 1,
          })
          .select()
          .single();

      // Create initial tracking stages
      await _createInitialTrackingStages(response['id'] as String);
      
      return response;
    } catch (e) {
      throw Exception('Failed to create application: $e');
    }
  }

  /// Get application by ID
  static Future<Map<String, dynamic>?> getApplication(String applicationId) async {
    try {
      final response = await _client
          .from('applications')
          .select()
          .eq('application_id', applicationId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  /// Get application by ID and email (for tracking)
  static Future<Map<String, dynamic>?> getApplicationForTracking({
    required String applicationId,
    required String email,
  }) async {
    try {
      final response = await _client
          .from('applications')
          .select()
          .eq('application_id', applicationId)
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch application for tracking: $e');
    }
  }

  // ===========================================================================
  // TRACKING STAGES METHODS
  // ===========================================================================

  /// Create initial tracking stages for new application
  static Future<void> _createInitialTrackingStages(String applicationUuid) async {
    final stages = [
      {
        'stage_number': 1,
        'stage_name': 'Application Info',
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      },
      {
        'stage_number': 2,
        'stage_name': 'Payment Info',
        'status': 'pending',
      },
      {
        'stage_number': 3,
        'stage_name': 'Application Process',
        'status': 'pending',
      },
      {
        'stage_number': 4,
        'stage_name': 'Submission Stage',
        'status': 'pending',
      },
      {
        'stage_number': 5,
        'stage_name': 'Final Decision',
        'status': 'pending',
      },
    ];

    for (final stage in stages) {
      await _client
          .from('tracking_stages')
          .insert({
            ...stage,
            'application_id': applicationUuid,
          });
    }
  }

  /// Get tracking stages for application - FIXED TYPE CASTING
  static Future<List<Map<String, dynamic>>> getTrackingStages(String applicationUuid) async {
    try {
      final response = await _client
          .from('tracking_stages')
          .select()
          .eq('application_id', applicationUuid)
          .order('stage_number');

      // FIX: Explicit type casting
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('❌ Error fetching tracking stages: $e', name: 'DatabaseService');
      throw Exception('Failed to fetch tracking stages: $e');
    }
  }

  /// Update tracking stage status
  static Future<void> updateTrackingStage({
    required String applicationUuid,
    required int stageNumber,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _client
          .from('tracking_stages')
          .update(updateData)
          .eq('application_id', applicationUuid)
          .eq('stage_number', stageNumber);

      // Update application current_stage if moving forward
      if (status == 'completed' && stageNumber < 5) {
        await _client
            .from('applications')
            .update({
              'current_stage': stageNumber + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', applicationUuid);
      }
    } catch (e) {
      throw Exception('Failed to update tracking stage: $e');
    }
  }

  // ===========================================================================
  // PAYMENT METHODS
  // ===========================================================================

  /// Create payment record - FIXED PAYMENT STATUS
static Future<Map<String, dynamic>> createPayment({
  required String applicationUuid,
  required double amount,
  required String paymentMethod,
  String? receiptUrl,
  String? upiTransactionId,
}) async {
  try {
    // Determine correct payment status
    String paymentStatus;
    if (paymentMethod == 'payLater') {
      paymentStatus = 'pending'; // Pay Later should be pending, not completed
    } else if (receiptUrl != null && receiptUrl.isNotEmpty) {
      paymentStatus = 'completed'; // UPI with receipt is completed
    } else {
      paymentStatus = 'pending'; // Default to pending
    }

    final response = await _client
        .from('payments')
        .insert({
          'application_id': applicationUuid,
          'amount': amount,
          'payment_method': paymentMethod,
          'status': paymentStatus, // ← FIXED: Use correct status
          'receipt_url': receiptUrl,
          'upi_transaction_id': upiTransactionId,
        })
        .select()
        .single();

    // Update tracking stage ONLY if payment is actually completed
    if (paymentStatus == 'completed') {
      await updateTrackingStage(
        applicationUuid: applicationUuid,
        stageNumber: 2,
        status: 'completed',
        notes: 'Payment completed via $paymentMethod',
      );
    } else if (paymentMethod == 'payLater') {
      // For Pay Later, set stage to in_progress (waiting for payment)
      await updateTrackingStage(
        applicationUuid: applicationUuid,
        stageNumber: 2,
        status: 'in_progress',
        notes: 'Payment scheduled for later - awaiting payment',
      );
    }

    return response;
  } catch (e) {
    throw Exception('Failed to create payment: $e');
  }
}

  /// Update payment status
  static Future<void> updatePaymentStatus({
    required String paymentUuid,
    required String status,
    String? receiptUrl,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (receiptUrl != null) {
        updateData['receipt_url'] = receiptUrl;
      }

      await _client
          .from('payments')
          .update(updateData)
          .eq('id', paymentUuid);
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  /// Get payment by application ID
  static Future<Map<String, dynamic>?> getPayment(String applicationUuid) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('application_id', applicationUuid)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  // Add to DatabaseService class
static Future<void> savePaymentReceipt({
  required String applicationId,
  required String receiptUrl,
  required String fileName,
  required int fileSize,
  required DateTime uploadDate,
}) async {
  try {
    final client = Supabase.instance.client;
    
    await client.from('payment_receipts').insert({
      'application_id': applicationId,
      'receipt_url': receiptUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'uploaded_at': uploadDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    debugPrint('Error saving payment receipt: $e');
    rethrow;
  }
}

  // ===========================================================================
  // DOCUMENT METHODS
  // ===========================================================================

  /// Save document record to database
  static Future<Map<String, dynamic>> saveDocument({
    required String applicationUuid,
    required String documentName,
    required String documentType,
    required int fileSize,
    required String downloadUrl,
  }) async {
    try {
      final response = await _client
          .from('application_documents')
          .insert({
            'application_id': applicationUuid,
            'document_name': documentName,
            'document_type': documentType,
            'file_size': fileSize,
            'download_url': downloadUrl,
            'upload_status': 'uploaded',
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save document: $e');
    }
  }

  /// Get documents for application - FIXED TYPE CASTING
  static Future<List<Map<String, dynamic>>> getApplicationDocuments(String applicationUuid) async {
    try {
      final response = await _client
          .from('application_documents')
          .select()
          .eq('application_id', applicationUuid)
          .order('created_at');

      // FIX: Explicit type casting
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('❌ Error fetching documents: $e', name: 'DatabaseService');
      throw Exception('Failed to fetch documents: $e');
    }
  }

  // ===========================================================================
  // APPLICATION STATUS METHODS
  // ===========================================================================

  /// Update application status
  static Future<void> updateApplicationStatus({
    required String applicationUuid,
    required String status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('applications')
          .update(updateData)
          .eq('id', applicationUuid);

      // Update tracking stages based on status
      await _updateStagesBasedOnStatus(applicationUuid, status);
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  /// Update tracking stages based on application status
  static Future<void> _updateStagesBasedOnStatus(String applicationUuid, String status) async {
    switch (status) {
      case 'payment_pending':
        await updateTrackingStage(
          applicationUuid: applicationUuid,
          stageNumber: 2,
          status: 'in_progress',
          notes: 'Waiting for payment',
        );
        break;
      case 'under_review':
        await updateTrackingStage(
          applicationUuid: applicationUuid,
          stageNumber: 3,
          status: 'in_progress',
          notes: 'Application under review',
        );
        break;
      case 'approved':
        await updateTrackingStage(
          applicationUuid: applicationUuid,
          stageNumber: 5,
          status: 'completed',
          notes: 'Visa approved',
        );
        break;
      case 'rejected':
        await updateTrackingStage(
          applicationUuid: applicationUuid,
          stageNumber: 5,
          status: 'completed',
          notes: 'Visa rejected',
        );
        break;
    }
  }

  // ===========================================================================
  // SIMPLE ERROR HANDLING METHODS
  // ===========================================================================

  /// Simple validation for application data
  static List<String> validateApplicationData({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) {
    final errors = <String>[];

    if (firstName.isEmpty) {
      errors.add('First name is required');
    }

    if (lastName.isEmpty) {
      errors.add('Last name is required');
    }

    if (email.isEmpty) {
      errors.add('Email is required');
    }

    if (phone.isEmpty) {
      errors.add('Phone number is required');
    }

    return errors;
  }

  /// Check if application ID already exists
  static Future<bool> applicationIdExists(String applicationId) async {
    try {
      final response = await _client
          .from('applications')
          .select('application_id')
          .eq('application_id', applicationId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
 /// Save passport details for each passenger
static Future<void> savePassportDetails({
  required String applicationUuid,
  required String passengerName,
  required String passportNumber,
  required String dateOfBirth,
  required String issueDate,
  required String expiryDate,
  required String issuingAuthority,
  required int passengerIndex,
}) async {
  try {
    await _client
        .from('passport_details')
        .insert({
          'application_id': applicationUuid,
          'passenger_name': passengerName,
          'passport_number': passportNumber,
          'date_of_birth': dateOfBirth,
          'issue_date': issueDate,
          'expiry_date': expiryDate,
          'issuing_authority': issuingAuthority,
          'passenger_index': passengerIndex,
        });
  } catch (e) {
    throw Exception('Failed to save passport details: $e');
  }
}
}
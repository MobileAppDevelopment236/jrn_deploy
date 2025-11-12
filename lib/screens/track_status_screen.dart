import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jrr_immigration_app/services/database_service.dart';

class TrackStatusScreen extends StatefulWidget {
  const TrackStatusScreen({super.key});

  @override
  State<TrackStatusScreen> createState() => _TrackStatusScreenState();
}

class _TrackStatusScreenState extends State<TrackStatusScreen> {
  final TextEditingController _applicationIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // Removed unused phoneController since we're using mock data
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _hasSearched = false;
  
  // Mock application data - In real app, this would come from backend
  Map<String, dynamic>? _applicationData;
  
  // Tracking stages as per client requirement
  final List<TrackingStage> _trackingStages = [
    TrackingStage(
      title: 'Application Info',
      description: 'Applicant details & documents',
      icon: Icons.person,
      status: StageStatus.pending,
    ),
    TrackingStage(
      title: 'Payment Info', 
      description: 'Fee payment details',
      icon: Icons.payment,
      status: StageStatus.pending,
    ),
    TrackingStage(
      title: 'Application Process',
      description: 'Under review & processing',
      icon: Icons.assignment,
      status: StageStatus.pending,
    ),
    TrackingStage(
      title: 'Submission Stage', 
      description: 'Application completed',
      icon: Icons.send,
      status: StageStatus.pending,
    ),
    TrackingStage(
      title: 'Final Decision',
      description: 'Visa approval/rejection',
      icon: Icons.verified,
      status: StageStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Application Status',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Section
            _buildSearchSection(),
            
            const SizedBox(height: 24),
            
            if (_hasSearched && _applicationData != null) ...[
              // Application Status Display
              _buildApplicationStatus(),
              const SizedBox(height: 16),
              _buildTrackingStages(),
              const SizedBox(height: 16),
              _buildApplicationDetails(),
            ] else if (_hasSearched) ...[
              // No application found
              _buildNotFoundMessage(),
            ] else ...[
              // Welcome message
              _buildWelcomeMessage(),
            ],
          ],
        ),
      ),
    );
  }

  

Widget _buildSearchSection() {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Track Your Application',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 12),
            
            // Responsive form layout
LayoutBuilder(
  builder: (context, constraints) {
    final bool isWideScreen = constraints.maxWidth > 600;
    
    if (isWideScreen) {
      // Wide screen - horizontal layout
      return Row(
        children: [
          // Application ID Field
          Expanded(
            child: TextFormField(
              controller: _applicationIdController,
              decoration: const InputDecoration(
                labelText: 'Application ID',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true, // Reduces height slightly to prevent cutting
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Email Field
          Expanded(
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true, // Reduces height slightly to prevent cutting
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (!_isValidEmail(value)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Search Button
          SizedBox(
            width: 100, // Fixed width for button
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Search',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      );
    } else {
      // Narrow screen - vertical layout
      return Column(
        children: [
          // Application ID Field
          TextFormField(
            controller: _applicationIdController,
            decoration: const InputDecoration(
              labelText: 'Application ID',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              if (!_isValidEmail(value)) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _searchApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Search',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      );
    }
  },
),
            
            
            // Error messages display area
            if (_formKey.currentState?.validate() == false) ...[
              const SizedBox(height: 8),
              Text(
                'Please fix the errors above',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
  Widget _buildApplicationStatus() {
    final status = _applicationData!['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 40, color: statusColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application Status',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _formatStatus(status),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusDetail('Application ID', _applicationData!['id']),
                _buildStatusDetail('Submitted Date', _applicationData!['submittedDate']),
                _buildStatusDetail('Visa Type', _applicationData!['visaType']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Replace your entire _buildTrackingStages() method with this:

Widget _buildTrackingStages() {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Progress',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 12),
          
          // Horizontal Scrollable Stages
          SizedBox(
            height: 120, // Fixed height for horizontal view
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _trackingStages.asMap().entries.map((entry) {
                final index = entry.key;
                final stage = entry.value;
                return _buildHorizontalStage(stage, index);
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHorizontalStage(TrackingStage stage, int index) {
  return Container(
    width: 140, // Fixed width for each stage
    margin: EdgeInsets.only(
      right: index < _trackingStages.length - 1 ? 8 : 0,
    ),
    child: Column(
      children: [
        // Stage indicator with number
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStageColor(stage.status),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getStageBorderColor(stage.status),
                  width: 2,
                ),
              ),
            ),
            Text(
              '${index + 1}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Stage title
        Text(
          stage.title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getStageColor(stage.status),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        
        // Stage status
        Text(
          _getStageStatusText(stage.status),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        
        // Completion date if available
        if (stage.completedDate != null) ...[
          const SizedBox(height: 4),
          Text(
            DateFormat('dd MMM').format(stage.completedDate!),
            style: GoogleFonts.inter(
              fontSize: 9,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    ),
  );
}

String _getStageStatusText(StageStatus status) {
  switch (status) {
    case StageStatus.completed:
      return 'Completed';
    case StageStatus.inProgress:
      return 'In Progress';
    case StageStatus.pending:
      return 'Pending';
  }
}

  Widget _buildTimelineRow(TrackingStage stage, int index, bool isLast) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getStageColor(stage.status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStageBorderColor(stage.status),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getStageIcon(stage.status),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: _getTimelineColor(index),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Stage content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStageBackgroundColor(stage.status),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStageBorderColor(stage.status),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(stage.icon, color: _getStageColor(stage.status)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: _getStageColor(stage.status),
                            ),
                          ),
                          Text(
                            stage.description,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (stage.completedDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Completed: ${DateFormat('dd MMM yyyy').format(stage.completedDate!)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicationDetails() {
  // Safely get all values with fallbacks
  final applicantName = _applicationData!['applicantName']?.toString() ?? 'Not provided';
  //final passportNumber = _applicationData!['passportNumber']?.toString() ?? 'Not provided';
  final destinationCountry = _applicationData!['destinationCountry']?.toString() ?? 'Not provided';
  final visaType = _applicationData!['visaType']?.toString() ?? 'Not provided';
  final applicationFee = _applicationData!['applicationFee']?.toString() ?? 'Not paid';
  final paymentStatus = _applicationData!['paymentStatus']?.toString() ?? 'pending';
  final documentsCount = _applicationData!['documentsCount']?.toString() ?? '0 documents';
  final lastUpdated = _applicationData!['lastUpdated']?.toString() ?? 'Not available';
  final notes = _applicationData!['notes']?.toString();

  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow('Applicant Name', applicantName),
          _buildDetailRow('Destination Country', destinationCountry),
          _buildDetailRow('Visa Type', visaType),
          _buildDetailRow('Application Fee', applicationFee),
          _buildDetailRow('Payment Status', paymentStatus),
          _buildDetailRow('Documents Uploaded', documentsCount),
          _buildDetailRow('Last Updated', lastUpdated),
          
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: GoogleFonts.inter(
                        color: Colors.orange[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildNotFoundMessage() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Application Not Found',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No application found with the provided ID and email. Please check your details and try again.',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _hasSearched = false;
                  });
                },
                child: Text(
                  'Search Again',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.track_changes,
              size: 64,
              color: const Color(0xFF1E88E5).withOpacity(0.7), // This is fine for now
            ),
            const SizedBox(height: 16),
            Text(
              'Track Your Visa Application',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E88E5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your Application ID to check the current status and track progress through all stages of your visa application.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildFeatureRow('Real-time application tracking'),
            _buildFeatureRow('5-stage progress visualization'),
            _buildFeatureRow('Document upload status'),
            _buildFeatureRow('Payment status monitoring'),
            _buildFeatureRow('Estimated timeline updates'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: Color(0xFF1E88E5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchApplication() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
    _applicationData = null;
  });

  try {
    final applicationId = _applicationIdController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    debugPrint('🔍 Searching for application: $applicationId, email: $email');

    // REAL API call to database
    final applicationData = await DatabaseService.getApplicationForTracking(
      applicationId: applicationId,
      email: email,
    );

    _logDatabaseResponse(applicationData); 

    if (applicationData != null && applicationData.isNotEmpty) {
      final applicationUuid = applicationData['id'] as String;
      
      debugPrint('✅ Application found, fetching additional data...');
      
      try {
        // Get all related data with proper type handling
        final trackingStages = await DatabaseService.getTrackingStages(applicationUuid);
        final paymentData = await DatabaseService.getPayment(applicationUuid);
        final documents = await DatabaseService.getApplicationDocuments(applicationUuid);
        // Ensure proper type casting
        final List<Map<String, dynamic>> typedTrackingStages = 
            (trackingStages as List).cast<Map<String, dynamic>>();
        final List<Map<String, dynamic>> typedDocuments = 
            (documents as List).cast<Map<String, dynamic>>();

        debugPrint('📊 Data retrieved - Stages: ${typedTrackingStages.length}, Payment: ${paymentData != null ? 'Yes' : 'No'}, Documents: ${typedDocuments.length}');

        // Format the data for display
        final formattedData = _formatApplicationData(
          applicationData, 
          typedTrackingStages, 
          paymentData, 
          typedDocuments
        );
        
        // Update UI with real data
        setState(() {
          _applicationData = formattedData;
          _updateTrackingStagesFromDatabase(typedTrackingStages);
        });
        
        debugPrint('✅ Application data loaded successfully');
      } catch (e) {
        debugPrint('💥 Error fetching related data: $e');
        throw Exception('Failed to load application details: $e');
      }
    } else {
      // No application found
      debugPrint('❌ No application found with provided details');
      setState(() {
        _applicationData = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No application found with the provided Application ID and Email'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
  } catch (e) {
    debugPrint('💥 Error searching application: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching application: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }
}

// ADD THIS NEW METHOD - Place it inside _TrackStatusScreenState class
void _logDatabaseResponse(Map<String, dynamic>? applicationData) {
  if (applicationData == null) {
    debugPrint('📭 Database returned null application data');
    return;
  }
  
  debugPrint('📋 APPLICATION DATA FROM DATABASE:');
  debugPrint('  - ID: ${applicationData['id']}');
  debugPrint('  - Application ID: ${applicationData['application_id']}');
  debugPrint('  - Name: ${applicationData['first_name']} ${applicationData['last_name']}');
  debugPrint('  - Email: ${applicationData['email']}');
  debugPrint('  - Status: ${applicationData['status']}');
  debugPrint('  - Visa Type: ${applicationData['visa_type']}');
  debugPrint('  - Country: ${applicationData['destination_country']}');
  debugPrint('  - Created: ${applicationData['created_at']}');
  debugPrint('  - Updated: ${applicationData['updated_at']}');
}

Map<String, dynamic> _formatApplicationData(
  Map<String, dynamic> applicationData,
  List<Map<String, dynamic>> trackingStages,
  Map<String, dynamic>? paymentData,
  List<Map<String, dynamic>> documents,
) {
  final status = applicationData['status']?.toString() ?? 'submitted';
  final submittedDate = applicationData['created_at'] != null 
      ? DateFormat('dd MMM yyyy').format(DateTime.parse(applicationData['created_at'].toString()).toLocal())
      : 'Not available';
  
  final lastUpdated = applicationData['updated_at'] != null
      ? DateFormat('dd MMM yyyy').format(DateTime.parse(applicationData['updated_at'].toString()).toLocal())
      : submittedDate;

  // Calculate progress based on actual completed stages from database
  final completedStages = trackingStages.where((stage) => stage['status'] == 'completed').length;
  final totalStages = trackingStages.length;

  // Get payment status with proper fallbacks
  // Get payment status with proper fallbacks
String paymentStatus = 'pending';
String paymentAmount = 'Not paid';

if (paymentData != null) {
  paymentStatus = paymentData['status']?.toString() ?? 'pending';
  
  // Format payment amount based on payment method
  if (paymentData['amount'] != null) {
    final paymentMethod = paymentData['payment_method']?.toString() ?? '';
    if (paymentMethod == 'payLater') {
      paymentAmount = '₹${paymentData['amount']} (Pay Later)';
    } else {
      paymentAmount = '₹${paymentData['amount']}';
    }
  }
  
  // For Pay Later users, show appropriate status
  if (paymentData['payment_method']?.toString() == 'payLater' && paymentStatus == 'pending') {
    paymentStatus = 'scheduled'; // More descriptive than 'pending'
  }
}

  // Safely handle all fields that could be null
  return {
    'id': applicationData['application_id']?.toString() ?? 'N/A',
    'status': status,
    'applicantName': '${applicationData['first_name']?.toString() ?? ''} ${applicationData['last_name']?.toString() ?? ''}'.trim(),
    'destinationCountry': applicationData['destination_country']?.toString() ?? 'Not provided',
    'visaType': applicationData['visa_type']?.toString() ?? 'Not provided',
    'applicationFee': paymentAmount,
    'paymentStatus': paymentStatus,
    'documentsCount': '${documents.length} document${documents.length != 1 ? 's' : ''}',
    'submittedDate': submittedDate,
    'lastUpdated': lastUpdated,
    'progress': '$completedStages/$totalStages stages completed',
    'notes': _getStatusNotes(status, applicationData),
    
  };
}

void _updateTrackingStagesFromDatabase(List<Map<String, dynamic>> dbStages) {
  // Reset all stages to pending first
  for (int i = 0; i < _trackingStages.length; i++) {
    _trackingStages[i] = _trackingStages[i].copyWith(
      status: StageStatus.pending,
      completedDate: null,
    );
  }
  
  // Update stages based on actual database data
  for (final dbStage in dbStages) {
    final stageNumber = dbStage['stage_number'] as int?;
    if (stageNumber == null || stageNumber < 1 || stageNumber > _trackingStages.length) {
      continue;
    }
    
    final index = stageNumber - 1;
    StageStatus status;
    switch (dbStage['status']) {
      case 'completed':
        status = StageStatus.completed;
        break;
      case 'in_progress':
        status = StageStatus.inProgress;
        break;
      default:
        status = StageStatus.pending;
    }
    
    DateTime? completedDate;
    if (dbStage['completed_at'] != null) {
      try {
        completedDate = DateTime.parse(dbStage['completed_at']).toLocal();
      } catch (e) {
        debugPrint('Error parsing completed_at: $e');
      }
    }
    
    _trackingStages[index] = _trackingStages[index].copyWith(
      status: status,
      completedDate: completedDate,
    );
  }
}

// Get status-specific notes
String _getStatusNotes(String status, Map<String, dynamic> applicationData) {
  switch (status) {
    case 'submitted':
      return 'Application submitted successfully. Waiting for payment confirmation.';
    case 'payment_pending':
      return 'Payment pending. Please complete the payment to proceed.';
    case 'under_review':
      return 'Application is under review. Our team is processing your documents.';
    case 'approved':
      return 'Congratulations! Your visa has been approved.';
    case 'rejected':
      return 'Visa application rejected. Please contact support for details.';
    default:
      return 'Application is being processed.';
  }
} 
 

  // Helper methods for styling
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return const Color.fromARGB(255, 7, 8, 7);
      case 'rejected': return Colors.red;
      case 'under_review': return Colors.orange;
      case 'payment_pending': return Colors.amber;
      case 'submitted': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.verified;
      case 'rejected': return Icons.cancel;
      case 'under_review': return Icons.hourglass_empty;
      case 'payment_pending': return Icons.payment;
      case 'submitted': return Icons.description;
      default: return Icons.help;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'under_review': return 'Under Review';
      case 'payment_pending': return 'Payment Pending';
      case 'submitted': return 'Submitted';
      default: return 'Unknown';
    }
  }

  Color _getStageColor(StageStatus status) {
    switch (status) {
      case StageStatus.completed: return Colors.green;
      case StageStatus.inProgress: return Colors.orange;
      case StageStatus.pending: return Colors.grey;
    }
  }

  Color _getStageBorderColor(StageStatus status) {
    switch (status) {
      case StageStatus.completed: return Colors.green;
      case StageStatus.inProgress: return Colors.orange;
      case StageStatus.pending: return Colors.grey.shade300;
    }
  }

  Color _getStageBackgroundColor(StageStatus status) {
    switch (status) {
      case StageStatus.completed: return Colors.green.shade50;
      case StageStatus.inProgress: return Colors.orange.shade50;
      case StageStatus.pending: return Colors.grey.shade50;
    }
  }

  IconData _getStageIcon(StageStatus status) {
    switch (status) {
      case StageStatus.completed: return Icons.check;
      case StageStatus.inProgress: return Icons.autorenew;
      case StageStatus.pending: return Icons.schedule;
    }
  }

  Color _getTimelineColor(int index) {
    final currentStage = _trackingStages[index].status;
    return currentStage == StageStatus.completed ? Colors.green : Colors.grey.shade300;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }
}

// Data models for tracking stages
enum StageStatus { pending, inProgress, completed }

class TrackingStage {
  final String title;
  final String description;
  final IconData icon;
  final StageStatus status;
  final DateTime? completedDate;

  TrackingStage({
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.completedDate,
  });

  TrackingStage copyWith({
    String? title,
    String? description,
    IconData? icon,
    StageStatus? status,
    DateTime? completedDate,
  }) {
    return TrackingStage(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}
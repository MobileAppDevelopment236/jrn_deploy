import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrr_immigration_app/services/supabase_storage_service.dart';
import 'package:intl/intl.dart';

// Date formatter for email
final _emailDateFormatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a', 'en_IN');

class ImmigrationAdviceScreen extends StatefulWidget {
  const ImmigrationAdviceScreen({super.key});

  @override
  State<ImmigrationAdviceScreen> createState() => _ImmigrationAdviceScreenState();
}

class _ImmigrationAdviceScreenState extends State<ImmigrationAdviceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false; 
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentCountryController = TextEditingController();
  final TextEditingController _targetCountryController = TextEditingController();
  final TextEditingController _visaTypeController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _otherAdviceController = TextEditingController();

  // Dropdown values
  String? _selectedAdviceType;
  String? _selectedTimeline;

  // Character count for purpose field
  int _purposeCharCount = 0;

  // Track if "Other" is selected
  bool get _showOtherAdviceField => _selectedAdviceType == 'Other';

  static const List<String> _adviceTypes = [
    'Visa Eligibility Assessment',
    'Document Preparation',
    'Application Strategy',
    'Appeal Process',
    'Permanent Residency',
    'Citizenship Process',
    'Other'
  ];

  static const List<String> _timelineOptions = [
    'Immediate (Within 1 month)',
    'Short-term (1-3 months)',
    'Medium-term (3-6 months)',
    'Long-term (6+ months)'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentCountryController.dispose();
    _targetCountryController.dispose();
    _visaTypeController.dispose();
    _purposeController.dispose();
    _otherAdviceController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _generateAndSendImmigrationEmail();
    }
  }

  void _generateAndSendImmigrationEmail() async {
    setState(() {
      _isSubmitting = true;
    });

    // STEP 1: Generate unique application ID
    final now = DateTime.now();
    final applicationId = 'IA${now.millisecondsSinceEpoch}';

    try {
      final subject = 'JRR GO Immigration Advice Request - ${_fullNameController.text}';
      final body = _generateEmailBody(applicationId);
      final htmlBody = _generateHtmlEmailBody(applicationId);
      final emailSent = await _sendEmailViaResendAPI(subject, body, htmlBody, applicationId);
      
      if (emailSent) {
        if (!mounted) return;
        _showFinalSuccessDialog(applicationId);
      } else {
        if (!mounted) return;
        _showManualEmailOption(subject, body, applicationId);
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('Email sending error: $error');
      final subject = 'JRR GO Immigration Advice Request - ${_fullNameController.text}';
      final body = _generateEmailBody(applicationId);
      _showManualEmailOption(subject, body, applicationId);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _generateEmailBody(String applicationId) {
    final now = DateTime.now();
    
    // Handle "Other" advice type
    String adviceType = _selectedAdviceType ?? 'Not specified';
    if (_selectedAdviceType == 'Other' && _otherAdviceController.text.isNotEmpty) {
      adviceType = 'Other: ${_otherAdviceController.text}';
    }
    
    return '''
**IMMIGRATION ADVICE REQUEST - CLIENT SUBMISSION**

**APPLICATION TRACKING**
• Application ID: $applicationId
• Submitted: ${_emailDateFormatter.format(now)}
• Service Type: Immigration Advice

**PERSONAL INFORMATION**
• Full Name: ${_fullNameController.text}
• Email: ${_emailController.text}
• Phone: ${_phoneController.text}

**IMMIGRATION DETAILS**
• Current Country: ${_currentCountryController.text}
• Destination Country: ${_targetCountryController.text}
• Advice Type: $adviceType
• Preferred Visa Type: ${_visaTypeController.text}
• Timeline: ${_selectedTimeline ?? 'Not specified'}

**PURPOSE & BACKGROUND**
• Purpose of Immigration: ${_purposeController.text.isNotEmpty ? _purposeController.text : 'Not specified'}

**TRACKING INFORMATION**
Application Status: RECEIVED ✅
Our team will contact you within 24 hours.
Use this Application ID for follow-up: $applicationId

---
**ACTION REQUIRED:** Please contact the client within 24 hours for initial consultation.

Best regards,
JRR Immigration Advisory Team
''';
  }

  String _generateHtmlEmailBody(String applicationId) {
  final now = DateTime.now();
  
  // Handle "Other" advice type
  String adviceType = _selectedAdviceType ?? 'Not specified';
  if (_selectedAdviceType == 'Other' && _otherAdviceController.text.isNotEmpty) {
    adviceType = 'Other: ${_otherAdviceController.text}';
  }

  // ✅ USE YOUR ACTUAL LOGO URL (from the screenshot)
  String logoUrl = 'https://zbjowyzxujktgwqrjseh.supabase.co/storage/v1/object/public/logos/JRR%20Logo.png';

  return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: linear-gradient(135deg, #1E88E5, #1565C0); color: white; padding: 20px; text-align: center; border-radius: 8px; margin-bottom: 20px; }
        .logo-container { display: flex; align-items: center; justify-content: center; gap: 15px; margin-bottom: 10px; }
        .logo-img { height: 50px; width: auto; }
        .logo-text { font-size: 24px; font-weight: bold; }
        .application-id { background: #e3f2fd; padding: 15px; border-left: 4px solid #1E88E5; margin: 15px 0; }
        .section { margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 5px; }
        .section-title { color: #1E88E5; font-weight: bold; margin-bottom: 10px; font-size: 16px; }
        .field { margin: 8px 0; }
        .field-label { font-weight: bold; color: #555; }
        .status { background: #e8f5e8; color: #2e7d32; padding: 10px; border-radius: 5px; text-align: center; margin: 15px 0; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 2px solid #1E88E5; text-align: center; color: #666; }
        .action-required { background: #fff3e0; padding: 15px; border-left: 4px solid #ff9800; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo-container">
            <img src="$logoUrl" alt="JRR Logo" class="logo-img" onerror="this.style.display='none'">
            <div class="logo-text">🚀 JRR IMMIGRATION SERVICES</div>
        </div>      
        <div>Professional Immigration Advisory</div>
    </div>

    <div class="application-id">
        <strong>Application ID:</strong> $applicationId<br>
        <strong>Submitted:</strong> ${_emailDateFormatter.format(now)}<br>
        <strong>Service Type:</strong> Immigration Advice
    </div>

    <!-- Rest of your HTML remains exactly the same -->
    <div class="section">
        <div class="section-title">📋 PERSONAL INFORMATION</div>
        <div class="field"><span class="field-label">Full Name:</span> ${_fullNameController.text}</div>
        <div class="field"><span class="field-label">Email:</span> ${_emailController.text}</div>
        <div class="field"><span class="field-label">Phone:</span> ${_phoneController.text}</div>
    </div>

    <div class="section">
        <div class="section-title">🌍 IMMIGRATION DETAILS</div>
        <div class="field"><span class="field-label">Current Country:</span> ${_currentCountryController.text}</div>
        <div class="field"><span class="field-label">Destination Country:</span> ${_targetCountryController.text}</div>
        <div class="field"><span class="field-label">Advice Type:</span> $adviceType</div>
        <div class="field"><span class="field-label">Preferred Visa Type:</span> ${_visaTypeController.text}</div>
        <div class="field"><span class="field-label">Timeline:</span> ${_selectedTimeline ?? 'Not specified'}</div>
    </div>

    <div class="section">
        <div class="section-title">🎯 PURPOSE & BACKGROUND</div>
        <div class="field"><span class="field-label">Purpose of Immigration:</span> ${_purposeController.text.isNotEmpty ? _purposeController.text : 'Not specified'}</div>
    </div>

    <div class="status">
        ✅ APPLICATION STATUS: RECEIVED<br>
        Our team will contact you within 24 hours.<br>
        <strong>Use this Application ID for follow-up: $applicationId</strong>
    </div>

    <div class="action-required">
        <strong>🚀 ACTION REQUIRED:</strong> Please contact the client within 24 hours for initial consultation.
    </div>

    <div class="footer">
        <strong>Best regards,</strong><br>
        JRR Immigration Advisory Team<br>
        <em>We work beyond borders</em>
    </div>
</body>
</html>
''';
}

  Future<bool> _sendEmailViaResendAPI(String subject, String body, String htmlBody, String applicationId) async {
    try {
      final response = await SupabaseStorageService.sendApplicationEmail(
        subject: subject,
        body: body,
        htmlBody: htmlBody, // Add this parameter to your Supabase service
        toEmails: ['jrrindia@gmail.com'],
        ccEmails: ['jrrgoindia@gmail.com'],
        applicationId: applicationId,
        receiptUrl: null,
      );
      
      return response;
    } catch (e) {
      debugPrint('Edge Function email error: $e');
      return false;
    }
  }

  void _showFinalSuccessDialog(String applicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Sent Successfully', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your immigration advice request has been sent to our team.', style: GoogleFonts.inter()),
            const SizedBox(height: 12),
            
            // Application ID display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Application ID:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(applicationId, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                  const SizedBox(height: 8),
                  Text('Please save this ID for tracking your application', style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            const Text('✓ Data sent to backend team for processing'),
            const SizedBox(height: 8),
            const Text('✓ Email sent with all your details'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Our team will contact you within 24 hours.',
                style: GoogleFonts.inter(color: Colors.green, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text('OK', style: GoogleFonts.inter(color: const Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
  }

  void _showManualEmailOption(String subject, String body, String applicationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alternative Submission Method', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your request has been prepared. You can:', style: GoogleFonts.inter()),
              
              // Application ID display
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 Your Application ID:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(applicationId, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                    const SizedBox(height: 4),
                    Text('Save this ID for tracking', style: GoogleFonts.inter(fontSize: 11)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📧 Option 1: Auto-Send (Recommended)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text('We\'ll send your request directly to our team.', style: GoogleFonts.inter()),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final htmlBody = _generateHtmlEmailBody(applicationId);
                          _sendEmailViaResendAPI(subject, body, htmlBody, applicationId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Send Automatically', style: GoogleFonts.inter()),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✉️ Option 2: Send via Email App',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text('Open your email app with pre-filled content.', style: GoogleFonts.inter()),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchEmailApp(subject, body);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: Text('Open Email App', style: GoogleFonts.inter()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmailApp(String subject, String body) async {
    try {
      final emailUrl = _buildProperlyEncodedEmailUrl(subject, body);
      
      if (await canLaunchUrl(emailUrl)) {
        final result = await launchUrl(
          emailUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (result) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('Could not open email app. Please check if you have an email app installed.');
        }
      } else {
        _showErrorDialog('No email app found. Please install an email app to send your request.');
      }
    } catch (error) {
      _showErrorDialog('Error: $error');
    }
  }

  Uri _buildProperlyEncodedEmailUrl(String subject, String body) {
    const primaryRecipient = 'jrrindia@gmail.com';
    const ccRecipients = 'jrrgoindia@gmail.com';
    
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    
    return Uri.parse('mailto:$primaryRecipient?cc=$ccRecipients&subject=$encodedSubject&body=$encodedBody');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Ready to Send', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your immigration advice request has been prepared successfully!', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📧 You can now:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text('• Add more emails in TO field (comma separated)', style: GoogleFonts.inter(fontSize: 12)),
                  Text('• Add emails in CC field for copies', style: GoogleFonts.inter(fontSize: 12)),
                  Text('• Delete or modify existing emails', style: GoogleFonts.inter(fontSize: 12)),
                  Text('• Review the formatted content', style: GoogleFonts.inter(fontSize: 12)),
                  Text('• Click SEND when ready', style: GoogleFonts.inter(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text('OK', style: GoogleFonts.inter(color: const Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inter(color: const Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedAdviceType = null;
      _selectedTimeline = null;
      _purposeCharCount = 0;
    });
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _currentCountryController.clear();
    _targetCountryController.clear();
    _visaTypeController.clear();
    _purposeController.clear();
    _otherAdviceController.clear();
  }

  void _updatePurposeCharCount(String text) {
    setState(() {
      _purposeCharCount = text.length;
    });
  }

  // Custom dropdown menu item with proper overflow handling
  Widget _buildDropdownMenuItem(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
        ),
        overflow: TextOverflow.visible,
        maxLines: 2,
        softWrap: true,
      ),
    );
  }

  // "Other" advice type text field
  Widget _buildOtherAdviceField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: _otherAdviceController,
        decoration: const InputDecoration(
          labelText: 'Please specify your advice need *',
          hintText: 'Describe the type of advice you need',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.edit),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        validator: (value) {
          if (_selectedAdviceType == 'Other' && (value == null || value.isEmpty)) {
            return 'Please specify your advice need';
          }
          return null;
        },
      ),
    );
  }

  // Assured Visa Service Widget - UPDATED: Removed boxes and chips
  Widget _buildAssuredVisaService() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - UPDATED: Removed box, kept as plain text
            Text(
              'PREMIUM SERVICE',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title and Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assured Visa Service',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹99,999',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Visa Approved or Get 100% Refund',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // UPDATED: Removed box from GUARANTEED badge
                Text(
                  'GUARANTEED',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Our premium service gives you complete confidence. If your visa is not approved, we refund the full service fee (T&C apply).',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // What You Get Section - UPDATED: Replaced chips with bullet points
            Text(
              'What You Get',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            // UPDATED: Bullet points instead of chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('Priority processing'),
                _buildBulletPoint('Detailed document verification'),
                _buildBulletPoint('Strong cover letter & travel plan'),
                _buildBulletPoint('Visa application preparation'),
                _buildBulletPoint('Appointment scheduling'),
                _buildBulletPoint('Dedicated case officer'),
                _buildBulletPoint('Unlimited consultation'),
                _buildBulletPoint('Refund Guarantee (T&C Apply)'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Refund Guarantee Section - UPDATED: Removed box
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund Guarantee (T&C Apply)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You receive 100% refund if:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• All documents are genuine\n'
                  '• No information is hidden\n'
                  '• You meet eligibility & financial requirements\n'
                  '• Embassy refusal happens despite a complete, strong file',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Eligible Countries
            Text(
              'Eligible Countries',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'USA | UK | Schengen (Europe) | Canada',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '(USA cases will be approved after eligibility screening.)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Suitable For
            Text(
              'Suitable For',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Business Travelers • Family Visitors • Frequent Travelers • Corporate Travelers',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Footer - UPDATED: Removed box
            SizedBox(
              width: double.infinity,
              child: Text(
                'JRR Immigration – We work beyond borders',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Helper method for bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;
            final bool isVeryWideScreen = constraints.maxWidth > 900;
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Actual JRR Logo with error handling
                Image.asset(
                  'assets/images/JRR Logo.png',
                  width: isVeryWideScreen ? 48 : (isWideScreen ? 40 : 32),
                  height: isVeryWideScreen ? 48 : (isWideScreen ? 40 : 32),
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if logo fails to load
                    return Container(
                      width: isVeryWideScreen ? 48 : (isWideScreen ? 40 : 32),
                      height: isVeryWideScreen ? 48 : (isWideScreen ? 40 : 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.flag,
                        color: const Color(0xFF1E88E5),
                        size: isVeryWideScreen ? 32 : (isWideScreen ? 28 : 24),
                      ),
                    );
                  },
                ),
                SizedBox(width: isVeryWideScreen ? 20 : (isWideScreen ? 16 : 12)),
                Text(
                  isVeryWideScreen ? 'JRR Immigration Services' : 'JRR Immigration',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: isVeryWideScreen ? 22 : (isWideScreen ? 20 : 18),
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 600;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Assured Visa Service Section
                _buildAssuredVisaService(),

                Card(
                  elevation: 1,
                  color: Colors.blue[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Fill the form and we\'ll send your request directly to our immigration specialists. No need to manually send emails.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Rest of your existing form code remains exactly the same...
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Immigration Advice',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete the form below and we\'ll send your request directly to our immigration specialists.',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Personal Information',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Personal Information Row - Responsive
                          if (isWideScreen)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _fullNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name *',
                                      hintText: 'Enter your full name',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      if (value.length < 2) {
                                        return 'Please enter a valid name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email *',
                                      hintText: 'Enter your email address',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.email),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter email address';
                                      }
                                      if (!_isValidEmail(value)) {
                                        return 'Please enter valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone *',
                                      hintText: 'Enter your phone number',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.phone),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter phone number';
                                      }
                                      if (!_isValidPhone(value)) {
                                        return 'Enter valid phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextFormField(
                                  controller: _fullNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name *',
                                    hintText: 'Enter your full name',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.length < 2) {
                                      return 'Please enter a valid name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email *',
                                    hintText: 'Enter your email address',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter email address';
                                    }
                                    if (!_isValidEmail(value)) {
                                      return 'Please enter valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone *',
                                    hintText: 'Enter your phone number',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.phone),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter phone number';
                                    }
                                    if (!_isValidPhone(value)) {
                                      return 'Enter valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 20),

                          Text(
                            'Immigration Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Current and Destination Country - Responsive
                          if (isWideScreen)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _currentCountryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Current Country *',
                                      hintText: 'e.g., India, USA, UK',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.location_on),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter current country';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _targetCountryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Destination Country *',
                                      hintText: 'e.g., Canada, Australia, USA',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.flag),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter destination country';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextFormField(
                                  controller: _currentCountryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Current Country *',
                                    hintText: 'e.g., India, USA, UK',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter current country';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _targetCountryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Destination Country *',
                                    hintText: 'e.g., Canada, Australia, USA',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.flag),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter destination country';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 12),
                          
                          // Advice Type and Visa Type - Responsive (WITH "OTHER" FIELD)
                          if (isWideScreen)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedAdviceType,
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        menuMaxHeight: 400,
                                        decoration: const InputDecoration(
                                          labelText: 'Type of Advice Needed *',
                                          hintText: 'Select advice type',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.help_outline),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: _adviceTypes.map((String type) {
                                          return DropdownMenuItem<String>(
                                            value: type,
                                            child: _buildDropdownMenuItem(type),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedAdviceType = newValue;
                                            if (newValue != 'Other') {
                                              _otherAdviceController.clear();
                                            }
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select advice type';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _visaTypeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Preferred Visa Type',
                                          hintText: 'e.g., Student Visa, Work Permit',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.assignment),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // "Other" advice type field for wide screen
                                if (_showOtherAdviceField) _buildOtherAdviceField(),
                              ],
                            )
                          else
                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedAdviceType,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  menuMaxHeight: 400,
                                  decoration: const InputDecoration(
                                    labelText: 'Type of Advice Needed *',
                                    hintText: 'Select advice type',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.help_outline),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _adviceTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: _buildDropdownMenuItem(type),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedAdviceType = newValue;
                                      if (newValue != 'Other') {
                                        _otherAdviceController.clear();
                                      }
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select advice type';
                                    }
                                    return null;
                                  },
                                ),
                                // "Other" advice type field for mobile
                                if (_showOtherAdviceField) _buildOtherAdviceField(),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _visaTypeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Preferred Visa Type',
                                    hintText: 'e.g., Student Visa, Work Permit',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.assignment),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 12),
                          
                          // Timeline Dropdown - Full width
                          DropdownButtonFormField<String>(
                            value: _selectedTimeline,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            menuMaxHeight: 300,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Timeline',
                              hintText: 'Select your timeline',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _timelineOptions.map((String timeline) {
                              return DropdownMenuItem<String>(
                                value: timeline,
                                child: _buildDropdownMenuItem(timeline),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTimeline = newValue;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 20),

                          Text(
                            'Purpose of Immigration',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _purposeController,
                            maxLines: 3,
                            maxLength: 120,
                            decoration: InputDecoration(
                              labelText: 'Purpose of Immigration (Optional)',
                              hintText: 'Describe your purpose for immigration (up to 120 characters)',
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              counterText: '$_purposeCharCount/120 characters',
                              counterStyle: TextStyle(
                                color: _purposeCharCount > 120 ? Colors.red : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onChanged: _updatePurposeCharCount,
                          ),
                          
                          const SizedBox(height: 24),

                          // Buttons - Responsive
                          if (isWideScreen)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E88E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 2,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.email, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Send Request',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Color(0xFF1E88E5)),
                                    ),
                                    child: Text(
                                      'Reset Form',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: const Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E88E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 2,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.email, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Send Request',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _resetForm,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: Color(0xFF1E88E5)),
                                    ),
                                    child: Text(
                                      'Reset Form',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: const Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📧 How It Works:',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Your request is sent directly to our team\n'
                                  '• No manual email sending required\n'
                                  '• Team will contact you within 24 hours\n'
                                  '• Fallback email option available if needed',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
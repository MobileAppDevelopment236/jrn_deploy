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

  // Dropdown values
  String? _selectedAdviceType;
  String? _selectedTimeline;

  // Character count for purpose field
  int _purposeCharCount = 0;

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

    try {
      final subject = 'JRR GO Immigration Advice Request - ${_fullNameController.text}';
      final body = _generateEmailBody();

      final emailSent = await _sendEmailViaResendAPI(subject, body);
      
      if (emailSent) {
        if (!mounted) return;
        _showFinalSuccessDialog();
      } else {
        if (!mounted) return;
        _showManualEmailOption(subject, body);
      }
    } catch (error) {
      if (!mounted) return;
      debugPrint('Email sending error: $error');
      final subject = 'JRR GO Immigration Advice Request - ${_fullNameController.text}';
      final body = _generateEmailBody();
      _showManualEmailOption(subject, body);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _generateEmailBody() {
    final now = DateTime.now();
    
    return '''
**IMMIGRATION ADVICE REQUEST - CLIENT SUBMISSION**

**SUBMISSION DETAILS**
• Submitted: ${_emailDateFormatter.format(now)}
• Service Type: Immigration Advice

**PERSONAL INFORMATION**
• Full Name: ${_fullNameController.text}
• Email: ${_emailController.text}
• Phone: ${_phoneController.text}

**IMMIGRATION DETAILS**
• Current Country: ${_currentCountryController.text}
• Destination Country: ${_targetCountryController.text}
• Advice Type: ${_selectedAdviceType ?? 'Not specified'}
• Preferred Visa Type: ${_visaTypeController.text}
• Timeline: ${_selectedTimeline ?? 'Not specified'}

**PURPOSE & BACKGROUND**
• Purpose of Immigration: ${_purposeController.text.isNotEmpty ? _purposeController.text : 'Not specified'}

**REQUEST**
Please provide professional immigration advice for the above case.

---
**ACTION REQUIRED:** Please contact the client within 24 hours for initial consultation.

Best regards,
JRR Immigration Advisory Team
''';
  }

  Future<bool> _sendEmailViaResendAPI(String subject, String body) async {
    try {
      final response = await SupabaseStorageService.sendApplicationEmail(
        subject: subject,
        body: body,
        toEmails: ['jrrindia@gmail.com'],
        ccEmails: ['jrrgoindia@gmail.com'],
        applicationId: '',
        receiptUrl: null,
      );
      
      return response;
    } catch (e) {
      debugPrint('Edge Function email error: $e');
      return false;
    }
  }

  void _showFinalSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Sent Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your immigration advice request has been sent to our team.'),
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
              child: const Text(
                'Our team will contact you within 24 hours.',
                style: TextStyle(color: Colors.green),
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

  void _showManualEmailOption(String subject, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alternative Submission Method'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your request has been prepared. You can:'),
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
                    const Text(
                      '📧 Option 1: Auto-Send (Recommended)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    const Text('We\'ll send your request directly to our team.'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendEmailViaResendAPI(subject, body);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Send Automatically'),
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
                    const Text(
                      '✉️ Option 2: Send via Email App',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text('Open your email app with pre-filled content.'),
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
                        child: const Text('Open Email App'),
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
            child: const Text('Cancel'),
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
  }

  void _updatePurposeCharCount(String text) {
    setState(() {
      _purposeCharCount = text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Immigration Advice',
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
          children: [
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
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                hintText: 'Full Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
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
                                hintText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
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
                                hintText: 'Phone',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
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
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedAdviceType,
                              decoration: const InputDecoration(
                                labelText: 'Type of Advice Needed *',
                                hintText: 'Select advice type',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.help_outline),
                              ),
                              items: _adviceTypes.map((String type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedAdviceType = newValue;
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
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedTimeline,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Timeline',
                          hintText: 'Select your timeline',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: _timelineOptions.map((String timeline) {
                          return DropdownMenuItem<String>(
                            value: timeline,
                            child: Text(timeline),
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
                          counterText: '$_purposeCharCount/120 characters',
                          counterStyle: TextStyle(
                            color: _purposeCharCount > 120 ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onChanged: _updatePurposeCharCount,
                      ),
                      
                      const SizedBox(height: 24),

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
      ),
    );
  }
}
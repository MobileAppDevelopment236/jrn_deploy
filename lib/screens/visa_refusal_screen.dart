import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jrr_immigration_app/services/supabase_storage_service.dart';

// Date formatter for email
final _emailDateFormatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a', 'en_IN');

class VisaRefusalScreen extends StatefulWidget {
  const VisaRefusalScreen({super.key});

  @override
  State<VisaRefusalScreen> createState() => _VisaRefusalScreenState();
}

class _VisaRefusalScreenState extends State<VisaRefusalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers - Split name into first and last name
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _appliedCountryController = TextEditingController();
  final _visaTypeController = TextEditingController();
  final _applicationDateController = TextEditingController();
  final _refusalDateController = TextEditingController();
  final _refusalReasonController = TextEditingController();
  final _previousTravelHistoryController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  // Dropdown values
  String? _selectedVisaCategory;
  String? _selectedAppealStatus;

  // Loading state
  bool _isLoading = false;

  // Validation flags
  bool _firstNameValidated = false;
  bool _lastNameValidated = false;
  bool _emailValidated = false;
  bool _phoneValidated = false;
  bool _appliedCountryValidated = false;
  bool _visaTypeValidated = false;
  bool _applicationDateValidated = false;
  bool _refusalDateValidated = false;
  bool _refusalReasonValidated = false;

  final List<String> _visaCategories = [
    'Tourist',
    'Student',
    'Work',
    'Business',
    'Family',
    'Transit',
    'Other'
  ];

  final List<String> _appealStatusOptions = [
    'Not Appealed',
    'Planning to Appeal',
    'Appeal in Progress',
    'Already Appealed - Failed'
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _appliedCountryController.dispose();
    _visaTypeController.dispose();
    _applicationDateController.dispose();
    _refusalDateController.dispose();
    _refusalReasonController.dispose();
    _previousTravelHistoryController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {DateTime? firstDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (!mounted) return;
    
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
      _validateDates();
    }
  }

  void _validateDates() {
    if (_applicationDateController.text.isNotEmpty && _refusalDateController.text.isNotEmpty) {
      final appDate = _parseDate(_applicationDateController.text);
      final refusalDate = _parseDate(_refusalDateController.text);
      
      if (appDate != null && refusalDate != null && refusalDate.isBefore(appDate)) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refusal date cannot be before application date'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _refusalDateController.clear();
        });
      }
    }
  }

  void _submitForm() async {
    // Mark all fields as validated
    setState(() {
      _firstNameValidated = true;
      _lastNameValidated = true;
      _emailValidated = true;
      _phoneValidated = true;
      _appliedCountryValidated = true;
      _visaTypeValidated = true;
      _applicationDateValidated = true;
      _refusalDateValidated = true;
      _refusalReasonValidated = true;
    });

    if (_formKey.currentState!.validate()) {
      if (_applicationDateController.text.isNotEmpty && _refusalDateController.text.isNotEmpty) {
        final appDate = _parseDate(_applicationDateController.text);
        final refusalDate = _parseDate(_refusalDateController.text);
        
        if (appDate != null && refusalDate != null && refusalDate.isBefore(appDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refusal date cannot be before application date'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      setState(() {
        _isLoading = true;
      });

      await _generateAndSendVisaRefusalEmail();
      
      setState(() {
        _isLoading = false;
      });
    } else {
      // Show error if validation fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fix all errors before submitting'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAndSendVisaRefusalEmail() async {
    try {
      final subject = 'JRR GO Visa Refusal Assistance Request - ${_firstNameController.text} ${_lastNameController.text}';
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
      final subject = 'JRR GO Visa Refusal Assistance Request - ${_firstNameController.text} ${_lastNameController.text}';
      final body = _generateEmailBody();
      _showManualEmailOption(subject, body);
    }
  }

  String _generateEmailBody() {
    final now = DateTime.now();
    
    return '''
**VISA REFUSAL ASSISTANCE REQUEST - CLIENT SUBMISSION**

**SUBMISSION DETAILS**
• Submitted: ${_emailDateFormatter.format(now)}
• Service Type: Visa Refusal Assistance

**CLIENT INFORMATION**
• First Name: ${_firstNameController.text}
• Last Name: ${_lastNameController.text}
• Email Address: ${_emailController.text}
• Phone Number: ${_phoneController.text}

**VISA APPLICATION DETAILS**
• Applied Country: ${_appliedCountryController.text}
• Visa Type: ${_visaTypeController.text}
• Visa Category: ${_selectedVisaCategory ?? 'Not specified'}
• Application Date: ${_applicationDateController.text}

**REFUSAL DETAILS**
• Refusal Date: ${_refusalDateController.text}
• Refusal Reason: ${_refusalReasonController.text}
• Appeal Status: ${_selectedAppealStatus ?? 'Not specified'}

**ADDITIONAL INFORMATION**
• Previous Travel History: ${_previousTravelHistoryController.text.isNotEmpty ? _previousTravelHistoryController.text : 'None provided'}
• Additional Notes: ${_additionalNotesController.text.isNotEmpty ? _additionalNotesController.text : 'None provided'}

**REQUEST**
Please review this visa refusal case and provide assistance with reapplication or appeal process.

---
**ACTION REQUIRED:** Please contact the client within 24 hours to discuss next steps and assistance options.

Best regards,
JRR Visa Assistance Team
''';
  }

  Future<bool> _sendEmailViaResendAPI(String subject, String body) async {
    try {
      final response = await SupabaseStorageService.sendApplicationEmail(
        subject: subject,
        body: body,
        toEmails: ['jrrindia@gmail.com'],
        ccEmails: ['jrrgoindia@gmail.com'],
        applicationId: 'VISA-REFUSAL-${DateTime.now().millisecondsSinceEpoch}',
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
            const Text('Your visa refusal assistance request has been sent to our team.'),
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
            Text('Your visa refusal assistance request has been prepared successfully!', style: GoogleFonts.inter()),
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
      _selectedVisaCategory = null;
      _selectedAppealStatus = null;
      _firstNameValidated = false;
      _lastNameValidated = false;
      _emailValidated = false;
      _phoneValidated = false;
      _appliedCountryValidated = false;
      _visaTypeValidated = false;
      _applicationDateValidated = false;
      _refusalDateValidated = false;
      _refusalReasonValidated = false;
    });
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _appliedCountryController.clear();
    _visaTypeController.clear();
    _applicationDateController.clear();
    _refusalDateController.clear();
    _refusalReasonController.clear();
    _previousTravelHistoryController.clear();
    _additionalNotesController.clear();
    
    // Close any open dialogs
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visa Refusal Assistance',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
                // Information Card - Like Forex Screen
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
                            'Fill the form and we\'ll send your request directly to our visa specialists. No need to manually send emails.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Form Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Text(
                            'Visa Refusal Assistance',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete this form for expert assistance. Our team will review your case within 24 hours.',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),

                          // Personal Information Section
                          const SizedBox(height: 20),
                          Text(
                            'Personal Information',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // First Name and Last Name - Responsive
                          isWideScreen 
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _firstNameController,
                                        decoration: InputDecoration(
                                          labelText: 'First Name *',
                                          hintText: 'As per passport',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.person),
                                          errorText: _firstNameValidated && (_firstNameController.text.isEmpty || _firstNameController.text.length < 2) 
                                              ? 'Enter valid first name'
                                              : null,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _firstNameValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          if (value.length < 2) return 'Enter valid first name';
                                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                            return 'Name can only contain letters and spaces';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lastNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Last Name *',
                                          hintText: 'As per passport',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.person),
                                          errorText: _lastNameValidated && (_lastNameController.text.isEmpty || _lastNameController.text.length < 2) 
                                              ? 'Enter valid last name'
                                              : null,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _lastNameValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          if (value.length < 2) return 'Enter valid last name';
                                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                            return 'Name can only contain letters and spaces';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _firstNameController,
                                      decoration: InputDecoration(
                                        labelText: 'First Name *',
                                        hintText: 'As per passport',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.person),
                                        errorText: _firstNameValidated && (_firstNameController.text.isEmpty || _firstNameController.text.length < 2) 
                                            ? 'Enter valid first name'
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _firstNameValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        if (value.length < 2) return 'Enter valid first name';
                                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                          return 'Name can only contain letters and spaces';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _lastNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Last Name *',
                                        hintText: 'As per passport',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.person),
                                        errorText: _lastNameValidated && (_lastNameController.text.isEmpty || _lastNameController.text.length < 2) 
                                            ? 'Enter valid last name'
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _lastNameValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        if (value.length < 2) return 'Enter valid last name';
                                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                                          return 'Name can only contain letters and spaces';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          
                          // Email and Phone - Responsive
                          isWideScreen 
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email Address *',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.email),
                                          errorText: _emailValidated && _emailController.text.isNotEmpty && 
                                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)
                                              ? 'Enter valid email'
                                              : null,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: (value) {
                                          setState(() {
                                            _emailValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number *',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.phone),
                                          errorText: _phoneValidated && _phoneController.text.isNotEmpty && 
                                              !RegExp(r'^[0-9+\-\s()]{10,}$').hasMatch(_phoneController.text.replaceAll(RegExp(r'[\s\-()]'), ''))
                                              ? 'Enter valid phone'
                                              : null,
                                        ),
                                        keyboardType: TextInputType.phone,
                                        onChanged: (value) {
                                          setState(() {
                                            _phoneValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          final digitsOnly = value.replaceAll(RegExp(r'[\s\-()]'), '');
                                          if (digitsOnly.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
                                            return 'Please enter a valid phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email Address *',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.email),
                                        errorText: _emailValidated && _emailController.text.isNotEmpty && 
                                            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)
                                            ? 'Enter valid email'
                                            : null,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      onChanged: (value) {
                                        setState(() {
                                          _emailValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number *',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.phone),
                                        errorText: _phoneValidated && _phoneController.text.isNotEmpty && 
                                            !RegExp(r'^[0-9+\-\s()]{10,}$').hasMatch(_phoneController.text.replaceAll(RegExp(r'[\s\-()]'), ''))
                                            ? 'Enter valid phone'
                                            : null,
                                      ),
                                      keyboardType: TextInputType.phone,
                                      onChanged: (value) {
                                        setState(() {
                                          _phoneValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        final digitsOnly = value.replaceAll(RegExp(r'[\s\-()]'), '');
                                        if (digitsOnly.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),

                          // Visa Application Details Section
                          const SizedBox(height: 20),
                          Text(
                            'Visa Application Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Applied Country and Application Date - Responsive
                          isWideScreen 
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _appliedCountryController,
                                        decoration: InputDecoration(
                                          labelText: 'Applied Country *',
                                          hintText: 'e.g., USA, Canada',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.flag),
                                          errorText: _appliedCountryValidated && _appliedCountryController.text.isEmpty
                                              ? 'Required field'
                                              : null,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _appliedCountryValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _applicationDateController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Application Date *',
                                          hintText: 'Select date',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.calendar_today),
                                          errorText: _applicationDateValidated && _applicationDateController.text.isEmpty
                                              ? 'Required field'
                                              : null,
                                        ),
                                        onTap: () => _selectDate(context, _applicationDateController),
                                        onChanged: (value) {
                                          setState(() {
                                            _applicationDateValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _appliedCountryController,
                                      decoration: InputDecoration(
                                        labelText: 'Applied Country *',
                                        hintText: 'e.g., USA, Canada',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.flag),
                                        errorText: _appliedCountryValidated && _appliedCountryController.text.isEmpty
                                            ? 'Required field'
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _appliedCountryValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _applicationDateController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Application Date *',
                                        hintText: 'Select date',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.calendar_today),
                                        errorText: _applicationDateValidated && _applicationDateController.text.isEmpty
                                            ? 'Required field'
                                            : null,
                                      ),
                                      onTap: () => _selectDate(context, _applicationDateController),
                                      onChanged: (value) {
                                        setState(() {
                                          _applicationDateValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          
                          // Visa Type and Category - Responsive
                          isWideScreen 
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _visaTypeController,
                                        decoration: InputDecoration(
                                          labelText: 'Visa Type *',
                                          hintText: 'e.g., Tourist, Student',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.assignment),
                                          errorText: _visaTypeValidated && _visaTypeController.text.isEmpty
                                              ? 'Required field'
                                              : null,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _visaTypeValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedVisaCategory,
                                        isExpanded: true, // FIX: Added to prevent overflow
                                        decoration: const InputDecoration(
                                          labelText: 'Visa Category',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.category),
                                        ),
                                        items: _visaCategories.map((String category) {
                                          return DropdownMenuItem<String>(
                                            value: category,
                                            child: Text(
                                              category,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedVisaCategory = value;
                                          });
                                        },
                                        hint: const Text(
                                          'Select category',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _visaTypeController,
                                      decoration: InputDecoration(
                                        labelText: 'Visa Type *',
                                        hintText: 'e.g., Tourist, Student',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.assignment),
                                        errorText: _visaTypeValidated && _visaTypeController.text.isEmpty
                                            ? 'Required field'
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _visaTypeValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedVisaCategory,
                                      isExpanded: true, // FIX: Added to prevent overflow
                                      decoration: const InputDecoration(
                                        labelText: 'Visa Category',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.category),
                                      ),
                                      items: _visaCategories.map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            category,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedVisaCategory = value;
                                        });
                                      },
                                      hint: const Text(
                                        'Select category',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                          // Refusal Details Section
                          const SizedBox(height: 20),
                          Text(
                            'Refusal Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Refusal Date and Appeal Status - Responsive
                          isWideScreen 
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _refusalDateController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: 'Refusal Date *',
                                          hintText: 'Select date',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.calendar_today),
                                          errorText: _refusalDateValidated && _refusalDateController.text.isEmpty
                                              ? 'Required field'
                                              : null,
                                        ),
                                        onTap: () {
                                          DateTime? firstDate;
                                          if (_applicationDateController.text.isNotEmpty) {
                                            firstDate = _parseDate(_applicationDateController.text);
                                          }
                                          _selectDate(context, _refusalDateController, firstDate: firstDate);
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _refusalDateValidated = true;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) return 'Required field';
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedAppealStatus,
                                        isExpanded: true, // FIX: Added to prevent overflow
                                        decoration: const InputDecoration(
                                          labelText: 'Appeal Status',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.gavel),
                                        ),
                                        items: _appealStatusOptions.map((String status) {
                                          return DropdownMenuItem<String>(
                                            value: status,
                                            child: Text(
                                              status,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAppealStatus = value;
                                          });
                                        },
                                        hint: const Text(
                                          'Select status',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    TextFormField(
                                      controller: _refusalDateController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Refusal Date *',
                                        hintText: 'Select date',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.calendar_today),
                                        errorText: _refusalDateValidated && _refusalDateController.text.isEmpty
                                            ? 'Required field'
                                            : null,
                                      ),
                                      onTap: () {
                                        DateTime? firstDate;
                                        if (_applicationDateController.text.isNotEmpty) {
                                          firstDate = _parseDate(_applicationDateController.text);
                                        }
                                        _selectDate(context, _refusalDateController, firstDate: firstDate);
                                      },
                                      onChanged: (value) {
                                        setState(() {
                                          _refusalDateValidated = true;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required field';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedAppealStatus,
                                      isExpanded: true, // FIX: Added to prevent overflow
                                      decoration: const InputDecoration(
                                        labelText: 'Appeal Status',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.gavel),
                                      ),
                                      items: _appealStatusOptions.map((String status) {
                                        return DropdownMenuItem<String>(
                                          value: status,
                                          child: Text(
                                            status,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAppealStatus = value;
                                        });
                                      },
                                      hint: const Text(
                                        'Select status',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 12),
                          
                          // Refusal Reason - Full width (always)
                          TextFormField(
                            controller: _refusalReasonController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Refusal Reason *',
                              hintText: 'Exact reason from refusal letter',
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                              errorText: _refusalReasonValidated && _refusalReasonController.text.isEmpty
                                  ? 'Required field'
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _refusalReasonValidated = true;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required field';
                              return null;
                            },
                          ),

                          // Additional Information Section
                          const SizedBox(height: 20),
                          Text(
                            'Additional Information',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextFormField(
                            controller: _previousTravelHistoryController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Previous Travel History',
                              hintText: 'Countries visited in past 5 years',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          TextFormField(
                            controller: _additionalNotesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Additional Notes',
                              hintText: 'Any other relevant information',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),

                          // Action Buttons - FIXED: Using LayoutBuilder for responsive buttons
const SizedBox(height: 24),
LayoutBuilder(
  builder: (context, constraints) {
    final bool isWide = constraints.maxWidth > 400;
    
    if (isWide) {
      // Horizontal layout for wider screens
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              child: _isLoading
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
      );
    } else {
      // Vertical layout for narrower screens
      return Column(
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
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
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF1E88E5)),
              minimumSize: const Size(double.infinity, 50),
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
        ],
      );
    }
  },
),
                          

                          const SizedBox(height: 16),

                          // How It Works Info - Like Forex Screen
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
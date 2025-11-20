import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrr_immigration_app/services/supabase_storage_service.dart';
import 'package:intl/intl.dart';

// Date formatter for email
final _emailDateFormatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a', 'en_IN');

class AIAssistantPopup {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AIAssistantPopupContent(),
    );
  }
}

class _AIAssistantPopupContent extends StatefulWidget {
  const _AIAssistantPopupContent();

  @override
  State<_AIAssistantPopupContent> createState() => _AIAssistantPopupContentState();
}

class _AIAssistantPopupContentState extends State<_AIAssistantPopupContent> {
  final TextEditingController _messageController = TextEditingController();
  final List<AIMessage> _messages = [];
  bool _isTyping = false;
  bool _showCompactForm = false;
  bool _isSubmitting = false;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _queryTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Unique application ID
  String _applicationId = '';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _generateApplicationId();
  }

  void _generateApplicationId() {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(now);
    final timePart = DateFormat('HHmmss').format(now);
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    _applicationId = 'JRR$datePart$timePart$random';
  }

  void _addWelcomeMessage() {
    _messages.add(AIMessage(
      "Hello! I'm JRR GO AI Assistant 👋\n\nI can help you with:\n• Visa information & applications\n• Document requirements\n• Application status\n• General inquiries\n\nWhat would you like to know today?",
      false
    ));
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messages.add(AIMessage(text, true));
    _messageController.clear();
    
    setState(() {
      _isTyping = true;
    });

    // Simulate AI processing
    Future.delayed(const Duration(milliseconds: 800), () {
      _processUserQuery(text);
    });
  }

  void _processUserQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    setState(() {
      _isTyping = false;
    });

    if (lowerQuery.contains('visa') || lowerQuery.contains('apply') || lowerQuery.contains('information')) {
      _messages.add(AIMessage(
        "I can help with visa applications! To provide accurate information, I'll need a few details.\n\nWould you like me to prepare a visa inquiry form for our specialists?",
        false,
        showFormTrigger: true
      ));
    } 
    else if (lowerQuery.contains('status') || lowerQuery.contains('track')) {
      _messages.add(AIMessage(
        "For application status tracking, you'll need your reference number. You can check it in the 'Track Status' section of the app, or I can help you contact our team for updates.",
        false
      ));
    }
    else if (lowerQuery.contains('document') || lowerQuery.contains('required')) {
      _messages.add(AIMessage(
        "Document requirements vary by visa type and destination. Common documents include:\n• Valid passport\n• Photographs\n• Financial proofs\n• Travel itinerary\n\nTell me which country you're applying to for specific requirements.",
        false
      ));
    }
    else if (lowerQuery.contains('refusal') || lowerQuery.contains('reject')) {
      _messages.add(AIMessage(
        "I understand visa refusals can be stressful. Our team specializes in:\n• Refusal case analysis\n• Reapplication strategies\n• Documentation review\n\nWould you like me to connect you with our refusal specialist?",
        false,
        showFormTrigger: true
      ));
    }
    else {
      _messages.add(AIMessage(
        "I understand you're asking about: \"$query\"\n\nI can help with general information. For detailed personal assistance, our specialist team can provide comprehensive support. Would you like me to prepare an inquiry form?",
        false,
        showFormTrigger: true
      ));
    }
  }

  void _showInquiryForm() {
    setState(() {
      _showCompactForm = true;
    });
    _messages.add(AIMessage(
      "Great! Please fill in your details below and describe your requirement. Our team will contact you within 24 hours.",
      false
    ));
  }

  void _submitInquiry() {
    if (_formKey.currentState?.validate() ?? false) {
      _generateAndSendEmail();
    }
  }

  // Email functionality from Immigration Advice Screen
  void _generateAndSendEmail() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final subject = 'JRR GO AI Assistant Inquiry - ${_nameController.text}';
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
      final subject = 'JRR GO AI Assistant Inquiry - ${_nameController.text}';
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
    final lastUserMessage = _messages.isNotEmpty ? 
        _messages.lastWhere((m) => m.isUser, orElse: () => AIMessage('No specific query mentioned', true)).text 
        : 'No specific query mentioned';
    
    return '''
**AI ASSISTANT INQUIRY - CLIENT SUBMISSION**

**APPLICATION DETAILS**
• Application ID: $_applicationId
• Submitted: ${_emailDateFormatter.format(now)}
• Source: AI Assistant Chat
• Last User Query: "$lastUserMessage"

**CLIENT INFORMATION**
• Full Name: ${_nameController.text}
• Email: ${_emailController.text}
• Phone: ${_phoneController.text}
• Inquiry Type: ${_queryTypeController.text.isNotEmpty ? _queryTypeController.text : 'General Inquiry'}

**CHAT CONTEXT**
This inquiry was generated through the AI Assistant chat interface. The client initially asked about topics related to immigration and requested specialist assistance.

**REQUEST**
Please contact the client to provide personalized assistance based on their inquiry.

---
**ACTION REQUIRED:** Please contact the client within 24 hours to address their immigration needs.

Best regards,
JRR GO AI Assistant System
''';
  }

  Future<bool> _sendEmailViaResendAPI(String subject, String body) async {
    try {
      final response = await SupabaseStorageService.sendApplicationEmail(
        subject: subject,
        body: body,
        toEmails: ['jrrindia@gmail.com'],
        ccEmails: ['jrrgoindia@gmail.com'],
        applicationId: _applicationId,
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
        title: const Text('Inquiry Sent Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your inquiry has been sent to our team.'),
            const SizedBox(height: 12),
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
                    'Application ID: $_applicationId',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please save this ID for future reference',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
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
              Navigator.pop(context); // Close success dialog
              Navigator.pop(context); // Close AI assistant
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
              const Text('Your inquiry has been prepared. You can:'),
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
                    const Text('We\'ll send your inquiry directly to our team.'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Application ID: $_applicationId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'Application ID: $_applicationId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
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
        _showErrorDialog('No email app found. Please install an email app to send your inquiry.');
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
            Text('Your inquiry has been prepared successfully!', style: GoogleFonts.inter()),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                'Application ID: $_applicationId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close AI assistant
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
      _showCompactForm = false;
    });
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _queryTypeController.clear();
    _messageController.clear();
    // Generate new application ID for next submission
    _generateApplicationId();
  }

  // Email validation methods
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.support_agent, color: Color(0xFF1E88E5)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JRR GO AI Assistant', style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                      Text('Online • Ready to help', style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      )),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_showCompactForm ? 1 : 0),
              itemBuilder: (context, index) {
                if (_showCompactForm && index == _messages.length + (_isTyping ? 1 : 0)) {
                  return _buildCompactForm();
                }
                
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input Area
          if (!_showCompactForm) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              backgroundColor: Color(0xFF1E88E5),
              radius: 16,
              child: Icon(Icons.support_agent, size: 16, color: Colors.white),
            )
          else
            const SizedBox(width: 32),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? const Color(0xFF1E88E5) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                if (message.showFormTrigger) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showInquiryForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Yes, show inquiry form', style: GoogleFonts.inter(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          
          if (message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildCompactForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E88E5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text('Quick Inquiry Form', style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Application ID: $_applicationId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Email Field
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!_isValidEmail(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Phone Number Field
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!_isValidPhone(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            
            // Query Type Field
            TextFormField(
              controller: _queryTypeController,
              decoration: const InputDecoration(
                labelText: 'What do you need help with? *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your inquiry';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                        : Text('Submit Inquiry', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1E88E5)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF1E88E5),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send, size: 16, color: Colors.white),
              onPressed: _sendMessage,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF1E88E5),
            radius: 16,
            child: Icon(Icons.support_agent, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                _buildTypingDot(1),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _queryTypeController.dispose();
    super.dispose();
  }
}

class AIMessage {
  final String text;
  final bool isUser;
  final bool showFormTrigger;

  AIMessage(this.text, this.isUser, {this.showFormTrigger = false});
}
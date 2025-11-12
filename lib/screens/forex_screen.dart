import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jrr_immigration_app/services/supabase_storage_service.dart';

// Date formatter for email
final _emailDateFormatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a', 'en_IN');

class ForexScreen extends StatefulWidget {
  const ForexScreen({super.key});

  @override
  State<ForexScreen> createState() => _ForexScreenState();
}

class _ForexScreenState extends State<ForexScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _sourceCurrencyController = TextEditingController();
  final TextEditingController _targetCurrencyController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  
  String _selectedService = 'Currency Exchange';
  bool _isLoading = false;

  final List<String> _services = [
    'Currency Exchange',
    'Foreign Transfer',
    'Forex Card',
    'Travelers Cheque',
    'Business Forex'
  ];

  // Validation flags
  bool _nameValidated = false;
  bool _emailValidated = false;
  bool _phoneValidated = false;
  bool _sourceCurrencyValidated = false;
  bool _targetCurrencyValidated = false;
  bool _amountValidated = false;
  bool _purposeValidated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forex Service Request',
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
          final bool isPortrait = constraints.maxHeight > constraints.maxWidth;
          final bool isLargeScreen = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Information Card - Like Immigration Screen
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
                            'Fill the form and we\'ll send your request directly to our forex specialists. No need to manually send emails.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Main Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Professional Forex Services',
                            style: GoogleFonts.inter(
                              fontSize: isLargeScreen ? 20 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete the form below and we\'ll send your request directly to our forex specialists.',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: isLargeScreen ? 15 : 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Service Type Section
                          Text(
                            'Service Type',
                            style: GoogleFonts.inter(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedService,
                            decoration: const InputDecoration(
                              labelText: 'Select Service Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_exchange),
                            ),
                            items: _services.map<DropdownMenuItem<String>>((String service) {
                              return DropdownMenuItem<String>(
                                value: service,
                                child: Text(service),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedService = newValue ?? 'Currency Exchange';
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Hyderabad Availability Note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Note: Forex services are currently available in Hyderabad only.',
                                    style: GoogleFonts.inter(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Personal Information Section
                          Text(
                            'Personal Information',
                            style: GoogleFonts.inter(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Responsive Personal Information Row
                          if (isPortrait && !isLargeScreen)
                            _buildPersonalInfoColumn()
                          else
                            _buildPersonalInfoRow(isLargeScreen),

                          const SizedBox(height: 20),

                          // Transaction Details Section
                          Text(
                            'Transaction Details',
                            style: GoogleFonts.inter(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Responsive Transaction Details
                          if (isPortrait && !isLargeScreen)
                            _buildTransactionDetailsColumn()
                          else
                            _buildTransactionDetailsRow(isLargeScreen),

                          const SizedBox(height: 12),
                          
                          // Amount Field (Full width)
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.attach_money),
                              errorText: _amountValidated && _amountController.text.isNotEmpty && 
                                  !RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(_amountController.text)
                                  ? 'Enter valid amount'
                                  : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              setState(() {
                                _amountValidated = true;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              if (!RegExp(r'^[0-9]+(\.[0-9]{1,2})?$').hasMatch(value)) {
                                return 'Please enter a valid amount';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Amount must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Purpose Field (Full width)
                          TextFormField(
                            controller: _purposeController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Purpose of Transaction *',
                              hintText: 'Describe the purpose of this forex transaction in detail',
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                              errorText: _purposeValidated && (_purposeController.text.isEmpty || _purposeController.text.length < 10)
                                  ? 'Min. 10 characters required'
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _purposeValidated = true;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe the purpose';
                              }
                              if (value.length < 10) {
                                return 'Please provide more details';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Buttons - Responsive
                          if (isPortrait && !isLargeScreen)
                            _buildButtonsColumn()
                          else
                            _buildButtonsRow(),

                          const SizedBox(height: 16),

                          // How It Works Info
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
                                    fontSize: isLargeScreen ? 14 : 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• Your request is sent directly to our team\n'
                                  '• No manual email sending required\n'
                                  '• Team will contact you within 2 hours\n'
                                  '• Fallback email option available if needed',
                                  style: GoogleFonts.inter(
                                    fontSize: isLargeScreen ? 13 : 11,
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

  // Personal Information in Column (for portrait mode)
  Widget _buildPersonalInfoColumn() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person),
            errorText: _nameValidated && (_nameController.text.isEmpty || _nameController.text.length < 2) 
                ? 'Enter valid name'
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _nameValidated = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
              return 'Name can only contain letters and spaces';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email *',
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
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
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
            labelText: 'Phone *',
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
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            final digitsOnly = value.replaceAll(RegExp(r'[\s\-()]'), '');
            if (digitsOnly.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Personal Information in Row (for landscape mode)
  Widget _buildPersonalInfoRow(bool isLargeScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
              errorText: _nameValidated && (_nameController.text.isEmpty || _nameController.text.length < 2) 
                  ? 'Enter valid name'
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _nameValidated = true;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              if (value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                return 'Name can only contain letters and spaces';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: isLargeScreen ? 16 : 12),
        Expanded(
          child: TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email *',
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
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: isLargeScreen ? 16 : 12),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone *',
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
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              final digitsOnly = value.replaceAll(RegExp(r'[\s\-()]'), '');
              if (digitsOnly.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(digitsOnly)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // Transaction Details in Column (for portrait mode)
  Widget _buildTransactionDetailsColumn() {
    return Column(
      children: [
        TextFormField(
          controller: _sourceCurrencyController,
          decoration: InputDecoration(
            labelText: 'From Currency *',
            hintText: 'e.g., USD',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.currency_bitcoin),
            errorText: _sourceCurrencyValidated && (_sourceCurrencyController.text.isEmpty || _sourceCurrencyController.text.length != 3)
                ? '3-letter code'
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _sourceCurrencyValidated = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter currency code';
            }
            if (value.length != 3) {
              return 'Currency code must be 3 letters';
            }
            if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(value)) {
              return 'Only letters allowed';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _targetCurrencyController,
          decoration: InputDecoration(
            labelText: 'To Currency *',
            hintText: 'e.g., EUR',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.currency_yen),
            errorText: _targetCurrencyValidated && (_targetCurrencyController.text.isEmpty || _targetCurrencyController.text.length != 3)
                ? '3-letter code'
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _targetCurrencyValidated = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter currency code';
            }
            if (value.length != 3) {
              return 'Currency code must be 3 letters';
            }
            if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(value)) {
              return 'Only letters allowed';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Transaction Details in Row (for landscape mode)
  Widget _buildTransactionDetailsRow(bool isLargeScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _sourceCurrencyController,
            decoration: InputDecoration(
              labelText: 'From Currency *',
              hintText: 'e.g., USD',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_bitcoin),
              errorText: _sourceCurrencyValidated && (_sourceCurrencyController.text.isEmpty || _sourceCurrencyController.text.length != 3)
                  ? '3-letter code'
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _sourceCurrencyValidated = true;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter currency code';
              }
              if (value.length != 3) {
                return 'Currency code must be 3 letters';
              }
              if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(value)) {
                return 'Only letters allowed';
              }
              return null;
            },
          ),
        ),
        SizedBox(width: isLargeScreen ? 16 : 12),
        Expanded(
          child: TextFormField(
            controller: _targetCurrencyController,
            decoration: InputDecoration(
              labelText: 'To Currency *',
              hintText: 'e.g., EUR',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.currency_yen),
              errorText: _targetCurrencyValidated && (_targetCurrencyController.text.isEmpty || _targetCurrencyController.text.length != 3)
                  ? '3-letter code'
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _targetCurrencyValidated = true;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter currency code';
              }
              if (value.length != 3) {
                return 'Currency code must be 3 letters';
              }
              if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(value)) {
                return 'Only letters allowed';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // Buttons in Column (for portrait mode)
  Widget _buildButtonsColumn() {
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

  // Buttons in Row (for landscape mode)
  Widget _buildButtonsRow() {
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
  }

  // ... REST OF YOUR EXISTING METHODS REMAIN EXACTLY THE SAME ...
  // _submitForm(), _generateAndSendForexEmail(), _generateEmailBody(),
  // _sendEmailViaResendAPI(), _showFinalSuccessDialog(), _showManualEmailOption(),
  // _launchEmailApp(), _buildProperlyEncodedEmailUrl(), _showSuccessDialog(),
  // _showErrorDialog(), _resetForm(), dispose() methods remain unchanged

  void _submitForm() async {
    // Mark all fields as validated
    setState(() {
      _nameValidated = true;
      _emailValidated = true;
      _phoneValidated = true;
      _sourceCurrencyValidated = true;
      _targetCurrencyValidated = true;
      _amountValidated = true;
      _purposeValidated = true;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _generateAndSendForexEmail();
      
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

  Future<void> _generateAndSendForexEmail() async {
    try {
      final subject = 'JRR GO Forex Service Request - ${_nameController.text}';
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
      final subject = 'JRR GO Forex Service Request - ${_nameController.text}';
      final body = _generateEmailBody();
      _showManualEmailOption(subject, body);
    }
  }

  String _generateEmailBody() {
  final now = DateTime.now();
  
  return '''
**FOREX SERVICE REQUEST - CLIENT SUBMISSION**

**SUBMISSION DETAILS**
• Submitted: ${_emailDateFormatter.format(now)}
• Service Type: $_selectedService

**CLIENT INFORMATION**
• Full Name: ${_nameController.text}
• Email Address: ${_emailController.text}
• Phone Number: ${_phoneController.text}

**TRANSACTION DETAILS**
• Source Currency: ${_sourceCurrencyController.text.toUpperCase()}
• Target Currency: ${_targetCurrencyController.text.toUpperCase()}
• Amount: ${_amountController.text} ${_sourceCurrencyController.text.toUpperCase()}
• Conversion Request: ${_sourceCurrencyController.text.toUpperCase()} to ${_targetCurrencyController.text.toUpperCase()}

**PURPOSE OF TRANSACTION**
${_purposeController.text}

**REQUEST**
Please provide forex services and current exchange rates for the above transaction.

---
**ACTION REQUIRED:** Please contact the client within 2 hours with current exchange rates and processing details.

Best regards,
JRR Forex Services Team
''';
}

  Future<bool> _sendEmailViaResendAPI(String subject, String body) async {
    try {
      final response = await SupabaseStorageService.sendApplicationEmail(
        subject: subject,
        body: body,
        toEmails: ['jrrindia@gmail.com'],
        ccEmails: ['jrrgoindia@gmail.com'],
        applicationId: 'FOREX-${DateTime.now().millisecondsSinceEpoch}',
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
            const Text('Your forex service request has been sent to our team.'),
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
                'Our forex team will contact you within 2 hours with the best exchange rates.',
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
            Text('Your forex service request has been prepared successfully!', style: GoogleFonts.inter()),
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
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _amountController.clear();
    _sourceCurrencyController.clear();
    _targetCurrencyController.clear();
    _purposeController.clear();
    
    setState(() {
      _selectedService = 'Currency Exchange';
      _nameValidated = false;
      _emailValidated = false;
      _phoneValidated = false;
      _sourceCurrencyValidated = false;
      _targetCurrencyValidated = false;
      _amountValidated = false;
      _purposeValidated = false;
    });
    
    // Close any open dialogs
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _sourceCurrencyController.dispose();
    _targetCurrencyController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
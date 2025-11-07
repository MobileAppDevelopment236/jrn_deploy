import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:jrr_immigration_app/services/supabase_storage_service.dart';
import 'package:jrr_immigration_app/services/database_service.dart';
import 'package:jrr_immigration_app/utils/security_utils.dart';
final _emailDateFormatter = DateFormat('MMMM dd, yyyy \'at\' hh:mm a', 'en_IN');


/// Enhanced Country model with restrictions
class Country {
  final String name;
  final String code;
  final String? emoji;
  final bool isBanned;
  final bool isRestricted;
  final String? restrictionNote;
  
  const Country({
    required this.name, 
    required this.code, 
    this.emoji,
    this.isBanned = false,
    this.isRestricted = false,
    this.restrictionNote,
  });
}

/// Passenger Type model
class PassengerType {
  final String type;
  final String description;
  final double feeMultiplier;
  final List<String> allowedVisaTypes;
  
  const PassengerType({
    required this.type,
    required this.description,
    this.feeMultiplier = 1.0,
    this.allowedVisaTypes = const ['All'],
  });
}

/// Enhanced Visa Type model with specific fields
class VisaType {
  final String name;
  final String category;
  final List<String> requiredFields;
  final List<String> allowedPassengerTypes;
  
  const VisaType({
    required this.name,
    required this.category,
    this.requiredFields = const [],
    this.allowedPassengerTypes = const ['All'],
  });
}

/// Student Specific Information
class StudentInfo {
  String institutionName;
  String courseName;
  String duration;
  String studentId;
  String educationLevel;
  
  StudentInfo({
    this.institutionName = '',
    this.courseName = '',
    this.duration = '',
    this.studentId = '',
    this.educationLevel = '',
  });
}

/// Business Specific Information
class BusinessInfo {
  String companyName;
  String businessPurpose;
  String invitationCompany;
  String position;
  String businessDuration;
  
  BusinessInfo({
    this.companyName = '',
    this.businessPurpose = '',
    this.invitationCompany = '',
    this.position = '',
    this.businessDuration = '',
  });
}

/// Work Specific Information
class WorkInfo {
  String employerName;
  String jobTitle;
  String contractDuration;
  String salary;
  String workPermitNumber;
  
  WorkInfo({
    this.employerName = '',
    this.jobTitle = '',
    this.contractDuration = '',
    this.salary = '',
    this.workPermitNumber = '',
  });
}

/// Medical Specific Information
class MedicalInfo {
  String hospitalName;
  String treatmentType;
  String doctorName;
  String medicalCondition;
  String treatmentDuration;
  
  MedicalInfo({
    this.hospitalName = '',
    this.treatmentType = '',
    this.doctorName = '',
    this.medicalCondition = '',
    this.treatmentDuration = '',
  });
}

/// Document Upload Class - WITH MEMORY MANAGEMENT
class UploadedDocument {
  final String name;
  final String? path;
  final int size;
  final String extension;
  Uint8List? bytes; // Changed to mutable for memory management
  String? downloadUrl; 
  String? uploadStatus; 

  UploadedDocument({
    required this.name,
    this.path,
    required this.size,
    required this.extension,
    this.bytes,
    this.downloadUrl, 
    this.uploadStatus = 'pending', 
  });

  // ✅ MEMORY CLEANUP METHOD
  void clearBytes() {
    bytes = null;
    debugPrint('🧹 Cleared bytes for document: $name');
  }

  // ✅ ENHANCED COPYWITH WITH MEMORY MANAGEMENT
  UploadedDocument copyWith({
    String? downloadUrl,
    String? uploadStatus,
    Uint8List? bytes,
    bool clearExistingBytes = false,
  }) {
    return UploadedDocument(
      name: name,
      path: path,
      size: size,
      extension: extension,
      bytes: clearExistingBytes ? null : (bytes ?? this.bytes),
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadStatus: uploadStatus ?? this.uploadStatus,
    );
  }

  String get sizeInMB => '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  
  IconData get icon {
    switch (extension.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'jpg': case 'jpeg': case 'png': return Icons.image;
      case 'doc': case 'docx': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }
  
  Color get color {
    switch (extension.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'jpg': case 'jpeg': case 'png': return Colors.green;
      case 'doc': case 'docx': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // ADD THIS METHOD FOR EMAIL DISPLAY
  String get emailDisplay {
    if (downloadUrl != null && downloadUrl!.isNotEmpty) {
      return '• $name (${extension.toUpperCase()} - $sizeInMB)\n  📎 DOWNLOAD: $downloadUrl';
    } else {
      return '• $name (${extension.toUpperCase()} - $sizeInMB)\n  ❌ UPLOAD FAILED';
    }
  }
}

// Banned and Restricted Countries Lists
const List<String> bannedCountriesByIndia = [
  'Pakistan', 'Afghanistan', 'Iraq', 'Sudan', 'Somalia', 
  'Yemen', 'Syria', 'Nigeria', 'Iran', 'North Korea'
];

const List<String> restrictedCountries = [
  'China', 'Bangladesh', 'Myanmar', 'Nepal', 'Bhutan'
];

/// Enhanced Country list with restrictions
const List<Country> kCountries = [
  Country(name: 'United States', code: 'US', emoji: '🇺🇸'),
  Country(name: 'Canada', code: 'CA', emoji: '🇨🇦'),
  Country(name: 'United Kingdom', code: 'GB', emoji: '🇬🇧'),
  Country(name: 'Australia', code: 'AU', emoji: '🇦🇺'),
  Country(name: 'Germany', code: 'DE', emoji: '🇩🇪'),
  Country(name: 'France', code: 'FR', emoji: '🇫🇷'),
  Country(name: 'Italy', code: 'IT', emoji: '🇮🇹'),
  Country(name: 'Spain', code: 'ES', emoji: '🇪🇸'),
  Country(name: 'Japan', code: 'JP', emoji: '🇯🇵'),
  Country(name: 'Singapore', code: 'SG', emoji: '🇸🇬'),
  Country(name: 'Malaysia', code: 'MY', emoji: '🇲🇾'),
  Country(name: 'Thailand', code: 'TH', emoji: '🇹🇭'),
  Country(name: 'United Arab Emirates', code: 'AE', emoji: '🇦🇪'),
  Country(name: 'Qatar', code: 'QA', emoji: '🇶🇦'),
  Country(name: 'Saudi Arabia', code: 'SA', emoji: '🇸🇦'),
  Country(name: 'South Korea', code: 'KR', emoji: '🇰🇷'),
  Country(name: 'New Zealand', code: 'NZ', emoji: '🇳🇿'),
  Country(name: 'Switzerland', code: 'CH', emoji: '🇨🇭'),
  Country(name: 'Netherlands', code: 'NL', emoji: '🇳🇱'),
  Country(name: 'Sweden', code: 'SE', emoji: '🇸🇪'),
  Country(name: 'Norway', code: 'NO', emoji: '🇳🇴'),
  Country(name: 'Denmark', code: 'DK', emoji: '🇩🇰'),
  Country(name: 'Finland', code: 'FI', emoji: '🇫🇮'),
  Country(name: 'Ireland', code: 'IE', emoji: '🇮🇪'),
  Country(name: 'Austria', code: 'AT', emoji: '🇦🇹'),
  Country(name: 'Belgium', code: 'BE', emoji: '🇧🇪'),
  Country(name: 'Portugal', code: 'PT', emoji: '🇵🇹'),
  Country(name: 'Greece', code: 'GR', emoji: '🇬🇷'),
  Country(name: 'Turkey', code: 'TR', emoji: '🇹🇷'),
  Country(name: 'Sri Lanka', code: 'LK', emoji: '🇱🇰'),
  Country(name: 'Kenya', code: 'KE', emoji: '🇰🇪'),
  Country(name: 'Vietnam', code: 'VN', emoji: '🇻🇳'),
  
  // Restricted countries
  Country(
    name: 'China', 
    code: 'CN', 
    emoji: '🇨🇳',
    isRestricted: true,
    restrictionNote: 'Additional documentation and extended processing time required'
  ),
  Country(
    name: 'Bangladesh', 
    code: 'BD', 
    emoji: '🇧🇩',
    isRestricted: true,
    restrictionNote: 'Special considerations apply'
  ),
  Country(
    name: 'Myanmar', 
    code: 'MM', 
    emoji: '🇲🇲',
    isRestricted: true,
    restrictionNote: 'Border restrictions may apply'
  ),
  
  // Banned countries (disabled)
  Country(
    name: 'Pakistan', 
    code: 'PK', 
    emoji: '🇵🇰',
    isBanned: true,
    restrictionNote: 'Not eligible for Indian visa services'
  ),
  Country(
    name: 'Afghanistan', 
    code: 'AF', 
    emoji: '🇦🇫',
    isBanned: true,
    restrictionNote: 'Not eligible for Indian visa services'
  ),
  
  Country(name: 'OTHER', code: 'OT', emoji: '🌍'),
];

/// Enhanced Passenger Types with visa type restrictions
const List<PassengerType> kPassengerTypes = [
  PassengerType(
    type: 'Adult', 
    description: '18+ years', 
    feeMultiplier: 1.0,
    allowedVisaTypes: ['All']
  ),
  PassengerType(
    type: 'Child', 
    description: '2-17 years', 
    feeMultiplier: 0.7,
    allowedVisaTypes: ['Tourist Visa', 'Family Visa', 'Medical Visa', 'Transit Visa']
  ),
  PassengerType(
    type: 'Infant', 
    description: 'Under 2', 
    feeMultiplier: 0.3,
    allowedVisaTypes: ['Tourist Visa', 'Family Visa', 'Medical Visa', 'Transit Visa']
  ),
  PassengerType(
    type: 'Student', 
    description: 'With student ID', 
    feeMultiplier: 0.8,
    allowedVisaTypes: ['Student Visa']
  ),
  PassengerType(
    type: 'Senior', 
    description: '65+ years', 
    feeMultiplier: 0.6,
    allowedVisaTypes: ['Tourist Visa', 'Family Visa', 'Medical Visa']
  ),
];

/// Enhanced Visa Types with specific requirements - SIMPLIFIED
const List<VisaType> kVisaTypes = [
  VisaType(
    name: 'Tourist Visa',
    category: 'Tourism',
    allowedPassengerTypes: ['Adult', 'Child', 'Infant', 'Senior'],
  ),
  VisaType(
    name: 'Business Visa',
    category: 'Business',
    requiredFields: ['companyName', 'businessPurpose', 'position'],
    allowedPassengerTypes: ['Adult'],
  ),
  VisaType(
    name: 'Student Visa',
    category: 'Education',
    requiredFields: ['institutionName', 'courseName', 'duration', 'educationLevel'],
    allowedPassengerTypes: ['Student'],
  ),
  VisaType(
    name: 'Work Visa',
    category: 'Employment',
    requiredFields: ['employerName', 'jobTitle', 'contractDuration'],
    allowedPassengerTypes: ['Adult'],
  ),
  VisaType(
    name: 'Family Visa',
    category: 'Family',
    allowedPassengerTypes: ['Adult', 'Child', 'Infant', 'Senior'],
  ),
  VisaType(
    name: 'Transit Visa',
    category: 'Transit',
    allowedPassengerTypes: ['Adult', 'Child', 'Infant'],
  ),
  VisaType(
    name: 'Medical Visa',
    category: 'Medical',
    requiredFields: ['hospitalName', 'treatmentType', 'doctorName'],
    allowedPassengerTypes: ['Adult', 'Child', 'Infant', 'Senior'],
  ),
  VisaType(
    name: 'eVisa',
    category: 'Electronic',
    allowedPassengerTypes: ['Adult', 'Child', 'Infant', 'Senior'],
  ),
  VisaType(
    name: 'Other',
    category: 'Other',
    allowedPassengerTypes: ['All'],
  ),
];

/// eVisa Countries
const List<String> eVisaCountries = [
  'Turkey', 'Sri Lanka', 'Kenya', 'Vietnam', 'Australia'
];

/// Enhanced Document Upload Constants - SUPPORT ALL REAL-WORLD FORMATS
const int maxFileSize = 15 * 1024 * 1024; // Increased to 15MB for high-quality receipts
const List<String> allowedFileExtensions = [
  'pdf',        // PDF documents
  'jpg',        // JPEG images
  'jpeg',       // JPEG images
  'png',        // PNG images  
  'doc',        // Word documents
  'docx',       // Word documents
  'heic',       // iPhone High Efficiency images
  'heif',       // High Efficiency Image Format
  'webp',       // WebP images
  'bmp',        // Bitmap images
  'tiff',       // TIFF images
  'tif',        // TIFF images
];

/// Fee Structure
const Map<String, int> visaFees = {
  'Tourist Visa': 5000,
  'Business Visa': 5000,
  'Student Visa': 5000,
  'Work Visa': 25000,
  'Family Visa': 5000,
  'Transit Visa': 5000,
  'Medical Visa': 5000,  
  'eVisa': 2000,
  'Other': 0,
};

// ===========================================================================
// STEP 1: UPI PAYMENT CONFIGURATION - JRR INTEGRATED SOLUTIONS
// ===========================================================================

/// UPI Payment Configuration using JRR Integrated Solutions details
const Map<String, dynamic> upiPaymentConfig = {
  'upiId': 'jeebuanuradha@okicici',
  'name': 'JRR INTEGRATED SOLUTIONS',
  'qrCodeImagePath': 'assets/images/JRRupi_qr_code.png', 
  'note': 'Visa Application Fee - JRR INTEGRATED SOLUTIONS',
  'bankAccount': '37249086426',
  'bankName': 'State Bank of India',
  'ifscCode': 'SBIN0071202',
  'gpayNumber': '9848612917',
};

// ===========================================================================
// END OF STEP 1
// ===========================================================================

class VisaScreen extends StatefulWidget {
  const VisaScreen({super.key});

  @override
  State<VisaScreen> createState() => _VisaScreenState();
}

class _VisaScreenState extends State<VisaScreen> {
  int _currentStep = 0;
  //final int _totalSteps = 5; // NEW: Changed from 4 to 5
  bool _isSubmitting = false;
  

  // Document Upload Variables
  final List<UploadedDocument> _uploadedDocuments = [];
  String? _fileUploadError;
  bool _isUploading = false;

  // Form Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otherVisaTypeController = TextEditingController();
  final TextEditingController _previousRefusalController = TextEditingController();
  final TextEditingController _otherCountryController = TextEditingController();

  // Dynamic Passport Controllers
  final List<TextEditingController> _passportControllers = [TextEditingController()];
  final List<TextEditingController> _passengerNameControllers = [TextEditingController()];
  // NEW: Enhanced Passport Controllers
  final List<TextEditingController> _dateOfBirthControllers = [TextEditingController()];
  final List<TextEditingController> _passportIssueDateControllers = [TextEditingController()];
  final List<TextEditingController> _passportExpiryDateControllers = [TextEditingController()];
  final List<TextEditingController> _issuingAuthorityControllers = [TextEditingController()];

  // NEW: Enhanced Passport Error Variables
  final List<String?> _dateOfBirthErrors = [null];
  final List<String?> _passportIssueDateErrors = [null];
  final List<String?> _passportExpiryDateErrors = [null];
  final List<String?> _issuingAuthorityErrors = [null];

  // Visa Specific Controllers
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _educationLevelController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _businessPurposeController = TextEditingController();
  final TextEditingController _invitationCompanyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _businessDurationController = TextEditingController();
  
  final TextEditingController _employerController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _workDurationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _workPermitController = TextEditingController();
  
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _medicalConditionController = TextEditingController();
  final TextEditingController _treatmentDurationController = TextEditingController();

  // Form Data
  VisaType _selectedVisaType = kVisaTypes.first;
  Country _selectedCountry = kCountries.first;
  String? _previousRefusal;
  
  final List<UploadedDocument> _step1UploadedDocuments = [];
  bool _isStep1Uploading = false;
  String? _step1FileUploadError;

  // NEW: Payment State Variables
  String? _selectedPaymentMethod; // 'payNow' or 'payLater'
  bool _paymentCompleted = false;
  String? _paymentReceiptUrl;
  String? _paymentError;
  bool _isProcessingPayment = false;
  String? _applicationId; // ADD THIS LINE - Application ID for consistency

  final Map<String, int> _passengerTypeCounts = {
    'Adult': 1,
    'Child': 0,
    'Infant': 0,
    'Student': 0,
    'Senior': 0,
  };

  DateTime? _travelDate;
  DateTime? _returnDate;

  // Validation Errors
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passengersError;
  String? _otherVisaTypeError;
  String? _otherCountryError;
  final List<String?> _passportErrors = [null];
  final List<String?> _passengerNameErrors = [null];
  String? _travelDateError;
  String? _returnDateError;

  // Visa Specific Errors
  String? _institutionError;
  String? _courseError;
  String? _companyError;
  String? _businessPurposeError;
  String? _employerError;
  String? _jobTitleError;
  String? _hospitalError;
  String? _treatmentError;

 @override
void initState() {
  super.initState();
  _applicationId = _generateApplicationId();
  // DELAY heavy operations to improve initial load
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _updatePassengerControllers();
    _testStorageConnection();
    _logMemoryUsage('App initialized');
  });
}

  @override
  void dispose() {
    // Dispose all controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otherVisaTypeController.dispose();
    _previousRefusalController.dispose();
    _otherCountryController.dispose();
    
    // Dispose visa specific controllers
    _institutionController.dispose();
    _courseController.dispose();
    _studentIdController.dispose();
    _educationLevelController.dispose();
    _durationController.dispose();
    _companyController.dispose();
    _businessPurposeController.dispose();
    _invitationCompanyController.dispose();
    _positionController.dispose();
    _businessDurationController.dispose();
    _employerController.dispose();
    _jobTitleController.dispose();
    _workDurationController.dispose();
    _salaryController.dispose();
    _workPermitController.dispose();
    _hospitalController.dispose();
    _treatmentController.dispose();
    _doctorController.dispose();
    _medicalConditionController.dispose();
    _treatmentDurationController.dispose();
    
    for (final controller in _passportControllers) {
      controller.dispose();
    }
    for (final controller in _passengerNameControllers) {
      controller.dispose();
    }
    // NEW: Dispose enhanced passport controllers
for (final controller in _dateOfBirthControllers) {
  controller.dispose();
}
for (final controller in _passportIssueDateControllers) {
  controller.dispose();
}
for (final controller in _passportExpiryDateControllers) {
  controller.dispose();
}
for (final controller in _issuingAuthorityControllers) {
  controller.dispose();
}
    
    super.dispose();
  }

  // ADD THIS METHOD: Test storage connection
void _testStorageConnection() async {
  debugPrint('🧪 Testing Supabase storage connection...');
  await SupabaseStorageService.testBucketConnection();
}
// ADD THIS NEW METHOD to handle link clicks
// REPLACE the entire _launchDocumentUrl method:
Future<void> _launchDocumentUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open: $url')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error opening link: $e')),
    );
  }
}

  // Fee Calculation
  int get _calculatedFee {
    String visaType = _selectedVisaType.name;
    
    if (visaType == 'eVisa' && eVisaCountries.contains(_selectedCountry.name)) {
      return visaFees['eVisa'] ?? 0;
    }
    
    return visaFees[visaType] ?? 0;
  }

  String get _displayCountry {
    if (_selectedCountry.name == 'OTHER' && _otherCountryController.text.isNotEmpty) {
      return _otherCountryController.text;
    }
    return _selectedCountry.name;
  }

  void _updatePassengerControllers() {
  final totalPassengers = _passengerTypeCounts.values.reduce((a, b) => a + b);
  
  while (_passportControllers.length < totalPassengers) {
    _passportControllers.add(TextEditingController());
    _passengerNameControllers.add(TextEditingController());
    _dateOfBirthControllers.add(TextEditingController());
    _passportIssueDateControllers.add(TextEditingController());
    _passportExpiryDateControllers.add(TextEditingController());
    _issuingAuthorityControllers.add(TextEditingController());
    
    _passportErrors.add(null);
    _passengerNameErrors.add(null);
    _dateOfBirthErrors.add(null);
    _passportIssueDateErrors.add(null);
    _passportExpiryDateErrors.add(null);
    _issuingAuthorityErrors.add(null);
  }
  
  while (_passportControllers.length > totalPassengers) {
    _passportControllers.removeLast().dispose();
    _passengerNameControllers.removeLast().dispose();
    _dateOfBirthControllers.removeLast().dispose();
    _passportIssueDateControllers.removeLast().dispose();
    _passportExpiryDateControllers.removeLast().dispose();
    _issuingAuthorityControllers.removeLast().dispose();
    
    _passportErrors.removeLast();
    _passengerNameErrors.removeLast();
    _dateOfBirthErrors.removeLast();
    _passportIssueDateErrors.removeLast();
    _passportExpiryDateErrors.removeLast();
    _issuingAuthorityErrors.removeLast();
  }
  
  setState(() {});
}

  // Enhanced Passenger Type Validation
  bool _isPassengerTypeAllowed(String passengerType) {
    final visaType = _selectedVisaType;
    
    if (visaType.allowedPassengerTypes.contains('All')) {
      return true;
    }
    
    return visaType.allowedPassengerTypes.contains(passengerType);
  }

  String? _validatePassengerTypesForVisa() {
    final incompatiblePassengers = _passengerTypeCounts.entries
        .where((entry) => entry.value > 0 && !_isPassengerTypeAllowed(entry.key))
        .toList();

    if (incompatiblePassengers.isNotEmpty) {
      final incompatibleTypes = incompatiblePassengers.map((e) => e.key).join(', ');
      return '${_selectedVisaType.name} does not allow: $incompatibleTypes';
    }
    
    if (_selectedVisaType.allowedPassengerTypes.length == 1 && 
        _selectedVisaType.allowedPassengerTypes.first != 'All') {
      final requiredType = _selectedVisaType.allowedPassengerTypes.first;
      if (_passengerTypeCounts[requiredType] == 0) {
        return '${_selectedVisaType.name} requires at least one $requiredType passenger';
      }
    }
    
    return null;
  }

  void _resetPassengerCountsForVisaType() {
    final newCounts = <String, int>{};
    final visaType = _selectedVisaType;
    
    for (final passengerType in kPassengerTypes) {
      if (_isPassengerTypeAllowed(passengerType.type)) {
        newCounts[passengerType.type] = _passengerTypeCounts[passengerType.type] ?? 0;
      } else {
        newCounts[passengerType.type] = 0;
      }
    }

    final totalPassengers = newCounts.values.reduce((a, b) => a + b);
    if (totalPassengers == 0 && visaType.allowedPassengerTypes.isNotEmpty) {
      final defaultType = visaType.allowedPassengerTypes.first == 'All' 
          ? 'Adult' 
          : visaType.allowedPassengerTypes.first;
      newCounts[defaultType] = 1;
    }

    setState(() {
      _passengerTypeCounts.clear();
      _passengerTypeCounts.addAll(newCounts);
      _updatePassengerControllers();
    });
  }

  // Validation Methods
  String? _validateName(String value, String fieldName) {
    final sanitizedValue = SecurityUtils.sanitizeInput(value);
    final trimmed = sanitizedValue.trim();
    if (trimmed.isEmpty) return '$fieldName is required';
    if (trimmed.length < 2) return '$fieldName must be at least 2 characters';
    if (SecurityUtils.hasMaliciousContent(trimmed)) {
    return '$fieldName contains invalid characters';
    }
    if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ\s'-]+$").hasMatch(trimmed)) {
      return '$fieldName contains invalid characters';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) return 'Enter a valid phone number';
    return null;
  }

  String? _validatePassengers() {
    final totalPassengers = _passengerTypeCounts.values.reduce((a, b) => a + b);
    if (totalPassengers < 1 || totalPassengers > 20) return 'Enter number between 1-20';
    
    final visaValidationError = _validatePassengerTypesForVisa();
    if (visaValidationError != null) {
      return visaValidationError;
    }
    
    return null;
  }

  String? _validatePassportNumber(String value) {
    if (value.trim().isEmpty) return 'Passport number is required';
    final v = value.trim().toUpperCase();
    if (v.length < 6 || v.length > 12) return 'Passport number must be 6-12 characters';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(v)) return 'Only letters and numbers allowed';
    return null;
  }
  ///new code - start  issuingauthority, DOB field etc....
  // NEW VALIDATION METHODS FOR ENHANCED PASSPORT FIELDS:

// REPLACE THESE VALIDATION METHODS:

// FIXED VALIDATION METHODS:

// FIXED DATE VALIDATION METHODS:

String? _validateDateOfBirth(String value) {
  if (value.trim().isEmpty) return 'Date of Birth is required';
  
  try {
    final date = _parseDate(value);
    if (date == null) return 'Enter valid date (DD/MM/YYYY)';
    
    final today = DateTime.now();
    final age = today.difference(date).inDays ~/ 365;
    
    if (date.isAfter(today)) return 'Date of Birth cannot be in future';
    if (age < 5) return 'Must be at least 5 years old';
    return null;
  } catch (e) {
    return 'Enter valid date (DD/MM/YYYY)';
  }
}

String? _validatePassportIssueDate(String value, String? dobValue) {
  if (value.trim().isEmpty) return 'Passport Issue Date is required';
  
  try {
    final issueDate = _parseDate(value);
    if (issueDate == null) return 'Enter valid date (DD/MM/YYYY)';
    
    final today = DateTime.now();
    
    if (issueDate.isAfter(today)) return 'Issue Date cannot be in future';
    
    // Validate against Date of Birth
    if (dobValue != null && dobValue.trim().isNotEmpty) {
      final dob = _parseDate(dobValue);
      if (dob != null && issueDate.isBefore(dob)) {
        return 'Issue Date cannot be before Date of Birth';
      }
    }
    
    return null;
  } catch (e) {
    return 'Enter valid date (DD/MM/YYYY)';
  }
}

String? _validatePassportExpiryDate(String value, String? issueDateValue) {
  if (value.trim().isEmpty) return 'Passport Expiry Date is required';
  
  try {
    final expiryDate = _parseDate(value);
    if (expiryDate == null) return 'Enter valid date (DD/MM/YYYY)';
    
    final today = DateTime.now();
    
    if (expiryDate.isBefore(today)) return 'Passport has expired';
    
    // Validate against Issue Date
    if (issueDateValue != null && issueDateValue.trim().isNotEmpty) {
      final issueDate = _parseDate(issueDateValue);
      if (issueDate != null) {
        if (expiryDate.isBefore(issueDate)) {
          return 'Expiry Date must be after Issue Date';
        }
        
        // Check minimum validity (at least 6 months from TODAY)
        final minValidityDate = today.add(const Duration(days: 180));
        if (expiryDate.isBefore(minValidityDate)) {
          return 'Passport must be valid for at least 6 months from today';
        }
      }
    }
    
    return null;
  } catch (e) {
    return 'Enter valid date (DD/MM/YYYY)';
  }
}

// ADD THIS HELPER METHOD FOR SAFE DATE PARSING:
DateTime? _parseDate(String dateString) {
  if (dateString.isEmpty) return null;
  
  try {
    // Try parsing with explicit DD/MM/YYYY format
    final parsed = DateFormat('dd/MM/yyyy').parse(dateString);
    return parsed;
  } catch (e) {
    try {
      // Fallback: try parsing as DateTime directly (for ISO format)
      return DateTime.parse(dateString);
    } catch (e) {
      // Final fallback: try MM/DD/YYYY format
      try {
        return DateFormat('MM/dd/yyyy').parse(dateString);
      } catch (e) {
        return null;
      }
    }
  }
}

String? _validateIssuingAuthority(String value) {
  if (value.trim().isEmpty) return 'Issuing Authority is required';
  if (value.trim().length < 2) return 'Enter valid issuing authority';
  return null;
}
// ===========================================================================
// MEMORY MONITORING
// ===========================================================================

// MEMORY MONITORING METHOD
void _logMemoryUsage(String context) {
  int totalBytes = 0;
  int documentsWithBytes = 0;
  
  // Check Step 1 documents
  for (final doc in _step1UploadedDocuments) {
    if (doc.bytes != null) {
      totalBytes += doc.bytes!.length;
      documentsWithBytes++;
    }
  }
  
  // Check Step 2 documents  
  for (final doc in _uploadedDocuments) {
    if (doc.bytes != null) {
      totalBytes += doc.bytes!.length;
      documentsWithBytes++;
    }
  }
  
  final totalMB = totalBytes / (1024 * 1024);
  
  debugPrint('🧠 MEMORY USAGE at [$context]:');
  debugPrint('   📁 Documents with active bytes: $documentsWithBytes');
  debugPrint('   💾 Total memory used: ${totalMB.toStringAsFixed(2)} MB');
  debugPrint('   📊 Step 1 docs: ${_step1UploadedDocuments.length}');
  debugPrint('   📊 Step 2 docs: ${_uploadedDocuments.length}');
}


// ===========================================================================
// STEP 3: HELPER METHODS FOR UPI PAYMENT
// ===========================================================================

// Helper method for UPI details display
Widget _buildUpiDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

// Copy to clipboard functionality
void _copyToClipboard(String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('UPI ID copied to clipboard: $text'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

// ===========================================================================
// END OF STEP 3
// ===========================================================================


// ===========================================================================
// SIMPLIFIED PAYMENT METHODS
// ===========================================================================

void _uploadPaymentReceipt() async {
  setState(() {
    _isProcessingPayment = true;
    _paymentError = null;
  });

  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedFileExtensions,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      // DEBUG: Print file info for troubleshooting
      debugPrint('📄 Selected file: ${file.name}, size: ${file.size}, bytes: ${file.bytes?.length}');
      
      // ENHANCED FILE VALIDATION
      if (file.size > maxFileSize) {
        setState(() {
          _paymentError = 'File too large (${(file.size / (1024 * 1024)).toStringAsFixed(2)}MB). Maximum: ${maxFileSize ~/ (1024 * 1024)}MB';
          _isProcessingPayment = false;
        });
        return;
      }

      // VALIDATE FILE TYPE - MORE FLEXIBLE
      final fileExtension = _getFileExtension(file.name).toLowerCase();
      debugPrint('🔍 File extension: $fileExtension');
      
      if (!allowedFileExtensions.contains(fileExtension)) {
        setState(() {
          _paymentError = 'File type "$fileExtension" not supported.\n'
              'Supported formats: PDF, JPG, PNG, DOC, DOCX, HEIC, WEBP, BMP, TIFF';
          _isProcessingPayment = false;
        });
        return;
      }

      // ADDITIONAL SAFETY CHECK: Ensure file has bytes
      if (file.bytes == null || file.bytes!.isEmpty) {
        setState(() {
          _paymentError = 'File is empty or cannot be read. Please try selecting the file again.';
          _isProcessingPayment = false;
        });
        return;
      }

      // ACTUAL UPLOAD TO SUPABASE
      final receiptUrl = await SupabaseStorageService.uploadDocument(
        fileName: 'payment_receipt_${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        fileBytes: file.bytes!,
        applicationId: _applicationId!,
      );

      setState(() {
        _isProcessingPayment = false;
        _paymentCompleted = true;
        _paymentReceiptUrl = receiptUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment receipt uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  } catch (e) {
    debugPrint('💥 Payment receipt upload error: $e');
    setState(() {
      _isProcessingPayment = false;
      _paymentError = 'Error uploading receipt: ${e.toString()}';
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ===========================================================================
// END OF SIMPLIFIED PAYMENT METHODS
// ===========================================================================

// Add this helper method if not already present, or enhance it:
String _getFileExtension(String fileName) {
  try {
    // Handle files with multiple dots and special cases
    final parts = fileName.split('.');
    if (parts.length > 1) {
      String extension = parts.last.toLowerCase();
      
      // Handle special cases
      if (extension == 'jpeg') return 'jpg';
      if (extension == 'tiff') return 'tif';
      
      return extension;
    }
    return 'unknown';
  } catch (e) {
    return 'unknown';
  }
}


  String? _validateTravelDate(DateTime? date) {
    if (date == null) return 'Travel date is required';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (date.isBefore(yesterday)) return 'Travel date cannot be in the past';
    return null;
  }

  String? _validateReturnDate(DateTime? returnDate, DateTime? travelDate) {
    if (returnDate == null) return 'Return date is required';
    if (travelDate != null && returnDate.isBefore(travelDate)) {
      return 'Return date must be on or after travel date';
    }
    if (returnDate.isBefore(DateTime.now())) return 'Return date cannot be in the past';
    return null;
  }

  String? _validateOtherVisaType(String value) {
    if (_selectedVisaType.name == 'Other' && value.trim().isEmpty) {
      return 'Please specify your visa type';
    }
    if (value.trim().isNotEmpty && value.trim().length < 3) {
      return 'Visa type must be at least 3 characters';
    }
    return null;
  }

  String? _validateOtherCountry(String value) {
    if (_selectedCountry.name == 'OTHER' && value.trim().isEmpty) {
      return 'Please specify your destination country';
    }
    if (value.trim().isNotEmpty && value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }
    return null;
  }

  // Visa Specific Validations
  String? _validateRequiredField(String value, String fieldName) {
    if (value.trim().isEmpty) return '$fieldName is required for ${_selectedVisaType.name}';
    return null;
  }

  // Step Validators
  bool _validateStep1() {
    setState(() {
      _firstNameError = _validateName(_firstNameController.text, 'First name');
      _lastNameError = _validateName(_lastNameController.text, 'Last name');
      _emailError = _validateEmail(_emailController.text);
      _phoneError = _validatePhone(_phoneController.text);
      _passengersError = _validatePassengers();
      _otherVisaTypeError = _validateOtherVisaType(_otherVisaTypeController.text);
      
      // Visa specific validations
      _institutionError = _validateRequiredField(_institutionController.text, 'Institution name');
      _courseError = _validateRequiredField(_courseController.text, 'Course name');
      _companyError = _validateRequiredField(_companyController.text, 'Company name');
      _businessPurposeError = _validateRequiredField(_businessPurposeController.text, 'Business purpose');
      _employerError = _validateRequiredField(_employerController.text, 'Employer name');
      _jobTitleError = _validateRequiredField(_jobTitleController.text, 'Job title');
      _hospitalError = _validateRequiredField(_hospitalController.text, 'Hospital name');
      _treatmentError = _validateRequiredField(_treatmentController.text, 'Treatment type');
    });

    final basicValid = _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passengersError == null &&
        _otherVisaTypeError == null;

    // Check visa specific required fields
    bool visaSpecificValid = true;
    for (final field in _selectedVisaType.requiredFields) {
      switch (field) {
        case 'institutionName':
          if (_institutionError != null) visaSpecificValid = false;
          break;
        case 'courseName':
          if (_courseError != null) visaSpecificValid = false;
          break;
        case 'companyName':
          if (_companyError != null) visaSpecificValid = false;
          break;
        case 'businessPurpose':
          if (_businessPurposeError != null) visaSpecificValid = false;
          break;
        case 'employerName':
          if (_employerError != null) visaSpecificValid = false;
          break;
        case 'jobTitle':
          if (_jobTitleError != null) visaSpecificValid = false;
          break;
        case 'hospitalName':
          if (_hospitalError != null) visaSpecificValid = false;
          break;
        case 'treatmentType':
          if (_treatmentError != null) visaSpecificValid = false;
          break;
      }
    }

    return basicValid && visaSpecificValid;
  }

  bool _validateStep2() {
  bool allPassportsValid = true;
  bool allNamesValid = true;
  bool allDOBValid = true;
  bool allIssueDateValid = true;
  bool allExpiryDateValid = true;
  bool allAuthorityValid = true;
  
  for (int i = 0; i < _passportControllers.length; i++) {
    _passportErrors[i] = _validatePassportNumber(_passportControllers[i].text);
    _passengerNameErrors[i] = _validateName(_passengerNameControllers[i].text, 'Passenger name');
    _dateOfBirthErrors[i] = _validateDateOfBirth(_dateOfBirthControllers[i].text);
    _passportIssueDateErrors[i] = _validatePassportIssueDate(
      _passportIssueDateControllers[i].text, 
      _dateOfBirthControllers[i].text
    );
    _passportExpiryDateErrors[i] = _validatePassportExpiryDate(
      _passportExpiryDateControllers[i].text, 
      _passportIssueDateControllers[i].text
    );
    _issuingAuthorityErrors[i] = _validateIssuingAuthority(_issuingAuthorityControllers[i].text);
    
    if (_passportErrors[i] != null) allPassportsValid = false;
    if (_passengerNameErrors[i] != null) allNamesValid = false;
    if (_dateOfBirthErrors[i] != null) allDOBValid = false;
    if (_passportIssueDateErrors[i] != null) allIssueDateValid = false;
    if (_passportExpiryDateErrors[i] != null) allExpiryDateValid = false;
    if (_issuingAuthorityErrors[i] != null) allAuthorityValid = false;
  }
  
  setState(() {});
  
  return allPassportsValid && allNamesValid && allDOBValid && allIssueDateValid && allExpiryDateValid && allAuthorityValid;
}

  bool _validateStep3() {
    setState(() {
      _travelDateError = _validateTravelDate(_travelDate);
      _returnDateError = _validateReturnDate(_returnDate, _travelDate);
      _otherCountryError = _validateOtherCountry(_otherCountryController.text);
    });
    return _travelDateError == null && _returnDateError == null && _otherCountryError == null;
  }

  // NEW: Step 4 Validation (Payment & Documents)
bool _validateStep4() {
  // Validate payment method selection
  if (_selectedPaymentMethod == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a payment method'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  // For PayNow, validate payment is completed
  if (_selectedPaymentMethod == 'payNow' && !_paymentCompleted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete the payment process'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  return true;
}

  // Document Upload Methods
  Future<void> _pickDocuments() async {
    try {
      setState(() {
        _isUploading = true;
        _fileUploadError = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedFileExtensions,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        _processSelectedFiles(result.files);
      }
    } catch (e) {
      setState(() {
        _fileUploadError = 'Error selecting files: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _processSelectedFiles(List<PlatformFile> files) {
    List<String> errors = [];
    List<UploadedDocument> validFiles = [];

    for (var file in files) {
      // SAFE way to get file extension on web
      final fileExtension = _getFileExtension(file.name);
      
      // Validate file type
      if (!allowedFileExtensions.contains(fileExtension)) {
        errors.add('${file.name}: File type not allowed');
        continue;
      }

      // Validate file size
      if (file.size > maxFileSize) {
        errors.add('${file.name}: File too large (${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB)');
        continue;
      }

      // Check for duplicates
      bool isDuplicate = _uploadedDocuments.any((doc) => 
          doc.name == file.name && doc.size == file.size);
      
      if (isDuplicate) {
        errors.add('${file.name}: File already uploaded');
        continue;
      }

      // WEB-COMPATIBLE: Don't use file.path on web
      validFiles.add(UploadedDocument(
        name: file.name,
        path: null, // Don't use path on web
        size: file.size,
        extension: fileExtension,
        bytes: file.bytes, // Use bytes instead
      ));
    }

    setState(() {
      _uploadedDocuments.addAll(validFiles);
      if (errors.isNotEmpty) {
        _fileUploadError = errors.join('\n');
      }
    });

    _logMemoryUsage('After processing selected files');

  }

  
  void _removeDocument(int index) {
    setState(() {
      _uploadedDocuments.removeAt(index);
      _fileUploadError = null;
    });
  }
  // ADD THIS METHOD RIGHT HERE:
void _removeStep1Document(int index) {
  setState(() {
    _step1UploadedDocuments.removeAt(index);
    _step1FileUploadError = null;
  });
}

  void _showCompressionTips() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('File Size Reduction Tips'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For All File Types:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '• Maximum file size: 15MB\n'
              '• Use built-in phone editors to reduce size\n'
              '• Avoid screenshots - use original files\n'
              '• For iPhone HEIC: Convert to JPG in Photos app',
            ),
            SizedBox(height: 12),
            Text(
              'Image Files (JPG, PNG, HEIC, WEBP, BMP, TIFF):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '• Reduce quality to 80-90%\n'
              '• Resize to 1500px maximum width\n'
              '• Use "Photo Compressor" mobile apps\n'
              '• Scan documents in black & white mode',
            ),
            SizedBox(height: 12),
            Text(
              'Document Files (PDF, DOC, DOCX):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '• Use "SmallPDF" or "iLovePDF" online tools\n'
              '• Remove unnecessary pages\n'
              '• Use "Reduce File Size" in Adobe Reader\n'
              '• Convert to optimized PDF format',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got It'),
        ),
      ],
    ),
  );
}

  // Document Upload UI
  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Supporting Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload required documents (Max 10MB per file)',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickDocuments,
            icon: _isUploading 
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload),
            label: Text(_isUploading ? 'Selecting Files...' : 'Select Documents'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.blue.shade400),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Compression Tips
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange.shade600),
            const SizedBox(width: 4),
            const Text('Large files? ', style: TextStyle(fontSize: 12)),
            GestureDetector(
              onTap: _showCompressionTips,
              child: Text(
                'Learn how to reduce size',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        
        // Allowed File Types - SHOW ALL SUPPORTED FORMATS
Wrap(
  spacing: 8,
  runSpacing: 4,
  children: [
    _buildFileTypeChip('PDF', Icons.picture_as_pdf, Colors.red),
    _buildFileTypeChip('JPG', Icons.image, Colors.green),
    _buildFileTypeChip('PNG', Icons.image, Colors.blue),
    _buildFileTypeChip('DOC', Icons.description, Colors.blue.shade700),
    _buildFileTypeChip('HEIC', Icons.camera_alt, Colors.purple),
    _buildFileTypeChip('WEBP', Icons.image_search, Colors.orange),
    _buildFileTypeChip('BMP', Icons.photo_library, Colors.brown),
    _buildFileTypeChip('TIFF', Icons.high_quality, Colors.teal),
  ],
),

        // Error Message
        if (_fileUploadError != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _fileUploadError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],

        // Uploaded Files List
        if (_uploadedDocuments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Uploaded Documents (${_uploadedDocuments.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ..._uploadedDocuments.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return _buildDocumentItem(file, index);
          }),
        ],

        // No Files Message
        if (_uploadedDocuments.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                const Text('No documents uploaded yet'),
                const SizedBox(height: 4),
                Text(
                  'Supported: PDF, JPG, PNG, DOC, DOCX • Max 10MB each',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileTypeChip(String label, IconData icon, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDocumentItem(UploadedDocument file, int index) {
  final hasDownloadLink = file.downloadUrl != null && file.downloadUrl!.isNotEmpty;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Icon(file.icon, color: file.color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${file.extension.toUpperCase()} • ${file.sizeInMB}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (file.uploadStatus != null && file.uploadStatus != 'pending')
                Text(
                  'Status: ${file.uploadStatus}',
                  style: TextStyle(
                    fontSize: 10,
                    color: file.uploadStatus == 'uploaded' ? Colors.green : Colors.orange,
                  ),
                ),
              // ADD THIS: Show clickable link when available
              if (hasDownloadLink) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _launchDocumentUrl(file.downloadUrl!),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 12, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Click to view/download',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeDocument(index),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    ),
  );
}
  // UI Components
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // FIX: Prevent scroll jumps
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your personal details and select visa type.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // SIMPLIFIED Visa Type Dropdown
          DropdownButtonFormField<VisaType>(
            initialValue: _selectedVisaType,
            decoration: const InputDecoration(
              labelText: 'Visa Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.assignment),
              filled: true,
              fillColor: Colors.white,
            ),
            dropdownColor: Colors.white,
            items: kVisaTypes.map((visaType) {
              return DropdownMenuItem<VisaType>(
                value: visaType,
                child: Text(
                  visaType.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedVisaType = val;
                  _resetPassengerCountsForVisaType();
                  _passengersError = _validatePassengers();
                  if (val.name != 'Other') {
                    _otherVisaTypeController.clear();
                    _otherVisaTypeError = null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // ADD THIS: Visa-specific document requirements note
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.blue[50],
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.blue.shade200),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Document Requirements for ${_selectedVisaType.name}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _getVisaDocumentRequirements(),
        style: TextStyle(
          color: Colors.blue[800],
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 8),
      Text(
  'You can upload these documents now using the upload section below, or in the next step.',
  style: TextStyle(
    color: Colors.blue[700],
    fontSize: 11,
    fontStyle: FontStyle.italic,
  ),
),
    ],
  ),
),
const SizedBox(height: 16),
// ADD THIS: Step 1 Document Upload Section
_buildStep1DocumentUploadSection(),
const SizedBox(height: 16),

          // Custom Visa Type Input Field
          if (_selectedVisaType.name == 'Other') ...[
            TextFormField(
              controller: _otherVisaTypeController,
              decoration: InputDecoration(
                labelText: 'Specify Your Visa Type *',
                hintText: 'e.g., Cultural Exchange, Sports, etc.',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
                errorText: _otherVisaTypeError,
              ),
              onChanged: (v) => setState(() => _otherVisaTypeError = _validateOtherVisaType(v)),
            ),
            const SizedBox(height: 16),
          ],

          // Visa Specific Information Sections
          _buildVisaSpecificFields(),

          // Personal Information Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name *',
                    hintText: 'As per passport',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _firstNameError,
                  ),
                  onChanged: (v) => setState(() => _firstNameError = _validateName(v, 'First name')),
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
                    errorText: _lastNameError,
                  ),
                  onChanged: (v) => setState(() => _lastNameError = _validateName(v, 'Last name')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    errorText: _emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (v) => setState(() => _emailError = _validateEmail(v)),
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
                    errorText: _phoneError,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => setState(() => _phoneError = _validatePhone(v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Previous Refusal Field - FIXED
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previous Visa Refusal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Have you had any previous visa refusals? (Optional)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _previousRefusal = 'no';
                  _previousRefusalController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: _previousRefusal == 'no' ? Colors.blue[50] : Colors.transparent,
                  border: Border(right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Container( // ← ADD THIS LINE
  constraints: const BoxConstraints(maxWidth: 100), // ← ADD THIS LINE
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'no',
                      groupValue: _previousRefusal,
                      onChanged: (String? value) {
                        setState(() {
                          _previousRefusal = value;
                          _previousRefusalController.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('No'),
                  ],
                ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _previousRefusal = 'yes';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: _previousRefusal == 'yes' ? Colors.blue[50] : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: 'yes',
                      groupValue: _previousRefusal,
                      onChanged: (String? value) {
                        setState(() {
                          _previousRefusal = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Yes'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),

              if (_previousRefusal == 'yes') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _previousRefusalController,
                  maxLines: 3,
                  maxLength: 120, // Fixed to 120 characters as requested
                  decoration: const InputDecoration(
                    labelText: 'Please provide details of previous refusal',
                    hintText: 'Country, visa type, date, and reason if known (max 120 characters)...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Passenger Type Selector
          _buildPassengerTypeSelector(),
        ],
      ),
    );
  }

  Widget _buildStep2() {
  return SingleChildScrollView(
    physics: const ClampingScrollPhysics(), // FIX: Prevent scroll jumps
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passport Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter passport details for all passengers and upload required documents.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // ⭐⭐⭐ STEP 4: ADDED DOCUMENT UPLOAD REMINDER HERE ⭐⭐⭐
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Remember to upload the required ${_selectedVisaType.name} documents mentioned in the previous step',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ⭐⭐⭐ END OF ADDED CODE ⭐⭐⭐

        _buildDynamicPassportFields(),
        
        // Document Upload Section
        _buildDocumentUploadSection(),
      ],
    ),
  );
}

  Widget _buildStep3() {
    final duration = (_travelDate != null && _returnDate != null && _returnDate!.isAfter(_travelDate!))
        ? _returnDate!.difference(_travelDate!).inDays
        : 0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // FIX: Prevent scroll jumps
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select destination country and travel dates.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Destination Country *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_displayCountry)),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (_selectedCountry.name == 'OTHER') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherCountryController,
                  decoration: InputDecoration(
                    labelText: 'Specify Your Destination Country *',
                    hintText: 'e.g., Brazil, South Africa, etc.',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    errorText: _otherCountryError,
                  ),
                  onChanged: (v) => setState(() {
                    _otherCountryError = _validateOtherCountry(v);
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: _travelDate != null ? DateFormat('dd/MM/yyyy').format(_travelDate!) : ''),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Travel Date *',
                    hintText: 'Select date',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.flight_takeoff),
                    errorText: _travelDateError,
                  ),
                  onTap: () => _selectDate('travel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: _returnDate != null ? DateFormat('dd/MM/yyyy').format(_returnDate!) : ''),
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Return Date *',
                    hintText: 'Select date',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.flight_land),
                    errorText: _returnDateError,
                  ),
                  onTap: () => _selectDate('return'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration of Stay',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$duration days',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.schedule, color: Color(0xFF1E88E5), size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Step 4 - Payment & Documents
Widget _buildStep4() {
  return SingleChildScrollView(
    physics: const ClampingScrollPhysics(), // FIX: Prevent scroll jumps
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment & Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete payment and upload required documents.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Service Fee Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Fee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  Text(
                    'Total amount to be paid',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                '₹$_calculatedFee INR',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment Method Selection
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
  child: ListTile(
    title: const Text('Pay Now'),
    subtitle: const Text('Complete payment immediately'),
    leading: Radio<String>(
      value: 'payNow',
      groupValue: _selectedPaymentMethod,
      onChanged: (String? value) {
        setState(() {
          _selectedPaymentMethod = value;
          _paymentCompleted = false; // Reset payment completion when switching to Pay Now
          _paymentReceiptUrl = null; // Reset receipt URL
        });
      },
    ),
  ),
),
                Expanded(
                  child: ListTile(
                    title: const Text('Pay Later'),
                    subtitle: const Text('Pay at office or later online'),
                    leading: Radio<String>(
                      value: 'payLater',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                          _paymentCompleted = false; // Auto-complete for pay later
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pay Now Section (Conditional)
        if (_selectedPaymentMethod == 'payNow') ...[
          _buildPayNowSection(),
          const SizedBox(height: 24),
        ],

        // Payment Receipt Upload (ONLY for PayNow after actual payment)
        if (_selectedPaymentMethod == 'payNow' && _paymentCompleted) ...[
          _buildReceiptUploadSection(),
          const SizedBox(height: 24),
        ],       
      ],
    ),
  );
}

Widget _buildStep1DocumentUploadSection() {
  // Show for ALL visa types that have document requirements
  // Remove the restriction to show for all visa types
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text(
        'Upload Visa Documents Now',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'You can upload required ${_selectedVisaType.name} documents here or in the next step',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 12),

      // Upload Button for Step 1
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isStep1Uploading ? null : _pickStep1Documents,
          icon: _isStep1Uploading 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_upload),
          label: Text(_isStep1Uploading ? 'Uploading...' : 'Upload Visa Documents'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.blue.shade400),
          ),
        ),
      ),

      // Error Message
      if (_step1FileUploadError != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _step1FileUploadError!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
        ),
      ],

      // Uploaded Files List for Step 1
      if (_step1UploadedDocuments.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          'Uploaded Visa Documents (${_step1UploadedDocuments.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ..._step1UploadedDocuments.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return _buildStep1DocumentItem(file, index);
        }),
      ],
    ],
  );
}

// Add this method
Widget _buildStep1DocumentItem(UploadedDocument file, int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Icon(file.icon, color: file.color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${file.extension.toUpperCase()} • ${file.sizeInMB}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (file.uploadStatus != null && file.uploadStatus != 'pending')
                Text(
                  'Status: ${file.uploadStatus}',
                  style: TextStyle(
                    fontSize: 10,
                    color: file.uploadStatus == 'uploaded' ? Colors.green : Colors.orange,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeStep1Document(index),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    ),
  );
}

// Add these methods
Future<void> _pickStep1Documents() async {
  try {
    setState(() {
      _isStep1Uploading = true;
      _step1FileUploadError = null;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: allowedFileExtensions,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _processStep1SelectedFiles(result.files);
    }
  } catch (e) {
    setState(() {
      _step1FileUploadError = 'Error selecting files: ${e.toString()}';
    });
  } finally {
    setState(() {
      _isStep1Uploading = false;
    });
  }
}

void _processStep1SelectedFiles(List<PlatformFile> files) {
  List<String> errors = [];
  List<UploadedDocument> validFiles = [];

  for (var file in files) {
    final fileExtension = _getFileExtension(file.name);
    
    // ENHANCED VALIDATION: Check file type
    if (!allowedFileExtensions.contains(fileExtension)) {
      errors.add('${file.name}: File type "$fileExtension" not allowed. Supported: ${allowedFileExtensions.join(', ')}');
      continue;
    }

    // ENHANCED VALIDATION: Check file size with better error message
    if (file.size > maxFileSize) {
      errors.add('${file.name}: File too large (${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB). Maximum: ${maxFileSize ~/ (1024 * 1024)}MB');
      continue;
    }

    // CRITICAL FIX: Check if file has bytes (this was missing)
    if (file.bytes == null || file.bytes!.isEmpty) {
      errors.add('${file.name}: File is empty or cannot be read. Please try selecting the file again.');
      continue;
    }

    // ENHANCED: Check for duplicates across BOTH Step 1 and Step 2
    bool isDuplicate = _step1UploadedDocuments.any((doc) => 
        doc.name == file.name && doc.size == file.size) ||
        _uploadedDocuments.any((doc) => 
        doc.name == file.name && doc.size == file.size);
    
    if (isDuplicate) {
      errors.add('${file.name}: File already uploaded in current application');
      continue;
    }

    // Create document with bytes preserved
    validFiles.add(UploadedDocument(
      name: file.name,
      path: null,
      size: file.size,
      extension: fileExtension,
      bytes: file.bytes, // ← THIS IS CRITICAL: Ensure bytes are preserved
      uploadStatus: 'pending',
    ));
  }

  setState(() {
    _step1UploadedDocuments.addAll(validFiles);
    if (errors.isNotEmpty) {
      _step1FileUploadError = errors.join('\n');
    }
  });
  
  // DEBUG: Help identify upload issues
  if (validFiles.isNotEmpty) {
    debugPrint('✅ Step 1: Added ${validFiles.length} files with bytes: ${validFiles.map((f) => '${f.name} (${f.bytes?.length ?? 0} bytes)').join(', ')}');
  }
  _logMemoryUsage('After processing Step 1 files');
}



// ===========================================================================
// STEP 2: UPDATED PAY NOW SECTION WITH QR CODE
// ===========================================================================

Widget _buildPayNowSection() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pay Now via UPI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 12),
        
        // UPI Payment Instructions with QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade100,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ACTUAL QR CODE IMAGE - JRR INTEGRATED SOLUTIONS
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Image.asset(
                  //upiPaymentConfig['qrCodeImagePath'],
                  'assets/images/JRRupi_qr_code.png', 
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 60, color: Colors.green.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Scan to Pay',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹$_calculatedFee',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // UPI Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //_buildUpiDetailRow('UPI ID:', upiPaymentConfig['upiId']),
                    _buildUpiDetailRow('Name:', upiPaymentConfig['name']),
                    _buildUpiDetailRow('Amount:', '₹$_calculatedFee INR'),
                    _buildUpiDetailRow('Note:', upiPaymentConfig['note']),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
                // Payment Instructions
Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.blue[50],
    borderRadius: BorderRadius.circular(6),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.info, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Payment Instructions:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '1. Scan the QR code with any UPI app\n'
        '2. Or manually send to UPI ID: ${upiPaymentConfig['upiId']}\n'
        '3. Or send to GPay number: ${upiPaymentConfig['gpayNumber']}\n'
        '4. Complete the payment\n'
        '5. Upload the payment receipt below',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Bank Transfer Option:\n'
        'Account: ${upiPaymentConfig['bankAccount']}\n'
        'Bank: ${upiPaymentConfig['bankName']}\n'
        'IFSC: ${upiPaymentConfig['ifscCode']}',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Manual UPI ID Copy Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manual Payment Option',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      upiPaymentConfig['upiId'],
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 20),
                    onPressed: () {
                      // Copy UPI ID to clipboard
                      _copyToClipboard(upiPaymentConfig['upiId']);
                    },
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Upload Receipt Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : _uploadPaymentReceipt,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessingPayment
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Upload Payment Receipt',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Note
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Application will be processed after receipt verification',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Enhanced Payment Error Display
if (_paymentError != null) ...[
  const SizedBox(height: 8),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(
              'Upload Error',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _paymentError!,
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 Tip: Try compressing large files or converting HEIC to JPG using your phone\'s built-in editor',
          style: TextStyle(
            color: Colors.red[600],
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ),
  ),
],
      ],
    ),
  );
}

// ===========================================================================
// END OF STEP 2
// ===========================================================================



// ===========================================================================
// STEP 4: ENHANCED RECEIPT UPLOAD SECTION
// ===========================================================================

Widget _buildReceiptUploadSection() {
  final hasReceipt = _paymentReceiptUrl != null && _paymentReceiptUrl!.isNotEmpty;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Payment Receipt',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      
      if (!hasReceipt) 
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.orange[50],
          ),
          child: Column(
            children: [
              const Icon(Icons.receipt_long, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              const Text(
                'Receipt Required',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please scan the QR code, complete payment, and upload your receipt',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),
Text(
  'Supported formats: PDF, JPG, PNG, DOC, DOCX, HEIC, WEBP, BMP, TIFF',
  style: TextStyle(
    color: Colors.orange[700],
    fontSize: 12,
    fontWeight: FontWeight.w500,
  ),
  textAlign: TextAlign.center,
),
              const SizedBox(height: 8),
              Text(
                'UPI ID: ${upiPaymentConfig['upiId']}',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      else 
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.green[50],
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 40, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                'Receipt Uploaded Successfully!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your application will be processed after receipt verification',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (_paymentReceiptUrl != null && _paymentReceiptUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchDocumentUrl(_paymentReceiptUrl!),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Uploaded Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

// ===========================================================================
// END OF STEP 4
// ===========================================================================

// NEW: Payment Processing Method
/*
void _processPayment() async {
  setState(() {
    _isProcessingPayment = true;
    _paymentError = null;
  });

  // Simulate payment processing
  await Future.delayed(const Duration(seconds: 2));

  setState(() {
    _isProcessingPayment = false;
    _paymentCompleted = true;
    _paymentReceiptUrl = null; // No receipt uploaded yet
  });

  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Payment completed successfully!'),
      backgroundColor: Colors.green,
    ),
  );

  // In real implementation, this would:
  // 1. Integrate with UPI/payment gateway
  // 2. Get actual payment confirmation
  // 3. Generate receipt automatically
}
*/

  Widget _buildStep5() {
    final String displayVisaType = _selectedVisaType.name == 'Other' && 
        _otherVisaTypeController.text.trim().isNotEmpty
        ? '${_selectedVisaType.name} (${_otherVisaTypeController.text.trim()})'
        : _selectedVisaType.name;

    final passengerBreakdown = _passengerTypeCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');

    final passportDetails = StringBuffer();
for (int i = 0; i < _passportControllers.length; i++) {
  final passengerName = _passengerNameControllers[i].text.isEmpty 
      ? 'Passenger ${i + 1}' 
      : _passengerNameControllers[i].text;
  final passportNumber = _passportControllers[i].text.isEmpty 
      ? 'Not provided' 
      : _passportControllers[i].text;
  final dateOfBirth = _dateOfBirthControllers[i].text.isEmpty 
      ? 'Not provided' 
      : _dateOfBirthControllers[i].text;
  final issueDate = _passportIssueDateControllers[i].text.isEmpty 
      ? 'Not provided' 
      : _passportIssueDateControllers[i].text;
  final expiryDate = _passportExpiryDateControllers[i].text.isEmpty 
      ? 'Not provided' 
      : _passportExpiryDateControllers[i].text;
  final issuingAuthority = _issuingAuthorityControllers[i].text.isEmpty 
      ? 'Not provided' 
      : _issuingAuthorityControllers[i].text;
  
  passportDetails.writeln('• $passengerName:');
  passportDetails.writeln('  Passport: $passportNumber');
  passportDetails.writeln('  Date of Birth: $dateOfBirth');
  passportDetails.writeln('  Issue Date: $issueDate');
  passportDetails.writeln('  Expiry Date: $expiryDate');
  passportDetails.writeln('  Issuing Authority: $issuingAuthority');
  passportDetails.writeln('');
}

    final previousRefusalText = _previousRefusal == 'yes' 
        ? 'Yes - ${_previousRefusalController.text.isNotEmpty ? _previousRefusalController.text : "Details provided"}' 
        : (_previousRefusal == 'no' ? 'No' : 'Not specified');

    // Collect visa specific information for review
    final visaSpecificInfo = StringBuffer();
    if (_selectedVisaType.name == 'Student Visa') {
      if (_institutionController.text.isNotEmpty) visaSpecificInfo.writeln('• Institution: ${_institutionController.text}');
      if (_courseController.text.isNotEmpty) visaSpecificInfo.writeln('• Course: ${_courseController.text}');
      if (_educationLevelController.text.isNotEmpty) visaSpecificInfo.writeln('• Education Level: ${_educationLevelController.text}');
    } else if (_selectedVisaType.name == 'Business Visa') {
      if (_companyController.text.isNotEmpty) visaSpecificInfo.writeln('• Company: ${_companyController.text}');
      if (_positionController.text.isNotEmpty) visaSpecificInfo.writeln('• Position: ${_positionController.text}');
      if (_businessPurposeController.text.isNotEmpty) visaSpecificInfo.writeln('• Purpose: ${_businessPurposeController.text}');
    } else if (_selectedVisaType.name == 'Work Visa') {
      if (_employerController.text.isNotEmpty) visaSpecificInfo.writeln('• Employer: ${_employerController.text}');
      if (_jobTitleController.text.isNotEmpty) visaSpecificInfo.writeln('• Job Title: ${_jobTitleController.text}');
      if (_workDurationController.text.isNotEmpty) visaSpecificInfo.writeln('• Duration: ${_workDurationController.text}');
    } else if (_selectedVisaType.name == 'Medical Visa') {
      if (_hospitalController.text.isNotEmpty) visaSpecificInfo.writeln('• Hospital: ${_hospitalController.text}');
      if (_treatmentController.text.isNotEmpty) visaSpecificInfo.writeln('• Treatment: ${_treatmentController.text}');
      if (_doctorController.text.isNotEmpty) visaSpecificInfo.writeln('• Doctor: ${_doctorController.text}');
    }

    // Document upload info for review with ACTUAL links
    // COMBINE documents from both Step 1 and Step 2
final allDocuments = [..._step1UploadedDocuments, ..._uploadedDocuments];
final totalDocuments = allDocuments.length;

// Document upload info for review with ACTUAL links
final documentInfo = totalDocuments > 0
    ? 'Uploaded Documents (Total: $totalDocuments):\n\n'
        '${allDocuments.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final stepNumber = index < _step1UploadedDocuments.length ? 'Step 1' : 'Step 2';
          
          if (doc.downloadUrl != null && doc.downloadUrl!.isNotEmpty) {
            return '• ${doc.name} (${doc.extension.toUpperCase()} - ${doc.sizeInMB}) - $stepNumber\n  🔗 DOWNLOAD: ${doc.downloadUrl}';
          } else {
            return '• ${doc.name} (${doc.extension.toUpperCase()} - ${doc.sizeInMB}) - $stepNumber\n  ⏳ Pending Upload';
          }
        }).join('\n\n')}'
    : 'No documents uploaded';


    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), // FIX: Prevent scroll jumps
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Application',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify all information before submission.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          _buildReviewItem('Visa Type', displayVisaType),
          _buildReviewItem('Service Fee', '₹$_calculatedFee INR'),
          _buildReviewItem('Payment Method', _selectedPaymentMethod == 'payNow' 
              ? 'Pay Now (UPI QR Code)' 
              : 'Pay Later'),
          _buildReviewItem('Primary Applicant', '${_firstNameController.text} ${_lastNameController.text}'),
          _buildReviewItem('Email', _emailController.text),
          _buildReviewItem('Phone', _phoneController.text),
          _buildReviewItem('Previous Refusal', previousRefusalText),
          _buildReviewItem('Destination Country', _displayCountry),
          _buildReviewItem('Total Passengers', _passengerTypeCounts.values.reduce((a, b) => a + b).toString()),
          if (passengerBreakdown.isNotEmpty) 
            _buildReviewItem('Passenger Types', passengerBreakdown),
          _buildReviewItem('Supporting Documents', documentInfo),
          if (visaSpecificInfo.isNotEmpty)
            _buildReviewItem('${_selectedVisaType.name} Details', visaSpecificInfo.toString()),
          _buildReviewItem('Passport Details', passportDetails.toString()),
          _buildReviewItem('Travel Date', _travelDate != null ? DateFormat('dd/MM/yyyy').format(_travelDate!) : 'Not provided'),
          _buildReviewItem('Return Date', _returnDate != null ? DateFormat('dd/MM/yyyy').format(_returnDate!) : 'Not provided'),
          _buildReviewItem('Duration of Stay', (_travelDate != null && _returnDate != null) ? '${_returnDate!.difference(_travelDate!).inDays} days' : 'Not calculated'),
        ],
      ),
    );
  }

  // Visa Specific Fields Builder
  Widget _buildVisaSpecificFields() {
    switch (_selectedVisaType.name) {
      case 'Student Visa':
        return _buildStudentVisaFields();
      case 'Business Visa':
        return _buildBusinessVisaFields();
      case 'Work Visa':
        return _buildWorkVisaFields();
      case 'Medical Visa':
        return _buildMedicalVisaFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentVisaFields() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Student Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _institutionController,
            decoration: InputDecoration(
              labelText: 'Educational Institution *',
              hintText: 'University/College/School name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.account_balance),
              errorText: _institutionError,
            ),
            onChanged: (v) => setState(() => _institutionError = _validateRequiredField(v, 'Institution name')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _courseController,
                  decoration: InputDecoration(
                    labelText: 'Course/Program *',
                    hintText: 'e.g., Computer Science, MBA',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.menu_book),
                    errorText: _courseError,
                  ),
                  onChanged: (v) => setState(() => _courseError = _validateRequiredField(v, 'Course name')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _educationLevelController,
                  decoration: const InputDecoration(
                    labelText: 'Education Level',
                    hintText: 'e.g., Undergraduate, Masters',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'University student ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Course Duration',
                    hintText: 'e.g., 2 years, 4 semesters',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessVisaFields() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _companyController,
            decoration: InputDecoration(
              labelText: 'Company Name *',
              hintText: 'Your current employer',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business_center),
              errorText: _companyError,
            ),
            onChanged: (v) => setState(() => _companyError = _validateRequiredField(v, 'Company name')),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Position/Designation',
              hintText: 'e.g., Manager, Director',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _businessPurposeController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Business Purpose *',
              hintText: 'Describe the purpose of your business visit...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description),
              errorText: _businessPurposeError,
            ),
            onChanged: (v) => setState(() => _businessPurposeError = _validateRequiredField(v, 'Business purpose')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _invitationCompanyController,
                  decoration: const InputDecoration(
                    labelText: 'Host/Inviting Company',
                    hintText: 'Company you are visiting',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.meeting_room),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _businessDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Expected Duration',
                    hintText: 'e.g., 1 week, 15 days',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkVisaFields() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.engineering, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Employment Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _employerController,
            decoration: InputDecoration(
              labelText: 'Employer Name *',
              hintText: 'Company/organization name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.business),
              errorText: _employerError,
            ),
            onChanged: (v) => setState(() => _employerError = _validateRequiredField(v, 'Employer name')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _jobTitleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title *',
                    hintText: 'e.g., Software Engineer, Manager',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.work),
                    errorText: _jobTitleError,
                  ),
                  onChanged: (v) => setState(() => _jobTitleError = _validateRequiredField(v, 'Job title')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _workDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Contract Duration',
                    hintText: 'e.g., 1 year, 2 years',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _salaryController,
                  decoration: const InputDecoration(
                    labelText: 'Salary/Compensation',
                    hintText: 'Annual/monthly salary',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _workPermitController,
                  decoration: const InputDecoration(
                    labelText: 'Work Permit Number',
                    hintText: 'If already obtained',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalVisaFields() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_hospital, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hospitalController,
            decoration: InputDecoration(
              labelText: 'Hospital/Clinic Name *',
              hintText: 'Medical facility name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.medical_services),
              errorText: _hospitalError,
            ),
            onChanged: (v) => setState(() => _hospitalError = _validateRequiredField(v, 'Hospital name')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _treatmentController,
                  decoration: InputDecoration(
                    labelText: 'Treatment Type *',
                    hintText: 'e.g., Surgery, Therapy',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.healing),
                    errorText: _treatmentError,
                  ),
                  onChanged: (v) => setState(() => _treatmentError = _validateRequiredField(v, 'Treatment type')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    hintText: 'Treating doctor',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _medicalConditionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Medical Condition',
              hintText: 'Brief description of medical condition...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _treatmentDurationController,
            decoration: const InputDecoration(
              labelText: 'Expected Treatment Duration',
              hintText: 'e.g., 2 weeks, 1 month',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
        ],
      ),
    );
  }
  

  Widget _buildPassengerTypeSelector() {
  final totalPassengers = _passengerTypeCounts.values.reduce((a, b) => a + b);
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Passenger Types *',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // FIXED: Use Wrap for better responsive layout that won't overflow
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: kPassengerTypes.map((passengerType) {
                final count = _passengerTypeCounts[passengerType.type] ?? 0;
                final isAllowed = _isPassengerTypeAllowed(passengerType.type);
                
                return SizedBox(
                  width: 110, // Fixed width for consistent sizing
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        passengerType.type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isAllowed ? Colors.black : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isAllowed ? Colors.grey.shade400 : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isAllowed ? Colors.white : Colors.grey[100],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 16, 
                                  color: isAllowed && count > 0 ? const Color(0xFF1E88E5) : Colors.grey[400]),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: isAllowed && count > 0 
                                  ? () => _updatePassengerCount(passengerType.type, count - 1) 
                                  : null,
                            ),
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAllowed ? Colors.black : Colors.grey[400],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 16,
                                  color: isAllowed && totalPassengers < 20 ? const Color(0xFF1E88E5) : Colors.grey[400]),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: isAllowed && totalPassengers < 20 
                                  ? () => _updatePassengerCount(passengerType.type, count + 1) 
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        passengerType.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: isAllowed ? Colors.grey[600] : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isAllowed)
                        Text(
                          'Not available',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Total Passengers Display (UNCHANGED)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Passengers:', 
                           style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800])),
                      Text('$totalPassengers', 
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (_passengersError != null) ...[
        const SizedBox(height: 6),
        Text(
          _passengersError!, 
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 12
          ),
        ),
      ],
    ],
  );
}


  
  void _updatePassengerCount(String type, int newCount) {
    setState(() {
      _passengerTypeCounts[type] = newCount;
      _passengersError = _validatePassengers();
      _updatePassengerControllers();
    });
  }

  Widget _buildDynamicPassportFields() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Passenger Passport Details *',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 12),
      
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _passportControllers.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Passenger Name
                TextFormField(
                  controller: _passengerNameControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter passenger full name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    errorText: _passengerNameErrors[index],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passengerNameErrors[index] = _validateName(value, 'Passenger name');
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Date of Birth
                TextFormField(
                  controller: _dateOfBirthControllers[index],
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    hintText: 'DD/MM/YYYY',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.cake),
                    errorText: _dateOfBirthErrors[index],
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectPassengerDate('dob', index),
                    ),
                  ),
                  onTap: () => _selectPassengerDate('dob', index),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    // Passport Number
                    Expanded(
                      child: TextFormField(
                        controller: _passportControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Passport Number *',
                          hintText: 'AB1234567',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.confirmation_number),
                          errorText: _passportErrors[index],
                        ),
                        onChanged: (value) {
                          if (value != value.toUpperCase()) {
                            _passportControllers[index].value = TextEditingValue(
                              text: value.toUpperCase(),
                              selection: _passportControllers[index].selection,
                            );
                          }
                          setState(() {
                            _passportErrors[index] = _validatePassportNumber(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Issuing Authority
                    Expanded(
                      child: TextFormField(
                        controller: _issuingAuthorityControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Issuing Authority *',
                          hintText: 'e.g., London, UK',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          errorText: _issuingAuthorityErrors[index],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _issuingAuthorityErrors[index] = _validateIssuingAuthority(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    // Passport Issue Date
                    Expanded(
                      child: TextFormField(
                        controller: _passportIssueDateControllers[index],
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Issue Date *',
                          hintText: 'DD/MM/YYYY',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.date_range),
                          errorText: _passportIssueDateErrors[index],
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectPassengerDate('issue', index),
                          ),
                        ),
                        onTap: () => _selectPassengerDate('issue', index),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Passport Expiry Date
                    Expanded(
                      child: TextFormField(
                        controller: _passportExpiryDateControllers[index],
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date *',
                          hintText: 'DD/MM/YYYY',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.event_busy),
                          errorText: _passportExpiryDateErrors[index],
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectPassengerDate('expiry', index),
                          ),
                        ),
                        onTap: () => _selectPassengerDate('expiry', index),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
  Widget _buildReviewItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]))),
          Expanded(flex: 3, child: Text(value.isEmpty ? 'Not provided' : value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  List<Step> _buildSteps() {
  return [
    Step(
      title: const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.w600)), 
      content: _buildStep1(), 
      isActive: _currentStep >= 0, 
      state: _currentStep > 0 ? StepState.complete : StepState.indexed
    ),
    Step(
      title: const Text('Passport Details', style: TextStyle(fontWeight: FontWeight.w600)), 
      content: _buildStep2(), 
      isActive: _currentStep >= 1, 
      state: _currentStep > 1 ? StepState.complete : StepState.indexed
    ),
    Step(
      title: const Text('Travel Plans', style: TextStyle(fontWeight: FontWeight.w600)), 
      content: _buildStep3(), 
      isActive: _currentStep >= 2, 
      state: _currentStep > 2 ? StepState.complete : StepState.indexed
    ),
    // NEW: Payment & Documents Step
    Step(
      title: const Text('Payment & Docs', style: TextStyle(fontWeight: FontWeight.w600)), 
      content: _buildStep4(), 
      isActive: _currentStep >= 3, 
      state: _currentStep > 3 ? StepState.complete : StepState.indexed
    ),
    // CHANGED: Review becomes Step 5
    Step(
      title: const Text('Review', style: TextStyle(fontWeight: FontWeight.w600)), 
      content: _buildStep5(),  // CHANGED: _buildStep4() to _buildStep5()
      isActive: _currentStep >= 4, 
      state: StepState.indexed
    ),
  ];
}

  Future<void> _selectDate(String fieldType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (fieldType == 'travel') {
        _travelDate = picked;
        _travelDateError = _validateTravelDate(picked);
        _returnDateError = _validateReturnDate(_returnDate, _travelDate);
      } else {
        _returnDate = picked;
        _returnDateError = _validateReturnDate(picked, _travelDate);
      }
    });
  }

  // NEW DATE PICKER METHODS FOR PASSPORT FIELDS:

// REPLACE THIS METHOD:

// REPLACE THE ENTIRE _selectPassengerDate METHOD WITH THIS:

Future<void> _selectPassengerDate(String fieldType, int passengerIndex) async {
  DateTime initialDate = DateTime.now();
  DateTime firstDate = DateTime(1900);
  DateTime lastDate = DateTime(2100);

  // Set appropriate date ranges based on field type
  switch (fieldType) {
    case 'dob':
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
      lastDate = DateTime.now(); // Can't select future date for birth
      break;
    case 'issue':
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 5));
      lastDate = DateTime.now(); // Can't select future date for issue
      break;
    case 'expiry':
      initialDate = DateTime.now().add(const Duration(days: 365 * 5));
      firstDate = DateTime.now(); // Can't select past date for expiry
      break;
  }

  try {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format the selected date
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      
      // Update the controller and validation
      setState(() {
        switch (fieldType) {
          case 'dob':
            _dateOfBirthControllers[passengerIndex].text = formattedDate;
            _dateOfBirthErrors[passengerIndex] = _validateDateOfBirth(formattedDate);
            break;
          case 'issue':
            _passportIssueDateControllers[passengerIndex].text = formattedDate;
            _passportIssueDateErrors[passengerIndex] = _validatePassportIssueDate(
              formattedDate, 
              _dateOfBirthControllers[passengerIndex].text
            );
            break;
          case 'expiry':
            _passportExpiryDateControllers[passengerIndex].text = formattedDate;
            _passportExpiryDateErrors[passengerIndex] = _validatePassportExpiryDate(
              formattedDate,
              _passportIssueDateControllers[passengerIndex].text
            );
            break;
        }
      });
    }
  } catch (e) {
    debugPrint('Error in date picker: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting date: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  Future<void> _showCountryPicker() async {
    final Country? selected = await showModalBottomSheet<Country>(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 500,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close), 
                      onPressed: () => Navigator.pop(ctx)
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Some countries have restrictions',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: _showBannedCountriesWarning,
                      child: const Text(
                        'View List',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: kCountries.length,
                  itemBuilder: (context, index) {
                    final country = kCountries[index];
                    return ListTile(
                      leading: Text(country.emoji ?? '', style: const TextStyle(fontSize: 20)),
                      title: Text(country.name),
                      subtitle: country.isBanned 
                        ? const Text('Not eligible', style: TextStyle(color: Colors.red))
                        : country.isRestricted
                          ? Text(country.restrictionNote ?? 'Restricted', style: const TextStyle(color: Colors.orange))
                          : null,
                      trailing: _selectedCountry.name == country.name 
                        ? const Icon(Icons.check, color: Colors.blue) 
                        : null,
                      onTap: country.isBanned 
                        ? null 
                        : () => Navigator.pop(ctx, country),
                      enabled: !country.isBanned,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCountry = selected;
        if (selected.name != 'OTHER') {
          _otherCountryController.clear();
          _otherCountryError = null;
        }
        
        if (selected.isRestricted) {
          _showCountrySpecificWarning(selected);
        }
      });
    }
  }

  void _showBannedCountriesWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Important Notice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel Restrictions Notice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'The following countries are currently restricted/banned for visa applications from India:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            
            const Text(
              '🚫 Banned Countries:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            Text(
              bannedCountriesByIndia.join(', '),
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              '⚠️ Restricted Countries:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            Text(
              restrictedCountries.join(', '),
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Applications for these countries require special consideration and additional documentation.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showCountrySpecificWarning(Country country) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${country.emoji} ${country.name} Visa Notice'),
        content: Text(
          country.restrictionNote ?? 
          'Additional documentation and extended processing time may be required for ${country.name}. '
          'Our team will contact you with specific requirements.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ENHANCED SUPABASE UPLOAD INTEGRATION
  // ===========================================================================

  // Application ID Generation
  String _generateApplicationId() {
    return 'VISA${DateTime.now().millisecondsSinceEpoch}';
  }

  // Enhanced Email Instructions Dialog with Supabase Upload
  void _showEmailInstructionsDialog() {
    final applicationId = _generateApplicationId();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Upload Documents & Send Email'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your documents will be securely uploaded and shared via download links.',
                style: TextStyle(fontSize: 16),
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
                    const Text(
                      '📎 Secure Document Upload',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                    ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Application ID: $applicationId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Documents uploaded to secure cloud storage\n• Download links included in email\n• No file size limitations\n• Backend team can access files directly',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Process:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Upload documents to secure storage'),
              const Text('2. Generate email with download links'),
              const Text('3. Open email app with pre-filled content'),
              const Text('4. Click "SEND" to complete application'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _uploadAndSendEmail(applicationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upload & Send Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndSendEmail(String applicationId) async {
  setState(() {
    _isSubmitting = true;
  });

  // SIMPLE VALIDATION CHECK
  final validationErrors = DatabaseService.validateApplicationData(
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    email: _emailController.text,
    phone: _phoneController.text,
  );

  if (validationErrors.isNotEmpty) {
    setState(() {
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please fill all required fields: ${validationErrors.join(', ')}'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // Check if application ID already exists
    final idExists = await DatabaseService.applicationIdExists(applicationId);
    if (idExists) {
      // Generate new ID if duplicate
      _applicationId = _generateApplicationId();
      applicationId = _applicationId!;
    }

    // STEP 1: Save application to database
    final applicationUuid = await _saveApplicationToDatabase(applicationId);
    
    // STEP 2: Upload documents to Supabase (BOTH Step 1 and Step 2 documents)
    List<String> successfulUploads = [];

    // Combine documents from both steps
    final allDocumentsToUpload = [..._step1UploadedDocuments, ..._uploadedDocuments];

    if (allDocumentsToUpload.isNotEmpty) {
      // FIX: Remove unused variable assignment
      await _uploadAllDocumentsToSupabase(applicationId, applicationUuid);
      
      // Collect successfully uploaded documents from BOTH steps
      successfulUploads = allDocumentsToUpload
          .where((doc) => doc.uploadStatus == 'uploaded' && doc.downloadUrl != null)
          .map((doc) => doc.downloadUrl!)
          .toList();
    }
    
    // STEP 3: Save payment record
    if (_selectedPaymentMethod != null) {
      await _savePaymentToDatabase(applicationUuid);
    }
    
    // STEP 4: Generate and send email with actual download links
    _generateAndSendEmailWithLinks(applicationId, successfulUploads, _paymentReceiptUrl);
    
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error during submission: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
// RESTORED: Complete email generation with all original details
void _generateAndSendEmailWithLinks(String applicationId, List<String> downloadLinks, String? receiptUrl) {
  final subject = 'Visa Application - ${_firstNameController.text} ${_lastNameController.text} (ID: $applicationId)';
  
  final String displayVisaType = _selectedVisaType.name == 'Other' && 
      _otherVisaTypeController.text.trim().isNotEmpty
      ? '${_selectedVisaType.name} (${_otherVisaTypeController.text.trim()})'
      : _selectedVisaType.name;

  final passengerBreakdown = _passengerTypeCounts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => '${entry.key}: ${entry.value}')
      .join(', ');

  // Build clean passport details - RESTORED FROM ORIGINAL
  final passportDetails = StringBuffer();
  for (int i = 0; i < _passportControllers.length; i++) {
    final passengerName = _passengerNameControllers[i].text.isEmpty 
        ? 'Passenger ${i + 1}' 
        : _passengerNameControllers[i].text;
    final passportNumber = _passportControllers[i].text.isEmpty 
        ? 'Not provided' 
        : _passportControllers[i].text;
    final dateOfBirth = _dateOfBirthControllers[i].text.isEmpty 
        ? 'Not provided' 
        : _dateOfBirthControllers[i].text;
    final issueDate = _passportIssueDateControllers[i].text.isEmpty 
        ? 'Not provided' 
        : _passportIssueDateControllers[i].text;
    final expiryDate = _passportExpiryDateControllers[i].text.isEmpty 
        ? 'Not provided' 
        : _passportExpiryDateControllers[i].text;
    final issuingAuthority = _issuingAuthorityControllers[i].text.isEmpty 
        ? 'Not provided' 
        : _issuingAuthorityControllers[i].text;
    
    passportDetails.writeln('• $passengerName:');
    passportDetails.writeln('  Passport: $passportNumber');
    passportDetails.writeln('  Date of Birth: $dateOfBirth');
    passportDetails.writeln('  Issue Date: $issueDate');
    passportDetails.writeln('  Expiry Date: $expiryDate');
    passportDetails.writeln('  Issuing Authority: $issuingAuthority');
    passportDetails.writeln('');
  }

  final duration = (_travelDate != null && _returnDate != null && _returnDate!.isAfter(_travelDate!))
      ? _returnDate!.difference(_travelDate!).inDays
      : 0;

  final previousRefusalText = _previousRefusal == 'yes' 
      ? 'Yes - ${_previousRefusalController.text.isNotEmpty ? _previousRefusalController.text : "Details provided"}' 
      : (_previousRefusal == 'no' ? 'No' : 'Not specified');

  // Build visa-specific information - RESTORED FROM ORIGINAL
  final visaSpecificInfo = StringBuffer();
  if (_selectedVisaType.name == 'Student Visa') {
    if (_institutionController.text.isNotEmpty) visaSpecificInfo.writeln('• Institution: ${_institutionController.text}');
    if (_courseController.text.isNotEmpty) visaSpecificInfo.writeln('• Course: ${_courseController.text}');
    if (_educationLevelController.text.isNotEmpty) visaSpecificInfo.writeln('• Education Level: ${_educationLevelController.text}');
    if (_durationController.text.isNotEmpty) visaSpecificInfo.writeln('• Duration: ${_durationController.text}');
  } else if (_selectedVisaType.name == 'Business Visa') {
    if (_companyController.text.isNotEmpty) visaSpecificInfo.writeln('• Company: ${_companyController.text}');
    if (_positionController.text.isNotEmpty) visaSpecificInfo.writeln('• Position: ${_positionController.text}');
    if (_businessPurposeController.text.isNotEmpty) visaSpecificInfo.writeln('• Purpose: ${_businessPurposeController.text}');
    if (_invitationCompanyController.text.isNotEmpty) visaSpecificInfo.writeln('• Host Company: ${_invitationCompanyController.text}');
  } else if (_selectedVisaType.name == 'Work Visa') {
    if (_employerController.text.isNotEmpty) visaSpecificInfo.writeln('• Employer: ${_employerController.text}');
    if (_jobTitleController.text.isNotEmpty) visaSpecificInfo.writeln('• Job Title: ${_jobTitleController.text}');
    if (_workDurationController.text.isNotEmpty) visaSpecificInfo.writeln('• Duration: ${_workDurationController.text}');
    if (_salaryController.text.isNotEmpty) visaSpecificInfo.writeln('• Salary: ${_salaryController.text}');
  } else if (_selectedVisaType.name == 'Medical Visa') {
    if (_hospitalController.text.isNotEmpty) visaSpecificInfo.writeln('• Hospital: ${_hospitalController.text}');
    if (_treatmentController.text.isNotEmpty) visaSpecificInfo.writeln('• Treatment: ${_treatmentController.text}');
    if (_doctorController.text.isNotEmpty) visaSpecificInfo.writeln('• Doctor: ${_doctorController.text}');
    if (_treatmentDurationController.text.isNotEmpty) visaSpecificInfo.writeln('• Duration: ${_treatmentDurationController.text}');
  }

  // FIX: Combine documents from both steps and calculate accurate counts
  final combinedDocuments = [..._step1UploadedDocuments, ..._uploadedDocuments];
  final totalDocuments = combinedDocuments.length;
  final successfulDocuments = combinedDocuments.where((doc) => 
      doc.downloadUrl != null && doc.downloadUrl!.isNotEmpty).length;
  final failedDocuments = totalDocuments - successfulDocuments;

  // RESTORED: Complete email body with all original sections
  final emailBody = '''
**VISA APPLICATION - NEW SUBMISSION**

**APPLICATION DETAILS**
• Application ID: $applicationId
• Submitted: ${_emailDateFormatter.format(DateTime.now().toLocal())}
• Status: Pending Review

**APPLICANT INFORMATION**
• Primary Applicant: ${_firstNameController.text} ${_lastNameController.text}
• Email: ${_emailController.text}
• Phone: ${_phoneController.text}
• Previous Visa Refusal: $previousRefusalText

**VISA & TRAVEL DETAILS**
• Visa Type: $displayVisaType
• Destination: $_displayCountry
• Travel Dates: ${_travelDate != null ? DateFormat('dd/MM/yyyy').format(_travelDate!) : 'N/A'} to ${_returnDate != null ? DateFormat('dd/MM/yyyy').format(_returnDate!) : 'N/A'}
• Duration: $duration days
• Service Fee: ₹$_calculatedFee INR
• Payment: ${_selectedPaymentMethod == 'payNow' ? 'Paid (UPI)' : 'Pay Later'}

**PASSENGER DETAILS**
• Total Passengers: ${_passengerTypeCounts.values.reduce((a, b) => a + b)}
• Breakdown: $passengerBreakdown

${visaSpecificInfo.isNotEmpty ? '**ADDITIONAL INFORMATION**:\n$visaSpecificInfo' : ''}

**PASSPORT INFORMATION**
$passportDetails

**DOCUMENTS SUMMARY**  
• Total Uploaded: $totalDocuments
• Successful: $successfulDocuments
• Failed: $failedDocuments

${combinedDocuments.isNotEmpty ? 'UPLOADED DOCUMENTS:' : 'No documents uploaded'}
${combinedDocuments.map((doc) {
  if (doc.downloadUrl != null && doc.downloadUrl!.isNotEmpty) {
    return '• ${doc.name} (${doc.extension.toUpperCase()} - ${doc.sizeInMB})\n  Download URL: ${doc.downloadUrl}';
  } else {
    return '• ${doc.name} (${doc.extension.toUpperCase()} - ${doc.sizeInMB}) - UPLOAD FAILED';
  }
}).join('\n\n')}

${receiptUrl != null && receiptUrl.isNotEmpty ? '''
**PAYMENT RECEIPT**
• Receipt URL: $receiptUrl
''' : ''}

---
**ACTION REQUIRED:** Please process this application and contact applicant if additional information needed.

Best regards,
JRR Immigration Services
''';

  _sendVisaEmail(subject, emailBody, receiptUrl, applicationId);
}
  // PROPER Email Sending with Resend API
Future<void> _sendVisaEmail(String subject, String body, String? receiptUrl, String applicationId) async {
  // Remove the local applicationId generation - use the passed parameter
  try {
    setState(() {
      _isSubmitting = true;
    });

    // Use Edge Function to send email
    final emailSent = await _sendEmailViaResendAPI(subject, body, applicationId, receiptUrl);
    
    if (emailSent) {
      if (!mounted) return;
      _showFinalSuccessDialog();
    } else {
      if (!mounted) return;
      // Fallback to manual option
      _showManualEmailOption(subject, body);
    }
  } catch (error) {
    if (!mounted) return;
    print('Email sending error: $error');
    // Fallback: Show manual option
    _showManualEmailOption(subject, body);
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}


// UPDATED Email sending method
Future<bool> _sendEmailViaResendAPI(String subject, String body, String applicationId, String? receiptUrl) async {
  try {
    final response = await SupabaseStorageService.sendApplicationEmail(
      subject: subject,
      body: body,
      toEmails: ['jrrindia@gmail.com'],
      ccEmails: ['jrrgoindia@gmail.com'],
      applicationId: applicationId,
      receiptUrl: receiptUrl,
    );
    
    return response;
  } catch (e) {
    print('Edge Function email error: $e');
    return false;
  }
}

  // Fallback method for email issues
  void _showManualEmailOption(String subject, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email App Not Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not open email app automatically. Please copy the information below and send it manually to:'),
              const SizedBox(height: 8),
              const Text('TO: jrrindia@gmail.com'),
              const Text('CC: jrrgoindia@gmail.com'),
              const SizedBox(height: 16),
              const Text('Subject:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(subject),
              const SizedBox(height: 16),
              const Text('Body:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard functionality can be added here
              Navigator.pop(context);
              _showFinalSuccessDialog();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFinalSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Sent Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your visa application has been sent to our team.'),
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
            child: const Text('OK', style: TextStyle(color: Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
  debugPrint('🧹 Starting form reset with memory cleanup...');
  
  // ✅ CRITICAL: CLEAR BYTES FROM ALL DOCUMENTS BEFORE CLEARING LISTS
  _logMemoryUsage('Before reset');
  
  for (final doc in _step1UploadedDocuments) {
    doc.clearBytes(); // FREE MEMORY
  }
  for (final doc in _uploadedDocuments) {
    doc.clearBytes(); // FREE MEMORY
  }
  
  // Now safely clear the lists
  _step1UploadedDocuments.clear();
  _uploadedDocuments.clear();
  
  // Reset other form state
  setState(() {
    _currentStep = 0;
    _selectedVisaType = kVisaTypes.first;
    _selectedCountry = kCountries.first;
    _travelDate = null;
    _returnDate = null;
    _previousRefusal = null;
    
    // Reset payment data
    _selectedPaymentMethod = null;
    _paymentCompleted = false;
    _paymentReceiptUrl = null;
    _paymentError = null;
    _isProcessingPayment = false;
    _applicationId = _generateApplicationId();
    
    _passengerTypeCounts.clear();
    _passengerTypeCounts.addAll({
      'Adult': 1,
      'Child': 0,
      'Infant': 0,
      'Student': 0,
      'Senior': 0,
    });
    
    // Clear all controllers
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _otherVisaTypeController.clear();
    _previousRefusalController.clear();
    _otherCountryController.clear();
    
    // Clear visa specific controllers
    _institutionController.clear();
    _courseController.clear();
    _studentIdController.clear();
    _educationLevelController.clear();
    _durationController.clear();
    _companyController.clear();
    _businessPurposeController.clear();
    _invitationCompanyController.clear();
    _positionController.clear();
    _businessDurationController.clear();
    _employerController.clear();
    _jobTitleController.clear();
    _workDurationController.clear();
    _salaryController.clear();
    _workPermitController.clear();
    _hospitalController.clear();
    _treatmentController.clear();
    _doctorController.clear();
    _medicalConditionController.clear();
    _treatmentDurationController.clear();
    
    // Clear uploaded documents (already cleared above)
    _fileUploadError = null;
    _step1FileUploadError = null;
    
    // Clear passport controllers
    for (final controller in _passportControllers) {
      controller.clear();
    }
    for (final controller in _passengerNameControllers) {
      controller.clear();
    }
    for (final controller in _dateOfBirthControllers) {
      controller.clear();
    }
    for (final controller in _passportIssueDateControllers) {
      controller.clear();
    }
    for (final controller in _passportExpiryDateControllers) {
      controller.clear();
    }
    for (final controller in _issuingAuthorityControllers) {
      controller.clear();
    }
    
    _updatePassengerControllers();
  });
  
  _logMemoryUsage('After reset');
  debugPrint('✅ Form reset completed with memory cleanup');
}

// ENHANCED: Memory-efficient document upload with byte cleanup
Future<bool> _uploadAllDocumentsToSupabase(String applicationId, String applicationUuid) async {
  // COMBINE documents from both steps
  final allDocumentsToUpload = [..._step1UploadedDocuments, ..._uploadedDocuments];
  
  if (allDocumentsToUpload.isEmpty) {
    debugPrint('📭 No documents to upload');
    return true;
  }
  
  // LOG INITIAL MEMORY USAGE
  _logMemoryUsage('Before upload process');
  
  setState(() {
    _isUploading = true;
    _fileUploadError = null;
    _step1FileUploadError = null;
  });
  
  try {
    int successfulUploads = 0;
    int totalDocuments = allDocumentsToUpload.length;
    
    debugPrint('🚀 Starting upload of $totalDocuments documents');
    
    for (int i = 0; i < totalDocuments; i++) {
      final doc = allDocumentsToUpload[i];
      final isStep1Doc = i < _step1UploadedDocuments.length;
      
      // ✅ SAFETY CHECK: Ensure file has bytes
      if (doc.bytes == null) {
        debugPrint('⚠️ Skipping ${doc.name}: No bytes available');
        continue;
      }
      
      final fileSizeMB = (doc.bytes!.length / (1024 * 1024)).toStringAsFixed(2);
      debugPrint('📤 Uploading ${doc.name} ($fileSizeMB MB)...');
      
      try {
        // UPDATE UI: Show uploading status
        if (isStep1Doc) {
          _step1UploadedDocuments[i] = _step1UploadedDocuments[i].copyWith(
            uploadStatus: 'uploading',
          );
        } else {
          final step2Index = i - _step1UploadedDocuments.length;
          _uploadedDocuments[step2Index] = _uploadedDocuments[step2Index].copyWith(
            uploadStatus: 'uploading',
          );
        }
        setState(() {});
        
        // UPLOAD TO SUPABASE with retry logic
        String downloadUrl;
        try {
          downloadUrl = await SupabaseStorageService.uploadDocument(
            fileName: '${applicationId}_${doc.name}',
            fileBytes: doc.bytes!,
            applicationId: applicationId,
          ).timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint('❌ First upload attempt failed for ${doc.name}: $e');
          // RETRY: Wait 2 seconds and try again
          await Future.delayed(const Duration(seconds: 2));
          downloadUrl = await SupabaseStorageService.uploadDocument(
            fileName: '${applicationId}_${doc.name}',
            fileBytes: doc.bytes!,
            applicationId: applicationId,
          ).timeout(const Duration(seconds: 30));
        }
        
        // SAVE TO DATABASE
        await DatabaseService.saveDocument(
          applicationUuid: applicationUuid,
          documentName: doc.name,
          documentType: doc.extension,
          fileSize: doc.size,
          downloadUrl: downloadUrl,
        );
        
        // ✅ CRITICAL: UPDATE DOCUMENT STATUS AND CLEAR BYTES
        if (isStep1Doc) {
          _step1UploadedDocuments[i] = _step1UploadedDocuments[i].copyWith(
            downloadUrl: downloadUrl,
            uploadStatus: 'uploaded',
          );
          // CLEAR BYTES FROM MEMORY
          _step1UploadedDocuments[i].clearBytes();
        } else {
          final step2Index = i - _step1UploadedDocuments.length;
          _uploadedDocuments[step2Index] = _uploadedDocuments[step2Index].copyWith(
            downloadUrl: downloadUrl,
            uploadStatus: 'uploaded',
          );
          // CLEAR BYTES FROM MEMORY
          _uploadedDocuments[step2Index].clearBytes();
        }
        
        successfulUploads++;
        debugPrint('✅ Successfully uploaded: ${doc.name} - Bytes cleared from memory');
        
        // SMALL DELAY: Avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        debugPrint('❌ Failed to upload ${doc.name}: $e');
        
        // UPDATE FAILED STATUS (but don't clear bytes - allow retry)
        if (isStep1Doc) {
          _step1UploadedDocuments[i] = _step1UploadedDocuments[i].copyWith(
            uploadStatus: 'failed',
          );
        } else {
          final step2Index = i - _step1UploadedDocuments.length;
          _uploadedDocuments[step2Index] = _uploadedDocuments[step2Index].copyWith(
            uploadStatus: 'failed',
          );
        }
      }
      
      setState(() {});
    }
    
    // LOG FINAL MEMORY USAGE
    _logMemoryUsage('After upload process');
    
    // SHOW SUMMARY to user
    final failedCount = totalDocuments - successfulUploads;
    if (failedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$failedCount document(s) failed to upload. Check email for details.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    debugPrint('📊 Upload Summary: $successfulUploads/$totalDocuments successful');
    return successfulUploads > 0;
    
  } catch (e) {
    debugPrint('💥 Upload process failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document upload failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  } finally {
    setState(() {
      _isUploading = false;
    });
  }
}



  // ADD THIS NEW METHOD: Save application to database
Future<String> _saveApplicationToDatabase(String applicationId) async {
  try {
    final applicationData = await DatabaseService.createApplication(
      applicationId: applicationId,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      visaType: _selectedVisaType.name == 'Other' 
          ? _otherVisaTypeController.text 
          : _selectedVisaType.name,
      destinationCountry: _displayCountry,
      travelDate: _travelDate,
      returnDate: _returnDate,
      totalPassengers: _passengerTypeCounts.values.reduce((a, b) => a + b),
      previousRefusal: _previousRefusal,
      refusalDetails: _previousRefusal == 'yes' ? _previousRefusalController.text : null,
    );

    final applicationUuid = applicationData['id'] as String;

    // ✅ ADD THIS PART: Save passport details for each passenger
    for (int i = 0; i < _passportControllers.length; i++) {
      try {
        await DatabaseService.savePassportDetails(
          applicationUuid: applicationUuid,
          passengerName: _passengerNameControllers[i].text,
          passportNumber: _passportControllers[i].text,
          dateOfBirth: _dateOfBirthControllers[i].text,
          issueDate: _passportIssueDateControllers[i].text,
          expiryDate: _passportExpiryDateControllers[i].text,
          issuingAuthority: _issuingAuthorityControllers[i].text,
          passengerIndex: i,
        );
      } catch (e) {
        debugPrint('Warning: Failed to save passport details for passenger ${i + 1}: $e');
      }
    }

    return applicationUuid;
  } catch (e) {
    throw Exception('Failed to save application to database: $e');
  }
}

// ADD THIS NEW METHOD: Save payment to database
Future<void> _savePaymentToDatabase(String applicationUuid) async {
  try {
    await DatabaseService.createPayment(
      applicationUuid: applicationUuid,
      amount: _calculatedFee.toDouble(),
      paymentMethod: _selectedPaymentMethod!,
      receiptUrl: _paymentReceiptUrl,
      upiTransactionId: _paymentReceiptUrl != null ? 'UPI_${DateTime.now().millisecondsSinceEpoch}' : null,
    );
  } catch (e) {
    debugPrint('Warning: Failed to save payment record: $e');
    // Don't throw error here as payment might be handled separately
  }
}

  Future<void> _submitApplication() async {
  if (!_validateStep1()) {
    setState(() => _currentStep = 0);
    return;
  }
  if (!_validateStep2()) {
    setState(() => _currentStep = 1);
    return;
  }
  if (!_validateStep3()) {
    setState(() => _currentStep = 2);
    return;
  }
  if (!_validateStep4()) {  // NEW: Validate payment step
    setState(() => _currentStep = 3);
    return;
  }

  setState(() => _isSubmitting = true);
  
  await Future.delayed(const Duration(seconds: 1));
  
  if (!mounted) return;
  
  setState(() => _isSubmitting = false);
  
  _showEmailInstructionsDialog();
}
  void _onStepTapped(int step) {
  if (step <= _currentStep) {
    setState(() => _currentStep = step);
    return;
  }

  for (int s = 0; s < step; s++) {
    bool ok;
    if (s == 0) {
      ok = _validateStep1();
    } else if (s == 1) {
      ok = _validateStep2();
    } else if (s == 2) {
      ok = _validateStep3();
    } else if (s == 3) {
      ok = _validateStep4();  // NEW: Validate payment step
    } else {
      ok = true; // Step 5 (Review) doesn't need validation
    }
    
    if (!ok) {
      setState(() => _currentStep = s);
      return;
    }
  }
  setState(() => _currentStep = step);
}

// Add this method to get visa-specific document requirements
String _getVisaDocumentRequirements() {
  switch (_selectedVisaType.name) {
    case 'Business Visa':
      return 'Required documents for Business Visa:\n'
          '• Business invitation letter\n• Company registration documents\n'
          '• Business itinerary\n• Proof of business relationship\n'
          '• Financial documents showing business capacity';
    
    case 'Student Visa':
      return 'Required documents for Student Visa:\n'
          '• Admission letter from educational institution\n'
          '• Proof of financial support\n• Academic transcripts\n'
          '• Student ID card (if available)\n• Course details and duration';
    
    case 'Work Visa':
      return 'Required documents for Work Visa:\n'
          '• Employment contract\n• Company offer letter\n'
          '• Educational qualifications\n• Work experience certificates\n'
          '• Professional licenses (if applicable)';
    
    case 'Medical Visa':
      return 'Required documents for Medical Visa:\n'
          '• Medical diagnosis report\n• Doctor\'s recommendation letter\n'
          '• Hospital admission confirmation\n• Treatment cost estimate\n'
          '• Medical history records';
    
    case 'Tourist Visa':
      return 'Required documents for Tourist Visa:\n'
          '• Hotel bookings\n• Flight itinerary\n• Bank statements\n'
          '• Travel insurance\n• Proof of employment/income';
    
    case 'Transit Visa':
      return 'Required documents for Transit Visa:\n'
          '• Onward flight tickets\n• Visa for final destination (if required)\n'
          '• Proof of sufficient funds for transit period';
    
    case 'Family Visa':
      return 'Required documents for Family Visa:\n'
          '• Marriage certificate (if applicable)\n• Birth certificates\n'
          '• Proof of relationship\n• Family photos\n• Invitation letter from family member';
    
    default:
      return 'Please upload all relevant supporting documents for your visa application '
          'as required by immigration authorities.';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visa Application',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _resetForm,
      tooltip: 'Reset Form',
    ),
  ],
      ),
      body: SingleChildScrollView(
        
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visa Application',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete this multi-step form to apply for your visa. Our team will process your application within 3-5 business days.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Theme(
                      data: ThemeData(
                        colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
                      ),
                      child: Stepper(
                        currentStep: _currentStep,
                        onStepContinue: () {
  bool isCurrentStepValid = true;
  
  // Validate ONLY the current step before proceeding
  switch (_currentStep) {
    case 0:
      isCurrentStepValid = _validateStep1();
      break;
    case 1:
      isCurrentStepValid = _validateStep2();
      break;
    case 2:
      isCurrentStepValid = _validateStep3();
      break;
    case 3:
      isCurrentStepValid = _validateStep4();
      break;
    case 4: // Review step - no validation needed
      isCurrentStepValid = true;
      break;
  }
  
  if (!isCurrentStepValid) {
    // Show error message and stay on current step
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please fix errors in step ${_currentStep + 1} before continuing'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  // Only proceed to next step if validation passes
  if (_currentStep < _buildSteps().length - 1) {
    setState(() => _currentStep++);
  } else {
    _submitApplication();
  }
},
                        onStepCancel: () {
                          if (_currentStep > 0) setState(() => _currentStep--);
                        },
                        onStepTapped: _onStepTapped,
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Row(children: [
                              if (_currentStep > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: details.onStepCancel,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: Color(0xFF1E88E5)),
                                    ),
                                    child: const Text(
                                      'BACK',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_currentStep > 0) const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: details.onStepContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(
                                          _currentStep == _buildSteps().length - 1 ? 'SUBMIT' : 'CONTINUE',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ]),
                          );
                        },
                        steps: _buildSteps(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Card(
              elevation: 1,
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Application Processing',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Standard processing time: 3-5 business days. Urgent processing available upon request.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
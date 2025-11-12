// lib/screens/profile_screen.dart - FIXED VERSION
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _userServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // FIXED: Proper type handling for Future.wait
  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Load all data in parallel with proper type handling
        final List<Future<dynamic>> futures = [
          // Profile data
          _supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single(),
          // Applications data with error handling
          _supabase
              .from('applications')
              .select()
              .eq('email', user.email ?? 'no-email')
              .order('created_at', ascending: false)
              .then((data) => data, onError: (e) {
                developer.log('Error loading applications: $e', name: 'ProfileScreen');
                return [];
              }),
          // Services data with error handling
          _supabase
              .from('user_services')
              .select()
              .eq('user_id', user.id)
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .then((data) => data, onError: (e) {
                developer.log('Services table not available: $e', name: 'ProfileScreen');
                return [];
              }),
        ];

        final results = await Future.wait(futures);

        if (mounted) {
          setState(() {
            _userProfile = results[0] as Map<String, dynamic>?;
            _applications = List<Map<String, dynamic>>.from(results[1] as List);
            _userServices = List<Map<String, dynamic>>.from(results[2] as List);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      developer.log('Error loading profile data: $e', name: 'ProfileScreen');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// FIXED: Better async context handling with proper mounted checks
Future<void> _updateProfilePhoto() async {
  if (!mounted) return;

  try {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Source'),
        content: const Text('Select photo source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;

    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null && mounted) {
      // Show loading snackbar
      _showSnackBar('Uploading photo...', isProgress: true);
      
      final user = _supabase.auth.currentUser!;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await image.readAsBytes();
      
      try {
        await _supabase.storage
            .from('avatars')
            .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: true));
        
        final avatarUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);
        
        await _supabase
            .from('profiles')
            .update({
              'avatar_url': avatarUrl,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
        
        if (mounted) {
          _hideCurrentSnackBar();
          await _loadUserData();
          _showSnackBar('Profile photo updated successfully!', isSuccess: true);
        }
      } catch (uploadError) {
        if (mounted) {
          _hideCurrentSnackBar();
          _showSnackBar('Failed to upload photo. Please try again.', isError: true);
        }
      }
    }
  } catch (e) {
    developer.log('Error updating photo: $e', name: 'ProfileScreen');
    if (mounted) {
      _hideCurrentSnackBar();
      _showSnackBar('Failed to update photo. Please try again.', isError: true);
    }
  }
}

// Helper methods to safely show/hide snackbars
void _showSnackBar(String message, {bool isProgress = false, bool isSuccess = false, bool isError = false}) {
  if (!mounted) return;
  
  Color backgroundColor = Colors.grey;
  if (isSuccess) backgroundColor = Colors.green;
  if (isError) backgroundColor = Colors.red;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: isProgress
          ? Row(
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(width: 12),
                Text(message),
              ],
            )
          : Text(message),
      backgroundColor: backgroundColor,
      duration: isProgress ? const Duration(seconds: 30) : const Duration(seconds: 3),
    ),
  );
}

void _hideCurrentSnackBar() {
  if (!mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}
  // Profile Header with white background
  Widget _buildProfileHeader() {
    final String? avatarUrl = _userProfile?['avatar_url'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Larger profile picture (120px)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E88E5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl) as ImageProvider
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                      : null,
                ),
              ),
              // Camera button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  onPressed: _updateProfilePhoto,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Text(
            _userProfile?['full_name'] ?? 'User Name',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?['email'] ?? 'email@example.com',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Personal Info Card
  Widget _buildPersonalInfoCard() {
    final bool hasAdditionalInfo = _userProfile?['date_of_birth'] != null ||
        _userProfile?['nationality'] != null ||
        _userProfile?['address'] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 24, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Personal Information',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _editPersonalInfo,
                    child: Text(
                      'EDIT',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (!hasAdditionalInfo)
                _buildEmptyState(
                  Icons.info_outline,
                  'Complete your profile',
                  'Add your personal information for better service',
                )
              else
                Column(
                  children: [
                    if (_userProfile?['phone'] != null)
                      _buildInfoRow('Phone', _userProfile!['phone']),
                    if (_userProfile?['date_of_birth'] != null)
                      _buildInfoRow('Birthday', _formatDate(_userProfile!['date_of_birth'])),
                    if (_userProfile?['nationality'] != null)
                      _buildInfoRow('Nationality', _userProfile!['nationality']),
                    if (_userProfile?['city'] != null && _userProfile?['country'] != null)
                      _buildInfoRow('Location', '${_userProfile!['city']}, ${_userProfile!['country']}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Services Section
  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.widgets_outlined, size: 24, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Text(
                    'My Services',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_userServices.isEmpty)
                _buildEmptyState(
                  Icons.widgets_outlined,
                  'No Active Services',
                  'Explore our services to get started with your immigration journey',
                  actionButton: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Explore Services',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _userServices.map((service) => _buildServiceItem(service)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.work_outline, color: Color(0xFF1E88E5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['service_type'] ?? 'Immigration Service',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active • Started ${_formatDate(service['created_at'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Active',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Applications Section
  Widget _buildApplicationsSection() {
    if (_applications.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 24, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recent Applications',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_applications.length}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._applications.take(3).map((application) => _buildApplicationItem(application)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationItem(Map<String, dynamic> application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.airplane_ticket, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${application['destination_country'] ?? 'Unknown'} - ${application['visa_type'] ?? 'Visa'}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Applied: ${_formatDate(application['created_at'])}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(application['status'] ?? 'pending').withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (application['status'] ?? 'pending').toString().toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(application['status'] ?? 'pending'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState(IconData icon, String title, String subtitle, {Widget? actionButton}) {
    return Column(
      children: [
        Icon(icon, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionButton != null) ...[
          const SizedBox(height: 16),
          actionButton,
        ],
      ],
    );
  }

  // Menu Section
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildMenuButton(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Add or manage payment options',
                onTap: _showPaymentMethods,
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with your applications',
                onTap: _showHelpSupport,
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your account security',
                onTap: _showPrivacySecurity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1E88E5), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _editPersonalInfo() {
    showDialog(
      context: context,
      builder: (context) => EditPersonalInfoDialog(
        profile: _userProfile,
        onSave: _loadUserData,
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact our support team for assistance:'),
            const SizedBox(height: 16),
            _buildContactInfo(
              'Email',
              'jrrindia@gmail.com',
              Icons.email,
            ),
            const SizedBox(height: 12),
            _buildContactInfo(
              'Email (Secondary)',
              'jrrgoindia@gmail.com',
              Icons.email,
            ),
            const SizedBox(height: 12),
            _buildContactInfo(
              'Phone',
              '+91 7893638689',
              Icons.phone,
            ),
            const SizedBox(height: 12),
            _buildContactInfo(
              'Address',
              'Plot 70, Kalyannagar Colony, Gaddiannaram, Hyderabad-500060, Telangana, India',
              Icons.location_on,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPrivacySecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const SingleChildScrollView(
          child: Text(
            'Your data is protected under the Digital Personal Data Protection Act, 2023 (India). '
            'We use industry-standard security measures to protect your personal information. '
            'For detailed information, please refer to our Privacy Policy in the app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Text(
          'Manage your payment options and view payment history. '
          'Currently we support UPI payments and Pay Later options.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E88E5)),
              const SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            _buildPersonalInfoCard(),
            _buildServicesSection(),
            _buildApplicationsSection(),
            _buildMenuSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// EditPersonalInfoDialog remains the same
class EditPersonalInfoDialog extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onSave;

  const EditPersonalInfoDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EditPersonalInfoDialog> createState() => _EditPersonalInfoDialogState();
}

class _EditPersonalInfoDialogState extends State<EditPersonalInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _fullNameController.text = widget.profile?['full_name'] ?? '';
    _phoneController.text = widget.profile?['phone'] ?? '';
    _dateOfBirthController.text = widget.profile?['date_of_birth'] ?? '';
    _nationalityController.text = widget.profile?['nationality'] ?? '';
    _addressController.text = widget.profile?['address'] ?? '';
    _cityController.text = widget.profile?['city'] ?? '';
    _countryController.text = widget.profile?['country'] ?? '';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  bool _isValidDate(String date) {
    if (date.isEmpty) return true;
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{10,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final updateData = {
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'nationality': _nationalityController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (_dateOfBirthController.text.trim().isNotEmpty && 
            _isValidDate(_dateOfBirthController.text.trim())) {
          updateData['date_of_birth'] = _dateOfBirthController.text.trim();
        }

        await _supabase
            .from('profiles')
            .update(updateData)
            .eq('id', user.id);

        if (mounted) {
          Navigator.pop(context);
          widget.onSave();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Save error: $e', name: 'ProfileScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Personal Information',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        hintText: '+1 (555) 123-4567',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateOfBirthController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && !_isValidDate(value)) {
                          return 'Please enter a valid date (YYYY-MM-DD)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nationalityController,
                      decoration: const InputDecoration(
                        labelText: 'Nationality',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
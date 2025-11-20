// lib/screens/profile_screen.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'track_status_screen.dart';
import 'payment_screen.dart';

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
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted && !forceRefresh) {
        setState(() => _isLoading = true);
      } else if (mounted && forceRefresh) {
        setState(() => _isRefreshing = true);
      }

      // Load profile data
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 10));

      // Load applications
      final applicationsData = await _supabase
          .from('applications')
          .select()
          .eq('email', user.email ?? 'no-email')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10))
          .catchError((e) {
            developer.log('Error loading applications: $e', name: 'ProfileScreen');
            return <Map<String, dynamic>>[];
          });

      if (mounted) {
        setState(() {
          _userProfile = profileData;
          _applications = List<Map<String, dynamic>>.from(applicationsData);
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      developer.log('Error loading profile data: $e', name: 'ProfileScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

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
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      
      if (image != null && mounted) {
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
            await _loadUserData(forceRefresh: true);
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
                  Expanded(child: Text(message)),
                ],
              )
            : Text(message),
        backgroundColor: backgroundColor,
        duration: isProgress ? const Duration(seconds: 15) : const Duration(seconds: 3),
      ),
    );
  }

  void _hideCurrentSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

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

  // NEW: Track Status section instead of My Services
  Widget _buildTrackStatusSection() {
    if (_applications.isEmpty && _isLoading) return const SizedBox.shrink();
    
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
                  const Icon(Icons.track_changes_outlined, size: 24, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 12),
                  Text(
                    'Track Application Status',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_applications.isEmpty)
                _buildEmptyState(
                  Icons.assignment_outlined,
                  'Track Application Status',
                  'Check your application status using your Application ID and Email',
                  actionButton: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                       context,
                       MaterialPageRoute(
                          builder: (context) => const TrackStatusScreen(),
                       ),
                      );
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
                      'Track Your Application',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _applications.map((application) => _buildApplicationItem(application)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationItem(Map<String, dynamic> application) {
    return GestureDetector(
      onTap: () {
        // You can add navigation to detailed application view here
        _showApplicationDetails(application);
      },
      child: Container(
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
      ),
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Destination', application['destination_country'] ?? 'N/A'),
              _buildDetailRow('Visa Type', application['visa_type'] ?? 'N/A'),
              _buildDetailRow('Status', application['status'] ?? 'pending'),
              _buildDetailRow('Applied Date', _formatDate(application['created_at'])),
              if (application['reference_number'] != null)
                _buildDetailRow('Reference', application['reference_number']),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

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
        onSave: () => _loadUserData(forceRefresh: true),
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
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PaymentScreen(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadUserData(forceRefresh: true),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const _ProfileLoadingWidget()
          : RefreshIndicator(
              onRefresh: () => _loadUserData(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    _buildPersonalInfoCard(),
                    _buildTrackStatusSection(), // Replaced Services with Track Status
                    _buildMenuSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProfileLoadingWidget extends StatelessWidget {
  const _ProfileLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

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

        if (_dateOfBirthController.text.trim().isNotEmpty) {
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
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateOfBirthController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDate,
                        ),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
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
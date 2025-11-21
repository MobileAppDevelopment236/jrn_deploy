import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AccommodationScreen extends StatelessWidget {
  const AccommodationScreen({super.key});

  final String googleTravelUrl = 'https://www.google.com/travel/hotels';

  Future<void> _launchGoogleTravel(BuildContext context) async {
    try {
      final Uri url = Uri.parse(googleTravelUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch Google Travel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find Accommodation',
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
        padding: EdgeInsets.all(isLandscape ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Header Section
            _buildHeaderSection(isLandscape),
            SizedBox(height: isLandscape ? 16 : 24),
            
            // Clear Disclaimer
            _buildDisclaimerSection(isLandscape),
            SizedBox(height: isLandscape ? 16 : 24),
            
            // Action Button with info
            _buildActionSection(context, isLandscape),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isLandscape) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 16 : 20),
        child: Column(
          children: [
            Icon(
              Icons.hotel,
              size: isLandscape ? 48 : 64,
              color: const Color(0xFF1E88E5).withAlpha(178),
            ),
            SizedBox(height: isLandscape ? 12 : 16),
            Text(
              'Accommodation Search',
              style: GoogleFonts.inter(
                fontSize: isLandscape ? 18 : 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E88E5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            Text(
              'Search for hotels, resorts, and apartments through Google Travel with best prices and wide selection.',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: isLandscape ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLandscape ? 12 : 16),
            _buildFeatureRow('Real-time price comparison', isLandscape),
            _buildFeatureRow('Hotels, resorts & apartments', isLandscape),
            _buildFeatureRow('Free cancellation options', isLandscape),
            _buildFeatureRow('Customer reviews & ratings', isLandscape),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerSection(bool isLandscape) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Important Notice',
                    style: GoogleFonts.inter(
                      fontSize: isLandscape ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            Text(
              'This is a free external link service for your convenience:',
              style: GoogleFonts.inter(
                color: Colors.grey[700],
                fontSize: isLandscape ? 13 : 14,
              ),
            ),
            SizedBox(height: isLandscape ? 8 : 12),
            _buildDisclaimerItem('We simply provide a link to Google Travel', isLandscape),
            _buildDisclaimerItem('No search or booking happens within this app', isLandscape),
            _buildDisclaimerItem('We are not affiliated with Google Travel', isLandscape),
            _buildDisclaimerItem('We are not responsible for Google Travel\'s services', isLandscape),
            _buildDisclaimerItem('All transactions are between you and Google Travel', isLandscape),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, bool isLandscape) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isLandscape ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              SizedBox(width: isLandscape ? 8 : 12),
              Expanded(
                child: Text(
                  'You will be redirected to Google Travel website to search and book accommodations',
                  style: GoogleFonts.inter(
                    fontSize: isLandscape ? 12 : 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isLandscape ? 12 : 16),
        _buildActionButton(context, isLandscape),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, bool isLandscape) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _launchGoogleTravel(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isLandscape ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, size: 20),
            SizedBox(width: isLandscape ? 8 : 12),
            Flexible(
              child: Text(
                'Search Accommodations on Google Travel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: isLandscape ? 14 : 16,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                fontSize: isLandscape ? 12 : 13,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerItem(String text, bool isLandscape) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.grey[700],
                fontSize: isLandscape ? 12 : 13,
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
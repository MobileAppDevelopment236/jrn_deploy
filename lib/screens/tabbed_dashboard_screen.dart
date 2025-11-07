import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jrr_immigration_app/screens/visa_screen.dart';
import 'package:jrr_immigration_app/screens/auth/login_screen.dart';
import 'package:jrr_immigration_app/services/auth_service.dart';
import 'package:jrr_immigration_app/screens/forex_screen.dart';
import 'package:jrr_immigration_app/screens/insurance_screen.dart';
import 'package:jrr_immigration_app/screens/track_status_screen.dart' as track_screen;
import 'package:jrr_immigration_app/screens/visa_refusal_screen.dart';
import 'package:jrr_immigration_app/screens/ai_assistant_popup.dart';
import 'package:jrr_immigration_app/screens/immigration_advice_screen.dart';
import 'package:jrr_immigration_app/screens/flights_screen.dart';
import 'package:jrr_immigration_app/screens/accommodation_screen.dart';
import 'package:jrr_immigration_app/screens/profile_screen.dart';



class TabbedDashboardScreen extends StatefulWidget {
  const TabbedDashboardScreen({super.key});

  @override
  State<TabbedDashboardScreen> createState() => _TabbedDashboardScreenState();
}

class _TabbedDashboardScreenState extends State<TabbedDashboardScreen> {
  // Original Dashboard Colors (from your old dashboard)
  final Color _primaryBlue = const Color(0xFF1E88E5); // Exact blue from old dashboard
  final Color _backgroundColor = const Color(0xFFF8F9FA); // Light grey background
  final Color _cardColor = Colors.white;  
  final Color _textSecondary = const Color(0xFF666666); // Grey text

    // Privacy Policy & Terms Content
    final String _privacyPolicyContent = '''
Privacy Policy

Effective Date: XX-Nov-2025
JRR App --- JRR Integrated Solutions

JRR Integrated Solutions ("Company", "We", "Us", "Our") operates the JRR App and related services including visa & immigration support, visa refusal services, and add-on services such as air ticket and accommodation booking.

We are committed to protecting your personal data and complying with the Digital Personal Data Protection Act, 2023 (India) and applicable data protection principles.

By using our app or services, you agree to the practices described in this Privacy Policy.

1. Data Controller Information

JRR Integrated Solutions
Off. Plot 70, Kalyannagar Colony,
Gaddiannaram, Hyderabad-500060, Telangana, India
📧 Email: jrrindia@gmail.com
📞 Phone: +91 7893638689

2. Personal Data We Collect

We may collect the following categories of personal data:

✅ Identity & Contact Data
- Full name, gender, date of birth
- Email address, phone number, address

✅ Immigration & Travel Data
- Passport details
- Visa history, visa refusal documents
- Travel dates, itinerary and booking preferences

✅ Account & Usage Data
- Login credentials
- Device information, IP address
- Location services (optional, with consent)

✅ Payment & Transaction Data
- Payment method details (processed through secure gateway)
- Transaction records for add-on services

We do not knowingly collect children's data without parental consent.

3. Purpose of Data Use

We process your information for:
- Visa consultation, filing, and follow-up services
- Visa refusal handling and legal assistance
- Offering flight and hotel booking add-on services
- Communicating immigration status and service updates
- Customer support and account management
- Safety, security, fraud prevention
- Legal and compliance purposes
- Improving app performance and user experience

4. Consent & Legal Basis

We obtain user consent before collecting and processing data.
You may withdraw consent anytime by contacting us — however, services may be partially or fully disabled after withdrawal.

5. Data Sharing and Third-Party Access

We may share necessary information:
- With trusted travel booking partners for flight/hotel fulfilment
- With payment gateway providers
- With government/immigration authorities when required by law

We do not sell or rent personal data to any third party.

✅ As confirmed by the Company, data is not stored outside India
✅ Third-party service providers are required to protect your data

6. Data Retention

We retain data only as long as required:

|--------------------------------------------------------------------------------|
 Data Type	                        Retention Duration                           
|--------------------------------------------------------------------------------|
 Visa case files                Until service completion + legal compliance period
 Travel booking records	   Until booking fulfilment + audit requirement
 Account data	                 Until account deletion request
 Payment data	                 As per financial laws
|--------------------------------------------------------------------------------|

After expiration — data is deleted or anonymized securely.

7. Data Security

We use industry-standard safeguards including:
✅ Encryption of sensitive data
✅ Access control and authentication
✅ Regular security audits
✅ App firewall and monitoring systems

However, no digital system is 100% secure — users are encouraged to maintain strong login protection.

8. User Rights

Users may exercise the following rights:
- Access: Request copy of your personal data
- Correction: Fix inaccurate or incomplete information
- Erase: Request deletion when no longer required
- Consent withdrawal: Stop data processing
- Grievance: Lodge complaints with our officer or relevant authority

Requests should be sent to: jrrindia@gmail.com

9. Cookies & Tracking Technologies

Our app may use tracking technologies for:
- App analytics
- Improving service experience
- Remembering user preferences

You may disable tracking via device settings, but some app features may be limited.

10. Third-Party Links

Our app may contain external links for travel bookings.
We are not responsible for privacy practices of external partners.
Users should review their policies before proceeding.

11. Policy Updates

We may update this policy occasionally.
Latest version will always be posted in the app and/or on our website along with the effective date.

12. Governing Law

This Privacy Policy is governed by the laws of India.
Disputes shall be resolved by courts in Hyderabad, Telangana.

📌 By using our app, you acknowledge you have read, understood, and agreed to this Privacy Policy.
''';

final String _termsAndConditionsContent = '''
Terms & Conditions --- JRR App

Effective Date: XX-Nov-2025
JRR Integrated Solutions

These Terms & Conditions ("Terms") govern your use of the JRR App and services provided by JRR Integrated Solutions ("Company", "We", "Us", "Our").
By downloading or using the app, you agree to be bound by these Terms.

If you do not agree, please discontinue use of the app.

1. Services Covered

The JRR App provides:
1. Visa consultation & documentation assistance
2. Visa refusal review & advisory services
3. Add-on travel services including:
  • Flight search and booking support
  • Accommodation search and booking support
  • Travel Insurance

We are NOT responsible for visa grant decisions — approval is solely at the discretion of the respective embassy/consulate.

2. User Responsibilities

Users must:
✅ Provide accurate and truthful information
✅ Ensure passport & documents are valid
✅ Comply with immigration rules & conditions
✅ Pay all required service charges and government fees

Any incorrect submission due to false or incomplete information is the user's responsibility.

3. Account Registration

To use certain features, users may create an account.
You are responsible for maintaining:
- confidentiality of login credentials
- activity under your account

We may suspend or terminate accounts involved in suspicious or illegal activity.

4. Third-Party Travel Services

Flight, travel insurance and accommodation services may be fulfilled by authorized third-party partners.

✔ We facilitate access to booking options
❌ We do NOT operate airlines, hotels, or booking portals

Once redirected to a partner platform:
- Booking terms of the partner apply
- We are not liable for changes, delays, cancellations, price changes, refunds, or service disruptions caused by partners

5. Fees & Payments

- Service charges are communicated before taking any action
- Government visa fees, GST, VFS charges, travel fees are borne by the user
- In-app payments are processed by licensed gateways

Some fees may be non-refundable due to third-party policies.

A detailed Refund & Cancellation policy will be available separately.

6. No Guarantee or Legal Liability

We assist in documentation and advisory only.

We are NOT liable for:
- Visa rejections/refusals
- Delays or additional document requests from embassies
- Losses due to travel cancellations or changes
- Any immigration authority decision or travel restriction

Decisions are made solely by government authorities.

7. User Restrictions

Users must NOT:
❌ Upload harmful files, fake documents, or malicious data
❌ Misuse or hack the app
❌ Violate any visa, immigration, or travel laws

We may take appropriate action (including legal action) against misuse.

8. Intellectual Property

All app content, designs, logos, trademarks, and technology belong to:
JRR Integrated Solutions

Users are only granted limited permission to use the app—not to copy, modify, resell, or reverse-engineer any part of it.

9. Data Protection

Our data handling complies with India's Digital Personal Data Protection Act, 2023.
Please review our Privacy Policy for complete details.

10. Service Modifications

We may enhance, update, suspend, or discontinue features without prior notice — especially those offered by third-party partners.

11. Limitation of Liability

To the maximum extent allowed by law:
- Our total liability is limited to the amount of service fees paid to us
- We are not liable for indirect or consequential losses

12. Termination

We may suspend or terminate access if a user:
- Violates Terms
- Misuses the app
- Provides fraudulent information

Users may delete their account anytime.

13. Governing Law & Jurisdiction

These Terms are governed by the laws of India.
Any dispute shall be subject to the exclusive jurisdiction of the courts in Hyderabad, Telangana.

14. Contact Information

For concerns or complaints:

JRR Integrated Solutions
Off. Plot 70, Kalyannagar Colony,
Gaddiannaram, Hyderabad — 500060, India
Email: jrrindia@gmail.com
Phone: +91 7893638689
''';
  





  // Navigation methods
  void _navigateToVisa(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const VisaScreen()));
  }

  void _navigateToInsurance(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const InsuranceScreen()));
  }

  void _navigateToImmigrationAdvice(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ImmigrationAdviceScreen()));
  }

  void _navigateToFlights(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightsScreen()));
  }

  void _navigateToAccommodation(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AccommodationScreen()));
  }

  void _showPrivacyPolicy(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Privacy Policy'),
      content: SingleChildScrollView(
        child: Text(_privacyPolicyContent),
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

void _showTermsAndConditions(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Terms & Conditions'),
      content: SingleChildScrollView(
        child: Text(_termsAndConditionsContent),
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
  

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            //height: 120,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: _primaryBlue),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _primaryBlue,
        ),
      ),
    );
  }

  Widget _buildFooterButton(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _primaryBlue, size: 20),
              const SizedBox(height: 4),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: _primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: _backgroundColor,
    floatingActionButton: FloatingActionButton(
      onPressed: () => AIAssistantPopup.show(context),
      backgroundColor: _primaryBlue,
      foregroundColor: Colors.white,
      elevation: 2,
      child: const Icon(Icons.support_agent, size: 20),
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          // HEADER - Clean like old dashboard
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Header Row - Exactly like old dashboard
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo - Using your JRR logo
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: Image.asset(
                        'assets/images/JRR Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // Welcome Message - Centered
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Welcome to JRR Go!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: _primaryBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We work beyond borders',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "India's Only Legally Backed Immigration & Travel App",
                            style: GoogleFonts.inter(
                            color: _textSecondary,
                            fontSize: 12,
                           ),
                         ),
                        ],
                      ),
                    ),
                    
                    // Logout Button 
                    Container(
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                        label: Text(
                          'Logout',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Blue bottom line - Exactly like old dashboard
                Container(
                  height: 2,
                  color: _primaryBlue,
                  margin: const EdgeInsets.only(top: 16),
                ),
              ],
            ),
          ),

          // MAIN CONTENT - Clean layout like old dashboard
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VISA SERVICES SECTION
                _buildSectionTitle('Visa Services'),
                
                // Single Row - Only 3 visa services (removed Upload Documents, Application History, Visa Requirements)
                Row(
                  children: [
                    _buildServiceItem(
                      icon: Icons.assignment,
                      title: 'Apply Visa',
                      subtitle: 'New application',
                      onTap: () => _navigateToVisa(context),
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.track_changes,
                      title: 'Track Status',
                      subtitle: 'Check application',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const track_screen.TrackStatusScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.warning,
                      title: 'Visa Refusal',
                      subtitle: 'Get assistance',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VisaRefusalScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // TRAVEL SERVICES SECTION
                _buildSectionTitle('Travel Services'),
                
                // Single Row - Only 3 main travel services
                Row(
                  children: [
                    _buildServiceItem(
                      icon: Icons.flight,
                      title: 'Flight Booking',
                      subtitle: 'Book best fares',
                      onTap: () => _navigateToFlights(context),
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.hotel,
                      title: 'Accommodation',
                      subtitle: 'Hotels & apartments',
                      onTap: () => _navigateToAccommodation(context),
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.security,
                      title: 'Travel Insurance',
                      subtitle: 'Get protected',
                      onTap: () => _navigateToInsurance(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // FINANCIAL SERVICES SECTION
                _buildSectionTitle('Financial Services'),
                
                // Single Row - Only Forex Services
                Row(
                  children: [
                    _buildServiceItem(
                      icon: Icons.currency_exchange,
                      title: 'Forex Services',
                      subtitle: 'Currency exchange',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForexScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 24),

                // SUPPORT SERVICES SECTION
                _buildSectionTitle('Support Services'),
                
                // Single Row - Only 2 main support services
                Row(
                  children: [
                    _buildServiceItem(
                      icon: Icons.lightbulb_outline,
                      title: 'Immigration Advice',
                      subtitle: 'Expert consultation',
                      onTap: () => _navigateToImmigrationAdvice(context),
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.support_agent,
                      title: 'AI Assistant',
                      subtitle: 'Instant help',
                      onTap: () => AIAssistantPopup.show(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 24),

                // LEGAL & SUPPORT SECTION - NOW PROPERLY ALIGNED
                _buildSectionTitle('Legal & Support'),
                
                // Single Row - Privacy Policy and Terms & Conditions
                Row(
                  children: [
                    _buildServiceItem(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      subtitle: 'Data protection info',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    const SizedBox(width: 12),
                    _buildServiceItem(
                      icon: Icons.description,
                      title: 'Terms & Conditions',
                      subtitle: 'App usage terms',
                      onTap: () => _showTermsAndConditions(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    ),

    // FOOTER - Simple like old dashboard
    bottomNavigationBar: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFooterButton('Home', Icons.home, () {}),
          _buildFooterButton('Visa', Icons.assignment, () => _navigateToVisa(context)),
          _buildFooterButton('Flights', Icons.flight, () => _navigateToFlights(context)),
          _buildFooterButton('Insurance', Icons.security, () => _navigateToInsurance(context)),
          _buildFooterButton('Profile', Icons.person, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
  
}
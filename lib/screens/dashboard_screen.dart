import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jrr_immigration_app/screens/visa_screen.dart';
import 'package:jrr_immigration_app/screens/coming_soon_screen.dart';
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _navigateToVisa(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const VisaScreen()));
  }

  void _navigateToInsurance(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const InsuranceScreen()));
  }

  void _navigateToImmigrationAdvice(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ImmigrationAdviceScreen()));
  }

  // ADD THESE TWO NEW NAVIGATION METHODS
  void _navigateToFlights(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const FlightsScreen()));
  }

  void _navigateToAccommodation(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AccommodationScreen()));
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
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: () => AIAssistantPopup.show(context),
        backgroundColor: const Color(0xFF1E88E5),
        mini: true,
        elevation: 4,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // CUSTOM HEADER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Header row with logo, welcome message, and logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: Image.asset(
                        'assets/images/JRR Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    
                    // Welcome message - centered between logo and logout
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome to JRR Go!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1E88E5),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your complete immigration solution',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
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
                
                // Blue bottom line for the header
                Container(
                  height: 2,
                  color: const Color(0xFF1E88E5),
                  margin: const EdgeInsets.only(top: 16),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Quick Actions Title
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Actions - Buttons with consistent blue color
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActionButton(
                        icon: Icons.assignment,
                        label: 'Apply Visa',
                        color: const Color(0xFF1E88E5),
                        onTap: () => _navigateToVisa(context),
                      ),
                      _buildActionButton(
                        icon: Icons.track_changes,
                        label: 'Track Status',
                        color: const Color(0xFF1E88E5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const track_screen.TrackStatusScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.warning,
                        label: 'Visa Refusal',
                        color: const Color(0xFF1E88E5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VisaRefusalScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.security,
                        label: 'Travel Insurance',
                        color: const Color(0xFF1E88E5),
                        onTap: () => _navigateToInsurance(context),
                      ),
                      _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: 'Immigration Advice',
                        color: const Color(0xFF1E88E5),
                        onTap: () => _navigateToImmigrationAdvice(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Services Title
                  Text(
                    'Our Services',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Services - Cards with 3 in a row
                  Column(
                    children: [
                      // First Row of Services (3 services)
                      Row(
                        children: [
                          Expanded(child: _buildServiceCard(
                            icon: Icons.assignment,
                            title: 'Visa Services',
                            description: 'Apply and track visa applications',
                            color: const Color(0xFF1E88E5),
                            onTap: () => _navigateToVisa(context),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildServiceCard(
                            icon: Icons.flight,
                            title: 'Flight Booking',
                            description: 'Book flights at best prices',
                            color: const Color(0xFF1E88E5),
                            onTap: () => _navigateToFlights(context), // UPDATED
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildServiceCard(
                            icon: Icons.lightbulb_outline,
                            title: 'Immigration Advice',
                            description: 'Professional immigration consultation',
                            color: const Color(0xFF1E88E5),
                            onTap: () => _navigateToImmigrationAdvice(context),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Second Row of Services (3 services)
                      Row(
                        children: [
                          Expanded(child: _buildServiceCard(
                            icon: Icons.hotel,
                            title: 'Accommodation',
                            description: 'Find hotels and apartments',
                            color: const Color(0xFF1E88E5),
                            onTap: () => _navigateToAccommodation(context), // UPDATED
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildServiceCard(
                            icon: Icons.currency_exchange,
                            title: 'Forex Services',
                            description: 'Currency exchange and cards',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForexScreen(),
                                ),
                              );
                            },
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _buildServiceCard(
                            icon: Icons.warning,
                            title: 'Visa Refusal',
                            description: 'Assistance with visa refusal cases',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VisaRefusalScreen(),
                                ),
                              );
                            },
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Third Row of Services (2 services - centered)
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(), // Empty space for centering
                          ),
                          Expanded(
                            flex: 2,
                            child: _buildServiceCard(
                              icon: Icons.security,
                              title: 'Travel Insurance',
                              description: 'Comprehensive travel insurance plans',
                              color: const Color(0xFF1E88E5),
                              onTap: () => _navigateToInsurance(context),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(), // Empty space for centering
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer Navigation Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFooterButton('Home', Icons.home, const Color(0xFF1E88E5), () {}),
                _buildFooterButton('Visa', Icons.assignment, const Color(0xFF1E88E5), () => _navigateToVisa(context)),
                _buildFooterButton('Flights', Icons.flight, const Color(0xFF1E88E5), () => _navigateToFlights(context)), // UPDATED
                _buildFooterButton('Insurance', Icons.security, const Color(0xFF1E88E5), () => _navigateToInsurance(context)),
                _buildFooterButton('Profile', Icons.person, const Color(0xFF1E88E5), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComingSoonScreen(serviceName: 'Profile'),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Footer Button Widget
  Widget _buildFooterButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: color,
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

  // Action Button Widget
  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Service Card Widget
  Widget _buildServiceCard({required IconData icon, required String title, required String description, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get Started →',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
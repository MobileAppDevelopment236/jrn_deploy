import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:jrr_immigration_app/screens/dashboard_screen.dart'; // Add this
import 'package:jrr_immigration_app/screens/tabbed_dashboard_screen.dart';
import 'package:jrr_immigration_app/screens/accommodation_screen.dart';
import 'package:jrr_immigration_app/screens/flights_screen.dart';
import 'package:jrr_immigration_app/screens/forex_screen.dart';
import 'package:jrr_immigration_app/screens/profile_screen.dart';
import 'package:jrr_immigration_app/screens/visa_screen.dart';
import 'package:jrr_immigration_app/screens/insurance_screen.dart';
import 'package:jrr_immigration_app/screens/documents_screen.dart';
import 'package:jrr_immigration_app/screens/immigration_advice_screen.dart'; // NEW IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _widgetOptions = <Widget>[
    const TabbedDashboardScreen(), 
    const VisaScreen(),
    const FlightsScreen(),
    const AccommodationScreen(),
    const ForexScreen(),
    const InsuranceScreen(),
    const DocumentsScreen(),
    const ProfileScreen(),
    const ImmigrationAdviceScreen(), // NEW SERVICE
  ];

  
  final List<String> _appBarTitles = [
  'Dashboard', // Changed from 'Home' to 'Dashboard'
  'Visa Services',
  'Flight Booking',
  'Accommodation',
  'Forex Services',
  'Travel Insurance',
  'My Documents',
  'My Profile',
  'Immigration Advice'
 ];

  // Update the drawer items to include Home and Immigration Advice
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? Colors.blue : Colors.grey[700]),
      title: Text(title,
          style: GoogleFonts.inter(
            color: _selectedIndex == index ? Colors.blue : Colors.grey[700],
            fontWeight: _selectedIndex == index ? FontWeight.w600 : FontWeight.normal,
          )),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex], style: GoogleFonts.inter()),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_outlined), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Text(
                      'JRR',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('JRR GO',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                  Text('We work beyond borders',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      )),
                  Text('India\'s Only Legally Backed Immigration & Travel App', 
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 10, 
                      )),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.home, 'Home', 0), // Added Home item
                  _buildDrawerItem(Icons.assignment, 'Visa Services', 1),
                  _buildDrawerItem(Icons.flight, 'Flight Booking', 2),
                  _buildDrawerItem(Icons.hotel, 'Accommodation', 3),
                  _buildDrawerItem(Icons.currency_exchange, 'Forex Services', 4),
                  _buildDrawerItem(Icons.security, 'Travel Insurance', 5),
                  _buildDrawerItem(Icons.folder, 'My Documents', 6),
                  _buildDrawerItem(Icons.person, 'My Profile', 7),
                  _buildDrawerItem(Icons.lightbulb_outline, 'Immigration Advice', 8), // NEW ITEM
                  const Divider(),
                  _buildDrawerItem(Icons.settings, 'Settings', 7),
                  _buildDrawerItem(Icons.help, 'Help & Support', 7),
                  _buildDrawerItem(Icons.logout, 'Logout', 7),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
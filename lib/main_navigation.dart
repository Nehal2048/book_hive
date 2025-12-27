import 'package:book_hive/pages/dashboard/aitools.dart';
import 'package:book_hive/pages/dashboard/community_screen.dart';
import 'package:book_hive/pages/dashboard/dashboard.dart';
import 'package:book_hive/pages/dashboard/discovery_screen.dart';
import 'package:book_hive/pages/dashboard/library.dart';
import 'package:book_hive/pages/dashboard/marketplace.dart';
import 'package:book_hive/trash/testData.dart';
import 'package:flutter/material.dart';
import 'package:book_hive/services/auth_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    DashboardScreen(),
    LibraryScreen(),
    MarketplaceScreen(),
    AiToolsScreen(),
    CommunityScreen(),
    DiscoveryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  NavigationRailDestination _navDestination(
    IconData icon,
    String label,
    int index,
  ) {
    final bool isActive = _selectedIndex == index;
    return NavigationRailDestination(
      icon: Icon(
        icon,
        color: isActive ? Colors.deepPurple : Colors.deepPurple.shade200,
      ),
      selectedIcon: Icon(icon, color: Colors.deepPurple, size: 32),
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.deepPurple : Colors.deepPurple.shade200,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 900;
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: AppBar(
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Icon(Icons.hive, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Text(
                    'BookHive',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              elevation: 1,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showAccountSheet(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Icon(Icons.person, color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onItemTapped,
                labelType: isWide
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected,
                backgroundColor: Colors.deepPurple.shade50,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      Icon(Icons.hive, color: Colors.deepPurple, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'BookHive',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                destinations: [
                  _navDestination(Icons.home, 'Dashboard', 0),
                  _navDestination(Icons.library_books, 'Library', 1),
                  _navDestination(Icons.store, 'Marketplace', 2),
                  _navDestination(Icons.lightbulb, 'AI Tools', 3),
                  _navDestination(Icons.people, 'Community', 4),
                  _navDestination(Icons.search, 'Discover', 5),
                ],
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showAccountSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _AccountSheet(
      onLogout: () async {
        Navigator.of(ctx).pop();
        try {
          await AuthService().signOut();
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logged out')));
        Navigator.of(context).pushReplacementNamed('/');
      },
    ),
  );
}

class _AccountSheet extends StatelessWidget {
  final VoidCallback onLogout;

  const _AccountSheet({required this.onLogout});

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final user = fakeCurrentUser;

    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade100,
                child: const Icon(Icons.person, color: Colors.deepPurple),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          row(Icons.badge, 'Name', user.name),
          row(Icons.email, 'Email', user.email),
          row(Icons.calendar_today, 'Join Date', _fmtDate(user.joinDate)),
          row(Icons.verified_user, 'User Type', user.userType),
          row(
            Icons.shopping_cart,
            'Buyer Status',
            user.buyerFlag ? 'Active' : 'Inactive',
          ),
          row(
            Icons.storefront,
            'Seller Status',
            user.sellerFlag ? 'Active' : 'Inactive',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

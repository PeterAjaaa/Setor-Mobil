import 'package:flutter/material.dart';
import 'package:setor_mobil/screens/auth/login_screen.dart';
import 'package:setor_mobil/screens/page/order_screen.dart';
import 'dart:async';

import 'package:setor_mobil/screens/page/vehicle_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPromoIndex = 0;
  int _selectedBottomNavIndex = 0;
  String _selectedCategory = 'All';
  final PageController _promoController = PageController();
  Timer? _promoTimer;

  final List<Map<String, dynamic>> _promos = [
    {
      'title': '50% Discount',
      'subtitle': 'Get 50% Discount',
      'colors': [Color(0xFF0066FF), Color(0xFF2563Eb)],
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'Rent 3 days minimal',
      'colors': [Color(0xFFfbbf24), Color(0xFFeA580C)],
    },
    {
      'title': 'Cashback 100k',
      'subtitle': 'First Transaction',
      'colors': [Color(0xFFa855F7), Color(0xFF9333EA)],
    },
  ];

  final List<Map<String, dynamic>> _vehicles = [
    {
      'name': 'Honda Beat',
      'type': 'Motorcycle',
      'price': 'Rp 50.000',
      'rating': 4.8,
    },
    {
      'name': 'Yamaha Aerox',
      'type': 'Motorcycle',
      'price': 'Rp 75.000',
      'rating': 4.9,
    },
    {
      'name': 'Honda Vario',
      'type': 'Motorcycle',
      'price': 'Rp 60.000',
      'rating': 4.7,
    },
    {
      'name': 'Toyota Avanza',
      'type': 'Car',
      'price': 'Rp 300.000',
      'rating': 4.8,
    },
    {'name': 'Honda Brio', 'type': 'Car', 'price': 'Rp 250.000', 'rating': 4.6},
    {
      'name': 'Daihatsu Xenia',
      'type': 'Car',
      'price': 'Rp 200.000',
      'rating': 4.7,
    },
    {
      'name': 'Suzuki Ertiga',
      'type': 'Car',
      'price': 'Rp 320.000',
      'rating': 4.8,
    },
    {
      'name': 'Honda PCX',
      'type': 'Motorcycle',
      'price': 'Rp 85.000',
      'rating': 4.9,
    },
    {
      'name': 'Yamaha NMAX',
      'type': 'Motorcycle',
      'price': 'Rp 90.000',
      'rating': 4.8,
    },
    {
      'name': 'Toyota Innova',
      'type': 'Car',
      'price': 'Rp 400.000',
      'rating': 4.8,
    },
  ];

  @override
  void intitState() {
    super.initState();
    _startPromoAutoScroll();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    _promoTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentPromoIndex < _promos.length - 1) {
        _currentPromoIndex++;
      } else {
        _currentPromoIndex = 0;
      }

      if (_promoController.hasClients) {
        _promoController.animateToPage(
          _currentPromoIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0066FF)),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredVehicles {
    if (_selectedCategory == 'All') return _vehicles;
    return _vehicles.where((v) => v['type'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPromoCarousel(),

                    SizedBox(height: 5),

                    _buildCategories(),
                    SizedBox(height: 24),

                    _buildVehicleList(),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF0066FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Bandung, West Java',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _handleLogout,
                    icon: Icon(Icons.person_outlined, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[400]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search vehicles',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Special Promo!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 12),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.22,
            child: PageView.builder(
              controller: _promoController,
              onPageChanged: (index) {
                setState(() => _currentPromoIndex = index);
              },
              itemCount: _promos.length,
              itemBuilder: (context, index) {
                final promo = _promos[index];
                return Container(
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: promo['colors'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promo['title'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            promo['subtitle'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: promo['colors'][0],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Use Promo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promos.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: index == _currentPromoIndex ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: index == _currentPromoIndex
                      ? Color(0xFF0066FF)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: ['All', 'Motorcycle', 'Car'].map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedCategory = category);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Color(0xFF0066FF)
                        : Colors.grey[100],
                    foregroundColor: isSelected
                        ? Colors.white
                        : Colors.grey[700],
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Vehicles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0066FF),
                  ),
                ),
                label: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF0066FF),
                  size: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: _filteredVehicles.length,
            itemBuilder: (context, index) {
              final vehicle = _filteredVehicles[index];
              return _buildVehicleCard(vehicle);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0066FF).withOpacity(0.1),
                  Color(0xFF1A1A1A).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                vehicle['type'] == 'Motorcycle'
                    ? Icons.motorcycle
                    : Icons.directions_car,
                size: 50,
                color: Color(0xFF0066FF),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  vehicle['type'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vehicle['price'],
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 2),
                        Text(
                          vehicle['rating'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => VehicleDetailScreen(vehicle: vehicle),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Rent Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.calendar_today_outlined, 'Order', 1),
              _buildNavItem(Icons.favorite_outline, 'Favorite', 2),
              _buildNavItem(Icons.menu, 'Menu', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBottomNavIndex = index);

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryScreen(),
            ),
          );
        }

        if (index == 3) {
          _handleLogout();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Color(0xFF0066FF) : Colors.grey[400],
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Color(0xFF0066FF) : Colors.grey[400],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

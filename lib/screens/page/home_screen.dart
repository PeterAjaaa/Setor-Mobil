import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:setor_mobil/screens/page/order_screen.dart';
import 'package:setor_mobil/screens/page/profile_screen.dart';
import 'package:setor_mobil/screens/page/vehicle_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  final _storage = const FlutterSecureStorage();

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

  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
    _fetchVehicles();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  double _calculateAverageRating(List<dynamic>? ratings) {
    if (ratings == null || ratings.isEmpty) return 0.0;

    double sum = 0;
    for (var rating in ratings) {
      sum += (rating['Rating'] ?? 0).toDouble();
    }
    return sum / ratings.length;
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);

    try {
      // Get the JWT token from secure storage
      final token = await _storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      // Fetch cars and motorcycles in parallel with auth header
      final responses = await Future.wait([
        http.get(
          Uri.parse('https://api.intracrania.com/cars'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        http.get(
          Uri.parse('https://api.intracrania.com/motorcycles'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      ]);

      List<Map<String, dynamic>> allVehicles = [];

      // Process cars
      if (responses[0].statusCode == 200) {
        final carsData = jsonDecode(responses[0].body);

        if (carsData['status'] == 200 && carsData['data'] != null) {
          final cars = (carsData['data'] as List)
              .where((car) {
                return car['status'] == 'Available';
              })
              .map((car) {
                return {
                  'id': car['id'],
                  'name': '${car['brand']} ${car['model']}',
                  'brand': car['brand'],
                  'model': car['model'],
                  'type': 'Car',
                  'price': 'Rp ${_formatPrice(car['price_per_day'])}/day',
                  'pricePerDay': car['price_per_day'],
                  'rating': _calculateAverageRating(car['ratings']),
                  'year': car['year'],
                  'description': car['description'],
                  'image_url': car['image_url'],
                  'registration_num': car['registration_num'],
                };
              })
              .toList();
          allVehicles.addAll(cars);
        }
      }

      // Process motorcycles
      if (responses[1].statusCode == 200) {
        final motorcyclesData = jsonDecode(responses[1].body);

        if (motorcyclesData['status'] == 200 &&
            motorcyclesData['data'] != null) {
          final motorcycles = (motorcyclesData['data'] as List)
              .where((moto) {
                return moto['status'] == 'Available';
              })
              .map((moto) {
                return {
                  'id': moto['id'],
                  'name': '${moto['brand']} ${moto['model']}',
                  'brand': moto['brand'],
                  'model': moto['model'],
                  'type': 'Motorcycle',
                  'price': 'Rp ${_formatPrice(moto['price_per_day'])}/day',
                  'pricePerDay': moto['price_per_day'],
                  'rating': _calculateAverageRating(moto['ratings']),
                  'year': moto['year'],
                  'description': moto['description'],
                  'image_url': moto['image_url'],
                  'registration_num': moto['registration_num'],
                };
              })
              .toList();
          allVehicles.addAll(motorcycles);
        }
      }

      setState(() {
        _vehicles = allVehicles;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching vehicles: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0066FF),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVehicles,
                      color: Color(0xFF0066FF),
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
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
              // Left side: Location
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
              // Right side: Profile Icon (Bell Icon REMOVED from this Row)
              Row(
                children: [
                  // This IconButton for the bell icon is REMOVED
                  /*
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                  */
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.person_outlined, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          // Search Bar
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
                              color: Colors.white.withValues(alpha: 0.9),
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
    if (_filteredVehicles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No vehicles available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
              childAspectRatio: 0.65,
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
            color: Colors.black.withValues(alpha: 0.03),
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
                  Color(0xFF0066FF).withValues(alpha: 0.1),
                  Color(0xFF1A1A1A).withValues(alpha: 0.05),
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
                    Expanded(
                      child: Text(
                        vehicle['price'],
                        style: TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    vehicle['rating'] > 0.0
                        ? Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 2),
                              Text(
                                vehicle['rating'].toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No rating',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
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
                          builder: (context) =>
                              VehicleDetailScreen(vehicle: vehicle),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              _buildNavItem(Icons.person_outline, 'Profile', 2),
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
        if (index == 0) {
          setState(() => _selectedBottomNavIndex = index);
          return;
        }

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
          );
        }

        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          );
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

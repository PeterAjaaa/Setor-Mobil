import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:setor_mobil/main.dart'; // <--- IMPORTANT: Import where MyApp is defined
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

  // The promo colors should ideally also follow the ColorScheme,
  // but keeping the hardcoded colors here for unique promo identity.
  final List<Map<String, dynamic>> _promos = [
    {
      'title': '50% Discount',
      'subtitle': 'Get 50% Discount',
      'colors': [Color(0xFF0066FF), Color(0xFF2563Eb)], // Primary Blue
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'Rent 3 days minimal',
      'colors': [Color(0xFFfbbf24), Color(0xFFeA580C)], // Yellow/Orange
    },
    {
      'title': 'Cashback 100k',
      'subtitle': 'First Transaction',
      'colors': [Color(0xFFa855F7), Color(0xFF9333EA)], // Purple
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
      final token = await _storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

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

      if (responses[0].statusCode == 200) {
        final carsData = jsonDecode(responses[0].body);
        if (carsData['status'] == 200 && carsData['data'] != null) {
          final cars = (carsData['data'] as List)
              .where((car) => car['status'] == 'Available')
              .map((car) {
                return {
                  'id': car['id'],
                  'name': '${car['brand']} ${car['model']}',
                  'brand': car['brand'],
                  'model': car['model'],
                  'type': 'Car',
                  'price': '${_formatPrice(car['price_per_day'])}/day',
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

      if (responses[1].statusCode == 200) {
        final motorcyclesData = jsonDecode(responses[1].body);
        if (motorcyclesData['status'] == 200 &&
            motorcyclesData['data'] != null) {
          final motorcycles = (motorcyclesData['data'] as List)
              .where((moto) => moto['status'] == 'Available')
              .map((moto) {
                return {
                  'id': moto['id'],
                  'name': '${moto['brand']} ${moto['model']}',
                  'brand': moto['brand'],
                  'model': moto['model'],
                  'type': 'Motorcycle',
                  'price': '${_formatPrice(moto['price_per_day'])}/day',
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
        // Use a color from the theme or a dedicated error color
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicles: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    // Convert to number first to handle different input types
    final number = price is num
        ? price
        : double.tryParse(price.toString()) ?? 0;

    // Create number format for Indonesian Rupiah
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return format.format(number);
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
    // Get the ColorScheme from the current theme context
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Use the color scheme's background color (e.g., colorScheme.background or colorScheme.surface)
      // The default Scaffold background usually adapts well, but setting it explicitly can be helpful.
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        // Use the primary color from the ColorScheme
                        color: colorScheme.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVehicles,
                      // Use the primary color for the indicator color
                      color: colorScheme.primary,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPromoCarousel(colorScheme),
                            SizedBox(height: 5),
                            _buildCategories(colorScheme),
                            SizedBox(height: 24),
                            _buildVehicleList(colorScheme),
                            SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(colorScheme),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    // Use colors from ColorScheme
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Use primary container color for the header background
        color: colorScheme.primary,
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
                  // Use onPrimary for icons/text on the primary background
                  Icon(
                    Icons.location_on,
                    color: colorScheme.onPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Bandung, West Java',
                    style: TextStyle(
                      color: colorScheme.onPrimary, // Use onPrimary
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Right side: Profile Icon & Dark Mode Toggle
              Row(
                children: [
                  // --- UPDATED TOGGLE BUTTON ---
                  IconButton(
                    onPressed: () {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final newTheme = isDark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      MyApp.of(context).toggleTheme(newTheme);
                    },
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: colorScheme.onPrimary, // Use onPrimary
                    ),
                  ),
                  // -----------------------------
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.person_outlined,
                      color: colorScheme.onPrimary,
                    ), // Use onPrimary
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
              // Using colorScheme.surface or a lighter color for the search bar background
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ), // Use onSurface with opacity
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search vehicles',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      ), // Use onSurface with opacity
                      fontSize: 14,
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

  Widget _buildPromoCarousel(ColorScheme colorScheme) {
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
              // Use onBackground/onSurface for general text
              color: colorScheme.onSurface,
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
                      colors:
                          promo['colors'], // Keep hardcoded colors for promos
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
                              color: Colors
                                  .white, // Colors.white works well on the gradient
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            promo['subtitle'],
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.9,
                              ), // Colors.white works well on the gradient
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          // Use the first color of the promo for the text (e.g., blue for the blue promo)
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
                  // Use the primary color for the active indicator
                  color: index == _currentPromoIndex
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ), // Light grey equivalent on any background
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(ColorScheme colorScheme) {
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
              color: colorScheme.onSurface, // Use onBackground
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
                    // Use primary for selected, surface/secondaryContainer for unselected
                    backgroundColor: isSelected
                        ? colorScheme.primary
                        : colorScheme.secondaryContainer.withValues(
                            alpha: 0.3,
                          ), // A light grey/container background
                    foregroundColor: isSelected
                        ? colorScheme
                              .onPrimary // Text on primary is onPrimary
                        : colorScheme
                              .onSurface, // Text on container is onSurface
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

  Widget _buildVehicleList(ColorScheme colorScheme) {
    if (_filteredVehicles.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              SizedBox(height: 16),
              Text(
                'No vehicles available',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: colorScheme.onSurface, // Use onBackground
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary, // Use primary color
                  ),
                ),
                label: Icon(
                  Icons.chevron_right,
                  color: colorScheme.primary, // Use primary color
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
            // Pass the ColorScheme down to the card
            itemBuilder: (context, index) {
              final vehicle = _filteredVehicles[index];
              return _buildVehicleCard(vehicle, colorScheme);
            },
          ),
        ],
      ),
    );
  }

  // Accept ColorScheme as an argument
  Widget _buildVehicleCard(
    Map<String, dynamic> vehicle,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        // Use surface or surfaceVariant for card background
        color: colorScheme.surface,
        border: Border.all(
          // Use outline or a subtle color for the border
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
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
              // Use a gradient based on the primary color for a subtle effect
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.surface.withValues(alpha: 0.05),
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
                color: colorScheme.primary, // Icon color is primary
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
                    color: colorScheme.onSurface, // Text color is onSurface
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  vehicle['type'],
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ), // Secondary text color
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vehicle['price'],
                        style: TextStyle(
                          color: colorScheme.primary, // Price color is primary
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
                              // Keep Colors.amber for the star rating as it's a standard accent
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 2),
                              Text(
                                vehicle['rating'].toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme
                                      .onSurface, // Rating text is onSurface
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No rating',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
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
                      // Button background is primary
                      backgroundColor: colorScheme.primary,
                      // Button text color is onPrimary
                      foregroundColor: colorScheme.onPrimary,
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

  // Accept ColorScheme as an argument
  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        // Bottom nav background is surface
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.3),
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
              // Pass the ColorScheme to the nav item
              _buildNavItem(Icons.home, 'Home', 0, colorScheme),
              _buildNavItem(
                Icons.calendar_today_outlined,
                'Order',
                1,
                colorScheme,
              ),
              _buildNavItem(Icons.person_outline, 'Profile', 2, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  // Accept ColorScheme as an argument
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    ColorScheme colorScheme,
  ) {
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
            // Selected color is primary, unselected is onSurface with opacity
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.4),
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              // Selected color is primary, unselected is onSurface with opacity
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

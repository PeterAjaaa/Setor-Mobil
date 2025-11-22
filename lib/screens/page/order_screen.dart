import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:setor_mobil/screens/page/home_screen.dart';
import 'package:setor_mobil/screens/page/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _selectedBottomNavIndex = 1;
  final _storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> _ongoingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _is404Error = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _is404Error = false;
      });
    }

    try {
      final token = await _storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId =
          decodedToken['user_id'] ?? decodedToken['id'] ?? decodedToken['sub'];

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      final response = await http
          .get(
            Uri.parse('https://api.intracrania.com/orders/user/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 200 && data['data'] != null) {
          final ordersList = data['data'] as List;
          final List<Map<String, dynamic>> orders = [];

          // Fetch vehicle details for each order
          for (var order in ordersList) {
            final vehicleDetails = await _getVehicleDetails(order);
            orders.add({
              'id': order['id']?.toString() ?? 'N/A',
              'created_at': order['created_at'],
              'duration': order['duration'] ?? 0,
              'pickup_time': order['pickup_time'],
              'price': order['price'] ?? 0,
              'status': order['status'] ?? 'Unknown',
              'car_id': order['car_id'],
              'motorcycle_id': order['motorcycle_id'],
              'rating': order['rating'],
              'vehicle': vehicleDetails['name'],
              'image_url': vehicleDetails['image_url'],
              'type': order['car_id'] != null && order['car_id'] != 0
                  ? 'Car'
                  : 'Motorcycle',
            });
          }

          if (mounted) {
            setState(() {
              _ongoingOrders = orders
                  .where(
                    (order) =>
                        order['status'] == 'Active' ||
                        order['status'] == 'Pending',
                  )
                  .toList();

              _completedOrders = orders
                  .where(
                    (order) =>
                        order['status'] == 'Completed' ||
                        order['status'] == 'Cancelled',
                  )
                  .toList();

              _isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Invalid response format');
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _is404Error = true;
            _ongoingOrders = [];
            _completedOrders = [];
          });
        }
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<Map<String, String>> _getVehicleDetails(
    Map<String, dynamic> order,
  ) async {
    try {
      final token = await _storage.read(key: 'token');

      if (token == null || token.isEmpty) {
        return {'name': 'Unknown Vehicle', 'image_url': ''};
      }

      String endpoint;
      int? vehicleId;

      if (order['car_id'] != null && order['car_id'] != 0) {
        vehicleId = order['car_id'];
        endpoint = 'https://api.intracrania.com/cars/$vehicleId';
      } else if (order['motorcycle_id'] != null &&
          order['motorcycle_id'] != 0) {
        vehicleId = order['motorcycle_id'];
        endpoint = 'https://api.intracrania.com/motorcycles/$vehicleId';
      } else {
        return {'name': 'Unknown Vehicle', 'image_url': ''};
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 && data['data'] != null) {
          final vehicle = data['data'];
          return {
            'name': '${vehicle['brand']} ${vehicle['model']}',
            'image_url': vehicle['image_url'] ?? '',
          };
        }
      }

      return {'name': 'Unknown Vehicle', 'image_url': ''};
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
      return {'name': 'Unknown Vehicle', 'image_url': ''};
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      // Extract date without timezone conversion
      // Format: "2025-11-22T10:10:00+07:00"
      final parts = dateStr.split('T')[0].split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      return '${_getMonthName(month)} $day, $year';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      // Extract time without timezone conversion
      // Format: "2025-11-22T10:10:00+07:00"
      final timePart = dateStr.split('T')[1].split('+')[0].split('-')[0];
      final parts = timePart.split(':');
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return colorScheme.primary;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  void _viewOrderDetail(Map<String, dynamic> order, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Order Details',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vehicle Image
              if (order['image_url'] != null && order['image_url'].isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surfaceVariant,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: order['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          order['type'] == 'Motorcycle'
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          color: colorScheme.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(
                          order['type'] == 'Motorcycle'
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          color: colorScheme.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              _buildDetailText(
                'Vehicle',
                order['vehicle'] ?? 'N/A',
                colorScheme,
              ),
              _buildDetailText('Type', order['type'] ?? 'N/A', colorScheme),
              _buildDetailText(
                'Duration',
                '${order['duration'] ?? 0} days',
                colorScheme,
              ),
              _buildDetailText(
                'Price',
                _formatPrice(order['price']),
                colorScheme,
              ),
              _buildDetailText(
                'Pickup Time',
                '${_formatDate(order['pickup_time'])} at ${_formatTime(order['pickup_time'])}',
                colorScheme,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${order['status'] ?? 'Unknown'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (order['rating'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rating: ${order['rating']['Rating'] ?? 'N/A'} ⭐',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailText(
    String label,
    String? value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: Text(
          'My Orders',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        bottom:
            _is404Error ||
                (_ongoingOrders.isEmpty &&
                    _completedOrders.isEmpty &&
                    !_isLoading &&
                    !_hasError)
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.onPrimary,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onPrimary.withValues(
                  alpha: 0.7,
                ),
                tabs: [
                  Tab(text: 'Ongoing (${_ongoingOrders.length})'),
                  Tab(text: 'Completed (${_completedOrders.length})'),
                ],
              ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: TextStyle(color: colorScheme.error),
                  ),
                  ElevatedButton(
                    onPressed: _fetchOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _is404Error || (_ongoingOrders.isEmpty && _completedOrders.isEmpty)
          ? _buildNoOrdersWidget(colorScheme)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_ongoingOrders, colorScheme),
                _buildOrderList(_completedOrders, colorScheme),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(colorScheme),
    );
  }

  Widget _buildNoOrdersWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 60,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(
              'Go to Home',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders,
    ColorScheme colorScheme,
  ) {
    Widget content;

    if (orders.isEmpty) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Text(
              "No orders in this category",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderListCard(orders[index], colorScheme),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: colorScheme.primary,
      child: content,
    );
  }

  Widget _buildOrderListCard(
    Map<String, dynamic> order,
    ColorScheme colorScheme,
  ) {
    return _buildOrderCard(order, colorScheme);
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(
      order['status'] ?? 'Unknown',
      colorScheme,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewOrderDetail(order, colorScheme),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Vehicle Image with proper cropping
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        order['image_url'] != null &&
                            order['image_url'].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: order['image_url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: colorScheme.surfaceVariant,
                              child: Icon(
                                order['type'] == 'Motorcycle'
                                    ? Icons.two_wheeler
                                    : Icons.directions_car,
                                color: colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: colorScheme.surfaceVariant,
                              child: Icon(
                                order['type'] == 'Motorcycle'
                                    ? Icons.two_wheeler
                                    : Icons.directions_car,
                                color: colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                          )
                        : Icon(
                            order['type'] == 'Motorcycle'
                                ? Icons.two_wheeler
                                : Icons.directions_car,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['vehicle'] ?? 'Unknown Vehicle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatPrice(order['price']),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _viewOrderDetail(order, colorScheme),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Detail'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedBottomNavIndex == index;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () {
        if (_selectedBottomNavIndex != index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Ensure these imports match your project structure
import 'package:setor_mobil/screens/page/home_screen.dart';
import 'package:setor_mobil/screens/page/profile_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBottomNavIndex = 1; // Order is index 1
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
      final userId = decodedToken['user_id'] ?? decodedToken['id'] ?? decodedToken['sub'];

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
          final orders = (data['data'] as List).map((order) {
            return {
              'id': order['id'].toString(),
              'created_at': order['created_at'],
              'duration': order['duration'],
              'pickup_time': order['pickup_time'],
              'pickup_location': order['pickup_location'],
              'price': order['price'],
              'status': order['status'],
              'car_id': order['car_id'],
              'motorcycle_id': order['motorcycle_id'],
              'rating': order['rating'],
              'vehicle': _getVehicleName(order),
              'type': order['car_id'] != null && order['car_id'] != 0
                  ? 'Car'
                  : 'Motorcycle',
            };
          }).toList();

          if (mounted) {
            setState(() {
              _ongoingOrders = orders
                  .where((order) =>
                      order['status'] == 'Active' || order['status'] == 'Pending')
                  .toList();

              _completedOrders = orders
                  .where((order) =>
                      order['status'] == 'Completed' || order['status'] == 'Cancelled')
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

  String _getVehicleName(Map<String, dynamic> order) {
    if (order['car_id'] != null && order['car_id'] != 0) {
      return 'Car #${order['car_id']}';
    } else if (order['motorcycle_id'] != null && order['motorcycle_id'] != 0) {
      return 'Motorcycle #${order['motorcycle_id']}';
    }
    return 'Unknown Vehicle';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
        return colorScheme.primary; // Use Global Primary Color
      case 'cancelled':
        return colorScheme.error; // Use Global Error Color
      default:
        return colorScheme.outline;
    }
  }

  void _viewOrderDetail(Map<String, dynamic> order, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Order #${order['id']}', style: TextStyle(color: colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailText('Vehicle', order['vehicle'], colorScheme),
              _buildDetailText('Type', order['type'], colorScheme),
              _buildDetailText('Duration', '${order['duration']} days', colorScheme),
              _buildDetailText('Price', _formatPrice(order['price']), colorScheme),
              _buildDetailText('Pickup Location', order['pickup_location'], colorScheme),
              _buildDetailText('Pickup Time',
                  '${_formatDate(order['pickup_time'])} at ${_formatTime(order['pickup_time'])}', colorScheme),
              const SizedBox(height: 8),
              Text(
                'Status: ${order['status']}',
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              if (order['rating'] != null) ...[
                const SizedBox(height: 8),
                Text('Rating: ${order['rating']['Rating']} ⭐', style: TextStyle(color: colorScheme.onSurface)),
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

  Widget _buildDetailText(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === GLOBAL THEME ACCESS ===
    // This pulls colors from your main.dart ThemeData
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Uses global background color
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // Uses global primary color
        title: Text(
          'My Orders',
          style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        bottom: _is404Error || (_ongoingOrders.isEmpty && _completedOrders.isEmpty && !_isLoading && !_hasError)
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.onPrimary, // Uses global onPrimary color
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
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
                    Text(_errorMessage, style: TextStyle(color: colorScheme.error)),
                    ElevatedButton(
                        onPressed: _fetchOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: const Text("Retry"))
                  ],
                ))
              : _is404Error || (_ongoingOrders.isEmpty && _completedOrders.isEmpty)
                  ? _buildNoOrdersWidget(colorScheme)
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: colorScheme.primary,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOrderList(_ongoingOrders, colorScheme),
                          _buildOrderList(_completedOrders, colorScheme),
                        ],
                      ),
                    ),
      bottomNavigationBar: _buildBottomNav(colorScheme),
    );
  }

  Widget _buildNoOrdersWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 60, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('No orders yet',
              style: TextStyle(fontSize: 18, color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (context) => const HomeScreen()),
               );
            },
            child: Text('Go to Home', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders, ColorScheme colorScheme) {
    if (orders.isEmpty) {
      return Center(child: Text("No orders in this category", style: TextStyle(color: colorScheme.onSurfaceVariant)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index], colorScheme),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(order['status'], colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
                Text(
                  'Order #${order['id']}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    order['type'] == 'Motorcycle' ? Icons.two_wheeler : Icons.directions_car,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['vehicle'],
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      Text(_formatPrice(order['price']),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: colorScheme.shadow.withOpacity(0.1),
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
              _buildNavItem(Icons.calendar_today_outlined, 'Order', 1, colorScheme),
              _buildNavItem(Icons.person_outline, 'Profile', 2, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, ColorScheme colorScheme) {
    final isSelected = _selectedBottomNavIndex == index;
    // Use global Primary color for selected, global onSurfaceVariant for unselected
    final color = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.6);

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
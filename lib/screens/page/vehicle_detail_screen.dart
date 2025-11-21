import 'package:flutter/material.dart';
import 'package:setor_mobil/screens/widgets/booking_bottom_sheet.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  void _showBookingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: Stack(
        children: [
          // 1. The Scroll View
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF0066FF),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0066FF).withValues(alpha: 0.1),
                          const Color(0xFF1A1A1A).withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        vehicle['type'] == 'Motorcycle'
                            ? Icons.motorcycle
                            : Icons.directions_car,
                        size: 120,
                        color: const Color(0xFF0066FF),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle['name'],
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle['type'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.amber.shade50,
                              border: Border.all(
                                color: isDark
                                    ? Colors.amber.withValues(alpha: 0.3)
                                    : Colors.amber.shade100,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vehicle['rating'].toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  ' (124)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Price Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(
                                      0xFF1E3ABA,
                                    ).withValues(alpha: 0.3),
                                    const Color(
                                      0xFF1E40AF,
                                    ).withValues(alpha: 0.3),
                                  ]
                                : [Colors.blue.shade50, Colors.blue.shade100],
                          ),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E40AF).withValues(alpha: 0.5)
                                : Colors.blue.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rental Price',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  vehicle['price'],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0066FF),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // --- MODIFICATION HERE ---
                      // The text will naturally wrap and expand the column height
                      Text(
                        vehicle['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. The Floating Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              ),
              child: SafeArea(
                // 1. Reduce bottom spacing (was 10) to match the top
                minimum: const EdgeInsets.only(bottom: 4),
                child: Padding(
                  // 2. Reduce top spacing (was 10). This removes the gap above.
                  padding: const EdgeInsets.only(top: 4, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _showBookingBottomSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: const Color(
                          0xFF0066FF,
                        ).withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget (kept from your original code)
  Widget _buildFeature(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: const Color(0xFF2A2A2A)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0066FF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

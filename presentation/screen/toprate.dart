// screens/recent_orders.dart
import 'package:flutter/material.dart';
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/domain/driverservice.dart';

class toprateWidget extends StatefulWidget {
  const toprateWidget({Key? key}) : super(key: key);

  @override
  State<toprateWidget> createState() => _RecentOrdersWidgetState();
}

class _RecentOrdersWidgetState extends State<toprateWidget> {
  bool _isLoading = true;
  List<UserModel> _users = []; // Use your existing UserModel
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
  }

  Future<void> _loadRecentUsers() async {
    try {
      final profileService = ProfileService();
      final users = await profileService.getAllUsers();
      
      // Filter users with rating >= 3
      final filteredUsers = users.where((user) => 
          (user.rating ?? 0.0) > 3.0
      ).toList();
      
      // Take only first 5 filtered users (or all if less than 5)
      final recentUsers = filteredUsers.take(10).toList();
      
      setState(() {
        _users = recentUsers;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load recent orders: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _loadRecentUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Drivers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rating above 3.0 only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _refreshOrders,
                  icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Horizontal scroll view
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _refreshOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_border,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No premium drivers available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Minimum rating: above 3.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: _refreshOrders,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  ),
                                  child: const Text(
                                    'Refresh',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User info with rating
                                        Row(
                                          children: [
                                            // Profile Image
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(25),
                                                color: Colors.deepPurple.withOpacity(0.1),
                                              ),
                                              child: (user.image ?? '').isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(25),
                                                      child: Image.network(
                                                        user.image!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            const Icon(
                                                          Icons.person,
                                                          color: Colors.deepPurple,
                                                          size: 24,
                                                        ),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.person,
                                                      color: Colors.deepPurple,
                                                      size: 24,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  // Rating display
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: Colors.amber,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${(user.rating ?? 0.0).toStringAsFixed(1)}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                      if ((user.rating ?? 0.0) >= 4.0)
                                                        Container(
                                                          margin: const EdgeInsets.only(left: 6),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(
                                                              color: Colors.green,
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'Top Rated',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Driver details
                                        _buildDetailRow(
                                          Icons.phone,
                                          user.phone ?? 'No phone',
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        _buildDetailRow(
                                          Icons.work_history,
                                          '${user.experience ?? 0} years experience',
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        if (user.price != null && user.price! > 0)
                                          _buildDetailRow(
                                            Icons.attach_money,
                                            '₹${user.price!.toStringAsFixed(2)}/km',
                                            color: Colors.green,
                                            isBold: true,
                                          ),
                                        
                                        // Extra details for orders
                                        const SizedBox(height: 6),
                                        _buildDetailRow(
                                          Icons.location_on,
                                          'Available for rides',
                                          color: Colors.blue,
                                        ),
                                        
                                        const SizedBox(height: 12),
                                        
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.deepPurple,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Premium Driver',
                                                style: TextStyle(
                                                  color: Colors.deepPurple,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color color = Colors.grey, bool isBold = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

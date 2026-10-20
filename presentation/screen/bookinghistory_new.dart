import 'package:flutter/material.dart';
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/domain/bookingservice.dart';
import 'package:url_launcher/url_launcher.dart';

class Bookinghistory extends StatefulWidget {
  const Bookinghistory({super.key});

  @override
  State<Bookinghistory> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<Bookinghistory>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _allBookingData = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterByTab(_tabController.index);
      }
    });
    _loadAllBookingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _filterByTab(int index) {
    setState(() {
      switch (index) {
        case 0:
          _filteredBookings = List.from(_bookings);
          break;
        case 1:
          _filteredBookings = _bookings
              .where((b) => b.status.toLowerCase() == 'confirmed')
              .toList();
          break;
        case 2:
          _filteredBookings = _bookings
              .where((b) => b.status.toLowerCase() == 'pending')
              .toList();
          break;
        case 3:
          _filteredBookings = _bookings
              .where((b) =>
                  b.status.toLowerCase() == 'cancelled' ||
                  b.status.toLowerCase() == 'canceled')
              .toList();
          break;
      }
    });
  }

  Future<void> _loadAllBookingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allData = await _bookingService.getAllBookingData();
      setState(() {
        _allBookingData = allData;
        _bookings = allData['allBookings'] as List<BookingModel>;
        _filteredBookings = List.from(_bookings);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBookings() async {
    await _loadAllBookingData();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate == today) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (bookingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getAddress(String address) {
    if (address.isEmpty ||
        address == "null" ||
        address.toLowerCase() == "address not available") {
      return "Address not available";
    }
    return address;
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 1:
        return 'confirmed';
      case 2:
        return 'pending';
      case 3:
        return 'cancelled';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // ✅ NO AppBar — avoids all title/action/tab overflow conflicts
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Custom Header Row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Booking History",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    onPressed: _refreshBookings,
                  ),
                ],
              ),
            ),

            // ✅ TabBar in its own container — fully separated from AppBar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: Colors.grey[200]),

            // ✅ Body content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _bookings.isEmpty
                          ? const Center(child: Text('No bookings found'))
                          : RefreshIndicator(
                              onRefresh: _refreshBookings,
                              child: _filteredBookings.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No ${_getTabLabel(_tabController.index)} bookings found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _filteredBookings.length,
                                      itemBuilder: (context, index) {
                                        final booking =
                                            _filteredBookings[index];
                                        return _buildBookingCard(booking);
                                      },
                                    ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final pickupAddress = _getAddress(booking.pickupAddress);
    final dropAddress = _getAddress(booking.dropAddress);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatDate(booking.bookedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.person,
                            size: 22, color: Colors.amber[800]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            booking.userPhone,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _buildRouteRow(
                  Icons.location_on,
                  "Pickup",
                  pickupAddress,
                  pickupAddress == "Address not available",
                ),

                const SizedBox(height: 8),

                _buildRouteRow(
                  Icons.flag,
                  "Drop",
                  dropAddress,
                  dropAddress == "Address not available",
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: booking.status.toLowerCase() == 'completed'
                      ? ElevatedButton(
                          onPressed: () =>
                              _showPaymentDialog(booking, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Payment",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () =>
                              _showBookingDetails(booking, context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.amber),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
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

  Widget _buildRouteRow(
      IconData icon, String label, String address, bool isNotAvailable) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 16,
            color: isNotAvailable ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isNotAvailable ? Colors.grey[400] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isNotAvailable ? Colors.grey[400] : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getBookingPrice(BookingModel booking) {
    // Use only the price from API response, ensure it's not null
    final price = booking.price;
    if (price != null && price > 0) {
      return price;
    }
    return 0.0;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "completed":
        return Colors.green;
      case "cancelled":
      case "canceled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _normalizePhoneForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  Future<void> _sendOtpToWhatsApp(String phone) async {
    final whatsappPhone = _normalizePhoneForWhatsApp(phone);
    if (whatsappPhone.isEmpty) {
      throw Exception('Invalid phone number for WhatsApp OTP');
    }

    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final text = Uri.encodeComponent('Your OTP will is  now available will expire in 5 minutes : $otp');
    final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$text');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Unable to open WhatsApp');
    }
  }

  Future<void> _callCustomer(String phone) async {
    final sanitizedPhone = phone.trim();
    if (sanitizedPhone.isEmpty) {
      throw Exception('Customer phone number is missing');
    }

    final uri = Uri.parse('tel:$sanitizedPhone');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Unable to open phone dialer');
    }
  }

  void _showBookingDetails(BookingModel booking, BuildContext context) {
    final pickupAddress = _getAddress(booking.pickupAddress);
    final dropAddress = _getAddress(booking.dropAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Booking Details",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                        Icons.person, "Customer Name", booking.userName),
                    _buildDetailRow(
                        Icons.phone, "Phone Number", booking.userPhone),
                    _buildDetailRow(
                        Icons.location_on, "Pickup", pickupAddress),
                    _buildDetailRow(Icons.flag, "Drop", dropAddress),
                    _buildDetailRow(Icons.calendar_today, "Booked Date",
                        _formatDate(booking.bookedDate)),
                    _buildDetailRow(Icons.info, "Status", booking.status),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _callCustomer(booking.userPhone).catchError((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Unable to call customer"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Contact Driver",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BookingModel booking, BuildContext context) {
    try {
      final price = _getBookingPrice(booking);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Process payment for ${booking.userName}?'),
              const SizedBox(height: 16),
              Text(
                'Amount: ₹${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Processing payment...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  
                  // Process payment via API
                  final result = await _bookingService.processPayment(
                    name: booking.userName,
                    email: booking.userEmail ?? '',
                    phone: booking.userPhone,
                    paymentMethod: 'cash',
                    bookingId: booking.id ?? '',
                    amount: _getBookingPrice(booking),
                    pickupAddress: booking.pickupAddress,
                    dropAddress: booking.dropAddress,
                  );

                  // Send OTP to registered customer WhatsApp number after payment.
                  await _sendOtpToWhatsApp(booking.userPhone);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result['message'] ?? 'Payment processed successfully!'} OTP sent to registered WhatsApp.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/domain/bookingservice.dart';
import 'package:taxiuuse/presentation/screen/payment_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class Bookinghistory extends StatefulWidget {
  const Bookinghistory({super.key});

  @override
  State<Bookinghistory> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<Bookinghistory>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  List<BookingModel> _bookings = [];
  List<BookingModel> _filteredBookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter dropdown variable
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Confirmed', 'Pending', 'Cancelled'];
  String _selectedDateFilter = 'All Dates';
  final List<String> _dateFilterOptions = [
    'All Dates',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'This Month',
    'Custom Range',
  ];
  DateTimeRange? _customDateRange;
  
  // Speech-to-text variables
  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _loadAllBookingData();
  }

  // ===============================
  // SPEECH TO TEXT INITIALIZATION
  // ===============================
  void _initSpeechToText() async {
    try {
      _speechToText = SpeechToText();
      
      // Request microphone permission
      var status = await Permission.microphone.request();
      
      if (status == PermissionStatus.granted) {
        bool available = await _speechToText.initialize(
          onError: (val) {
            print('Speech error: $val');
            setState(() {
              _isListening = false;
            });
          },
          onStatus: (val) {
            setState(() {
              if (val == 'done' || val == 'notListening') {
                _isListening = false;
              }
            });
          },
        );
        
        if (available) {
          setState(() {
            _speechEnabled = true;
          });
          print('✅ Speech recognition enabled in booking history');
        }
      } else {
        print('❌ Microphone permission denied in booking history');
        setState(() {
          _speechEnabled = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎤 Microphone permission is required for voice search in booking history'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Enable Now',
              textColor: Colors.white,
              onPressed: () async {
                bool opened = await openAppSettings();
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable microphone permission in your device settings'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Speech initialization error in booking history: $e');
      setState(() {
        _speechEnabled = false;
        _isListening = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() {
      _isListening = true;
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'en_US',
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _filterBookingsBySearch(String query) {
    setState(() {
      _searchController.text = query;
      _applyAllFilters();
    });
  }

  void _applyStatusFilter() {
    _applyAllFilters();
  }

  void _applyAllFilters() {
    final statusFiltered = _filterBookingsByStatus(_bookings);
    final dateFiltered = _filterBookingsByDate(statusFiltered);

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      _filteredBookings = dateFiltered.where((booking) =>
        booking.userName.toLowerCase().contains(query) ||
        booking.userPhone.toLowerCase().contains(query) ||
        booking.pickupAddress.toLowerCase().contains(query) ||
        booking.dropAddress.toLowerCase().contains(query)
      ).toList();
    } else {
      _filteredBookings = dateFiltered;
    }
  }

  List<BookingModel> _filterBookingsByStatus(List<BookingModel> bookings) {
    switch (_selectedFilter) {
      case 'Confirmed':
        return bookings.where((booking) => 
          booking.status.toLowerCase() == 'confirmed' ||
          booking.status.toLowerCase() == 'assigned' ||
          booking.status.toLowerCase() == 'completed'
        ).toList();
      case 'Pending':
        return bookings.where((booking) => 
          booking.status.toLowerCase() == 'pending' ||
          booking.status.toLowerCase() == 'waiting'
        ).toList();
      case 'Cancelled':
        return bookings.where((booking) => 
          booking.status.toLowerCase() == 'cancelled' ||
          booking.status.toLowerCase() == 'rejected'
        ).toList();
      default:
        return List.from(bookings);
    }
  }

  List<BookingModel> _filterBookingsByDate(List<BookingModel> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isSameDate(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    switch (_selectedDateFilter) {
      case 'Today':
        return bookings.where((booking) {
          final bookedDate = booking.bookedDate.toLocal();
          return isSameDate(bookedDate, today);
        }).toList();
      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return bookings.where((booking) {
          final bookedDate = booking.bookedDate.toLocal();
          return isSameDate(bookedDate, yesterday);
        }).toList();
      case 'Last 7 Days':
        final start = today.subtract(const Duration(days: 6));
        return bookings.where((booking) {
          final bookedDate = booking.bookedDate.toLocal();
          final normalized = DateTime(
            bookedDate.year,
            bookedDate.month,
            bookedDate.day,
          );
          return !normalized.isBefore(start) && !normalized.isAfter(today);
        }).toList();
      case 'This Month':
        return bookings.where((booking) {
          final bookedDate = booking.bookedDate.toLocal();
          return bookedDate.year == now.year && bookedDate.month == now.month;
        }).toList();
      case 'Custom Range':
        if (_customDateRange == null) {
          return List.from(bookings);
        }
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return bookings.where((booking) {
          final bookedDate = booking.bookedDate.toLocal();
          return !bookedDate.isBefore(start) && !bookedDate.isAfter(end);
        }).toList();
      default:
        return List.from(bookings);
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = 'Custom Range';
        _applyAllFilters();
      });
    }
  }

  String _getDateFilterLabel() {
    if (_selectedDateFilter == 'Custom Range' && _customDateRange != null) {
      final start = _customDateRange!.start;
      final end = _customDateRange!.end;
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    }
    return _selectedDateFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Call all booking APIs to get complete data
  Future<void> _loadAllBookingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all booking data from all endpoints
      final allData = await _bookingService.getAllBookingData();
      
      setState(() {
        _bookings = allData['allBookings'] as List<BookingModel>;
        _applyAllFilters(); // Apply filters after loading
        _isLoading = false;
      });

      print('✅ All booking data loaded successfully:');
      print('Total bookings: ${allData['totalBookings']}');
      print('Pending: ${allData['pendingCount']}');
      print('Assigned: ${allData['assignedCount']}');
      print('Ongoing: ${allData['ongoingCount']}');
      print('Completed: ${allData['completedCount']}');
      print('Cancelled: ${allData['cancelledCount']}');
      print('Today: ${allData['todayCount']}');

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load booking data: $e';
        _isLoading = false;
      });
      print('❌ Error loading booking data: $e');
    }
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Booking History",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBookings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              
              // Filter Dropdown
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.filter_list, color: Colors.amber),
                      isExpanded: true,
                      items: _filterOptions.map((String filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Row(
                            children: [
                              Icon(
                                _getFilterIcon(filter),
                                size: 18,
                                color: _getFilterColor(filter),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: filter == _selectedFilter 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  color: _getFilterColor(filter),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFilter = newValue;
                            _applyAllFilters();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDateFilter,
                      icon: const Icon(Icons.date_range, color: Colors.amber),
                      isExpanded: true,
                      items: _dateFilterOptions.map((String filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Text(
                            filter == 'Custom Range' ? _getDateFilterLabel() : filter,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        if (newValue == null) return;
                        if (newValue == 'Custom Range') {
                          await _pickCustomDateRange();
                          return;
                        }
                        setState(() {
                          _selectedDateFilter = newValue;
                          if (newValue != 'Custom Range') {
                            _customDateRange = null;
                          }
                          _applyAllFilters();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _bookings.isEmpty
                  ? const Center(child: Text('No bookings found'))
                  : RefreshIndicator(
                      onRefresh: _refreshBookings,
                      child: _buildBookingList(),
                    ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Confirmed':
        return Icons.check_circle;
      case 'Pending':
        return Icons.pending;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.list_alt;
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  Widget _buildBookingList() {
    return Column(
      children: [
        // Category Header with Count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getFilterIcon(_selectedFilter),
                    color: _getFilterColor(_selectedFilter),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedFilter} Bookings',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_filteredBookings.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Booking List
        Expanded(
          child: _filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getFilterIcon(_selectedFilter),
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedFilter.toLowerCase()} bookings',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _filteredBookings[index];
                    return _buildBookingCard(booking);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDate(booking.bookedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 25,
                          color: Colors.amber[800],
                        ),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            booking.userPhone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildRouteRow(Icons.location_on, "Pickup", booking.pickupAddress),
                const SizedBox(height: 8),
                _buildRouteRow(Icons.flag, "Drop", booking.dropAddress),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: booking.status.toLowerCase() == 'completed'
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>PaymentScreen(booking: booking)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Payment",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            _showBookingDetails(booking, context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.amber),
                          ),
                          child: const Text(
                            "View Details",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
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

  Widget _buildRouteRow(IconData icon, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "confirmed":
        return Colors.green;
      case "pending":
        return Colors.blue;
      case "canceled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBookingDetails(BookingModel booking, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                    Text(
                      "Booking Details",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, "Customer Name", booking.userName),
                    _buildDetailRow(Icons.phone, "Phone Number", booking.userPhone),
                    _buildDetailRow(Icons.calendar_today, "Booked Date", _formatDate(booking.bookedDate)),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
}

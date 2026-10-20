import 'package:flutter/material.dart';
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;

  String _encodedNote() {
    return Uri.encodeComponent(
      'Taxi Payment for ${widget.booking.userName} - ${widget.booking.id}',
    );
  }

  Future<void> _processCashPayment() async {
    setState(() => _isLoading = true);
    
    try {
      // Cash is collected offline; no API call.
      await Future.delayed(const Duration(milliseconds: 300));
      
      setState(() => _isLoading = false);
      _showPaymentSuccessDialog('Cash');
    } catch (e) {
      setState(() => _isLoading = false);
      _showPaymentErrorDialog('Payment processing error: $e');
    }
  }

  double _calculateDynamicAmount() {
    if (widget.booking.price != null && widget.booking.price! > 0) {
      return widget.booking.price!;
    }
    return 100.0;
  }

  void _showPaymentSuccessDialog(String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$method Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Payment confirmed for ${widget.booking.userName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: INR ${_calculateDynamicAmount().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to booking history
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPaymentApp(String paymentMethod) async {
    const upiId = '919876543210'; // Replace with your real UPI ID (example: merchant@upi)
    final amount = _calculateDynamicAmount().toStringAsFixed(2);
    final note = _encodedNote();

    final uriCandidates = <Uri>[];

    switch (paymentMethod.toLowerCase()) {
      case 'gpay':
        uriCandidates.addAll([
          Uri.parse('gpay://upi/pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
          Uri.parse('tez://upi/pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
          Uri.parse('upi://pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
        ]);
        break;
      case 'phonepay':
        uriCandidates.addAll([
          Uri.parse('phonepe://upi/pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
          Uri.parse('phonepe://pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
          Uri.parse('upi://pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
        ]);
        break;
      default:
        uriCandidates.add(
          Uri.parse('upi://pay?pa=$upiId&pn=TaxiService&am=$amount&cu=INR&tn=$note'),
        );
    }

    try {
      for (final uri in uriCandidates) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch payment app. Please install a UPI app.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _buildPaymentScreen(),
    );
  }


  Widget _buildPaymentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Booking Details Card
          Container(
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Booking Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(Icons.person, "Customer", widget.booking.userName),
                _buildDetailRow(Icons.phone, "Phone", widget.booking.userPhone),
              
                const Divider(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Amount",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "INR ${_calculateDynamicAmount().toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Payment Methods
          const Text(
            "Select Payment Method",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Cash Payment Option
          _buildPaymentMethodButton(
            "Cash Payment",
            "Cash",
            Colors.green,
            () => _processCashPayment(),
          ),
          
          const SizedBox(height: 12),
          
          // GPay Button
          _buildPaymentMethodButton(
            "Google Pay",
            "assets/gpay_logo.png", // You'll need to add this asset
            Colors.blue,
            () => _launchPaymentApp('gpay'),
          ),
          
          const SizedBox(height: 12),
          
          // PhonePe Button
          _buildPaymentMethodButton(
            "PhonePe",
            "assets/phonepe_logo.png", // You'll need to add this asset
            Colors.purple,
            () => _launchPaymentApp('phonepay'),
          ),
          
          const SizedBox(height: 24),
          
          // Card Payment Option (for future implementation)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.credit_card, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Card Payment",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Coming soon",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
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

  Widget _buildPaymentMethodButton(
    String title,
    String logoPath,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title == "Google Pay" ? Icons.account_balance_wallet : Icons.phone_android,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "PAY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

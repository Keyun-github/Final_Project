import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'order_tracking_page.dart';

class PaymentPage extends StatefulWidget {
  final CartProvider cart;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String deliveryTime;
  final String? deliveryDate;
  final String? deliverySlot;

  const PaymentPage({
    super.key,
    required this.cart,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.deliveryTime,
    this.deliveryDate,
    this.deliverySlot,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String _selectedMethod = 'Midtrans';
  bool _isProcessing = false;
  final DELIVERY_FEE = 10000;

  String get _totalWithDeliveryFormatted =>
      'Rp ${(widget.cart.totalPrice + DELIVERY_FEE).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    bool slotBooked = false;
    String? redirectUrl;
    String? transactionId;
    int? orderId;

    try {
      // Book time slot if available - MUST succeed to proceed
      if (widget.deliveryDate != null && widget.deliveryTime.isNotEmpty) {
        final success = await ApiService.bookTimeSlot(
          widget.deliveryDate!,
          widget.deliveryTime,
        );
        if (!success) {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
          });
          _showStockError(
            'Waktu pengiriman sudah penuh. Silakan pilih waktu lain.',
          );
          return;
        }
        slotBooked = true;
      }

      // Submit order to backend API (with PENDING_PAYMENT status for Midtrans)
      final orderResponse = await ApiService.createOrder(
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        deliveryAddress: widget.customerAddress,
        totalAmount: widget.cart.totalPrice + DELIVERY_FEE,
        paymentMethod: _selectedMethod,
        items: widget.cart.items
            .map(
              (item) => {
                'productName': item.product.name,
                'unitName': item.selectedUnit ?? '',
                'unitPrice': item.effectivePrice,
                'quantity': item.quantity,
              },
            )
            .toList(),
        deliveryDate: widget.deliveryDate,
        deliveryTime: widget.deliveryTime,
      );

      orderId = orderResponse['id'];
      print('[PaymentPage] Order created with ID: $orderId, status: ${orderResponse['status']}');

      // Get snap token from Midtrans
      final snapData = await ApiService.getSnapToken(
        orderId: orderId.toString(),
        amount: widget.cart.totalPrice + DELIVERY_FEE,
        customerName: widget.customerName,
        customerEmail: 'customer_${widget.customerPhone}@test.com',
        customerPhone: widget.customerPhone,
      );

      redirectUrl = snapData['redirectUrl'];
      transactionId = snapData['transactionId'];
      print('[PaymentPage] Got snap token: $transactionId');
      print('[PaymentPage] Redirect URL: $redirectUrl');

      if (!mounted) return;

      if (redirectUrl != null) {
        // Open Midtrans payment page in browser
        final uri = Uri.parse(redirectUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          print('[PaymentPage] Could not open URL: $redirectUrl');
        }

        // Show dialog to check payment status
        final shouldConfirm = await _showPaymentRedirectDialog(transactionId ?? '');

        if (!shouldConfirm || !mounted) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      // Confirm payment (backend will update status to PENDING and deduct stock)
      if (orderId != null) {
        final confirmResult = await ApiService.confirmPayment(orderId);
        print('[PaymentPage] Payment confirmed: $confirmResult');
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to order tracking
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderTrackingPage(
            customerName: widget.customerName,
            customerAddress: widget.customerAddress,
            paymentMethod: _selectedMethod,
            totalAmount: _totalWithDeliveryFormatted,
            deliveryTime: widget.deliveryTime,
            orderId: orderId,
          ),
        ),
        (route) => route.isFirst, // Keep only the home page
      );

      // Clear cart
      widget.cart.clearCart();
    } on StockException catch (e) {
      // Release time slot on stock error
      if (slotBooked &&
          widget.deliveryDate != null &&
          widget.deliveryTime.isNotEmpty) {
        await ApiService.releaseTimeSlot(
          widget.deliveryDate!,
          widget.deliveryTime,
        );
      }
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showStockError(e.message);
    } catch (e) {
      print('[PaymentPage] Error: $e');
      // Release time slot on any error
      if (slotBooked &&
          widget.deliveryDate != null &&
          widget.deliveryTime.isNotEmpty) {
        await ApiService.releaseTimeSlot(
          widget.deliveryDate!,
          widget.deliveryTime,
        );
      }
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showStockError('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<bool> _showPaymentRedirectDialog(String transactionId) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            const Text(
              'Selesaikan Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Silakan selesaikan pembayaran di halaman Midtrans.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transaction ID:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              transactionId,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Setelah pembayaran selesai, tekan "Pembayaran Selesai" di bawah.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Belum Selesai',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00C853),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Pembayaran Selesai',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showStockError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text(
              'Stok Tidak Cukup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Memproses pembayaran...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Total Amount Card =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalWithDeliveryFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.cart.itemCount} item',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===== Delivery Info Summary =====
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kirim ke:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.customerPhone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.customerAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===== Payment Method (Midtrans Only) =====
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF6C63FF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0065F8,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0065F8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Midtrans',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bank Transfer, E-Wallet, QRIS, dll',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

      // Bottom: Pay Now
      bottomNavigationBar: _isProcessing
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Bayar Sekarang',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

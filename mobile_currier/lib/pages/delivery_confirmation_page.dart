import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class DeliveryConfirmationPage extends StatefulWidget {
  final int orderId;
  final Future<void> Function() onConfirm;

  const DeliveryConfirmationPage({
    super.key,
    required this.orderId,
    required this.onConfirm,
  });

  @override
  State<DeliveryConfirmationPage> createState() =>
      _DeliveryConfirmationPageState();
}

class _DeliveryConfirmationPageState extends State<DeliveryConfirmationPage> {
  File? _deliveryPhoto;
  XFile? _deliveryPhotoXFile; // For web compatibility
  bool _hasSignature = false;
  bool _isLoading = false;
  int _orderId = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId;
  }

  Future<void> _takePhoto({bool fromCamera = true}) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _deliveryPhotoXFile = photo;
          // Try to create File, but may not work on web
          try {
            _deliveryPhoto = File(photo.path);
          } catch (e) {
            // On web, File(photo.path) won't work, keep _deliveryPhoto as null
            _deliveryPhoto = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _takePhoto(fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to display photo - works on all platforms
  Widget _buildPhotoDisplay() {
    // Web: use XFile path (it's a blob URL that works with Image.network)
    if (_deliveryPhotoXFile != null) {
      return Image.network(
        _deliveryPhotoXFile!.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image, size: 48),
      );
    }

    // Native: use File
    if (_deliveryPhoto != null) {
      return Image.file(_deliveryPhoto!, fit: BoxFit.cover);
    }

    // No photo - show placeholder
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(
          'Ketuk untuk mengambil foto',
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showSignaturePad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SignaturePad(
        onSignatureComplete: (hasSignature) {
          setState(() {
            _hasSignature = hasSignature;
          });
        },
      ),
    );
  }

  Future<void> _confirmDelivery() async {
    // Check if we have a photo (either File or XFile)
    if (_deliveryPhoto == null && _deliveryPhotoXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan foto terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan minta tanda tangan customer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload photo to Supabase first
      if (_orderId > 0) {
        final String? photoPath =
            _deliveryPhotoXFile?.path ?? _deliveryPhoto?.path;
        if (photoPath != null) {
          debugPrint(
            '[_confirmDelivery] Uploading photo to Supabase for order $_orderId: $photoPath',
          );

          // Upload to Supabase
          final supabaseUrl = await SupabaseService.uploadDeliveryPhoto(photoPath);

          if (supabaseUrl != null) {
            debugPrint(
              '[_confirmDelivery] Supabase upload successful: $supabaseUrl',
            );

            // Save URL to backend
            final saved = await ApiService.saveDeliveryPhotoUrl(
              _orderId,
              supabaseUrl,
            );

            if (saved) {
              debugPrint('[_confirmDelivery] URL saved to backend');
            } else {
              debugPrint('[_confirmDelivery] Failed to save URL to backend');
            }
          } else {
            debugPrint(
              '[_confirmDelivery] Supabase upload returned null - continuing anyway',
            );
          }
        }
      }

      // Call onConfirm to update status
      debugPrint('[_confirmDelivery] Calling onConfirm callback...');
      if (mounted) {
        await widget.onConfirm();
        debugPrint('[_confirmDelivery] onConfirm completed');
      }
    } catch (e) {
      debugPrint('[_confirmDelivery] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pengantaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ambil foto barang dan minta tanda tangan customer',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. Foto Barang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showPhotoOptions(),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (_deliveryPhoto != null || _deliveryPhotoXFile != null)
                        ? const Color(0xFF1565C0)
                        : Colors.grey[300]!,
                    width:
                        (_deliveryPhoto != null || _deliveryPhotoXFile != null)
                        ? 2
                        : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildPhotoDisplay(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Tanda Tangan Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showSignaturePad,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasSignature
                        ? const Color(0xFF1565C0)
                        : Colors.grey[300]!,
                    width: _hasSignature ? 2 : 1,
                  ),
                ),
                child: _hasSignature
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 40,
                            color: Color(0xFF1565C0),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tanda tangan diterima',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ketuk untuk minta tanda tangan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Konfirmasi Selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePad extends StatefulWidget {
  final Function(bool) onSignatureComplete;

  const SignaturePad({super.key, required this.onSignatureComplete});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke = [..._currentStroke, details.localPosition];
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _strokes.add(_currentStroke);
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _save() {
    final hasSignature = _strokes.isNotEmpty || _currentStroke.isNotEmpty;
    widget.onSignatureComplete(hasSignature);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tanda Tangan Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    TextButton(onPressed: _clear, child: const Text('Hapus')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Minta customer untuk menandatangani di atas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    if (currentStroke.length >= 2) {
      final path = Path()..moveTo(currentStroke[0].dx, currentStroke[0].dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true;
  }
}

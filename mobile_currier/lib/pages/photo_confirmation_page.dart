import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

class PhotoConfirmationPage extends StatefulWidget {
  final int orderId;
  final String title;
  final String subtitle;
  final Future<void> Function() onConfirm;

  const PhotoConfirmationPage({
    super.key,
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
  });

  @override
  State<PhotoConfirmationPage> createState() => _PhotoConfirmationPageState();
}

class _PhotoConfirmationPageState extends State<PhotoConfirmationPage> {
  File? _photo;
  XFile? _photoXFile;
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
          _photoXFile = photo;
          try {
            _photo = File(photo.path);
          } catch (e) {
            _photo = null;
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

  Widget _buildPhotoDisplay() {
    if (_photoXFile != null) {
      return Image.network(
        _photoXFile!.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image, size: 48),
      );
    }

    if (_photo != null) {
      return Image.file(_photo!, fit: BoxFit.cover);
    }

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

  Future<void> _confirm() async {
    if (_photo == null && _photoXFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan foto terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_orderId > 0) {
        final String? photoPath = _photoXFile?.path ?? _photo?.path;
        if (photoPath != null) {
          debugPrint(
            '[_confirm] Uploading photo to Supabase for order $_orderId: $photoPath',
          );

          // Upload to Supabase
          final supabaseUrl = await SupabaseService.uploadDeliveryPhoto(photoPath);

          if (supabaseUrl != null) {
            debugPrint(
              '[_confirm] Supabase upload successful: $supabaseUrl',
            );

            // Save URL to backend
            await ApiService.saveDeliveryPhotoUrl(_orderId, supabaseUrl);
          } else {
            debugPrint(
              '[_confirm] Supabase upload returned null - continuing anyway',
            );
          }
        }
      }

      await widget.onConfirm();
    } catch (e) {
      debugPrint('[_confirm] Error: $e');
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
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Foto Bukti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_photo != null || _photoXFile != null)
                        ? const Color(0xFF1565C0)
                        : Colors.grey[300]!,
                    width: (_photo != null || _photoXFile != null) ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _buildPhotoDisplay(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
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
                            'Konfirmasi',
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

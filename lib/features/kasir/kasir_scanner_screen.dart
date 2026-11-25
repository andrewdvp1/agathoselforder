import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_buttons.dart';
import '../../core/widgets/glass_container.dart';
import '../../services/order_service.dart';
import 'order_verification_sheet.dart';

class KasirScannerScreen extends StatefulWidget {
  final VoidCallback onOrderProcessed;

  const KasirScannerScreen({
    super.key,
    required this.onOrderProcessed,
  });

  @override
  State<KasirScannerScreen> createState() => _KasirScannerScreenState();
}

class _KasirScannerScreenState extends State<KasirScannerScreen> {
  final _orderService = OrderService();
  late final MobileScannerController _scannerController;

  bool _processingScan = false;
  bool _qrDetectedHighlight = false;
  bool _torchOn = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || _processingScan) return;

    setState(() {
      _processingScan = true;
      _qrDetectedHighlight = true;
    });

    try {
      final order = await _orderService.lookupOrderByQrOrCode(code);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => OrderVerificationSheet(
          initialOrder: order,
          onCompleted: widget.onOrderProcessed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _processingScan = false;
            _qrDetectedHighlight = false;
          });
        }
      }
    }
  }

  Future<void> _openManualInputDialog() async {
    final ctrl = TextEditingController();
    final submitted = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            tier: GlassTier.level3,
            borderRadius: 20,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Input Kode Pesanan Manual',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan nomor pesanan (contoh: ORD-SEED-005) atau QR token jika kamera tidak tersedia.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (v) => Navigator.of(ctx).pop(v),
                  decoration: const InputDecoration(
                    labelText: 'Order Code / QR Token',
                    hintText: 'ORD-YYYYMMDD-XXXXX',
                    prefixIcon: Icon(Icons.keyboard_alt_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GlassOutlinedButton(
                        label: 'Batal',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassPrimaryButton(
                        label: 'Cari Pesanan',
                        onPressed: () => Navigator.of(ctx).pop(ctrl.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ctrl.dispose();

    if (submitted != null && submitted.trim().isNotEmpty) {
      await _handleCode(submitted);
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash tidak tersedia pada perangkat ini.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final frameColor =
        _qrDetectedHighlight ? AppColors.secondary : AppColors.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-Bleed Camera Scanner
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (_processingScan) return;
            for (final barcode in capture.barcodes) {
              final val = barcode.rawValue;
              if (val != null && val.trim().isNotEmpty) {
                _handleCode(val);
                break;
              }
            }
          },
          errorBuilder: (context, error, _) {
            _cameraError = error.errorDetails?.message ??
                'Kamera tidak dapat diakses. Pastikan izin kamera aktif (HTTPS di Web).';
            return _CameraFallbackView(
              message: _cameraError!,
              onManualInput: _openManualInputDialog,
            );
          },
        ),

        // 2. Semi-Transparent Dark Cutout Overlay + Corner Brackets
        IgnorePointer(
          child: CustomPaint(
            painter: _ScannerOverlayPainter(bracketColor: frameColor),
            child: const SizedBox.expand(),
          ),
        ),

        // 3. Top Header Overlay
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassContainer(
                  tier: GlassTier.level2,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: frameColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pindai QR Code Pesanan',
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              _processingScan
                                  ? 'Memverifikasi data pesanan...'
                                  : 'Arahkan kamera ke QR pengunjung untuk verifikasi',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_processingScan)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 4. Floating Glass Level 2 Bottom Action Panel (Flash + Manual Order Code)
        Positioned(
          left: 20,
          right: 20,
          bottom: isMobile ? 96 : 24,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassContainer(
                tier: GlassTier.level2,
                borderRadius: 18,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (!kIsWeb) ...[
                      GlassSecondaryButton(
                        label: _torchOn ? 'Flash On' : 'Flash',
                        icon: _torchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        onPressed: _toggleTorch,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: GlassPrimaryButton(
                        label: 'Input Kode Manual',
                        icon: Icons.keyboard_alt_outlined,
                        useBrandFill: false,
                        onPressed: _openManualInputDialog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraFallbackView extends StatelessWidget {
  final String message;
  final VoidCallback onManualInput;

  const _CameraFallbackView({
    required this.message,
    required this.onManualInput,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.bgCanvas,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassContainer(
          tier: GlassTier.level2,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  size: 48, color: AppColors.tertiaryLight),
              const SizedBox(height: 12),
              Text('Kamera Tidak Aktif', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              GlassPrimaryButton(
                label: 'Masukkan Kode Pesanan Manual',
                icon: Icons.keyboard_alt_outlined,
                onPressed: onManualInput,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Color bracketColor;

  const _ScannerOverlayPainter({required this.bracketColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cutSize = (size.shortestSide * 0.62).clamp(210.0, 300.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: cutSize,
      height: cutSize,
    );

    final bgPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      bgPath,
      Paint()..color = const Color(0xA60F172A), // rgba(15,23,42,0.65)
    );

    // Draw corner brackets
    final paint = Paint()
      ..color = bracketColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + len)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + len, rect.top),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - len)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + len, rect.bottom),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.bracketColor != bracketColor;
}

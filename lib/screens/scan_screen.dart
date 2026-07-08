import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:confetti/confetti.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/theme.dart';
import '../services/supabase_service.dart';

enum ScanPhase { scan, connecting, waiting, validating, success }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  ScanPhase _phase = ScanPhase.scan;
  bool _torchEnabled = false;
  String? _binId;
  bool _showManualInput = false;

  final TextEditingController _manualCodeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  late ConfettiController _confettiController;
  Timer? _simulatedProgressTimer;

  StreamSubscription<int>? _bottleCountSubscription;
  int _currentBottleCount = 0;

  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _checkProfileAndPermissions();
  }

  Future<void> _checkProfileAndPermissions() async {
    final profileOk = await _ensureProfileExists();
    if (!profileOk) return;

    await _requestCameraPermission();
  }

  Future<bool> _ensureProfileExists() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _showError('User not authenticated');
        if (mounted) Navigator.pop(context);
        return false;
      }

      final profile = await _supabaseService.getProfile(userId);
      if (profile == null) {
        _showError(
          'Failed to create user profile. Please try logging in again.',
        );
        if (mounted) Navigator.pop(context);
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Error ensuring profile exists: $e');
      _showError('Profile error: $e');
      if (mounted) Navigator.pop(context);
      return false;
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      setState(() {
        _hasCameraPermission = true;
      });
    } else if (status.isDenied) {
      _showError('Camera permission is required to scan QR codes');
      Navigator.pop(context);
    } else if (status.isPermanentlyDenied) {
      _showError(
        'Camera permission is permanently denied. Enable it in settings.',
      );
      await openAppSettings();
    }
  }

  @override
  void dispose() {
    _simulatedProgressTimer?.cancel();
    _bottleCountSubscription?.cancel();
    _manualCodeController.dispose();
    _scannerController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _startIotProgression(String code) async {
    setState(() {
      _binId = code;
      _phase = ScanPhase.connecting;
      _currentBottleCount = 0;
    });

    if (_hasCameraPermission) {
      _scannerController.stop();
    }

    try {
      final sessionStart = DateTime.now().toUtc(); // anchor point
      await _supabaseService.startBinSession(binId: code);

      if (!mounted) return;

      setState(() {
        _phase = ScanPhase.waiting;
      });

      _listenBottleCounter(sessionStart);
    } catch (e) {
      _showError(e.toString());
      _resetScan();
    }
  }

  void _listenBottleCounter(DateTime sessionStart) {
    final userId = _supabaseService.currentUser!.id;

    _bottleCountSubscription?.cancel();

    _bottleCountSubscription = _supabaseService
        .watchBottleCountSince(userId, _binId!, sessionStart)
        .listen(
          (count) {
            if (!mounted) return;

            setState(() {
              _currentBottleCount = count;
            });
          },
          onError: (error) {
            debugPrint('Error in bottle count stream: $error');
            _showError('Stream error: $error');
          },
        );
  }

  Future<void> _finishAndClaim() async {
    setState(() {
      _phase = ScanPhase.validating;
    });

    try {
      await _supabaseService.endBinSession(
        binId: _binId!,
        bottleCount: _currentBottleCount,
      );

      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        await _supabaseService.refreshProfile(userId);
      }

      if (!mounted) return;

      _confettiController.play();

      setState(() {
        _phase = ScanPhase.success;
      });
    } catch (e) {
      _showError(e.toString());
      _resetScan();
    }
  }

  void _submitManualCode() {
    String code = _manualCodeController.text.trim();
    if (code.isEmpty) {
      code = 'BIN-UITM-01';
    }
    _manualCodeController.clear();
    setState(() {
      _showManualInput = false;
    });
    _startIotProgression(code);
  }

  void _resetScan() {
    _simulatedProgressTimer?.cancel();
    _bottleCountSubscription?.cancel();
    setState(() {
      _phase = ScanPhase.scan;
      _binId = null;
      _currentBottleCount = 0;
    });
    if (_hasCameraPermission) {
      _scannerController.start();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.destructiveColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Scanning View
          if (_phase == ScanPhase.scan && _hasCameraPermission) ...[
            MobileScanner(
              controller: _scannerController,
              fit: BoxFit.cover,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && _phase == ScanPhase.scan) {
                  final String? rawVal = barcodes.first.rawValue;
                  if (rawVal != null && rawVal.isNotEmpty) {
                    _startIotProgression(rawVal);
                  }
                }
              },
            ),

            // Scan View Overlay (Darken outer area, highlight middle square)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 240,
                      width: 240,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Highlight Corner Markers
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  children: [
                    _buildScannerCorner(
                      Alignment.topLeft,
                      rotateX: false,
                      rotateY: false,
                    ),
                    _buildScannerCorner(
                      Alignment.topRight,
                      rotateX: true,
                      rotateY: false,
                    ),
                    _buildScannerCorner(
                      Alignment.bottomLeft,
                      rotateX: false,
                      rotateY: true,
                    ),
                    _buildScannerCorner(
                      Alignment.bottomRight,
                      rotateX: true,
                      rotateY: true,
                    ),
                  ],
                ),
              ),
            ),

            // Scanning Line Animation (Static wrapper or animated offset)
            const ScanningLineEffect(),
          ],

          // 2. Simulated IoT progress panels (Connecting, Connected, Validating, Success)
          if (_phase != ScanPhase.scan)
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(gradient: AppTheme.gradientHero),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Center(child: _buildIotPanel(isDark)),
            ),

          // 3. Header controls (Back, Page title, Torch toggle)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'Scan Bottle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_phase == ScanPhase.scan && _hasCameraPermission)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _torchEnabled = !_torchEnabled;
                        });
                        _scannerController.toggleTorch();
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _torchEnabled ? LucideIcons.zapOff : LucideIcons.zap,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // 4. Bottom action prompts (during scan mode)
          if (_phase == ScanPhase.scan)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardBgDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.shadowCard,
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  '📷',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to Scan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Align the QR code on the bin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showManualInput = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.cardBgDark
                              : Colors.white,
                          foregroundColor: isDark
                              ? AppTheme.textLight
                              : AppTheme.textDark,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(LucideIcons.keyboard, size: 18),
                        label: const Text(
                          'Enter Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Manual input sheets/dialog
          if (_showManualInput)
            GestureDetector(
              onTap: () => setState(() => _showManualInput = false),
              child: Container(
                color: Colors.black54,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap bubble
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardBgDark : Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black12,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enter Bin Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textLight
                                  : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _manualCodeController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'e.g. BIN-UITM-01',
                            ),
                            onSubmitted: (_) => _submitManualCode(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _submitManualCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Connect',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 6. Celebration Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryColor,
                AppTheme.accentLime,
                AppTheme.primaryDark,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCorner(
    Alignment alignment, {
    required bool rotateX,
    required bool rotateY,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: !rotateY
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            bottom: rotateY
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            left: !rotateX
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
            right: rotateX
                ? const BorderSide(color: AppTheme.primaryColor, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIotPanel(bool isDark) {
    if (_phase == ScanPhase.success) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle2,
                color: AppTheme.primaryColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bottle Detected!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Great job! You\'ve recycled $_currentBottleCount plastic bottle${_currentBottleCount > 1 ? "s" : ""}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.shadowCard,
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${_currentBottleCount * 10} ★',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppTheme.borderLight),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CO₂ Saved',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_currentBottleCount * 0.2).toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                '♻️ Recycling one bottle saves enough energy to power a lightbulb for 3 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLime,
                foregroundColor: AppTheme.primaryDark,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Scan Another',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(LucideIcons.home, size: 16),
              label: const Text(
                'Back to Home',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // IoT connection sequence tracker
    final steps = [
      {
        'key': ScanPhase.connecting,
        'label': 'Connecting to bin…',
        'icon': LucideIcons.wifi,
      },
      {
        'key': 'connected',
        'label': 'ESP32 ${_binId ?? "BIN-UITM-01"} online',
        'icon': LucideIcons.cpu,
      },
      {
        'key': ScanPhase.waiting,
        'label': 'Waiting for ESP32...',
        'icon': LucideIcons.activity,
      },
      {
        'key': ScanPhase.validating,
        'label': 'Validating sensors…',
        'icon': LucideIcons.loader2,
      },
    ];

    String stepTitle = 'Connecting…';
    String stepDesc = 'Establishing a secure session.';
    if (_phase == ScanPhase.waiting) {
      stepTitle = 'Ready to Recycle';
      stepDesc = 'Drop your plastic bottle into the smart bin.';
    } else if (_phase == ScanPhase.validating) {
      stepTitle = 'Validating…';
      stepDesc = 'Checking weight, IR & ultrasonic sensors.';
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🍶', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            stepTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stepDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardBgDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
              boxShadow: AppTheme.shadowCard,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: steps.map((step) {
                final stepKey = step['key'];
                bool isDone = false;
                bool isActive = false;

                if (_phase == ScanPhase.connecting) {
                  isActive = stepKey == ScanPhase.connecting;
                } else if (_phase == ScanPhase.waiting) {
                  isDone =
                      stepKey == ScanPhase.connecting || stepKey == 'connected';
                  isActive = stepKey == ScanPhase.waiting;
                } else if (_phase == ScanPhase.validating) {
                  isDone =
                      stepKey == ScanPhase.connecting ||
                      stepKey == 'connected' ||
                      stepKey == ScanPhase.waiting;
                  isActive = stepKey == ScanPhase.validating;
                }

                Color iconColor = AppTheme.textMuted;
                Color bgColor = AppTheme.borderLight;
                if (isDone) {
                  iconColor = Colors.white;
                  bgColor = AppTheme.primaryColor;
                } else if (isActive) {
                  iconColor = AppTheme.primaryDark;
                  bgColor = AppTheme.accentLime;
                }

                Widget iconWidget;
                if (isDone) {
                  iconWidget = const Icon(
                    LucideIcons.checkCircle2,
                    color: Colors.white,
                    size: 14,
                  );
                } else {
                  iconWidget = Icon(
                    step['icon'] as IconData,
                    color: iconColor,
                    size: 14,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        height: 28,
                        width: 28,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: iconWidget),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isDone || isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isDark
                                ? (isDone || isActive
                                      ? Colors.white
                                      : Colors.white38)
                                : (isDone || isActive
                                      ? AppTheme.textDark
                                      : AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (_phase == ScanPhase.waiting) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardBgDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bottle Count',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$_currentBottleCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _currentBottleCount == 0 ? null : _finishAndClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Finish & Claim Points',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ScanningLineEffect extends StatefulWidget {
  const ScanningLineEffect({super.key});

  @override
  State<ScanningLineEffect> createState() => _ScanningLineEffectState();
}

class _ScanningLineEffectState extends State<ScanningLineEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -110, end: 110).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Opacity(
              opacity: (1.0 - (_animation.value.abs() / 110.0)).clamp(0.0, 1.0),
              child: Container(
                width: 220,
                height: 2,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

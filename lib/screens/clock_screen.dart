import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../services/device_monitor_service.dart';
import '../models/app_settings.dart';

class ClockScreen extends StatefulWidget {
  final DeviceMonitorService monitor;
  final AppSettings settings;
  final bool isAutoLaunch;

  const ClockScreen({
    super.key,
    required this.monitor,
    required this.settings,
    this.isAutoLaunch = false,
  });

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin {

  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _colonVisible = true;
  DeviceStatus? _status;
  StreamSubscription<DeviceStatus>? _statusSub;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _accent = Color(0xFF00FFA8);
  static const _bg = Color(0xFF0A0C10);
  static const _dim = Color(0xFF3A6E58);
  static const _dimmer = Color(0xFF1E3028);

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _applyBrightness();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _now = DateTime.now();
        _colonVisible = !_colonVisible;
      });
    });

    _statusSub = widget.monitor.statusStream.listen((status) {
      setState(() => _status = status);
      // Auto-dismiss only if this was auto-launched (not manual/preview)
      if (!status.shouldShowClock && widget.isAutoLaunch && mounted) {
        _dismiss();
      }
    });
  }

  Future<void> _applyBrightness() async {
    try {
      await ScreenBrightness().setScreenBrightness(
          widget.settings.screenBrightness);
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (_) {}
    await _fadeCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _statusSub?.cancel();
    _fadeCtrl.dispose();
    WakelockPlus.disable();
    ScreenBrightness().resetScreenBrightness().catchError((_) {});
    super.dispose();
  }

  String get _hours => widget.settings.show24h
      ? DateFormat('HH').format(_now)
      : DateFormat('hh').format(_now);

  String get _minutes => DateFormat('mm').format(_now);
  String get _seconds => DateFormat('ss').format(_now);

  String get _amPm => widget.settings.show24h
      ? ''
      : DateFormat('a').format(_now);

  String get _dateStr {
    final day = DateFormat('EEEE').format(_now).toUpperCase();
    final date = DateFormat('d MMMM yyyy').format(_now).toUpperCase();
    return '$day · $date';
  }

  int get _batteryLevel => _status?.batteryLevel ?? 0;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: _bg,
        body: GestureDetector(
          onTap: widget.isAutoLaunch ? null : _dismiss,
          child: Stack(
            children: [
              const _ScanlineOverlay(),
              // Ambient glow
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 360,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(200),
                      gradient: RadialGradient(colors: [
                        _accent.withOpacity(0.05),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              ..._buildCorners(),
              Positioned(
                  top: 0, left: 0, right: 0, child: _buildStatusBar()),
              Center(child: _buildClockFace()),
              Positioned(
                  bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
              // Accent line
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 200, height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        _accent.withOpacity(0.35),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              // Tap to dismiss hint (manual/preview only)
              if (!widget.isAutoLaunch)
                Positioned(
                  bottom: 28, left: 0, right: 0,
                  child: Center(
                    child: Text(
                      'TAP ANYWHERE TO CLOSE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        letterSpacing: 2.5,
                        color: _dimmer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _StatusPill(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 14, height: 9,
                decoration: BoxDecoration(
                  border: Border.all(color: _dim, width: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text('LANDSCAPE',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9, letterSpacing: 2, color: _dim)),
            ]),
          ),
          const Spacer(),
          _StatusPill(
            highlight: true,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bolt_rounded, size: 11, color: _accent),
              const SizedBox(width: 4),
              Text(
                'CHARGING · $_batteryLevel%',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9, letterSpacing: 1.8, color: _accent,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          _BatteryWidget(level: _batteryLevel),
        ],
      ),
    );
  }

  Widget _buildClockFace() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            _TimeSegment(_hours),
            _ColonWidget(visible: _colonVisible),
            _TimeSegment(_minutes),
            if (_amPm.isNotEmpty) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _amPm,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 20,
                    color: _dim,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.settings.showSeconds) ...[
          const SizedBox(height: 4),
          Text(
            _seconds,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              letterSpacing: 8,
              color: _accent,
            ),
          ),
        ],
        if (widget.settings.showDate) ...[
          const SizedBox(height: 12),
          Text(
            _dateStr,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 4.5,
              color: _dim,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            widget.isAutoLaunch
                ? 'AUTO-LAUNCH · DOCK MODE'
                : 'MANUAL LAUNCH',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8, letterSpacing: 2.5, color: _dimmer,
            ),
          ),
          const Spacer(),
          Text('SENSOR ACTIVE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8, letterSpacing: 2.5, color: _dimmer,
              )),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 18.0; const pad = 14.0;
    const color = Color(0xFF00FFA833); const thick = 1.5;
    return [
      Positioned(top: pad, left: pad,
          child: _Corner(size: size, color: color, thick: thick, top: true, left: true)),
      Positioned(top: pad, right: pad,
          child: _Corner(size: size, color: color, thick: thick, top: true, left: false)),
      Positioned(bottom: pad, left: pad,
          child: _Corner(size: size, color: color, thick: thick, top: false, left: true)),
      Positioned(bottom: pad, right: pad,
          child: _Corner(size: size, color: color, thick: thick, top: false, left: false)),
    ];
  }
}

// ── Sub-widgets (unchanged from before) ───────────────────────────────────

class _TimeSegment extends StatelessWidget {
  final String text;
  const _TimeSegment(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontFamily: 'monospace', fontSize: 82, fontWeight: FontWeight.w300,
    color: Color(0xFFE8F8F0), letterSpacing: 4, height: 1,
  ));
}

class _ColonWidget extends StatelessWidget {
  final bool visible;
  const _ColonWidget({required this.visible});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: AnimatedOpacity(
      opacity: visible ? 1.0 : 0.08,
      duration: const Duration(milliseconds: 200),
      child: const Text(':', style: TextStyle(
        fontFamily: 'monospace', fontSize: 82, fontWeight: FontWeight.w300,
        color: Color(0xFFE8F8F0), height: 1,
      )),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final Widget child;
  final bool highlight;
  const _StatusPill({required this.child, this.highlight = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFF00FFA8).withOpacity(0.07) : Colors.transparent,
      border: Border.all(
        color: highlight ? const Color(0xFF00FFA8).withOpacity(0.2) : const Color(0xFF1E3028),
        width: 0.5,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _BatteryWidget extends StatelessWidget {
  final int level;
  const _BatteryWidget({required this.level});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 24, height: 11,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3A6E58), width: 0.6),
          borderRadius: BorderRadius.circular(2),
        ),
        padding: const EdgeInsets.all(1.5),
        child: FractionallySizedBox(
          widthFactor: (level / 100).clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00FFA8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
      Container(
        width: 3, height: 5,
        margin: const EdgeInsets.only(left: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF3A6E58),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ],
  );
}

class _Corner extends StatelessWidget {
  final double size, thick;
  final Color color;
  final bool top, left;
  const _Corner({required this.size, required this.color, required this.thick,
    required this.top, required this.left});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _CornerPainter(
        color: color, thick: thick, top: top, left: left)),
  );
}

class _CornerPainter extends CustomPainter {
  final Color color; final double thick; final bool top, left;
  _CornerPainter({required this.color, required this.thick,
    required this.top, required this.left});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = thick
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.square;
    final w = size.width; final h = size.height;
    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, 0), p);
      canvas.drawLine(Offset(0, 0), Offset(w, 0), p);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), p);
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
    } else {
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
      canvas.drawLine(Offset(w, h), Offset(0, h), p);
    }
  }
  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();
  @override
  Widget build(BuildContext context) =>
      Positioned.fill(child: CustomPaint(painter: _ScanlinePainter()));
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF00FFB0).withOpacity(0.013)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

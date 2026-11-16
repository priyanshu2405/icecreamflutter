import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

class FrameStyle {
  final String name;
  final Color color;
  final Color pill;
  final Color? tint;
  final bool sprinkles;
  const FrameStyle(
    this.name,
    this.color,
    this.pill, {
    this.tint,
    this.sprinkles = false,
  });
}

const frames = [
  FrameStyle('Drip', C.pink, C.pink),
  FrameStyle('Classic', C.cream, C.pink),
  FrameStyle('Sprinkles', C.yellow, C.pink, sprinkles: true),
  FrameStyle('Midnight', C.ink, C.pink, tint: Color(0x33000000)),
  FrameStyle('Birthday', Color(0xFF9AD8FF), C.pink, sprinkles: true),
];

/// A photo taken in the booth. Front-camera shots are mirrored so the
/// result looks the same as the live preview did.
class BoothShot {
  final String path;
  final bool mirrored;
  const BoothShot(this.path, {this.mirrored = false});
}

/// The Lick It frame drawn over [child]: the live camera on the booth screen,
/// or the captured photo on the share screen.
class BoothFrame extends StatelessWidget {
  final FrameStyle style;
  final double scale;
  final double radius;
  final Widget? child;
  const BoothFrame({
    super.key,
    required this.style,
    this.child,
    this.scale = 1,
    this.radius = 26,
  });

  /// The captured photo, filling the frame.
  static Widget photo(BoothShot shot) => Transform.flip(
    flipX: shot.mirrored,
    child: Image.file(File(shot.path), fit: BoxFit.cover, gaplessPlayback: true),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius * scale),
      child: Stack(
        fit: StackFit.expand,
        children: [
          child ?? const ColoredBox(color: Color(0xFF2A2023)),
          if (style.tint != null) Container(color: style.tint),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: style.color, width: 12 * scale),
              borderRadius: BorderRadius.circular(radius * scale),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70 * scale,
            child: CustomPaint(painter: _DripPainter(style.color)),
          ),
          if (style.sprinkles)
            Positioned.fill(
              child: CustomPaint(painter: _SprinklePainter(scale)),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26 * scale,
            child: Column(
              children: [
                Text(
                  'Love at First Lick.',
                  style: script(
                    30 * scale,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: C.deep,
                        offset: Offset(0, 2 * scale),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: Colors.black38,
                        offset: Offset(0, 3 * scale),
                        blurRadius: 8 * scale,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: style.pill,
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Text(
                    'LICK IT · ${app.storeShort.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fred(
                      12 * scale,
                      color: Colors.white,
                      spacing: 1.5 * scale,
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
}

class _DripPainter extends CustomPainter {
  final Color color;
  _DripPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(0, 0);
    p.lineTo(0, s.height * 0.45);
    const drips = [0.55, 0.3, 0.8, 0.4, 0.95, 0.35, 0.6, 0.3];
    final step = s.width / drips.length;
    for (var i = 0; i < drips.length; i++) {
      final x0 = i * step;
      final depth = s.height * drips[i];
      p.quadraticBezierTo(
        x0 + step * 0.1,
        s.height * 0.3,
        x0 + step * 0.3,
        s.height * 0.35,
      );
      p.lineTo(x0 + step * 0.3, depth - step * 0.2);
      p.arcToPoint(
        Offset(x0 + step * 0.7, depth - step * 0.2),
        radius: Radius.circular(step * 0.2),
        clockwise: false,
      );
      p.lineTo(x0 + step * 0.7, s.height * 0.35);
      p.quadraticBezierTo(
        x0 + step * 0.9,
        s.height * 0.3,
        x0 + step,
        s.height * 0.4,
      );
    }
    p.lineTo(s.width, 0);
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DripPainter old) => old.color != color;
}

class _SprinklePainter extends CustomPainter {
  final double scale;
  _SprinklePainter(this.scale);

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    const colors = [C.pink, Colors.white, Color(0xFF8FD3FF), C.yellow, C.deep];
    for (var i = 0; i < 46; i++) {
      final edge = rnd.nextInt(4);
      final along = rnd.nextDouble();
      final inset = rnd.nextDouble() * 34 * scale;
      final o = switch (edge) {
        0 => Offset(along * s.width, 70 * scale + inset),
        1 => Offset(s.width - inset, along * s.height),
        2 => Offset(along * s.width, s.height - inset),
        _ => Offset(inset, along * s.height),
      };
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 12 * scale,
            height: 4 * scale,
          ),
          Radius.circular(2 * scale),
        ),
        Paint()..color = colors[i % colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ---------------------------------------------------------------------------
// A15 Photo booth: live camera inside the frame
// ---------------------------------------------------------------------------

class PhotoBoothScreen extends StatefulWidget {
  const PhotoBoothScreen({super.key});

  @override
  State<PhotoBoothScreen> createState() => _PhotoBoothScreenState();
}

class _PhotoBoothScreenState extends State<PhotoBoothScreen> with WidgetsBindingObserver {
  int _frame = 0;
  bool _strip = false; // PHOTO or STRIP ×4
  bool _timer = false;
  bool _flash = false;
  int? _count;
  String? _progress; // "2 / 4" while a strip is being taken
  bool _flashOverlay = false;
  bool _busy = false;

  List<CameraDescription> _cameras = const [];
  CameraController? _cam;
  bool _front = true;
  String? _camError;
  List<BoothShot>? _last; // last shots this session (thumbnail bottom-left)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cam?.dispose();
    super.dispose();
  }

  // The camera must be released when the app goes to the background and
  // re-opened when it comes back (required on both Android and iOS).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _cam;
    if (state == AppLifecycleState.inactive) {
      _cam = null;
      cam?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && cam == null) {
      _startCamera();
    }
  }

  CameraDescription? _pick() {
    final want = _front ? CameraLensDirection.front : CameraLensDirection.back;
    for (final c in _cameras) {
      if (c.lensDirection == want) return c;
    }
    return _cameras.isEmpty ? null : _cameras.first;
  }

  Future<void> _startCamera() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      final desc = _pick();
      if (desc == null) {
        setState(() => _camError = 'No camera found on this device.');
        return;
      }
      _front = desc.lensDirection == CameraLensDirection.front;
      final cam = CameraController(desc, ResolutionPreset.high, enableAudio: false);
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      final old = _cam;
      setState(() {
        _cam = cam;
        _camError = null;
      });
      await old?.dispose();
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('AccessDenied') || e.code.contains('AccessRestricted') || e.code.contains('Permission');
      setState(
        () => _camError = denied
            ? 'Lick It needs your camera for the Photo Booth. Allow camera access for Lick It in your phone Settings, then come back.'
            : "The camera couldn't start (${e.description ?? e.code}).",
      );
    }
  }

  Future<void> _flip() async {
    if (_busy || _cameras.length < 2) return;
    final old = _cam;
    setState(() {
      _front = !_front;
      _cam = null;
    });
    await old?.dispose();
    await _startCamera();
  }

  Future<BoothShot?> _takeOne() async {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) return null;
    if (_timer) {
      for (var i = 3; i > 0; i--) {
        setState(() => _count = i);
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return null;
      }
      setState(() => _count = null);
    }
    try {
      await cam.setFlashMode(_flash ? FlashMode.always : FlashMode.off);
    } on CameraException {
      // Front cameras usually have no flash; carry on without it.
    }
    final file = await cam.takePicture();
    if (!mounted) return null;
    setState(() => _flashOverlay = true);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (mounted) setState(() => _flashOverlay = false);
    return BoothShot(file.path, mirrored: _front);
  }

  Future<void> _shoot() async {
    if (_busy) return;
    if (_cam == null) {
      toast(context, _camError ?? 'The camera is starting…');
      return;
    }
    setState(() => _busy = true);
    try {
      final shots = <BoothShot>[];
      final n = _strip ? 4 : 1;
      for (var i = 0; i < n; i++) {
        if (n > 1) setState(() => _progress = '${i + 1} / $n');
        final s = await _takeOne();
        if (s == null) return;
        shots.add(s);
        if (i < n - 1) await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
      }
      _last = shots;
      if (!mounted) return;
      push(context, PhotoShareScreen(style: frames[_frame], shots: shots));
    } on CameraException catch (e) {
      if (mounted) toast(context, "Couldn't take the photo (${e.description ?? e.code})");
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _count = null;
          _progress = null;
        });
      }
    }
  }

  Widget _live() {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) {
      return ColoredBox(
        color: const Color(0xFF2A2023),
        child: Center(
          child: _camError == null
              ? const CircularProgressIndicator(color: Colors.white)
              : Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _camError!,
                        textAlign: TextAlign.center,
                        style: dm(14.5, color: Colors.white, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Btn('Try again', expand: false, height: 44, fontSize: 15, onTap: _startCamera),
                    ],
                  ),
                ),
        ),
      );
    }
    // Fill the frame with the preview (the preview's aspect ratio is long side / short side).
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 100,
        height: 100 * cam.value.aspectRatio,
        child: CameraPreview(cam),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final last = _last;
    return Scaffold(
      backgroundColor: const Color(0xFF15100F),
      body: Column(
        children: [
          Container(height: top, color: frames[_frame].color),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: BoothFrame(style: frames[_frame], child: _live()),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 12,
                  child: _roundIcon(
                    Icons.close_rounded,
                    () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _timer = !_timer),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _timer ? C.yellow : Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '3s',
                            style: dm(14, color: _timer ? C.ink : Colors.white, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _roundIcon(
                        _flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        () => setState(() => _flash = !_flash),
                        active: _flash,
                      ),
                    ],
                  ),
                ),
                if (_progress != null)
                  Positioned(
                    top: 66,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Text(_progress!, style: dm(14, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                if (_count != null)
                  Center(
                    child: Text('$_count', style: fred(120, color: Colors.white, height: 1)),
                  ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flashOverlay ? 1 : 0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: frames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final sel = i == _frame;
                return GestureDetector(
                  onTap: () => setState(() => _frame = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: frames[i].color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sel ? Colors.white : Colors.white24,
                            width: sel ? 3 : 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        frames[i].name,
                        style: dm(12, color: sel ? Colors.white : Colors.white60, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Your last shot this session: tap to share it again.
                GestureDetector(
                  onTap: last == null
                      ? null
                      : () => push(context, PhotoShareScreen(style: frames[_frame], shots: last)),
                  child: Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: last == null ? Colors.white24 : Colors.white, width: 2),
                    ),
                    child: last == null
                        ? const Icon(Icons.photo_outlined, color: Colors.white38)
                        : BoothFrame.photo(last.first),
                  ),
                ),
                GestureDetector(
                  onTap: _shoot,
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _busy ? C.deep : C.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _cameras.length < 2 ? 0.35 : 1,
                  child: _roundIcon(Icons.flip_camera_ios_outlined, _flip, size: 52),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final strip in [false, true])
                GestureDetector(
                  onTap: _busy ? null : () => setState(() => _strip = strip),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      strip ? 'STRIP ×4' : 'PHOTO',
                      style: dm(
                        13.5,
                        color: _strip == strip ? C.pink : Colors.white54,
                        weight: FontWeight.w700,
                        spacing: 0.8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10 + bottom),
        ],
      ),
    );
  }

  Widget _roundIcon(
    IconData i,
    VoidCallback onTap, {
    bool active = false,
    double size = 44,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? C.yellow : Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Icon(i, color: active ? C.ink : Colors.white, size: size * 0.5),
    ),
  );
}

// ---------------------------------------------------------------------------
// A16 Photo share: points are earned only after the photo is really shared
// ---------------------------------------------------------------------------

class PhotoShareScreen extends StatefulWidget {
  final FrameStyle style;
  final List<BoothShot> shots; // 1 photo, or 4 for a strip
  const PhotoShareScreen({super.key, required this.style, required this.shots});

  @override
  State<PhotoShareScreen> createState() => _PhotoShareScreenState();
}

class _PhotoShareScreenState extends State<PhotoShareScreen> {
  final _card = GlobalKey();
  final _shareBtn = GlobalKey();
  bool _sharing = false;

  /// iOS share-sheet actions that keep the photo on the phone instead of
  /// sharing it. These never earn points.
  static const _notAShare = [
    'SaveToCameraRoll',
    'CopyToPasteboard',
    'Print',
    'AssignToContact',
    'SaveToFiles',
    'MarkupAsPDF',
    'AddToReadingList',
  ];

  /// The framed photo exactly as shown on screen, as a PNG.
  Future<XFile> _render() async {
    final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return XFile.fromData(
      data!.buffer.asUint8List(),
      mimeType: 'image/png',
      name: 'lick-it-photo-${DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = await _render();
      // iPad needs to know where to anchor the share popover.
      final box = _shareBtn.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      final result = await Share.shareXFiles(
        [file],
        text: 'Love at First Lick 🍦 #LickItLove',
        sharePositionOrigin: origin,
      );
      if (!mounted) return;

      final shared = result.status == ShareResultStatus.success && !_notAShare.any(result.raw.contains);
      if (!shared) {
        toast(
          context,
          result.status == ShareResultStatus.success
              ? 'Saved. Share it to an app to earn ${Rules.photoPoints} pts.'
              : 'Not shared yet. Share it to earn ${Rules.photoPoints} pts.',
        );
        return;
      }
      if (!Api.hasToken) {
        toast(context, 'Shared! Sign in next time to earn points for sharing.');
        return;
      }
      final earned = await Repo.sharePhoto();
      if (!mounted) return;
      if (earned > 0) app.sharedPhoto = true;
      toast(context, earned > 0 ? 'Shared · +$earned pts earned!' : 'Shared! Thanks for spreading the love.');
      setState(() {});
    } catch (_) {
      if (mounted) toast(context, "Couldn't open sharing. Please try again.");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = math.min(w * 0.76, 320.0);
    final shots = widget.shots;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Retake', style: dm(16, weight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text('Looking sweet!', textAlign: TextAlign.center, style: fred(20)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text('Done', style: dm(16, color: C.deep, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  Center(
                    child: Transform.rotate(
                      angle: 0.03,
                      // Everything inside the boundary is what gets shared.
                      child: RepaintBoundary(
                        key: _card,
                        child: Container(
                          width: cardW,
                          padding: EdgeInsets.fromLTRB(cardW * 0.05, cardW * 0.05, cardW * 0.05, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (shots.length > 1)
                                SizedBox(
                                  height: cardW * 1.08,
                                  child: GridView.count(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 6,
                                    crossAxisSpacing: 6,
                                    childAspectRatio: 0.82,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      for (final s in shots.take(4))
                                        BoothFrame(
                                          style: widget.style,
                                          scale: 0.32,
                                          radius: 10,
                                          child: BoothFrame.photo(s),
                                        ),
                                    ],
                                  ),
                                )
                              else
                                AspectRatio(
                                  aspectRatio: 0.82,
                                  child: BoothFrame(
                                    style: widget.style,
                                    scale: cardW / 400,
                                    radius: 4,
                                    child: BoothFrame.photo(shots.first),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text('Love at First Lick.', style: script(20, color: C.deep)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: C.yellow, shape: BoxShape.circle),
                          child: Text(app.sharedPhoto ? '✓' : '+${Rules.photoPoints}', style: fred(17)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: dm(14, color: Colors.white, height: 1.35),
                              children: [
                                const TextSpan(text: 'Share with '),
                                TextSpan(
                                  text: '#LickItLove',
                                  style: dm(14, color: Colors.white, weight: FontWeight.w700, height: 1.35),
                                ),
                                TextSpan(
                                  text: app.sharedPhoto
                                      ? '. Your sharing points are in your account.'
                                      : ' to earn ${Rules.photoPoints} points on your first share. Points are added once the photo is shared.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Btn(
                    _sharing ? 'Opening…' : 'Share photo',
                    key: _shareBtn,
                    icon: Icons.ios_share_rounded,
                    onTap: _sharing ? null : _share,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pick Instagram, TikTok, WhatsApp, Facebook or any app on your phone.',
                    textAlign: TextAlign.center,
                    style: dm(13, color: C.grey, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

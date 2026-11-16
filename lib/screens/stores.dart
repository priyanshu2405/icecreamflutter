import 'dart:async';

import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// A13 Stores
// ---------------------------------------------------------------------------

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: h * 0.5,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: MapPainter()),
                  ),
                  Positioned(
                    left: c.maxWidth * 0.62 - 60,
                    top: c.maxHeight * 0.52 - 60,
                    child: Blob(120, C.pink.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    left: c.maxWidth * 0.62 - 26,
                    top: c.maxHeight * 0.52 - 52,
                    child: const MapPin(size: 52),
                  ),
                  Positioned(
                    left: c.maxWidth * 0.3,
                    top: c.maxHeight * 0.72,
                    child: Container(
                      width: 30,
                      height: 30,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: C.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 10,
            child: Row(
              children: [
                const CircleBtn(),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: C.grey),
                        const SizedBox(width: 10),
                        Text('Surrey, BC', style: dm(16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.56,
            maxChildSize: 0.9,
            builder: (context, scroll) => Container(
              decoration: const BoxDecoration(
                color: C.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: C.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: Text('Nearby stores', style: fred(22))),
                      Text('1 open', style: dm(13, color: C.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C.deep, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 130,
                          child: Image.asset(
                            'assets/images/store.jpg',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'City Parkway',
                                      style: fred(20),
                                    ),
                                  ),
                                  Text(
                                    '0.4 km',
                                    style: dm(15, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  style: dm(13.5, color: C.grey),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'Unit #5, 10302 City Pkwy, Surrey · ',
                                    ),
                                    TextSpan(
                                      text: 'Open now',
                                      style: dm(
                                        13.5,
                                        color: C.green,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final t in [
                                    'Pickup',
                                    'Delivery',
                                    'Dine-in',
                                    'Photo booth',
                                  ])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: C.blush,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        t,
                                        style: dm(
                                          12.5,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Open today 12:00 pm – 11:00 pm',
                                style: dm(13, color: C.grey),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Btn(
                                      'Order here',
                                      height: 50,
                                      fontSize: 16,
                                      onTap: () {
                                        app.setMode(Mode.pickup);
                                        app.setTab(1);
                                        Navigator.of(context)
                                            .popUntil((r) => r.isFirst);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Btn(
                                      'Directions',
                                      style: BtnStyle.outline,
                                      height: 50,
                                      fontSize: 16,
                                      onTap: () => toast(
                                        context,
                                        'Opens Maps with directions in the full app',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Dashed(
                    color: const Color(0xFFD8C6CD),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: dm(13.5, height: 1.4),
                                children: [
                                  TextSpan(
                                    text: 'More Lick It stores coming soon. ',
                                    style: dm(
                                      13.5,
                                      weight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "Turn on alerts and we'll tell you when one opens near you.",
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ListenableBuilder(
                            listenable: app,
                            builder: (context, _) => PinkSwitch(
                              value: app.storeAlerts,
                              onChanged: (v) {
                                app.storeAlerts = v;
                                app.savePrefs();
                                if (v) {
                                  toast(
                                    context,
                                    "We'll let you know when a new store opens",
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A14 Geo promo (lock-screen notification demo)
// ---------------------------------------------------------------------------

class GeoPromoScreen extends StatefulWidget {
  const GeoPromoScreen({super.key});

  @override
  State<GeoPromoScreen> createState() => _GeoPromoScreenState();
}

class _GeoPromoScreenState extends State<GeoPromoScreen> {
  late Timer _t;
  DateTime _now = DateTime.now();
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _show = true);
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF3A1F2B),
      body: Stack(
        children: [
          Positioned(
            right: -size.width * 0.3,
            top: size.height * 0.15,
            child: Blob(size.width, const Color(0xFF5A2A40)),
          ),
          Positioned(
            left: -size.width * 0.4,
            bottom: -size.width * 0.3,
            child: Blob(size.width * 1.1, const Color(0xFF4A2234)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                        Text(
                          '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}',
                          style: dm(18, color: Colors.white70),
                        ),
                        Text(
                          '$h:${_now.minute.toString().padLeft(2, '0')}',
                          style: fred(86, color: Colors.white, height: 1.1),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSlide(
                          offset: _show ? Offset.zero : const Offset(0, -0.4),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _show ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: _notif(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _appRow('Tue'),
                              const SizedBox(height: 8),
                              Text(
                                'Your points are about to melt',
                                style: dm(15, weight: FontWeight.w700),
                              ),
                              Text(
                                "${app.points} pts: you're ${(500 - app.points).clamp(0, 500)} away from a free scoop.",
                                style: dm(14),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How it\'s triggered',
                                style: fred(17, color: const Color(0xFFFF7DB4)),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final t in [
                                    'Geofence 300 m',
                                    'Store open',
                                    'Max 1 alert / day',
                                    'Set in admin',
                                  ])
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        t,
                                        style: dm(
                                          13,
                                          color: Colors.white,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appRow(String when) => Row(
    children: [
      const Logo(size: 26, shadow: false),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'LICK IT',
          style: dm(13, weight: FontWeight.w500, spacing: 0.5),
        ),
      ),
      Text(when, style: dm(12.5, color: C.grey)),
    ],
  );

  Widget _notif(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _appRow('now'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're 200 m from Lick It",
                      style: dm(16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: dm(14, height: 1.35),
                        children: [
                          const TextSpan(text: 'Swing by for '),
                          TextSpan(
                            text: '10% off all shakes',
                            style: dm(
                              14,
                              weight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          const TextSpan(
                            text: ' for the next hour. Biscoff Golden Hour is calling.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FoodTile(
                color: const Color(0xFFFFF0C2),
                size: 60,
                icon: Icons.local_drink_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Btn(
                  'Order ahead',
                  height: 42,
                  fontSize: 15,
                  onTap: () {
                    app.applyDeal();
                    app.openMenu('Shakes');
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Btn(
                  'Directions',
                  style: BtnStyle.blush,
                  height: 42,
                  fontSize: 15,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const StoresScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

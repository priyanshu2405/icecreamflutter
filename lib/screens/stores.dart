
import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'catering.dart';

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
                        Text(
                          stores.first.city.isEmpty ? 'Lick It stores' : '${stores.first.city}, BC',
                          style: dm(16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const CartButton(),
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
                      Text(
                        '${stores.length} ${stores.length == 1 ? 'store' : 'stores'}',
                        style: dm(13, color: C.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < stores.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _StoreCard(store: stores[i], highlight: i == 0),
                  ],
                  const SizedBox(height: 12),
                  const CateringCard(),
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
                  if (Biz.instagram.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    CardBox(
                      color: C.blush,
                      border: C.blush,
                      onTap: () => openLink(context, Uri.parse('https://instagram.com/${Biz.instagram}')),
                      child: Row(
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: C.deep),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: dm(14),
                                children: [
                                  TextSpan(text: 'Tag us. Get featured. ', style: dm(14, weight: FontWeight.w700)),
                                  TextSpan(text: 'Follow @${Biz.instagram}'),
                                ],
                              ),
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 18, color: C.grey),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One store from the admin: photo, address, hours, services, and buttons.
class _StoreCard extends StatelessWidget {
  final StoreInfo store;
  final bool highlight;
  const _StoreCard({required this.store, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final phone = store.phone.isNotEmpty ? store.phone : Biz.phone;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: highlight ? C.deep : C.line, width: highlight ? 2 : 1.2),
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
                Text(store.name, style: fred(20)),
                const SizedBox(height: 2),
                Text(store.address, style: dm(13.5, color: C.grey, height: 1.35)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in [
                      'Pickup',
                      if (store.offersDelivery) 'Delivery',
                      'Dine-in',
                      'Photo booth',
                    ])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: C.blush,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(t, style: dm(12.5, weight: FontWeight.w700)),
                      ),
                  ],
                ),
                if (store.hours.isNotEmpty || phone.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (store.hours.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16, color: C.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(store.hours, style: dm(13, color: C.grey))),
                      ],
                    ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => openLink(context, telLink(phone)),
                      child: Row(
                        children: [
                          const Icon(Icons.call_outlined, size: 16, color: C.deep),
                          const SizedBox(width: 6),
                          Text(phone, style: dm(13, color: C.deep, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Btn(
                        'Order here',
                        height: 50,
                        fontSize: 16,
                        onTap: () {
                          app.storeId = store.id;
                          app.setMode(Mode.pickup);
                          app.setTab(1);
                          Navigator.of(context).popUntil((r) => r.isFirst);
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
                        onTap: () => openLink(context, directionsTo(store)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

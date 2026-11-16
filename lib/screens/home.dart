import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'flavour_finder.dart';
import 'tracking.dart';
import 'photo_booth.dart';
import 'product.dart';
import 'stores.dart';

// ---------------------------------------------------------------------------
// A04 Home (pickup) / A04b Home (delivery)
// ---------------------------------------------------------------------------

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final top = MediaQuery.of(context).padding.top;
        final delivery = app.mode == Mode.delivery;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: top + 226,
                    child: Container(
                      color: C.pink,
                      child: Stack(
                        children: [
                          Positioned(
                            right: -70,
                            top: -50,
                            child: Blob(
                              230,
                              Colors.white.withValues(alpha: 0.13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, top + 14, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${greeting()}, ${app.firstName}',
                                    style: dm(15, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "What's the craving?",
                                      style: fred(26, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => app.setTab(2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: C.yellow,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${app.points} pts',
                                      style: dm(14, weight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ModeToggle(delivery: delivery),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => delivery
                              ? showAddressSheet(context)
                              : push(context, const StoresScreen()),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  delivery
                                      ? 'Deliver to ${app.addressLine} · 30–40 min'
                                      : 'Pickup · City Pkwy, Surrey · open now',
                                  overflow: TextOverflow.ellipsis,
                                  style: dm(14, color: Colors.white),
                                ),
                              ),
                              const Icon(
                                Icons.expand_more_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _NearbyBanner(),
                      ],
                    ),
                  ),
                ],
              ),
              if (app.active != null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ActiveOrderStrip(order: app.active!),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return GestureDetector(
                      onTap: () => app.openMenu(c),
                      child: Column(
                        children: [
                          FoodTile(
                            color: categoryTile[c]!,
                            size: 74,
                            radius: 20,
                            icon: categoryIcon[c],
                          ),
                          const SizedBox(height: 8),
                          Text(c, style: dm(13, weight: FontWeight.w700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text('Picked for you', style: fred(20))),
                    GestureDetector(
                      onTap: () => push(context, const FlavourFinderScreen()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: C.ink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: dm(
                                12,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 176,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _PickCard(
                      item: itemById('signature'),
                      tag: 'You love chocolate',
                    ),
                    _PickCard(
                      item: itemById('pista'),
                      tag: 'New',
                      tile: const Color(0xFFE2F0D9),
                    ),
                    _PickCard(
                      item: itemById('goldenhour'),
                      tag: '10% off nearby',
                    ),
                    _PickCard(item: itemById('mango'), tag: 'Ordered before'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CardBox(
                  color: C.blush,
                  border: C.blush,
                  onTap: () => push(context, const PhotoBoothScreen()),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: C.deep,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lick It Photo Booth', style: fred(17)),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                style: dm(14, color: C.ink),
                                children: [
                                  const TextSpan(
                                    text: 'Snap your treat with our frames, share it, earn ',
                                  ),
                                  TextSpan(
                                    text: '25 pts',
                                    style: dm(14, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool delivery;
  const _ModeToggle({required this.delivery});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool sel, Mode m) => Expanded(
      child: GestureDetector(
        onTap: () => app.setMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: dm(
              16,
              weight: FontWeight.w700,
              color: sel ? C.deep : Colors.white,
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          seg('Pickup', !delivery, Mode.pickup),
          seg('Delivery', delivery, Mode.delivery),
        ],
      ),
    );
  }
}

class _NearbyBanner extends StatelessWidget {
  const _NearbyBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.ink,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: Colors.black38,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          app.applyDeal();
          app.openMenu('Shakes');
          toast(context, '10% off shakes applied for the next 58 min');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: C.yellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined, color: C.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "You're nearby! ",
                        style: dm(
                          14.5,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '10% off all shakes for the next 58 min',
                        style: dm(14.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                app.dealApplied ? 'On ✓' : 'Use',
                style: dm(15, color: C.pink, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final MenuItem item;
  final String tag;
  final Color? tile;
  const _PickCard({required this.item, required this.tag, this.tile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 168,
        child: CardBox(
          padding: EdgeInsets.zero,
          onTap: () => push(context, ProductScreen(item: item)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: tile ?? item.tile,
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tag, style: dm(11.5, weight: FontWeight.w700)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dm(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.singular} · ${money(item.price)}',
                      style: dm(13, color: C.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAddressSheet(BuildContext context) {
  final ctrl = TextEditingController(text: app.address);
  showSheet(
    context,
    title: 'Deliver to',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Where should we bring your order?',
          style: dm(14.5, color: C.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Street address, city · apartment / buzzer',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: C.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: C.line),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Btn(
          'Save address',
          onTap: () async {
            final v = ctrl.text.trim();
            if (v.isEmpty) {
              toast(context, 'Please type your address first');
              return;
            }
            try {
              await Repo.saveAddress(v);
              if (context.mounted) Navigator.pop(context);
            } on ApiException catch (e) {
              if (context.mounted) toast(context, e.message);
            }
          },
        ),
      ],
    ),
  );
}

class ActiveOrderStrip extends StatelessWidget {
  final ActiveOrder order;
  const ActiveOrderStrip({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final ready = order.stage == 2;
    return Material(
      color: C.pink,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openTracking(context, order),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: C.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.deep, width: 3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.number} · ${order.mode == Mode.delivery ? 'On the way' : (ready ? 'Ready now' : 'Making it now')}',
                      style: fred(17, color: Colors.white),
                    ),
                    Text(
                      order.mode == Mode.delivery
                          ? 'Delivery · arriving soon'
                          : (ready
                                ? 'Pickup · at the counter'
                                : 'Pickup · ready ~7 min'),
                      style: dm(13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Text(
                'Track',
                style: dm(15, color: Colors.white, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

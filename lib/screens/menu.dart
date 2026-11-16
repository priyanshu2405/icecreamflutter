import 'package:flutter/material.dart';

import '../data.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'build_your_own.dart';
import 'cart.dart';
import 'product.dart';

// ---------------------------------------------------------------------------
// A05 Menu
// ---------------------------------------------------------------------------

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final cat = app.menuCategory;
        final items = _q.isEmpty
            ? menu.where((m) => m.category == cat).toList()
            : menu
                  .where(
                    (m) =>
                        m.name.toLowerCase().contains(_q) ||
                        m.desc.toLowerCase().contains(_q) ||
                        m.category.toLowerCase().contains(_q),
                  )
                  .toList();
        // Build-your-own lives under Waffles, like the website (Menu / Waffles / Build your own).
        final showIce = _q.isEmpty && cat.toLowerCase() == 'ice cream' && scoopFlavours.isNotEmpty;
        final showByo = _q.isEmpty
            ? cat.toLowerCase() == 'waffles'
            : 'build your own waffle'.contains(_q) || _q.contains('build');
        final modeLabel = switch (app.mode) {
          Mode.pickup => 'Pickup · ${app.storeShort}',
          Mode.delivery => 'Delivery · Home',
          Mode.dineIn => 'Dine-in · ${app.storeShort}',
        };
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                    child: Row(
                      children: [
                        Expanded(child: Text('Menu', style: fred(30))),
                        GestureDetector(
                          onTap: () => app.setMode(
                            app.mode == Mode.pickup
                                ? Mode.delivery
                                : Mode.pickup,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: C.blush,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              modeLabel,
                              style: dm(
                                13.5,
                                color: C.deep,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!Repo.catalogLoaded) const _OfflineMenuNotice(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) =>
                          setState(() => _q = v.trim().toLowerCase()),
                      style: dm(16),
                      decoration: InputDecoration(
                        hintText: 'Search waffles, flavours, drinks',
                        hintStyle: dm(16, color: C.grey),
                        prefixIcon: const Icon(Icons.search, color: C.grey),
                        suffixIcon: _q.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close, color: C.grey),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _q = '');
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: C.line,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: C.deep, width: 2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => PillChip(
                        categories[i],
                        selected: _q.isEmpty && categories[i] == cat,
                        fontSize: 15,
                        onTap: () {
                          if (_q.isNotEmpty) {
                            _search.clear();
                            setState(() => _q = '');
                          }
                          app.setCategory(categories[i]);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_q.isEmpty ? cat : 'Results', style: fred(22)),
                        const Spacer(),
                        Text(
                          _q.isEmpty
                              ? categoryBlurb[cat]!
                              : '${items.length} found',
                          style: dm(13, color: C.grey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty && !showByo && !showIce
                        ? Center(
                            child: Text(
                              'No treats match "$_q" yet',
                              style: dm(15, color: C.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              app.cartCount > 0 ? 100 : 20,
                            ),
                            itemCount: items.length + (showByo || showIce ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              if (showByo || showIce) {
                                if (i == 0) return showByo ? const ByoBanner() : const _TodaysFlavours();
                                return MenuRow(item: items[i - 1]);
                              }
                              return MenuRow(item: items[i]);
                            },
                          ),
                  ),
                ],
              ),
              if (app.cartCount > 0)
                Positioned(left: 16, right: 16, bottom: 12, child: CartBar()),
            ],
          ),
        );
      },
    );
  }
}

/// "In the case today": every active flavour, grouped like the website menu.
class _TodaysFlavours extends StatefulWidget {
  const _TodaysFlavours();

  @override
  State<_TodaysFlavours> createState() => _TodaysFlavoursState();
}

class _TodaysFlavoursState extends State<_TodaysFlavours> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Flavour>>{};
    for (final f in scoopFlavours) {
      groups.putIfAbsent(f.group, () => []).add(f);
    }
    return CardBox(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: C.blush, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.icecream_outlined, color: C.deep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In the case today', style: fred(17)),
                        Text(
                          '${scoopFlavours.length} flavours · selection rotates',
                          style: dm(13, color: C.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: C.grey),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final g in groups.entries) ...[
                    const SizedBox(height: 8),
                    Text(
                      g.key.toUpperCase(),
                      style: dm(12, color: C.deep, weight: FontWeight.w700, spacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final f in g.value)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: C.cream,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: f.dot, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(f.name, style: dm(13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Please tell our team about allergies. Flavours and toppings are subject to availability.',
                    style: dm(12, color: C.grey, height: 1.35),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown when the live menu couldn't be loaded and the built-in sample menu
/// is on screen instead.
class _OfflineMenuNotice extends StatefulWidget {
  const _OfflineMenuNotice();

  @override
  State<_OfflineMenuNotice> createState() => _OfflineMenuNoticeState();
}

class _OfflineMenuNoticeState extends State<_OfflineMenuNotice> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    await Repo.bootstrap();
    if (!mounted) return;
    setState(() => _busy = false);
    app.touch();
    if (!Repo.catalogLoaded) toast(context, "Still can't reach Lick It. Check your internet connection.");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: CardBox(
        color: C.blush,
        border: C.blush,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: C.deep, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Couldn't load the full menu, so you're seeing a sample.",
                style: dm(13.5, height: 1.3),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _retry,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: C.deep))
                  : Text('Retry', style: dm(14, color: C.deep, weight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  final MenuItem item;
  const MenuRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final deal = item.isShake && app.dealApplied;
    return CardBox(
      padding: const EdgeInsets.all(12),
      onTap: () => push(context, ProductScreen(item: item)),
      child: Row(
        children: [
          FoodTile(color: item.tile, size: 78, icon: item.icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: dm(16, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  item.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: dm(13, color: C.grey, height: 1.3),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      money(app.unitFor(item, 0, 0)),
                      style: dm(15, weight: FontWeight.w700),
                    ),
                    if (deal) ...[
                      const SizedBox(width: 6),
                      Text(
                        money(item.price),
                        style: dm(
                          13,
                          color: C.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '-10%',
                        style: dm(12, color: C.deep, weight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: C.deep,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                app.add(item);
                toast(
                  context,
                  'Added ${item.name}',
                  action: 'View cart',
                  onAction: () => push(context, const CartScreen()),
                );
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.ink,
      borderRadius: BorderRadius.circular(22),
      elevation: 8,
      shadowColor: Colors.black45,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => push(context, const CartScreen()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.deep,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${app.cartCount}',
                  style: dm(15, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'View cart',
                  style: dm(16, color: Colors.white, weight: FontWeight.w700),
                ),
              ),
              Text(
                money(app.subtotal),
                style: dm(16, color: Colors.white, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

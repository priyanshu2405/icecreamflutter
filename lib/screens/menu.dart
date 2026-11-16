import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
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
        final modeLabel = switch (app.mode) {
          Mode.pickup => 'Pickup · City Pkwy',
          Mode.delivery => 'Delivery · Home',
          Mode.dineIn => 'Dine-in · City Pkwy',
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
                    child: items.isEmpty
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
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => MenuRow(item: items[i]),
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

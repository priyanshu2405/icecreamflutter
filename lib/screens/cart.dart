import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart' show showAddressSheet;
import 'stores.dart';
import 'tracking.dart';

// ---------------------------------------------------------------------------
// A07 Cart (pickup) / A07b Cart (delivery)
// ---------------------------------------------------------------------------

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  /// A Featured menu item (Admin > Menu items > Featured) that can go straight in the cart.
  MenuItem? _upsell() {
    for (final m in menu) {
      if (m.featured && !m.isIceCream && !app.inCart(m.id) && !byoItems.any((b) => b.id == m.id)) return m;
    }
    return null;
  }

  ScheduledTime? _scheduled;

  Future<void> _schedule() async {
    final days = scheduleDays;
    if (days == null) {
      // older server: any time
      final now = TimeOfDay.now();
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
        helpText: 'Schedule for later',
      );
      if (t == null || !mounted) return;
      final n = DateTime.now();
      var at = DateTime(n.year, n.month, n.day, t.hour, t.minute);
      if (at.isBefore(n)) at = at.add(const Duration(days: 1));
      setState(() => _scheduled = ScheduledTime(t.format(context), at: at));
      return;
    }
    final picked = await showSlotPicker(context, days, _scheduled?.slot);
    if (picked != null && mounted) setState(() => _scheduled = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final mode = app.mode;
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const ScreenHeader('Your cart', cart: false),
                Expanded(
                  child: app.cart.isEmpty
                      ? _empty(context)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          children: [
                            _ModeSegment(mode: mode),
                            const SizedBox(height: 12),
                            _whereCard(context, mode),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PillChip(
                                  switch (mode) {
                                    Mode.pickup => 'ASAP · ready ~15 min',
                                    Mode.delivery => 'ASAP · 30–40 min',
                                    Mode.dineIn => 'ASAP · to your table',
                                  },
                                  selected: _scheduled == null,
                                  fontSize: 13.5,
                                  onTap: () =>
                                      setState(() => _scheduled = null),
                                ),
                                if (scheduleDays == null || scheduleDays!.isNotEmpty)
                                  PillChip(
                                    _scheduled == null
                                        ? 'Schedule for later'
                                        : 'Scheduled · ${_scheduled!.label}',
                                    selected: _scheduled != null,
                                    fontSize: 13.5,
                                    onTap: _schedule,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            for (final l in app.cart) ...[
                              _CartLineCard(line: l),
                              const SizedBox(height: 12),
                            ],
                            // "Add a …?" suggestion: a Featured item from the admin that isn't in the cart yet.
                            if (_upsell() case final up?)
                              Material(
                                color: C.blush,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () {
                                    app.add(up);
                                    toast(context, 'Added ${up.name}');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        FoodTile(
                                          color: up.tile,
                                          size: 44,
                                          radius: 12,
                                          icon: up.icon,
                                          imageUrl: up.art,
                                          photo: up.hasPhoto,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              style: dm(14.5),
                                              children: [
                                                const TextSpan(text: 'Add a '),
                                                TextSpan(text: up.name, style: dm(14.5, weight: FontWeight.w700)),
                                                const TextSpan(text: '?'),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '+ ${money(up.price)}',
                                          style: dm(15, color: C.deep, weight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row2('Subtotal', money(app.subtotal)),
                            if (mode == Mode.delivery)
                              Row2('Delivery fee', money(app.deliveryFee)),
                            Row2(
                              "Points you'll earn",
                              '+${app.earnBeforePoints} pts',
                              style: dm(
                                15,
                                color: C.green,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
                if (app.cart.isNotEmpty)
                  _BottomBar(
                    child: Btn(
                      'Go to checkout',
                      trailing: money(app.subtotal + app.deliveryFee),
                      onTap: () =>
                          push(context, CheckoutScreen(scheduled: _scheduled)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: C.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.icecream_outlined, size: 52, color: C.deep),
          ),
          const SizedBox(height: 18),
          Text('Your cart is empty', style: fred(24)),
          const SizedBox(height: 6),
          Text(
            'Every great day starts with a scoop.',
            style: dm(15, color: C.grey),
          ),
          const SizedBox(height: 22),
          Btn(
            'Browse the menu',
            expand: false,
            onTap: () {
              app.setTab(1);
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    ),
  );

  Widget _whereCard(BuildContext context, Mode mode) {
    final (title, sub) = switch (mode) {
      Mode.pickup => (
        'Pickup at ${app.storeShort}',
        app.store.address,
      ),
      Mode.delivery => (
        'Deliver to Home',
        app.addressLine,
      ),
      Mode.dineIn => ('Dine-in at ${app.storeShort}', 'Table 7 · we\'ll bring it over'),
    };
    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: C.blush,
              shape: BoxShape.circle,
            ),
            child: Icon(
              mode == Mode.dineIn
                  ? Icons.table_restaurant_outlined
                  : Icons.location_on_outlined,
              color: C.deep,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: dm(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(sub, style: dm(13, color: C.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (mode == Mode.delivery) {
                showAddressSheet(context);
              } else if (mode == Mode.pickup) {
                push(context, const StoresScreen());
              } else {
                toast(context, 'Scan the QR on your table to change it');
              }
            },
            child: Text(
              'Change',
              style: dm(15, color: C.deep, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final Mode mode;
  const _ModeSegment({required this.mode});

  @override
  Widget build(BuildContext context) {
    Widget seg(Mode m, String t, String s) {
      final sel = m == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => app.setMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? C.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  t,
                  style: dm(
                    15,
                    weight: FontWeight.w700,
                    color: sel ? Colors.white : C.ink,
                  ),
                ),
                Text(s, style: dm(11.5, color: sel ? Colors.white70 : C.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line, width: 1.2),
      ),
      child: Row(
        children: [
          // Same choices as the website checkout (Delivery only when it's on in the admin).
          seg(Mode.pickup, 'Pickup', '~15 min'),
          if (Rules.deliveryEnabled) seg(Mode.delivery, 'Delivery', '30–40 min'),
        ],
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  final CartLine line;
  const _CartLineCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          FoodTile(color: line.item.tile, size: 70, icon: line.item.icon, imageUrl: line.item.art, photo: line.item.hasPhoto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.name, style: dm(16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  app.lineSubtitle(line),
                  maxLines: line.note == null ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: dm(12.5, color: C.grey, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  money(app.lineTotal(line)),
                  style: dm(15, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          QtyStepper(
            qty: line.qty,
            onMinus: () => app.changeQty(line, -1),
            onPlus: () => app.changeQty(line, 1),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: C.line)),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// A08 Checkout
// ---------------------------------------------------------------------------

/// The same four choices as the website checkout.
enum PayMethod { counter, wallet, card, split }

/// A "schedule for later" choice: a server slot, or (older servers) any time.
class ScheduledTime {
  final String label;
  final String? slot;
  final DateTime? at;
  const ScheduledTime(this.label, {this.slot, this.at});
}

/// Day tabs and time slots from the server, same as the website's checkout.
Future<ScheduledTime?> showSlotPicker(BuildContext context, List<ScheduleDay> days, String? current) {
  var day = 0;
  for (var i = 0; i < days.length; i++) {
    if (days[i].slots.any((s) => s.value == current)) day = i;
  }
  return showModalBottomSheet<ScheduledTime>(
    context: context,
    backgroundColor: C.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Schedule for later', style: fred(22)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      PillChip(days[i].label, selected: day == i, onTap: () => set(() => day = i)),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in days[day].slots)
                          PillChip(
                            s.label,
                            selected: s.value == current,
                            fontSize: 13.5,
                            onTap: () => Navigator.pop(
                              ctx,
                              ScheduledTime(
                                days[day].label == 'Today' ? s.label : '${days[day].label} ${s.label}',
                                slot: s.value,
                              ),
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
      ),
    ),
  );
}

class CheckoutScreen extends StatefulWidget {
  final ScheduledTime? scheduled;
  const CheckoutScreen({super.key, this.scheduled});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Points choices in whole-dollar steps at the admin's point value (\$1, \$2, \$4 off).
  static List<int> get _ptsSteps => [0, pointsPerDollar, pointsPerDollar * 2, pointsPerDollar * 4];
  static String _pct(double rate) {
    final v = rate * 100;
    return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  }

  // Points can't be worth more than the order (the server refuses that).
  static bool _ptsFit(int p) => p * Rules.pointValue <= app.subtotal + app.deliveryFee + 0.001;
  late int _pts = app.points >= _ptsSteps[2] && _ptsFit(_ptsSteps[2]) ? _ptsSteps[2] : 0;
  PayMethod _pay = PayMethod.counter; // pay at pickup / on delivery, like the website

  String _summary(BuildContext context) {
    final when = widget.scheduled == null
        ? switch (app.mode) {
            Mode.pickup => 'ASAP (~15 min)',
            Mode.delivery => 'ASAP (30–40 min)',
            Mode.dineIn => 'ASAP',
          }
        : widget.scheduled!.label;
    return switch (app.mode) {
      Mode.pickup => 'Pickup · ${app.storeShort} · $when',
      Mode.delivery => 'Delivery · Home · $when',
      Mode.dineIn => 'Dine-in · Table 7 · $when',
    };
  }

  // Availability rules copied from the website checkout.
  bool get _signedIn => Api.hasToken;
  bool get _online => Rules.onlinePayments;
  bool _walletOk(double total) => _signedIn && app.wallet + 0.001 >= total;
  bool _splitOk(double total) => _signedIn && _online && app.wallet > 0.005 && app.wallet + 0.001 < total;

  /// The choice actually used: falls back to paying at the counter if the
  /// picked option stopped applying (e.g. points made the total change).
  PayMethod _effective(double total) => switch (_pay) {
    PayMethod.wallet when _walletOk(total) => PayMethod.wallet,
    PayMethod.split when _splitOk(total) => PayMethod.split,
    PayMethod.card when _online => PayMethod.card,
    _ => PayMethod.counter,
  };

  Future<void> _place() async {
    // Same checks as the website, taken from Admin > Settings.
    if (!Rules.orderingEnabled) {
      toast(context, 'Online ordering is paused right now.');
      return;
    }
    if (Rules.minOrder > 0 && app.subtotal + 0.001 < Rules.minOrder) {
      toast(context, 'The minimum order is ${money(Rules.minOrder)}. Add ${money(Rules.minOrder - app.subtotal)} more.');
      return;
    }
    final total = app.total(_pts);
    final pay = _effective(total);
    await runPayment(
      context,
      ptsUsed: _pts,
      walletUsed: switch (pay) {
        PayMethod.wallet => total,
        PayMethod.split => round2(app.wallet),
        _ => 0,
      },
      payAtStore: pay == PayMethod.counter,
      scheduledFor: widget.scheduled?.at,
      scheduledSlot: widget.scheduled?.slot,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = app.total(_pts);
    final pay = _effective(total);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader('Checkout', cart: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                children: [
                  CardBox(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _summary(context),
                            style: dm(14.5, weight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Edit',
                            style: dm(
                              15,
                              color: C.blue,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.ink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Use your points',
                                style: fred(19, color: Colors.white),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: C.yellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${app.points} pts',
                                style: dm(13.5, weight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final p in _ptsSteps) ...[
                              if (p != 0) const SizedBox(width: 8),
                              Expanded(child: _ptsTile(p)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$pointsPerDollar points = ${money(1)} off · you'll still earn ${total.floor()} pts",
                          style: dm(12.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Notes for the kitchen', style: fred(19)),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: app.orderNotes,
                    onChanged: (v) => app.orderNotes = v,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    style: dm(15.5),
                    decoration: InputDecoration(
                      hintText: 'Optional, e.g. extra napkins please',
                      hintStyle: dm(15, color: C.grey),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: C.line, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: C.deep, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Pay with', style: fred(19)),
                  const SizedBox(height: 10),
                  CardBox(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _payRow(
                          pay,
                          PayMethod.counter,
                          Icons.storefront_outlined,
                          app.mode == Mode.delivery ? 'Pay on delivery' : 'Pay at pickup',
                          'Card or cash at the counter',
                          enabled: true,
                        ),
                        const Divider(height: 1, color: C.line),
                        _payRow(
                          pay,
                          PayMethod.wallet,
                          Icons.account_balance_wallet_outlined,
                          'Lick It Wallet',
                          _signedIn ? '${money(app.wallet)} balance' : 'Sign in to use',
                          enabled: _walletOk(total),
                          why: !_signedIn
                              ? 'Sign in to use your wallet.'
                              : (app.wallet > 0.005 && _online
                                    ? "Your wallet doesn't cover the whole order. Choose 'Wallet + pay the rest online'."
                                    : 'Your wallet balance is too low for this order.'),
                        ),
                        const Divider(height: 1, color: C.line),
                        _payRow(
                          pay,
                          PayMethod.card,
                          Icons.credit_card_rounded,
                          'Pay online by card',
                          _online ? 'Credit or debit card' : 'Coming soon',
                          enabled: _online,
                          why: 'Online card payment is coming soon.',
                        ),
                        if (_signedIn && _online) ...[
                          const Divider(height: 1, color: C.line),
                          _payRow(
                            pay,
                            PayMethod.split,
                            Icons.call_split_rounded,
                            'Wallet + pay the rest online',
                            app.wallet > 0.005
                                ? (app.wallet + 0.001 >= total
                                      ? 'Your wallet already covers this order'
                                      : '${money(app.wallet)} from wallet · ${money(total - app.wallet)} online')
                                : 'Add money to your wallet first',
                            enabled: _splitOk(total),
                            why: app.wallet + 0.001 >= total
                                ? 'Your wallet covers the whole order. Choose Lick It Wallet.'
                                : 'Add money to your wallet first.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row2('Subtotal', money(app.subtotal)),
                  if (app.mode == Mode.delivery)
                    Row2('Delivery fee', money(app.deliveryFee)),
                  if (_pts > 0)
                    Row2(
                      'Points ($_pts)',
                      '−${money(_pts * Rules.pointValue)}',
                      rightStyle: dm(
                        15,
                        color: C.green,
                        weight: FontWeight.w700,
                      ),
                    ),
                  Row2('GST (${_pct(Rules.gstRate)}%)', money(app.gst(_pts))),
                ],
              ),
            ),
            _BottomBar(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Total', style: fred(20))),
                      Text(money(total), style: fred(26)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Btn('Place order', onTap: _place),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ptsTile(int p) {
    final sel = _pts == p;
    final enabled = p <= app.points && _ptsFit(p);
    return GestureDetector(
      onTap: enabled
          ? () => setState(() => _pts = p)
          : () => toast(context, p > app.points ? 'You need $p pts for this' : 'That is more than this order costs'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFF7DB4) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? const Color(0xFFFF7DB4) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Column(
            children: [
              Text(
                p == 0 ? 'None' : '$p',
                style: dm(
                  15,
                  color: sel ? C.ink : Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                p == 0 ? money(0) : '−${money(p * Rules.pointValue)}',
                style: dm(11.5, color: sel ? C.ink : Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payRow(
    PayMethod current,
    PayMethod m,
    IconData icon,
    String title,
    String sub, {
    required bool enabled,
    String? why,
  }) {
    final on = current == m;
    return Material(
      color: on ? C.blush : (enabled ? Colors.white : const Color(0xFFF6F1F3)),
      child: InkWell(
        onTap: () {
          if (!enabled) {
            toast(context, why ?? 'That option is not available for this order.');
            return;
          }
          setState(() => _pay = m);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Row(
              children: [
                Icon(icon, color: C.deep),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: dm(15.5, weight: FontWeight.w700)),
                      Text(sub, style: dm(12.5, color: C.grey)),
                    ],
                  ),
                ),
                RadioDot(on),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a short "processing" dialog, places the order and opens tracking.
Future<void> runPayment(
  BuildContext context, {
  required int ptsUsed,
  double walletUsed = 0,
  DateTime? scheduledFor,
  String? scheduledSlot,
  bool payAtStore = false,
}) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(color: C.deep, strokeWidth: 4),
            ),
            const SizedBox(height: 18),
            Text('Placing your order…', style: fred(19)),
            const SizedBox(height: 4),
            Text(
              'Sending it to the kitchen',
              style: dm(13.5, color: C.grey),
            ),
          ],
        ),
      ),
    ),
  );
  final ActiveOrder order;
  try {
    order = await Repo.placeOrder(
      ptsUsed: ptsUsed,
      walletUsed: walletUsed,
      scheduledFor: scheduledFor,
      scheduledSlot: scheduledSlot,
      payAtStore: payAtStore,
    );
  } on ApiException catch (e) {
    nav.pop(); // close dialog
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }
  nav.pop(); // close dialog
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => TrackingScreen(order: order)),
    (r) => r.isFirst,
  );
}

import 'package:flutter/material.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';
import 'flavour_finder.dart';
import 'home.dart' show showAddressSheet;
import 'orders.dart';
import 'rewards.dart';
import 'splash.dart';
import 'stores.dart';

// ---------------------------------------------------------------------------
// A19 Profile
// ---------------------------------------------------------------------------

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: C.deep,
                    shape: BoxShape.circle,
                  ),
                  child: Text('PS', style: fred(24, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName, style: fred(24)),
                      Text(
                        'Scoop tier · member since 2026',
                        style: dm(14, color: C.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('${app.points}', 'Points', C.deep, () => app.setTab(2)),
                const SizedBox(width: 8),
                _stat(
                  '\$${app.wallet.toStringAsFixed(app.wallet % 1 == 0 ? 0 : 2)}',
                  'Wallet',
                  C.ink,
                  () => push(context, const WalletScreen()),
                ),
                const SizedBox(width: 8),
                _stat(
                  '${app.ordersCount}',
                  'Orders',
                  C.ink,
                  () => push(context, const OrdersScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CardBox(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row(
                    'O',
                    'Orders & reorder',
                    null,
                    () => push(context, const OrdersScreen()),
                  ),
                  _row(
                    'AI',
                    'Flavour Finder',
                    'New',
                    () => push(context, const FlavourFinderScreen()),
                  ),
                  _row(
                    '\$',
                    'Payment methods',
                    'Visa •• 4821',
                    () => _payments(context),
                  ),
                  _row(
                    'A',
                    'Saved addresses',
                    'Home',
                    () => showAddressSheet(context),
                  ),
                  _row(
                    'S',
                    'Favourite store',
                    'City Pkwy',
                    () => push(context, const StoresScreen()),
                  ),
                  _row(
                    'G',
                    'Gift cards',
                    null,
                    () => push(context, const WalletScreen()),
                  ),
                  _row(
                    '?',
                    'Help & allergen info',
                    null,
                    () => _allergens(context),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  _toggle('Nearby offers (GPS)', app.gpsOffers, (v) {
                    app.gpsOffers = v;
                    app.savePrefs();
                  }),
                  const Divider(height: 1, color: C.line),
                  _toggle('Order & reward alerts', app.orderAlerts, (v) {
                    app.orderAlerts = v;
                    app.savePrefs();
                  }),
                  const Divider(height: 1, color: C.line),
                  _toggle('Email news & offers', app.emailNews, (v) {
                    app.emailNews = v;
                    app.savePrefs();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'PROTOTYPE DEMOS',
              style: dm(
                12,
                color: C.grey,
                weight: FontWeight.w700,
                spacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            CardBox(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _row(
                    '🔔',
                    'Nearby offer notification',
                    'Lock screen',
                    () => push(context, const GeoPromoScreen()),
                  ),
                  _row('↩', 'Sign out', null, () async {
                    await Repo.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (_) => false,
                    );
                  }),
                  _row('🗑', 'Delete my account', 'Permanent', () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete your account?'),
                        content: const Text(
                          'Your points, wallet balance and saved details will be removed. This cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    try {
                      await Repo.deleteAccount();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (_) => false,
                      );
                    } on ApiException catch (e) {
                      if (context.mounted) toast(context, e.message);
                    }
                  }, last: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Lick It · v1.0',
                style: dm(12, color: C.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String big, String label, Color color, VoidCallback onTap) =>
      Expanded(
        child: CardBox(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(big, style: fred(22, color: color)),
              Text(label, style: dm(13, color: C.grey)),
            ],
          ),
        ),
      );

  Widget _row(
    String badge,
    String title,
    String? trailing,
    VoidCallback onTap, {
    bool last = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.blush,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: dm(14, color: C.deep, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: dm(16))),
                if (trailing != null)
                  Text(trailing, style: dm(13.5, color: C.grey)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: C.grey),
              ],
            ),
          ),
        ),
        if (!last) const Divider(height: 1, color: C.line, indent: 14),
      ],
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: dm(15.5))),
            PinkSwitch(value: value, onChanged: onChanged),
          ],
        ),
      );

  void _payments(BuildContext context) {
    showSheet(
      context,
      title: 'Payment methods',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardBox(
            border: C.deep,
            borderWidth: 2,
            child: Row(
              children: [
                const MiniBadge('VISA', Color(0xFF1A1F71)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Visa •• 4821 · default',
                    style: dm(15, weight: FontWeight.w700),
                  ),
                ),
                Text('08/29', style: dm(13, color: C.grey)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CardBox(
            child: Row(
              children: [
                const MiniBadge('LICK', C.pink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lick It Wallet',
                    style: dm(15, weight: FontWeight.w700),
                  ),
                ),
                Text(money(app.wallet), style: dm(13, color: C.grey)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Btn(
            'Add a card',
            style: BtnStyle.outline,
            icon: Icons.add,
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Secure card entry opens here in the full app');
            },
          ),
        ],
      ),
    );
  }

  void _allergens(BuildContext context) {
    showSheet(
      context,
      title: 'Help & allergen info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All items are made in a kitchen that handles milk, eggs, wheat, soy, peanuts and tree nuts. '
            'Pistachio, Rocky Road and Pista Kunafa contain nuts. Ask our team about dairy-free sorbet options.',
            style: dm(15, color: C.grey, height: 1.45),
          ),
          const SizedBox(height: 16),
          Btn(
            'Chat with us',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {
              Navigator.pop(context);
              toast(context, 'Support chat opens here');
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../data.dart';
import '../screens/rewards.dart' show Reward, rewards;
import '../theme.dart';
import 'api_client.dart';

/// Everything that talks to the backend and then updates the app-wide state
/// ([app], [menu], [rewards] ...). Screens call these instead of mutating
/// numbers locally, so the server is always the source of truth.
class Repo {
  static bool catalogLoaded = false;
  static List<Map<String, dynamic>> _packs = [];

  // ----------------------------------------------------------------- helpers
  static Color _hex(String? s, [Color fallback = const Color(0xFFFCE1EC)]) {
    if (s == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s)) return fallback;
    return Color(int.parse('FF${s.substring(1)}', radix: 16));
  }

  static IconData _icon(String? key) => switch (key) {
    'grid' => Icons.grid_on_rounded,
    'snow' => Icons.ac_unit_rounded,
    'drink' => Icons.local_drink_outlined,
    'coffee' => Icons.coffee_outlined,
    'cake' => Icons.cake_outlined,
    _ => Icons.icecream_outlined,
  };

  static Mode _mode(String? m) => switch (m) {
    'delivery' => Mode.delivery,
    'dine_in' => Mode.dineIn,
    _ => Mode.pickup,
  };

  static String _modeApi(Mode m) => switch (m) {
    Mode.delivery => 'delivery',
    Mode.dineIn => 'dine_in',
    Mode.pickup => 'pickup',
  };

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static String _dateLabel(DateTime d) {
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) return 'Today';
    return '${_months[d.month - 1]} ${d.day}';
  }

  // ----------------------------------------------------------------- catalog
  /// Loads the menu, flavours, rewards and pricing rules. If the server can't
  /// be reached the bundled defaults in data.dart stay in place.
  static Future<void> bootstrap() async {
    try {
      final j = await Api.get('/bootstrap');
      _applyCatalog(j['data'] as Map<String, dynamic>);
      catalogLoaded = true;
      _loadedAt = DateTime.now();
    } catch (_) {
      // keep the offline fallback menu
    }
  }

  static DateTime? _loadedAt;
  static Future<void>? _refreshing;

  /// Re-reads the menu, categories, flavours, prices and settings so anything
  /// changed in the website admin shows up without reinstalling or restarting.
  /// Called when the app comes back to the foreground, on tab changes and on
  /// pull-to-refresh. Skipped if the last load was under 30 seconds ago
  /// (unless [force]); a refresh already running is reused.
  static Future<void> refresh({bool force = false}) {
    final last = _loadedAt;
    if (!force && last != null && DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return Future.value();
    }
    return _refreshing ??= () async {
      try {
        await bootstrap();
        // Points / wallet changed by staff (Admin > Customers) show up too.
        if (Api.hasToken) {
          try {
            final j = await Api.get('/me');
            applyUser(j['data'] as Map<String, dynamic>);
          } catch (_) {}
        }
        // Delivery switched off in the admin while the app was open.
        if (app.mode == Mode.delivery && !Rules.deliveryEnabled) app.mode = Mode.pickup;
        app.touch();
      } finally {
        _refreshing = null;
      }
    }();
  }

  static void _applyCatalog(Map<String, dynamic> d) {
    Rules.apply(d['settings'] as Map<String, dynamic>);

    final cats = (d['categories'] as List).cast<Map<String, dynamic>>();
    if (cats.isNotEmpty) {
      categories = [for (final c in cats) c['name'] as String];
      categorySlug = {for (final c in cats) c['name'] as String: (c['slug'] ?? '') as String};
      categoryImage = {
        for (final c in cats)
          if (c['image_url'] is String && (c['image_url'] as String).isNotEmpty) c['name'] as String: c['image_url'] as String,
      };
      categoryBlurb = {for (final c in cats) c['name'] as String: (c['blurb'] ?? '') as String};
      categoryTile = {for (final c in cats) c['name'] as String: _hex(c['tile_color'] as String?)};
      categoryIcon = {for (final c in cats) c['name'] as String: _icon(c['icon'] as String?)};
      if (!categories.contains(app.menuCategory)) app.menuCategory = categories.first;
    }
    final bySlug = {for (final c in cats) c['slug'] as String: c};

    final products = (d['products'] as List).cast<Map<String, dynamic>>();
    if (products.isNotEmpty) {
      menu = [
        for (final p in products)
          if (bySlug[p['category']] != null)
            MenuItem(
              id: p['slug'] as String,
              name: p['name'] as String,
              desc: (p['description'] ?? '') as String,
              category: bySlug[p['category']]!['name'] as String,
              categorySlug: p['category'] as String,
              price: (p['price'] as num).toDouble(),
              tile: _hex(p['tile_color'] as String?),
              icon: _icon(bySlug[p['category']]!['icon'] as String?),
              tag: p['tag'] as String?,
              imageUrl: p['image_url'] as String?,
              shakeFlag: bySlug[p['category']]!['is_shake'] as bool,
              scoopFlag: bySlug[p['category']]!['takes_scoops'] as bool,
              featured: p['is_featured'] as bool? ?? false,
            ),
      ];
    }

    final fl = (d['flavours'] as List).cast<Map<String, dynamic>>();
    if (fl.isNotEmpty) {
      scoopFlavours = [
        for (final f in fl)
          Flavour(
            f['name'] as String,
            _hex(f['dot_color'] as String?, C.pink),
            (f['group'] ?? 'Flavours') as String,
            ((f['groups'] as List?) ?? const []).cast<String>(),
          ),
      ];
      flavourGroups = ((d['flavour_groups'] as List?) ?? const []).cast<String>();
    }
    final tp = (d['toppings'] as List).cast<String>();
    if (tp.isNotEmpty) toppingOptions = List<String>.of(tp);

    final st = (d['stores'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (st.isNotEmpty) {
      stores = [
        for (final s in st)
          StoreInfo(
            id: (s['id'] as num?)?.toInt(),
            name: (s['name'] ?? 'Lick It') as String,
            address: (s['address'] ?? '') as String,
            city: (s['city'] ?? '') as String,
            hours: StoreInfo.clean(s['hours'] as String?),
            phone: StoreInfo.clean(s['phone'] as String?),
            lat: (s['latitude'] as num?)?.toDouble(),
            lng: (s['longitude'] as num?)?.toDouble(),
            offersDelivery: s['offers_delivery'] as bool? ?? true,
          ),
      ];
    }
    final settings = d['settings'] as Map<String, dynamic>;
    Biz.phone = StoreInfo.clean(settings['business_phone'] as String?);
    Biz.instagram = StoreInfo.clean(settings['instagram_handle'] as String?).replaceFirst('@', '');
    if (Biz.instagram.isEmpty) Biz.instagram = 'lickit'; // same fallback as the website

    // Pickup / delivery time slots.
    if (d.containsKey('schedule')) {
      final sc = d['schedule'] as Map<String, dynamic>?;
      scheduleDays = [
        for (final day in ((sc?['days'] as List?) ?? const []).cast<Map<String, dynamic>>())
          ScheduleDay(day['label'] as String, [
            for (final s in (day['slots'] as List).cast<Map<String, dynamic>>())
              ScheduleSlot(s['v'] as String, s['label'] as String),
          ]),
      ];
    }

    // Per-item add-on prices (blank in the admin = default price).
    final pr = d['prices'] is Map<String, dynamic> ? d['prices'] as Map<String, dynamic> : null;
    // PHP sends an empty map as [] — treat anything that isn't a map as "no prices".
    Map<String, double> nums(dynamic m) => {
      if (m is Map)
        for (final e in m.entries)
          if (e.value is num) e.key as String: (e.value as num).toDouble(),
    };
    if (pr != null) {
      Rules.scoopPrices = nums(pr['scoops']);
      Rules.toppingPrices = nums(pr['toppings']);
      Rules.drizzlePrices = nums(pr['drizzles']);
    }

    // Build your own: bases and drizzles from Admin > Build your own.
    final byo = d['byo'];
    if (byo is Map<String, dynamic>) {
      final bases = (byo['bases'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (bases.isNotEmpty) {
        byoBases = [
          for (final b in bases)
            ByoBase(
              b['name'] as String,
              _hex(b['color'] as String?, const Color(0xFFC9852F)),
              (b['slug'] ?? 'build-your-own') as String,
              (b['price'] as num).toDouble(),
            ),
        ];
      }
      final dz = (byo['drizzles'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (dz.isNotEmpty) {
        byoDrizzles = [for (final x in dz) Flavour(x['name'] as String, _hex(x['color'] as String?, C.deep))];
        Rules.drizzlePrices = {
          ...Rules.drizzlePrices,
          for (final x in dz) x['name'] as String: ((x['price'] ?? 0) as num).toDouble(),
        };
      }
    } else {
      // Older server: the base prices come from the website's pricing settings.
      byoBases = [
        for (final b in byoBases)
          ByoBase(b.name, b.color, b.slug, b.slug == 'build-your-own' ? Rules.byoBase : Rules.byoBase + Rules.byoUpcharge),
      ];
    }

    const tiles = [Color(0xFFF1E6D6), Color(0xFFFCE1EC), Color(0xFFFFF0C2), Color(0xFFE2F0D9)];
    final rw = (d['rewards'] as List).cast<Map<String, dynamic>>();
    rewards = [
      for (var i = 0; i < rw.length; i++)
        Reward(rw[i]['name'] as String, rw[i]['points_cost'] as int, tiles[i % tiles.length], rw[i]['id'] as int),
    ];

    _packs = (d['wallet_packs'] as List).cast<Map<String, dynamic>>();
    if (_packs.isNotEmpty) {
      app.packAmounts = [for (final p in _packs) (p['amount'] as num).round()];
      app.packBonus = {for (final p in _packs) (p['amount'] as num).round(): p['bonus_points'] as int};
    }
    app.touch();
  }

  // ----------------------------------------------------------------- session
  static void applyUser(Map<String, dynamic> u) {
    app.fullName = (u['name'] as String?) ?? 'Friend';
    app.firstName = (u['first_name'] as String?) ?? app.fullName;
    app.points = (u['points'] as num).toInt();
    app.wallet = (u['wallet_balance'] as num).toDouble();
    app.ordersCount = (u['orders_count'] as num?)?.toInt() ?? 0;
    app.address = (u['address'] as String?) ?? '';
    app.phone = (u['phone'] as String?) ?? '';
    app.email = (u['email'] as String?) ?? '';
    final p = (u['preferences'] as Map?) ?? {};
    app.gpsOffers = p['gps_offers'] as bool? ?? true;
    app.orderAlerts = p['order_alerts'] as bool? ?? true;
    app.emailNews = p['email_news'] as bool? ?? false;
    app.storeAlerts = p['store_alerts'] as bool? ?? false;
    app.touch();
  }

  /// Returns true when a saved login is still valid.
  static Future<bool> restoreSession() async {
    if (!Api.hasToken) return false;
    try {
      final j = await Api.get('/me');
      applyUser(j['data'] as Map<String, dynamic>);
      await _loadAccountData();
      return true;
    } on ApiException catch (e) {
      if (e.status == 401) return false;
      return false;
    }
  }

  /// Catering, cakes & parties request (same form as the website's Locations page).
  static Future<String> sendCatering({
    required String name,
    required String phone,
    String? eventType,
    DateTime? date,
    int? guests,
    String? interestedIn,
    String? message,
  }) async {
    final msg = [
      if (interestedIn != null) 'Interested in: $interestedIn',
      if (message != null && message.trim().isNotEmpty) message.trim(),
    ].join('\n');
    final j = await Api.post('/catering-enquiries', {
      'name': name,
      'phone': phone,
      if (eventType != null) 'event_type': eventType,
      if (date != null)
        'event_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (guests != null) 'guests': guests,
      if (msg.isNotEmpty) 'message': msg,
    });
    return (j['message'] ?? 'Thanks! We will be in touch shortly.') as String;
  }

  static Future<void> requestCode(String identifier) async {
    await Api.post('/auth/otp/request', {'identifier': identifier});
  }

  /// Same check as the website's sign-in form: is this a new customer, and is
  /// an email still needed? (Older servers without this check: assume a new
  /// customer, and ask phone sign-ups for an email.)
  static Future<({bool exists, bool needsEmail})> checkIdentifier(String identifier) async {
    try {
      final j = await Api.post('/auth/check', {'identifier': identifier});
      final d = j['data'] as Map<String, dynamic>;
      return (exists: d['exists'] == true, needsEmail: d['needs_email'] == true);
    } catch (_) {
      return (exists: false, needsEmail: !identifier.contains('@'));
    }
  }

  static Future<void> verifyCode(String identifier, String code, {String? name, String? email}) async {
    final j = await Api.post('/auth/otp/verify', {
      'identifier': identifier,
      'code': code,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
    });
    final d = j['data'] as Map<String, dynamic>;
    await Api.saveToken(d['token'] as String);
    applyUser(d['user'] as Map<String, dynamic>);
    await _loadAccountData();
  }

  static Future<void> signOut() async {
    try {
      await Api.post('/auth/logout');
    } catch (_) {}
    await Api.saveToken(null);
    app.resetSession();
  }

  static Future<void> deleteAccount() async {
    await Api.delete('/me');
    await Api.saveToken(null);
    app.resetSession();
  }

  static Future<void> _loadAccountData() async {
    await Future.wait([loadOrders(), loadFavourites(), loadHistory()]);
  }

  /// Points and wallet history (same data as the website's Rewards page).
  static Future<void> loadHistory() async {
    try {
      final r = (await Api.get('/rewards'))['data'] as Map<String, dynamic>;
      app.pointsHistory = [
        for (final a in ((r['activity'] as List?) ?? const []).cast<Map<String, dynamic>>())
          HistoryLine(DateTime.tryParse((a['date'] ?? '') as String)?.toLocal(), a['text'] as String, (a['points'] as num).toDouble()),
      ];
      final w = (await Api.get('/wallet'))['data'] as Map<String, dynamic>;
      app.walletHistory = [
        for (final t in ((w['transactions'] as List?) ?? const []).cast<Map<String, dynamic>>())
          HistoryLine(
            DateTime.tryParse((t['created_at'] ?? '') as String)?.toLocal(),
            (t['note'] as String?)?.isNotEmpty == true
                ? t['note'] as String
                : '${(t['reason'] as String? ?? '').replaceAll('_', ' ')}'.trim(),
            (t['amount'] as num).toDouble(),
          ),
      ];
      app.touch();
    } on ApiException {
      // history is a nice-to-have; keep what we had
    }
  }

  static List<AiPick> _picksFrom(dynamic list) => [
    for (final p in ((list as List?) ?? const []).cast<Map<String, dynamic>>())
      if (menu.any((m) => m.id == (p['slug'] ?? p['product'])))
        AiPick((p['slug'] ?? p['product']) as String, (p['reason'] ?? '') as String),
  ];

  /// AI menu assistant: "what are you in the mood for?" (null when it's off or busy).
  static Future<({String message, List<AiPick> picks})?> aiMenu(String prompt) async {
    try {
      final d = (await Api.post('/ai/menu', {'prompt': prompt}))['data'] as Map<String, dynamic>;
      final picks = _picksFrom(d['picks']);
      return picks.isEmpty ? null : (message: (d['message'] ?? '') as String, picks: picks);
    } on ApiException {
      return null;
    }
  }

  /// Keyword-based picks from real menu items (works without AI; needs sign-in).
  static Future<List<AiPick>> flavourFinder(String text) async {
    try {
      final d = (await Api.post('/flavour-finder', {'text': text}))['data'] as Map<String, dynamic>;
      return _picksFrom(d['picks']);
    } on ApiException {
      return const [];
    }
  }

  /// "Tell us what you're craving": the AI builds a waffle. Throws ApiException with a friendly message.
  static Future<({String message, String? base, List<String> scoops, String? drizzle, List<String> toppings})> aiBuild(
    String prompt,
  ) async {
    final d = (await Api.post('/ai/build', {'prompt': prompt}))['data'] as Map<String, dynamic>;
    final b = (d['build'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      message: (d['message'] ?? '') as String,
      base: b['base'] as String?,
      scoops: ((b['scoops'] as List?) ?? const []).cast<String>(),
      drizzle: b['drizzle'] as String?,
      toppings: ((b['toppings'] as List?) ?? const []).cast<String>(),
    );
  }

  /// Menu items that go with the waffle being built. live = chosen by the AI (else crowd favourites).
  static Future<({bool live, List<AiPick> picks})> aiPicks({
    String? base,
    List<String> scoops = const [],
    String? drizzle,
    List<String> toppings = const [],
  }) async {
    try {
      final d = (await Api.post('/ai/picks', {
        'base': base,
        'scoops': scoops,
        'drizzle': drizzle,
        'toppings': toppings,
      }))['data'] as Map<String, dynamic>;
      return (live: d['source'] != 'default', picks: _picksFrom(d['picks']));
    } on ApiException {
      return (live: false, picks: const <AiPick>[]);
    }
  }

  static Future<void> loadFavourites() async {
    try {
      final j = await Api.get('/favourites');
      app.favourites
        ..clear()
        ..addAll((j['data'] as List).cast<String>());
      app.touch();
    } catch (_) {}
  }

  static Future<void> toggleFavourite(String id) async {
    try {
      await Api.post('/favourites/$id/toggle');
    } catch (_) {}
  }

  static Future<void> savePrefs() async {
    try {
      final j = await Api.put('/me', {
        'preferences': {
          'gps_offers': app.gpsOffers,
          'order_alerts': app.orderAlerts,
          'email_news': app.emailNews,
          'store_alerts': app.storeAlerts,
        },
      });
      applyUser(j['data'] as Map<String, dynamic>);
    } catch (_) {}
  }

  static Future<void> saveAddress(String address) async {
    final j = await Api.put('/me', {'address': address});
    applyUser(j['data'] as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------ orders
  static ActiveOrder _active(Map<String, dynamic> o) {
    final items = (o['items'] as List).cast<Map<String, dynamic>>();
    final store = o['store'] as Map<String, dynamic>?;
    final order = ActiveOrder(
      number: o['number'] as String,
      mode: _mode(o['mode'] as String?),
      names: [for (final i in items) i['name'] as String],
      total: (o['total'] as num).toDouble(),
      earn: (o['points_earned'] as num).toInt(),
      placed: DateTime.parse(o['placed_at'] as String).toLocal(),
      waffle: items.isNotEmpty && (items.first['name'] as String).toLowerCase().contains('waffle'),
      status: o['status'] as String,
      statusAt: DateTime.tryParse((o['updated_at'] ?? '') as String)?.toLocal(),
      prepMinutes: (store?['prep_minutes'] as num?)?.toInt() ?? 15,
    );
    order.collected = order.status == 'completed';
    return order;
  }

  static PastOrder _past(Map<String, dynamic> o) {
    final items = (o['items'] as List).cast<Map<String, dynamic>>();
    final p = PastOrder(
      _dateLabel(DateTime.parse(o['placed_at'] as String).toLocal()),
      _mode(o['mode'] as String?) == Mode.delivery ? 'Delivery' : 'Pickup',
      [for (final i in items) if (i['product'] != null) i['product'] as String],
      o['title'] as String,
      (o['total'] as num).toDouble(),
      (o['points_earned'] as num).toInt(),
      C.blush,
      number: o['number'] as String,
    );
    p.rated = o['rating'] != null;
    return p;
  }

  static Future<void> loadOrders() async {
    try {
      final j = await Api.get('/orders');
      final list = (j['data'] as List).cast<Map<String, dynamic>>();
      app.past
        ..clear()
        ..addAll(list.where((o) => o['status'] == 'completed').map(_past));
      final open = list.where((o) => o['status'] != 'completed' && o['status'] != 'cancelled');
      app.active = open.isEmpty ? null : _active(open.first);
      app.touch();
    } catch (_) {}
  }

  /// Sends the cart to the server. Throws [ApiException] with a readable message.
  static Future<ActiveOrder> placeOrder({
    required int ptsUsed,
    required double walletUsed,
    DateTime? scheduledFor,
    String? scheduledSlot,
    bool payAtStore = false,
  }) async {
    final total = app.total(ptsUsed);
    final method = payAtStore
        ? 'pay_at_store'
        : (walletUsed <= 0 ? 'card' : (walletUsed + 0.005 >= total ? 'wallet' : 'split'));
    final j = await Api.post('/orders', {
      'items': [
        for (final l in app.cart)
          {
            'product': l.item.id,
            'quantity': l.qty,
            'scoops': l.scoops,
            'toppings': l.toppings,
            if (l.note != null) 'note': l.note,
            if (l.drizzle != null) 'drizzle': l.drizzle,
          },
      ],
      'mode': _modeApi(app.mode),
      'points_used': ptsUsed,
      'geo_deal': app.dealApplied,
      'payment_method': method,
      if (method == 'split') 'wallet_amount': walletUsed,
      if (app.mode == Mode.delivery) 'delivery_address': app.address,
      if (app.store.id != null) 'store_id': app.store.id,
      if (app.orderNotes.trim().isNotEmpty) 'notes': app.orderNotes.trim(),
      if (scheduledSlot != null)
        'scheduled_for': scheduledSlot
      else if (scheduledFor != null)
        'scheduled_for': scheduledFor.toUtc().toIso8601String(),
    });
    final order = _active(j['data'] as Map<String, dynamic>);
    applyUser(j['user'] as Map<String, dynamic>);
    app.cart.clear();
    app.orderNotes = '';
    loadHistory();
    app.dealApplied = false;
    app.active = order;
    app.touch();
    return order;
  }

  /// Poll the kitchen status of the current order.
  static Future<void> refreshActive() async {
    final o = app.active;
    if (o == null || o.collected) return;
    try {
      final j = await Api.get('/orders/${o.number}');
      final d = j['data'] as Map<String, dynamic>;
      final status = d['status'] as String;
      if (status != o.status) {
        o.status = status;
        o.statusAt = DateTime.tryParse((d['updated_at'] ?? '') as String)?.toLocal() ?? DateTime.now();
      }
      o.collected = status == 'completed';
      o.total = (d['total'] as num).toDouble();
      app.touch();
    } catch (_) {}
  }

  /// Customer confirms they have the order. Returns the points earned by it.
  static Future<int> collectActive() async {
    final o = app.active;
    if (o == null) return 0;
    if (!o.collected) {
      final j = await Api.post('/orders/${o.number}/collect');
      applyUser(j['user'] as Map<String, dynamic>);
      o.status = 'completed';
      o.collected = true;
    } else {
      await _refreshUser();
    }
    app.touch();
    return o.earn;
  }

  static Future<void> _refreshUser() async {
    try {
      final j = await Api.get('/me');
      applyUser(j['data'] as Map<String, dynamic>);
    } catch (_) {}
  }

  static Future<void> rateOrder(PastOrder o, int stars) async {
    if (o.number == null) return;
    try {
      final j = await Api.post('/orders/${o.number}/rate', {'stars': stars});
      o.rated = true;
      applyUser(j['user'] as Map<String, dynamic>);
    } catch (_) {}
  }

  // ------------------------------------------------------ rewards & wallet
  static Future<String> redeemReward(Reward r) async {
    final j = await Api.post('/rewards/${r.id}/redeem');
    applyUser(j['user'] as Map<String, dynamic>);
    loadHistory();
    return (j['data'] as Map<String, dynamic>)['code'] as String;
  }

  static Future<void> topUp(int amount) async {
    final pack = _packs.where((p) => (p['amount'] as num).round() == amount);
    if (pack.isEmpty) throw ApiException('That top-up amount is not available.');
    final j = await Api.post('/wallet/top-up', {'pack_id': pack.first['id']});
    applyUser(j['user'] as Map<String, dynamic>);
    loadHistory();
  }

  /// Privacy / Terms / Allergen text, edited in Admin > Settings > Website pages.
  /// Returns (title, blocks) where each block is (isHeading, text).
  static Future<({String title, List<({bool heading, String text})> blocks})> legalPage(String slug) async {
    final j = await Api.get('/pages/$slug');
    final d = j['data'] as Map<String, dynamic>;
    return (
      title: (d['title'] ?? '') as String,
      blocks: [
        for (final b in (d['blocks'] as List? ?? const []).cast<Map<String, dynamic>>())
          (heading: b['heading'] == true, text: (b['text'] ?? '') as String),
      ],
    );
  }

  /// Records a completed Photo Booth share. Returns the points the server
  /// awarded (only the customer's first-ever share earns points; 0 otherwise).
  static Future<int> sharePhoto() async {
    if (!Api.hasToken) return 0;
    try {
      final j = await Api.post('/photo-booth/share');
      applyUser(j['user'] as Map<String, dynamic>);
      return (j['earned'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

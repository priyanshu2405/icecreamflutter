import 'package:flutter/material.dart';

import 'services/repo.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// Menu data (mock). Food photos are placeholder tiles, as in the design file.
// ---------------------------------------------------------------------------

class MenuItem {
  final String id;
  final String name;
  final String desc;
  final String category;
  final double price;
  final Color tile;
  final IconData icon;
  final String? tag;
  final String? imageUrl;
  final bool? shakeFlag;
  final bool? scoopFlag;

  const MenuItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.category,
    required this.price,
    required this.tile,
    required this.icon,
    this.tag,
    this.imageUrl,
    this.shakeFlag,
    this.scoopFlag,
  });

  bool get isShake => shakeFlag ?? category == 'Shakes';
  bool get takesScoops => scoopFlag ?? category != 'Shakes';
  String get singular => switch (category) {
    'Waffles' => 'Waffle',
    'Shakes' => 'Shake',
    'Ice Cream' => 'Ice cream',
    _ => category,
  };
}

// The lists below start with a bundled fallback menu and are replaced by the
// server's menu on launch (see services/repo.dart).
List<String> categories = ['Ice Cream', 'Waffles', 'Bingsu', 'Shakes'];

Map<String, String> categoryBlurb = {
  'Ice Cream': 'Small batch. Big scoops.',
  'Waffles': 'Golden edges. Generous toppings.',
  'Bingsu': 'Shaved snow, piled high.',
  'Shakes': 'Thick, cold, made to order.',
};

Map<String, Color> categoryTile = {
  'Ice Cream': Color(0xFFFCE1EC),
  'Waffles': Color(0xFFF1E6D6),
  'Bingsu': Color(0xFFFFF0C2),
  'Shakes': Color(0xFFFCE1EC),
};

Map<String, IconData> categoryIcon = {
  'Ice Cream': Icons.icecream_outlined,
  'Waffles': Icons.grid_on_rounded,
  'Bingsu': Icons.ac_unit_rounded,
  'Shakes': Icons.local_drink_outlined,
};

List<MenuItem> menu = <MenuItem>[
  // Waffles
  MenuItem(
    id: 'signature',
    name: 'Lick It Signature',
    desc: 'Three chocolates & brownie crunch',
    category: 'Waffles',
    price: 16.95,
    tile: Color(0xFFFCE1EC),
    icon: Icons.grid_on_rounded,
    tag: 'Best seller',
  ),
  MenuItem(
    id: 'biscoff',
    name: 'Lotus Biscoff',
    desc: 'Biscoff spread & cookie crumble',
    category: 'Waffles',
    price: 15.95,
    tile: Color(0xFFF1E6D6),
    icon: Icons.grid_on_rounded,
  ),
  MenuItem(
    id: 'banoffee',
    name: 'Banoffee Pie',
    desc: 'Banana, caramel, cream & crumble',
    category: 'Waffles',
    price: 15.95,
    tile: Color(0xFFFFF0C2),
    icon: Icons.grid_on_rounded,
  ),
  MenuItem(
    id: 'redvelvet',
    name: 'Red Velvet',
    desc: 'Red velvet waffle & white chocolate',
    category: 'Waffles',
    price: 15.45,
    tile: Color(0xFFFAD4DF),
    icon: Icons.grid_on_rounded,
  ),
  MenuItem(
    id: 'rockyroad',
    name: 'Rocky Road',
    desc: 'Oreo crunch, chocolate & almonds',
    category: 'Waffles',
    price: 15.45,
    tile: Color(0xFFEADDD3),
    icon: Icons.grid_on_rounded,
  ),
  // Bingsu
  MenuItem(
    id: 'pista',
    name: 'Pista Kunafa',
    desc: 'Pistachio cream, kunafa crunch & rose',
    category: 'Bingsu',
    price: 18.95,
    tile: Color(0xFFE2F0D9),
    icon: Icons.ac_unit_rounded,
    tag: 'New',
  ),
  MenuItem(
    id: 'mango',
    name: 'Mango Mania Bingsu',
    desc: 'Alphonso mango, mango sorbet & cream',
    category: 'Bingsu',
    price: 17.95,
    tile: Color(0xFFFFF0C2),
    icon: Icons.ac_unit_rounded,
  ),
  MenuItem(
    id: 'cheesecake',
    name: 'Strawberry Cheesecake',
    desc: 'Cheesecake bites, berries & condensed milk',
    category: 'Bingsu',
    price: 17.45,
    tile: Color(0xFFFCE1EC),
    icon: Icons.ac_unit_rounded,
  ),
  MenuItem(
    id: 'matchabingsu',
    name: 'Matcha Red Bean',
    desc: 'Ceremonial matcha, red bean & mochi',
    category: 'Bingsu',
    price: 16.95,
    tile: Color(0xFFE2F0D9),
    icon: Icons.ac_unit_rounded,
  ),
  // Ice cream
  MenuItem(
    id: 'dubai',
    name: 'Dubai Chocolate Strawberry Cup',
    desc: 'Strawberries, pistachio kunafa & chocolate',
    category: 'Ice Cream',
    price: 17.80,
    tile: Color(0xFFE2F0D9),
    icon: Icons.icecream_outlined,
  ),
  MenuItem(
    id: 'velvet',
    name: 'Vanilla Velvet Cloud',
    desc: 'Madagascar vanilla, whipped & airy',
    category: 'Ice Cream',
    price: 6.75,
    tile: Color(0xFFFFF4DA),
    icon: Icons.icecream_outlined,
  ),
  MenuItem(
    id: 'double',
    name: 'Double Scoop Waffle Cone',
    desc: 'Any two flavours in a fresh waffle cone',
    category: 'Ice Cream',
    price: 8.45,
    tile: Color(0xFFF1E6D6),
    icon: Icons.icecream_outlined,
  ),
  MenuItem(
    id: 'single',
    name: 'Single Scoop Cup',
    desc: 'One generous scoop, your pick',
    category: 'Ice Cream',
    price: 5.95,
    tile: Color(0xFFFCE1EC),
    icon: Icons.icecream_outlined,
  ),
  // Shakes
  MenuItem(
    id: 'goldenhour',
    name: 'Biscoff Golden Hour',
    desc: 'Biscoff, caramel & vanilla bean',
    category: 'Shakes',
    price: 10.95,
    tile: Color(0xFFFFF0C2),
    icon: Icons.local_drink_outlined,
  ),
  MenuItem(
    id: 'oreo',
    name: 'Oreo Overload',
    desc: 'Cookies & cream, Oreo crumb rim',
    category: 'Shakes',
    price: 10.45,
    tile: Color(0xFFEADDD3),
    icon: Icons.local_drink_outlined,
  ),
  MenuItem(
    id: 'strawberry',
    name: 'Strawberry Dream',
    desc: 'Fresh strawberries & cotton candy',
    category: 'Shakes',
    price: 9.95,
    tile: Color(0xFFFCE1EC),
    icon: Icons.local_drink_outlined,
  ),
  MenuItem(
    id: 'matcha',
    name: 'Iced Matcha',
    desc: 'Ceremonial matcha, oat milk & vanilla',
    category: 'Shakes',
    price: 6.25,
    tile: Color(0xFFE2F0D9),
    icon: Icons.local_drink_outlined,
  ),
];

MenuItem itemById(String id) =>
    menu.firstWhere((m) => m.id == id, orElse: () => menu.first);

class Flavour {
  final String name;
  final Color dot;
  const Flavour(this.name, this.dot);
}

List<Flavour> scoopFlavours = <Flavour>[
  Flavour('Vanilla Bean', Color(0xFFF5E6B3)),
  Flavour('Strawberry', C.pink),
  Flavour('Salted Caramel', C.waffle),
  Flavour('Pistachio', Color(0xFF9ACD5A)),
  Flavour('Cookies & Cream', Color(0xFF8A8A8A)),
  Flavour('Cotton Candy', Color(0xFF8FD3FF)),
];

List<String> toppingOptions = [
  'Oreo crumble',
  'Brownie pieces',
  'Fresh strawberries',
  'Kit Kat',
  'Nutella drizzle',
  'Rainbow sprinkles',
];

/// Pricing rules. Defaults match the design; the server's values replace them
/// on launch so the cart always shows the same maths the server will charge.
class Rules {
  static double scoop = 2.50;
  static double topping = 1.25;
  static double deliveryFee = 4.99;
  static double gstRate = 0.05;
  static double pointValue = 0.01; // 100 pts = \$1.00
  static double dealPercent = 10;
  static bool dealEnabled = true;
  static int photoPoints = 25;
  static int ratingPoints = 15;
  static bool orderingEnabled = true;

  static void apply(Map<String, dynamic> s) {
    double d(String k, double f) => (s[k] as num?)?.toDouble() ?? f;
    scoop = d('scoop_price', scoop);
    topping = d('topping_price', topping);
    deliveryFee = d('delivery_fee', deliveryFee);
    gstRate = d('gst_rate', gstRate);
    pointValue = d('point_value', pointValue);
    dealPercent = d('geo_deal_percent', dealPercent);
    dealEnabled = s['geo_deal_enabled'] as bool? ?? dealEnabled;
    photoPoints = (s['photo_share_points'] as num?)?.toInt() ?? photoPoints;
    ratingPoints = (s['rating_points'] as num?)?.toInt() ?? ratingPoints;
    orderingEnabled = s['ordering_enabled'] as bool? ?? orderingEnabled;
  }
}

// ---------------------------------------------------------------------------
// Cart, orders and app state
// ---------------------------------------------------------------------------

class CartLine {
  final MenuItem item;
  final List<String> scoops;
  final List<String> toppings;
  int qty;

  CartLine(this.item, this.scoops, this.toppings, this.qty);

  double get baseUnit =>
      item.price +
      scoops.length * Rules.scoop +
      toppings.length * Rules.topping;

  bool sameAs(MenuItem i, List<String> s, List<String> t) =>
      i.id == item.id &&
      s.join('|') == scoops.join('|') &&
      t.join('|') == toppings.join('|');
}

enum Mode { pickup, delivery, dineIn }

class ActiveOrder {
  final String number;
  final Mode mode;
  final List<String> names;
  double total;
  final int earn;
  final DateTime placed;
  final bool waffle;
  bool collected = false;

  /// Kitchen status from the server: received | making | ready |
  /// out_for_delivery | completed | cancelled.
  String status;
  DateTime statusAt;
  final int prepMinutes;

  ActiveOrder({
    required this.number,
    required this.mode,
    required this.names,
    required this.total,
    required this.earn,
    required this.placed,
    required this.waffle,
    this.status = 'received',
    DateTime? statusAt,
    this.prepMinutes = 15,
  }) : statusAt = statusAt ?? DateTime.now();

  // The tracking screens were designed around a timer. These numbers map the
  // real server status onto that timeline (stage 0 = received, 1 = making,
  // 2 = ready / on the way; delivery "arrives" when the order is completed).
  static const prepSeconds = 18;
  static const driveSeconds = 45;

  int get elapsed {
    switch (status) {
      case 'received':
        return 2;
      case 'making':
        return 10;
      case 'ready':
        return prepSeconds;
      case 'out_for_delivery':
        final s = DateTime.now().difference(statusAt).inSeconds;
        final span = driveSeconds - 1 - prepSeconds;
        return prepSeconds + (s * span / 600).floor().clamp(0, span);
      case 'completed':
        return prepSeconds + driveSeconds;
      default:
        return 0;
    }
  }

  int get stage => elapsed < 4 ? 0 : (elapsed < prepSeconds ? 1 : 2);
}

class PastOrder {
  final String date;
  final String mode;
  final List<String> itemIds;
  final String title;
  final double total;
  final int pts;
  final Color tile;
  final String? number;
  bool rated = false;

  PastOrder(
    this.date,
    this.mode,
    this.itemIds,
    this.title,
    this.total,
    this.pts,
    this.tile, {
    this.number,
  });
}

class AppState extends ChangeNotifier {
  String firstName = 'Friend';
  String fullName = 'Friend';
  String address = '';
  String phone = '';
  String email = '';
  int points = 0;
  double wallet = 0;
  int ordersCount = 0;
  List<int> packAmounts = [10, 25, 50, 100];
  Map<int, int> packBonus = {10: 0, 25: 0, 50: 50, 100: 120};

  String get addressLine =>
      address.isEmpty ? 'Add your delivery address' : address;

  Mode mode = Mode.pickup;
  bool dealApplied = false;
  int tab = 0;
  String menuCategory = 'Waffles';

  final List<CartLine> cart = [];
  final Set<String> favourites = {};
  ActiveOrder? active;

  bool gpsOffers = true;
  bool orderAlerts = true;
  bool emailNews = false;
  bool sharedPhoto = false;
  bool storeAlerts = false;

  final List<PastOrder> past = [];

  /// Clears everything that belongs to the signed-in customer.
  void resetSession() {
    firstName = 'Friend';
    fullName = 'Friend';
    address = '';
    phone = '';
    email = '';
    points = 0;
    wallet = 0;
    ordersCount = 0;
    cart.clear();
    favourites.clear();
    past.clear();
    active = null;
    sharedPhoto = false;
    dealApplied = false;
    tab = 0;
    notifyListeners();
  }

  /// Saves the notification toggles on the server.
  void savePrefs() {
    notifyListeners();
    Repo.savePrefs();
  }

  // --- navigation helpers ---
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  void openMenu(String category) {
    menuCategory = category;
    tab = 1;
    notifyListeners();
  }

  void setCategory(String c) {
    menuCategory = c;
    notifyListeners();
  }

  void setMode(Mode m) {
    mode = m;
    notifyListeners();
  }

  void applyDeal() {
    if (!Rules.dealEnabled) return;
    dealApplied = true;
    notifyListeners();
  }

  void toggleFav(String id) {
    favourites.contains(id) ? favourites.remove(id) : favourites.add(id);
    notifyListeners();
    Repo.toggleFavourite(id);
  }

  void touch() => notifyListeners();

  // --- cart ---
  double unitFor(MenuItem item, int scoops, int toppings) {
    var p = item.price + scoops * Rules.scoop + toppings * Rules.topping;
    if (item.isShake && dealApplied) p = p * (1 - Rules.dealPercent / 100);
    return round2(p);
  }

  double unitPrice(CartLine l) =>
      unitFor(l.item, l.scoops.length, l.toppings.length);
  double lineTotal(CartLine l) => round2(unitPrice(l) * l.qty);
  int get cartCount => cart.fold(0, (s, l) => s + l.qty);
  double get subtotal => round2(cart.fold(0.0, (s, l) => s + lineTotal(l)));
  double get deliveryFee =>
      mode == Mode.delivery && cart.isNotEmpty ? Rules.deliveryFee : 0.0;
  int get earnBeforePoints => (subtotal + deliveryFee).floor();

  void add(
    MenuItem item, {
    List<String> scoops = const [],
    List<String> toppings = const [],
    int qty = 1,
  }) {
    for (final l in cart) {
      if (l.sameAs(item, scoops, toppings)) {
        l.qty += qty;
        notifyListeners();
        return;
      }
    }
    cart.add(CartLine(item, List.of(scoops), List.of(toppings), qty));
    notifyListeners();
  }

  void changeQty(CartLine l, int delta) {
    l.qty += delta;
    if (l.qty <= 0) cart.remove(l);
    notifyListeners();
  }

  bool inCart(String id) => cart.any((l) => l.item.id == id);

  String lineSubtitle(CartLine l) {
    final parts = <String>[...l.scoops.map((s) => '$s scoop'), ...l.toppings];
    if (parts.isNotEmpty) return '+ ${parts.join(' · ')}';
    if (l.item.isShake) {
      return dealApplied
          ? 'Thick shake · ${Rules.dealPercent.round()}% nearby deal'
          : 'Thick shake';
    }
    return l.item.desc;
  }

  // --- checkout maths (rates come from the server: Admin > Settings) ---
  double gst(int pts) => round2(
    (subtotal + deliveryFee - pts * Rules.pointValue) * Rules.gstRate,
  );
  double total(int pts) =>
      round2(subtotal + deliveryFee - pts * Rules.pointValue + gst(pts));

  /// Called when the customer collects / receives the order.
  int collect() {
    final o = active;
    if (o == null || o.collected) return 0;
    o.collected = true;
    notifyListeners();
    return o.earn; // points were already credited by the server
  }

  void finishOrder() {
    final o = active;
    if (o == null) return;
    collect();
    past.insert(
      0,
      PastOrder(
        'Today',
        o.mode == Mode.delivery ? 'Delivery' : 'Pickup',
        [],
        o.names.join(', '),
        o.total,
        o.earn,
        C.blush,
        number: o.number,
      ),
    );
    active = null;
    notifyListeners();
  }

  // --- rewards / wallet ---
  bool redeem(int cost) {
    if (points < cost) return false;
    points -= cost;
    notifyListeners();
    return true;
  }

  void topUp(double amount, int bonus) {
    wallet = round2(wallet + amount);
    points += bonus;
    notifyListeners();
  }

  void earn(int pts) {
    points += pts;
    notifyListeners();
  }
}

/// Single app-wide state object (fine for a prototype).
final app = AppState();

double round2(double v) => (v * 100).round() / 100;

String money(double v) => '\$${v.toStringAsFixed(2)}';

String fmtTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

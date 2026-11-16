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

  /// Category slug from the admin ("ice-cream", "waffles"…); null on the bundled sample menu.
  final String? categorySlug;
  final double price;
  final Color tile;
  final IconData icon;
  final String? tag;
  final String? imageUrl;
  final bool? shakeFlag;
  final bool? scoopFlag;

  /// "Featured" in the website admin: shown as Fan favourites on Home.
  final bool featured;

  /// Picture to show, like the website: the product's own photo, else its category's illustration.
  String? get art => imageUrl ?? categoryImage[category];
  bool get hasPhoto => imageUrl != null;

  const MenuItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.category,
    this.categorySlug,
    required this.price,
    required this.tile,
    required this.icon,
    this.tag,
    this.imageUrl,
    this.shakeFlag,
    this.scoopFlag,
    this.featured = false,
  });

  /// Every product in the admin's "Ice Cream" category (Single scoop, Double scoop…):
  /// the customer picks the flavours it includes, like the website.
  bool get isIceCream => isIceCategory(category, categorySlug);

  /// "Single/Double/Triple" in the name sets how many flavours are included (same rule as the website).
  int get includedFlavours {
    final n = name.toLowerCase();
    return n.contains('triple') ? 3 : (n.contains('double') ? 2 : 1);
  }

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

/// Category name → slug from the admin.
Map<String, String> categorySlug = {};

/// The website keys its ice-cream picker on the category slug "ice-cream",
/// so a renamed category still works.
bool isIceCategory(String name, [String? slug]) =>
    (slug ?? categorySlug[name]) == 'ice-cream' || name.trim().toLowerCase() == 'ice cream';

/// Category name → picture uploaded in Admin > Categories ("Website illustration").
Map<String, String> categoryImage = {};

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

MenuItem itemById(String id) => menu.firstWhere(
  (m) => m.id == id,
  orElse: () => byoItems.firstWhere((m) => m.id == id, orElse: () => menu.first),
);

// ---------------------------------------------------------------------------
// Build your own waffle (same builder as luckit.vads.ca/build-your-own)
// ---------------------------------------------------------------------------

/// A waffle base from Admin > Build your own. Each one is linked to the hidden
/// product that carries its price, so the server charges the same amount.
class ByoBase {
  final String name;
  final Color color;
  final String slug;
  final double price;
  const ByoBase(this.name, this.color, this.slug, this.price);
}

const byoMaxScoops = 3;

/// Bases in admin order (replaced by the server's list on launch).
List<ByoBase> byoBases = const [
  ByoBase('Classic Belgian', Color(0xFFC9852F), 'build-your-own', 11.95),
  ByoBase('Red Velvet', Color(0xFFB3263E), 'build-your-own-red-velvet', 12.95),
  ByoBase('Chocolate', Color(0xFF6B3B26), 'build-your-own-chocolate', 12.95),
];

ByoBase? byoBaseNamed(String? name) {
  for (final b in byoBases) {
    if (b.name == name) return b;
  }
  return null;
}

/// The hidden "build your own" products, one per base.
List<MenuItem> get byoItems => [
  for (final b in byoBases)
    MenuItem(
      id: b.slug,
      name: b.slug == 'build-your-own' ? 'Build your own waffle' : 'Build your own waffle (${b.name} base)',
      desc: 'Custom waffle from the builder',
      category: 'Build your own',
      price: b.price,
      tile: const Color(0xFFFDE6EF),
      icon: Icons.grid_view_rounded,
    ),
];

MenuItem byoItemFor(String base) {
  final b = byoBaseNamed(base) ?? byoBases.first;
  return byoItems.firstWhere((m) => m.id == b.slug, orElse: () => byoItems.first);
}

/// Drizzles offered by the builder (name + colour, from Admin > Build your own).
List<Flavour> byoDrizzles = const <Flavour>[
  Flavour('Nutella', Color(0xFF5A2E1E)),
  Flavour('Lotus Biscoff', Color(0xFFB5732F)),
  Flavour('Belgian chocolate', Color(0xFF3E2117)),
  Flavour('White chocolate', Color(0xFFF3E9DC)),
  Flavour('Caramel', Color(0xFFD8902F)),
  Flavour('Pistachio cream', Color(0xFF9CCC65)),
];

// ---------------------------------------------------------------------------
// Stores and business details (from the website admin)
// ---------------------------------------------------------------------------

class StoreInfo {
  final int? id;
  final String name;
  final String address;
  final String city;
  final String hours;
  final String phone;
  final double? lat;
  final double? lng;
  final bool offersDelivery;

  const StoreInfo({
    this.id,
    required this.name,
    required this.address,
    required this.city,
    this.hours = '',
    this.phone = '',
    this.lat,
    this.lng,
    this.offersDelivery = true,
  });

  /// Admin placeholders like "[Your opening hours]" aren't shown to customers.
  static String clean(String? v) {
    final t = (v ?? '').trim();
    return t.startsWith('[') && t.endsWith(']') ? '' : t;
  }
}

List<StoreInfo> stores = const [
  StoreInfo(
    name: 'Lick It · City Pkwy',
    address: 'Unit #5, 10302 City Pkwy, Surrey, BC V3T 4Y8',
    city: 'Surrey',
    lat: 49.1913,
    lng: -122.849,
  ),
];

Uri directionsTo(StoreInfo s) => Uri.parse(
  'https://www.google.com/maps/dir/?api=1&destination='
  '${Uri.encodeComponent(s.lat != null && s.lng != null ? '${s.lat},${s.lng}' : s.address)}',
);

Uri telLink(String phone) => Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

// ---------------------------------------------------------------------------
// "Schedule for later" slots (Admin > Settings > Scheduling)
// ---------------------------------------------------------------------------

class ScheduleSlot {
  final String value; // exact time the server expects back, e.g. 2026-11-17T12:00:00-07:00
  final String label; // "12:00 pm"
  const ScheduleSlot(this.value, this.label);
}

class ScheduleDay {
  final String label; // "Today", "Tomorrow", "Wed, Nov 18"
  final List<ScheduleSlot> slots;
  const ScheduleDay(this.label, this.slots);
}

/// null = older server (free time picker); empty = scheduling switched off.
List<ScheduleDay>? scheduleDays;

/// A menu item suggested by the server (AI or crowd favourite) with its reason.
class AiPick {
  final String slug;
  final String reason;
  const AiPick(this.slug, this.reason);
}

/// One line of points or wallet history.
class HistoryLine {
  final DateTime? date;
  final String text;
  final double amount; // points, or dollars for the wallet
  const HistoryLine(this.date, this.text, this.amount);
}

/// Business phone and Instagram handle from the admin settings.
class Biz {
  static String phone = '';
  static String instagram = '';
}

/// Menu items suggested under the builder ("Goes great with your waffle").
const byoPairings = ['Strawberry Blush', 'Vanilla Velvet Cloud', 'Oreo Dream', 'Dubai Cup'];

class Flavour {
  final String name;
  final Color dot;
  final String group; // first group: "The Classics", "Fruit Favourites"… (from the admin)
  final List<String> groups; // a flavour can sit in several groups
  const Flavour(this.name, this.dot, [this.group = 'Flavours', this.groups = const []]);
  List<String> get allGroups => groups.isEmpty ? [group] : groups;
}

/// Flavour groups in admin order, hidden ones left out (empty = older server).
List<String> flavourGroups = [];

/// Flavours grouped like the website menu: groups in the admin's order, hidden
/// groups left out, and a flavour shown under each of its groups.
Map<String, List<Flavour>> groupedFlavours() {
  final groups = <String, List<Flavour>>{for (final g in flavourGroups) g: []};
  for (final f in scoopFlavours) {
    for (final g in f.allGroups) {
      if (flavourGroups.isEmpty) {
        groups.putIfAbsent(g, () => []).add(f);
      } else if (groups.containsKey(g)) {
        groups[g]!.add(f);
      }
    }
  }
  groups.removeWhere((_, v) => v.isEmpty);
  // Nothing matched the group list (e.g. every group hidden): still offer every flavour.
  if (groups.isEmpty && scoopFlavours.isNotEmpty) groups['Flavours'] = List.of(scoopFlavours);
  return groups;
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
  static bool deliveryEnabled = true; // Admin > Settings > Offer delivery
  static double minOrder = 0; // Admin > Settings > Minimum order
  static String currency = '\$'; // Admin > Settings > Currency symbol
  /// Per-item prices from the admin. Missing = the default scoop / topping price.
  static Map<String, double> scoopPrices = {};
  static Map<String, double> toppingPrices = {};
  static Map<String, double> drizzlePrices = {};
  static double scoopPriceOf(String name) =>
      scoopPrices[name.replaceFirst(RegExp(r'^Extra:\s*', caseSensitive: false), '').trim()] ?? scoop;
  static double toppingPriceOf(String name) => toppingPrices[name.trim()] ?? topping;
  static double drizzlePriceOf(String? name) => name == null ? 0 : (drizzlePrices[name.trim()] ?? 0);

  // card / split / wallet top-up. Off unless the server says they're on
  // (matches the live website, where online payments are switched off).
  static bool onlinePayments = false;
  static bool aiEnabled = false; // AI suggestions (OpenAI key set on the server)
  static String siteUrl = 'https://luckit.vads.ca/';
  static double byoBase = 11.95; // build-your-own: Classic Belgian price
  static double byoUpcharge = 1.00; // build-your-own: Red Velvet / Chocolate extra

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
    deliveryEnabled = s['delivery_enabled'] as bool? ?? deliveryEnabled;
    minOrder = d('min_order', minOrder);
    final cur = (s['currency_symbol'] as String?)?.trim();
    if (cur != null && cur.isNotEmpty) currency = cur;
    byoBase = d('byo_base_price', byoBase);
    onlinePayments = s['online_payments'] as bool? ?? false;
    aiEnabled = s['ai_enabled'] as bool? ?? aiEnabled;
    final url = s['site_url'] as String?;
    if (url != null && url.startsWith('http')) siteUrl = url.endsWith('/') ? url : '$url/';
    byoUpcharge = d('byo_base_upcharge', byoUpcharge);
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

  /// Kitchen note sent with the line (build-your-own: base, drizzle and the
  /// customer's own note).
  final String? note;

  /// Build your own: the drizzle (priced per drizzle in the admin).
  final String? drizzle;

  CartLine(this.item, this.scoops, this.toppings, this.qty, {this.note, this.drizzle});

  double get baseUnit =>
      item.price +
      scoops.length * Rules.scoop +
      toppings.length * Rules.topping;

  bool sameAs(MenuItem i, List<String> s, List<String> t, [String? n, String? d]) =>
      i.id == item.id &&
      s.join('|') == scoops.join('|') &&
      t.join('|') == toppings.join('|') &&
      (n ?? '') == (note ?? '') &&
      (d ?? '') == (drizzle ?? '');
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

  /// Store the customer orders from (null = first store) and their kitchen note.
  int? storeId;
  String orderNotes = '';

  /// Where the delivery address was pinned on the map (this session).
  double? addressLat;
  double? addressLng;

  /// Points history ("Recent activity") and wallet history from the server.
  List<HistoryLine> pointsHistory = [];
  List<HistoryLine> walletHistory = [];
  StoreInfo get store => stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);

  /// "City Pkwy" from "Lick It · City Pkwy".
  String get storeShort {
    final n = store.name;
    final i = n.lastIndexOf('·');
    return (i >= 0 ? n.substring(i + 1) : n).trim();
  }

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
    // Delivery switched off in the admin: stay on pickup, like the website.
    if (m == Mode.delivery && !Rules.deliveryEnabled) m = Mode.pickup;
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
  /// Same as the server: product price + each scoop's and topping's own price
  /// (+ the drizzle for build your own). Scoops only count where the category takes them.
  double unitFor(MenuItem item, List<String> scoops, List<String> toppings, {String? drizzle}) {
    var p = item.price + Rules.drizzlePriceOf(drizzle);
    if (item.takesScoops) {
      for (final s in scoops) {
        p += Rules.scoopPriceOf(s);
      }
    }
    for (final t in toppings) {
      p += Rules.toppingPriceOf(t);
    }
    if (item.isShake && dealApplied) p = p * (1 - Rules.dealPercent / 100);
    return round2(p);
  }

  double unitPrice(CartLine l) => unitFor(l.item, l.scoops, l.toppings, drizzle: l.drizzle);
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
    String? note,
    String? drizzle,
  }) {
    for (final l in cart) {
      if (l.sameAs(item, scoops, toppings, note, drizzle)) {
        l.qty += qty;
        notifyListeners();
        return;
      }
    }
    cart.add(CartLine(item, List.of(scoops), List.of(toppings), qty, note: note, drizzle: drizzle));
    notifyListeners();
  }

  void changeQty(CartLine l, int delta) {
    l.qty += delta;
    if (l.qty <= 0) cart.remove(l);
    notifyListeners();
  }

  bool inCart(String id) => cart.any((l) => l.item.id == id);

  String lineSubtitle(CartLine l) {
    final parts = <String>[
      ...l.scoops.map((s) => s.startsWith('Extra: ') ? 'Extra ${s.substring(7)} scoop' : '$s scoop'),
      ...l.toppings,
    ];
    if (l.note != null && l.note!.isNotEmpty) {
      return [l.note!, if (parts.isNotEmpty) '+ ${parts.join(' · ')}'].join('\n');
    }
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

String money(double v) => '${Rules.currency}${v.toStringAsFixed(2)}';

/// "100" when 1 point = \$0.01 (Admin > Settings > Value of 1 point).
int get pointsPerDollar => Rules.pointValue > 0 ? (1 / Rules.pointValue).round() : 100;

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

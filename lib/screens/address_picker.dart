import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data.dart';
import '../services/api_client.dart';
import '../services/geocoder.dart';
import '../services/repo.dart';
import '../theme.dart';
import '../widgets.dart';

// ---------------------------------------------------------------------------
// Delivery address on a real map (OpenStreetMap, no API key).
// Drag the map so the pin sits on the door, search an address, or use the
// phone's location. The address under the pin fills in by itself.
// ---------------------------------------------------------------------------

/// Opens the map picker. Returns true when an address was saved.
Future<bool> pickDeliveryAddress(BuildContext context) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const AddressPickerScreen()),
  );
  return saved ?? false;
}

class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  final _unit = TextEditingController();
  final _searchFocus = FocusNode();

  late LatLng _center;
  String _line = ''; // address under the pin
  bool _lookingUp = false;
  bool _locating = false;
  bool _saving = false;
  bool _searching = false;
  List<Place> _results = const [];
  Timer? _reverseTimer;
  Timer? _searchTimer;
  bool _mapReady = false;
  (LatLng, double)? _pendingMove; // a jump asked for before the map finished drawing

  StoreInfo get _store => app.store;
  LatLng? get _storePoint =>
      _store.lat != null && _store.lng != null ? LatLng(_store.lat!, _store.lng!) : null;

  @override
  void initState() {
    super.initState();
    // Start where the customer's address was last pinned, else at the store, else Surrey.
    _center = app.addressLat != null && app.addressLng != null
        ? LatLng(app.addressLat!, app.addressLng!)
        : (_storePoint ?? const LatLng(49.1913, -122.849));

    // "123 Main St, Surrey · Unit 5" → address + unit
    final saved = app.address.trim();
    final i = saved.indexOf(' · Unit ');
    _line = i >= 0 ? saved.substring(0, i) : saved;
    if (i >= 0) _unit.text = saved.substring(i + ' · Unit '.length);

    if (app.addressLat == null && _line.isNotEmpty) {
      _findSaved(); // put the pin on the saved address
    } else if (_line.isEmpty) {
      _lookUp();
    }
  }

  @override
  void dispose() {
    _reverseTimer?.cancel();
    _searchTimer?.cancel();
    _search.dispose();
    _unit.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _findSaved() async {
    final r = await Geocoder.search(_line, nearLat: _center.latitude, nearLng: _center.longitude);
    if (!mounted || r.isEmpty) return;
    _moveTo(LatLng(r.first.lat, r.first.lng), label: _line);
  }

  void _moveTo(LatLng p, {String? label, double zoom = 17}) {
    _center = p;
    if (_mapReady) {
      _map.move(p, zoom);
    } else {
      _pendingMove = (p, zoom);
    }
    if (label != null) {
      setState(() => _line = label);
    } else {
      _lookUp();
    }
  }

  /// Address under the pin, looked up a moment after the map stops moving.
  void _lookUpSoon() {
    _reverseTimer?.cancel();
    _reverseTimer = Timer(const Duration(milliseconds: 800), _lookUp);
  }

  Future<void> _lookUp() async {
    final p = _center;
    setState(() => _lookingUp = true);
    final label = await Geocoder.reverse(p.latitude, p.longitude);
    if (!mounted || p != _center) return; // the map moved again meanwhile
    setState(() {
      _lookingUp = false;
      if (label != null && label.isNotEmpty) _line = label;
    });
  }

  void _onSearchChanged(String v) {
    _searchTimer?.cancel();
    if (v.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 900), () => _runSearch(v));
  }

  Future<void> _runSearch(String v) async {
    setState(() => _searching = true);
    final r = await Geocoder.search(
      v,
      nearLat: _storePoint?.latitude ?? _center.latitude,
      nearLng: _storePoint?.longitude ?? _center.longitude,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = r;
    });
    if (r.isEmpty && v.trim().length >= 3) toast(context, 'No matching address. Try adding the city.');
  }

  void _pick(Place p) {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() => _results = const []);
    _moveTo(LatLng(p.lat, p.lng), label: p.label);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) toast(context, 'Turn on Location in your phone settings, then try again.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          toast(
            context,
            perm == LocationPermission.deniedForever
                ? 'Location is off for Lick It. You can allow it in your phone settings.'
                : 'Location permission is needed to find you. You can also search or drag the map.',
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      _moveTo(LatLng(pos.latitude, pos.longitude), zoom: 18);
    } on TimeoutException {
      if (mounted) toast(context, "Couldn't get your location. Try again outside, or search instead.");
    } catch (_) {
      if (mounted) toast(context, "Couldn't get your location. You can search or drag the map instead.");
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final line = _line.trim();
    if (line.isEmpty) {
      toast(context, 'Move the pin to your address first');
      return;
    }
    final unit = _unit.text.trim();
    final full = unit.isEmpty ? line : '$line · Unit $unit';
    setState(() => _saving = true);
    try {
      await Repo.saveAddress(full);
      app.addressLat = _center.latitude;
      app.addressLng = _center.longitude;
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _distance {
    final s = _storePoint;
    if (s == null) return null;
    final km = const Distance().as(LengthUnit.Meter, s, _center) / 1000;
    return '${km < 10 ? km.toStringAsFixed(1) : km.round()} km from ${app.storeShort}';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 16,
                    minZoom: 4,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _mapReady = true;
                      final m = _pendingMove;
                      if (m != null) _map.move(m.$1, m.$2);
                      _pendingMove = null;
                    },
                    onPositionChanged: (camera, hasGesture) {
                      if (!hasGesture) return;
                      _center = camera.center;
                      _lookUpSoon();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ca.vads.lickit',
                    ),
                    if (_storePoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _storePoint!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: C.ink,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.icecream_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => openLink(context, Uri.parse('https://www.openstreetmap.org/copyright')),
                        ),
                      ],
                    ),
                  ],
                ),
                // the pin always marks the centre of the map
                IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: const Icon(Icons.location_on_rounded, color: C.deep, size: 48),
                    ),
                  ),
                ),
                // back + search
                Positioned(
                  left: 16,
                  right: 16,
                  top: top + 10,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleBtn(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              elevation: 3,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(26),
                              child: TextField(
                                controller: _search,
                                focusNode: _searchFocus,
                                textInputAction: TextInputAction.search,
                                onChanged: _onSearchChanged,
                                onSubmitted: _runSearch,
                                style: dm(15.5),
                                decoration: InputDecoration(
                                  hintText: 'Search your address',
                                  hintStyle: dm(15, color: C.grey),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.search, color: C.grey),
                                  suffixIcon: _searching
                                      ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: C.deep),
                                          ),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_results.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8, left: 56),
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: C.line),
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined, color: C.deep),
                              title: Text(_results[i].label, style: dm(14.5)),
                              onTap: () => _pick(_results[i]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // use my location
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _locating ? null : _useMyLocation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _locating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: C.deep),
                                  )
                                : const Icon(Icons.my_location_rounded, color: C.deep, size: 20),
                            const SizedBox(width: 8),
                            Text('Use my current location', style: dm(14, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // address card
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 14 + bottom),
            decoration: const BoxDecoration(
              color: C.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Deliver to', style: fred(20)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on_outlined, color: C.deep, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lookingUp && _line.isEmpty
                            ? 'Finding the address…'
                            : (_line.isEmpty ? 'Drag the map to put the pin on your door' : _line),
                        style: dm(15.5, weight: FontWeight.w700, height: 1.3),
                      ),
                    ),
                    if (_lookingUp)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 2),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: C.deep),
                        ),
                      ),
                  ],
                ),
                if (_distance != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(_distance!, style: dm(13, color: C.grey)),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _unit,
                  textCapitalization: TextCapitalization.characters,
                  style: dm(15.5),
                  decoration: InputDecoration(
                    hintText: 'Unit / buzzer (optional)',
                    hintStyle: dm(15, color: C.grey),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: C.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: C.deep, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Btn(_saving ? 'Saving…' : 'Deliver here', onTap: _saving ? null : _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

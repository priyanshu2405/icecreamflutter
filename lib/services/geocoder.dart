import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place found by address search, or the address under the map pin.
class Place {
  final double lat;
  final double lng;
  final String label; // "10302 City Pkwy, Surrey, BC V3T 4Y8"
  const Place(this.lat, this.lng, this.label);
}

/// Address search and "what's at this spot" using OpenStreetMap's free
/// Nominatim service (no API key). Their usage policy asks for an app name in
/// the User-Agent and no more than about one request a second, so the map
/// screen only looks things up after typing/dragging stops.
class Geocoder {
  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'LickItApp/1.0 (+https://luckit.vads.ca)',
    'Accept-Language': 'en',
  };
  static final _client = http.Client();

  /// Addresses matching [query], nearest to ([nearLat], [nearLng]) first.
  static Future<List<Place>> search(String query, {double? nearLat, double? nearLng}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    final params = {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '6',
      'countrycodes': 'ca',
      if (nearLat != null && nearLng != null) ...{
        // prefer results around the store, but still allow anywhere in Canada
        'viewbox': '${nearLng - 0.6},${nearLat + 0.4},${nearLng + 0.6},${nearLat - 0.4}',
        'bounded': '0',
      },
    };
    try {
      final res = await _client
          .get(Uri.https(_host, '/search', params), headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final list = jsonDecode(res.body);
      if (list is! List) return const [];
      return [
        for (final r in list.cast<Map<String, dynamic>>())
          if (double.tryParse('${r['lat']}') != null && double.tryParse('${r['lon']}') != null)
            Place(double.parse('${r['lat']}'), double.parse('${r['lon']}'), _label(r)),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The street address at a point on the map (null if it can't be found).
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final res = await _client
          .get(
            Uri.https(_host, '/reverse', {
              'lat': '$lat',
              'lon': '$lng',
              'format': 'jsonv2',
              'addressdetails': '1',
              'zoom': '18',
            }),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r is! Map<String, dynamic> || r['error'] != null) return null;
      return _label(r);
    } catch (_) {
      return null;
    }
  }

  /// Short, postal-style label: "123 Main St, Surrey, BC V3T 4Y8".
  static String _label(Map<String, dynamic> r) {
    final a = (r['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    String? s(String k) {
      final v = a[k];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final road = s('road') ?? s('pedestrian') ?? s('footway') ?? s('residential');
    final street = [s('house_number'), road].whereType<String>().join(' ');
    final first = street.isNotEmpty ? street : (r['name'] as String? ?? '');
    final city = s('city') ?? s('town') ?? s('village') ?? s('municipality') ?? s('suburb');
    final iso = s('ISO3166-2-lvl4'); // "CA-BC"
    final prov = iso != null && iso.contains('-') ? iso.split('-').last : s('state');
    final tail = [prov, s('postcode')].whereType<String>().join(' ');
    final parts = [first, city, tail].where((x) => x != null && x.isNotEmpty).cast<String>().toList();
    if (parts.isEmpty) return (r['display_name'] as String? ?? '').split(', ').take(4).join(', ');
    return parts.join(', ');
  }
}

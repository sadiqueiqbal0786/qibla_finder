import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../qibla_controller.dart';
import '../l10n/app_strings.dart';

class CityChoice {
  const CityChoice(this.name, this.latitude, this.longitude, this.country);
  final String name;
  final double latitude, longitude;
  final String? country;
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, required this.controller});
  final QiblaController controller;
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _search = TextEditingController();
  bool _busy = false;
  String? _error;
  List<CityChoice> _results = [];
  /// The offline fallback when there is no GPS fix and no network for the
  /// geocoder, so it has to cover where the users actually are. The Indian
  /// entries follow the states with the largest Muslim populations rather
  /// than the largest cities: Bihar, Uttar Pradesh, Assam and Kashmir were
  /// missing entirely while Bengaluru was present.
  static const _cities = [
    CityChoice('Delhi, India', 28.6139, 77.209, 'IN'),
    CityChoice('Mumbai, India', 19.076, 72.8777, 'IN'),
    CityChoice('Lucknow, India', 26.8467, 80.9462, 'IN'),
    CityChoice('Patna, India', 25.5941, 85.1376, 'IN'),
    CityChoice('Kolkata, India', 22.5726, 88.3639, 'IN'),
    CityChoice('Hyderabad, India', 17.385, 78.4867, 'IN'),
    CityChoice('Bengaluru, India', 12.9716, 77.5946, 'IN'),
    CityChoice('Chennai, India', 13.0827, 80.2707, 'IN'),
    CityChoice('Ahmedabad, India', 23.0225, 72.5714, 'IN'),
    CityChoice('Jaipur, India', 26.9124, 75.7873, 'IN'),
    CityChoice('Ranchi, India', 23.3441, 85.3096, 'IN'),
    CityChoice('Guwahati, India', 26.1445, 91.7362, 'IN'),
    CityChoice('Srinagar, India', 34.0837, 74.7973, 'IN'),
    CityChoice('Karachi, Pakistan', 24.8607, 67.0011, 'PK'),
    CityChoice('Lahore, Pakistan', 31.5204, 74.3587, 'PK'),
    CityChoice('Islamabad, Pakistan', 33.6844, 73.0479, 'PK'),
    CityChoice('Dhaka, Bangladesh', 23.8103, 90.4125, 'BD'),
    CityChoice('Chattogram, Bangladesh', 22.3569, 91.7832, 'BD'),
    CityChoice('Makkah, Saudi Arabia', 21.4225, 39.8262, 'SA'),
    CityChoice('Madinah, Saudi Arabia', 24.4672, 39.6111, 'SA'),
    CityChoice('Dubai, UAE', 25.2048, 55.2708, 'AE'),
    CityChoice('London, UK', 51.5074, -0.1278, 'GB'),
    CityChoice('New York, USA', 40.7128, -74.006, 'US'),
    CityChoice('Singapore', 1.3521, 103.8198, 'SG'),
  ];
  Future<void> _find() async {
    final query = _search.text.trim();
    if (query.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final places = await Geocoding()
          .locationFromAddress(query)
          .timeout(const Duration(seconds: 12));
      final results = <CityChoice>[];
      for (final place in places.take(5)) {
        String? country;
        String label = query;
        try {
          final names = await Geocoding()
              .placemarkFromCoordinates(place.latitude, place.longitude)
              .timeout(const Duration(seconds: 4));
          if (names.isNotEmpty) {
            country = names.first.isoCountryCode;
            label = [
              names.first.locality,
              names.first.administrativeArea,
              names.first.country,
            ].whereType<String>().where((v) => v.isNotEmpty).toSet().join(', ');
            if (label.isEmpty) label = query;
          }
        } catch (_) {
          /* Coordinates remain usable without a place label. */
        }
        results.add(
          CityChoice(label, place.latitude, place.longitude, country),
        );
      }
      if (mounted) {
        setState(() {
          _results = results;
          _error = results.isEmpty
              ? 'No city found. Try adding the country name.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Search unavailable. Choose a suggested city or try again online.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(CityChoice city) async {
    setState(() => _busy = true);
    try {
      await widget.controller.selectLocation(
        label: city.name,
        latitude: city.latitude,
        longitude: city.longitude,
        country: city.country,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save location. Try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Choose a city'))),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: _busy || widget.controller.isRefreshing
              ? null
              : () async {
                  setState(() => _busy = true);
                  await widget.controller.useDeviceLocation();
                  if (context.mounted) Navigator.pop(context);
                },
          icon: const Icon(Icons.my_location),
          label: Text(context.tr('Use device location')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _find(),
          decoration: InputDecoration(
            labelText: context.tr('Search city'),
            border: const OutlineInputBorder(),
            // A tooltip inside a decoration's suffix does not reach the
            // semantics tree, so this button was tappable but announced
            // nothing. Labelling the icon merges onto the button's own node,
            // which a wrapping Semantics does not.
            suffixIcon: IconButton(
              tooltip: context.tr('Search'),
              onPressed: _busy ? null : _find,
              icon: Icon(Icons.search, semanticLabel: context.tr('Search')),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'City search uses your device’s geocoding service. Suggested cities also work offline.',
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(context.tr(_error!)),
          ),
        for (final city in [
          ..._results,
          ..._cities.where(
            (c) =>
                _search.text.isEmpty ||
                c.name.toLowerCase().contains(_search.text.toLowerCase()),
          ),
        ])
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(city.name),
            subtitle: Text(
              '${city.latitude.toStringAsFixed(3)}, ${city.longitude.toStringAsFixed(3)}',
            ),
            onTap: _busy || widget.controller.isRefreshing
                ? null
                : () => _choose(city),
          ),
      ],
    ),
  );
}

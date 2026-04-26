import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../cubits/location_cubit.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        if (state.status == LocationStatus.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return const _LocationView();
      },
    );
  }
}

class _LocationView extends StatefulWidget {
  const _LocationView();

  @override
  State<_LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<_LocationView> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LocationCubit>().state;

    // Default to Houston oilfield area if no location
    final centerLat = state.currentLat ?? 29.7604;
    final centerLng = state.currentLng ?? -95.3698;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              await context.read<LocationCubit>().refreshLocation();
              final s = context.read<LocationCubit>().state;
              if (s.hasLocation) {
                _mapController.move(
                  LatLng(s.currentLat!, s.currentLng!),
                  14, // zoom in closer to show street level
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Moved to your current location'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not get location — check permissions'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            tooltip: 'Go to my location',
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: () => _showAddPinSheet(context),
            tooltip: 'Add rig',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 8,
                onLongPress: (tapPos, latLng) =>
                    _showAddPinAtLocation(context, latLng),
              ),
              children: [
                // OpenStreetMap tile layer — completely free
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nuviolabs.rigsync',
                ),

                // Current location marker
                if (state.hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                            state.currentLat!, state.currentLng!),
                        width: 40,
                        height: 40,
                        child: const _CurrentLocationMarker(),
                      ),
                    ],
                  ),

                // Rig pin markers
                MarkerLayer(
                  markers: state.rigPins.map((pin) {
                    final isSelected =
                        state.selectedPin?.id == pin.id;
                    return Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          context.read<LocationCubit>().selectPin(pin);
                          _mapController.move(
                            LatLng(pin.latitude, pin.longitude),
                            10,
                          );
                        },
                        child: _RigMarker(isSelected: isSelected),
                      ),
                    );
                  }).toList(),
                ),

                // OSM attribution (required by OSM license)
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: state.selectedPin == null
                ? _NoSelectionPanel(pins: state.rigPins)
                : _RigDetailPanel(state: state),
          ),
        ],
      ),
    );
  }

  void _showAddPinSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LocationCubit>(),
        child: const _AddPinSheet(),
      ),
    );
  }

  void _showAddPinAtLocation(BuildContext context, LatLng latLng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<LocationCubit>(),
        child: _AddPinSheet(presetLatLng: latLng),
      ),
    );
  }
}

// ── Custom markers ────────────────────────────────────────────────────────────

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2)
        ],
      ),
    );
  }
}

class _RigMarker extends StatelessWidget {
  const _RigMarker({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSelected ? 36 : 30,
          height: isSelected ? 36 : 30,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE65100)
                : const Color(0xFFE65100).withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.oil_barrel_outlined,
              color: Colors.white, size: 16),
        ),
        Container(
          width: 2,
          height: 8,
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }
}

// ── No selection panel ────────────────────────────────────────────────────────

class _NoSelectionPanel extends StatelessWidget {
  const _NoSelectionPanel({required this.pins});
  final List<RigPin> pins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (pins.isEmpty) {
      return Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant
                    .withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No rigs pinned yet',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a rig, or long-press the map to drop a pin',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Saved rigs',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: pins.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.oil_barrel_outlined,
                      size: 18, color: Color(0xFFE65100)),
                ),
                title: Text(pins[i].name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '${pins[i].latitude.toStringAsFixed(4)}, '
                      '${pins[i].longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: theme.colorScheme.error),
                  onPressed: () => _confirmDeletePin(context, pins[i].id, pins[i].name),
                ),
                onTap: () =>
                    context.read<LocationCubit>().selectPin(pins[i]),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rig detail panel ──────────────────────────────────────────────────────────

class _RigDetailPanel extends StatelessWidget {
  const _RigDetailPanel({required this.state});
  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pin = state.selectedPin!;

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.oil_barrel_outlined,
                      color: Color(0xFFE65100)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pin.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (pin.description != null)
                        Text(pin.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  onPressed: () => _confirmDeletePin(context, pin.id, pin.name),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.travelDistanceKm != null)
              _TravelCard(
                distanceKm: state.travelDistanceKm!,
                durationMin: state.travelDurationMin ?? 0,
              ),
            const SizedBox(height: 12),
            if (state.isLoadingWeather)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator()))
            else if (state.weather != null)
              _WeatherCard(weather: state.weather!)
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                  theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add your OpenWeather API key in location_cubit.dart to see weather',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  const _TravelCard(
      {required this.distanceKm, required this.durationMin});
  final double distanceKm;
  final int durationMin;

  String _fmt(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_car_outlined,
              color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Travel from your location',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                '${distanceKm.toStringAsFixed(0)} km  ·  ${_fmt(durationMin)}',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                width: 52,
                height: 52,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.wb_cloudy_outlined, size: 40),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${weather.temperature.toStringAsFixed(0)}°C',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    weather.description[0].toUpperCase() +
                        weather.description.substring(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    'Updated ${_timeAgo(weather.fetchedAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherStat(
                  icon: Icons.thermostat_outlined,
                  label: 'Feels like',
                  value:
                  '${weather.feelsLike.toStringAsFixed(0)}°C'),
              _WeatherStat(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${weather.humidity}%'),
              _WeatherStat(
                  icon: Icons.air,
                  label: 'Wind',
                  value:
                  '${weather.windSpeed.toStringAsFixed(0)} m/s'),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Add pin sheet ─────────────────────────────────────────────────────────────

class _AddPinSheet extends StatefulWidget {
  const _AddPinSheet({this.presetLatLng});
  final LatLng? presetLatLng;

  @override
  State<_AddPinSheet> createState() => _AddPinSheetState();
}

class _AddPinSheetState extends State<_AddPinSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.presetLatLng != null) {
      _latController.text =
          widget.presetLatLng!.latitude.toStringAsFixed(6);
      _lngController.text =
          widget.presetLatLng!.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (name.isEmpty || lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and valid coordinates')));
      return;
    }
    setState(() => _isLoading = true);
    await context.read<LocationCubit>().addRigPin(
      name: name,
      latitude: lat,
      longitude: lng,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pin a rig location',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Long-press anywhere on the map to auto-fill coordinates.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Rig name',
                hintText: 'e.g. Rig 47 — Permian Basin',
                prefixIcon: const Icon(Icons.oil_barrel_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude',
                      hintText: '29.7604',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude',
                      hintText: '-95.3698',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Gate code: 1234',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_location_alt_outlined),
              label: const Text('Save rig location'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeletePin(
    BuildContext context, String id, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remove rig location?'),
      content: Text(
          '"$name" will be removed from your saved rigs. This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<LocationCubit>().deletePin(id);
  }
}
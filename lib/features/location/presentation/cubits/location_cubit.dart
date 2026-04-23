import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RigPin extends Equatable {
  const RigPin({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': latitude,
    'lng': longitude,
    'description': description,
  };

  factory RigPin.fromJson(Map<String, dynamic> j) => RigPin(
    id: j['id'] as String,
    name: j['name'] as String,
    latitude: (j['lat'] as num).toDouble(),
    longitude: (j['lng'] as num).toDouble(),
    description: j['description'] as String?,
  );

  @override
  List<Object?> get props => [id, name, latitude, longitude, description];
}

class WeatherData extends Equatable {
  const WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.fetchedAt,
  });

  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final DateTime fetchedAt;

  bool get isStale =>
      DateTime.now().difference(fetchedAt).inMinutes > 60;

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'description': description,
    'icon': icon,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'feelsLike': feelsLike,
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
  };

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
    temperature: (j['temperature'] as num).toDouble(),
    description: j['description'] as String,
    icon: j['icon'] as String,
    humidity: j['humidity'] as int,
    windSpeed: (j['windSpeed'] as num).toDouble(),
    feelsLike: (j['feelsLike'] as num).toDouble(),
    fetchedAt: DateTime.fromMillisecondsSinceEpoch(j['fetchedAt'] as int),
  );

  @override
  List<Object?> get props => [
    temperature, description, icon,
    humidity, windSpeed, feelsLike, fetchedAt,
  ];
}

enum LocationStatus { initial, loading, loaded, error }

class LocationState extends Equatable {
  const LocationState({
    this.status = LocationStatus.initial,
    this.rigPins = const [],
    this.selectedPin,
    this.currentLat,
    this.currentLng,
    this.weather,
    this.isLoadingWeather = false,
    this.travelDistanceKm,
    this.travelDurationMin,
    this.errorMessage,
  });

  final LocationStatus status;
  final List<RigPin> rigPins;
  final RigPin? selectedPin;
  final double? currentLat;
  final double? currentLng;
  final WeatherData? weather;
  final bool isLoadingWeather;
  final double? travelDistanceKm;
  final int? travelDurationMin;
  final String? errorMessage;

  bool get hasLocation => currentLat != null && currentLng != null;

  LocationState copyWith({
    LocationStatus? status,
    List<RigPin>? rigPins,
    RigPin? selectedPin,
    double? currentLat,
    double? currentLng,
    WeatherData? weather,
    bool? isLoadingWeather,
    double? travelDistanceKm,
    int? travelDurationMin,
    String? errorMessage,
    bool clearSelected = false,
    bool clearWeather = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      rigPins: rigPins ?? this.rigPins,
      selectedPin: clearSelected ? null : (selectedPin ?? this.selectedPin),
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      weather: clearWeather ? null : (weather ?? this.weather),
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      travelDistanceKm: travelDistanceKm ?? this.travelDistanceKm,
      travelDurationMin: travelDurationMin ?? this.travelDurationMin,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status, rigPins, selectedPin, currentLat, currentLng,
    weather, isLoadingWeather, travelDistanceKm,
    travelDurationMin, errorMessage,
  ];
}

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(const LocationState());

  static const _pinsKey = 'rig_pins';
  static const _weatherCacheKey = 'weather_cache';
  static const _weatherApiKey = 'e71b5e8ab7dafda478d89c0cfcf5a951';

  final Map<String, WeatherData> _weatherCache = {};

  Future<void> initialize() async {
    emit(state.copyWith(status: LocationStatus.loading));
    await _loadPins();
    await _loadWeatherCache();
    await _getCurrentLocation();
    emit(state.copyWith(status: LocationStatus.loaded));
  }

  Future<void> _loadPins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pinsKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      final pins = list
          .map((e) => RigPin.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(rigPins: pins));
    } catch (_) {}
  }

  Future<void> _savePins(List<RigPin> pins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pinsKey, jsonEncode(pins.map((p) => p.toJson()).toList()));
  }

  Future<void> addRigPin({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    final pin = RigPin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      description: description,
    );
    final updated = [...state.rigPins, pin];
    await _savePins(updated);
    emit(state.copyWith(rigPins: updated));
  }

  Future<void> deletePin(String id) async {
    final updated = state.rigPins.where((p) => p.id != id).toList();
    await _savePins(updated);
    _weatherCache.remove(id);
    await _saveWeatherCache();
    emit(state.copyWith(
      rigPins: updated,
      clearSelected: state.selectedPin?.id == id,
      clearWeather: state.selectedPin?.id == id,
    ));
  }

  void selectPin(RigPin pin) {
    emit(state.copyWith(selectedPin: pin));
    _fetchWeatherCached(pin);
    _estimateTravel(pin.latitude, pin.longitude);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      emit(state.copyWith(
        currentLat: position.latitude,
        currentLng: position.longitude,
      ));
    } catch (_) {}
  }

  Future<void> refreshLocation() async {
    await _getCurrentLocation();
    if (state.selectedPin != null) {
      _estimateTravel(
          state.selectedPin!.latitude, state.selectedPin!.longitude);
    }
  }

  Future<void> _loadWeatherCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weatherCacheKey);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        final w =
        WeatherData.fromJson(entry.value as Map<String, dynamic>);
        if (!w.isStale) _weatherCache[entry.key] = w;
      }
    } catch (_) {}
  }

  Future<void> _saveWeatherCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _weatherCache.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_weatherCacheKey, jsonEncode(map));
  }

  Future<void> _fetchWeatherCached(RigPin pin) async {
    final cached = _weatherCache[pin.id];
    if (cached != null && !cached.isStale) {
      emit(state.copyWith(weather: cached));
      return;
    }

    emit(state.copyWith(isLoadingWeather: true));
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
            '?lat=${pin.latitude}&lon=${pin.longitude}'
            '&appid=$_weatherApiKey&units=metric',
      );
      final response =
      await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final main = data['main'] as Map<String, dynamic>;
        final wind = data['wind'] as Map<String, dynamic>;
        final weatherInfo =
        (data['weather'] as List).first as Map<String, dynamic>;

        final weather = WeatherData(
          temperature: (main['temp'] as num).toDouble(),
          description: weatherInfo['description'] as String,
          icon: weatherInfo['icon'] as String,
          humidity: main['humidity'] as int,
          windSpeed: (wind['speed'] as num).toDouble(),
          feelsLike: (main['feels_like'] as num).toDouble(),
          fetchedAt: DateTime.now(),
        );

        _weatherCache[pin.id] = weather;
        await _saveWeatherCache();
        emit(state.copyWith(isLoadingWeather: false, weather: weather));
      } else {
        emit(state.copyWith(isLoadingWeather: false));
      }
    } catch (_) {
      emit(state.copyWith(isLoadingWeather: false));
    }
  }

  void _estimateTravel(double rigLat, double rigLng) {
    if (!state.hasLocation) return;
    final distanceM = Geolocator.distanceBetween(
        state.currentLat!, state.currentLng!, rigLat, rigLng);
    final distanceKm = distanceM / 1000;
    final durationMin = ((distanceKm / 80) * 60).round();
    emit(state.copyWith(
      travelDistanceKm: distanceKm,
      travelDurationMin: durationMin,
    ));
  }
}
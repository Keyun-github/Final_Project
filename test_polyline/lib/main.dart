import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final points = [
      LatLng(-7.26282, 112.73351),
      LatLng(-7.26278, 112.73330),
      LatLng(-7.26275, 112.73317),
      LatLng(-7.26273, 112.73310),
      LatLng(-7.26280, 112.73320),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Polyline Test')),
        body: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-7.2628, 112.7332),
            initialZoom: 16,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.test_polyline',
            ),
            MarkerLayer(markers: [
              Marker(
                point: LatLng(-7.2628, 112.7332),
                child: const Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ]),
            PolylineLayer(polylines: [
              Polyline(
                points: points,
                color: Colors.green,
                strokeWidth: 8,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

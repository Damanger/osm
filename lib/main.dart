import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Open Street Map',
      home: MyHomePage(title: 'Open Street Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? userLocation;
  bool showAdditionalButtons = false;
  final MapController mapController = MapController();

  Future<void> determineAndSetPosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }
    }
    final Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });
    // Forzar la actualización del mapa para centrarse en la nueva ubicación
    mapController.move(userLocation!, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox(
          height: 35,
          child: Text(
            'OpenStreetMap',
            style: TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        toolbarHeight: 30,
      ),
      body: Center(
        child: userLocation == null
            ? ElevatedButton(
          onPressed: () {
            determineAndSetPosition();
          },
          child: const Text('Activar localización'),
        )
            : content(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showAdditionalButtons = !showAdditionalButtons;
          });
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget content() {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController, // Añadir el controlador del mapa
          options: MapOptions(
            center: userLocation!,
            zoom: 10,
            maxZoom: 20,
            minZoom: 1,
          ),
          children: [
            openStreetMapTileLayer,
            MarkerLayer(
              markers: [
                Marker(
                  point: userLocation!,
                  width: 60,
                  height: 60,
                  alignment: Alignment.centerLeft,
                  child: const Icon(
                    Icons.person_pin_circle_sharp,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (showAdditionalButtons)
          Positioned(
            bottom: 120,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    // Lógica para el primer botón adicional
                  },
                  child: Icon(Icons.search),
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {
                    determineAndSetPosition();
                  },
                  child: Icon(Icons.location_pin),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
  subdomains: const ['a', 'b', 'c'],
);

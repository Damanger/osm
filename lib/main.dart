import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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
  LatLng? searchLocation;
  bool showAdditionalButtons = false;
  final MapController mapController = MapController();
  TextEditingController searchController = TextEditingController();

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
    mapController.move(userLocation!, 10);
  }

  Future<void> searchAndMoveToPlace(String query) async {
    List<Location> locations = await locationFromAddress(query);
    if (locations.isNotEmpty) {
      final LatLng newLocation =
      LatLng(locations[0].latitude, locations[0].longitude);
      setState(() {
        searchLocation = newLocation;
      });
      mapController.move(newLocation, 10);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('No se encontró ningún lugar con esta búsqueda.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox(
          height: 35,
          child: Text(
            'OpenStreetMap',
            style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontWeight: FontWeight.bold),
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
          mapController: mapController,
          options: MapOptions(
            center: userLocation!,
            zoom: 10,
            maxZoom: 20,
            minZoom: 1,
          ),
          children: [
            openStreetMapTileLayer,
            if (userLocation != null)
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
            if (searchLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: searchLocation!,
                    width: 60,
                    height: 60,
                    alignment: Alignment.centerLeft,
                    child: const Icon(
                      Icons.location_pin,
                      size: 60,
                      color: Colors.red,
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
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Buscar ubicación'),
                          content: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Ingrese la ubicación',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                searchAndMoveToPlace(searchController.text);
                                Navigator.of(context).pop();
                              },
                              child: Text('Buscar'),
                            ),
                          ],
                        );
                      },
                    );
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


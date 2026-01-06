import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding_package;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_place/google_place.dart';
import 'package:location/location.dart' as location_package;
import 'package:my_app/widgets/map_utils.dart';

class MapScreen extends StatefulWidget {
  const MapScreen(
      {super.key,
      required this.average,
      required this.fuelValue,
      required this.vehicle});

  final double? average;
  final double? fuelValue;
  final String? vehicle;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _startSearchFieldController = TextEditingController();
  final _endSearchFieldController = TextEditingController();
  late GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];
  Timer? _debounce;
  DetailsResult? startPosition;
  DetailsResult? endPosition;
  late FocusNode startFocusNode;
  late FocusNode endFocusNode;
  late CameraPosition _initialPosition;
  GoogleMapController? mapController;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  double distance = 0.0;
  location_package.Location locations = location_package.Location();
  location_package.LocationData? currentLocations;
  StreamSubscription<location_package.LocationData>? locationSubscription;
  double totalDistance = 0;
  double fuelCost = 0;
  final user = FirebaseAuth.instance.currentUser;
  String address = '';
  bool manualSelectionModeEnabled = false;
  bool adLoaded = false;
  bool isLocationListening = false;
  bool isSelectingStart = true;
  late InterstitialAd interstitialAd;

  initInterstitialAd() {
    InterstitialAd.load(
        adUnitId: "ca-app-pub-6918970288444004/4685761565",
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            setState(() {
              adLoaded = true;
            });
          },
          onAdFailedToLoad: (error) {
            interstitialAd.dispose();
          },
        ));
  }

  @override
  void initState() {
    super.initState();
    initInterstitialAd();
    googlePlace = GooglePlace('AIzaSyApFIXs6AJrOi0mecO8cC7fqISQiTn6L6c');
    startFocusNode = FocusNode();
    endFocusNode = FocusNode();
    _initialPosition = const CameraPosition(
      target: LatLng(33.6844, 73.0479),
      zoom: 14,
    );
    _getUserLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    if (isLocationListening) {
      locationSubscription?.cancel();
      isLocationListening = false;
    }
    startFocusNode.dispose();
    endFocusNode.dispose();
    mapController!.dispose();

    super.dispose();
  }

  void autoCompleteSearch(String value) async {
    final result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  // add Polylines..............
  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      width: 4,
      points: polylineCoordinates,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  // Get polylines...............
  _getPolyline() async {
    if (startPosition != null && endPosition != null) {
      polylineCoordinates.clear();

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyApFIXs6AJrOi0mecO8cC7fqISQiTn6L6c', // Replace with your API key
        PointLatLng(
          startPosition!.geometry!.location!.lat!,
          startPosition!.geometry!.location!.lng!,
        ),
        PointLatLng(
          endPosition!.geometry!.location!.lat!,
          endPosition!.geometry!.location!.lng!,
        ),
        travelMode: TravelMode.driving,
        optimizeWaypoints: true,
      );

      if (result.status == 'OK') {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        for (var i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += calculateDistance(
              polylineCoordinates[i].latitude,
              polylineCoordinates[i].longitude,
              polylineCoordinates[i + 1].latitude,
              polylineCoordinates[i + 1].longitude);
        }
        setState(() {
          distance = totalDistance;
        });
        _addPolyLine();
      }
    }
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  // Camera position updator
  void _updateCameraPositionFromStart() {
    if (startPosition != null) {
      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(
            startPosition!.geometry!.location!.lat!,
            startPosition!.geometry!.location!.lng!,
          ),
          zoom: 14,
        );
      });
    }
  }

  void _startLocationUpdates() {
    if (!isLocationListening) {
      locationSubscription = locations.onLocationChanged.listen(
        (location_package.LocationData newLocation) {
          setState(() {
            // Handle location updates here
            currentLocations = newLocation;

            LatLng targetPosition;

            if (startPosition != null) {
              targetPosition = LatLng(
                startPosition!.geometry!.location!.lat!,
                startPosition!.geometry!.location!.lng!,
              );

              // Update the map camera position to follow the start position after a delay
              Timer(const Duration(minutes: 2), () {
                if (mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLng(targetPosition),
                  );
                }
              });
            } else {
              targetPosition = LatLng(
                currentLocations!.latitude!,
                currentLocations!.longitude!,
              );
            }

            // Update the map camera position to follow the user's location immediately if not using the start position
            if (mapController != null && startPosition == null) {
              mapController!.animateCamera(
                CameraUpdate.newLatLng(targetPosition),
              );
            }
          });
        },
      );
      isLocationListening = true;
    }
  }

// Get User Location
  void _getUserLocation() async {
    try {
      location_package.LocationData locationData =
          await locations.getLocation();
      List<geocoding_package.Placemark> placemarks =
          await geocoding_package.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );
      setState(() {
        currentLocations = locationData;

        if (startPosition == null && placemarks.isNotEmpty) {
          geocoding_package.Placemark currentPlacemark = placemarks[0];

          if (currentPlacemark.name != null) {
            address += '${currentPlacemark.name!}, ';
          }
          if (currentPlacemark.subLocality != null) {
            address += '${currentPlacemark.subLocality!}, ';
          }
          if (currentPlacemark.locality != null) {
            address += '${currentPlacemark.locality!}, ';
          }

          startPosition = DetailsResult(
            geometry: Geometry(
              location: Location(
                lat: currentLocations!.latitude!,
                lng: currentLocations!.longitude!,
              ),
            ),
            name: address,
          );

          // Update your UI with the new location details.
          _startSearchFieldController.text = startPosition!.name!;
        }
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

// calculate cost.......
  void _calculateFuelCost() async {
    try {
      if (user != null) {
        final userId = user!.uid;
        fuelCost = (distance / widget.average!) * widget.fuelValue!;
        if (distance == 0) {
          showDialog(
              context: context,
              builder: ((context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    title: const Text(
                      'Invalid  Input',
                      style: TextStyle(fontSize: 20),
                    ),
                    content: const Text(
                      'please Select the location First to Find distance ',
                      style: TextStyle(fontSize: 15),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Ok',
                          ))
                    ],
                  )));
        } else if (distance != 0) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: ((context) => Center(
                  child: AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Text(
                      'Fuel Cost',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(
                              width: 10,
                            ),
                            Image.asset('assets/images/cost.png'),
                            const Text(
                              'Trip Cost:',
                              style: TextStyle(
                                color: Color(0xFFBCBBB9),
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              ' ${fuelCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(
                              width: 10,
                            ),
                            Image.asset('assets/images/distance.png'),
                            const Text(
                              'Distance:',
                              style: TextStyle(
                                color: Color(0xFFBCBBB9),
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              " ${distance.toStringAsFixed(2)} KM",
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                          ],
                        )
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          String startPointText =
                              _startSearchFieldController.text;
                          final userData = {
                            'total Distance': distance.toStringAsFixed(2),
                            'fuelCost':
                                double.parse(fuelCost.toStringAsFixed(2)),
                            'startPoint': startPointText,
                            'endPoint': _endSearchFieldController.text,
                            'date': Timestamp.now(),
                            'vehicle_name': widget.vehicle,
                          };

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('History')
                              .add(userData);
                          setState(() {
                            endPosition = null;
                            startPosition = DetailsResult(
                              geometry: Geometry(
                                location: Location(
                                  lat: currentLocations!.latitude!,
                                  lng: currentLocations!.longitude!,
                                ),
                              ),
                              name: address,
                            );
                            _startSearchFieldController.text =
                                startPosition!.name!;
                            _endSearchFieldController.clear();
                            distance = 0;
                          });
                          Navigator.of(context).pop();

                          if (adLoaded) {
                            interstitialAd.show();
                          }

                          // Close the dialog
                        },
                        child: const Text(
                          'Save',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (adLoaded) {
                            interstitialAd.show();
                          }
                        },
                        child: const Text(
                          'Cancel',
                        ),
                      ),
                    ],
                  ),
                )),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
        ),
      );
    }
  }

  //place mark.....
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final List<geocoding_package.Placemark> placemarks =
          await geocoding_package.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final geocoding_package.Placemark placemark = placemarks.first;
        final StringBuffer addressBuffer = StringBuffer();

        if (placemark.name != null) {
          addressBuffer.write(placemark.name!);
        }
        if (placemark.subLocality != null) {
          if (addressBuffer.isNotEmpty) addressBuffer.write(', ');
          addressBuffer.write(placemark.subLocality!);
        }
        if (placemark.locality != null) {
          if (addressBuffer.isNotEmpty) addressBuffer.write(', ');
          addressBuffer.write(placemark.locality!);
        }

        final String formattedAddress = addressBuffer.toString();
        return formattedAddress.isNotEmpty ? formattedAddress : null;
      }
    } catch (e) {
      print('Error retrieving address: $e');
    }
    return null;
  }

// on map tap select location................
  // Function to handle tapping on the map for selecting the end position
  void _onEndPositionTapped(LatLng tappedLatLng) async {
    if (manualSelectionModeEnabled) {
      final double tappedLatitude = tappedLatLng.latitude;
      final double tappedLongitude = tappedLatLng.longitude;
      final String? address =
          await getAddressFromCoordinates(tappedLatitude, tappedLongitude);

      if (address != null) {
        setState(() {
          _endSearchFieldController.text = address;
          endPosition = DetailsResult(
            geometry: Geometry(
              location: Location(
                lat: tappedLatLng.latitude,
                lng: tappedLatLng.longitude,
              ),
            ),
          );
        });

        // Calculate route if both start and end positions are set
        if (startPosition != null && endPosition != null) {
          await fetchRouteBetweenSelectedPositions();
        }
      }
      manualSelectionModeEnabled = false;
    }
  }

// Function to handle tapping on the map for selecting the start position
  void _onStartPositionTapped(LatLng tappedLatLng) async {
    if (manualSelectionModeEnabled) {
      final double tappedLatitude = tappedLatLng.latitude;
      final double tappedLongitude = tappedLatLng.longitude;
      final String? address =
          await getAddressFromCoordinates(tappedLatitude, tappedLongitude);

      if (address != null) {
        setState(() {
          _startSearchFieldController.text = address;
          startPosition = DetailsResult(
            geometry: Geometry(
              location: Location(
                lat: tappedLatLng.latitude,
                lng: tappedLatLng.longitude,
              ),
            ),
          );
        });

        // Calculate route if both start and end positions are set
        if (startPosition != null && endPosition != null) {
          await fetchRouteBetweenSelectedPositions();
        }
      }
      manualSelectionModeEnabled = false;
    }
  }

// Function to fetch route between selected positions and update polyline
  Future<void> fetchRouteBetweenSelectedPositions() async {
    if (startPosition != null && endPosition != null) {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyApFIXs6AJrOi0mecO8cC7fqISQiTn6L6c',
        PointLatLng(
          startPosition!.geometry!.location!.lat!,
          startPosition!.geometry!.location!.lng!,
        ),
        PointLatLng(
          endPosition!.geometry!.location!.lat!,
          endPosition!.geometry!.location!.lng!,
        ),
        travelMode: TravelMode.driving,
      );

      if (result.status == 'OK') {
        polylineCoordinates.clear();
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        double totalDistance = 0;
        for (var i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += calculateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }
        setState(() {
          distance = totalDistance;
          _addPolyLine();
        });
      }
    }
  }

  void _handleMapTap(LatLng tappedLatLng) {
    if (isSelectingStart) {
      _onStartPositionTapped(tappedLatLng);
    } else {
      _onEndPositionTapped(tappedLatLng);
    }
  }

//buid context .............
  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      if (currentLocations != null)
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(
            currentLocations!.latitude!,
            currentLocations!.longitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
    };

    if (startPosition != null && endPosition != null) {
      markers = {
        Marker(
          markerId: const MarkerId('Start'),
          position: LatLng(
            startPosition!.geometry!.location!.lat!,
            startPosition!.geometry!.location!.lng!,
          ),
        ),
        Marker(
          markerId: const MarkerId('End'),
          position: LatLng(
            endPosition!.geometry!.location!.lat!,
            endPosition!.geometry!.location!.lng!,
          ),
        ),
      };
    }
    // scaffold...........
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Map',
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 300,
            color: const Color(0xFF121212),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: TextField(
                    controller: _startSearchFieldController,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      suffixIcon: _startSearchFieldController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _startSearchFieldController.clear();
                                predictions = [];
                                distance = 0;
                                totalDistance = 0;
                                startPosition = null;
                              },
                              icon: const Icon(Icons.clear_outlined),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF383836),
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xFF383836),
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    autofocus: false,
                    focusNode: startFocusNode,
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 250), () {
                        if (value.isNotEmpty) {
                          autoCompleteSearch(value);
                        } else {
                          setState(() {
                            predictions = [];
                            startPosition = null;
                          });
                        }
                        if (startPosition != null && endPosition != null) {
                          _getPolyline();
                        }
                      });
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isSelectingStart = true;
                          manualSelectionModeEnabled = true;
                        });
                      },
                      icon: const Icon(Icons.pin_drop),
                      label: const Text(
                        'Tap here and Select location on Map',
                        style: TextStyle(fontFamily: "Jua"),
                      )),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: TextField(
                          focusNode: endFocusNode,
                          enabled:
                              _startSearchFieldController.text.isNotEmpty &&
                                  startPosition != null,
                          controller: _endSearchFieldController,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            suffixIcon:
                                _endSearchFieldController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            predictions = [];
                                            _endSearchFieldController.clear();
                                            distance = 0;
                                            totalDistance = 0;
                                            endPosition = null;
                                          });
                                        },
                                        icon: const Icon(Icons.clear_outlined),
                                      )
                                    : null,
                            hintText: 'To :',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                            ),
                            border: const OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          autocorrect: false,
                          autofocus: false,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 150), () {
                              if (value.isNotEmpty) {
                                autoCompleteSearch(value);
                              } else {
                                setState(() {
                                  predictions = [];
                                  endPosition = null;
                                });
                              }

                              if (startPosition != null &&
                                  endPosition != null) {
                                _getPolyline();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF383836),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _calculateFuelCost,
                          child: const Text(
                            'Find Cost',
                            style: TextStyle(
                              color: Color(0xFFBCBBB9),
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          )),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isSelectingStart = false;
                          manualSelectionModeEnabled = true;
                        });
                      },
                      icon: const Icon(Icons.pin_drop),
                      label: const Text(
                        'Tap here and Select location on Map',
                        style: TextStyle(fontFamily: "Jua"),
                      )),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: GoogleMap(
              onTap: _handleMapTap,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              polylines: Set<Polyline>.of(polylines.values),
              initialCameraPosition: _initialPosition,
              markers: Set.from(markers),
              onMapCreated: (GoogleMapController controller) {
                setState(() {
                  mapController = controller;
                });
                Future.delayed(
                  const Duration(milliseconds: 10000),
                  () {
                    if (markers.isNotEmpty) {
                      // Check if a start position is selected
                      if (startPosition != null) {
                        // Update the camera position to the selected start position
                        LatLng startLatLng = LatLng(
                          startPosition!.geometry!.location!.lat!,
                          startPosition!.geometry!.location!.lng!,
                        );
                        controller.moveCamera(
                          CameraUpdate.newLatLng(startLatLng),
                        );
                      }
                      // Animate the camera to fit all markers
                      controller.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          MapUtils.boundsFromLatLngList(
                            markers.map((loc) => loc.position).toList(),
                          ),
                          1,
                        ),
                      );
                      _getPolyline();
                    }
                  },
                );
              },
            ),
          ),
          if (predictions.isNotEmpty)
            DraggableScrollableSheet(
                initialChildSize: 0.5,
                builder: (context, scrollController) {
                  return Container(
                    color: const Color(0xFF121212),
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: predictions.length,
                        itemBuilder: (ctx, index) {
                          return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child:
                                    Icon(Icons.pin_drop, color: Colors.white),
                              ),
                              title: Text(
                                predictions[index].description.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () async {
                                final placeId = predictions[index].placeId!;
                                final details =
                                    await googlePlace.details.get(placeId);
                                if (details != null &&
                                    details.result != null &&
                                    mounted) {
                                  if (startFocusNode.hasFocus ||
                                      startPosition == null) {
                                    setState(() {
                                      FocusScope.of(context)
                                          .requestFocus(startFocusNode);
                                      startPosition = details.result;
                                      _startSearchFieldController.text =
                                          details.result!.name!;
                                      predictions = [];

                                      FocusScope.of(context).unfocus();
                                    });
                                  } else {
                                    endPosition = details.result;
                                    _endSearchFieldController.text =
                                        details.result!.name!;
                                    predictions = [];

                                    FocusScope.of(context).unfocus();
                                    _getPolyline();
                                  }

                                  _updateCameraPositionFromStart();
                                  mapController!.animateCamera(
                                    CameraUpdate.newLatLng(
                                      LatLng(
                                        details
                                            .result!.geometry!.location!.lat!,
                                        details
                                            .result!.geometry!.location!.lng!,
                                      ),
                                    ),
                                  );
                                }
                              });
                        }),
                  );
                }),
        ],
      ),
    );
  }
}

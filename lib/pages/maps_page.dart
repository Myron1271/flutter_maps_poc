import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final Location _locationController = new Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  // point of interests
  // static const LatLng _schoolStrijp = LatLng(51.4515, 5.4534);
  // static const LatLng _schoolR10 = LatLng(51.4511, 5.4798);

  //static const LatLng _homeLocation = LatLng(51.0036, 5.8548);
  LatLng? _currentP;
  bool _isTrackingCamera = true;
  double? _lastZoomLevel;
  LatLng? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) {
      if (_currentP != null) {
        _mapController.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentP!),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: ((GoogleMapController controller) {
                _mapController.complete(controller);
                _lastPanPosition = _currentP;
                controller.getZoomLevel().then((zoomLevel) {
                  _lastZoomLevel = zoomLevel;
                });
                if (_isTrackingCamera) {
                  _cameraToPosition(_currentP!);
                }
              }),
              onCameraMove: (CameraPosition position) {
                if (_lastZoomLevel != null && position.zoom != _lastZoomLevel) {
                  _lastZoomLevel = position.zoom;
                  _isTrackingCamera = false;
                }
                else if (_lastPanPosition != null && (_lastPanPosition!.latitude - position.target.latitude).abs() > 0.001 && (_lastPanPosition!.longitude - position.target.longitude).abs() > 0.001) {
                  _isTrackingCamera = false;
                }
                _lastPanPosition = position.target;
              },                         
              initialCameraPosition:
                  CameraPosition(target: _currentP ?? LatLng(50.9999, 5.8680), zoom: 13),
              markers: {
                Marker(
                    markerId: const MarkerId("_currentLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _currentP!),
                /* Point of interests  
               Marker(
                    markerId: MarkerId("_sourceLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _schoolR10),
                Marker(
                    markerId: MarkerId("_destinationLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _schoolStrijp) 
              */
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isTrackingCamera = !_isTrackingCamera;
            if (_isTrackingCamera) {
              _cameraToPosition(_currentP!);
            }
          });
        },
        child: Icon(
            _isTrackingCamera ? Icons.location_searching : Icons.location_off),
      ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 18);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (_isTrackingCamera &&
              _lastPanPosition != null &&
              (_lastPanPosition!.latitude - currentLocation.latitude!).abs() > 0.001 &&
              (_lastPanPosition!.longitude - currentLocation.longitude!).abs() > 0.001) {
            _isTrackingCamera = false;
          }
          if (_isTrackingCamera) {
            _cameraToPosition(_currentP!);
          }
        });
      }
    });
  }
}
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/common/listeners/map_object_tap_listener.dart';
import 'package:yandex_mapkit/permission_manager.dart';
import 'package:yandex_mapkit/snackbar.dart';
import 'package:yandex_mapkit/utils/extension_utils.dart';

import 'package:yandex_maps_mapkit/init.dart' as init;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import 'package:yandex_maps_mapkit/src/bindings/image/image_provider.dart' as IP;
import 'package:yandex_maps_mapkit/src/mapkit/map/text_style.dart' as TS;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'dart:math' as math;

// import 'package:common/utils/extension_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init.initMapkit(
      apiKey: '2c6fdcaf-35cd-4b05-8c1c-8c186a13c9a8'
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  MapWindow? _mapWindow;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            body: FlutterMapWidget(
              onMapCreated: (mapWindow) => _mapWindow = mapWindow
            )
        )
    );
  }
}

final class FlutterMapWidget extends StatefulWidget {
  final void Function(MapWindow) onMapCreated;
  final VoidCallback? onMapDispose;

  const FlutterMapWidget({
    super.key,
    required this.onMapCreated,
    this.onMapDispose,
  });

  @override
  State<StatefulWidget> createState() => FlutterMapWidgetState();
}

final class FlutterMapWidgetState extends State<FlutterMapWidget> {
  late final AppLifecycleListener _lifecycleListener;

  MapWindow? _mapWindow;
  bool _isMapkitActive = false;
  late final _permissionManager;
  late final UserLocationLayer _userLocationLayer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: YandexMap(
        onMapCreated: _onMapCreated,
        platformViewType: PlatformViewType.Hybrid,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startMapkit();

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _requestPermissionsIfNeeded();
        _startMapkit();
        _setMapTheme();
      },
      onInactive: () {
        _stopMapkit();
      },
    );
    _permissionManager  = PermissionManager(DialogsFactory(_showDialog));

    Future.delayed(Duration(seconds: 1)).then((_) {
      _mapWindow?.map.move(
          const CameraPosition(
              Point(latitude: 43.115429, longitude: 131.885418),
              zoom: 10.0,
              azimuth: 0.0,
              tilt: 0.0
          )
      );
      // setMark();
    });
    Future.delayed(Duration(seconds: 2)).then((_) {
      setMark();
    });
  }

  void _showDialog(
      String descriptionText,
      ButtonTextsWithActions buttonTextsWithActions,
      ) {
    final actionButtons = buttonTextsWithActions.map((button) {
      return TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          button.$2();
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        child: Text(button.$1),
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(descriptionText),
          contentTextStyle: Theme.of(context).textTheme.labelLarge,
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: actionButtons,
        );
      },
    );
  }

  void _requestPermissionsIfNeeded() {
    final permissions = [PermissionType.accessLocation];
    _permissionManager.tryToRequest(permissions);
    _permissionManager.showRequestDialog(permissions);
  }

  @override
  void dispose() {
    _stopMapkit();
    _lifecycleListener.dispose();
    widget.onMapDispose?.call();
    super.dispose();
  }

  void _startMapkit() {
    if (!_isMapkitActive) {
      _isMapkitActive = true;
      mapkit.onStart();
    }
  }

  void setMark() {
    if (_mapWindow == null) return;
    final placemark = _mapWindow!.map.mapObjects.addPlacemark()
      ..geometry = const Point(latitude: 43.115429, longitude: 131.885418)
      ..setText('Vladivostok')
      ..setTextStyle(
          const TS.TextStyle(
            size: 30.0,
            color: Colors.red,
            outlineColor: Colors.white,
            placement: TextStylePlacement.Right,
            offset: 5.0,
          )
      );
    // ..setIcon(IP.ImageProvider.fromImageProvider(const AssetImage("assets/ic_pin.png")));

    print('Placemark:  ${placemark.geometry.latitude}');
    final listener = MapObjectTapListenerImpl(onMapObjectTapped: (MapObject o, Point p) {
      print('Tapped: $p');
      return false;
    });
    placemark.addTapListener(listener);
  }

  void _stopMapkit() {
    if (_isMapkitActive) {
      _isMapkitActive = false;
      mapkit.onStop();
    }
  }

  void _onMapCreated(MapWindow window) {
    window.let((it) {
      widget.onMapCreated(window);
      _mapWindow = it;

      it.map.logo.setAlignment(
        const LogoAlignment(
          LogoHorizontalAlignment.Left,
          LogoVerticalAlignment.Bottom,
        ),
      );
    });
    _requestPermissionsIfNeeded();
    // _userLocationLayer = mapkit.createUserLocationLayer(window)
    //   ..headingEnabled = true
    //   ..setVisible(true)
    //   ..setObjectListener(this);

    _setMapTheme();
  }

  void _setMapTheme() {
    _mapWindow?.map.nightModeEnabled =
        Theme.of(context).brightness == Brightness.dark;
  }

  // @override
  // void onObjectAdded(UserLocationView userLocationView) {
  //   if (_mapWindow == null) return;
  //   _userLocationLayer.setAnchor(
  //     math.Point(_mapWindow!.width() * 0.5, _mapWindow!.height() * 0.5),
  //     math.Point(_mapWindow!.width() * 0.5, _mapWindow!.height() * 0.5),
  //   );
  //
  //   final imageProvider = IP.ImageProvider.fromImageProvider(const AssetImage("assets/ic_pin.png"));
  //   userLocationView.arrow.setIcon(imageProvider);
  //
  //   final pinIcon = userLocationView.pin.useCompositeIcon();
  //
  //   pinIcon.setIcon(
  //     imageProvider,
  //     const IconStyle(
  //       anchor: math.Point(0.0, 0.0),
  //       rotationType: RotationType.Rotate,
  //       zIndex: 0.0,
  //       scale: 0.75,
  //     ),
  //     name: "icon",
  //   );
  //   userLocationView.accuracyCircle.fillColor = Colors.blue.withAlpha(100);
  // }
  //
  // @override
  // void onObjectRemoved(UserLocationView view) {}
  //
  // @override
  // void onObjectUpdated(UserLocationView view, ObjectEvent event) {}
}


// final class MapObjectTapListenerImpl implements MapObjectTapListener {
//
//   @override
//   bool onMapObjectTap(MapObject mapObject, Point point) {
//     showSnackBar(null, "Tapped the placemark: Point(latitude: ${point.latitude}, longitude: ${point.longitude})");
//     return true;
//   }
// }
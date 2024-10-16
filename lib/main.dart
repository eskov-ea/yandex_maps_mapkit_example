import 'package:flutter/material.dart';

import 'package:yandex_maps_mapkit/init.dart' as init;
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/yandex_map.dart';

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
            body: YandexMap(
              onMapCreated: (mapWindow) => _mapWindow = mapWindow
            )
        )
    );
  }
}

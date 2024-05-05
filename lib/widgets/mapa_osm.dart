// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tfm_admin/servicios/gps.dart' as gps;
import 'package:tfm_admin/widgets/mapa_guide.dart' as mapaGuide;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../pages/nomination_search.dart' as nominationSearch;
import 'package:maps_toolkit/maps_toolkit.dart' as mapToolKit;
import 'package:confirm_dialog/confirm_dialog.dart' as confirmDialog;
import 'dart:math';

class MapaOSM extends StatelessWidget {
  MapaOSM({
    Key? key,
    selectedPlaces,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Provider.of<MapOSMProvider>(context).initGPS(context);
    var mapOSMProvider = context.watch<MapOSMProvider>();
    //print("lstLinesFuture.length: ${mapOSMProvider.lstLinesFuture.length}");
    return FlutterMap(
      mapController: Provider.of<MapOSMProvider>(context).mapController,
      options: getMapOptions(context),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        PolylineLayer(
          polylines: mapOSMProvider.lstLines,
        ),
        MarkerLayer(markers: Provider.of<MapOSMProvider>(context).markers),
      ],
    );
  }

  getMapOptions(BuildContext context) {
    var mapOSMProvider = context.read<MapOSMProvider>();
    return MapOptions(
      maxZoom: 18,
      minZoom: 4,
      onPositionChanged: (position, hasGesture) {
        if (hasGesture) {
          mapOSMProvider.gesturing();
        }
      },
      onLongPress: (tapPosition, point) {
        mapOSMProvider.onPunto(context, point);
      },
      center: LatLng(19.384580, -99.118289),
    );
  }
}

class MapOSMProvider with ChangeNotifier {
  int iGesturing = 0;
  String placeDisplayName = "";
  double placeLat = 0;
  double placeLon = 0;
  late final MapController mapController;
  final List<Marker> markers = [];
  List<MarkerType> destinos = [];
  List<LatLngType> lstOriginalLines = [];
  List<Polyline> lstLines = [];
  List<LatLng> lstLinesPast = [];
  List<LatLng> lstLinesPresent = [];
  List<LatLng> lstLinesFuture = [];
  int iLineaCercana = 0;
  num masCerca = 999999;
  num distanceToEndLine = 0;
  int distanceToArrive = 0;
  late gps.GpsProvider gpsProvider;
  late mapaGuide.MapaGuideProvider mapaGuideProvider;
  bool animando = false;
  late TickerProvider vsync;
  int distanciaFaltante = 0;
  int tiempoFaltante = 0;

  MapOSMProvider() {
    mapController = MapController();
  }

  initGPS(BuildContext buildContext) async {
    gpsProvider = buildContext.watch<gps.GpsProvider>();
    mapaGuideProvider = buildContext.read<mapaGuide.MapaGuideProvider>();
    if (await gpsProvider.iniGPS()) {
      await route(buildContext);
      await getNearLine(buildContext);
      await getDistanceTimeToArrive();
      moveCenter(buildContext);
      mapaGuideProvider.notify(buildContext);
    }
  }

  onPunto(BuildContext context, LatLng punto) async {
    if (await confirmDialog.confirm(
      context,
      title: Text("Nuevo destino"),
      content: Text("¿Desea ir a ese punto?"),
      textOK: const Text('Si'),
      textCancel: const Text('No'),
    )) {
      irAlPunto(context, punto);
    }
  }

  irAlPunto(BuildContext context, LatLng punto) async {
    var nominationSearchProviderWatch =
        context.read<nominationSearch.NominationSearchProvider>();
    nominationSearchProviderWatch.selectedPlaces.clear();
    placeDisplayName = "";
    placeLat = punto.latitude;
    placeLon = punto.longitude;
    await getPath(context);
    if (lstOriginalLines.isNotEmpty) {
      createLines(context);
    }
  }

  gesturing() {
    iGesturing = ((1000 / 10) * 5).toInt();
  }

  route(BuildContext buildContext) async {
    var nominationSearchProviderWatch =
        buildContext.read<nominationSearch.NominationSearchProvider>();
    if (nominationSearchProviderWatch.selectedPlaces.isNotEmpty) {
      if (placeDisplayName !=
          nominationSearchProviderWatch.selectedPlaces[0].displayName) {
        placeDisplayName =
            nominationSearchProviderWatch.selectedPlaces[0].displayName;
        placeLat = nominationSearchProviderWatch.selectedPlaces[0].lat;
        placeLon = nominationSearchProviderWatch.selectedPlaces[0].lon;
        getPath(buildContext);
      }
    }
    if (lstOriginalLines.isNotEmpty) {
      createLines(buildContext);
    }
  }

  getPath(BuildContext buildContext) async {
    var latitude = gpsProvider.locationData.latitude;
    var longitude = gpsProvider.locationData.longitude;

    var options = BaseOptions(
      baseUrl: "https://routing.openstreetmap.de",
      connectTimeout: 5000,
      receiveTimeout: 3000,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept-Language': 'es'
      },
    );
    final Map<String, String> queryParameters = <String, String>{
      'geometries': 'geojson',
      'alternatives': 'true',
      'steps': 'true',
      'overview': 'full'
    };
    Dio dio = Dio(options);
    Response response = await dio.get(
        //"/routed-car/route/v1/driving/$longitude,$latitude;$placeLon,$placeLat",
        //"/routed-bike/route/v1/driving/$longitude,$latitude;$placeLon,$placeLat",
        "/routed-foot/route/v1/driving/$longitude,$latitude;$placeLon,$placeLat",
        queryParameters: queryParameters);

    var routes = response.data["routes"];
    var waypoints = response.data["waypoints"];
    if (routes.length > 0) {
      getRoutes(buildContext, routes, waypoints);
    }
  }

  getDistanceTimeToArrive() async {
    int distanciaFaltanteX = 0;
    int tiempoFaltanteX = 0;
    for (int i = iLineaCercana; i < lstOriginalLines.length; i++) {
      distanciaFaltanteX += lstOriginalLines[i].distance.toInt();
      tiempoFaltanteX += lstOriginalLines[i].duration.toInt();
    }
    distanciaFaltante = (distanciaFaltanteX / 1000).floor();
    tiempoFaltante = (tiempoFaltanteX / 60).floor();
  }

  getRoutes(BuildContext buildContext, List routes, List waypoints) async {
    lstOriginalLines.clear();
    double tDistance = 0;
    double tDuration = 0;
    String tSummary = "";
    var route = routes[0];
    var legs = route["legs"];
    var markerDestino = MarkerType(id: "2", name: "destino");
    for (int iLeg = 0; iLeg < legs.length; iLeg++) {
      var leg = legs[iLeg];
      tSummary = leg["summary"];
      tDistance += double.parse(leg["distance"].toString());
      tDuration += double.parse(leg["duration"].toString());
      var steps = leg["steps"];
      for (int iStep = 0; iStep < steps.length; iStep++) {
        var step = steps[iStep];
        String name = step["name"];
        String drivingSide = step["driving_side"];
        String mode = step["mode"];
        double sDistance = double.parse(step["distance"].toString());
        double sDuration = double.parse(step["duration"].toString());
        var coordinates = step["geometry"]["coordinates"];
        var maneuver = step["maneuver"];
        int roundExit = getRoundExit(maneuver, "roundexit");
        String maneuverType = getManeuver(maneuver, "type");
        String maneuverModifier = getManeuver(maneuver, "modifier");
        for (int iCoordinate = 0;
            iCoordinate < coordinates.length;
            iCoordinate++) {
          var coordinate = coordinates[iCoordinate];
          double lng = double.parse(coordinate[0].toString());
          double lat = double.parse(coordinate[1].toString());
          lstOriginalLines.add(LatLngType(
              distance: sDistance,
              duration: sDuration,
              lat: lat,
              lng: lng,
              roundExit: roundExit,
              maneuverType: maneuverType,
              maneuverModifier: maneuverModifier));
          markerDestino.latitud = lat;
          markerDestino.longitud = lng;
          markerDestino.widget = Icon(
            Icons.sports_score,
            color: Colors.green,
          );
          maneuverType = "";
          maneuverModifier = "";
          sDistance = 0;
          sDuration = 0;
        }
      }
      for (int iWayPoints = 0; iWayPoints < waypoints.length; iWayPoints++) {
        var startWayPoint = waypoints[0];
        var endWayPoint = waypoints[1];
        if (placeDisplayName == "") {
          placeDisplayName = endWayPoint["name"];
          var nominationSearchProviderWatch =
              buildContext.read<nominationSearch.NominationSearchProvider>();
          nominationSearchProviderWatch.setSelectedPlace(placeDisplayName);
        }
      }
    }
  }

  String getManeuver(var maneuver, String field) {
    String value = "";
    try {
      if (field == "type") value = maneuver["type"];
      if (field == "modifier") value = maneuver["modifier"];
    } catch (Ex) {
      return value;
    }
    return value;
  }

  int getRoundExit(var maneuver, String field) {
    int value = 0;
    try {
      value = maneuver["exit"];
    } catch (Ex) {
      return value;
    }
    return value;
  }

  calculateCenterPresent() {
    var locationKalman = gpsProvider.getKalmanLocation();
    var latitude = locationKalman.latitude;
    var longitude = locationKalman.longitude;

    num a = gpsProvider.distancePointToLine(
        LatLng(latitude, longitude),
        LatLng(lstLinesPresent[0].latitude, lstLinesPresent[0].longitude),
        LatLng(lstLinesPresent[1].latitude, lstLinesPresent[1].longitude));
    num c = mapToolKit.SphericalUtil.computeDistanceBetween(
        mapToolKit.LatLng(latitude, longitude),
        mapToolKit.LatLng(
            lstLinesPresent[0].latitude, lstLinesPresent[0].longitude));
    num B = mapToolKit.SphericalUtil.computeDistanceBetween(
        mapToolKit.LatLng(
            lstLinesPresent[0].latitude, lstLinesPresent[0].longitude),
        mapToolKit.LatLng(
            lstLinesPresent[1].latitude, lstLinesPresent[1].longitude));
    num b = sqrt(pow(c, 2) - pow(a, 2));
    if (a.isNaN) a = 1;
    if (b.isNaN) b = 1;
    if (B.isNaN) B = 1;
    num fraction = b / B;
    mapToolKit.LatLng pointCenter = mapToolKit.SphericalUtil.interpolate(
        mapToolKit.LatLng(
            lstLinesPresent[0].latitude, lstLinesPresent[0].longitude),
        mapToolKit.LatLng(
            lstLinesPresent[1].latitude, lstLinesPresent[1].longitude),
        fraction);
    distanceToEndLine = B - b;
    return pointCenter;
  }

  //crea arboles = [];
  List<Marker> arboles = [];
  moveCenter(BuildContext buildContext) {
    double rotationangle = 0;
    var pointCenter = LatLng(gpsProvider.locationData.latitude!,
        gpsProvider.locationData.longitude!);
    if (lstLinesPresent.isNotEmpty) {
      mapToolKit.LatLng p = calculateCenterPresent();
      pointCenter = LatLng(p.latitude, p.longitude);
      rotationangle = gpsProvider.anglePointToPoint(
              LatLng(lstLinesPresent[0].latitude, lstLinesPresent[0].longitude),
              LatLng(
                  lstLinesPresent[1].latitude, lstLinesPresent[1].longitude)) +
          0.0;
    }

    var radianAngle = gpsProvider.degreeToRadian(rotationangle - 45);

    markers.clear();
    //add 10 markers around the destination
    if (arboles.isEmpty) {
      for (int i = 0; i < 10; i++) {
        LatLng randomPoint = LatLng(
          pointCenter.latitude + (Random().nextDouble() - 0.5) * 0.01,
          pointCenter.longitude + (Random().nextDouble() - 0.5) * 0.01,
        );
        //random colors for the markers darkgreen, green, lightgreen, orange, red, darkred,brown,coffee,blue,lightblue
        var colors = [
          Colors.green,
          Colors.lightGreen,
          Colors.orange,
          Colors.red,
          Colors.brown,
          Colors.blue,
          Colors.lightBlue
        ];

        var names = [
          "dark green",
          "green",
          "light green",
          "orange",
          "red",
          "dark red",
          "brown",
          "coffee",
          "blue",
          "light blue"
        ];

        int index = Random().nextInt(colors.length);

        var color = colors[index];
        var name = names[index];

        var zoom = mapController.zoom;
        double sizeIcon = 20; //50 / zoom;

        var marker = Marker(
            width: 50,
            height: 50,
            point: randomPoint,
            rotate: false,
            builder: (ctx) => Container(
                width: sizeIcon,
                height: sizeIcon,
                child: Column(children: [
                  Icon(
                    Icons.nature,
                    color: color,
                    size: sizeIcon,
                  ),
                  Container(
                    height: 20,
                    //decorated box curved
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.8)),                    
                    padding: EdgeInsets.all(0),
                      child: Center(
                        child: Text(
                                            name,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 10,color: Colors.white),
                                          ),
                      )),
                ])));
        arboles.add(marker);
      }
    }

    
    try {
      var markerCenter = Marker(
          width: 50,
          height: 50,
          point: pointCenter,
          rotate: false,
          builder: (ctx) => AnimatedContainer(
                duration: Duration(seconds: 1),
                transform: Matrix4.rotationZ(radianAngle),
                transformAlignment: Alignment.center,
                child: Container(
                  width: 50,
                  height: 50,
                  child: Stack(
                    fit: StackFit.expand,
                    children: const [
                      Icon(
                        Icons.near_me_outlined,
                        color: Colors.white,
                        size: 50,
                        shadows: [
                          BoxShadow(
                            blurRadius: 12.0,
                            color: Colors.black,
                          ),
                          BoxShadow(
                            blurRadius: 12.0,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.near_me, //my_location,
                        color: Colors.orange,
                        size: 40,
                      ),
                      Icon(
                        Icons.my_location,
                        color: Colors.black,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ));
      markers.add(markerCenter);
      if (placeLat != 0.0) {
        var markerDestination = Marker(
            width: 50,
            height: 50,
            point: LatLng(placeLat, placeLon),
            rotate: false,
            builder: (ctx) => Icon(
                  Icons.circle,
                  size: 50,
                  color: Colors.red,
                ));
        markers.add(markerDestination);
      }
    markers.addAll(arboles);
      if (iGesturing <= 0) {
        mapController.rotate(-rotationangle.toDouble());
        if (lstLinesPresent.isNotEmpty) {
          var bounds = LatLngBounds();
          bounds.extend(LatLng(
              lstLinesPresent[0].latitude, lstLinesPresent[0].longitude));
          bounds.extend(LatLng(gpsProvider.locationData.latitude!,
              gpsProvider.locationData.longitude!));
          bounds.extend(LatLng(
              lstLinesPresent[0].latitude, lstLinesPresent[0].longitude));
          var zoomX = mapController.centerZoomFitBounds(bounds);
          mapController.move(
              LatLng(pointCenter.latitude, pointCenter.longitude), zoomX.zoom);
        } else {
          mapController.move(
              LatLng(pointCenter.latitude, pointCenter.longitude),
              mapController.zoom);
        }
      }

      if (iGesturing <= 0) {
        print("stop");
      }
      if (iGesturing >= 0) {
        iGesturing--;
      }
    } catch (ex) {
      print(ex);
    }
  }

  getNearLine(BuildContext buildContext) async {
    masCerca = 999999;
    var locationKalman = gpsProvider.getKalmanLocation();
    for (int i = 0; i < lstOriginalLines.length - 2; i++) {
      num distancia = gpsProvider.distancePointToLine(
          LatLng(locationKalman.latitude, locationKalman.longitude),
          LatLng(lstOriginalLines[i].lat, lstOriginalLines[i].lng),
          LatLng(lstOriginalLines[i + 1].lat, lstOriginalLines[i + 1].lng));
      if (distancia < masCerca) {
        iLineaCercana = i;
        masCerca = distancia;
      }
    }
  }

  createLines(BuildContext buildContext) async {
    await getNearLine(buildContext);
    lstLines.clear();
    lstLinesPast = [];
    lstLinesPresent = [];
    lstLinesFuture = [];
    notifyListeners();
    for (int i = 0; i <= iLineaCercana; i++) {
      lstLinesPast
          .add(LatLng(lstOriginalLines[i].lat, lstOriginalLines[i].lng));
    }

    for (int i = iLineaCercana; i <= iLineaCercana + 1; i++) {
      lstLinesPresent
          .add(LatLng(lstOriginalLines[i].lat, lstOriginalLines[i].lng));
    }

    for (int i = iLineaCercana + 1; i < lstOriginalLines.length - 2; i++) {
      lstLinesFuture
          .add(LatLng(lstOriginalLines[i].lat, lstOriginalLines[i].lng));
    }

    lstLines.add(Polyline(
        points: lstLinesFuture,
        strokeWidth: 10.0,
        color: Colors.blue.shade900));
    lstLines.add(Polyline(
        points: lstLinesPresent, strokeWidth: 10.0, color: Colors.red));

    lstLines.add(Polyline(
        points: lstLinesPast, strokeWidth: 10.0, color: Colors.yellow));
  }
}

class MarkerType {
  MarkerType({required this.id, required this.name});
  final String id;
  final String name;
  String description = "";
  late Widget widget;
  late IconData icon;
  double latitud = 0;
  double longitud = 0;
}

class LatLngType {
  LatLngType(
      {required this.lat,
      required this.lng,
      this.maneuverType = "",
      this.maneuverModifier = "",
      this.distance = 0,
      this.duration = 0,
      this.roundExit = 0,
      this.anunciado = 0});
  double lat = 0;
  double lng = 0;
  String maneuverType = "";
  String maneuverModifier = "";
  num distance = 0;
  num duration = 0;
  int anunciado = 0;
  int roundExit = 0;
}

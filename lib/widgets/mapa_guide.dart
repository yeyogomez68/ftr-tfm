
import 'package:flutter/material.dart';
import 'package:tfm_admin/servicios/gps.dart';
import 'package:tfm_admin/widgets/mapa_osm.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mapToolKit;
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapaGuide extends StatelessWidget {
  MapaGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var gpsProvider = context.read<GpsProvider>();
    var mapaGuideProvider = context.read<MapaGuideProvider>();
    var mapOSMProvider = context.watch<MapOSMProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      width: MediaQuery.of(context).size.width,
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: (MediaQuery.of(context).size.width / 2) - 60,
            height: 70,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    mapaGuideProvider.displayText,
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(4, 8), // Shadow position
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  child: mapaGuideProvider.iconArrow,
                  /*
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(gpsProvider.degreeToRadian(0))
                      ..multiply(
                          Matrix4.rotationX(gpsProvider.degreeToRadian(0)))
                      ..multiply(
                          Matrix4.rotationZ(gpsProvider.degreeToRadian(-45))),
                    child: mapaGuideProvider.iconArrow,
                  ),
                  */
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(4, 8), // Shadow position
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: (MediaQuery.of(context).size.width / 2) - 60,
            height: 70,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  child: Text(
                    "en " +
                        mapOSMProvider.distanceToEndLine.toInt().toString() +
                        " metros",
                    style: Theme.of(context).textTheme.titleSmall,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(4, 8), // Shadow position
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapaGuideProvider with ChangeNotifier {
  String voiceTextLast = "";
  String displayText = "Iniciando viaje";
  Widget iconArrow = Icon(
    Icons.straight,
    size: 40,
    color: Colors.black,
  );
  Widget iconStraight = Icon(
    Icons.straight,
    size: 40,
    color: Colors.black,
  );
  Widget iconStop = Icon(
    Icons.stop,
    size: 40,
    color: Colors.black,
  );
  Widget iconSlightRight = Icon(
    Icons.turn_slight_right,
    size: 40,
    color: Colors.black,
  );
  Widget iconSlightLeft = Icon(
    Icons.turn_slight_left,
    size: 40,
    color: Colors.black,
  );
  Widget iconRight = Icon(
    Icons.turn_right,
    size: 40,
    color: Colors.black,
  );
  Widget iconLeft = Icon(
    Icons.turn_left,
    size: 40,
    color: Colors.black,
  );

  late MapOSMProvider mapOSMProvider;
  late GpsProvider gpsProvider;
  late FlutterTts flutterTts;
  int iLineaCercanaAnterior = -1;

  MapaGuideProvider() {
    initText2Speech();
  }

  notify(BuildContext buildContext) async {
    gpsProvider = buildContext.read<GpsProvider>();
    mapOSMProvider = buildContext.read<MapOSMProvider>();
    if (mapOSMProvider.lstLines.isNotEmpty) {
      notifyLine(buildContext);
    }
  }

  notifyLine(BuildContext buildContext) async {
    if (mapOSMProvider.masCerca > 100) {
      instructionPath("OUTROAD");
      await mapOSMProvider.getPath(buildContext);
    } else {
      if (mapOSMProvider.iLineaCercana != iLineaCercanaAnterior) {
        if (mapOSMProvider.lstOriginalLines.length >
            mapOSMProvider.iLineaCercana + 2) {
          String voiceTextAux =
              "${mapOSMProvider.lstOriginalLines[mapOSMProvider.iLineaCercana + 2].maneuverType} / ${mapOSMProvider.lstOriginalLines[mapOSMProvider.iLineaCercana + 2].maneuverModifier}";
          if (mapOSMProvider.distanceToEndLine < 20) {
            instructionPath(voiceTextAux);
            notifyListeners();
          } else {
            instructionPath("STRAIGHT");
          }
        } else {
          instructionPath("ARRIVE");
        }
      }
    }
    soundText2Speech2(displayText);
  }

  instructionPath(String voice2Text) {
    /*
    if (voice2Text.toUpperCase().contains("CONTINUE")) {
      displayText = "Sigue derecho";
      iconArrow = iconStraight;
      return;
    }
    */
    if (voice2Text.toUpperCase().contains("STRAIGHT")) {
      displayText = "Sigue derecho";
      iconArrow = iconStraight;
      return;
    }
    if (voice2Text.toUpperCase().contains("DEPART")) {
      displayText = "Iniciando viaje!";
      iconArrow = iconStraight;
      return;
    }
    if (voice2Text.toUpperCase().contains("OUTROAD")) {
      displayText = "Se ha alejado de la ruta!";
      iconArrow = iconStop;
    }
    if (voice2Text.toUpperCase().contains("ARRIVE")) {
      displayText = "Llegaste!";
      iconArrow = iconStop;
      return;
    }
    if (voice2Text.toUpperCase().contains("TURN") &&
        voice2Text.toUpperCase().contains("RIGHT")) {
      displayText = "Gira a la derecha";
      iconArrow = iconRight;
      return;
    }
    if (voice2Text.toUpperCase().contains("TURN") &&
        voice2Text.toUpperCase().contains("LEFT")) {
      displayText = "Gira a la izquierda";
      iconArrow = iconLeft;
      return;
    }
    if (voice2Text.toUpperCase().contains("RIGHT")) {
      displayText = "Gira a la derecha";
      iconArrow = iconSlightRight;
      return;
    }
    if (voice2Text.toUpperCase().contains("LEFT")) {
      displayText = "Gira a la izquierda";
      iconArrow = iconSlightLeft;
      return;
    }
  }

  initText2Speech() {
    flutterTts = FlutterTts();
    flutterTts.setVolume(1.0);
    flutterTts.setLanguage("es-ES");
  }

  soundText2Speech(String texto) async {
    var result = await flutterTts.speak(texto);
  }

  soundText2Speech2(String texto) async {
    if (texto != voiceTextLast && texto != "") {
      voiceTextLast = texto;
      var result = flutterTts.speak(texto);
      return flutterTts.awaitSpeakCompletion(true);
    }
  }
}

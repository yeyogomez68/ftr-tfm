
import 'package:flutter/material.dart';
import 'package:tfm_admin/widgets/mapa_guide.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:osm_nominatim/osm_nominatim.dart' as osmNominatim;

class NominationSearchForm extends StatelessWidget {
  NominationSearchForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Spacer(),
        !context.watch<NominationSearchProvider>().typingEnabled
            ? GestureDetector(
                onTap: () {
                  context.read<NominationSearchProvider>().initTyping();
                  context.read<MapaGuideProvider>().iLineaCercanaAnterior = -1;
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 150,
                  child: Text(
                    context.read<NominationSearchProvider>().lastWords,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              )
            : SizedBox(
                width: MediaQuery.of(context).size.width - 150,
                child: TextFormField(
                  controller:
                      context.read<NominationSearchProvider>().controller,
                  onChanged: (value) {},
                  onEditingComplete: () {
                    context.read<NominationSearchProvider>().finishTyping();
                  },
                  focusNode:
                      context.read<NominationSearchProvider>().myFocusNode,
                )),
        const Spacer(),
        IconButton(
            iconSize: context
                    .read<NominationSearchProvider>()
                    .speechToText
                    .isListening
                ? 50
                : 40,
            padding: const EdgeInsets.all(0),
            onPressed: () {
              if (context
                  .read<NominationSearchProvider>()
                  .speechToText
                  .isListening) {
                context.read<NominationSearchProvider>().stopListening();
              } else {
                context.read<NominationSearchProvider>().startListening();
              }
            },
            icon: Icon(
                context
                        .read<NominationSearchProvider>()
                        .speechToText
                        .isListening
                    ? Icons.mic
                    : Icons.mic_off,
                color: Colors.red))
      ],
    );
  }
}

class NominationResults extends StatelessWidget {
  NominationResults({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var nominationSearchProvider = context.read<NominationSearchProvider>();
    return Column(
      children: [
        Container(
          height: 40,
          width: double.maxFinite,
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                iconSize: 30,
                icon: Icon(Icons.cancel),
                onPressed: () {
                  nominationSearchProvider.cancel();
                },
              ),
            ],
          ),
        ),
        Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height - 240,
            color: Colors.transparent,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                  reverse: false,
                  itemCount:
                      context.watch<NominationSearchProvider>().places.length,
                  itemBuilder: (BuildContext context, int index) {
                    return showItem(context, index);
                  }),
            )),
      ],
    );
  }

  Future _refreshData() async {}

  showItem(BuildContext context, int index) {
    var nominationSearchProvider = context.read<NominationSearchProvider>();
    return GestureDetector(
      onTap: () {
        nominationSearchProvider.addSelectedPlace(index);
      },
      child: Card(
        color: Theme.of(context).cardColor.withOpacity(.5),
        child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(5),
            child: Text(
              nominationSearchProvider.places[index].displayName,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            )),
      ),
    );
  }
}

class NominationSearchProvider with ChangeNotifier {
  bool typingEnabled = false;
  bool listeningEnabled = false;
  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  String lastWords = "";
  FocusNode myFocusNode = FocusNode();
  late TextEditingController controller = TextEditingController();
  List<dynamic> places = [];
  List<dynamic> selectedPlaces = [];

  NominationSearchProvider() {
    searchWords();
    myFocusNode = FocusNode();
    speechToText = SpeechToText();
    controller = TextEditingController();
    initSpeech();
  }

  void initTyping() async {
    typingEnabled = true;
    listeningEnabled = false;
    myFocusNode.requestFocus();
    selectedPlaces.clear();
    notifyListeners();
  }

  void finishTyping() async {
    searchWords();
  }

  cancel() async {
    selectedPlaces.clear();
    typingEnabled = false;
    listeningEnabled = false;
    lastWords = "";
    controller.text = "";
    searchWords();
  }

  addSelectedPlace(int index) async {
    selectedPlaces.clear();
    selectedPlaces.add(places[index]);
    typingEnabled = false;
    listeningEnabled = false;
    lastWords = places[index].displayName;
    controller.text = "";
    notifyListeners();
  }

  setSelectedPlace(String placeName) async {
    selectedPlaces.clear();
    selectedPlaces.add(placeType(placeName));
    typingEnabled = false;
    listeningEnabled = false;
    lastWords = placeName;
    controller.text = "";
    notifyListeners();
  }

  searchWords() async {
    myFocusNode.unfocus();
    lastWords = controller.text;
    if (lastWords == "") {
      lastWords = "¿A dónde vamos?";
    } else {
      if (lastWords != "¿A dónde vamos?") {
        await searchOsmNominatim(lastWords);
      }
    }
    notifyListeners();
  }

  void initSpeech() async {
    speechEnabled = await speechToText.initialize();
    notifyListeners();
  }

  void startListening() async {
    selectedPlaces.clear();
    lastWords = "";
    typingEnabled = false;
    listeningEnabled = true;
    var locales = await speechToText.locales();
    locales.forEach((element) {
      print("localeId: ${element.localeId}, ${element.name}");
    });
    notifyListeners();
    await speechToText.listen(
        onResult: onSpeechResult,
        localeId: "es-MX",
        listenFor: const Duration(seconds: 5));
    notifyListeners();
  }

  void stopListening() async {
    await speechToText.stop();
    searchWords();
  }

  onSpeechResult(SpeechRecognitionResult result) async {
    lastWords = result.recognizedWords;
    if (speechToText.isNotListening) {
      controller.text = lastWords;
      searchWords();
      notifyListeners();
    }
  }

  searchOsmNominatim(String destino) async {
    places = await osmNominatim.Nominatim.searchByName(
      query: destino,
      limit: 50,
      addressDetails: true,
      language: "es",
      extraTags: true,
      nameDetails: true,
    );
  }
}

class placeType {
  String displayName = "";
  double lat = 0;
  double lon = 0;
  placeType(this.displayName);
}

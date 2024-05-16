import 'package:flutter/material.dart';
import 'package:tfm_admin/widgets/mapa_guide.dart' as mapaGuide;
import 'package:tfm_admin/widgets/mapa_osm.dart';
import 'package:provider/provider.dart';
import '../widgets/mapa_osm.dart' as mapaOSM;
import '../pages/nomination_search.dart' as nominationSearch;
import 'package:tfm_admin/servicios/gps.dart' as gpsProvider;
import 'package:tfm_admin/widgets/mapa_guide.dart' as mapaGuide;
import 'package:tfm_admin/pages/MyHGomePage.dart';

class Mapa extends StatelessWidget {
  const Mapa({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => mapaOSM.MapOSMProvider()),
        ChangeNotifierProvider(create: (_) => mapaGuide.MapaGuideProvider()),
        ChangeNotifierProvider(create: (_) => gpsProvider.GpsProvider()),
        ChangeNotifierProvider(
            create: (_) => nominationSearch.NominationSearchProvider()),
      ],
      builder: (buildContext, child) {
        return Scaffold(
          drawer: drawer(buildContext),
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(children: [
                    buildContent(context),
                    buildHeader(context),
                    buildGuide(context),
                    buildFooter(context),
                    buildNominationResults(context),
                  ]));
            },
          ),
        );
      },
    );
  }

  buildHeader(BuildContext buildContext) {
    var nominationSearchProvider =
        buildContext.read<nominationSearch.NominationSearchProvider>();
    return Positioned(
        top: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
          width: MediaQuery.of(buildContext).size.width,
          height: 100,
          color: Theme.of(buildContext).cardColor.withOpacity(.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {
                    Scaffold.of(buildContext)
                        .openDrawer(); // Activate the drawer
                  },
                  icon: Icon(Icons.menu,
                      size: 40, color: Theme.of(buildContext).primaryColor)),
              Expanded(child: nominationSearch.NominationSearchForm())
            ],
          ),
        ));
  }

  drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Urban Tree Vision'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: const Text('Capturar árboles'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage(
                            categoria: "",
                          )));
            },
          )          
        ],
      ),
    );
  }

  buildGuide(BuildContext buildContext) {
    var nominationSearchProviderWatch =
        buildContext.watch<nominationSearch.NominationSearchProvider>();
    if (nominationSearchProviderWatch.selectedPlaces.isEmpty) {
      return const Positioned(
        top: -100,
        child: SizedBox(
          width: 1,
          height: 1,
        ),
      );
    } else {
      return Positioned(
        top: 100,
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          width: MediaQuery.of(buildContext).size.width,
          height: 70,
          color: Theme.of(buildContext).cardColor.withOpacity(.0),
          child: mapaGuide.MapaGuide(),
        ),
      );
    }
  }

  buildContent(BuildContext buildContext) {
    var nominationSearchProviderWatch =
        buildContext.watch<nominationSearch.NominationSearchProvider>();
    return Positioned(
      top: 0,
      child: Container(
        width: MediaQuery.of(buildContext).size.width,
        height: MediaQuery.of(buildContext).size.height,
        color: Colors.blue,
        child: mapaOSM.MapaOSM(
            selectedPlaces: nominationSearchProviderWatch.selectedPlaces),
      ),
    );
  }

  buildNominationResults(BuildContext buildContext) {
    var nominationSearchProvider =
        buildContext.read<nominationSearch.NominationSearchProvider>();
    var nominationSearchProviderWatch =
        buildContext.watch<nominationSearch.NominationSearchProvider>();
    if ((nominationSearchProvider.typingEnabled ||
            nominationSearchProvider.listeningEnabled) &&
        nominationSearchProviderWatch.selectedPlaces.isEmpty) {
      return Positioned(
        top: 100,
        left: 5,
        child: Container(
          width: MediaQuery.of(buildContext).size.width - 10,
          height: MediaQuery.of(buildContext).size.height - 200,
          color: Theme.of(buildContext).cardColor.withOpacity(.5),
          child: nominationSearch.NominationResults(),
        ),
      );
    } else {
      return const Positioned(
        top: -100,
        child: SizedBox(
          width: 1,
          height: 1,
        ),
      );
    }
  }

  buildFooter(BuildContext context) {
    var mapa = context.watch<mapaOSM.MapOSMProvider>();
    return Positioned(
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 100,
        color: Theme.of(context).cardColor.withOpacity(.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              padding: EdgeInsets.all(5),
              child: Text(
                mapa.distanciaFaltante.toString() + " kms",
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
            Container(
              padding: EdgeInsets.all(5),
              child: Text(
                mapa.tiempoFaltante.toString() + " minutos",
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
    );
  }
}

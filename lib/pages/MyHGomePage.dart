import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tfm_admin/pages/FilePickerPage.dart';
import 'package:tfm_admin/pages/LoginPage.dart';
import 'package:tfm_admin/widgets/CameraButton.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Urban Tree Vision"),
        actions: [
          InkWell(
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginPage()), (route) => false);
            },
            child: const Icon(Icons.login),
          )
        ],
      ),
      floatingActionButton: const CameraButton(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Cargar un archivo de datos'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FilePickerPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

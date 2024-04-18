import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewUserPage extends StatefulWidget {
  const NewUserPage({super.key});

  @override
  State createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  late String email, password;
  final _formKey = GlobalKey<FormState>();
  String error = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo Usuario'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Registro de nuevo usuario",
                  style: TextStyle(color: Colors.black, fontSize: 24)),
            ),
            Offstage(
              offstage: error == '',
              child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("error", style: TextStyle(color: Colors.red))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: fomrRegisterUser(),
            ),
          ],
        ));
  }

  Widget fomrRegisterUser() {
    return Form(
        key: _formKey,
        child: Column(
            children: [buildEmail(), buildPassword(), buildRegisterButton(),]));
  }


  Widget buildEmail() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
      onSaved: (value) {
        email = value!;
      },
    );
  }

  Widget buildPassword() {
    return TextFormField(
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Password'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campos es obligatorio';
        }
        return null;
      },
      onSaved: (value) {
        password = value!;
      },
    );
  }

  Widget buildRegisterButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            UserCredential? userCredential =
                await createUserWithEmailAndPassword(email, password);
            if (userCredential != null) {
              if (userCredential.user != null) {
                await userCredential.user!.sendEmailVerification();
                Navigator.of(context).pop();
              }
            }
          }
        },
        child: const Text('Registrate'),
      ),
    );
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = e.code.toString();
      });
    }
    return null;
  }
}

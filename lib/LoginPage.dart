import 'package:flutter/material.dart';
import 'package:tfm_admin/MyHGomePage.dart';
import "package:firebase_auth/firebase_auth.dart";

class LoginPage extends StatefulWidget {
  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
          title: const Text('Login'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Login",
                  style: TextStyle(color: Colors.black, fontSize: 24)),
            ),
            Offstage(
              offstage: error.isEmpty,
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("error", style: TextStyle(color: Colors.red))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: formLogin(),
            ),
          ],
        ));
  }

  Widget formLogin() {
    return Form(
        key: _formKey,
        child: Column(
            children: [buildEmail(), buildPassword(), buildLoginButton()]));
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

  Widget buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MyHomePage()),
                (route) => false);
          }
        },
        child: const Text('Login'),
      ),
    );
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        setState(() {
          error = 'Usuario no encontrado';
        });
      }
    }
    return Future.error('Error');
  }
}

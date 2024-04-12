import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tfm_admin/MyHGomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfm_admin/NewUserPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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
              offstage: error == '',
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
            children: [buildEmail(), buildPassword(), buildLoginButton(),newUser()]));
  }

  Widget newUser() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const Text('¿Eres Nuevo?'),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const NewUserPage()));
          },
          child: const Text('Registrate'),
        )
      ],
    );

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
            UserCredential? userCredential =
                await signInWithEmailAndPassword(email, password);
            if (userCredential != null) {
              if (userCredential.user != null) {
                if (userCredential.user!.emailVerified) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                      (route) => false);
                } else {
                  setState(() {
                    error = 'Verifica tu correo electronico primero';
                  });
                }
              } else {
                setState(() {
                  error = 'Upsss Paso algo y no sabemos que fue, intenta de nuevo';
                });
              }
            }
          }
        },
        child: const Text('Login'),
      ),
    );
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = 'Error o credenciales invalidas';
      });
    }
  }
}

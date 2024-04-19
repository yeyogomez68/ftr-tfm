import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tfm_admin/pages/MyHGomePage.dart';
import 'package:tfm_admin/pages/NewUserPage.dart';
import 'package:crypto/crypto.dart';

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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Login",
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
              child: formLogin(),
            ),
          ],
        ));
  }

  Widget formLogin() {
    return Form(
        key: _formKey,
        child: Column(
            children: [buildEmail(), 
            buildPassword(), 
            buildLoginButton(),
            newUser(),
            buildOrLine(),
            buildBtnGoogleApple()]));
  }

  Widget buildOrLine() {
    return const Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Divider()),
        Text(' ó '),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget buildBtnGoogleApple() {
    return Column(
      children: [
        SignInButton(
          Buttons.google,
          onPressed: () async {
            await getInGoogle();
            if (FirebaseAuth.instance.currentUser != null) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const MyHomePage()), (Route<dynamic> route) => false);
            }
          },
        ),
        Offstage(
          offstage: !Platform.isIOS,
          child: SignInButton(
            Buttons.apple,
            onPressed: () async {
              await getInApple();
              if (FirebaseAuth.instance.currentUser != null) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const MyHomePage()), (Route<dynamic> route) => false);
              }
            },
          ),
        ),
      ],
    );
  }

  Future<UserCredential> getInGoogle() async { 
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn(); 
    final GoogleSignInAuthentication? googleAuthentication = await googleUser?.authentication;
    final credentials = GoogleAuthProvider.credential(
      accessToken: googleAuthentication?.accessToken,
      idToken: googleAuthentication?.idToken
    );
    return FirebaseAuth.instance.signInWithCredential(credentials);
  }

  Future<UserCredential> getInApple() async { 
    final rawNoce = generateNonce();
    final nonce = sha256ToString(rawNoce);
    final appleCredentials = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: nonce); 
    final authCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredentials.identityToken,
      rawNonce: rawNoce
    );
    return await FirebaseAuth.instance.signInWithCredential(authCredential);
  }

  String sha256ToString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
    } on FirebaseAuthException {
      setState(() {
        error = 'Error o credenciales invalidas';
      });
    }
    return null;
  }
}

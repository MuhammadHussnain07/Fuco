import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_app/screens/forgetpassword.dart';

var islogin = true;
final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _enterEmail = '';
  var _enterPassword = '';
  var _enterUsername = '';
  var passwordVisible = true;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }
    _form.currentState!.save();
    try {
      if (islogin) {
        await _firebase.signInWithEmailAndPassword(
          email: _enterEmail,
          password: _enterPassword,
        );
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enterEmail,
          password: _enterPassword,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enterUsername,
          'email': _enterEmail,
          'google signup': FirebaseAuth.instance.currentUser!.email,
        });
      }
    } on FirebaseAuthException catch (error) {
      String errorMessage = 'Authentication failed';
      if (error.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebase.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: SingleChildScrollView(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(
                children: [
                  SizedBox(
                      height: 100,
                      child: Image.asset('assets/images/Splash Logo.png')),
                  const SizedBox(
                    height: 5,
                  ),
                  SizedBox(
                      height: 30,
                      child: Image.asset('assets/images/Splash Text.png')),
                  Form(
                    key: _form,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          if (!islogin)
                            TextFormField(
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF383836),
                                border: const OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF383836),
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF383836),
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                hintText: "Username",
                                hintStyle: const TextStyle(
                                    color: Color(0xFFE8E7E3), fontSize: 16),
                              ),
                              autocorrect: false,
                              enableSuggestions: false,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.trim().length < 4) {
                                  return 'enter the valid name atleast 4 characters';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enterUsername = value!;
                              },
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF383836),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF383836),
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Color(0xFF383836),
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              hintText: "Email Address",
                              hintStyle: const TextStyle(
                                  color: Color(0xFFE8E7E3), fontSize: 15),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return islogin
                                    ? 'Please enter email address'
                                    : 'Please enter a valid email address ';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterEmail = value!;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          TextFormField(
                            obscureText: passwordVisible,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF383836),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    passwordVisible = !passwordVisible;
                                  });
                                },
                                icon: Icon(
                                  passwordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFFE8E7E3),
                                ),
                              ),
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF383836),
                                  ),
                                  borderRadius: BorderRadius.circular(15)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF383836),
                                  ),
                                  borderRadius: BorderRadius.circular(15)),
                              hintText: "Password",
                              hintStyle: const TextStyle(
                                  color: Color(0xFFE8E7E3), fontSize: 15),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return islogin
                                    ? 'Password is required'
                                    : 'Password must be 6 characters long';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              width: 320,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A8C5B),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(
                                        0, 3), // changes position of shadow
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  child: Text(
                                    islogin ? 'Login' : 'Signup',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (islogin)
                            const Text(
                              '_______________or_______________',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (islogin)
                            GestureDetector(
                              onTap: signInWithGoogle,
                              child: Container(
                                width: 320,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7894D2),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Image.asset('assets/images/google.png'),
                                      const SizedBox(
                                          width: 10), // Adjust as per your need
                                      const Text(
                                        "             Signup with Google",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(
                            height: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            onPressed: () {
                              setState(() {
                                islogin = islogin ? false : true;
                              });
                            },
                            child: Text(
                              islogin
                                  ? 'Create an account'
                                  : 'Already have an account',
                              style: const TextStyle(
                                  color: Color(0xFF7894D2),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            )),
                      ),
                      if (islogin)
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: GestureDetector(
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                  color: Color(0xFFBCBBB9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (ctx) => const ForgotPasswordPage()),
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ]),
          ),
        ));
  }
}

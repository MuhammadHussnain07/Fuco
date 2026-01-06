import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:my_app/screens/history.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:my_app/screens/setting.dart';
import 'package:my_app/screens/vehicle.dart';
import 'package:my_app/widgets/imagepicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ManuScreen extends StatefulWidget {
  const ManuScreen({super.key});

  @override
  State<ManuScreen> createState() => _ManuScreenState();
}

class _ManuScreenState extends State<ManuScreen> {
  File? _selectedImage;
  late User _user;
  late InterstitialAd interstitialAd;
  bool isAdLoaded = false;

  initInterstitialAd() {
    InterstitialAd.load(
        adUnitId: "ca-app-pub-6918970288444004/4685761565",
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            setState(() {
              isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (error) {
            print('Ad failed to load: $error');
            interstitialAd.dispose(); // Dispose the ad if it fails to load
          },
        ));
  }

  void reloadInterstitialAd() {
    interstitialAd.dispose();
    initInterstitialAd();
  }

  @override
  void initState() {
    super.initState();
    initInterstitialAd();
    _user = FirebaseAuth.instance.currentUser!;
    String? userEmail = _user.email;
    print('User email: $userEmail');
  }

  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child(uid)
            .child(fileName);

        final compressedImageBytes =
            await FlutterImageCompress.compressWithFile(
          _selectedImage!.path,
          quality: 90,
        );
        if (compressedImageBytes != null) {
          final uploadTask = storageRef.putData(compressedImageBytes);
          final snapshot = await uploadTask;
          if (snapshot.state == firebase_storage.TaskState.success) {
            final downloadUrl = await snapshot.ref.getDownloadURL();
            print('Image uploaded. Download URL: $downloadUrl');
            await FirebaseFirestore.instance
                .collection('user_images')
                .doc(uid)
                .set({
              'image_url': downloadUrl,
            });
            print('Image URL saved to Firestore');
          } else {
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
            );
          }
        } else {
          print('Image compression failed.');
        }
      }
    }
  }

  int _selectedIndex = 0;
  final List<String> _titles = [
    'Home',
    'Add Vehicle',
    'History',
  ];

  final List<Widget> _tabs = [
    const HomeScreen(),
    const AddVehicle(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF1D1D1D),
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: GNav(
                backgroundColor: const Color(0xFF1D1D1D),
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor: const Color.fromARGB(70, 158, 158, 158),
                gap: 5,
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  if (_selectedIndex == 2) {
                    if (isAdLoaded) {
                      interstitialAd.show();
                      reloadInterstitialAd();
                    }
                  }
                },
                tabs: const [
                  GButton(
                    icon: Icons.home,
                    iconSize: 30,
                  ),
                  GButton(
                    icon: Icons.add,
                    iconSize: 30,
                  ),
                  GButton(
                    icon: Icons.history,
                    iconSize: 30,
                  ),
                ]),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1D1D),
        elevation: 0,
        title: Text(_titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 25,
              color: Colors.white,
            )),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF121212),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              UserImagePicker(
                onSelectedImage: (img) {
                  setState(() {
                    _selectedImage = img;
                  });
                  _uploadImageToFirebase();
                },
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 110),
                child: Text('${_user.email}'),
              ),
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => const SettingScreen()));
                  },
                  icon: const Icon(
                    Icons.settings,
                    color: Color(0xFFBCBBB9),
                  ),
                  label: const Text(
                    'Setting',
                    style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 20),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Share.share(
                        'https://play.google.com/store/apps/details?id=com.ainigmagames.Fuco');
                  },
                  icon: const Icon(
                    Icons.share,
                    color: Color(0xFFBCBBB9),
                  ),
                  label: const Text(
                    'Share',
                    style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 20),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    const link =
                        "https://apps.enigma4d.com/fuco/privacypolicy/";
                    await launch(link);
                  },
                  icon: const Icon(
                    Icons.privacy_tip,
                    color: Color(0xFFBCBBB9),
                  ),
                  label: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFFBCBBB9),
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    const link = "https://apps.enigma4d.com/fuco/#futc";
                    await launch(link);
                  },
                  icon: const Icon(
                    Icons.book,
                    color: Color(0xFFBCBBB9),
                  ),
                  label: const Text(
                    'Terms & condition',
                    style: TextStyle(
                      color: Color(0xFFBCBBB9),
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    label: const Text(
                      'Log out',
                      style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 20),
                    ),
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Color(0xFFBCBBB9),
                    )),
              )
            ],
          ),
        ),
      ),
      body: _tabs[_selectedIndex],
    );
  }
}

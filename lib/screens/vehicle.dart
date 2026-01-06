import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddVehicle extends StatefulWidget {
  const AddVehicle({Key? key}) : super(key: key);

  @override
  State<AddVehicle> createState() => _AddVehicleState();
}

class _AddVehicleState extends State<AddVehicle> {
  final user = FirebaseAuth.instance.currentUser;
  List<String> priceFields = [];
  String selectedPriceField = '';
  double fieldValue = 0.0;
  String make = '';
  String variant = '';
  double? cityAverage;
  double? longAverage;
  double? cityAc;
  double? longAc;

  TextEditingController makeController = TextEditingController();
  TextEditingController variantController = TextEditingController();
  TextEditingController cityAverageController = TextEditingController();
  TextEditingController longAverageController = TextEditingController();
  TextEditingController cityAcController = TextEditingController();
  TextEditingController longAcController = TextEditingController();
  late InterstitialAd interstitialAd;
  bool isAdLoaded = false;
  late SharedPreferences _prefs;
  bool _showPrivacyPolicyDialog = true;

  @override
  void initState() {
    super.initState();
    fetchPriceFields();
    initInterstitialAd();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    bool? hasAgreed = _prefs.getBool('hasAgreedToPrivacyPolicy');
    if (hasAgreed != null && hasAgreed) {
      setState(() {
        _showPrivacyPolicyDialog = false;
      });
    } else {
      // Show the privacy policy dialog automatically
      showPrivacyPolicyDialogIfNeeded();
    }
  }

  void showPrivacyPolicyDialogIfNeeded() {
    if (_showPrivacyPolicyDialog) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Privacy Policy',
          ),
          content: const SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Ainigma Games built the Fuco app as an Ad Supported app. This SERVICE is provided by Ainigma Games at no cost and is intended for use as is.',
                ),
                SizedBox(height: 10),
                Text(
                  'This page is used to inform visitors regarding my policies with the collection, use, and disclosure of Personal Information if anyone decided to use my Service.',
                ),
                SizedBox(height: 10),
                Text(
                  'If you choose to use my Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that I collect is used for providing and improving the Service. I will not use or share your information with anyone except as described in this Privacy Policy.',
                ),
                SizedBox(height: 10),
                Text(
                  'The terms used in this Privacy Policy have the same meanings as in our Terms and Conditions, which are accessible at Terms & Conditions unless otherwise defined in this Privacy Policy.',
                ),
                SizedBox(height: 10),
                Text(
                  'Information Collection and Use',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'For a better experience, while using our Service, I may require you to provide us with certain personally identifiable information, including but not limited to Location, Precise Location, Name, Email, User Id, Pictures, App interactions, Crash logs, Diagnostics, Other app performance data, Diagnostics, Device or other IDs. The information that I request will be retained on your device and is not collected by me in any way.',
                ),
                SizedBox(height: 10),
                Text(
                  'The app does use third-party services that may collect information used to identify you.',
                ),
                SizedBox(height: 10),
                Text(
                  'Link to the privacy policy of third-party service providers used by the app',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Google Play Services',
                ),
                Text(
                  'AdMob',
                ),
                Text(
                  'Google Analytics for Firebase',
                ),
                Text(
                  'Firebase Crashlytics',
                ),
                SizedBox(height: 10),
                Text(
                  'Log Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'I want to inform you that whenever you use my Service, in a case of an error in the app I collect data and information (through third-party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol (“IP”) address, device name, operating system version, the configuration of the app when utilizing my Service, the time and date of your use of the Service, and other statistics.',
                ),
                SizedBox(height: 10),
                Text(
                  'Cookies',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device’s internal memory.',
                ),
                SizedBox(height: 10),
                Text(
                  'This Service does not use these “cookies” explicitly. However, the app may use third-party code and libraries that use “cookies” to collect information and improve their services. You have the option to either accept or refuse these cookies and know when a cookie is being sent to your device. If you choose to refuse our cookies, you may not be able to use some portions of this Service.',
                ),
                SizedBox(height: 10),
                Text(
                  'Service Providers\n'
                  '\n'
                  'I may employ third-party companies and individuals due to the following reasons:\n'
                  '\n'
                  'To facilitate our Service;\n'
                  'To provide the Service on our behalf;\n'
                  'To perform Service-related services; or\n'
                  'To assist us in analyzing how our Service is used.\n'
                  'I want to inform users of this Service that these third parties have access to their Personal Information. The reason is to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.\n'
                  '\n'
                  'Security\n'
                  '\n'
                  'I value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and I cannot guarantee its absolute security.\n'
                  '\n'
                  'Links to Other Sites\n'
                  '\n'
                  'This Service may contain links to other sites. If you click on a third-party link, you will be directed to that site. Note that these external sites are not operated by me. Therefore, I strongly advise you to review the Privacy Policy of these websites. I have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.\n'
                  '\n'
                  'Children’s Privacy\n'
                  '\n'
                  'These Services do not address anyone under the age of 13. I do not knowingly collect personally identifiable information from children under 13 years of age. In the case I discover that a child under 13 has provided me with personal information, I immediately delete this from our servers. If you are a parent or guardian and you are aware that your child has provided us with personal information, please contact me so that I will be able to do the necessary actions.\n'
                  '\n'
                  'Changes to This Privacy Policy\n'
                  '\n'
                  'I may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. I will notify you of any changes by posting the new Privacy Policy on this page.\n'
                  '\n'
                  'This policy is effective as of 2024-01-15\n'
                  '\n'
                  'Contact Us\n'
                  '\n'
                  'If you have any questions or suggestions about my Privacy Policy, do not hesitate to contact me at:\n'
                  'info@enigma4d.com',
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Terms & Conditions:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'By downloading or using the app, these terms will automatically apply to you – you should make sure therefore that you read them carefully before using the app. You’re not allowed to copy or modify the app, any part of the app, or our trademarks in any way. You’re not allowed to attempt to extract the source code of the app, and you also shouldn’t try to translate the app into other languages or make derivative versions. The app itself, and all the trademarks, copyright, database rights, and other intellectual property rights related to it, still belong to Ainigma Games.\n'
                  '\n'
                  'Ainigma Games is committed to ensuring that the app is as useful and efficient as possible. For that reason, we reserve the right to make changes to the app or to charge for its services, at any time and for any reason. We will never charge you for the app or its services without making it very clear to you exactly what you’re paying for.\n'
                  '\n'
                  'The Fuco app stores and processes personal data that you have provided to us, to provide my Service. It’s your responsibility to keep your phone and access to the app secure. We therefore recommend that you do not jailbreak or root your phone, which is the process of removing software restrictions and limitations imposed by the official operating system of your device. It could make your phone vulnerable to malware/viruses/malicious programs, compromise your phone’s security features and it could mean that the Fuco app won’t work properly or at all.\n'
                  '\n'
                  'The app does use third-party services that declare their Terms and Conditions.\n'
                  '\n'
                  'Link to Terms and Conditions of third-party service providers used by the app\n'
                  '\n'
                  'Google Play Services\n'
                  'AdMob\n'
                  'Google Analytics for Firebase\n'
                  'Firebase Crashlytics\n'
                  '\n'
                  'You should be aware that there are certain things that Ainigma Games will not take responsibility for. Certain functions of the app will require the app to have an active internet connection. The connection can be Wi-Fi or provided by your mobile network provider, but Ainigma Games cannot take responsibility for the app not working at full functionality if you don’t have access to Wi-Fi, and you don’t have any of your data allowance left.\n'
                  '\n'
                  'If you’re using the app outside of an area with Wi-Fi, you should remember that the terms of the agreement with your mobile network provider will still apply. As a result, you may be charged by your mobile provider for the cost of data for the duration of the connection while accessing the app, or other third-party charges. In using the app, you’re accepting responsibility for any such charges, including roaming data charges if you use the app outside of your home territory (i.e. region or country) without turning off data roaming. If you are not the bill payer for the device on which you’re using the app, please be aware that we assume that you have received permission from the bill payer for using the app.\n'
                  '\n'
                  'Along the same lines, Ainigma Games cannot always take responsibility for the way you use the app i.e. You need to make sure that your device stays charged – if it runs out of battery and you can’t turn it on to avail the Service, Ainigma Games cannot accept responsibility.\n'
                  '\n'
                  'The Fuel Cost are updated on regular interval, they are not real time. and the cost of travel is an estimation based on current cost, distance estimation and the average of your vehical (provided by you). we do not claim in any way or form that the travel cost we provide is a fact, its an estimation and an educated guess. and Ainigma Games is not responsible for any changes in the estimation and reallife cost.\n'
                  '\n'
                  'With respect to Ainigma Games’s responsibility for your use of the app, when you’re using the app, it’s important to bear in mind that although we endeavor to ensure that it is updated and correct at all times, we do rely on third parties to provide information to us so that we can make it available to you. Ainigma Games accepts no liability for any loss, direct or indirect, you experience as a result of relying wholly on this functionality of the app.\n'
                  '\n'
                  'At some point, we may wish to update the app. The app is currently available on Android – the requirements for the system(and for any additional systems we decide to extend the availability of the app to) may change, and you’ll need to download the updates if you want to keep using the app. Ainigma Games does not promise that it will always update the app so that it is relevant to you and/or works with the Android version that you have installed on your device. However, you promise to always accept updates to the application when offered to you, We may also wish to stop providing the app, and may terminate use of it at any time without giving notice of termination to you. Unless we tell you otherwise, upon any termination, (a) the rights and licenses granted to you in these terms will end; (b) you must stop using the app, and (if needed) delete it from your device.\n'
                  '\n'
                  'Changes to This Terms and Conditions\n'
                  '\n'
                  'I may update our Terms and Conditions from time to time. Thus, you are advised to review this page periodically for any changes. I will notify you of any changes by posting the new Terms and Conditions on this page.\n'
                  '\n'
                  'These terms and conditions are effective as of 2024-01-15\n'
                  '\n'
                  'Contact Us\n'
                  '\n'
                  'If you have any questions or suggestions about my Terms and Conditions, do not hesitate to contact me at:\n'
                  'info@enigma4d.com',
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _prefs.setBool('hasAgreedToPrivacyPolicy', true);
                setState(() {
                  _showPrivacyPolicyDialog = false;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Agree',
              ),
            ),
          ],
        ),
      );
    }
  }

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
            interstitialAd.dispose();
          },
        ));
  }

  Future<void> fetchPriceFields() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('prices').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        priceFields = data.keys.toList();
        selectedPriceField = priceFields.first;
        await fetchPriceValue(selectedPriceField);
        setState(() {});
      }
    } catch (error) {
      print('Error fetching price fields: $error');
    }
  }

  Future<void> fetchPriceValue(String field) async {
    try {
      final fieldSnapshot =
          await FirebaseFirestore.instance.collection('prices').limit(1).get();
      if (fieldSnapshot.docs.isNotEmpty) {
        final data = fieldSnapshot.docs.first.data();
        if (data[field] is int) {
          fieldValue = (data[field] as int).toDouble();
        } else if (data[field] is double) {
          fieldValue = data[field];
        }
        setState(() {});
      }
    } catch (error) {
      print('Error fetching price value: $error');
    }
  }

  void _submitData() async {
    if (make.isEmpty ||
        variant.isEmpty ||
        cityAverage == null ||
        longAverage == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Invalid Input',
            style: TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 240, 88, 77),
            ),
          ),
          content: const Text(
            'Please make sure all fields are valid.',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            )
          ],
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final existingData = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('vehicles')
            .where('make', isEqualTo: make)
            .where('variant', isEqualTo: variant)
            .where('City average', isEqualTo: cityAverage)
            .where('Long average', isEqualTo: longAverage)
            .where('Ac City', isEqualTo: cityAc)
            .where('Ac Long', isEqualTo: longAc)
            .get();

        if (existingData.docs.isNotEmpty) {
          // Show dialog indicating that the data is already saved
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx) => AlertDialog(
              // Your dialog content
              title: const Text(
                "Alert",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 240, 88, 77),
                ),
              ),
              content: const Text(
                "Please make sure all fields are valid",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        makeController.clear();
                        variantController.clear();
                        cityAverageController.clear();
                        longAverageController.clear();
                        cityAcController.clear();
                        longAcController.clear();
                        selectedPriceField = priceFields.first;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "ok",
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Jua',
                      ),
                    ))
              ],
            ),
          );
        } else {
          final userData = {
            'make': make,
            'variant': variant,
            'fuelType': selectedPriceField,
            'fuelValue': fieldValue,
            'City average': cityAverage,
            'Long average': longAverage,
            'Ac City': cityAc,
            'Ac Long': longAc,
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('vehicles')
              .add(userData);

          // Show success message after saving data
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: const Text(
                'Success',
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 15,
                  color: Color.fromARGB(255, 240, 88, 77),
                ),
              ),
              content: const Text(
                'Vehicle data saved successfully. Go to Home screen.',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      makeController.clear();
                      variantController.clear();
                      cityAverageController.clear();
                      longAverageController.clear();
                      cityAcController.clear();
                      longAcController.clear();
                      selectedPriceField = priceFields.first;

                      if (isAdLoaded) {
                        interstitialAd.show();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      }
    } catch (error) {
      print('$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Container(
              width: 320,
              height: 570,
              decoration: ShapeDecoration(
                  color: const Color(0xFF1D1D1D),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: 285,
                      height: 232,
                      decoration: ShapeDecoration(
                          color: const Color(0xFF272727),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Make:',
                                style: TextStyle(
                                  color: Color(0xFFBCBBB9),
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(
                                width: 35,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: makeController,
                                  onChanged: (value) {
                                    make = value;
                                  },
                                  textCapitalization: TextCapitalization.words,
                                  autocorrect: false,
                                  cursorColor: Colors.grey,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Honda',
                                    filled: true,
                                    fillColor: const Color(0xFF383836),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF383836),
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF383836),
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Variant:',
                                style: TextStyle(
                                  color: Color(0xFFBCBBB9),
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: variantController,
                                  onChanged: (value) {
                                    variant = value;
                                  },
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Civic',
                                    filled: true,
                                    fillColor: const Color(0xFF383836),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF383836),
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color(0xFF383836),
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Fuel Type:',
                                style: TextStyle(
                                  color: Color(0xFFBCBBB9),
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Container(
                                  height: 55,
                                  decoration: ShapeDecoration(
                                      color: const Color(0xFF383836),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      )),
                                  child: DropdownButton<String>(
                                    underline: Container(
                                      height: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    value: selectedPriceField,
                                    onChanged: (newValue) async {
                                      setState(() {
                                        selectedPriceField = newValue!;
                                      });
                                      await fetchPriceValue(selectedPriceField);
                                    },
                                    isExpanded: true,
                                    items: priceFields
                                        .map<DropdownMenuItem<String>>(
                                      (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              value,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                        width: 284,
                        height: 265,
                        decoration: ShapeDecoration(
                            color: const Color(0xFF272727),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFF4A8C5B),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Image.asset(
                                        'assets/images/average.png',
                                        color: const Color(0xFFBCBBB9),
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Average',
                                  style: TextStyle(
                                    color: Color(0xFF577552),
                                    fontSize: 20,
                                  ),
                                )
                              ],
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'City:',
                                  style: TextStyle(
                                    color: Color(0xFF7894D2),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  width: 75,
                                ),
                                Text(
                                  'Highway:',
                                  style: TextStyle(
                                    color: Color(0xFF4A8C5B),
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                )
                              ],
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: cityAverageController,
                                    onChanged: (value) {
                                      double? parsedDouble =
                                          double.tryParse(value);
                                      if (parsedDouble != null) {
                                        cityAverage = parsedDouble;
                                      } else {}
                                    },
                                    autocorrect: false,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF383836),
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: longAverageController,
                                    onChanged: (value) {
                                      double? parsedDouble =
                                          double.tryParse(value);
                                      if (parsedDouble != null) {
                                        longAverage = parsedDouble;
                                      } else {}
                                    },
                                    autocorrect: false,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF383836),
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                            const Text(
                              "Averages with Ac:",
                              style: TextStyle(
                                color: Color(0xFFBCBBB9),
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: cityAcController,
                                    onChanged: (value) {
                                      double? parsedDouble =
                                          double.tryParse(value);
                                      if (parsedDouble != null) {
                                        cityAc = parsedDouble;
                                      } else {}
                                    },
                                    autocorrect: false,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF383836),
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: longAcController,
                                    onChanged: (value) {
                                      double? parsedDouble =
                                          double.tryParse(value);
                                      if (parsedDouble != null) {
                                        longAc = parsedDouble;
                                      } else {}
                                    },
                                    autocorrect: false,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF383836),
                                      border: const OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF383836),
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ],
                        )),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF383836),
                          shape: const CircleBorder(),
                        ),
                        onPressed: _submitData,
                        child: Image.asset('assets/images/cor.png.png'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/map.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardData {
  final String title;
  final double content;
  final String imagePath;

  CardData(this.title, this.content, this.imagePath);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<QuerySnapshot> priceFirestore;
  int selectedCardIndex = 0;
  int currentIndex = 0;

  final Map<String, Color> titleColors = {
    'Petrol': const Color(0xFFFAE360),
    'Diesel': const Color(0xFFF48E35),
    'CNG': const Color(0xFF8FBDDF),
    'Hi-Octane': const Color(0xFFF06A8A),
  };

  @override
  void initState() {
    super.initState();
    priceFirestore =
        FirebaseFirestore.instance.collection('prices').snapshots();
    listenToPriceChanges();
    checkDisclosureStatus();
  }

  Future<void> checkDisclosureStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool shown = prefs.getBool('disclosureShown') ?? false;
    if (!shown) {
      // Show the disclosure dialog if it hasn't been shown before
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'Disclosure',
              style: TextStyle(fontFamily: 'jua'),
            ),
            content: const Text(
              'Fuco collects your location data to nevigate you and give you your exect location and show you exectly where you are',
              style: TextStyle(fontFamily: 'jua'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(fontFamily: 'jua'),
                ),
                onPressed: () {
                  markDisclosureAsShown();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> markDisclosureAsShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclosureShown', true);
  }

  void listenToPriceChanges() {
    FirebaseFirestore.instance.collection('prices').snapshots().listen((event) {
      final latestPrices = event.docs.first.data();
      updateFuelValues(latestPrices);
    });
  }

  Future<void> updateFuelValues(Map<String, dynamic> latestPrices) async {
    final vehicleCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('vehicles');

    final vehicles = await vehicleCollection.get();

    for (final vehicle in vehicles.docs) {
      final vehicleData = vehicle.data();
      final fuelType = vehicleData['fuelType'] as String;

      final newFuelValue = latestPrices[fuelType] as double?;
      if (newFuelValue != null) {
        vehicleCollection.doc(vehicle.id).update({'fuelValue': newFuelValue});
      }
    }
  }

  void showCard(int index) {
    setState(() {
      selectedCardIndex = index;
    });
  }

  Widget _buildCard(Map<String, dynamic> vehicleData) {
    String? veri = vehicleData['variant'] as String?;
    double? fuelValue = vehicleData['fuelValue'] as double?;
    double? cityAverage = vehicleData['City average'] as double?;
    String cityAverageText =
        cityAverage != null ? cityAverage.toStringAsFixed(1) : "N/A";
    double? longAverage = vehicleData['Long average'] as double?;
    String longAverageText =
        longAverage != null ? longAverage.toStringAsFixed(1) : "N/A";
    double? cityAc = vehicleData['Ac City'] as double?;
    String cityAcText = cityAc != null ? cityAc.toStringAsFixed(1) : "";
    double? longAc = vehicleData['Ac Long'] as double?;
    String longAcText = longAc != null ? longAc.toStringAsFixed(1) : "";

    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFF1D1D1D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      height: 250,
      width: 350,
      margin: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 3),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${vehicleData['make']}\n',
                          style: const TextStyle(
                            color: Color(0xFF94B3F2),
                            fontSize: 20,
                          ),
                        ),
                        TextSpan(
                          text: '${vehicleData['variant']}',
                          style: const TextStyle(
                            color: Color(0xFFBCBBB9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              ' ${vehicleData['fuelType']}',
              style: const TextStyle(
                color: Color(0xFFBCBBB9),
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 0,
              ),
            ),
            Text(
              '$fuelValue PKR',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFBCBBB9),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Padding(
              padding: EdgeInsets.only(right: 230),
              child: Text('Find cost:'),
            ),
            const SizedBox(
              height: 5,
            ),
            if (longAc == null && cityAc == null)
              const SizedBox(
                height: 40,
              ),
            SingleChildScrollView(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: GestureDetector(
                              onTap: () {
                                checkAndNavigateToMapScreen(
                                    veri, cityAverage, fuelValue);
                              },
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF383836),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/City.png'),
                                      Text(
                                        ' ${cityAverageText}km/l',
                                        style: const TextStyle(
                                            color: Color(0xFF94B3F2),
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(
                          width: 60,
                        ),
                        Padding(
                            padding: const EdgeInsets.only(right: 30),
                            child: GestureDetector(
                              onTap: () {
                                checkAndNavigateToMapScreen(
                                    veri, longAverage, fuelValue);
                              },
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF383836),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset('assets/images/Highway.png'),
                                      Text(
                                        ' ${longAverageText}km/l',
                                        style: const TextStyle(
                                            color: Color(0xFF94B3F2),
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        cityAc != null
                            ? Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: GestureDetector(
                                  onTap: () {
                                    checkAndNavigateToMapScreen(
                                        veri, cityAc, fuelValue);
                                  },
                                  child: Container(
                                    width: 110,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF383836),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                              'assets/images/CityAC.png'),
                                          Text(
                                            ' ${cityAcText}km/l',
                                            style: const TextStyle(
                                                color: Color(0xFF94B3F2),
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ))
                            : const SizedBox(
                                width: 10,
                              ),
                        longAc != null
                            ? const SizedBox(
                                width: 60,
                              )
                            : const SizedBox(
                                width: 0,
                              ),
                        longAc != null
                            ? SizedBox(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 30),
                                    child: GestureDetector(
                                      onTap: () {
                                        checkAndNavigateToMapScreen(
                                            veri, longAc, fuelValue);
                                      },
                                      child: Container(
                                        width: 110,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF383836),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                  'assets/images/HighwayAC.png'),
                                              Text(
                                                ' ${longAcText}km/l',
                                                style: const TextStyle(
                                                    color: Color(0xFF94B3F2),
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                              )
                            : const SizedBox(
                                width: 10,
                              )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Future<void> checkAndNavigateToMapScreen(
      String? veri, double? average, double? fuelValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool shown = prefs.getBool('disclosureShown') ?? false;
    if (!shown) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'Disclosure',
              style: TextStyle(fontFamily: 'jua'),
            ),
            content: const Text(
              'Fuco collects your location data to nevigate you and give you your exect location and show you exectly where you are ',
              style: TextStyle(fontFamily: 'jua'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'OK',
                  style: TextStyle(fontFamily: 'jua'),
                ),
                onPressed: () async {
                  await markDisclosureAsShown();
                  Navigator.of(context).pop();
                  navigateToMapScreen(veri, average, fuelValue);
                },
              ),
            ],
          );
        },
      );
    } else {
      navigateToMapScreen(veri, average, fuelValue);
    }
  }

  Future<void> navigateToMapScreen(
      String? veri, double? average, double? fuelValue) async {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => MapScreen(
        vehicle: veri,
        average: average,
        fuelValue: fuelValue,
      ),
    ));
  }

  List<DocumentSnapshot> vehicleList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SingleChildScrollView(
            child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                width: 375,
                height: 315,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1D1D1D),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: const ShapeDecoration(
                                shape: OvalBorder(),
                                color: Color(0x7FD98982),
                              ),
                              child: const Center(
                                child: Text(
                                  'PKR',
                                  style: TextStyle(
                                    color: Color(0xFFD98982),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Fuel Prices',
                            style: TextStyle(
                              color: Color(0xFFE8E7E3),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      StreamBuilder(
                        stream: priceFirestore,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final documentData = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;

                          final List<CardData> cardListData = [
                            CardData(
                                'Petrol',
                                (documentData['Petrol'] as num?)?.toDouble() ??
                                    0.0,
                                'assets/images/petrol.png'),
                            CardData(
                                'Diesel',
                                (documentData['Diesel '] as num?)?.toDouble() ??
                                    0.0,
                                'assets/images/diesel.png'),
                            CardData(
                                'CNG',
                                (documentData['cng'] as num?)?.toDouble() ??
                                    0.0,
                                'assets/images/cng.png'),
                            CardData(
                                'Hi-Octane',
                                (documentData['Hi-Octane'] as num?)
                                        ?.toDouble() ??
                                    0.0,
                                'assets/images/hi.png'),
                          ];
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (selectedCardIndex != -1)
                                    Card(
                                      margin: const EdgeInsets.all(16.0),
                                      color: const Color(0xFF1D1D1D),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10, right: 10),
                                            child: Text(
                                              cardListData[selectedCardIndex]
                                                  .title,
                                              style: TextStyle(
                                                  color: titleColors[
                                                      cardListData[
                                                              selectedCardIndex]
                                                          .title],
                                                  fontSize: 25),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              '${cardListData[selectedCardIndex].content.toStringAsFixed(2)} /L',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFFBCBBB9)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 15, right: 15),
                                child: Container(
                                  width: 350,
                                  height: 100,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFF272727),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            for (int i = 0;
                                                i < cardListData.length;
                                                i++)
                                              GestureDetector(
                                                onTap: () => showCard(i),
                                                child: SizedBox(
                                                  height: 40,
                                                  width: 40,
                                                  child: Image.asset(
                                                      cardListData[i]
                                                          .imagePath),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            const SizedBox(
                                              width: 2,
                                            ),
                                            for (int i = 0;
                                                i < cardListData.length;
                                                i++)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 5),
                                                child: TextButton(
                                                    onPressed: () =>
                                                        showCard(i),
                                                    child: Text(
                                                      cardListData[i].title,
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFFBCBBB9),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Container(
                  width: 375,
                  height: 280,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF1D1D1D)),
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('vehicles')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              ' Add a vehicle first',
                              style: TextStyle(
                                color: Color(0xFFE8E7E3),
                                fontSize: 15,
                              ),
                            ),
                          );
                        }
                        vehicleList = snapshot.data!.docs;

                        return PageView.builder(
                            itemCount: vehicleList.length,
                            controller: PageController(
                              initialPage: currentIndex,
                              viewportFraction: 1,
                            ),
                            onPageChanged: (index) {
                              setState(() {
                                currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final vehicle = vehicleList[index];
                              final vehicleData =
                                  vehicle.data() as Map<String, dynamic>;
                              return Stack(
                                children: [
                                  _buildCard(vehicleData),
                                  Positioned(
                                    left: 20,
                                    top: 20,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: const ShapeDecoration(
                                        color: Color(0xFF94B3F2),
                                        shape: OvalBorder(),
                                      ),
                                      child:
                                          Image.asset('assets/images/blue.png'),
                                    ),
                                  ),
                                ],
                              );
                            });
                      })),
            )
          ]),
        )));
  }
}

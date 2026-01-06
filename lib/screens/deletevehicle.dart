import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class DeleteVehicleScreen extends StatefulWidget {
  const DeleteVehicleScreen({Key? key}) : super(key: key);

  @override
  State<DeleteVehicleScreen> createState() => _DeleteVehicleScreenState();
}

class _DeleteVehicleScreenState extends State<DeleteVehicleScreen> {
  final TextEditingController cityAverageController = TextEditingController();
  final TextEditingController longAverageController = TextEditingController();
  final TextEditingController cityAcController = TextEditingController();
  final TextEditingController longAcController = TextEditingController();

  bool adLoaded = false;

  late InterstitialAd interstitialAd;

  initInterstitialAd() {
    InterstitialAd.load(
        adUnitId: "ca-app-pub-6918970288444004/4685761565",
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            setState(() {
              adLoaded = true;
            });
          },
          onAdFailedToLoad: (error) {
            interstitialAd.dispose();
          },
        ));
  }

  @override
  void initState() {
    super.initState();
    initInterstitialAd();
  }

  void reloadInterstitialAd() {
    interstitialAd.dispose();
    initInterstitialAd();
  }

  Stream<QuerySnapshot> vehicleData() {
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('vehicles')
          .snapshots();
    } catch (e) {
      print('Error fetching vehicles: $e');
      return const Stream.empty();
    }
  }

  void _updateAverages(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('vehicles')
          .doc(document.id)
          .update({
        'City average': double.parse(cityAverageController.text),
        'Long average': double.parse(longAverageController.text),
        'Ac City': double.parse(cityAcController.text),
        'Ac Long': double.parse(longAcController.text),
      });
    } catch (e) {
      print('Error updating averages: $e');
    }
  }

  void _deleteVehicle(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('vehicles')
          .doc(document.id)
          .delete();
    } catch (e) {
      print('Error deleting vehicle: $e');
    }
  }

  void _showUpdateDialog(DocumentSnapshot document) {
    double? cityAcAverage = document['Ac City'] as double?;
    double? longAcAverage = document['Ac Long'] as double?;
    cityAverageController.text = document['City average'].toString();
    longAverageController.text = document['Long average'].toString();
    cityAcController.text = document['Ac City'].toString();
    longAcController.text = document['Ac Long'].toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121212),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Update Averages',
              style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cityAverageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'City average',
                  labelStyle: TextStyle(color: Color(0xFFBCBBB9), fontSize: 20),
                ),
              ),
              TextField(
                controller: longAverageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Long average',
                    labelStyle:
                        TextStyle(color: Color(0xFFBCBBB9), fontSize: 20)),
              ),
              cityAcAverage != null
                  ? TextField(
                      controller: cityAcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CityAc average',
                        labelStyle:
                            TextStyle(color: Color(0xFFBCBBB9), fontSize: 20),
                      ),
                    )
                  : const SizedBox(),
              longAcAverage != null
                  ? TextField(
                      controller: longAcController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'LongAc average',
                          labelStyle: TextStyle(
                              color: Color(0xFFBCBBB9), fontSize: 20)),
                    )
                  : const SizedBox(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (adLoaded) {
                  interstitialAd.show();
                  reloadInterstitialAd();
                }
                Navigator.pop(context);
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFBCBBB9))),
            ),
            TextButton(
              onPressed: () {
                if (adLoaded) {
                  interstitialAd.show();
                  reloadInterstitialAd();
                }
                _updateAverages(document);
                Navigator.pop(context);
              },
              child: const Text(
                'Update',
                style: TextStyle(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'Delete vehicles',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: vehicleData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> vehicleData =
                  documents[index].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
                  color: const Color(0xFF383836),
                  shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF383836)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Text(
                              vehicleData['make'],
                              style: const TextStyle(
                                  color: Color(0xFFBCBBB9), fontSize: 20),
                            ),
                          ),
                          Text(
                            vehicleData['variant'],
                            style: const TextStyle(
                                color: Color(0xFFBCBBB9), fontSize: 20),
                          ),
                          IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color(0xFFBCBBB9),
                              ),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            const Color(0xFF121212),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18)),
                                        title: const Text(
                                          "Alert!",
                                          style: TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                        content: const Text(
                                          "Are you sure to delete the vehicle",
                                          style: TextStyle(
                                              color: Color(0xFFBCBBB9)),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                _deleteVehicle(
                                                    documents[index]);
                                                Navigator.pop(context);
                                              },
                                              child: const Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              )),
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text(
                                                "cancel",
                                              ))
                                        ],
                                      );
                                    });
                              }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A8C5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _showUpdateDialog(documents[index]),
                        child: const Text('Update average',
                            style: TextStyle(color: Color(0xFFBCBBB9))),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

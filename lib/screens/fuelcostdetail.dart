// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class FuelCostDetails extends StatefulWidget {
  const FuelCostDetails({Key? key}) : super(key: key);

  @override
  State<FuelCostDetails> createState() => _FuelCostDetailsState();
}

class _FuelCostDetailsState extends State<FuelCostDetails> {
  double totalCost = 0.0;
  double dailyCost = 0.0;
  double weeklyCost = 0.0;
  double monthlyCost = 0.0;

  Future<void> showFuelCost() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final historyCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('History');

        final fuelCostCollection = await historyCollection.get();

        final now = DateTime.now();
        final currentDayStart = DateTime(now.year, now.month, now.day);
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        dailyCost = 0.0;

        for (final cost in fuelCostCollection.docs) {
          final costData = cost.data();
          final fuelCost = costData['fuelCost'] as double?;
          final date = costData['date'] as Timestamp?;

          if (fuelCost != null && date != null) {
            final dateValue = date.toDate();

            totalCost += fuelCost;

            if (dateValue.isAfter(currentDayStart)) {
              // Within the last day
              dailyCost += fuelCost;
            }
            if (dateValue.isAfter(sevenDaysAgo)) {
              // Within the last 7 days (weekly)
              weeklyCost += fuelCost;
            }

            if (dateValue.isAfter(thirtyDaysAgo)) {
              // Within the last 30 days (monthly)
              monthlyCost += fuelCost;
            }
          }
        }

        print('Total Cost: $totalCost');
        print('Daily Cost: $dailyCost');
        print('Weekly Cost: $weeklyCost');
        print('Monthly Cost: $monthlyCost');

        if (mounted) {
          // Check if the widget is still mounted before calling setState.
          setState(() {
            totalCost = totalCost;
            dailyCost = dailyCost;
            weeklyCost = weeklyCost;
            monthlyCost = monthlyCost;
          });
        }
      } else {
        print('No user signed in');
      }
    } catch (e) {
      print('Error fetching fuel cost data: $e');
    }
  }

  late BannerAd bannerAd;
  bool isAdLoaded = false;
  var adUnit = "ca-app-pub-6918970288444004/1703594755";
  initBannerAd() {
    bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: adUnit,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            print('Banner Ad failed to load: $error');
            ad.dispose(); // Dispose the ad if it fails to load
            Future.delayed(const Duration(seconds: 30), () {
              bannerAd.load();
            });
          },
        ),
        request: const AdRequest());
    bannerAd.load();
  }

  @override
  void initState() {
    super.initState();
    initBannerAd();
    showFuelCost();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: isAdLoaded
            ? SizedBox(
                height: bannerAd.size.height.toDouble(),
                width: bannerAd.size.width.toDouble(),
                child: AdWidget(ad: bannerAd),
              )
            : const SizedBox(),
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text(
            'Fuel Cost Details',
            style: TextStyle(color: Color(0xFFE8E7E3)),
          ),
          backgroundColor: const Color(0xFF1D1D1D),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 100,
              ),
              Center(
                child: Card(
                  color: const Color(0xFF1D1D1D),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      const Text(
                        '           Total fuel cost you use           ',
                        style: TextStyle(color: Color(0xFFE8E7E3)),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text('PKR: ${totalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color.fromARGB(240, 242, 141, 53),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Card(
                color: const Color(0xFF1D1D1D),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      '             Daily fuel cost you use          ',
                      style: TextStyle(color: Color(0xFFE8E7E3)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('PKR: ${dailyCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color.fromARGB(240, 242, 141, 53),
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Card(
                color: const Color(0xFF1D1D1D),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      '         weekly fuel cost you use        ',
                      style: TextStyle(color: Color(0xFFE8E7E3)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('PKR: ${weeklyCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color.fromARGB(240, 242, 141, 53),
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Card(
                color: const Color(0xFF1D1D1D),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      '        Monthly fuel cost you use       ',
                      style: TextStyle(color: Color(0xFFE8E7E3)),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('PKR: ${monthlyCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color.fromARGB(240, 242, 141, 53),
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

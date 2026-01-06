import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Enumeration for different history intervals
enum HistoryInterval { all, daily, weekly, monthly }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  // Initialize the selected interval to All initially
  HistoryInterval selectedInterval = HistoryInterval.all;

  // Define variables for month and date selection
  int selectedMonth = DateTime.now().month;
  int selectedDay = DateTime.now().day;

  // Function to build Firestore query based on interval, month, and day
  Future<QuerySnapshot> buildHistoryFuture(
      HistoryInterval interval, int month, int day) async {
    DateTime startDate;
    DateTime endDate;

    if (interval == HistoryInterval.all) {
      // Set startDate to the beginning of the year and endDate to the end of the year
      startDate = DateTime(DateTime.now().year, 1, 1);
      endDate = DateTime(DateTime.now().year, 12, 31, 23, 59, 59);
    } else {
      startDate = DateTime(DateTime.now().year, month, day);
      endDate = DateTime(DateTime.now().year, month, day, 23, 59, 59);
    }

    return await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('History')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    // Get the number of days in the selected month
    int daysInMonth = DateTime(DateTime.now().year, selectedMonth + 1, 0).day;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(12, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: selectedMonth == index + 1
                            ? const Color(0xFF333333)
                            : const Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedInterval = HistoryInterval.monthly;
                          selectedMonth = index + 1;
                        });
                      },
                      child: Text(
                        getMonthName(index + 1),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFBCBBB9),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(daysInMonth, (index) {
                  // Calculate the date for the current day
                  DateTime currentDate =
                      DateTime(DateTime.now().year, selectedMonth, index + 1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: selectedDay == index + 1
                            ? const Color(0xFF333333)
                            : const Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedInterval = HistoryInterval.daily;
                          selectedDay = index + 1;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Column(
                            children: [
                              // Placeholder to maintain the layout when the image is not shown
                              const SizedBox(
                                height: 20,
                                width: 20,
                              ),
                              Text(
                                '${index + 1}\n${DateFormat('EEEE').format(currentDate)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFBCBBB9),
                                ),
                              ),
                            ],
                          ),
                          if (selectedDay == index + 1)
                            Positioned(
                              top: -20, // Adjust the position as needed
                              child: Image.asset(
                                'assets/images/dot.png',
                                color: const Color(0xFF121212),
                                height: 50,
                                width: 50,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              // Trigger rebuild when the selected values change
              key: Key('$selectedInterval-$selectedMonth-$selectedDay'),
              future: buildHistoryFuture(
                  selectedInterval, selectedMonth, selectedDay),
              builder: (ctx, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  );
                }
                final travelHistory = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: travelHistory.length,
                  itemBuilder: (ctx, index) {
                    final travelData =
                        travelHistory[index].data() as Map<String, dynamic>;
                    final timestamp = travelData['date'] as Timestamp;
                    final travelDate = timestamp.toDate();

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: const Color(0xFF272727),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text(
                                    'Date:  ${DateFormat.yMMMd().format(travelDate)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFFBCBBB9)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text('Vehicle :',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Jua',
                                          color: Color(0xFFBCBBB9))),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '${travelData['vehicle_name']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFFBCBBB9)),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(
                                    left: 5,
                                    right: 5,
                                  ),
                                  child: Text('From :',
                                      style: TextStyle(
                                          fontFamily: 'Jua',
                                          fontSize: 13,
                                          color: Color(0xFFBCBBB9))),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '${travelData['startPoint']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFFBCBBB9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 5, right: 5),
                                  child: Text('To :',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Jua',
                                          color: Color(0xFFBCBBB9))),
                                ),
                                Text(
                                  '${travelData['endPoint']}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFFBCBBB9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child:
                                      Image.asset('assets/images/distance.png'),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  '${travelData['total Distance']} /KM',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFBCBBB9),
                                  ),
                                ),
                                const SizedBox(
                                  width: 100,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Image.asset('assets/images/cost.png'),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  '${travelData['fuelCost']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFBCBBB9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get month name
  String getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2023, month, 1));
  }
}

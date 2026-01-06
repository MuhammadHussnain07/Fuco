import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/deletevehicle.dart';
import 'package:my_app/screens/fuelcostdetail.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Future<void> deleteAllHistory() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Reference to the "History" collection
        final historyCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('History');
        final querySnapshot = await historyCollection.get();
        if (querySnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No history'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          for (final doc in querySnapshot.docs) {
            doc.reference.delete();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History is deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Setting',
        ),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF121212),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        title: const Text(
                          'Alert',
                          style: TextStyle(color: Colors.red, fontSize: 20),
                        ),
                        content: const Text(
                          'Are you sure to delete all the history',
                          style:
                              TextStyle(fontSize: 15, color: Color(0xFFBCBBB9)),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                deleteAllHistory();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ))),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Cencel',
                              ))
                        ],
                      ));
            },
            icon: const Icon(
              Icons.delete,
              color: Color(0xFFBCBBB9),
            ),
            label: const Text(
              'Clear all history                                                                  ',
              style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 18),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const FuelCostDetails()));
            },
            icon: const Icon(
              Icons.history,
              color: Color(0xFFBCBBB9),
            ),
            label: const Text(
              'Check a history of Fuelcost                                          ',
              style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 18),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const DeleteVehicleScreen()));
            },
            icon: const Icon(
              Icons.edit_document,
              color: Color(0xFFBCBBB9),
            ),
            label: const Text(
              'Delete /Edit Vehicles                                         ',
              style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 18),
            ),
          )
        ],
      ),
    );
  }
}

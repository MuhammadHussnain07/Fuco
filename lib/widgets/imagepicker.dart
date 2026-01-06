import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key, required this.onSelectedImage});
  final void Function(File img) onSelectedImage;

  @override
  State<UserImagePicker> createState() => _UserImagePickerState();
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? file;
  ImagePicker image = ImagePicker();
  String? lastImageUrl;

  void _pickImageCamera() async {
    var img = await image.pickImage(source: ImageSource.camera);
    setState(() {
      if (lastImageUrl != null) {
        DefaultCacheManager().removeFile(lastImageUrl!);
      }
      file = File(img!.path);
    });
    widget.onSelectedImage(file!);
  }

  void _pickImageGallery() async {
    var img = await image.pickImage(source: ImageSource.gallery);
    setState(() {
      if (lastImageUrl != null) {
        DefaultCacheManager().removeFile(lastImageUrl!);
      }
      file = File(img!.path);
    });
    widget.onSelectedImage(file!);
  }

  Future<File> _fetchNetworkImage(String imageUrl) async {
    final file = await DefaultCacheManager().getSingleFile(imageUrl);
    return file;
  }

  Stream<String?> _getImageURLStream(String userId) {
    return FirebaseFirestore.instance
        .collection('user_images')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.exists) {
        final imageUrl = snapshot.get('image_url');
        try {
          final cachedFile = await _fetchNetworkImage(imageUrl);
          lastImageUrl = cachedFile.path;
          return cachedFile.path;
        } catch (e) {
          return lastImageUrl;
        }
      } else {
        return lastImageUrl;
      }
    });
  }

  Future<void> _deleteImage() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;
    try {
      if (lastImageUrl != null) {
        await DefaultCacheManager().removeFile(lastImageUrl!);
        lastImageUrl = null;
      }

      await FirebaseFirestore.instance
          .collection('user_images')
          .doc(uid)
          .delete();
    } catch (error) {
      print('Error deleting profile photo: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    return Column(
      children: [
        const SizedBox(
          height: 20,
        ),
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: const Text(
                            'Alert',
                            style: TextStyle(
                                color: Color.fromARGB(255, 223, 100, 91),
                                fontSize: 20),
                          ),
                          content: const Text(
                            'Are you sure to Delete the Photo?',
                            style: TextStyle(fontSize: 15),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  _deleteImage();
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                )),
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
              icon: const Icon(Icons.delete)),
        ),
        StreamBuilder<String?>(
          stream: _getImageURLStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError ||
                (snapshot.hasData && snapshot.data == null)) {
              if (lastImageUrl != null) {
                return CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: FileImage(File(lastImageUrl!)),
                );
              } else {
                return const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color.fromARGB(34, 158, 158, 158),
                  child: Icon(
                    Icons.person_sharp,
                    size: 100,
                    color: Color(0xFFBCBBB9),
                  ),
                );
              }
            } else if (snapshot.hasData && snapshot.data != null) {
              final imageUrl = snapshot.data!;
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage: FileImage(File(imageUrl)),
              );
            } else {
              return const CircleAvatar(
                radius: 60,
                backgroundColor: Color.fromARGB(34, 158, 158, 158),
                child: Icon(
                  Icons.person_sharp,
                  size: 100,
                  color: Color(0xFFBCBBB9),
                ),
              );
            }
          },
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383836),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _pickImageGallery,
                icon: const Icon(Icons.image, color: Color(0xFFBCBBB9)),
                label: const Text(
                  ' Gallery',
                  style: TextStyle(
                    color: Color(0xFFBCBBB9),
                    fontSize: 15,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383836),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _pickImageCamera,
                icon: const Icon(
                  Icons.camera,
                  color: Color(0xFFBCBBB9),
                ),
                label: const Text(
                  'Camera',
                  style: TextStyle(color: Color(0xFFBCBBB9), fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

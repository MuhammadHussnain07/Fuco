import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  _launchStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.ainigmagames.Fuco';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Update"),
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
                ' New update is available click the button and update the app'),
            const SizedBox(
              height: 50,
            ),
            Center(
                child: ElevatedButton(
                    onPressed: _launchStore, child: const Text("Play store"))),
          ],
        ));
  }
}

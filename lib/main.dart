import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saahas/data.dart';
import 'package:saahas/l.dart';

void main() {
  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => MainState();
}

class MainState extends State<Main> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              prefix: Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.search),
              ),
            ),
            style: GoogleFonts.quicksand(
              color: Colors.black,
            ),
            onSubmitted: (value) {
              generate(value, updateUI);
            },
          ),
        ),
        body: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: renderTextWithLatex(
                conversations[index]['message'],
                GoogleFonts.quicksand(color: Colors.black, fontSize: 20),
              ),
              subtitle: const Divider(),
            );
          },
        ),
      ),
    );
  }

  void updateUI() {
    setState(() {});
  }
}

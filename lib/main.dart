import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saahas/data.dart';
import 'package:saahas/l.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          setState(() {
            _isListening = status == 'listening';
          });
        },
        onError: (errorNotification) {
          setState(() {
            _isListening = false;
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.blueGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 32, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        hintText: "Type or speak...",
                        hintStyle: GoogleFonts.quicksand(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      onSubmitted: (value) {
                        generate(value, updateUI);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _listen,
                    child: CircleAvatar(
                      backgroundColor: _isListening ? Colors.redAccent : Colors.blueAccent,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final message = conversations[index]['message'];
                  final isUser = index % 2 == 0;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.black : Colors.blueAccent.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            offset: const Offset(2, 2),
                            blurRadius: 5,
                          )
                        ],
                      ),
                      child: renderTextWithLatex(
                        message,
                        GoogleFonts.quicksand(
                          color: isUser ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateUI() {
    setState(() {});
  }
}

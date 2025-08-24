import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:ollama/ollama.dart';

Ollama _ollama = Ollama();
String continuous = "";
List<Map<String, dynamic>> conversations = [];

void main() {
  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;

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

  void updateUI() => setState(() {});

  Future<void> generate(String query, Function updateUI) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);

    conversations.add({"actor": "user", "message": query});
    continuous = "";
    conversations.add({"actor": "generator", "message": continuous});
    updateUI();

    try {
      final stream = _ollama.generate(query, model: "phi3");

      await for (final chunk in stream) {
        continuous += chunk.text;
        conversations.last['message'] = continuous;
        updateUI();
      }
    } catch (e) {
      continuous = 'Error: $e';
      conversations.last['message'] = continuous;
      updateUI();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF181A1B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF181A1B),
              floating: true,
              snap: true,
              toolbarHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Agentic',
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 7),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 98, 138, 150),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky TextField (always visible)
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _InputFieldDelegate(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF232526),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Type or speak...",
                        hintStyle: GoogleFonts.quicksand(color: Colors.grey, fontSize: 18),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18),
                      onSubmitted: (value) {
                        if (!_isLoading) {
                          generate(value, updateUI);
                          _textController.clear();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Floating icons (hide on scroll)
            SliverPersistentHeader(
              pinned: false,
              floating: true,
              delegate: _IconsDelegate(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon:
                            Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                        onPressed: _listen,
                      ),
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, color: Color.fromARGB(255, 98, 138, 150)),
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_textController.text.trim().isNotEmpty) {
                                  generate(_textController.text, updateUI);
                                  _textController.clear();
                                }
                              },
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),

            // Chat messages list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final message = conversations[index]['message'];
                  final isUser = conversations[index]['actor'] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.black : const Color.fromARGB(255, 98, 138, 150),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        message,
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
                childCount: conversations.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputFieldDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _InputFieldDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _InputFieldDelegate oldDelegate) => false;
}

class _IconsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _IconsDelegate({required this.child});

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _IconsDelegate oldDelegate) => false;
}

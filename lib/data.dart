import 'package:ollama/ollama.dart';

Ollama _ollama = Ollama();
String continuous = "";
List conversations = [];

void generate(dynamic query, Function updateUI) async {
  conversations.add({"actor": "user", "message": query});
  continuous = "";
  conversations.add({"actor": "generator", "message": continuous});

  updateUI();

  try {
    final stream = _ollama.generate(
      query,
      model: "phi3",
    );

    await for (final chunk in stream) {
      continuous += chunk.text;
      conversations.last['message'] = continuous;

      updateUI();
    }
  } catch (e) {
    continuous = 'Error: $e';
    updateUI();
  }
}

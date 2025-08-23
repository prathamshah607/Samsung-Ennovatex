import 'package:http/http.dart' as http;
import 'dart:convert';

String continuous = "";
List conversations = [];

void generate(String query, Function updateUI) async {
  // Add user message
  conversations.add({"actor": "user", "message": query});
  
  // Initialize generator message
  continuous = "";
  conversations.add({"actor": "generator", "message": continuous});
  
  updateUI();

  try {
    // Send query to local Python backend running Phi-3 Mini
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query}),
    );

    if (response.statusCode == 200) {
      // Update generator message with backend response
      continuous = jsonDecode(response.body)["response"];
      conversations.last['message'] = continuous;
      updateUI();
    } else {
      continuous = 'Error: ${response.statusCode}';
      updateUI();
    }
  } catch (e) {
    continuous = 'Error: $e';
    updateUI();
  }
}

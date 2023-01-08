import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

// Please fill in your own API key
const apiKey = '';

Future<void> getGPT3Completion(
  String apiKey,
  String prompt,
  String suffix,
  Future<void> Function(String)
      onData, // callback function to handle streaming data
  {
  int maxTokens = 200,
  double temperature = .3,
  bool stream = true,
}) async {
  final data = {
    'prompt': prompt,
    'suffix': suffix,
    'max_tokens': maxTokens,
    'temperature': temperature,
    'stream': stream, // set stream parameter to true
  };

  final headers = {
    'Authorization': apiKey,
    'Content-Type': 'application/json',
  };
  final request = http.Request(
    'POST',
    Uri.parse('https://api.openai.com/v1/engines/text-davinci-003/completions'),
  );
  request.body = json.encode(data);
  request.headers.addAll(headers);

  final httpResponse = await request.send();

  if (httpResponse.statusCode == 200) {
    await for (final chunk in httpResponse.stream) {
      var result = utf8.decode(chunk).split('text": "');
      var text = '';
      if (result.length > 1) {
        result = result[1].split('",');
        if (result.isNotEmpty) {
          text = result.first;
        }
      }

      final processedText = text
          .replaceAll('\\r', '\r')
          .replaceAll('\\t', '\t')
          .replaceAll('\\b', '\b')
          .replaceAll('\\f', '\f')
          .replaceAll('\\v', '\v')
          .replaceAll('\\\'', '\'')
          .replaceAll('"', '"')
          .replaceAll('\\0', '0')
          .replaceAll('\\1', '1')
          .replaceAll('\\2', '2')
          .replaceAll('\\3', '3')
          .replaceAll('\\4', '4')
          .replaceAll('\\5', '5')
          .replaceAll('\\6', '6')
          .replaceAll('\\7', '7')
          .replaceAll('\\8', '8')
          .replaceAll('\\9', '9');

      await onData(processedText);
    }
  }
}

Future<void> getGPT3Edit(
  String apiKey,
  String input,
  String instruction, {
  required Future<void> Function(List<String> result) onResult,
  required Future<void> Function() onError,
  int n = 1,
  double temperature = .3,
}) async {
  final data = {
    'model': 'text-davinci-edit-001',
    'input': input,
    'instruction': instruction,
    'temperature': temperature,
    'n': n,
  };

  final headers = {
    'Authorization': apiKey,
    'Content-Type': 'application/json',
  };

  var response = await http.post(
    Uri.parse('https://api.openai.com/v1/edits'),
    headers: headers,
    body: json.encode(data),
  );
  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    final choices = result['choices'];
    if (choices != null && choices is List) {
      onResult(choices.map((e) => e['text'] as String).toList());
    }
  } else {
    onError();
  }
}
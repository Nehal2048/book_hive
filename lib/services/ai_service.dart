import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:book_hive/models/book.dart';

class AiService {
  // Replace with your actual OpenAI API key
  static const _apiKey =
      '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';

  // OpenAI chat completions endpoint
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Generate a summary for a given Book using GPT-3.5
  static Future<String> generateSummary(Book book) async {
    final prompt =
        '''
Generate a concise, engaging, and easy-to-read summary for the following book:

Title: ${book.title}
Author: ${book.author}
Genre: ${book.genre}
Existing summary: ${book.summary}
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional book summarizer.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 300,
        'temperature': 0.7, // creativity
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final summary = data['choices'][0]['message']['content']
          .toString()
          .trim();
      return summary;
    } else {
      throw Exception('OpenAI API Error: ${response.body}');
    }
  }
}

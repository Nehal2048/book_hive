import 'dart:convert';
import 'package:book_hive/models/book.dart';
import 'package:http/http.dart' as http;

class AIBookService {
  final String apiKey;
  final String baseUrl;

  AIBookService({
    required this.apiKey,
    this.baseUrl = 'https://openrouter.ai/api/v1/chat/completions',
  });

  Future<String> generateReport(Book book) async {
    final prompt =
        """
Generate a comprehensive response for the book titled '${book.title}' by ${book.author}. Include the following:

1️⃣ **Summary**: A clear and concise summary of the book in 3–5 sentences.
2️⃣ **Key Takeaways**: List the top 5 lessons, insights, or ideas from the book.
3️⃣ **Similar Books**: Suggest 3–5 books similar in theme, style, or topic.
4️⃣ **AI Review**: Write a short AI-generated review of the book (2–3 sentences).
5️⃣ **Actionable Advice**: Suggest 2–3 practical actions or steps a reader can take based on the book's content.

Format your response as JSON with these keys: 
{
  "summary": "...",
  "key_takeaways": ["...", "...", "..."],
  "similar_books": ["...", "...", "..."],
  "ai_review": "...",
  "actionable_advice": ["...", "...", "..."]
}

Ensure the JSON is valid and ready to parse in the Flutter app.
""";

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are an assistant that generates clear and structured book insights for a mobile app.",
          },
          {"role": "user", "content": prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        'Failed to generate summary: ${response.statusCode} ${response.body}',
      );
    }
  }
}

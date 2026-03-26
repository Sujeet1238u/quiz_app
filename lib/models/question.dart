import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String text;      // Your app uses .text
  final List<String> options;
  final int correctIndex;
  final String category;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.category,
  });

  // This handles the Firebase data you uploaded
  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<String> optionsList = List<String>.from(data['options'] ?? []);
    final String answerText = data['answer'] ?? '';

    return Question(
      id: doc.id,
      text: data['question'] ?? '', // Maps Firebase 'question' to Flutter 'text'
      options: optionsList,
      correctIndex: optionsList.indexOf(answerText),
      category: data['category'] ?? '',
    );
  }
}
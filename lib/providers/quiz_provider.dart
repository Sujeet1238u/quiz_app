import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../data/mock_data.dart'; // <--- THIS WAS THE MISSING IMPORT

enum QuizStatus { idle, active, reviewing, finished }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final int? selectedOptionIndex;
  final List<int?> userAnswers;
  final int secondsLeft;
  final QuizStatus status;
  final QuizResult? result;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionIndex,
    this.userAnswers = const [],
    this.secondsLeft = 20,
    this.status = QuizStatus.idle,
    this.result,
  });

  bool get isAnswered => selectedOptionIndex != null;
  Question? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];
  int get totalQuestions => questions.length;
  bool get isLastQuestion => currentIndex == questions.length - 1;

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    int? selectedOptionIndex,
    List<int?>? userAnswers,
    int? secondsLeft,
    QuizStatus? status,
    QuizResult? result,
    bool clearSelected = false,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndex:
      clearSelected ? null : (selectedOptionIndex ?? this.selectedOptionIndex),
      userAnswers: userAnswers ?? this.userAnswers,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      status: status ?? this.status,
      result: result ?? this.result,
    );
  }
}

class QuizController extends StateNotifier<QuizState> {
  Timer? _timer;
  static const int timerDuration = 20;

  QuizController() : super(const QuizState());

  Future<void> startQuiz(String categoryId) async {
    state = const QuizState(status: QuizStatus.idle);
    List<Question> question = [];

    try {
      // Attempt to fetch from Firebase
      final snapshot = await FirebaseFirestore.instance
          .collection('week_1')
          .where('category', isEqualTo: categoryId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        question = snapshot.docs
            .map((doc) => Question.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print("Error fetching from Firebase: $e");
    }

    // Fallback to mock data if Firebase returned nothing
    if (question.isEmpty) {
      question = getQuestionsForCategory(categoryId);
    }

    if (question.isEmpty) {
      print("DEBUG: No questions found for $categoryId anywhere!");
      return;
    }

    // Shuffle and take 10
    question.shuffle();
    final selected = question.take(10).toList();

    state = QuizState(
      questions: selected,
      currentIndex: 0,
      userAnswers: List.filled(selected.length, null),
      secondsLeft: timerDuration,
      status: QuizStatus.active,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsLeft <= 1) {
        timer.cancel();
        _onTimeExpired();
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  void _onTimeExpired() {
    if (state.isAnswered) return;
    _recordAnswer(null);
    state = state.copyWith(status: QuizStatus.reviewing);
  }

  void selectOption(int index) {
    if (state.isAnswered || state.status != QuizStatus.active) return;
    _timer?.cancel();
    _recordAnswer(index);
    state = state.copyWith(
      selectedOptionIndex: index,
      status: QuizStatus.reviewing,
    );
  }

  void _recordAnswer(int? selectedIndex) {
    final answers = List<int?>.from(state.userAnswers);
    answers[state.currentIndex] = selectedIndex;
    state = state.copyWith(userAnswers: answers);
  }

  void nextQuestion() {
    if (state.isLastQuestion) {
      _finishQuiz();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      secondsLeft: timerDuration,
      status: QuizStatus.active,
      clearSelected: true,
    );

    _startTimer();
  }

  void _finishQuiz() {
    _timer?.cancel();

    final questions = state.questions;
    final answers = state.userAnswers;
    final answerResults = <bool>[];
    int correct = 0;

    for (int i = 0; i < questions.length; i++) {
      final isCorrect = answers[i] == questions[i].correctIndex;
      answerResults.add(isCorrect);
      if (isCorrect) correct++;
    }

    final points = correct * 10;
    final result = QuizResult(
      categoryId: questions.isNotEmpty ? questions.first.category : '',
      totalQuestions: questions.length,
      correctAnswers: correct,
      pointsEarned: points,
      answerResults: answerResults,
    );

    state = state.copyWith(status: QuizStatus.finished, result: result);
  }

  void resetQuiz() {
    _timer?.cancel();
    state = const QuizState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizProvider =
StateNotifierProvider.autoDispose<QuizController, QuizState>((ref) {
  return QuizController();
});
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../database/database_helper.dart';

class QuestionProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Question> _questions = [];
  bool _isLoading = false;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;

  List<Question> get unansweredQuestions => 
      _questions.where((q) => !q.isAnswered).toList();
  
  List<Question> get answeredQuestions => 
      _questions.where((q) => q.isAnswered).toList();

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _questions = await _databaseHelper.getAllQuestions();
    } catch (e) {
      debugPrint('Error loading questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestion(Question question) async {
    try {
      final id = await _databaseHelper.insertQuestion(question);
      final newQuestion = question.copyWith(id: id);
      _questions.insert(0, newQuestion);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding question: $e');
      rethrow;
    }
  }

  Future<void> updateQuestion(Question question) async {
    try {
      await _databaseHelper.updateQuestion(question);
      final index = _questions.indexWhere((q) => q.id == question.id);
      if (index != -1) {
        _questions[index] = question;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating question: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(int questionId) async {
    try {
      await _databaseHelper.deleteQuestion(questionId);
      _questions.removeWhere((q) => q.id == questionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting question: $e');
      rethrow;
    }
  }

  Future<Question?> getQuestion(int id) async {
    try {
      return await _databaseHelper.getQuestion(id);
    } catch (e) {
      debugPrint('Error getting question: $e');
      return null;
    }
  }

  Future<void> answerQuestion(int questionId, String answer) async {
    try {
      final question = _questions.firstWhere((q) => q.id == questionId);
      final updatedQuestion = question.copyWith(
        answer: answer,
        answeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateQuestion(updatedQuestion);
    } catch (e) {
      debugPrint('Error answering question: $e');
      rethrow;
    }
  }

  Future<void> loadUnansweredQuestions() async {
    try {
      final unanswered = await _databaseHelper.getUnansweredQuestions();
      // Update the unanswered questions in the main list
      for (final question in unanswered) {
        final index = _questions.indexWhere((q) => q.id == question.id);
        if (index != -1) {
          _questions[index] = question;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unanswered questions: $e');
    }
  }

  Future<void> loadAnsweredQuestions() async {
    try {
      final answered = await _databaseHelper.getAnsweredQuestions();
      // Update the answered questions in the main list
      for (final question in answered) {
        final index = _questions.indexWhere((q) => q.id == question.id);
        if (index != -1) {
          _questions[index] = question;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading answered questions: $e');
    }
  }

  int get unansweredCount => unansweredQuestions.length;
  int get answeredCount => answeredQuestions.length;
}

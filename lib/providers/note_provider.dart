import 'package:flutter/material.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await _databaseHelper.getAllNotes();
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(Note note) async {
    try {
      final id = await _databaseHelper.insertNote(note);
      final newNote = note.copyWith(id: id);
      _notes.insert(0, newNote);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding note: $e');
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _databaseHelper.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(int noteId) async {
    try {
      await _databaseHelper.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }
  }

  Future<Note?> getNote(int id) async {
    try {
      return await _databaseHelper.getNote(id);
    } catch (e) {
      debugPrint('Error getting note: $e');
      return null;
    }
  }

  int get totalNotes => _notes.length;
}

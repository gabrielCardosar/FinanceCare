import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/firestore_service.dart';

class NotesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadNotes(String uid) {
    _firestoreService.getNotes(uid).listen((notes) {
      _notes = notes;
      notifyListeners();
    });
  }

  Future<void> addNote(NoteModel note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveNote(note);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(NoteModel note) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveNote(note.copyWith(updatedAt: DateTime.now()));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(String uid, String noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteNote(uid, noteId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

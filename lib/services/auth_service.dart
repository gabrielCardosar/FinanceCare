import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ✅ FIX: usa try/catch mais amplo para capturar o erro PigeonUserDetails
  // que ocorre na versão 4.x do firebase_auth com Flutter mais novo
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // ✅ Captura erro PigeonUserDetails (bug do firebase_auth 4.x)
      // O usuário foi criado com sucesso mesmo com esse erro
      // Verifica se o usuário está logado
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Criou com sucesso, erro foi só na resposta — ignoramos
        // Retorna uma "fake" UserCredential não é possível, então reloga
        return await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      throw 'Erro ao criar conta. Tente novamente.';
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao fazer login. Tente novamente.';
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'invalid-credential':
        return 'Email ou senha incorretos.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
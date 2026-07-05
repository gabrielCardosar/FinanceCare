import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
      // Bug do firebase_auth 4.x: lança erro PigeonUserDetails mas cria o usuário
      // Verifica se o usuário foi criado mesmo assim
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Usuário criado com sucesso — faz sign in para retornar UserCredential
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
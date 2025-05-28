// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../services/auth_services.dart';
// import '../models/user_model.dart';

// class AuthProvider with ChangeNotifier {
//   final AuthService _authService = AuthService();

//   UserModel? _user;
//   bool _isLoading = false;

//   UserModel? get user => _user;
//   bool get isLoading => _isLoading;
//   bool get isAuthenticated => _user != null;

//   AuthProvider() {
//     // Listen to auth state changes
//     _authService.authStateChanges.listen((User? firebaseUser) {
//       if (firebaseUser != null) {
//         _user = UserModel(
//           id: firebaseUser.uid,
//           name: firebaseUser.displayName ?? '',
//           email: firebaseUser.email ?? '',
//           createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
//           isEmailVerified: firebaseUser.emailVerified,
//         );
//       } else {
//         _user = null;
//       }
//       notifyListeners();
//     });
//   }

//   Future<void> signIn(String email, String password) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       await _authService.signInWithEmailAndPassword(email, password);
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       rethrow;
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> register(String email, String password, String displayName) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       await _authService.registerWithEmailAndPassword(email, password, displayName);
//     } catch (e) {
//       _isLoading = false;
//       notifyListeners();
//       rethrow;
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> signOut() async {
//     await _authService.signOut();
//   }

//   Future<void> sendEmailVerification() async {
//     await _authService.sendEmailVerification();
//   }

//   Future<void> reloadUser() async {
//     await _authService.reloadUser();
//     notifyListeners();
//   }
// }
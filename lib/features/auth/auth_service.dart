import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/user_profile_service.dart';



class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final UserProfileService _userProfileService = UserProfileService();
  
  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,

  }) async{
    return await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createAccout({
    required String email,
    required String password,
  }) async{
    return await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async{
    await firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async{
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deleteAccount() async{
    await firebaseAuth.currentUser?.delete();
  }
  


  Future<void> updatePassword({required String password}) async{
    await firebaseAuth.currentUser?.updatePassword(password);
  }

  Future<void> sendEmailVerification() async{
    await firebaseAuth.currentUser?.sendEmailVerification();
  }

  Future<UserCredential?> signInWithGoogle({bool forceAccountSelection = true}) async {
    try {
      if (forceAccountSelection) {
        // Ensure previous Google session is cleared so the account picker shows
        try {
          await googleSignIn.disconnect();
        } catch (_) {}
        await googleSignIn.signOut();
      }
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await firebaseAuth.signInWithCredential(credential);
      
      // Store user profile information in local storage
      if (userCredential.user != null) {
        await _userProfileService.storeProfileFromFirebaseUser(userCredential.user!);
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    try {
      // Disconnect ensures the next sign-in prompts for account selection
      try {
        await googleSignIn.disconnect();
      } catch (_) {}
      await googleSignIn.signOut();
    } finally {
      // Clear stored profile data
      await _userProfileService.clearStoredProfile();
      await firebaseAuth.signOut();
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Google Sign-In xizmatini sozlash

  // Telefon orqali tizimga kirish
  Future<void> verifyPhoneNumber(
      String phoneNumber, Function(String) codeSentCallback) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Agar kod avtomatik tarzda aniqlansa, ushbu qism ishlaydi
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verifikatsiya xatosi: $e");
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        // Kod foydalanuvchiga SMS orqali yuborilgandan so'ng bu qism ishlaydi
        codeSentCallback(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Kodni olish vaqti tugaganda bu qism ishlaydi
      },
      timeout: const Duration(seconds: 60), // 1 daqiqalik timeout
    );
  }

  // Kod bilan autentifikatsiya qilish
  Future<void> signInWithPhoneNumber(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      throw e;
    }
  }

  // Google orqali tizimga kirish
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Agar foydalanuvchi Google kirishni rad etsa

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // Tizimdan chiqish
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Firebase til sozlamasi (Masalan, O'zbek tili)
  void setAppLanguage() {
    _auth.setLanguageCode("uz");
  }
}

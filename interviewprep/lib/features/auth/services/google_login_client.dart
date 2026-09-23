import 'package:google_login/google_login.dart';

class GoogleLoginClient {
  Future<String?> signInAndGetIdToken() async {
    final credential = await AuthServiceForGoogle().signInWithGoogle();
    final user = credential?.user;
    if (user == null) return null;
    return user.getIdToken();
  }
}

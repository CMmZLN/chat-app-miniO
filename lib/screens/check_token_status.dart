import 'package:flutter/material.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart' as jwt;

bool isTokenExpired = false;

Future<String?> getToken() async {
  return await AuthController().getToken();
}

class AuthService {
  static Future<void> checkTokenStatus(BuildContext context) async {
    var token = await getToken();
    bool isTokenExpired = jwt.JwtDecoder.isExpired(token.toString());
    if (isTokenExpired) {
      // Optionally remove token (if needed)
      AuthController().removeToken();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show Snackbar notification after the build is complete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('session expire! Please login again.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginForm()),
        );
      });
    }
  }
}

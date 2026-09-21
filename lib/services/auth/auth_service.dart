import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../neon_db_service.dart';

class AuthResult {
  final bool isSuccess;
  final bool isNewUser;
  final String? email;
  final String? fullName;
  final String? photoUrl;
  final String? householdName;
  final String? errorMessage;

  AuthResult({
    required this.isSuccess,
    this.isNewUser = false,
    this.email,
    this.fullName,
    this.photoUrl,
    this.householdName,
    this.errorMessage,
  });
}

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static const String _keyIsLoggedIn = 'auth_is_logged_in';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyFullName = 'auth_full_name';
  static const String _keyPhotoUrl = 'auth_photo_url';
  static const String _keyHouseholdName = 'auth_household_name';
  static const String _keyDietPreference = 'auth_diet_preference';
  static const String _keyHouseholdSize = 'auth_household_size';
  static const String _keyAppliances = 'auth_appliances';
  static const String _keyExclusions = 'auth_exclusions';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<Map<String, String?>> getActiveUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_keyUserId);
    if (userId == null || userId.isEmpty) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_keyUserId, userId);
      await prefs.setBool(_keyIsLoggedIn, true);
    }

    return {
      'id': userId,
      'email': prefs.getString(_keyUserEmail) ?? 'chef@kichook.app',
      'fullName': prefs.getString(_keyFullName) ?? 'Chef',
      'photoUrl': prefs.getString(_keyPhotoUrl),
      'householdName': prefs.getString(_keyHouseholdName) ?? 'My Kitchen',
      'dietPreference': prefs.getString(_keyDietPreference) ?? 'Veg',
      'householdSize': prefs.getString(_keyHouseholdSize) ?? '2',
      'appliances': prefs.getString(_keyAppliances) ?? 'Gas Stove,Kadai / Pan',
      'exclusions': prefs.getString(_keyExclusions) ?? '',
    };
  }

  static Future<void> saveSession({
    required String id,
    required String email,
    required String fullName,
    String? photoUrl,
    required String householdName,
    String dietPreference = 'Veg',
    String householdSize = '2',
    String appliances = 'Gas Stove,Kadai / Pan',
    String exclusions = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyFullName, fullName);
    if (photoUrl != null) {
      await prefs.setString(_keyPhotoUrl, photoUrl);
    }
    await prefs.setString(_keyHouseholdName, householdName);
    await prefs.setString(_keyDietPreference, dietPreference);
    await prefs.setString(_keyHouseholdSize, householdSize);
    await prefs.setString(_keyAppliances, appliances);
    await prefs.setString(_keyExclusions, exclusions);
  }

  static Future<void> updatePersonalization({
    required String dietPreference,
    required String householdSize,
    required String appliances,
    required String exclusions,
    String? householdName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDietPreference, dietPreference);
    await prefs.setString(_keyHouseholdSize, householdSize);
    await prefs.setString(_keyAppliances, appliances);
    await prefs.setString(_keyExclusions, exclusions);
    if (householdName != null && householdName.isNotEmpty) {
      await prefs.setString(_keyHouseholdName, householdName);
    }

    final email = prefs.getString(_keyUserEmail) ?? 'chef@kichook.app';
    final userId = prefs.getString(_keyUserId) ?? 'user_${DateTime.now().microsecondsSinceEpoch}';
    final fullName = prefs.getString(_keyFullName) ?? 'Chef';
    final photoUrl = prefs.getString(_keyPhotoUrl);
    final hName = householdName ?? prefs.getString(_keyHouseholdName) ?? 'My Kitchen';

    try {
      // Idempotent UPSERT: Inserts row if missing in DB, updates all columns if present
      await NeonDbService.registerUserInCloud(
        id: userId,
        email: email,
        fullName: fullName,
        photoUrl: photoUrl,
        householdName: hName,
        dietPreference: dietPreference,
        householdSize: householdSize,
        appliances: appliances,
        exclusions: exclusions,
      );
    } catch (_) {}
  }

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return AuthResult(isSuccess: false, errorMessage: 'Google sign in canceled by user');
      }

      final email = googleAccount.email.trim().toLowerCase();
      final name = googleAccount.displayName ?? email.split('@').first;
      final photoUrl = googleAccount.photoUrl;

      // Lookup profile in Neon PostgreSQL
      final existingUser = await NeonDbService.fetchUserByEmail(email);

      if (existingUser != null) {
        // Returning User -> Update last login & load session with cloud profile
        await NeonDbService.updateUserLastLogin(email);
        await saveSession(
          id: existingUser['id'] as String,
          email: existingUser['email'] as String,
          fullName: existingUser['fullName'] as String,
          photoUrl: existingUser['photoUrl'] as String?,
          householdName: existingUser['householdName'] as String? ?? 'My Kitchen',
          dietPreference: existingUser['dietPreference'] as String? ?? 'Veg',
          householdSize: existingUser['householdSize'] as String? ?? '2',
          appliances: existingUser['appliances'] as String? ?? 'Gas Stove,Kadai / Pan',
          exclusions: existingUser['exclusions'] as String? ?? '',
        );

        return AuthResult(
          isSuccess: true,
          isNewUser: false,
          email: email,
          fullName: existingUser['fullName'] as String,
          photoUrl: existingUser['photoUrl'] as String?,
          householdName: existingUser['householdName'] as String?,
        );
      } else {
        // New User -> Register immediately in Neon users table
        final newId = 'user_${DateTime.now().microsecondsSinceEpoch}';
        await NeonDbService.registerUserInCloud(
          id: newId,
          email: email,
          fullName: name,
          photoUrl: photoUrl,
          householdName: '$name\'s Kitchen',
          dietPreference: 'Veg',
          householdSize: '2',
          appliances: 'Gas Stove,Kadai / Pan',
          exclusions: '',
        );

        await saveSession(
          id: newId,
          email: email,
          fullName: name,
          photoUrl: photoUrl,
          householdName: '$name\'s Kitchen',
          dietPreference: 'Veg',
          householdSize: '2',
          appliances: 'Gas Stove,Kadai / Pan',
          exclusions: '',
        );

        return AuthResult(
          isSuccess: true,
          isNewUser: true,
          email: email,
          fullName: name,
          photoUrl: photoUrl,
        );
      }
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  // Unified Single-Flow Email Auth (Handles both Sign-In and Registration seamlessly)
  static Future<AuthResult> continueWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return AuthResult(isSuccess: false, errorMessage: 'Please enter both email and password.');
    }

    try {
      final existingUser = await NeonDbService.fetchUserByEmail(trimmedEmail);

      if (existingUser != null) {
        // Returning User -> Update last login & load session with cloud profile
        await NeonDbService.updateUserLastLogin(trimmedEmail);
        await saveSession(
          id: existingUser['id'] as String,
          email: existingUser['email'] as String,
          fullName: existingUser['fullName'] as String,
          photoUrl: existingUser['photoUrl'] as String?,
          householdName: existingUser['householdName'] as String? ?? 'My Kitchen',
          dietPreference: existingUser['dietPreference'] as String? ?? 'Veg',
          householdSize: existingUser['householdSize'] as String? ?? '2',
          appliances: existingUser['appliances'] as String? ?? 'Gas Stove,Kadai / Pan',
          exclusions: existingUser['exclusions'] as String? ?? '',
        );

        return AuthResult(
          isSuccess: true,
          isNewUser: false,
          email: trimmedEmail,
          fullName: existingUser['fullName'] as String,
          photoUrl: existingUser['photoUrl'] as String?,
          householdName: existingUser['householdName'] as String?,
        );
      } else {
        // New User -> Register immediately in Neon PostgreSQL users table
        final defaultName = fullName != null && fullName.trim().isNotEmpty
            ? fullName.trim()
            : trimmedEmail.split('@').first;
        final nameCapitalized = defaultName.isNotEmpty
            ? defaultName[0].toUpperCase() + defaultName.substring(1)
            : 'Chef';

        final newId = 'user_${DateTime.now().microsecondsSinceEpoch}';
        await NeonDbService.registerUserInCloud(
          id: newId,
          email: trimmedEmail,
          fullName: nameCapitalized,
          householdName: '$nameCapitalized\'s Kitchen',
          dietPreference: 'Veg',
          householdSize: '2',
          appliances: 'Gas Stove,Kadai / Pan',
          exclusions: '',
        );

        await saveSession(
          id: newId,
          email: trimmedEmail,
          fullName: nameCapitalized,
          householdName: '$nameCapitalized\'s Kitchen',
          dietPreference: 'Veg',
          householdSize: '2',
          appliances: 'Gas Stove,Kadai / Pan',
          exclusions: '',
        );

        return AuthResult(
          isSuccess: true,
          isNewUser: true,
          email: trimmedEmail,
          fullName: nameCapitalized,
        );
      }
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  // Backwards compatibility wrappers
  static Future<AuthResult> signInWithEmailAndPassword(String email, String password) =>
      continueWithEmail(email: email, password: password);

  static Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) =>
      continueWithEmail(email: email, password: password, fullName: fullName);

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}

import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userBioKey = 'user_bio';
  static const String _userContactKey = 'user_contact';

  final Uuid _uuid = const Uuid();

  /// ユーザーIDを取得または生成
  Future<String> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null || userId.isEmpty) {
      userId = _generateReadableUserId();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  /// 読みやすいユーザーIDを生成
  /// フォーマット: go_[形容詞][動物][数字4桁]
  /// 例: go_swift_fox_1234, go_brave_eagle_5678
  String _generateReadableUserId() {
    final List<String> adjectives = [
      'swift', 'brave', 'clever', 'strong', 'bright', 'calm', 'bold', 'quick',
      'wise', 'cool', 'fair', 'kind', 'wild', 'fast', 'free', 'pure',
      'true', 'keen', 'sharp', 'noble'
    ];

    final List<String> animals = [
      'fox', 'eagle', 'wolf', 'bear', 'lion', 'tiger', 'hawk', 'deer',
      'owl', 'swan', 'crow', 'ram', 'cat', 'dog', 'bird', 'fish',
      'duck', 'frog', 'bee', 'ant'
    ];

    final Random random = Random();
    final String adjective = adjectives[random.nextInt(adjectives.length)];
    final String animal = animals[random.nextInt(animals.length)];
    final int number = random.nextInt(10000);

    return 'go_${adjective}_${animal}_${number.toString().padLeft(4, '0')}';
  }

  /// UUIDベースの完全にユニークなIDを生成（将来的な拡張用）
  String _generateUniqueUserId() {
    return 'go_${_uuid.v4().replaceAll('-', '').substring(0, 12)}';
  }

  /// ユーザー名を取得・保存
  Future<String> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'ゲストユーザー';
  }

  Future<void> saveUserName(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// ユーザーバイオを取得・保存
  Future<String> getUserBio() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userBioKey) ?? '';
  }

  Future<void> saveUserBio(String bio) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userBioKey, bio);
  }

  /// ユーザー連絡先を取得・保存
  Future<String> getUserContact() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userContactKey) ?? '';
  }

  Future<void> saveUserContact(String contact) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userContactKey, contact);
  }

  /// ユーザーデータをリセット（新しいIDを生成）
  Future<void> resetUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    // 新しいIDを生成して返す
    await getUserId();
  }

  /// 全ユーザーデータをクリア
  Future<void> clearAllUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userBioKey);
    await prefs.remove(_userContactKey);
    print('🧹 UserService: All user data cleared from SharedPreferences');
  }

  /// ユーザーデータの存在チェック
  Future<bool> hasUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null ||
           prefs.getString(_userNameKey) != null ||
           prefs.getString(_userBioKey) != null ||
           prefs.getString(_userContactKey) != null;
  }

  void dispose() {
    // 必要に応じてリソースのクリーンアップ
  }
}
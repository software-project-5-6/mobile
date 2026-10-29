import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final ApiService _api = ApiService();

  static const Duration _requestTimeout = Duration(seconds: 60);

  static const String _deviceIdKey = 'psms_installation_device_id';

  // Keep the original backend endpoint paths.
  static const String _registerPath = '/api/notifications/register-device';

  static const String _unregisterPath = '/api/notifications/unregister-device';

  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  StreamSubscription<RemoteMessage>? _openedSubscription;

  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialMessageChecked = false;

  // Assign this callback from the UI/navigation layer.
  void Function(Map<String, dynamic>)? onNotificationTap;

  PushNotificationService({this.onNotificationTap});

  // ==========================================
  // 1. INITIALIZE PUSH NOTIFICATIONS
  // ==========================================

  Future<bool> initialize(String jwtToken) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('Unsupported notification platform.');
        return false;
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final status = settings.authorizationStatus;

      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        debugPrint('Notification permission denied.');
        return false;
      }

      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM token unavailable.');
        return false;
      }

      final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';

      final deviceId = await _getDeviceId();

      // Install listeners only once per service instance.
      setupNotificationHandlers();
      setupTokenRefreshHandler(jwtToken);

      await registerDevice(fcmToken, deviceType, deviceId, jwtToken);

      debugPrint('Push notifications initialized successfully.');

      return true;
    } catch (e) {
      debugPrint('Push notification initialization failed: $e');
      return false;
    }
  }

  // ==========================================
  // 2. STABLE APP INSTALLATION DEVICE ID
  // ==========================================

  Future<String> _getDeviceId() async {
    final preferences = SharedPreferencesAsync();

    final existingId = await preferences.getString(_deviceIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final random = Random.secure();

    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    final newId = base64UrlEncode(bytes).replaceAll('=', '');

    await preferences.setString(_deviceIdKey, newId);

    return newId;
  }

  // ==========================================
  // 3. REGISTER DEVICE WITH BACKEND
  // ==========================================

  Future<void> registerDevice(
    String token,
    String deviceType,
    String deviceId,
    String jwtToken,
  ) async {
    // jwtToken remains in the signature for
    // compatibility with existing screen calls.
    // Always retrieve the CURRENT Supabase JWT.
    final accessToken = await _api.getIdToken();

    final uri = Uri.parse('${ApiConstants.baseUrl}$_registerPath');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'token': token,
              'deviceType': deviceType,
              'deviceId': deviceId,
            }),
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Device registered successfully.');
        return;
      }

      throw Exception(
        'Device registration failed '
        '(${response.statusCode}).',
      );
    } on TimeoutException {
      throw Exception('Device registration timed out.');
    } catch (e) {
      debugPrint('Device registration error: $e');
      rethrow;
    }
  }

  // ==========================================
  // 4. SETUP NOTIFICATION HANDLERS
  // ==========================================

  void setupNotificationHandlers() {
    // Foreground notifications.
    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      debugPrint('Foreground notification received.');

      if (message.notification != null) {
        _handleNotification(message);
      }
    });

    // User taps notification from background.
    _openedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen((
      RemoteMessage message,
    ) {
      debugPrint('Notification opened from background.');

      _handleNotificationAction(message.data);
    });

    // User taps notification from terminated state.
    if (!_initialMessageChecked) {
      _initialMessageChecked = true;

      _messaging
          .getInitialMessage()
          .then((RemoteMessage? message) {
            if (message != null) {
              _handleNotificationAction(message.data);
            }
          })
          .catchError((Object error) {
            debugPrint('Initial notification check failed: $error');
          });
    }
  }

  // ==========================================
  // 5. HANDLE FOREGROUND NOTIFICATIONS
  // ==========================================

  void _handleNotification(RemoteMessage message) {
    final data = message.data;

    switch (data['type']) {
      case 'ARTIFACT_UPLOADED':
        debugPrint('Artifact upload notification received.');
        break;

      default:
        debugPrint('Foreground notification received.');
    }

    // To display a visible foreground notification,
    // integrate flutter_local_notifications
    // or an equivalent notification display mechanism.
  }

  // ==========================================
  // 6. HANDLE NOTIFICATION ACTIONS
  // ==========================================

  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == 'ARTIFACT_UPLOADED') {
      final projectId = data['projectId'];

      debugPrint(
        'Artifact notification tapped '
        'for project: $projectId',
      );
    }

    // Navigation is managed by the UI layer.
    onNotificationTap?.call(data);
  }

  // ==========================================
  // 7. FCM TOKEN REFRESH HANDLER
  // ==========================================

  void setupTokenRefreshHandler(String jwtToken) {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      String newFcmToken,
    ) async {
      try {
        if (newFcmToken.isEmpty) {
          return;
        }

        final deviceType = Platform.isAndroid ? 'ANDROID' : 'IOS';

        final deviceId = await _getDeviceId();

        // registerDevice fetches a fresh
        // Supabase access token when called.
        await registerDevice(newFcmToken, deviceType, deviceId, jwtToken);

        debugPrint('FCM token refresh registered successfully.');
      } catch (e) {
        debugPrint('FCM token refresh registration failed: $e');
      }
    });
  }

  // ==========================================
  // 8. UNREGISTER DEVICE
  // ==========================================

  Future<void> unregister(String jwtToken) async {
    try {
      // Call before Supabase signOut().
      final accessToken = await _api.getIdToken();

      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}$_unregisterPath',
      ).replace(queryParameters: {'token': fcmToken});

      final response = await http
          .delete(
            uri,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Accept': 'application/json',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Device unregistered successfully.');
      } else {
        throw Exception(
          'Device unregistration failed '
          '(${response.statusCode}).',
        );
      }
    } on TimeoutException {
      debugPrint('Device unregistration timed out.');
      rethrow;
    } catch (e) {
      debugPrint('Device unregistration failed: $e');
      rethrow;
    }
  }

  // ==========================================
  // 9. DISPOSE STREAM SUBSCRIPTIONS
  // ==========================================

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenRefreshSubscription = null;

    _initialMessageChecked = false;
  }
}

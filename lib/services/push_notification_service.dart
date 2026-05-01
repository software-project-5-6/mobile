import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../constants/api_constants.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // NOTE: Ensure this matches your ApiService.baseUrl!
  final String _baseUrl = ApiConstants.baseUrl;

  /// Initialize push notifications
  Future<bool> initialize(String jwtToken) async {
    try {
      // 1. Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Push notification permission denied');
        return false;
      }

      // 2. Get FCM token
      String? fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        print('Failed to get FCM token');
        return false;
      }
      print('FCM Token: $fcmToken');

      // 3. Get device info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String deviceType;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceType = 'ANDROID';
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'IOS';
      }

      // 4. Register with backend
      await registerDevice(fcmToken, deviceType, deviceId, jwtToken);

      // 5. Setup handlers
      setupNotificationHandlers();
      setupTokenRefreshHandler(jwtToken);

      return true;
    } catch (e) {
      print('Failed to initialize push notifications: $e');
      return false;
    }
  }

  /// Register device with backend[cite: 2]
  Future<void> registerDevice(
    String token,
    String deviceType,
    String deviceId,
    String jwtToken,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/notifications/register-device'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'deviceType': deviceType,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        print('Device registered for push notifications');
      } else {
        print('Failed to register device: ${response.body}');
      }
    } catch (e) {
      print('Error registering device: $e');
      rethrow;
    }
  }

  /// Setup notification handlers[cite: 2]
  void setupNotificationHandlers() {
    // Foreground messages[cite: 2]
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification received in foreground: ${message.data}');
      if (message.notification != null) {
        _handleNotification(message);
      }
    });

    // Background/terminated notification tapped[cite: 2]
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app from background');
      _handleNotificationAction(message.data);
    });

    // Check if opened from terminated state[cite: 2]
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Notification opened app from terminated state');
        _handleNotificationAction(message.data);
      }
    });
  }

  /// Handle notification display[cite: 2]
  void _handleNotification(RemoteMessage message) {
    // final notification = message.notification;
    final data = message.data;

    if (data['type'] == 'ARTIFACT_UPLOADED') {
      // Show local notification or update UI[cite: 2]
      print('New artifact: ${data['artifactName']} in ${data['projectName']}');
    }
  }

  /// Handle notification actions[cite: 2]
  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'];
    final projectId = data['projectId'];

    switch (type) {
      case 'ARTIFACT_UPLOADED':
        // Navigate to project details[cite: 2]
        print('Navigate to project: $projectId');
        // TODO: Add your Navigator code here to route to the ProjectArtifactsTab
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Setup token refresh handler[cite: 2]
  void setupTokenRefreshHandler(String jwtToken) {
    _messaging.onTokenRefresh.listen((String newToken) async {
      print('FCM Token refreshed: $newToken');
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId;
      String deviceType;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceType = 'ANDROID';
      } else {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceType = 'IOS';
      }

      await registerDevice(newToken, deviceType, deviceId, jwtToken);
    });
  }

  /// Unregister device[cite: 2]
  Future<void> unregister(String jwtToken) async {
    try {
      String? fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/notifications/unregister-device?token=$fcmToken'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        print('Device unregistered successfully');
      }
    } catch (e) {
      print('Failed to unregister device: $e');
    }
  }
}
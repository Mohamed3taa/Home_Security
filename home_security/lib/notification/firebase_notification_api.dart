import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FirebaseNotificationApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  Future<void> showForegroundNotification(RemoteMessage message) async {
    final String? imageUrl = message.notification?.android?.imageUrl;
    final BigPictureStyleInformation? bigPictureStyle =
        await _getBigPictureStyle(imageUrl);

    var androidDetails = AndroidNotificationDetails(
      'notification_channel_id',
      'Notification Channel',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigPictureStyle,
    );

    const darwinDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
    );
  }

  Future<BigPictureStyleInformation?> _getBigPictureStyle(
    String? imageUrl,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/notification_image.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
        );
      }
    } catch (_) {}

    return null;
  }

  Future<void> initNotifications() async {
    try {
      await initializeLocalNotifications();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        showForegroundNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firebaseMessaging.requestPermission();
      final fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken != null) {
        await _firestore.collection('Users').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayUnion([fcmToken]),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }
}

final firebaseNotificationApi = FirebaseNotificationApi();

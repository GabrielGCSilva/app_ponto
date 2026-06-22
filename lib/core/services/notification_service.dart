import 'package:flutter/material.dart'; // 🔥 ADICIONAR ESTE IMPORT
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Inicializar notificações
  Future<void> init() async {
    // 🔥 Solicitar permissão
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 🔥 Registrar token
      await _registrarToken();

      // 🔥 Escutar mensagens em primeiro plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _mostrarNotificacaoLocal(message);
      });

      // 🔥 Escutar quando o app é aberto pela notificação
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message);
      });

      // 🔥 Escutar quando o app é iniciado por uma notificação
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    }

    // 🔥 Inicializar notificações locais
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(initSettings);
  }

  // 🔥 Registrar token no Firestore
  Future<void> _registrarToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('tokens_notificacao').doc(token).set({
            'funcionarioId': user.uid,
            'token': token,
            'dataCriacao': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ Token registrado: $token');
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao registrar token: $e');
    }
  }

  // 🔥 Remover token (logout)
  Future<void> removerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('tokens_notificacao').doc(token).delete();
        debugPrint('✅ Token removido');
      }
    } catch (e) {
      debugPrint('❌ Erro ao remover token: $e');
    }
  }

  // 🔥 Mostrar notificação local
  void _mostrarNotificacaoLocal(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'app_ponto_channel',
      'App Ponto',
      channelDescription: 'Notificações do App Ponto',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    _localNotifications.show(
      DateTime.now().millisecond,
      notification.title,
      notification.body,
      details,
    );
  }

  // 🔥 Lidar com clique na notificação
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('📱 Notificação clicada: ${message.data}');
    // 🔥 Navegar para a tela apropriada
    // Exemplo: se a notificação for de alerta de ponto, abrir a tela de registro
  }
}
// 🔥 firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// 🔥 Configuração do Firebase (copie do seu firebase_options.dart)
firebase.initializeApp({
  apiKey: "AIzaSyBGzQyNLEcSMv8y1KGl1jn76KL-k-SUMjM",
  authDomain: "app-ponto-ggc.firebaseapp.com",
  projectId: "app-ponto-ggc",
  storageBucket: "app-ponto-ggc.firebasestorage.app",
  messagingSenderId: "331527965536",
  appId: "1:331527965536:web:f5948245084a119f2fec05",
});

// 🔥 Inicializar Messaging
const messaging = firebase.messaging();

// 🔥 Receber mensagens em background
messaging.onBackgroundMessage((payload) => {
  console.log('📩 Notificação em background:', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png',
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
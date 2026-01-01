// Firebase Cloud Messaging Service Worker
// 웹에서 백그라운드 알림을 수신하기 위해 필요한 파일입니다.

importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// ⚠️ TODO: Firebase Console > 프로젝트 설정 > 일반 > 내 앱 > 웹 앱 선택 > 'firebaseConfig' 값으로 교체하세요.
const firebaseConfig = {
  apiKey: "AIzaSyDBLkjvI3cEJh71UN7KaVvoiNLNy1Iih3o",
  authDomain: "destiny-os-2026.firebaseapp.com",
  projectId: "destiny-os-2026",
  storageBucket: "destiny-os-2026.firebasestorage.app",
  messagingSenderId: "16973939404",
  appId: "1:16973939404:web:2cf031a507fd1a861df869"
};

// Firebase 초기화
firebase.initializeApp(firebaseConfig);

// Messaging 객체 가져오기
const messaging = firebase.messaging();

// 백그라운드 메시지 수신 핸들러
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  // 알림 표시 제목과 내용
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png', // 앱 아이콘 경로
    badge: '/icons/Icon-maskable-192.png', // 모바일 상태바 아이콘 (흑백 권장)
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 이벤트 처리
self.addEventListener('notificationclick', function(event) {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();

  // 앱이 열려있으면 포커스, 아니면 홈 화면 열기
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true}).then(function(clientList) {
      // 이미 열린 탭이 있는지 확인
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.includes('/') && 'focus' in client) {
          return client.focus();
        }
      }
      // 열린 탭이 없으면 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});

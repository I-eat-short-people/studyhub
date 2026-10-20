importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyDummyKeyForStudyHubServiceWorker",
  authDomain: "studyhub.firebaseapp.com",
  projectId: "studyhub",
  storageBucket: "studyhub.appspot.com",
  messagingSenderId: "749333059425",
  appId: "1:749333059425:web:dummy"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Nhận tin nhắn trong background: ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'StudyHub';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : 'Bạn có thông báo mới từ StudyHub.',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

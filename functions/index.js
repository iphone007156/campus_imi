const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ✅ 1. Пуш при появлении новой новости
exports.sendNewsNotification = functions.firestore
  .document('news/{newsId}')
  .onCreate(async (snap, context) => {
    const news = snap.data();
    const payload = {
      notification: {
        title: `Новость: ${news.title}`,
        body: news.shortDescription || 'Нажмите, чтобы посмотреть',
      },
    };

    // Получаем все токены пользователей
    const usersSnapshot = await admin.firestore().collection('users').get();
    const tokens = [];
    usersSnapshot.forEach(doc => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length > 0) {
      // Отправляем пачками (FCM поддерживает до 500 токенов за раз)
      const chunks = [];
      for (let i = 0; i < tokens.length; i += 500) {
        chunks.push(tokens.slice(i, i + 500));
      }
      for (const chunk of chunks) {
        await admin.messaging().sendToDevice(chunk, payload);
      }
    }
  });

// ✅ 2. Пуш при добавлении новой пары
exports.sendScheduleUpdateNotification = functions.firestore
  .document('lessons/{lessonId}')
  .onCreate(async (snap, context) => {
    const lesson = snap.data();
    const payload = {
      notification: {
        title: 'Обновление расписания',
        body: `Добавлена пара: ${lesson.subject} (${lesson.group})`,
      },
    };
    const usersSnapshot = await admin.firestore().collection('users').get();
    const tokens = [];
    usersSnapshot.forEach(doc => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });
    if (tokens.length > 0) {
      await admin.messaging().sendToDevice(tokens, payload);
    }
  });
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool showAcceptButton;

  const PrivacyPolicyScreen({super.key, this.showAcceptButton = false});

  static const String _policyText = '''
ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ
приложения «Campus IMI»

Дата последнего обновления: 02.11.2026

1. ОБЩИЕ ПОЛОЖЕНИЯ
1.1. Настоящая Политика определяет порядок обработки и защиты
персональных данных пользователей приложения «Campus IMI».
1.2. Оператор персональных данных: K-IT.
1.3. Используя Приложение, Пользователь подтверждает согласие
с настоящей Политикой.

2. КАКИЕ ДАННЫЕ МЫ СОБИРАЕМ
2.1. Данные Пользователя: ФИО, email, телефон, группа, курс, направление, институт, фото профиля.
2.2. Автоматические данные: Firebase UID, push-токен (OneSignal), данные об устройстве, журналы ошибок.

3. ЦЕЛИ ОБРАБОТКИ
3.1. Авторизация и идентификация.
3.2. Отображение расписания, новостей, мероприятий.
3.3. Отправка push-уведомлений.
3.4. Улучшение работы Приложения.

4. ПЕРЕДАЧА ДАННЫХ
4.1. Данные передаются: Google Firebase, Supabase, OneSignal.
4.2. Передача осуществляется в объёме, необходимом для работы Приложения.

5. ХРАНЕНИЕ И ЗАЩИТА
5.1. Данные хранятся на защищённых серверах.
5.2. Срок хранения — до удаления аккаунта.

6. ПРАВА ПОЛЬЗОВАТЕЛЯ
6.1. Отозвать согласие на обработку.
6.2. Удалить аккаунт через раздел «Профиль» → «Удалить аккаунт».

7. КОНТАКТЫ
Оператор: ФГАОУ ВО «СВФУ им. М.К. Аммосова»
Адрес: 677000, г. Якутск, ул. Кулаковского, 42
Email: info@s-vfu.ru

8. ИЗМЕНЕНИЯ
8.1. Оператор вправе изменять настоящую Политику.
8.2. Актуальная версия всегда доступна в Приложении.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _policyText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ),
            if (showAcceptButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Принять и продолжить'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
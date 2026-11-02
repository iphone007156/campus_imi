class AppStrings {
  static const Map<String, Map<String, String>> _localizedValues = {
    'ru': {
      'app_title': 'СВФУ Кампус',
      'news': 'Новости',
      'news_sub': 'Последние события',
      'tasks': 'Задания',
      'tasks_sub': 'Учебные задания',
      'schedule': 'Расписание',
      'schedule_sub': 'Расписание занятий',
      'union': 'Профсоюз',
      'union_sub': 'Студенческий профсоюз',
      'map': 'Карта',
      'map_sub': 'Карта корпуса',
      'gradebook': 'Зачётка',
      'gradebook_sub': 'Оценки и учебный план',
      'profile': 'Профиль',
      'profile_sub': 'Личный кабинет',
      'settings': 'Настройки',
      'language': 'Язык',
      'theme': 'Тема',
      'theme_system': 'Системная',
      'theme_light': 'Светлая',
      'theme_dark': 'Тёмная',
      'support': 'Техническая поддержка',
      'support_sub': 'Нужна помощь? Напишите нам',
      'services': 'СЕРВИСЫ',
      // Для зачетки
      'grades': 'Оценки',
      'plan': 'Учебный план',
      'avg_score': 'Средний балл',
      'subjects': 'ДИСЦИПЛИНЫ',
      'no_grades': 'Пока нет оценок',
    },
    'en': {
      'app_title': 'NEFU Campus',
      'news': 'News',
      'news_sub': 'Latest news',
      'tasks': 'Tasks',
      'tasks_sub': 'Study tasks',
      'schedule': 'Schedule',
      'schedule_sub': 'Class schedule',
      'union': 'Union',
      'union_sub': 'Student union',
      'map': 'Map',
      'map_sub': 'Campus map',
      'gradebook': 'Gradebook',
      'gradebook_sub': 'Grades and curriculum',
      'profile': 'Profile',
      'profile_sub': 'Personal account',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'support': 'Technical Support',
      'support_sub': 'Need help? Write to us',
      'services': 'SERVICES',
      // Для зачетки
      'grades': 'Grades',
      'plan': 'Curriculum',
      'avg_score': 'Average Score',
      'subjects': 'SUBJECTS',
      'no_grades': 'No grades yet',
    },
  };

  static String t(String key, String langCode) {
    // Берем словарь для нужного языка. Если его нет — берем русский.
    final map = _localizedValues[langCode] ?? _localizedValues['ru'];

    // Безопасно получаем значение. Если ключа нет — возвращаем сам ключ.
    return map?[key] ?? key;
  }
}
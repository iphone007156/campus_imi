class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }
    if (value.length < 2) {
      return 'Имя слишком короткое';
    }
    return null;
  }

  static String? validateGroup(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите группу';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Некорректный email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    if (value.length < 6) {
      return 'Пароль должен быть минимум 6 символов';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите телефон';
    }
    if (value.length < 10) {
      return 'Введите корректный номер телефона';
    }
    return null;
  }

  // ===== ДОБАВЛЕННЫЕ МЕТОДЫ =====

  static String? validateEventTitle(String? value) {  // ← ДЛЯ МЕРОПРИЯТИЙ
    if (value == null || value.isEmpty) {
      return 'Введите название мероприятия';
    }
    if (value.length < 3) {
      return 'Название должно содержать минимум 3 символа';
    }
    return null;
  }

  static String? validateEventDescription(String? value) {  // ← ДЛЯ ОПИСАНИЯ
    if (value == null || value.isEmpty) {
      return 'Введите описание';
    }
    if (value.length < 10) {
      return 'Описание должно содержать минимум 10 символов';
    }
    return null;
  }

  static String? validateEventDate(String? value) {  // ← ДЛЯ ДАТЫ
    if (value == null || value.isEmpty) {
      return 'Введите дату';
    }
    // Простая проверка формата ДД.ММ.ГГГГ
    final dateRegExp = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
    if (!dateRegExp.hasMatch(value)) {
      return 'Введите дату в формате ДД.ММ.ГГГГ';
    }
    return null;
  }

  static String? validateEventTime(String? value) {  // ← ДЛЯ ВРЕМЕНИ
    if (value == null || value.isEmpty) {
      return 'Введите время';
    }
    final timeRegExp = RegExp(r'^\d{2}:\d{2}$');
    if (!timeRegExp.hasMatch(value)) {
      return 'Введите время в формате ЧЧ:ММ';
    }
    return null;
  }

  static String? validateEventLocation(String? value) {  // ← ДЛЯ МЕСТА
    if (value == null || value.isEmpty) {
      return 'Введите место проведения';
    }
    return null;
  }

  static String? validateEventPoints(String? value) {  // ← ДЛЯ БАЛЛОВ
    if (value == null || value.isEmpty) {
      return 'Введите количество баллов';
    }
    final points = int.tryParse(value);
    if (points == null) {
      return 'Введите число';
    }
    if (points < 0) {
      return 'Баллы не могут быть отрицательными';
    }
    if (points > 100) {
      return 'Максимум 100 баллов';
    }
    return null;
  }

  static String? validateRoom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите аудиторию';
    }
    return null;
  }

  static String? validateTeacher(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите преподавателя';
    }
    return null;
  }

  static String? validateSubjectName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите название предмета';
    }
    return null;
  }
}
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ===== МОДЕЛИ =====
class StaffMember {
  final String name;
  final String position;
  final String? degree;

  const StaffMember(this.name, this.position, [this.degree]);
}

class StaffDepartment {
  final String title;
  final IconData icon;
  final Color color;
  final List<StaffMember> members;

  const StaffDepartment({
    required this.title,
    required this.icon,
    required this.color,
    required this.members,
  });
}

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  // ===== ДАННЫЕ =====
  static const List<StaffDepartment> _departments = [
    // ===== РУКОВОДСТВО =====
    StaffDepartment(
      title: 'РУКОВОДСТВО',
      icon: Icons.person_pin,
      color: Color(0xFF3D6FA3),
      members: [
        StaffMember('Пинигина Нюргуяна Романовна', 'Директор института',
            'кандидат физико-математических наук'),
        StaffMember('Лукина Анна Саввична', 'Секретарь'),
      ],
    ),

    // ===== АЛГЕБРА, ГЕОМЕТРИЯ =====
    StaffDepartment(
      title:
      'Кафедра "Алгебра, геометрия, математический анализ и дифференциальные уравнения"',
      icon: Icons.calculate,
      color: Color(0xFF2E7D52),
      members: [
        StaffMember('Егоров Иван Егорович', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Лазарев Нюргун Петрович', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Попов Сергей Вячеславович', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Попова Татьяна Семеновна', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Хлуднев Александр Михайлович', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Афанасьева Вера Ильинична', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Бубякин Игорь Витальевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Иванова Оксана Федотовна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Неустроева Татьяна Кимовна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Поисеева Саргылана Семеновна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Попов Николай Сергеевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Потапова Саргылана Викторовна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Романова Наталья Анатольевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Семенова Галина Егоровна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Семенова Галина Михайловна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Шарин Евгений Федорович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Ефимова Саргылана Афанасьевна', 'Заведующий кабинетом'),
        StaffMember('Ефремов Айдаар Айаалович', 'Ассистент'),
        StaffMember('Кычкин Айсен Григорьевич', 'Ассистент'),
      ],
    ),

    // ===== ИНФОРМАЦИОННЫЕ ТЕХНОЛОГИИ =====
    StaffDepartment(
      title: 'Кафедра "Информационные технологии"',
      icon: Icons.computer,
      color: Color(0xFF7E3FBF),
      members: [
        StaffMember('Николаева Наталья Васильевна', 'Заведующий кафедрой',
            'кандидат физико-математических наук'),
        StaffMember('Мордовской Сергей Денисович', 'Профессор',
            'доктор технических наук'),
        StaffMember('Васильев Максим Дмитриевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Васильева Наталья Васильевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Кондаков Айсен Алексеевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Кылатчанов Роман Михайлович', 'Доцент',
            'кандидат технических наук'),
        StaffMember('Леонтьев Ньургун Анатольевич', 'Доцент',
            'кандидат технических наук'),
        StaffMember('Павлов Никифор Никитич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Стручкова Анна Михайловна', 'Доцент',
            'кандидат технических наук'),
        StaffMember('Абрамова Мария Степановна', 'Старший преподаватель'),
        StaffMember('Гаврильева Лена Ивановна', 'Старший преподаватель'),
        StaffMember('Захарова Диана Дмитриевна', 'Старший преподаватель'),
        StaffMember('Качалин Николай Николаевич', 'Старший преподаватель'),
        StaffMember('Леверьев Владимир Семенович', 'Старший преподаватель'),
        StaffMember('Лыткин Сергей Дмитриевич', 'Старший преподаватель'),
        StaffMember('Никифоров Дьулустан Васильевич', 'Старший преподаватель'),
        StaffMember('Петрова Евгения Анатольевна', 'Старший преподаватель'),
        StaffMember('Соловьева Туйаара Максимовна', 'Старший преподаватель'),
        StaffMember('Эверстов Владимир Васильевич', 'Старший преподаватель'),
        StaffMember('Яковлева Вера Ивановна', 'Методист-тьютор'),
      ],
    ),

    // ===== МАТЕМАТИЧЕСКАЯ ЭКОНОМИКА =====
    StaffDepartment(
      title: 'Кафедра "Математическая экономика и прикладная информатика"',
      icon: Icons.trending_up,
      color: Color(0xFFB8922A),
      members: [
        StaffMember('Матвеева Нюргуяна Николаевна', 'Заведующий кафедрой',
            'кандидат физико-математических наук'),
        StaffMember('Бебихов Юрий Владимирович', 'Доцент',
            'доктор физико-математических наук'),
        StaffMember('Иванова Мария Анатольевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Кайгородов Степан Петрович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Крылова Екатерина Анатольевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Матвеева Майя Васильевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Местников Семен Владимирович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Набережная Анна Тимофеевна', 'Доцент',
            'кандидат экономических наук'),
        StaffMember('Николаева Ирина Валентиновна', 'Доцент',
            'кандидат экономических наук'),
        StaffMember('Семёнова Мария Николаевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Федорова Надежда Тимофеевна', 'Доцент'),
        StaffMember('Комкова Анастасия Николаевна', 'Старший преподаватель'),
        StaffMember('Курилкина Анна Петровна', 'Старший преподаватель'),
        StaffMember('Леонтьев Семен Павлович', 'Старший преподаватель'),
        StaffMember('Панова Ия Иннокентьевна', 'Старший преподаватель'),
        StaffMember('Романова Евгения Юрьевна', 'Старший преподаватель'),
        StaffMember('Саввин Эрхан Эдуардович', 'Старший преподаватель'),
        StaffMember('Спиридонова Нарыйа Руслановна', 'Старший преподаватель'),
        StaffMember('Федотова Юлия Григорьевна', 'Старший преподаватель'),
        StaffMember('Эверстова Галина Васильевна', 'Старший преподаватель'),
        StaffMember('Егорова Ирина Михайловна', 'Ассистент'),
        StaffMember('Кычкин Артемий Алексеевич', 'Ассистент'),
      ],
    ),

    // ===== ИНФОРМАЦИОННАЯ БЕЗОПАСНОСТЬ =====
    StaffDepartment(
      title:
      'Кафедра "Информационная безопасность и телекоммуникационные системы"',
      icon: Icons.security,
      color: Color(0xFF8A5A00),
      members: [
        StaffMember('Николаева Ирина Валентиновна', 'Заведующий кафедрой',
            'кандидат экономических наук'),
        StaffMember('Антонов Степан Романович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Бороев Роман Николаевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Вахрушева Юлия Петровна', 'Старший преподаватель'),
        StaffMember('Мальков Игорь Михайлович', 'Старший преподаватель'),
        StaffMember('Никифоров Алексей Васильевич', 'Ассистент'),
      ],
    ),

    // ===== ТЕОРИЯ И МЕТОДИКА =====
    StaffDepartment(
      title:
      'Кафедра "Теория и методика обучения математике и информатике"',
      icon: Icons.school,
      color: Color(0xFF2E7D52),
      members: [
        StaffMember('Ефремов Валентин Павлович', 'Заведующий кафедрой',
            'кандидат педагогических наук'),
        StaffMember('Антонов Юрий Саввич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Аргунова Нина Васильевна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Афанасьев Афанасий Егорович', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Винокурова Екатерина Спиридоновна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Дьячковская Мотрена Давидовна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Курилкина Валентина Николаевна', 'Доцент',
            'кандидат философских наук'),
        StaffMember('Макарова Саргылана Михайловна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Максимов Василий Васильевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Находкина Инна Иннокентьевна', 'Доцент'),
        StaffMember('Попова Алена Михайловна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Скрябина Алевтина Гавриловна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Тарабукина Айталина Алексеевна', 'Доцент'),
        StaffMember('Хачиров Сергей Владимирович', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Эверстова Валентина Николаевна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Адамова Александра Петровна', 'Старший преподаватель'),
        StaffMember('Винокурова Светлана Захаровна', 'Старший преподаватель'),
        StaffMember('Ефремова Евдокия Александровна', 'Старший преподаватель'),
        StaffMember('Налыяхова Алёна Алексеевна', 'Старший преподаватель'),
        StaffMember('Ситников Сергей Иванович', 'Старший преподаватель'),
      ],
    ),

    // ===== ВЫСШАЯ МАТЕМАТИКА =====
    StaffDepartment(
      title: 'Кафедра "Высшая математика"',
      icon: Icons.functions,
      color: Color(0xFF3D6FA3),
      members: [
        StaffMember('Васильев Максим Дмитриевич', 'Заведующий кафедрой',
            'кандидат физико-математических наук'),
        StaffMember('Трофимцев Юрий Иванович', 'Профессор',
            'доктор технических наук'),
        StaffMember('Аммосова Марита Саввична', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Вихрева Ольга Анатольевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Иванов Гаврил Иванович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Николаев Владимир Егорович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Пинигина Нюргуяна Романовна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Тарасова Галина Ивановна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Филиппова Майя Петровна', 'Доцент',
            'кандидат педагогических наук'),
        StaffMember('Богушевич Инна Павловна', 'Старший преподаватель'),
        StaffMember('Габышева Татьяна Петровна', 'Старший преподаватель'),
        StaffMember('Фролов Григорий Григорьевич', 'Старший преподаватель'),
        StaffMember('Миронова Саргылана Дмитриевна', 'Заведующий кабинетом'),
      ],
    ),

    // ===== КОМПЬЮТЕРНО-ИНФОРМАЦИОННЫЙ ЦЕНТР =====
    StaffDepartment(
      title: 'Компьютерно-информационный центр',
      icon: Icons.computer,
      color: Color(0xFF3D6FA3),
      members: [
        StaffMember('Афанасьев Эллэй Исаевич', 'Начальник'),
        StaffMember('Никифоров Алексей Васильевич', 'Ведущий программист'),
      ],
    ),

    // ===== ЛАБОРАТОРИЯ ИИ =====
    StaffDepartment(
      title:
      'Лаборатория "Вычислительные технологии и искусственный интеллект"',
      icon: Icons.psychology,
      color: Color(0xFF7E3FBF),
      members: [
        StaffMember('Вабищевич Петр Николаевич', 'Главный научный сотрудник',
            'доктор физико-математических наук'),
        StaffMember('Степанов Сергей Павлович', 'Руководитель лаборатории',
            'кандидат физико-математических наук'),
        StaffMember('Сивцев Петр Васильевич', 'Ведущий научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Алексеев Валентин Николаевич',
            'Старший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Григорьев Василий Васильевич',
            'Старший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Калачикова Уйгулаана Семеновна',
            'Старший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Спиридонов Денис Алексеевич',
            'Старший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Тырылгин Алексей Афанасьевич',
            'Старший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Аммосов Дмитрий Андреевич',
            'Младший научный сотрудник',
            'кандидат физико-математических наук'),
        StaffMember('Леверьев Владимир Семенович',
            'Младший научный сотрудник'),
        StaffMember('Захаров Тимур Захарович', 'Лаборант'),
        StaffMember('Новгородов Туйгун Александрович', 'Лаборант'),
        StaffMember('Подорожная Екатерина Сергеевна', 'Лаборант'),
      ],
    ),

    // ===== НИ КАФЕДРА ВЫЧИСЛИТЕЛЬНЫЕ ТЕХНОЛОГИИ =====
    StaffDepartment(
      title:
      'Научно-исследовательская кафедра "Вычислительные технологии"',
      icon: Icons.science_outlined,
      color: Color(0xFF2E7D52),
      members: [
        StaffMember('Васильев Василий Иванович', 'Заведующий кафедрой',
            'доктор физико-математических наук'),
        StaffMember('Вабищевич Петр Николаевич', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Гусев Евгений Леонидович', 'Профессор',
            'доктор физико-математических наук'),
        StaffMember('Акимов Мир Петрович', 'Доцент',
            'кандидат технических наук'),
        StaffMember('Алексеев Валентин Николаевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Афанасьева Надежда Михайловна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Григорьев Василий Васильевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Иванов Дьулус Харлампьевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Калачикова Уйгулаана Семеновна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Никифоров Дьулустан Яковлевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Сивцев Петр Васильевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Сивцева Вера Исаевна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Спиридонов Денис Алексеевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Степанов Сергей Павлович', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Тимофеева Татьяна Семеновна', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Тырылгин Алексей Афанасьевич', 'Доцент',
            'кандидат физико-математических наук'),
        StaffMember('Аммосов Альберт Владимирович', 'Старший преподаватель'),
        StaffMember('Охлопков Гаврил Николаевич', 'Старший преподаватель'),
        StaffMember('Ильина Кюннэй Павловна', 'Преподаватель'),
        StaffMember('Гуринов Айтал Иванович', 'Ассистент'),
        StaffMember('Саввин Антон Васильевич', 'Ассистент'),
      ],
    ),

    // ===== УЧЕБНО-МЕТОДИЧЕСКИЙ ОТДЕЛ =====
    StaffDepartment(
      title: 'Учебно-методический отдел ИМИ',
      icon: Icons.menu_book,
      color: Color(0xFFB8922A),
      members: [
        StaffMember('Дьячковская Нюргуяна Гавриловна', 'Начальник отдела'),
        StaffMember('Егорова Оксана Николаевна',
            'Специалист по УМР 1 категории'),
        StaffMember('Тимофеева Анна Александровна',
            'Специалист по УМР 1 категории'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Сотрудники ИМИ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departments.length,
        itemBuilder: (context, i) => _DepartmentSection(
          department: _departments[i],
        ),
      ),
    );
  }
}

// ===== СЕКЦИЯ КАФЕДРЫ =====
class _DepartmentSection extends StatelessWidget {
  final StaffDepartment department;

  const _DepartmentSection({required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          iconColor: department.color,
          collapsedIconColor: department.color,
          initiallyExpanded: false,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: department.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(department.icon,
                    color: department.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  department.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, left: 50),
            child: Text(
              '${department.members.length} чел.',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          children: department.members
              .map((m) => _StaffTile(member: m, color: department.color))
              .toList(),
        ),
      ),
    );
  }
}

// ===== КАРТОЧКА СОТРУДНИКА =====
class _StaffTile extends StatelessWidget {
  final StaffMember member;
  final Color color;

  const _StaffTile({required this.member, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.person, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.position,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (member.degree != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    member.degree!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
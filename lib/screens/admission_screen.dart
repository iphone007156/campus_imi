import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdmissionScreen extends StatelessWidget {
  const AdmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Поступающим'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== ШАПКА =====
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryNavy, Color(0xFF3D6FA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ИМИ СВФУ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Твой путь к цифровому будущему! ПоднИМИсь к вершинам!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ===== ПРЕИМУЩЕСТВА =====
          _Section(
            title: 'ПОЧЕМУ МЫ?',
            icon: Icons.star,
            children: const [
              _Advantage(
                icon: Icons.psychology,
                title: 'Освой востребованные технологии',
                text:
                'Мы первыми в республике запустили программу по искусственному интеллекту — '
                    '«Фундаментальная информатика и информационные технологии (Программная инженерия в ИИ)». '
                    'C/C++, Python, Java, C# — всё это ждёт тебя.',
                color: Color(0xFF7E3FBF),
              ),
              _Advantage(
                icon: Icons.school,
                title: 'Фундаментальные знания',
                text:
                'Математическая логика, теория алгоритмов, дискретная математика — всё то, '
                    'что формирует мышление настоящего инженера и исследователя.',
                color: Color(0xFF3D6FA3),
              ),
              _Advantage(
                icon: Icons.devices,
                title: 'Специалисты полного цикла',
                text:
                'От веб- и мобильных приложений до бэкенд- и фронтенд-разработки. '
                    'Ты сможешь создавать как пользовательские интерфейсы, так и сложные серверные решения.',
                color: Color(0xFF2E7D52),
              ),
              _Advantage(
                icon: Icons.payments,
                title: '200+ бюджетных мест',
                text:
                'У нас есть более 200 бюджетных мест по 11 направлениям подготовки, и мы ждём именно тебя! '
                    'Сдавай ЕГЭ по профильной математике, русскому языку, информатике или физике.',
                color: Color(0xFFB8922A),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== СТАТИСТИКА =====
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '258',
                  label: 'бюджетных мест',
                  icon: Icons.school_outlined,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '11',
                  label: 'направлений',
                  icon: Icons.list_alt,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '65',
                  label: 'платных мест',
                  icon: Icons.work_outline,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '200+',
                  label: 'проходной балл',
                  icon: Icons.trending_up,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ===== БАКАЛАВРИАТ =====
          _Section(
            title: 'БАКАЛАВРИАТ',
            icon: Icons.school,
            children: [
              _ProgramCard(
                code: '01.03.01',
                name: 'Математика',
                profile: 'Фундаментальные исследования и цифровая экономика',
                budget: 18,
                paid: 25,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 161',
                color: const Color(0xFF3D6FA3),
              ),
              _ProgramCard(
                code: '01.03.02',
                name: 'Прикладная математика и информатика',
                profile: 'Искусственный интеллект и анализ данных',
                budget: 18,
                paid: 5,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 200',
                color: const Color(0xFF7E3FBF),
              ),
              _ProgramCard(
                code: '01.03.02',
                name: 'Прикладная математика и информатика',
                profile: 'Математическое моделирование и вычислительная математика',
                budget: 18,
                paid: 5,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 171',
                color: const Color(0xFF7E3FBF),
              ),
              _ProgramCard(
                code: '02.03.02',
                name: 'Фундаментальная информатика и ИТ',
                profile: 'Программная инженерия в искусственном интеллекте',
                budget: 21,
                paid: 4,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 225',
                color: const Color(0xFF2E7D52),
              ),
              _ProgramCard(
                code: '09.03.01',
                name: 'Информатика и вычислительная техника',
                profile: 'Технологии разработки программного обеспечения',
                budget: 44,
                paid: 5,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 201',
                color: const Color(0xFF8A5A00),
              ),
              _ProgramCard(
                code: '09.03.03',
                name: 'Прикладная информатика',
                profile: 'Прикладная информатика в ГМУ',
                budget: 25,
                paid: 5,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 175',
                color: const Color(0xFFB8922A),
              ),
              _ProgramCard(
                code: '09.03.03',
                name: 'Прикладная информатика',
                profile: 'Прикладная информатика в экономике',
                budget: 25,
                paid: 5,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 184',
                color: const Color(0xFFB8922A),
              ),
              _ProgramCard(
                code: '10.05.03',
                name: 'Информационная безопасность АС',
                profile: 'Безопасность открытых информационных систем',
                budget: 25,
                paid: 5,
                years: '5 лет 6 мес',
                price: 'от 230 т.р./год',
                passingScore: '—',
                color: Colors.red,
              ),
              _ProgramCard(
                code: '11.03.02',
                name: 'Инфокоммуникационные технологии',
                profile: 'Многоканальные телекоммуникационные системы',
                budget: 20,
                paid: 2,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 165',
                color: const Color(0xFF3D6FA3),
              ),
              _ProgramCard(
                code: '44.03.01',
                name: 'Педагогическое образование',
                profile: 'Математика',
                budget: 22,
                paid: 2,
                years: '4 года',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 148',
                color: const Color(0xFF2E7D52),
              ),
              _ProgramCard(
                code: '44.03.05',
                name: 'Педагогическое образование',
                profile: 'Информатика и Математика',
                budget: 22,
                paid: 2,
                years: '5 лет',
                price: 'от 230 т.р./год',
                passingScore: '2024 — 124',
                color: const Color(0xFF2E7D52),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== МАГИСТРАТУРА =====
          _Section(
            title: 'МАГИСТРАТУРА',
            icon: Icons.school_outlined,
            children: [
              _ProgramCard(
                code: '01.04.01',
                name: 'Математика',
                profile: 'Математические основы ИИ и моделирования',
                budget: 8,
                paid: 6,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '—',
                color: const Color(0xFF3D6FA3),
              ),
              _ProgramCard(
                code: '01.04.02',
                name: 'Прикладная математика и информатика',
                profile: 'Вычислительные технологии',
                budget: 8,
                paid: 2,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 80',
                color: const Color(0xFF7E3FBF),
              ),
              _ProgramCard(
                code: '01.04.02',
                name: 'Прикладная математика и информатика',
                profile: 'Перспективные методы ИИ в сетях',
                budget: 9,
                paid: 2,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 80',
                color: const Color(0xFF7E3FBF),
              ),
              _ProgramCard(
                code: '02.04.02',
                name: 'Фундаментальная информатика и ИТ',
                profile: 'Управление проектами в области ИТ',
                budget: 10,
                paid: 2,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 90',
                color: const Color(0xFF2E7D52),
              ),
              _ProgramCard(
                code: '09.04.01',
                name: 'Информатика и вычислительная техника',
                profile: 'Управление разработкой ПО',
                budget: 8,
                paid: 2,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 90',
                color: const Color(0xFF8A5A00),
              ),
              _ProgramCard(
                code: '09.04.03',
                name: 'Прикладная информатика',
                profile: 'Прикладная информатика в экономике и управлении',
                budget: 9,
                paid: 20,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 109',
                color: const Color(0xFFB8922A),
              ),
              _ProgramCard(
                code: '09.04.03',
                name: 'Прикладная информатика',
                profile: 'Прикладная информатика в юриспруденции',
                budget: 8,
                paid: 20,
                years: '2 года',
                price: 'от 250 т.р./год',
                passingScore: '2025 — 108',
                color: const Color(0xFFB8922A),
              ),
              _ProgramCard(
                code: '27.04.05',
                name: 'Инноватика',
                profile: 'Управление инновациями в цифровой экономике',
                budget: 10,
                paid: 5,
                years: '2 года 6 мес',
                price: '105 т.р./год',
                passingScore: '—',
                color: Colors.purple,
              ),
              _ProgramCard(
                code: '44.04.01',
                name: 'Педагогическое образование',
                profile: 'Учитель-исследователь в области мат. образования',
                budget: 10,
                paid: 2,
                years: '2 года 6 мес',
                price: '105 т.р./год',
                passingScore: '2024 — 85',
                color: const Color(0xFF2E7D52),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== КОНТАКТЫ ПК =====
          _Section(
            title: 'ПРИЁМНАЯ КОМИССИЯ',
            icon: Icons.contacts,
            children: [
              _ContactRow(
                icon: Icons.person,
                label: 'Директор',
                value: 'Пинигина Нюргуяна Романовна',
              ),
              _ContactRow(
                icon: Icons.location_on,
                label: 'Адрес',
                value:
                '677000, г. Якутск, ул. Кулаковского, 48, корпус ФЕН, 4 этаж, каб. 441',
              ),
              _ContactRow(
                icon: Icons.phone,
                label: 'Телефон',
                value: '+7 (4112) 49-68-34',
              ),
              _ContactRow(
                icon: Icons.email,
                label: 'Email',
                value: 'imi-pk@svfu.ru',
              ),
              _ContactRow(
                icon: Icons.language,
                label: 'Сайт',
                value: 'www.s-vfu.ru/imi',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ВНИМАНИЕ =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Стоимость обучения указана с учётом максимальной скидки для абитуриентов '
                        'с высокими баллами ЕГЭ. Полная стоимость может быть выше. '
                        'Уточняйте в приёмной комиссии.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ===== СЕКЦИЯ =====
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.accentBlue),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== ПРЕИМУЩЕСТВО =====
class _Advantage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _Advantage({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== СТАТ-КАРТОЧКА =====
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КАРТОЧКА ПРОГРАММЫ =====
class _ProgramCard extends StatelessWidget {
  final String code;
  final String name;
  final String profile;
  final int budget;
  final int paid;
  final String years;
  final String price;
  final String passingScore;
  final Color color;

  const _ProgramCard({
    required this.code,
    required this.name,
    required this.profile,
    required this.budget,
    required this.paid,
    required this.years,
    required this.price,
    required this.passingScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: color,
          collapsedIconColor: color,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, left: 0),
            child: Text(
              profile,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            _Row('Форма обучения', 'Очная'),
            _Row('Срок обучения', years),
            _Row('Бюджетных мест', '$budget'),
            _Row('Платных мест', '$paid'),
            _Row('Стоимость', price),
            _Row('Проходной балл', passingScore),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КОНТАКТ =====
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accentBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
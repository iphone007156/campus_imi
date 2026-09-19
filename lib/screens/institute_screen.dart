import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admission_screen.dart';
import 'staff_screen.dart';

class InstituteScreen extends StatelessWidget {
  const InstituteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('ИМИ СВФУ'),
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
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: const Icon(Icons.school,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Институт математики',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'и информатики',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'СВФУ им. М.К. Аммосова',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== ПОСТУПАЮЩИМ =====
          _BigButton(
            title: 'ПОСТУПАЮЩИМ',
            subtitle: '258 бюджетных мест, 11 направлений',
            icon: Icons.school_outlined,
            gradientColors: const [AppTheme.gold, Color(0xFF8A5A00)],
            borderColor: AppTheme.gold,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdmissionScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ===== СОТРУДНИКИ =====
          _BigButton(
            title: 'СОТРУДНИКИ ИНСТИТУТА',
            subtitle: 'Руководство и преподаватели',
            icon: Icons.people,
            gradientColors: const [
              AppTheme.accentBlue,
              AppTheme.primaryNavy
            ],
            borderColor: AppTheme.accentBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffScreen()),
            ),
          ),
          const SizedBox(height: 20),

          // ===== ИСТОРИЯ =====
          _Section(
            title: 'ИСТОРИЯ ИНСТИТУТА',
            icon: Icons.history_edu,
            children: [
              _Paragraph(
                'История развития Института берет свое начало с отделения математики '
                    'физико-математического факультета Якутского пединститута.',
              ),
              _Paragraph(
                'С открытием в 1956 году Якутского государственного университета началась '
                    'усиленная подготовка научно-педагогических кадров по математике, а в 1977 году '
                    'физико-математический факультет университета был разделен на два факультета: '
                    'математический и физический. В 1999 году, по инициативе первого Президента '
                    'Республики Саха (Якутия) М.Е. Николаева, математический факультет был преобразован '
                    'в Институт математики и информатики.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ЦЕЛЬ =====
          _Section(
            title: 'НАША ЦЕЛЬ',
            icon: Icons.flag,
            children: [
              _Paragraph(
                'Основной целью нашего института является работа по воспитанию '
                    'высококвалифицированных кадров по следующим направлениям бакалавриата и магистратуры.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== НАПРАВЛЕНИЯ =====
          _Section(
            title: 'НАПРАВЛЕНИЯ ПОДГОТОВКИ',
            icon: Icons.workspaces_outline,
            children: [
              _DirectionItem(
                icon: Icons.functions,
                label: 'Математика',
                color: const Color(0xFF3D6FA3),
              ),
              _DirectionItem(
                icon: Icons.computer,
                label: 'Прикладная математика и информатика',
                color: const Color(0xFF2E7D52),
              ),
              _DirectionItem(
                icon: Icons.terminal,
                label:
                'Фундаментальная информатика и информационные технологии',
                color: const Color(0xFF8A5A00),
              ),
              _DirectionItem(
                icon: Icons.memory,
                label: 'Информатика и вычислительная техника',
                color: const Color(0xFF7E3FBF),
              ),
              _DirectionItem(
                icon: Icons.business_center,
                label: 'Прикладная информатика',
                color: const Color(0xFFB8922A),
              ),
              _DirectionItem(
                icon: Icons.school,
                label: 'Педагогическое образование',
                color: const Color(0xFF2E7D52),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== КАФЕДРЫ =====
          _Section(
            title: 'КАФЕДРЫ',
            icon: Icons.account_balance,
            children: [
              _DepartmentItem(
                icon: Icons.calculate,
                label:
                'Алгебра, геометрия, математический анализ и дифференциальные уравнения',
                color: const Color(0xFF3D6FA3),
              ),
              _DepartmentItem(
                icon: Icons.functions,
                label: 'Высшая математика',
                color: const Color(0xFF2E7D52),
              ),
              _DepartmentItem(
                icon: Icons.security,
                label:
                'Информационная безопасность и телекоммуникационные системы',
                color: const Color(0xFF8A5A00),
              ),
              _DepartmentItem(
                icon: Icons.computer,
                label: 'Информационные технологии',
                color: const Color(0xFF7E3FBF),
              ),
              _DepartmentItem(
                icon: Icons.trending_up,
                label: 'Математическая экономика и прикладная информатика',
                color: const Color(0xFFB8922A),
              ),
              _DepartmentItem(
                icon: Icons.school,
                label:
                'Теория и методика обучения математике и информатике',
                color: const Color(0xFF2E7D52),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== НАУЧНЫЕ ПОДРАЗДЕЛЕНИЯ =====
          _Section(
            title: 'НАУЧНЫЕ ПОДРАЗДЕЛЕНИЯ',
            icon: Icons.science,
            children: [
              _DepartmentItem(
                icon: Icons.computer,
                label: 'Компьютерно-информационный центр',
                color: const Color(0xFF3D6FA3),
              ),
              _DepartmentItem(
                icon: Icons.psychology,
                label:
                'Лаборатория "Вычислительные технологии и искусственный интеллект"',
                color: const Color(0xFF7E3FBF),
              ),
              _DepartmentItem(
                icon: Icons.science_outlined,
                label:
                'Научно-исследовательская кафедра "Вычислительные технологии"',
                color: const Color(0xFF2E7D52),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ОБРАЗОВАНИЕ =====
          _Section(
            title: 'ОБРАЗОВАНИЕ',
            icon: Icons.auto_stories,
            children: [
              _Paragraph(
                'Мы учим анализировать, ставить и формулировать новые цели и задачи. '
                    'Наши студенты овладевают аналитическим мышлением и готовностью к управлению '
                    'сложными системами.',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppTheme.gold, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Образование, полученное в стенах нашего института, дает универсальные '
                            'возможности для развития личности в профессиональном плане.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== РАЗВИТИЕ =====
          _Section(
            title: 'ПОСТОЯННОЕ РАЗВИТИЕ',
            icon: Icons.trending_up,
            children: [
              _Paragraph(
                'Институт математики и информатики постоянно развивается, открывая новые специальности, '
                    'внедряя новые технологии, вводя новые формы воспитательной работы со студентами.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '1956',
                      label: 'Год основания',
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      value: '1999',
                      label: 'Институт ИМИ',
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      value: '6',
                      label: 'Кафедр',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== КОНТАКТЫ =====
          _Section(
            title: 'КОНТАКТЫ',
            icon: Icons.contacts,
            children: [
              _ContactItem(
                icon: Icons.location_on,
                label: 'Адрес',
                value: 'г. Якутск, ул. Кулаковского, 48',
              ),
              _ContactItem(
                icon: Icons.language,
                label: 'Сайт',
                value: 'imi.s-vfu.ru',
              ),
              _ContactItem(
                icon: Icons.email,
                label: 'Email',
                value: 'imi@s-vfu.ru',
              ),
            ],
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '© СВФУ им. М.К. Аммосова',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ===== БОЛЬШАЯ КНОПКА =====
class _BigButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color borderColor;
  final VoidCallback onTap;

  const _BigButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                borderColor.withValues(alpha: 0.15),
                borderColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: borderColor.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: borderColor),
            ],
          ),
        ),
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
            padding: const EdgeInsets.all(16),
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

// ===== ПАРАГРАФ =====
class _Paragraph extends StatelessWidget {
  final String text;

  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textDark,
          height: 1.6,
        ),
      ),
    );
  }
}

// ===== НАПРАВЛЕНИЕ =====
class _DirectionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DirectionItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КАФЕДРА =====
class _DepartmentItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DepartmentItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== STAT BOX =====
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== КОНТАКТ =====
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.accentBlue, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
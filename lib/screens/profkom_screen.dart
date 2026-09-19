import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'profkom_team_screen.dart';

class ProfkomScreen extends StatelessWidget {
  const ProfkomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Профсоюз СВФУ'),
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
                    // ✅ Логотип ВНУТРИ кружка
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppTheme.gold,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/i.jpg',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.people,
                              color: AppTheme.accentBlue,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Первичная профсоюзная',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'организация студентов',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'СВФУ им. М.К. Аммосова',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ===== СТАТИСТИКА =====
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '10K+',
                  label: 'Членов профсоюза',
                  icon: Icons.groups,
                  color: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '18',
                  label: 'Организаций',
                  icon: Icons.account_balance,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '2',
                  label: 'Филиала',
                  icon: Icons.location_city,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '26',
                  label: 'Подразделений',
                  icon: Icons.hub,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ===== О ПРОФСОЮЗЕ =====
          _Section(
            title: 'О ПРОФСОЮЗЕ',
            icon: Icons.info_outline,
            children: [
              _Paragraph(
                'Первичная профсоюзная организация студентов СВФУ поддерживает студенческие инициативы, '
                    'представляет интересы студенчества, организует крупнейшие культурно-массовые и '
                    'спортивно-оздоровительные мероприятия, организует санаторно-курортное лечение студентов '
                    'и многое другое.',
              ),
              _Paragraph(
                'В её состав входят 18 профсоюзных организаций факультетов и институтов, '
                    '2 филиала в городах Нерюнгри и Мирный, 26 структурных подразделений, '
                    'объединяющих в своих рядах тысячи студентов-активистов. В настоящее время она '
                    'объединяет более 10 тысяч членов профсоюза.',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ЗАДАЧИ =====
          _Section(
            title: 'ОСНОВНЫЕ ЗАДАЧИ',
            icon: Icons.task_alt,
            children: [
              _TaskItem(
                icon: Icons.shield,
                text:
                'Защита социально-экономических, гражданских, законных прав и интересов студентов',
                color: AppTheme.accentBlue,
              ),
              _TaskItem(
                icon: Icons.handshake,
                text:
                'Помощь студентам в решении конфликтных ситуаций, социальных и материальных вопросов',
                color: Colors.green,
              ),
              _TaskItem(
                icon: Icons.campaign,
                text:
                'Лоббирование интересов студенчества перед администрацией Университета',
                color: Colors.orange,
              ),
              _TaskItem(
                icon: Icons.how_to_vote,
                text:
                'Участие представителей в комиссиях и советах, обсуждении нормативно-правовых актов',
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== ПРЕДСЕДАТЕЛЬ =====
          _Section(
            title: 'ПРЕДСЕДАТЕЛЬ ППОС СВФУ',
            icon: Icons.person,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryNavy,
                        border: Border.all(
                            color: AppTheme.accentBlue, width: 2),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Колесов Максим Семенович',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Председатель ППОС СВФУ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== КОМАНДА ППОС (КНОПКА) =====
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfkomTeamScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentBlue.withValues(alpha: 0.15),
                      AppTheme.accentBlue.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentBlue.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.accentBlue,
                            AppTheme.primaryNavy
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'КОМАНДА ППОС',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Заместители, комиссии, центры и председатели ПОС',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppTheme.accentBlue),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== ВОЗМОЖНОСТИ =====
          _Section(
            title: 'ВОЗМОЖНОСТИ ДЛЯ СТУДЕНТОВ',
            icon: Icons.star,
            children: [
              _Paragraph(
                'ППОС СВФУ — представительный орган самоуправления в Северо-Восточном '
                    'федеральном университете, дающая возможность:',
              ),
              const SizedBox(height: 8),
              _OpportunityItem(
                icon: Icons.psychology,
                text: 'Проявить себя',
                color: Colors.purple,
              ),
              _OpportunityItem(
                icon: Icons.chat_bubble_outline,
                text: 'Развить коммуникативные навыки',
                color: AppTheme.accentBlue,
              ),
              _OpportunityItem(
                icon: Icons.star_border,
                text: 'Развить лидерские качества',
                color: AppTheme.gold,
              ),
              _OpportunityItem(
                icon: Icons.event,
                text: 'Развить организаторские способности',
                color: Colors.orange,
              ),
              _OpportunityItem(
                icon: Icons.handshake_outlined,
                text: 'Научиться выстраивать партнерские отношения',
                color: Colors.green,
              ),
              _OpportunityItem(
                icon: Icons.gavel,
                text: 'Повысить правовую грамотность',
                color: Colors.red,
              ),
              _OpportunityItem(
                icon: Icons.verified_user,
                text: 'Защищать свои права',
                color: AppTheme.primaryNavy,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== РЕКВИЗИТЫ =====
          _Section(
            title: 'БАНКОВСКИЕ РЕКВИЗИТЫ',
            icon: Icons.account_balance,
            children: [
              _InfoRow(
                label: 'ОГРН',
                value: '1021400001600',
              ),
              _InfoRow(
                label: 'ИНН',
                value: '1435133801',
              ),
              _InfoRow(
                label: 'КПП',
                value: '143501001',
              ),
              const Divider(height: 20),
              _InfoRow(
                label: 'Банк',
                value:
                'Якутское отделение № 8603 ПАО Сбербанк г. Якутск',
              ),
              _InfoRow(
                label: 'к/с',
                value: '30101810400000000609',
              ),
              _InfoRow(
                label: 'р/с',
                value: '40703810276020100550',
              ),
              _InfoRow(
                label: 'БИК',
                value: '049805609',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== КОНТАКТЫ =====
          _Section(
            title: 'КОНТАКТЫ',
            icon: Icons.contacts,
            children: [
              _ContactRow(
                icon: Icons.location_on,
                label: 'Юридический адрес',
                value:
                '677000, РС(Я), г. Якутск, ул. Белинского 58, каб. 308, 309',
              ),
              _ContactRow(
                icon: Icons.phone,
                label: 'Телефон/Факс',
                value: '8 (4112) 35-25-61',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ===== ПОДВАЛ =====
          Center(
            child: Text(
              '© ППОС СВФУ им. М.К. Аммосова',
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

// ===== ЗАДАЧА =====
class _TaskItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TaskItem({
    required this.icon,
    required this.text,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== ВОЗМОЖНОСТЬ =====
class _OpportunityItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _OpportunityItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== СТРОКА ИНФО =====
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
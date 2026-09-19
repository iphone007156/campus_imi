import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ===== МОДЕЛИ =====
class TeamMember {
  final String name;
  final String position;
  final String? address;
  final String? phone;
  final String? fax;
  final String? email;
  final bool isChairman;

  const TeamMember(
      this.name,
      this.position, {
        this.address,
        this.phone,
        this.fax,
        this.email,
        this.isChairman = false,
      });
}

class TeamSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<TeamMember> members;

  const TeamSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.members,
  });
}

class ProfkomTeamScreen extends StatelessWidget {
  const ProfkomTeamScreen({super.key});

  // ===== ДАННЫЕ =====
  static const List<TeamSection> _sections = [
    // ===== ПРЕДСЕДАТЕЛЬ =====
    TeamSection(
      title: 'ПРЕДСЕДАТЕЛЬ ППОС СВФУ',
      icon: Icons.person_pin,
      color: Color(0xFFB8922A),
      members: [
        TeamMember(
          'Колесов Максим Семенович',
          'Председатель ППОС СВФУ',
          address: 'г. Якутск, ул. Белинского 58, каб. 308, 309',
          phone: '+7 (4112) 35-25-61',
          email: 'ppossvfu@mail.ru',
          isChairman: true,
        ),
      ],
    ),

    // ===== ЗАМЕСТИТЕЛИ =====
    TeamSection(
      title: 'ЗАМЕСТИТЕЛИ ПРЕДСЕДАТЕЛЯ',
      icon: Icons.people,
      color: Color(0xFF3D6FA3),
      members: [
        TeamMember(
          'Михайлов Пётр Александрович',
          'Первый заместитель председателя по общим вопросам',
          address: 'г. Якутск, ул. Каландаришвили, 17, Коворкинг-центр ППОС СВФУ',
          phone: '+7 (924) 663-31-19',
          fax: '+7 (4112) 35-25-61',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Егорова Кюнняй Александровна',
          'Первый заместитель по организации досуга студентов и имиджевой политике',
          address: 'г. Якутск, ул. Белинского, 58, каб. 308',
          phone: '+7 (962) 735-55-82',
          fax: '+7 (4112) 35-25-61',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Винокуров Гаврил Алексеевич',
          'Первый заместитель по финансово-экономической деятельности',
          address: 'г. Якутск, ул. Белинского, 58, каб. 308',
          phone: '+7 (996) 914-80-05',
          fax: '+7 (4112) 35-25-61',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Никифоров Сергей Вячеславович',
          'Первый заместитель по развитию студенческих инициатив',
          address: 'г. Якутск, ул. Белинского, 58, каб. 308',
          phone: '+7 (964) 420-03-26',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Оконешникова Айталина Игоревна',
          'Заместитель председателя по информационной политике',
          address: 'г. Якутск, ул. Каландаришвили, 17, Коворкинг-центр ППОС СВФУ',
          phone: '+7 (996) 315-92-67',
          fax: '+7 (4112) 35-25-61',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Карпов Николай Валерьевич',
          'Заместитель председателя по имиджевой и корпоративной политике',
          address: 'г. Якутск, ул. Белинского, 58, каб. 308',
          phone: '+7 (924) 568-73-02',
          email: 'ppossvfu@mail.ru',
        ),
        TeamMember(
          'Кардашевская Надежда Андреевна',
          'Заместитель председателя по организационно-массовой работе',
          address: 'г. Якутск, ул. Каландаришвили, 17, Коворкинг-центр ППОС СВФУ',
          phone: '+7 (914) 102-21-19',
          email: 'ppossvfu@mail.ru',
        ),
      ],
    ),

    // ===== АППАРАТ =====
    TeamSection(
      title: 'АППАРАТ ППОС СВФУ',
      icon: Icons.business_center,
      color: Color(0xFF7E3FBF),
      members: [
        TeamMember('Сергеев Михаил Степанович', 'Советник председателя'),
        TeamMember('Тихонова Елена Васильевна',
            'Руководитель аппарата председателя'),
        TeamMember('Лугинова Августина Иннокентьевна', 'Главный бухгалтер'),
        TeamMember('Охлопкова Алина Алексеевна', 'Референт'),
        TeamMember('Колесов Константин Васильевич',
            'Руководитель аппарата МГЕР СВФУ'),
        TeamMember('Стручкова Наталья Дьулустановна',
            'Председатель Старостата СВФУ'),
        TeamMember('Габышев Артур Петрович', 'Старший профкоординатор'),
        TeamMember('Петров Кирилл Алексеевич', 'Старший профкоординатор'),
        TeamMember('Обоева Ирина Константиновна', 'Старший профкоординатор'),
        TeamMember('Николаева Сардана Дмитриевна', 'Старший профкоординатор'),
      ],
    ),

    // ===== КОМИССИИ =====
    TeamSection(
      title: 'КОМИССИИ',
      icon: Icons.groups,
      color: Color(0xFF2E7D52),
      members: [
        TeamMember('Платонов Семен Гаврильевич',
            'Комиссия по культурно-массовой работе «Точка кипения»'),
        TeamMember('Алексеев Игорь Георгиевич',
            'Комиссия по спорту «Олимп»'),
        TeamMember('Борисова Василина Михайловна',
            'Комиссия по имиджевой и корпоративной политике «ИМКО»'),
        TeamMember('Наумова Дарина Никитична',
            'Комиссия по делам семьи «Суперсемейка»'),
        TeamMember('Назаров Алексей Валерьевич',
            'Комиссия по безопасности'),
        TeamMember('Баишев Владислав Николаевич',
            'Комиссия по материальной помощи «Рука помощи»'),
        TeamMember('Зверев Евгений Евгеньевич',
            'Комиссия по организационно-массовой работе'),
      ],
    ),

    // ===== ЦЕНТРЫ И КЛУБЫ =====
    TeamSection(
      title: 'ЦЕНТРЫ И КЛУБЫ',
      icon: Icons.emoji_events,
      color: Color(0xFF8A5A00),
      members: [
        TeamMember('Ефимов Николай Андреевич', 'Руководитель Центра качества'),
        TeamMember('Бурнашев Александр Гаврильевич',
            'Комиссия по внешним связям «Альфа»'),
        TeamMember('Бурцева Лилия Гаврильевна', 'Руководитель Медиацентра'),
        TeamMember('Габышев Афанасий Владимирович',
            'Центр юридической помощи «ЩИТ»'),
        TeamMember('Иванов Уолан Владимирович',
            'Центр развития музыкантов «АЙАР Sound»'),
        TeamMember('Мярин Артем Владимирович',
            'Военно-патриотический центр «Улуу үһүйээн»'),
        TeamMember('Степанов Александр Михайлович',
            'Клуб рок-музыкантов "Drum\'n\'Bass"'),
        TeamMember('Зыков Кирилл Игнатович',
            'Танцевальная группа "RED CODE"'),
        TeamMember('Аргунов Александр Алексеевич',
            'Киберспортивный клуб «Yakutza»'),
        TeamMember('Бурцев Максим Андреевич',
            'Модельная группа «Studmodels»'),
        TeamMember('Городецкий Максим Романович',
            'Педагогический отряд "BigTime"'),
        TeamMember('Афанасьева Анна Михайловна', 'Руководитель пресс-службы'),
      ],
    ),

    // ===== ОТДЕЛЫ =====
    TeamSection(
      title: 'ОТДЕЛЫ',
      icon: Icons.support,
      color: Color(0xFF3D6FA3),
      members: [
        TeamMember('Ефимов Герман Алексеевич',
            'Начальник отдела по материально-техническому обеспечению'),
      ],
    ),

    // ===== ПРЕДСЕДАТЕЛИ ПОС =====
    TeamSection(
      title: 'ПРЕДСЕДАТЕЛИ ПОС ФАКУЛЬТЕТОВ И ИНСТИТУТОВ',
      icon: Icons.school,
      color: Color(0xFFB8922A),
      members: [
        TeamMember('Гермогенова Ирина Станиславовна', 'Председатель ПОС ИМИ'),
        TeamMember('Монастырев Эрэл Егорович', 'И.о. Председателя ПОС АДФ'),
        TeamMember('Антонов Айаал Владимирович', 'Председатель ПОС ГИ'),
        TeamMember('Васильев Станислав Александрович',
            'Председатель ПОС ГРФ'),
        TeamMember('Абрамов Альберт Александрович',
            'Вр.и.о. Председателя ПОС ИЕН'),
        TeamMember('Ядреева Валерия Анатольевна', 'Председатель ПОС ИЗФиР'),
        TeamMember('Саввинов Айсиэн Валентинович', 'Председатель ПОС ИП'),
        TeamMember('Саввинов Сергей Арианович', 'Председатель ПОС ИТИ'),
        TeamMember('Васильева Анна Саввитомовна', 'Председатель ПОС ИФ'),
        TeamMember('Кононов Виктор Владимирович',
            'Председатель ПОС ИФКиС'),
        TeamMember('Неустроева Дая Семеновна',
            'Председатель ПОС ИЯКН СВ РФ'),
        TeamMember('Шадрин Василий Евгеньевич', 'Председатель ПОС КИТ'),
        TeamMember('Ощепков Владислав Владимирович', 'Председатель ПОС МИ'),
        TeamMember('Куприянов Арнольд Геннадьевич', 'Председатель ПОС ПИ'),
        TeamMember('Сидорова Наталья Нюргуновна', 'Председатель ПОС ФЛФ'),
        TeamMember('Сыроватский Арылхан Николаевич',
            'Председатель ПОС ФТИ'),
        TeamMember('Васильев Эмилиан Русланович', 'Председатель ПОС ФЭИ'),
        TeamMember('Дмитриев Дьуластан Ильич', 'Председатель ПОС ЮФ'),
        TeamMember('Сакердонова Нарыйаана Климентовна',
            'Председатель ПОС МПТИ'),
        TeamMember('Васюкович Эльвира Игоревна', 'Председатель ПОС НТИ'),
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
        title: const Text('Команда ППОС'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        itemBuilder: (context, i) => _SectionCard(
          section: _sections[i],
        ),
      ),
    );
  }
}

// ===== КАРТОЧКА СЕКЦИИ =====
class _SectionCard extends StatelessWidget {
  final TeamSection section;

  const _SectionCard({required this.section});

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
          iconColor: section.color,
          collapsedIconColor: section.color,
          initiallyExpanded: true,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: section.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
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
              '${section.members.length} чел.',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          children: section.members
              .map((m) => _MemberTile(member: m, color: section.color))
              .toList(),
        ),
      ),
    );
  }
}

// ===== КАРТОЧКА УЧАСТНИКА =====
class _MemberTile extends StatelessWidget {
  final TeamMember member;
  final Color color;

  const _MemberTile({required this.member, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(
                      color: color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(
                  member.isChairman ? Icons.star : Icons.person,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.position,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ===== КОНТАКТЫ =====
          if (member.address != null ||
              member.phone != null ||
              member.fax != null ||
              member.email != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            if (member.address != null)
              _ContactLine(
                icon: Icons.location_on,
                text: member.address!,
                color: color,
              ),
            if (member.phone != null)
              _ContactLine(
                icon: Icons.phone,
                text: member.phone!,
                color: color,
              ),
            if (member.fax != null)
              _ContactLine(
                icon: Icons.print,
                text: 'Факс: ${member.fax}',
                color: color,
              ),
            if (member.email != null)
              _ContactLine(
                icon: Icons.email,
                text: member.email!,
                color: color,
              ),
          ],
        ],
      ),
    );
  }
}

// ===== СТРОКА КОНТАКТА =====
class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContactLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
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
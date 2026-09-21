import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/lesson.dart';

class AddScheduleScreen extends StatefulWidget {
  /// ✅ null = создание, не null = редактирование
  final Lesson? lesson;

  const AddScheduleScreen({super.key, this.lesson});

  bool get isEditing => lesson != null;

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _teacherController = TextEditingController();
  final _roomController = TextEditingController();

  int _selectedDay = 0;
  int _selectedWeek = 0;
  int _selectedTimeIndex = 0;
  String _selectedType = 'лек';
  String _selectedGroup = 'Б-ПИГМУ-24';

  bool _isLoading = false;

  static const List<String> _groups = [
    'Б-ПИГМУ-24',
    'Б-ПИЭ-24',
    'Б-ИВТ-24-1',
    'Б-ИВТ-24-2',
    'Б-ФИИТ-24',
  ];

  static const List<String> _days = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
  ];

  static const List<String> _weeks = [
    'Общая (каждую неделю)',
    'Нечётная',
    'Чётная',
  ];

  static const List<String> _timeSlots = [
    '8:00-9:35',
    '9:50-11:25',
    '11:40-13:15',
    '14:00-15:35',
    '15:50-17:25',
    '17:40-19:15',
  ];

  static const List<Map<String, String>> _types = [
    {'value': 'лек', 'label': 'Лекция'},
    {'value': 'пр', 'label': 'Практика'},
    {'value': 'лаб', 'label': 'Лабораторная'},
    {'value': 'сем', 'label': 'Семинар'},
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Если редактирование — заполняем поля
    if (widget.lesson != null) {
      final lesson = widget.lesson!;
      _subjectController.text = lesson.subject;
      _teacherController.text = lesson.teacher;
      _roomController.text = lesson.room;
      _selectedDay = lesson.dayIndex;
      _selectedWeek = lesson.week;
      _selectedType = lesson.type;
      _selectedGroup = lesson.group;

      final timeIndex = _timeSlots.indexOf(lesson.time);
      if (timeIndex != -1) _selectedTimeIndex = timeIndex;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final lesson = Lesson(
        id: widget.lesson?.id ?? '',
        time: _timeSlots[_selectedTimeIndex],
        subject: _subjectController.text.trim(),
        teacher: _teacherController.text.trim(),
        room: _roomController.text.trim(),
        type: _selectedType,
        dayIndex: _selectedDay,
        group: _selectedGroup,
        week: _selectedWeek,
      );

      if (widget.isEditing) {
        // ✅ Редактирование
        await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lesson.id)
            .update(lesson.toMap());
      } else {
        // ✅ Создание
        await FirebaseFirestore.instance
            .collection('lessons')
            .add(lesson.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? '✅ Занятие обновлено!'
                : '✅ Занятие добавлено!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Ошибка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditing ? 'Редактировать занятие' : 'Добавить занятие'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSchedule,
            child: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Text('Сохранить',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle('День недели'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_days.length, (i) {
                  final isSelected = i == _selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryNavy
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryNavy
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        _days[i],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              _SectionTitle('Неделя'),
              const SizedBox(height: 8),
              Column(
                children: List.generate(_weeks.length, (i) {
                  final isSelected = i == _selectedWeek;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWeek = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryNavy.withValues(alpha: 0.1)
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryNavy
                              : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppTheme.primaryNavy
                                : AppTheme.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _weeks[i],
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              _SectionTitle('Группа'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGroup,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _groups.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGroup = value);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _SectionTitle('Время занятия'),
              const SizedBox(height: 8),
              Column(
                children: List.generate(_timeSlots.length, (i) {
                  final isSelected = i == _selectedTimeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentBlue.withValues(alpha: 0.1)
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? AppTheme.accentBlue
                                : AppTheme.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time,
                              size: 18, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            _timeSlots[i],
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              _SectionTitle('Название предмета'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  hintText: 'Иностранный язык',
                  prefixIcon: Icon(Icons.book_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.cardWhite,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _SectionTitle('Преподаватель'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(
                  hintText: 'Егорова Т.Н.',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.cardWhite,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите преподавателя';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _SectionTitle('Аудитория'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  hintText: '561',
                  prefixIcon: Icon(Icons.room_outlined),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppTheme.cardWhite,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите аудиторию';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _SectionTitle('Тип занятия'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedType = type['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentBlue
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentBlue
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        type['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveSchedule,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(widget.isEditing ? Icons.save : Icons.add),
                  label: Text(
                    _isLoading
                        ? 'Сохранение...'
                        : (widget.isEditing
                        ? 'Сохранить изменения'
                        : 'Добавить занятие'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}
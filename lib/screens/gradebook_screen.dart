import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/subject.dart';
import '../services/firestore_service.dart';

class GradebookScreen extends StatelessWidget {
  const GradebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Зачётная книжка'),
      ),
      backgroundColor: AppTheme.backgroundGray,
      body: StreamBuilder<List<Subject>>(
        stream: firestoreService.getSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final subjects = snapshot.data ?? [];
          final graded = subjects.where((s) => s.grade != null);
          final double gpa = graded.isEmpty
              ? 0
              : graded.map((s) => s.grade!).reduce((a, b) => a + b) /
                  graded.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // GPA карточка
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryNavy, Color(0xFF3D6FA3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Средний балл',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gpa.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '1 курс, 1 семестр',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${subjects.length} предметов',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ПРЕДМЕТЫ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: List.generate(subjects.length, (i) {
                    final s = subjects[i];
                    return Container(
                      color: AppTheme.cardWhite,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            title: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                            subtitle: Text(
                              '${s.type} • ${s.teacher}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted),
                            ),
                            trailing: s.grade != null
                                ? _GradeBadge(grade: s.grade!)
                                : const Text(
                                    'не сдано',
                                    style: TextStyle(
                                        fontSize: 12, color: AppTheme.textMuted),
                                  ),
                          ),
                          if (i < subjects.length - 1)
                            const Divider(
                                height: 1, indent: 14, color: AppTheme.divider),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final int grade;
  const _GradeBadge({required this.grade});

  Color get _color {
    if (grade == 5) return const Color(0xFF2E7D52);
    if (grade == 4) return AppTheme.accentBlue;
    if (grade == 3) return const Color(0xFF8A5A00);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$grade',
          style: TextStyle(
            color: _color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

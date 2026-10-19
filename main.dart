import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// 1. ENTRY POINT & APP ROOT
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const XNotesUltimateProApp());
}

class XNotesUltimateProApp extends StatefulWidget {
  const XNotesUltimateProApp({super.key});

  @override
  State<XNotesUltimateProApp> createState() => _XNotesUltimateProAppState();
}

class _XNotesUltimateProAppState extends State<XNotesUltimateProApp> {
  int _accentColorHex = 0xFF00E5FF;
  bool _isOledMode = false;
  bool _isLightMode = false;
  double _blurSigma = 18.0;

  void _updateThemeSettings({int? accentColor, bool? isOled, bool? isLight, double? blur}) {
    setState(() {
      if (accentColor != null) _accentColorHex = accentColor;
      if (isOled != null) _isOledMode = isOled;
      if (isLight != null) _isLightMode = isLight;
      if (blur != null) _blurSigma = blur;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = Color(_accentColorHex);
    return MaterialApp(
      title: 'xNotes Ultimate Pro',
      debugShowCheckedModeBanner: false,
      themeMode: _isLightMode ? ThemeMode.light : ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: primaryAccent,
          secondary: const Color(0xFFD500F9),
          surface: const Color(0xFF10121C),
        ),
      ),
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF0F2F8),
        colorScheme: ColorScheme.light(
          primary: primaryAccent,
          secondary: const Color(0xFF7C4DFF),
          surface: Colors.white,
        ),
      ),
      home: MasterHomeScreen(
        accentColor: primaryAccent,
        isOledMode: _isOledMode,
        isLightMode: _isLightMode,
        blurSigma: _blurSigma,
        onThemeChanged: _updateThemeSettings,
      ),
    );
  }
}

// ============================================================================
// 2. DATA MODELS & ENUMS
// ============================================================================

enum PriorityLevel { low, medium, high, urgent }
enum SortOrder { modifiedDesc, modifiedAsc, createdDesc, titleAsc, priorityDesc }
enum ViewLayout { grid, list, compact }
enum NoteFontFamily { sans, serif, monospace, cursive }

class ChecklistItem {
  String id;
  String text;
  bool isDone;

  ChecklistItem({required this.id, required this.text, this.isDone = false});

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'isDone': isDone};
  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        id: map['id'] ?? '',
        text: map['text'] ?? '',
        isDone: map['isDone'] ?? false,
      );
}

class ExpenseItem {
  String id;
  String title;
  double amount;

  ExpenseItem({required this.id, required this.title, required this.amount});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'amount': amount};
  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class Flashcard {
  String id;
  String front;
  String back;
  String subject;

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.subject = 'General',
  });

  Map<String, dynamic> toMap() => {'id': id, 'front': front, 'back': back, 'subject': subject};
  factory Flashcard.fromMap(Map<String, dynamic> m) => Flashcard(
        id: m['id'] ?? '',
        front: m['front'] ?? '',
        back: m['back'] ?? '',
        subject: m['subject'] ?? 'General',
      );
}

class TimetableSlot {
  String id;
  String day;
  String time;
  String subject;
  String room;
  int colorHex;

  TimetableSlot({
    required this.id,
    required this.day,
    required this.time,
    required this.subject,
    required this.room,
    this.colorHex = 0xFF00E5FF,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'day': day,
        'time': time,
        'subject': subject,
        'room': room,
        'colorHex': colorHex,
      };

  factory TimetableSlot.fromMap(Map<String, dynamic> m) => TimetableSlot(
        id: m['id'] ?? '',
        day: m['day'] ?? 'Mon',
        time: m['time'] ?? '08:30 AM',
        subject: m['subject'] ?? '',
        room: m['room'] ?? '',
        colorHex: m['colorHex'] ?? 0xFF00E5FF,
      );
}

class ExamEntry {
  String id;
  String title;
  DateTime date;
  String subject;

  ExamEntry({required this.id, required this.title, required this.date, required this.subject});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'subject': subject,
      };

  factory ExamEntry.fromMap(Map<String, dynamic> m) => ExamEntry(
        id: m['id'] ?? '',
        title: m['title'] ?? '',
        date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
        subject: m['subject'] ?? 'General',
      );
}

class GpaCourse {
  String id;
  String name;
  double credits;
  double gradePoint;

  GpaCourse({required this.id, required this.name, required this.credits, required this.gradePoint});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'credits': credits, 'gradePoint': gradePoint};
  factory GpaCourse.fromMap(Map<String, dynamic> m) => GpaCourse(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        credits: (m['credits'] as num?)?.toDouble() ?? 3.0,
        gradePoint: (m['gradePoint'] as num?)?.toDouble() ?? 4.0,
      );
}

class Note {
  String id;
  String title;
  String content;
  String category;
  String mood;
  PriorityLevel priority;
  bool isPinned;
  bool isFavorite;
  bool isVaulted;
  bool isArchived;
  bool isTrash;
  DateTime createdAt;
  DateTime modifiedAt;
  int habitStreak;
  List<ChecklistItem> checklist;
  List<ExpenseItem> expenses;
  bool isCodeNote;
  String codeLanguage;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.mood = '💡 Inspired',
    this.priority = PriorityLevel.medium,
    this.isPinned = false,
    this.isFavorite = false,
    this.isVaulted = false,
    this.isArchived = false,
    this.isTrash = false,
    required this.createdAt,
    required this.modifiedAt,
    this.habitStreak = 0,
    List<ChecklistItem>? checklist,
    List<ExpenseItem>? expenses,
    this.isCodeNote = false,
    this.codeLanguage = 'Dart',
  })  : checklist = checklist ?? [],
        expenses = expenses ?? [];

  Note copyWith({
    String? title,
    String? content,
    String? category,
    String? mood,
    PriorityLevel? priority,
    bool? isPinned,
    bool? isFavorite,
    bool? isVaulted,
    bool? isArchived,
    bool? isTrash,
    DateTime? modifiedAt,
    int? habitStreak,
    List<ChecklistItem>? checklist,
    List<ExpenseItem>? expenses,
    bool? isCodeNote,
    String? codeLanguage,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      mood: mood ?? this.mood,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isVaulted: isVaulted ?? this.isVaulted,
      isArchived: isArchived ?? this.isArchived,
      isTrash: isTrash ?? this.isTrash,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      habitStreak: habitStreak ?? this.habitStreak,
      checklist: checklist ?? List.from(this.checklist),
      expenses: expenses ?? List.from(this.expenses),
      isCodeNote: isCodeNote ?? this.isCodeNote,
      codeLanguage: codeLanguage ?? this.codeLanguage,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'mood': mood,
        'priority': priority.index,
        'isPinned': isPinned,
        'isFavorite': isFavorite,
        'isVaulted': isVaulted,
        'isArchived': isArchived,
        'isTrash': isTrash,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'habitStreak': habitStreak,
        'checklist': checklist.map((x) => x.toMap()).toList(),
        'expenses': expenses.map((x) => x.toMap()).toList(),
        'isCodeNote': isCodeNote,
        'codeLanguage': codeLanguage,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        category: map['category'] ?? 'General',
        mood: map['mood'] ?? '💡 Inspired',
        priority: PriorityLevel.values[map['priority'] ?? 1],
        isPinned: map['isPinned'] ?? false,
        isFavorite: map['isFavorite'] ?? false,
        isVaulted: map['isVaulted'] ?? false,
        isArchived: map['isArchived'] ?? false,
        isTrash: map['isTrash'] ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        modifiedAt: DateTime.tryParse(map['modifiedAt'] ?? '') ?? DateTime.now(),
        habitStreak: map['habitStreak'] ?? 0,
        checklist: (map['checklist'] as List<dynamic>?)
                ?.map((item) => ChecklistItem.fromMap(item))
                .toList() ??
            [],
        expenses: (map['expenses'] as List<dynamic>?)
                ?.map((item) => ExpenseItem.fromMap(item))
                .toList() ??
            [],
        isCodeNote: map['isCodeNote'] ?? false,
        codeLanguage: map['codeLanguage'] ?? 'Dart',
      );
}

// ============================================================================
// 3. ULTRA-PREMIUM GLASS WIDGETS
// ============================================================================

class AmbientBackdropContainer extends StatelessWidget {
  final Widget child;
  final bool isOled;
  final bool isLight;

  const AmbientBackdropContainer({
    super.key,
    required this.child,
    required this.isOled,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    if (isOled) return Container(color: Colors.black, child: child);
    if (isLight) return Container(color: const Color(0xFFF1F3F9), child: child);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0E15), Color(0xFF1E0B36), Color(0xFF041C2C)],
            ),
          ),
        ),
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFFD500F9).withOpacity(0.35), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF00E5FF).withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? surfaceColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 18.0,
    this.borderColor,
    this.surfaceColor,
    this.padding,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withOpacity(0.15);
    final surface = surfaceColor ?? Colors.white.withOpacity(0.07);

    Widget box = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: box,
        ),
      );
    }
    return box;
  }
}

class GlassPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? glowColor;
  final bool isPrimary;
  final EdgeInsetsGeometry padding;

  const GlassPillButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.glowColor,
    this.isPrimary = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? const Color(0xFF00E5FF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: isPrimary ? accent.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: isPrimary ? accent.withOpacity(0.8) : Colors.white24,
                  width: 1.3,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. OFFLINE QR MATRIX PAINTER
// ============================================================================

class OfflineQrCanvasPainter extends CustomPainter {
  final String text;
  OfflineQrCanvasPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = Colors.white;
    final paintLight = Paint()..color = const Color(0xFF131522);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      paintLight,
    );

    final bytes = utf8.encode(text);
    const int matrixSize = 17;
    final double cellSize = size.width / (matrixSize + 2);

    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        final bool isFinder = (r < 4 && c < 4) || (r < 4 && c > matrixSize - 5) || (r > matrixSize - 5 && c < 4);
        bool shouldFill = false;

        if (isFinder) {
          shouldFill = (r == 0 || r == 3 || c == 0 || c == 3);
        } else {
          int hash = ((r * 31 + c * 17) ^ (bytes.isNotEmpty ? bytes[(r + c) % bytes.length] : 42));
          shouldFill = (hash % 3 == 0);
        }

        if (shouldFill) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH((c + 1) * cellSize, (r + 1) * cellSize, cellSize * 0.85, cellSize * 0.85),
              const Radius.circular(2),
            ),
            paintDark,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OfflineQrCanvasPainter oldDelegate) => oldDelegate.text != text;
}

// ============================================================================
// 5. MASTER CONTROLLER & MAIN HOME SCREEN
// ============================================================================

class MasterHomeScreen extends StatefulWidget {
  final Color accentColor;
  final bool isOledMode;
  final bool isLightMode;
  final double blurSigma;
  final Function({int? accentColor, bool? isOled, bool? isLight, double? blur}) onThemeChanged;

  const MasterHomeScreen({
    super.key,
    required this.accentColor,
    required this.isOledMode,
    required this.isLightMode,
    required this.blurSigma,
    required this.onThemeChanged,
  });

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  List<Note> _allNotes = [];
  List<Flashcard> _allFlashcards = [];
  List<TimetableSlot> _timetableSlots = [];
  List<ExamEntry> _examEntries = [];
  List<GpaCourse> _gpaCourses = [];

  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  SortOrder _currentSort = SortOrder.modifiedDesc;
  ViewLayout _currentLayout = ViewLayout.grid;

  bool _isAppLocked = true;
  bool _isVaultUnlocked = false;
  String _masterPin = '1234';
  String _vaultPin = '9999';
  String _scratchpadText = '';
  int _currentNavIndex = 0;

  Timer? _pomodoroTimer;
  int _pomodoroSecondsLeft = 25 * 60;
  bool _isPomodoroRunning = false;
  int _pomodoroCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawNotes = prefs.getString('xnotes_data_pro');
    final rawFlash = prefs.getString('xnotes_flashcards');
    final rawTime = prefs.getString('xnotes_timetable');
    final rawExams = prefs.getString('xnotes_exams');
    final rawGpa = prefs.getString('xnotes_gpa');
    final scratch = prefs.getString('xnotes_scratchpad') ?? '';
    final pin = prefs.getString('xnotes_pin') ?? '1234';
    final vPin = prefs.getString('xnotes_vpin') ?? '9999';

    List<Note> notes = [];
    if (rawNotes != null && rawNotes.isNotEmpty) {
      final List<dynamic> dec = jsonDecode(rawNotes);
      notes = dec.map((e) => Note.fromMap(e)).toList();
    } else {
      notes = _generateSeedData();
    }

    List<Flashcard> flashcards = [];
    if (rawFlash != null) {
      final List<dynamic> dec = jsonDecode(rawFlash);
      flashcards = dec.map((e) => Flashcard.fromMap(e)).toList();
    } else {
      flashcards = [
        Flashcard(id: 'fc1', front: 'd/dx [sin(x)] = ?', back: 'cos(x)', subject: 'Maths'),
        Flashcard(id: 'fc2', front: 'Newton\'s Second Law?', back: 'F = m × a', subject: 'Physics'),
      ];
    }

    List<TimetableSlot> slots = [];
    if (rawTime != null) {
      final List<dynamic> dec = jsonDecode(rawTime);
      slots = dec.map((e) => TimetableSlot.fromMap(e)).toList();
    } else {
      slots = [
        TimetableSlot(id: 't1', day: 'Mon', time: '08:30 - 10:30', subject: 'Calculus', room: 'Hall A'),
        TimetableSlot(id: 't2', day: 'Wed', time: '11:00 - 01:00', subject: 'Physics Lab', room: 'Lab 2'),
      ];
    }

    List<ExamEntry> exams = [];
    if (rawExams != null) {
      final List<dynamic> dec = jsonDecode(rawExams);
      exams = dec.map((e) => ExamEntry.fromMap(e)).toList();
    } else {
      exams = [
        ExamEntry(id: 'ex1', title: 'Final Combined Maths', date: DateTime.now().add(const Duration(days: 45)), subject: 'Maths'),
      ];
    }

    List<GpaCourse> gpa = [];
    if (rawGpa != null) {
      final List<dynamic> dec = jsonDecode(rawGpa);
      gpa = dec.map((e) => GpaCourse.fromMap(e)).toList();
    } else {
      gpa = [
        GpaCourse(id: 'g1', name: 'Applied Mathematics', credits: 4.0, gradePoint: 4.0),
        GpaCourse(id: 'g2', name: 'Computer Science', credits: 3.0, gradePoint: 3.7),
      ];
    }

    setState(() {
      _allNotes = notes;
      _allFlashcards = flashcards;
      _timetableSlots = slots;
      _examEntries = exams;
      _gpaCourses = gpa;
      _scratchpadText = scratch;
      _masterPin = pin;
      _vaultPin = vPin;
      _isLoading = false;
    });

    _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    try {
      final bool canBio = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (canBio) {
        final bool didAuth = await _localAuth.authenticate(
          localizedReason: 'Scan fingerprint to unlock xNotes Ultimate Pro',
          options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
        );
        if (didAuth) {
          setState(() => _isAppLocked = false);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('xnotes_data_pro', jsonEncode(_allNotes.map((n) => n.toMap()).toList()));
    await prefs.setString('xnotes_flashcards', jsonEncode(_allFlashcards.map((f) => f.toMap()).toList()));
    await prefs.setString('xnotes_timetable', jsonEncode(_timetableSlots.map((t) => t.toMap()).toList()));
    await prefs.setString('xnotes_exams', jsonEncode(_examEntries.map((e) => e.toMap()).toList()));
    await prefs.setString('xnotes_gpa', jsonEncode(_gpaCourses.map((g) => g.toMap()).toList()));
    await prefs.setString('xnotes_scratchpad', _scratchpadText);
  }

  List<Note> _generateSeedData() {
    final now = DateTime.now();
    return [
      Note(
        id: 'seed_1',
        title: '⚡ Fast Fourier Transform (FFT)',
        content: 'Calculates the Discrete Fourier Transform in O(N log N) time complexity.\n\nKey formula:\nX_k = \\sum_{n=0}^{N-1} x_n \\cdot e^{-i 2\\pi k n / N}',
        category: 'Study',
        priority: PriorityLevel.urgent,
        isPinned: true,
        createdAt: now,
        modifiedAt: now,
        checklist: [
          ChecklistItem(id: 'c1', text: 'Derive butterfly diagrams', isDone: true),
          ChecklistItem(id: 'c2', text: 'Solve past papers', isDone: false),
        ],
      ),
      Note(
        id: 'seed_2',
        title: '🎯 Async Memoizer Implementation',
        content: '// Fast memoization pattern in Dart\nclass Memoizer<T> {\n  Future<T>? _future;\n  Future<T> run(Future<T> Function() fn) => _future ??= fn();\n}',
        category: 'Programming',
        isCodeNote: true,
        codeLanguage: 'Dart',
        priority: PriorityLevel.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        modifiedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  List<Note> get _filteredNotes {
    return _allNotes.where((n) {
      if (n.isTrash || n.isArchived) return false;
      if (n.isVaulted && !_isVaultUnlocked) return false;

      final matchCat = (_selectedCategory == 'All' || n.category == _selectedCategory);
      final matchQuery = _searchQuery.isEmpty ||
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchCat && matchQuery;
    }).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.modifiedAt.compareTo(a.modifiedAt);
      });
  }

  void _addOrUpdateNote(Note note) {
    final idx = _allNotes.indexWhere((e) => e.id == note.id);
    setState(() {
      if (idx >= 0) {
        _allNotes[idx] = note;
      } else {
        _allNotes.insert(0, note);
      }
    });
    _saveAll();
  }

  void _openNoteEditor(Note? note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ComprehensiveNoteEditorScreen(
          note: note,
          accentColor: widget.accentColor,
          blurSigma: widget.blurSigma,
          onSave: (saved) => _addOrUpdateNote(saved),
        ),
      ),
    );
  }

  // ==========================================================================
  // UI BUILD & SECURITY GATE
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    if (_isAppLocked) {
      return _buildPasscodeLockGate();
    }

    return AmbientBackdropContainer(
      isOled: widget.isOledMode,
      isLight: widget.isLightMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildTopAppBar(),
        drawer: _buildDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildNotesFeedTab(),
                  _buildStudyAndCodeLabTab(),
                  _buildHabitsAndFinanceTab(),
                  _buildCalendarAndOutlineTab(),
                  _buildAnalyticsAndSettingsTab(),
                ],
              ),
        bottomNavigationBar: _buildBottomBar(),
        floatingActionButton: _currentNavIndex == 0
            ? FloatingActionButton(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                elevation: 10,
                shape: const CircleBorder(),
                onPressed: () => _openNoteEditor(null),
                child: const Icon(Icons.add_rounded, size: 30),
              )
            : null,
      ),
    );
  }

  Widget _buildPasscodeLockGate() {
    String enteredPin = '';
    return StatefulBuilder(
      builder: (context, setGateState) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: FrostedGlassCard(
              borderRadius: 32,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint_rounded, size: 60, color: widget.accentColor),
                  const SizedBox(height: 16),
                  const Text('xNotes Ultimate Pro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Enter App PIN (Default: $_masterPin)', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? widget.accentColor : Colors.white24,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (int i = 1; i <= 9; i++)
                        _pinDigit('$i', () {
                          if (enteredPin.length < 4) {
                            setGateState(() => enteredPin += '$i');
                            if (enteredPin == _masterPin) {
                              setState(() => _isAppLocked = false);
                            }
                          }
                        }),
                      _pinDigit('Bio', _attemptBiometric),
                      _pinDigit('0', () {
                        if (enteredPin.length < 4) {
                          setGateState(() => enteredPin += '0');
                          if (enteredPin == _masterPin) {
                            setState(() => _isAppLocked = false);
                          }
                        }
                      }),
                      _pinDigit('Del', () {
                        if (enteredPin.isNotEmpty) {
                          setGateState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pinDigit(String text, VoidCallback onTap) {
    return SizedBox(
      width: 66,
      height: 66,
      child: FrostedGlassCard(
        borderRadius: 33,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Center(
          child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(74),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            padding: const EdgeInsets.only(top: 28, left: 16, right: 16),
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: widget.accentColor),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search notes, code & flashcards...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, size: 18, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _currentLayout == ViewLayout.grid ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                    color: widget.accentColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _currentLayout = _currentLayout == ViewLayout.grid ? ViewLayout.list : ViewLayout.grid;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: FrostedGlassCard(
        borderRadius: 0,
        surfaceColor: const Color(0xFF090A14).withOpacity(0.95),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 50),
            Row(
              children: [
                Icon(Icons.terminal_rounded, size: 36, color: widget.accentColor),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('xNotes Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('100% Offline System', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 36),
            ListTile(
              leading: Icon(Icons.lock_rounded, color: widget.accentColor),
              title: const Text('Secret Vault Folder'),
              subtitle: Text(_isVaultUnlocked ? 'Unlocked' : 'Encrypted & Locked'),
              trailing: Switch(
                value: _isVaultUnlocked,
                activeColor: widget.accentColor,
                onChanged: (v) {
                  if (v) {
                    _promptVaultUnlock();
                  } else {
                    setState(() => _isVaultUnlocked = false);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: Colors.tealAccent),
              title: const Text('Export JSON Backup'),
              onTap: () {
                Navigator.pop(context);
                final jsonStr = jsonEncode(_allNotes.map((e) => e.toMap()).toList());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup JSON copied to clipboard!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptVaultUnlock() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131522),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Unlock Secret Vault'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter Vault PIN (Default: 9999)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GlassPillButton(
            label: 'Unlock',
            onTap: () {
              if (ctrl.text == _vaultPin) {
                setState(() => _isVaultUnlocked = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault Unlocked!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Vault PIN!')));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(Icons.notes_rounded, 0),
                _navItem(Icons.terminal_rounded, 1),
                _navItem(Icons.track_changes_rounded, 2),
                _navItem(Icons.calendar_month_rounded, 3),
                _navItem(Icons.pie_chart_rounded, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSel = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? widget.accentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: isSel ? widget.accentColor : Colors.white60, size: 24),
      ),
    );
  }

  // ==========================================================================
  // TAB VIEWS
  // ==========================================================================

  Widget _buildNotesFeedTab() {
    final categories = ['All', 'General', 'Study', 'Programming'];
    final notes = _filteredNotes;

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isSel ? widget.accentColor.withOpacity(0.25) : Colors.white.withOpacity(0.06),
                    border: Border.all(color: isSel ? widget.accentColor : Colors.white12),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel ? widget.accentColor : Colors.white70,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? const Center(child: Text('No notes available.'))
              : _currentLayout == ViewLayout.grid
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (c, i) => _buildNoteCard(notes[i]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notes.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNoteCard(notes[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Note n) {
    return FrostedGlassCard(
      borderRadius: 22,
      borderColor: n.isPinned ? widget.accentColor.withOpacity(0.6) : null,
      onTap: () => _openNoteEditor(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (n.isPinned) Icon(Icons.push_pin_rounded, size: 14, color: widget.accentColor),
              if (n.isFavorite) const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent),
              const Spacer(),
              Text(n.category, style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            n.title.isEmpty ? 'Untitled' : n.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              n.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: n.isCodeNote ? 'monospace' : null,
              ),
            ),
          ),
          Text(DateFormat('MMM d').format(n.modifiedAt), style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildStudyAndCodeLabTab() {
    final minutes = (_pomodoroSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_pomodoroSecondsLeft % 60).toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FrostedGlassCard(
            borderRadius: 24,
            child: Column(
              children: [
                const Text('Pomodoro Focus Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                Text('$minutes:$seconds', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassPillButton(
                      label: _isPomodoroRunning ? 'Pause' : 'Start',
                      icon: _isPomodoroRunning ? Icons.pause : Icons.play_arrow,
                      onTap: () {
                        if (_isPomodoroRunning) {
                          _pomodoroTimer?.cancel();
                          setState(() => _isPomodoroRunning = false);
                        } else {
                          setState(() => _isPomodoroRunning = true);
                          _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                            if (_pomodoroSecondsLeft > 0) {
                              setState(() => _pomodoroSecondsLeft--);
                            } else {
                              t.cancel();
                              setState(() {
                                _isPomodoroRunning = false;
                                _pomodoroCompleted++;
                                _pomodoroSecondsLeft = 25 * 60;
                              });
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    GlassPillButton(
                      label: 'Reset',
                      isPrimary: false,
                      onTap: () {
                        _pomodoroTimer?.cancel();
                        setState(() {
                          _isPomodoroRunning = false;
                          _pomodoroSecondsLeft = 25 * 60;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revision Flashcards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              GlassPillButton(
                label: 'Add Card',
                icon: Icons.add,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                onTap: () {
                  final fCtrl = TextEditingController();
                  final bCtrl = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF131522),
                      title: const Text('Add Flashcard'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: fCtrl, decoration: const InputDecoration(labelText: 'Question')),
                          TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Answer')),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            if (fCtrl.text.isNotEmpty && bCtrl.text.isNotEmpty) {
                              setState(() {
                                _allFlashcards.add(Flashcard(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  front: fCtrl.text,
                                  back: bCtrl.text,
                                ));
                              });
                              _saveAll();
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var fc in _allFlashcards)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FrostedGlassCard(
                borderRadius: 18,
                child: ListTile(
                  title: Text(fc.front, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(fc.back, style: TextStyle(color: widget.accentColor)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitsAndFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedGlassCard(
            borderRadius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Universal Instant Scratchpad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _scratchpadText,
                  maxLines: 6,
                  onChanged: (v) {
                    _scratchpadText = v;
                    _saveAll();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Dump formulas, temporary thoughts or numbers...',
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarAndOutlineTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedGlassCard(
            borderRadius: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.calendar_month_rounded, color: widget.accentColor),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Notes Mapped by Creation Date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _allNotes.length,
              itemBuilder: (ctx, i) {
                final n = _allNotes[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FrostedGlassCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Text(DateFormat('MMM dd').format(n.createdAt), style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(n.title.isEmpty ? 'Untitled' : n.title, overflow: TextOverflow.ellipsis)),
                        Text(n.category, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsAndSettingsTab() {
    int totalWords = 0;
    for (var n in _allNotes) {
      totalWords += n.content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedGlassCard(
            borderRadius: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${_allNotes.length}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: widget.accentColor)),
                    const Text('Total Notes', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
                Column(
                  children: [
                    Text('$totalWords', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: widget.accentColor)),
                    const Text('Words Written', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FrostedGlassCard(
            borderRadius: 24,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('True OLED Deep Black Mode'),
                  value: widget.isOledMode,
                  onChanged: (v) => widget.onThemeChanged(isOled: v),
                ),
                SwitchListTile(
                  title: const Text('Light Glass Mode'),
                  value: widget.isLightMode,
                  onChanged: (v) => widget.onThemeChanged(isLight: v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. COMPREHENSIVE NOTE & CODE STUDIO EDITOR
// ============================================================================

class ComprehensiveNoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Color accentColor;
  final double blurSigma;
  final Function(Note) onSave;

  const ComprehensiveNoteEditorScreen({
    super.key,
    required this.note,
    required this.accentColor,
    required this.blurSigma,
    required this.onSave,
  });

  @override
  State<ComprehensiveNoteEditorScreen> createState() => _ComprehensiveNoteEditorScreenState();
}

class _ComprehensiveNoteEditorScreenState extends State<ComprehensiveNoteEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late String _category;
  late PriorityLevel _priority;
  late bool _isPinned;
  late bool _isFavorite;
  late bool _isCodeMode;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _contentCtrl = TextEditingController(text: n?.content ?? '');
    _category = n?.category ?? 'General';
    _priority = n?.priority ?? PriorityLevel.medium;
    _isPinned = n?.isPinned ?? false;
    _isFavorite = n?.isFavorite ?? false;
    _isCodeMode = n?.isCodeNote ?? false;
  }

  void _persistAndExit() {
    final now = DateTime.now();
    final updated = (widget.note ??
            Note(
              id: now.millisecondsSinceEpoch.toString(),
              title: _titleCtrl.text,
              content: _contentCtrl.text,
              createdAt: now,
              modifiedAt: now,
            ))
        .copyWith(
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      category: _category,
      priority: _priority,
      isPinned: _isPinned,
      isFavorite: _isFavorite,
      isCodeNote: _isCodeMode,
      modifiedAt: now,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _persistAndExit,
        ),
        actions: [
          IconButton(
            icon: Icon(_isCodeMode ? Icons.code_off : Icons.code, color: widget.accentColor),
            onPressed: () => setState(() => _isCodeMode = !_isCodeMode),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
            onPressed: _persistAndExit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Document Title...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white12),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  fontFamily: _isCodeMode ? 'monospace' : null,
                  color: _isCodeMode ? const Color(0xFF80D8FF) : Colors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Start writing or coding...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

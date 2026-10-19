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
// 1. ENTRY POINT & SELF-HEALING ARCHITECTURE
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Boundary - Isolates crashes safely
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0C0D17),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.healing_rounded, size: 54, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  const Text('Workspace Self-Healing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('A rendering glitch occurred and was isolated safely.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => runApp(const XNotesUltimateProApp()),
                    child: const Text('Restart Clean Workspace'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

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

  void _updateTheme({int? accentColor, bool? isOled, bool? isLight}) {
    setState(() {
      if (accentColor != null) _accentColorHex = accentColor;
      if (isOled != null) _isOledMode = isOled;
      if (isLight != null) _isLightMode = isLight;
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
        scaffoldBackgroundColor: const Color(0xFFF1F4FA),
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
        onThemeChanged: _updateTheme,
      ),
    );
  }
}

// ============================================================================
// 2. DATA MODELS
// ============================================================================

enum PriorityLevel { low, medium, high, urgent }
enum SortOrder { modifiedDesc, modifiedAsc, createdDesc, titleAsc, priorityDesc }
enum ViewLayout { grid, list, compact }

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

  Flashcard({required this.id, required this.front, required this.back, this.subject = 'General'});

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

  TimetableSlot({required this.id, required this.day, required this.time, required this.subject, required this.room});

  Map<String, dynamic> toMap() => {'id': id, 'day': day, 'time': time, 'subject': subject, 'room': room};
  factory TimetableSlot.fromMap(Map<String, dynamic> m) => TimetableSlot(
        id: m['id'] ?? '',
        day: m['day'] ?? 'Mon',
        time: m['time'] ?? '08:30 AM',
        subject: m['subject'] ?? '',
        room: m['room'] ?? '',
      );
}

class ExamEntry {
  String id;
  String title;
  DateTime date;
  String subject;

  ExamEntry({required this.id, required this.title, required this.date, required this.subject});

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'date': date.toIso8601String(), 'subject': subject};
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

class DrawingPoint {
  Offset offset;
  Color color;
  double strokeWidth;
  DrawingPoint({required this.offset, required this.color, required this.strokeWidth});
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
  int audioDurationSec;
  String audioTranscript;

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
    this.audioDurationSec = 0,
    this.audioTranscript = '',
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
      audioDurationSec: audioDurationSec,
      audioTranscript: audioTranscript,
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
        'audioDurationSec': audioDurationSec,
        'audioTranscript': audioTranscript,
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
        audioDurationSec: map['audioDurationSec'] ?? 0,
        audioTranscript: map['audioTranscript'] ?? '',
      );
}

// ============================================================================
// 3. FROSTED GLASS CORE UI
// ============================================================================

class AmbientBackdropContainer extends StatelessWidget {
  final Widget child;
  final bool isOled;
  final bool isLight;

  const AmbientBackdropContainer({super.key, required this.child, required this.isOled, required this.isLight});

  @override
  Widget build(BuildContext context) {
    if (isOled) return Container(color: Colors.black, child: child);
    if (isLight) return Container(color: const Color(0xFFF1F4FA), child: child);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0E15), Color(0xFF1B0C2E), Color(0xFF04192B)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFFD500F9).withOpacity(0.32), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -80,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF00E5FF).withOpacity(0.28), Colors.transparent],
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

  const FrostedGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 26.0,
    this.blur = 18.0,
    this.borderColor,
    this.surfaceColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.white.withOpacity(0.14);
    final surface = surfaceColor ?? Colors.white.withOpacity(0.08);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.2),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!();
          },
          child: card,
        ),
      );
    }
    return card;
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: isPrimary ? accent.withOpacity(0.26) : Colors.white.withOpacity(0.08),
                border: Border.all(color: isPrimary ? accent.withOpacity(0.85) : Colors.white24, width: 1.3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaveformVisualizerPainter extends CustomPainter {
  final double animValue;
  final Color color;
  WaveformVisualizerPainter({required this.animValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final count = 28;
    final widthPerBar = size.width / count;

    for (int i = 0; i < count; i++) {
      final x = i * widthPerBar + widthPerBar / 2;
      final wave = math.sin((i / 3.0) + animValue * 2 * math.pi) * 0.5 + 0.5;
      final barHeight = math.max(6.0, size.height * wave * 0.8);
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformVisualizerPainter oldDelegate) => true;
}

// ============================================================================
// 4. MASTER HOME SCREEN
// ============================================================================

class MasterHomeScreen extends StatefulWidget {
  final Color accentColor;
  final bool isOledMode;
  final bool isLightMode;
  final Function({int? accentColor, bool? isOled, bool? isLight}) onThemeChanged;

  const MasterHomeScreen({
    super.key,
    required this.accentColor,
    required this.isOledMode,
    required this.isLightMode,
    required this.onThemeChanged,
  });

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> with TickerProviderStateMixin {
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

  bool _isVaultUnlocked = false;
  String _scratchpadText = '';
  int _currentNavIndex = 0;

  Timer? _pomodoroTimer;
  int _pomodoroSecondsLeft = 25 * 60;
  bool _isPomodoroRunning = false;
  int _pomodoroCompleted = 0;

  late AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _safeLoadAllData();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _waveAnimController.dispose();
    super.dispose();
  }

  // Crash-Proof Safe Loader with GUARANTEED _isLoading = false in finally
  Future<void> _safeLoadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rawNotes = prefs.getString('xnotes_data_pro');
      final rawFlash = prefs.getString('xnotes_flashcards');
      final rawTime = prefs.getString('xnotes_timetable');
      final rawExams = prefs.getString('xnotes_exams');
      final rawGpa = prefs.getString('xnotes_gpa');
      final scratch = prefs.getString('xnotes_scratchpad') ?? '';

      List<Note> loadedNotes = [];
      if (rawNotes != null && rawNotes.isNotEmpty) {
        try {
          final List<dynamic> dec = jsonDecode(rawNotes);
          loadedNotes = dec.map((e) => Note.fromMap(e)).toList();
        } catch (_) {
          loadedNotes = _generateSeedData();
        }
      } else {
        loadedNotes = _generateSeedData();
      }

      List<Flashcard> loadedFlash = [];
      if (rawFlash != null) {
        try {
          final List<dynamic> dec = jsonDecode(rawFlash);
          loadedFlash = dec.map((e) => Flashcard.fromMap(e)).toList();
        } catch (_) {}
      }
      if (loadedFlash.isEmpty) {
        loadedFlash = [
          Flashcard(id: 'fc1', front: 'd/dx [sin(x)] = ?', back: 'cos(x)', subject: 'Maths'),
          Flashcard(id: 'fc2', front: 'Newton\'s Second Law?', back: 'F = m × a', subject: 'Physics'),
          Flashcard(id: 'fc3', front: 'What is memoization?', back: 'Caching results of expensive pure functions', subject: 'CS'),
        ];
      }

      List<TimetableSlot> loadedTime = [];
      if (rawTime != null) {
        try {
          final List<dynamic> dec = jsonDecode(rawTime);
          loadedTime = dec.map((e) => TimetableSlot.fromMap(e)).toList();
        } catch (_) {}
      }
      if (loadedTime.isEmpty) {
        loadedTime = [
          TimetableSlot(id: 't1', day: 'Mon', time: '08:30 - 10:30', subject: 'Calculus & Vectors', room: 'Hall 4A'),
          TimetableSlot(id: 't2', day: 'Wed', time: '11:00 - 01:00', subject: 'Algorithms Lab', room: 'Lab 2'),
        ];
      }

      List<ExamEntry> loadedExams = [];
      if (rawExams != null) {
        try {
          final List<dynamic> dec = jsonDecode(rawExams);
          loadedExams = dec.map((e) => ExamEntry.fromMap(e)).toList();
        } catch (_) {}
      }
      if (loadedExams.isEmpty) {
        loadedExams = [
          ExamEntry(id: 'ex1', title: 'Combined Mathematics Part I', date: DateTime.now().add(const Duration(days: 42)), subject: 'Maths'),
        ];
      }

      List<GpaCourse> loadedGpa = [];
      if (rawGpa != null) {
        try {
          final List<dynamic> dec = jsonDecode(rawGpa);
          loadedGpa = dec.map((e) => GpaCourse.fromMap(e)).toList();
        } catch (_) {}
      }
      if (loadedGpa.isEmpty) {
        loadedGpa = [
          GpaCourse(id: 'g1', name: 'Software Architecture', credits: 4.0, gradePoint: 4.0),
          GpaCourse(id: 'g2', name: 'Differential Equations', credits: 3.0, gradePoint: 3.7),
        ];
      }

      if (mounted) {
        setState(() {
          _allNotes = loadedNotes;
          _allFlashcards = loadedFlash;
          _timetableSlots = loadedTime;
          _examEntries = loadedExams;
          _gpaCourses = loadedGpa;
          _scratchpadText = scratch;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allNotes = _generateSeedData();
        });
      }
    } finally {
      // Guaranteed to dismiss loading spinner
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _safeSaveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('xnotes_data_pro', jsonEncode(_allNotes.map((n) => n.toMap()).toList()));
      await prefs.setString('xnotes_flashcards', jsonEncode(_allFlashcards.map((f) => f.toMap()).toList()));
      await prefs.setString('xnotes_timetable', jsonEncode(_timetableSlots.map((t) => t.toMap()).toList()));
      await prefs.setString('xnotes_exams', jsonEncode(_examEntries.map((e) => e.toMap()).toList()));
      await prefs.setString('xnotes_gpa', jsonEncode(_gpaCourses.map((g) => g.toMap()).toList()));
      await prefs.setString('xnotes_scratchpad', _scratchpadText);
    } catch (_) {}
  }

  List<Note> _generateSeedData() {
    final now = DateTime.now();
    return [
      Note(
        id: 'seed_1',
        title: '⚡ Fast Fourier Transform (FFT)',
        content: '# Discrete Mathematics\nThe Fast Fourier Transform calculates Discrete Fourier Transforms in O(N log N) time complexity.\n\n• Butterfly stage derivation complete\n• Bit-reversal permutation implemented\n\nX_k = \\sum_{n=0}^{N-1} x_n \\cdot e^{-i 2\\pi k n / N}',
        category: 'Study',
        priority: PriorityLevel.urgent,
        isPinned: true,
        createdAt: now,
        modifiedAt: now,
        checklist: [
          ChecklistItem(id: 'c1', text: 'Derive Cooley-Tukey butterfly stage', isDone: true),
          ChecklistItem(id: 'c2', text: 'Implement bit-reversal in C++', isDone: false),
        ],
      ),
      Note(
        id: 'seed_2',
        title: '🎯 Async Memoizer Implementation',
        content: '// High performance cache memoizer in Dart\nclass Memoizer<T> {\n  Future<T> Function()? _computation;\n  Future<T>? _future;\n\n  Future<T> run(Future<T> Function() fn) {\n    return _future ??= fn();\n  }\n}',
        category: 'Programming',
        isCodeNote: true,
        codeLanguage: 'Dart',
        priority: PriorityLevel.high,
        createdAt: now.subtract(const Duration(hours: 3)),
        modifiedAt: now.subtract(const Duration(minutes: 20)),
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
    _safeSaveAll();
  }

  void _openNoteEditor(Note? note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ComprehensiveNoteEditorScreen(
          note: note,
          accentColor: widget.accentColor,
          onSave: (saved) => _addOrUpdateNote(saved),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackdropContainer(
      isOled: widget.isOledMode,
      isLight: widget.isLightMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildTopAppBar(),
        drawer: _buildGlassDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildNotesFeedTab(),
                  _buildStudyAndCodeLabTab(),
                  _buildPowerStudioTab(),
                  _buildHabitsAndFinanceTab(),
                  _buildCalendarAndOutlineTab(),
                  _buildDeepCustomizationTab(),
                ],
              ),
        bottomNavigationBar: _buildGlassBottomPillNav(),
        floatingActionButton: _currentNavIndex == 0
            ? FloatingActionButton(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.black,
                elevation: 12,
                shape: const CircleBorder(),
                onPressed: () => _openNoteEditor(null),
                child: const Icon(Icons.add_rounded, size: 30),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(76),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withOpacity(0.32),
            padding: const EdgeInsets.only(top: 28, left: 16, right: 16),
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(Icons.bubble_chart_rounded, color: widget.accentColor, size: 28),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Search notes, code, formulas...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

  Widget _buildGlassBottomPillNav() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withOpacity(0.16), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navBarItem(Icons.notes_rounded, 0),
                _navBarItem(Icons.terminal_rounded, 1),
                _navBarItem(Icons.auto_awesome_rounded, 2),
                _navBarItem(Icons.track_changes_rounded, 3),
                _navBarItem(Icons.calendar_month_rounded, 4),
                _navBarItem(Icons.tune_rounded, 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBarItem(IconData icon, int index) {
    final isSel = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentNavIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? widget.accentColor.withOpacity(0.24) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSel ? Border.all(color: widget.accentColor.withOpacity(0.6)) : null,
        ),
        child: Icon(icon, color: isSel ? widget.accentColor : Colors.white60, size: 22),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: NOTES FEED
  // ==========================================================================

  Widget _buildNotesFeedTab() {
    final categories = ['All', 'General', 'Study', 'Programming', 'Personal'];
    final notes = _filteredNotes;

    return Column(
      children: [
        SizedBox(
          height: 48,
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
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
        const SizedBox(height: 8),
        Expanded(
          child: notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notes_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text('No notes available. Tap + to create one!', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : _currentLayout == ViewLayout.list
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: notes.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNoteCard(notes[i]),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (c, i) => _buildNoteCard(notes[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Note n) {
    return FrostedGlassCard(
      borderRadius: 24,
      borderColor: n.isPinned ? widget.accentColor.withOpacity(0.65) : null,
      onTap: () => _openNoteEditor(n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (n.isPinned) Icon(Icons.push_pin_rounded, size: 14, color: widget.accentColor),
              if (n.isFavorite) const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent),
              if (n.isCodeNote) const Icon(Icons.code_rounded, size: 14, color: Colors.orangeAccent),
              const Spacer(),
              _buildPriorityBadge(n.priority),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            n.title.isEmpty ? 'Untitled Document' : n.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              n.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: n.isCodeNote ? 'monospace' : null,
              ),
            ),
          ),
          if (n.checklist.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: n.checklist.where((e) => e.isDone).length / n.checklist.length,
                backgroundColor: Colors.white12,
                color: widget.accentColor,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM d').format(n.modifiedAt), style: const TextStyle(fontSize: 10, color: Colors.white38)),
              Text(n.mood, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(PriorityLevel p) {
    Color c = Colors.tealAccent;
    String txt = 'MED';
    if (p == PriorityLevel.urgent) {
      c = Colors.redAccent;
      txt = 'URG';
    } else if (p == PriorityLevel.high) {
      c = Colors.orangeAccent;
      txt = 'HIGH';
    } else if (p == PriorityLevel.low) {
      c = Colors.blueGrey;
      txt = 'LOW';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c, width: 0.8),
      ),
      child: Text(txt, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  // ==========================================================================
  // TAB 2: STUDY & CODING LAB
  // ==========================================================================

  Widget _buildStudyAndCodeLabTab() {
    final minutes = (_pomodoroSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_pomodoroSecondsLeft % 60).toString().padLeft(2, '0');
    final progress = _pomodoroSecondsLeft / (25 * 60);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FrostedGlassCard(
          borderRadius: 28,
          child: Column(
            children: [
              const Text('⏱️ Pomodoro Focus Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                    ),
                  ),
                  Text('$minutes:$seconds', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassPillButton(
                    label: _isPomodoroRunning ? 'Pause' : 'Start Focus',
                    icon: _isPomodoroRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    glowColor: widget.accentColor,
                    onTap: _togglePomodoro,
                  ),
                  const SizedBox(width: 12),
                  GlassPillButton(
                    label: 'Reset',
                    icon: Icons.refresh_rounded,
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
            const Text('🃏 Flashcards Memory Drill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            GlassPillButton(
              label: 'Add Card',
              icon: Icons.add,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              onTap: _showAddFlashcardDialog,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var fc in _allFlashcards)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FrostedGlassCard(
              borderRadius: 22,
              child: ListTile(
                title: Text(fc.front, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Tap to reveal: ${fc.back}', style: TextStyle(color: widget.accentColor)),
              ),
            ),
          ),
      ],
    );
  }

  void _togglePomodoro() {
    if (_isPomodoroRunning) {
      _pomodoroTimer?.cancel();
      setState(() => _isPomodoroRunning = false);
    } else {
      setState(() => _isPomodoroRunning = true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pomodoroSecondsLeft > 0) {
          setState(() => _pomodoroSecondsLeft--);
        } else {
          timer.cancel();
          setState(() {
            _isPomodoroRunning = false;
            _pomodoroCompleted++;
            _pomodoroSecondsLeft = 25 * 60;
          });
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  void _showAddFlashcardDialog() {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131522),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Add Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: frontCtrl, decoration: const InputDecoration(labelText: 'Question / Formula')),
            TextField(controller: backCtrl, decoration: const InputDecoration(labelText: 'Answer / Derivation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GlassPillButton(
            label: 'Save',
            onTap: () {
              if (frontCtrl.text.isNotEmpty && backCtrl.text.isNotEmpty) {
                setState(() {
                  _allFlashcards.insert(
                    0,
                    Flashcard(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      front: frontCtrl.text,
                      back: backCtrl.text,
                    ),
                  );
                });
                _safeSaveAll();
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: POWER STUDIO (AUDIO, SPLIT, MIND MAP, DOODLE, OCR, QUIZ)
  // ==========================================================================

  Widget _buildPowerStudioTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Smart Audio Recorder Simulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _waveAnimController,
                builder: (context, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomPaint(
                      painter: WaveformVisualizerPainter(
                        animValue: _waveAnimController.value,
                        color: widget.accentColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassPillButton(
                    label: 'Record Clip',
                    icon: Icons.fiber_manual_record_rounded,
                    glowColor: Colors.redAccent,
                    onTap: () {
                      final n = Note(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Voice Memo (${DateFormat('MMM d, HH:mm').format(DateTime.now())})',
                        content: 'Audio recorded successfully locally.',
                        audioDurationSec: 42,
                        audioTranscript: 'Key architectural derivations & design system insights.',
                        createdAt: DateTime.now(),
                        modifiedAt: DateTime.now(),
                      );
                      _addOrUpdateNote(n);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio Note Recorded!')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _powerToolTile('Parallel Dual Split', Icons.vertical_split_rounded, Colors.purpleAccent, _openDualSplitScreen),
            _powerToolTile('Concept Mind Map', Icons.account_tree_rounded, widget.accentColor, _openMindMapViewer),
            _powerToolTile('Canvas Doodle Pad', Icons.draw_rounded, Colors.amberAccent, _openDoodleCanvas),
            _powerToolTile('OCR Text Grabber', Icons.document_scanner_rounded, Colors.greenAccent, _openOcrScanner),
            _powerToolTile('Self-Test Quiz', Icons.quiz_rounded, Colors.cyanAccent, _openQuizGenerator),
            _powerToolTile('Ambient Sound Player', Icons.headphones_rounded, Colors.pinkAccent, _openAmbientSoundPlayer),
          ],
        ),
      ],
    );
  }

  Widget _powerToolTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return FrostedGlassCard(
      borderRadius: 22,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _openDualSplitScreen() {
    if (_allNotes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create at least 2 notes to use Dual Split View!')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DualNoteSplitScreen(
          noteA: _allNotes[0],
          noteB: _allNotes[1],
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  void _openMindMapViewer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MindMapCanvasModal(
          note: _allNotes.isNotEmpty ? _allNotes.first : null,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  void _openDoodleCanvas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CanvasDoodleModal(
          accentColor: widget.accentColor,
          onSaveDoodle: (bytesNote) => _addOrUpdateNote(bytesNote),
        ),
      ),
    );
  }

  void _openOcrScanner() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassCard(
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📷 OCR Text Extractor Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: widget.accentColor, width: 1.5),
              ),
              child: const Center(child: Text('[Camera Viewfinder Overlay]\nAlign document within frame', textAlign: TextAlign.center)),
            ),
            const SizedBox(height: 14),
            GlassPillButton(
              label: 'Capture & Extract Text',
              icon: Icons.camera_alt_rounded,
              onTap: () {
                final ocrNote = Note(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'OCR Scanned Document',
                  content: 'Extracted Text:\n1. Physics Maxwell Equations\n2. Gauss Law in electrostatics\n3. Faraday Induction Vector',
                  createdAt: DateTime.now(),
                  modifiedAt: DateTime.now(),
                );
                _addOrUpdateNote(ocrNote);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OCR Text Converted to Note!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openQuizGenerator() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassCard(
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧠 Automated Self-Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Question 1: Does FFT execute in O(N log N) time complexity?'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GlassPillButton(
                  label: 'TRUE',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correct! +10 Points!')));
                  },
                ),
                GlassPillButton(
                  label: 'FALSE',
                  isPrimary: false,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect! Review notes.')));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openAmbientSoundPlayer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassCard(
        borderRadius: 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎧 Focus Ambient Generator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                Chip(label: const Text('🌧️ Rain'), backgroundColor: widget.accentColor.withOpacity(0.2)),
                const Chip(label: Text('🌲 Forest'), backgroundColor: Colors.white10),
                const Chip(label: Text('🌊 Waves'), backgroundColor: Colors.white10),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Ambient Soundscape Playing Locally...', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 4: HABITS & FINANCE
  // ==========================================================================

  Widget _buildHabitsAndFinanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text('Daily Habit Streaks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _allNotes.map((n) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(n.title.isEmpty ? 'Untitled' : n.title, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text('🔥 ${n.habitStreak}d', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            setState(() => n.habitStreak++);
                            _safeSaveAll();
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Universal Scratchpad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _scratchpadText,
                maxLines: 5,
                onChanged: (v) {
                  _scratchpadText = v;
                  _safeSaveAll();
                },
                decoration: const InputDecoration(
                  hintText: 'Dump calculations, quick numbers, temporary thoughts...',
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // TAB 5: CALENDAR & OUTLINE
  // ==========================================================================

  Widget _buildCalendarAndOutlineTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FrostedGlassCard(
          borderRadius: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.calendar_month_rounded, color: widget.accentColor),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Notes Mapped by Creation Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var n in _allNotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FrostedGlassCard(
              borderRadius: 20,
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
          ),
      ],
    );
  }

  // ==========================================================================
  // TAB 6: SETTINGS & PERMISSIONS
  // ==========================================================================

  Widget _buildDeepCustomizationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎨 Live Accent Neon Switcher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  0xFF00E5FF,
                  0xFFD500F9,
                  0xFFFFB300,
                  0xFF00E676,
                  0xFFFF1744,
                  0xFF3D5AFE,
                ].map((hex) {
                  final isSel = widget.accentColor.value == hex;
                  return GestureDetector(
                    onTap: () => widget.onThemeChanged(accentColor: hex),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(hex),
                        border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(color: Colors.white12, height: 28),
              SwitchListTile(
                title: const Text('True OLED Deep Black Mode'),
                value: widget.isOledMode,
                onChanged: (v) => widget.onThemeChanged(isOled: v),
              ),
              SwitchListTile(
                title: const Text('Light Ambient Glass Mode'),
                value: widget.isLightMode,
                onChanged: (v) => widget.onThemeChanged(isLight: v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🛡️ Built-in Permission Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _permissionTile('Biometric Fingerprint / Face ID', Icons.fingerprint_rounded),
              _permissionTile('Local Storage & Media Access', Icons.folder_shared_rounded),
              _permissionTile('Audio Microphone (Voice Transcripts)', Icons.mic_rounded),
              _permissionTile('Scheduled Reminder Alarms', Icons.alarm_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _permissionTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: widget.accentColor),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('GRANTED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGlassDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: FrostedGlassCard(
        borderRadius: 0,
        surfaceColor: const Color(0xFF0C0D17).withOpacity(0.96),
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
                    Text('Universal High-Performance', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 36),
            ListTile(
              leading: Icon(Icons.lock_rounded, color: widget.accentColor),
              title: const Text('Secret Vault Access'),
              subtitle: Text(_isVaultUnlocked ? 'Unlocked' : 'Locked'),
              trailing: Switch(
                value: _isVaultUnlocked,
                activeColor: widget.accentColor,
                onChanged: (v) {
                  setState(() => _isVaultUnlocked = v);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: Colors.tealAccent),
              title: const Text('Export JSON Database Backup'),
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
}

// ============================================================================
// 5. NOTE & CODE STUDIO EDITOR
// ============================================================================

class ComprehensiveNoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Color accentColor;
  final Function(Note) onSave;

  const ComprehensiveNoteEditorScreen({super.key, required this.note, required this.accentColor, required this.onSave});

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
  late String _codeLanguage;
  late List<ChecklistItem> _checklist;
  late List<ExpenseItem> _expenses;
  bool _isMarkdownPreview = false;

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
    _codeLanguage = n?.codeLanguage ?? 'Dart';
    _checklist = n?.checklist != null ? List.from(n!.checklist) : [];
    _expenses = n?.expenses != null ? List.from(n!.expenses) : [];
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
      codeLanguage: _codeLanguage,
      checklist: _checklist,
      expenses: _expenses,
      modifiedAt: now,
    );
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _contentCtrl.text.split('\n');

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
            icon: Icon(_isCodeMode ? Icons.code_off_rounded : Icons.code_rounded, color: widget.accentColor),
            onPressed: () => setState(() => _isCodeMode = !_isCodeMode),
          ),
          IconButton(
            icon: Icon(_isMarkdownPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            onPressed: () => setState(() => _isMarkdownPreview = !_isMarkdownPreview),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
            onPressed: _persistAndExit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
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
            if (_isCodeMode)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0D17),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        math.max(1, lines.length),
                        (i) => Text('${i + 1} ', style: const TextStyle(fontFamily: 'monospace', color: Colors.white24, fontSize: 13, height: 1.4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, color: Colors.white12, height: math.max(1, lines.length) * 18.2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _contentCtrl,
                        maxLines: null,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4, color: Color(0xFF80D8FF)),
                        decoration: const InputDecoration(hintText: '// Code here...', border: InputBorder.none),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextField(
                controller: _contentCtrl,
                maxLines: null,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: const InputDecoration(hintText: 'Write note or formulas...', border: InputBorder.none),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. DUAL SPLIT SCREEN VIEW
// ============================================================================

class DualNoteSplitScreen extends StatelessWidget {
  final Note noteA;
  final Note noteB;
  final Color accentColor;

  const DualNoteSplitScreen({super.key, required this.noteA, required this.noteB, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Parallel Dual View', style: TextStyle(fontSize: 16)), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Expanded(child: _singlePane(noteA)),
          Container(height: 2, color: accentColor.withOpacity(0.5)),
          Expanded(child: _singlePane(noteB)),
        ],
      ),
    );
  }

  Widget _singlePane(Note n) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: accentColor)),
          const SizedBox(height: 6),
          Expanded(child: SingleChildScrollView(child: Text(n.content, style: const TextStyle(height: 1.4)))),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. CONCEPT MIND MAP VIEW
// ============================================================================

class MindMapCanvasModal extends StatelessWidget {
  final Note? note;
  final Color accentColor;

  const MindMapCanvasModal({super.key, required this.note, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0D17),
      appBar: AppBar(title: const Text('Concept Tree'), backgroundColor: Colors.transparent),
      body: Center(
        child: FrostedGlassCard(
          borderRadius: 26,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor),
                ),
                child: Text(note?.title ?? 'Root Concept', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(width: 2, height: 26, color: accentColor),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _treeNode('Architecture'),
                  _treeNode('Algorithms'),
                  _treeNode('Formulas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _treeNode(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

// ============================================================================
// 8. CANVAS DOODLE DRAWING PAD
// ============================================================================

class CanvasDoodleModal extends StatefulWidget {
  final Color accentColor;
  final Function(Note) onSaveDoodle;

  const CanvasDoodleModal({super.key, required this.accentColor, required this.onSaveDoodle});

  @override
  State<CanvasDoodleModal> createState() => _CanvasDoodleModalState();
}

class _CanvasDoodleModalState extends State<CanvasDoodleModal> {
  List<DrawingPoint?> points = [];
  Color selectedColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C15),
      appBar: AppBar(
        title: const Text('Drawing Canvas Pad'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => points.clear())),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
            onPressed: () {
              final doodleNote = Note(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Handwritten Canvas Diagram',
                content: '[Diagram vector data saved with ${points.length} strokes]',
                createdAt: DateTime.now(),
                modifiedAt: DateTime.now(),
              );
              widget.onSaveDoodle(doodleNote);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            points.add(DrawingPoint(
              offset: details.localPosition,
              color: selectedColor,
              strokeWidth: 3.0,
            ));
          });
        },
        onPanEnd: (details) => points.add(null),
        child: CustomPaint(
          painter: _DoodlePainter(points: points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<DrawingPoint?> points;
  _DoodlePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final paint = Paint()
          ..color = points[i]!.color
          ..strokeCap = StrokeCap.round
          ..strokeWidth = points[i]!.strokeWidth;
        canvas.drawLine(points[i]!.offset, points[i + 1]!.offset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const XNotesUltimateApp());
}

// ============================================================================
// 1. DATA MODELS & ENUMS
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

class Note {
  String id;
  String title;
  String content;
  String category;
  String folder;
  String mood;
  String audioTranscript;
  int audioDurationSec;
  PriorityLevel priority;
  NoteFontFamily fontFamily;
  bool isPinned;
  bool isFavorite;
  bool isVaulted;
  bool isArchived;
  bool isTrash;
  bool isReadOnly;
  DateTime createdAt;
  DateTime modifiedAt;
  DateTime? reminderAt;
  int revisionCount;
  int habitStreak;
  List<ChecklistItem> checklist;
  List<ExpenseItem> expenses;
  List<String> attachments; // simulated local URIs
  int colorHex;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.folder = 'Default',
    this.mood = '💡 Inspired',
    this.audioTranscript = '',
    this.audioDurationSec = 0,
    this.priority = PriorityLevel.medium,
    this.fontFamily = NoteFontFamily.sans,
    this.isPinned = false,
    this.isFavorite = false,
    this.isVaulted = false,
    this.isArchived = false,
    this.isTrash = false,
    this.isReadOnly = false,
    required this.createdAt,
    required this.modifiedAt,
    this.reminderAt,
    this.revisionCount = 1,
    this.habitStreak = 0,
    List<ChecklistItem>? checklist,
    List<ExpenseItem>? expenses,
    List<String>? attachments,
    this.colorHex = 0xFF7C4DFF,
  })  : checklist = checklist ?? [],
        expenses = expenses ?? [],
        attachments = attachments ?? [];

  Note copyWith({
    String? title,
    String? content,
    String? category,
    String? folder,
    String? mood,
    String? audioTranscript,
    int? audioDurationSec,
    PriorityLevel? priority,
    NoteFontFamily? fontFamily,
    bool? isPinned,
    bool? isFavorite,
    bool? isVaulted,
    bool? isArchived,
    bool? isTrash,
    bool? isReadOnly,
    DateTime? modifiedAt,
    DateTime? reminderAt,
    int? revisionCount,
    int? habitStreak,
    List<ChecklistItem>? checklist,
    List<ExpenseItem>? expenses,
    List<String>? attachments,
    int? colorHex,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      folder: folder ?? this.folder,
      mood: mood ?? this.mood,
      audioTranscript: audioTranscript ?? this.audioTranscript,
      audioDurationSec: audioDurationSec ?? this.audioDurationSec,
      priority: priority ?? this.priority,
      fontFamily: fontFamily ?? this.fontFamily,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isVaulted: isVaulted ?? this.isVaulted,
      isArchived: isArchived ?? this.isArchived,
      isTrash: isTrash ?? this.isTrash,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      reminderAt: reminderAt ?? this.reminderAt,
      revisionCount: revisionCount ?? (this.revisionCount + 1),
      habitStreak: habitStreak ?? this.habitStreak,
      checklist: checklist ?? List.from(this.checklist),
      expenses: expenses ?? List.from(this.expenses),
      attachments: attachments ?? List.from(this.attachments),
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'folder': folder,
        'mood': mood,
        'audioTranscript': audioTranscript,
        'audioDurationSec': audioDurationSec,
        'priority': priority.index,
        'fontFamily': fontFamily.index,
        'isPinned': isPinned,
        'isFavorite': isFavorite,
        'isVaulted': isVaulted,
        'isArchived': isArchived,
        'isTrash': isTrash,
        'isReadOnly': isReadOnly,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
        'revisionCount': revisionCount,
        'habitStreak': habitStreak,
        'checklist': checklist.map((x) => x.toMap()).toList(),
        'expenses': expenses.map((x) => x.toMap()).toList(),
        'attachments': attachments,
        'colorHex': colorHex,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        category: map['category'] ?? 'General',
        folder: map['folder'] ?? 'Default',
        mood: map['mood'] ?? '💡 Inspired',
        audioTranscript: map['audioTranscript'] ?? '',
        audioDurationSec: map['audioDurationSec'] ?? 0,
        priority: PriorityLevel.values[map['priority'] ?? 1],
        fontFamily: NoteFontFamily.values[map['fontFamily'] ?? 0],
        isPinned: map['isPinned'] ?? false,
        isFavorite: map['isFavorite'] ?? false,
        isVaulted: map['isVaulted'] ?? false,
        isArchived: map['isArchived'] ?? false,
        isTrash: map['isTrash'] ?? false,
        isReadOnly: map['isReadOnly'] ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        modifiedAt: DateTime.tryParse(map['modifiedAt'] ?? '') ?? DateTime.now(),
        reminderAt: map['reminderAt'] != null ? DateTime.tryParse(map['reminderAt']) : null,
        revisionCount: map['revisionCount'] ?? 1,
        habitStreak: map['habitStreak'] ?? 0,
        checklist: (map['checklist'] as List<dynamic>?)
                ?.map((item) => ChecklistItem.fromMap(item))
                .toList() ??
            [],
        expenses: (map['expenses'] as List<dynamic>?)
                ?.map((item) => ExpenseItem.fromMap(item))
                .toList() ??
            [],
        attachments: List<String>.from(map['attachments'] ?? []),
        colorHex: map['colorHex'] ?? 0xFF7C4DFF,
      );
}

// ============================================================================
// 2. ULTRA-PREMIUM GLASSMORPHISM CORE UI WIDGETS
// ============================================================================

class AmbientBackdrop extends StatelessWidget {
  final Widget child;
  final bool isOledMode;
  final double blurIntensity;

  const AmbientBackdrop({
    super.key,
    required this.child,
    this.isOledMode = false,
    this.blurIntensity = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    if (isOledMode) {
      return Container(
        color: Colors.black,
        child: child,
      );
    }
    return Stack(
      children: [
        Container(color: const Color(0xFF090A10)),
        // Ambient Glowing Orbs
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9C27B0).withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -100,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF4081).withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class FrostedGlassBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? surfaceColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FrostedGlassBox({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.blur = 18.0,
    this.borderColor,
    this.surfaceColor,
    this.padding,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? Colors.white.withValues(alpha: 0.15);
    final effectiveSurface = surfaceColor ?? Colors.white.withValues(alpha: 0.06);

    Widget box = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: effectiveSurface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const dynamicOffset(0, 8),
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

const dynamicOffset = Offset.new;

// ============================================================================
// 3. OFFLINE QR CODE PAINTER (ZERO DEPENDENCIES)
// ============================================================================

class OfflineQrCanvasPainter extends CustomPainter {
  final String text;
  OfflineQrCanvasPainter(this.text);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = Colors.white;
    final paintLight = Paint()..color = const Color(0xFF1E1E2E);

    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)),
      paintLight,
    );

    // Deterministic pseudo-matrix derived from string bytes
    final bytes = utf8.encode(text);
    const int matrixSize = 17;
    final double cellSize = size.width / (matrixSize + 2);

    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        // Draw corners finder patterns
        final bool isCornerFinder = (r < 4 && c < 4) || (r < 4 && c > matrixSize - 5) || (r > matrixSize - 5 && c < 4);
        bool shouldFill = false;

        if (isCornerFinder) {
          shouldFill = (r == 0 || r == 3 || c == 0 || c == 3 || (r > matrixSize - 5 && (r == matrixSize - 1 || c == 0 || c == 3)) || (c > matrixSize - 5 && (r == 0 || r == 3 || c == matrixSize - 1)));
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
// 4. MAIN APPLICATION ROOT WIDGET
// ============================================================================

class XNotesUltimateApp extends StatefulWidget {
  const XNotesUltimateApp({super.key});

  @override
  State<XNotesUltimateApp> createState() => _XNotesUltimateAppState();
}

class _XNotesUltimateAppState extends State<XNotesUltimateApp> {
  bool _isOledMode = false;
  double _globalBlur = 18.0;

  void updateTheme({bool? isOled, double? blur}) {
    setState(() {
      if (isOled != null) _isOledMode = isOled;
      if (blur != null) _globalBlur = blur;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xNotes Ultimate',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFD500F9),
          surface: Color(0xFF13141F),
        ),
      ),
      home: MasterHomeScreen(
        isOledMode: _isOledMode,
        blurIntensity: _globalBlur,
        onThemeChanged: updateTheme,
      ),
    );
  }
}

// ============================================================================
// 5. MASTER HOME SCREEN CONTROLLER & UI
// ============================================================================

class MasterHomeScreen extends StatefulWidget {
  final bool isOledMode;
  final double blurIntensity;
  final Function({bool? isOled, double? blur}) onThemeChanged;

  const MasterHomeScreen({
    super.key,
    required this.isOledMode,
    required this.blurIntensity,
    required this.onThemeChanged,
  });

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> with SingleTickerProviderStateMixin {
  List<Note> _allNotes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  SortOrder _currentSort = SortOrder.modifiedDesc;
  ViewLayout _currentLayout = ViewLayout.grid;

  // Security & Vault
  bool _isAppLocked = true;
  bool _isVaultUnlocked = false;
  bool _isIncognitoMode = false;
  String _masterPin = "1234";
  String _vaultPassword = "vault";

  // Scratchpad
  String _scratchpadText = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final notesRaw = prefs.getString('xnotes_data');
    final scratch = prefs.getString('xnotes_scratchpad') ?? '';
    final pin = prefs.getString('xnotes_pin') ?? '1234';
    final vault = prefs.getString('xnotes_vault') ?? 'vault';

    List<Note> loaded = [];
    if (notesRaw != null && notesRaw.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(notesRaw);
      loaded = decoded.map((e) => Note.fromMap(e)).toList();
    } else {
      loaded = _generateInitialSeedNotes();
    }

    setState(() {
      _allNotes = loaded;
      _scratchpadText = scratch;
      _masterPin = pin;
      _vaultPassword = vault;
      _isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    if (_isIncognitoMode) return; // Incognito doesn't save to disk!
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _allNotes.map((n) => n.toMap()).toList();
    await prefs.setString('xnotes_data', jsonEncode(jsonList));
  }

  Future<void> _saveScratchpad(String val) async {
    _scratchpadText = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('xnotes_scratchpad', val);
  }

  List<Note> _generateInitialSeedNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: '1',
        title: '💎 Welcome to xNotes Ultimate',
        content: 'Experience ultra-premium glassmorphic note-taking with local intelligence and absolute offline privacy.\n\nEnjoy features like:\n• Interactive Checklists\n• Local 3-Line AI Summaries\n• Secret Vault Folders\n• Expense & Habit Trackers',
        category: 'Ideas',
        folder: 'Welcome',
        mood: '🚀 Productive',
        priority: PriorityLevel.urgent,
        isPinned: true,
        createdAt: now,
        modifiedAt: now,
        checklist: [
          ChecklistItem(id: 'c1', text: 'Explore Glass Blur slider in Settings', isDone: true),
          ChecklistItem(id: 'c2', text: 'Create your first encrypted Vault Note', isDone: false),
          ChecklistItem(id: 'c3', text: 'Test offline text-to-speech simulator', isDone: false),
        ],
      ),
      Note(
        id: '2',
        title: '⚡ UI/UX Architecture Manifesto',
        content: '# Glassmorphic Philosophy\nBlur sigma values must blend seamlessly into dynamic radial backdrops. Inner neon glows provide tactile feedback for power-users.',
        category: 'Work',
        folder: 'Design',
        mood: '🎨 Creative',
        priority: PriorityLevel.high,
        isFavorite: true,
        createdAt: now.subtract(const Duration(hours: 3)),
        modifiedAt: now.subtract(const Duration(minutes: 15)),
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
          n.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.audioTranscript.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchCat && matchQuery;
    }).toList()
      ..sort((a, b) {
        // Pinned notes always top unless sorting specifically
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        switch (_currentSort) {
          case SortOrder.modifiedDesc:
            return b.modifiedAt.compareTo(a.modifiedAt);
          case SortOrder.modifiedAsc:
            return a.modifiedAt.compareTo(b.modifiedAt);
          case SortOrder.createdDesc:
            return b.createdAt.compareTo(a.createdAt);
          case SortOrder.titleAsc:
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          case SortOrder.priorityDesc:
            return b.priority.index.compareTo(a.priority.index);
        }
      });
  }

  void _addOrUpdateNote(Note note) {
    final idx = _allNotes.indexWhere((element) => element.id == note.id);
    setState(() {
      if (idx >= 0) {
        _allNotes[idx] = note;
      } else {
        _allNotes.insert(0, note);
      }
    });
    _saveNotes();
  }

  void _duplicateNote(Note note) {
    final copy = note.copyWith(
      title: '${note.title} (Copy)',
      modifiedAt: DateTime.now(),
    );
    copy.id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _allNotes.insert(0, copy);
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note duplicated successfully!')),
    );
  }

  void _softDelete(Note note) {
    setState(() {
      note.isTrash = true;
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Moved to Recycle Bin'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              note.isTrash = false;
            });
            _saveNotes();
          },
        ),
      ),
    );
  }

  // Multi-note merging
  void _mergeNotesDialog() {
    List<String> selectedIds = [];
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final activeNotes = _allNotes.where((n) => !n.isTrash && !n.isArchived).toList();
            return AlertDialog(
              backgroundColor: const Color(0xFF181926),
              title: const Text('Merge Notes'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  itemCount: activeNotes.length,
                  itemBuilder: (c, i) {
                    final n = activeNotes[i];
                    final isChecked = selectedIds.contains(n.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(n.title.isEmpty ? 'Untitled' : n.title),
                      onChanged: (val) {
                        setDlgState(() {
                          if (val == true) {
                            selectedIds.add(n.id);
                          } else {
                            selectedIds.remove(n.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedIds.length < 2
                      ? null
                      : () {
                          final notesToMerge = _allNotes.where((n) => selectedIds.contains(n.id)).toList();
                          final mergedContent = notesToMerge.map((e) => '### ${e.title}\n${e.content}').join('\n\n---\n\n');
                          final newNote = Note(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: 'Merged Document (${notesToMerge.length} notes)',
                            content: mergedContent,
                            createdAt: DateTime.now(),
                            modifiedAt: DateTime.now(),
                          );
                          setState(() {
                            _allNotes.insert(0, newNote);
                          });
                          _saveNotes();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes merged into new document!')));
                        },
                  child: const Text('Merge'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Backup & Restore
  void _exportJsonBackup() {
    final raw = jsonEncode(_allNotes.map((e) => e.toMap()).toList());
    Clipboard.setData(ClipboardData(text: raw));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON Backup copied to Clipboard! Paste to save locally.')),
    );
  }

  void _restoreJsonBackupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F30),
        title: const Text('Restore JSON Backup'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste raw JSON backup here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              try {
                final List<dynamic> list = jsonDecode(ctrl.text);
                setState(() {
                  _allNotes = list.map((e) => Note.fromMap(e)).toList();
                });
                _saveNotes();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database restored successfully!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON structure!')));
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // Quick Clipboard Importer
  void _importFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      final now = DateTime.now();
      final newNote = Note(
        id: now.millisecondsSinceEpoch.toString(),
        title: 'Clipboard Import (${DateFormat('MMM d, HH:mm').format(now)})',
        content: data.text!,
        createdAt: now,
        modifiedAt: now,
      );
      setState(() {
        _allNotes.insert(0, newNote);
      });
      _saveNotes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported note from clipboard!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLocked) {
      return _buildPasscodeLockGate();
    }

    return AmbientBackdrop(
      isOledMode: widget.isOledMode,
      blurIntensity: widget.blurIntensity,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildTopGlassAppBar(),
        drawer: _buildSideDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNotesMainFeed(),
                  _buildScratchpadView(),
                  _buildCalendarView(),
                  _buildHabitTrackerView(),
                  _buildAnalyticsDashboard(),
                ],
              ),
        bottomNavigationBar: _buildGlassBottomNav(),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                elevation: 10,
                onPressed: () => _openNoteEditor(null),
                icon: const Icon(Icons.add_rounded, size: 28),
                label: const Text('NEW NOTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              )
            : null,
      ),
    );
  }

  // Passcode Lock Gate Screen
  Widget _buildPasscodeLockGate() {
    String enteredPin = "";
    return StatefulBuilder(
      builder: (context, setGateState) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: FrostedGlassBox(
              blur: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 68, color: Color(0xFF00E5FF)),
                  const SizedBox(height: 16),
                  const Text('xNotes Ultimate Protected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Enter App PIN (Default: $_masterPin)', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool filled = index < enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? const Color(0xFF00E5FF) : Colors.white24,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Number Pad Grid
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (var i = 1; i <= 9; i++)
                        _pinKey('$i', () {
                          if (enteredPin.length < 4) {
                            setGateState(() => enteredPin += '$i');
                            if (enteredPin == _masterPin) {
                              setState(() => _isAppLocked = false);
                            }
                          }
                        }),
                      _pinKey('Clear', () => setGateState(() => enteredPin = '')),
                      _pinKey('0', () {
                        if (enteredPin.length < 4) {
                          setGateState(() => enteredPin += '0');
                          if (enteredPin == _masterPin) {
                            setState(() => _isAppLocked = false);
                          }
                        }
                      }),
                      _pinKey('Unlock', () {
                        if (enteredPin == _masterPin) {
                          setState(() => _isAppLocked = false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Passcode!')));
                          setGateState(() => enteredPin = '');
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

  Widget _pinKey(String label, VoidCallback onTap) {
    return SizedBox(
      width: 70,
      height: 70,
      child: FrostedGlassBox(
        padding: EdgeInsets.zero,
        borderRadius: 35,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(74),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
            padding: const EdgeInsets.only(top: 28, left: 16, right: 16),
            child: Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.dashboard_customize_rounded, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search notes, tags, transcripts...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, size: 20, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _currentLayout == ViewLayout.grid
                        ? Icons.grid_view_rounded
                        : _currentLayout == ViewLayout.list
                            ? Icons.view_agenda_rounded
                            : Icons.table_rows_rounded,
                    color: const Color(0xFF00E5FF),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_currentLayout == ViewLayout.grid) {
                        _currentLayout = ViewLayout.list;
                      } else if (_currentLayout == ViewLayout.list) {
                        _currentLayout = ViewLayout.compact;
                      } else {
                        _currentLayout = ViewLayout.grid;
                      }
                    });
                  },
                ),
                PopupMenuButton<SortOrder>(
                  icon: const Icon(Icons.sort_rounded, color: Colors.white70),
                  onSelected: (val) => setState(() => _currentSort = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: SortOrder.modifiedDesc, child: Text('Modified (Recent)')),
                    const PopupMenuItem(value: SortOrder.modifiedAsc, child: Text('Modified (Oldest)')),
                    const PopupMenuItem(value: SortOrder.createdDesc, child: Text('Date Created')),
                    const PopupMenuItem(value: SortOrder.titleAsc, child: Text('Title (A-Z)')),
                    const PopupMenuItem(value: SortOrder.priorityDesc, child: Text('Priority Highest')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: FrostedGlassBox(
        borderRadius: 0,
        blur: 25,
        surfaceColor: const Color(0xFF0C0D17).withValues(alpha: 0.88),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 50),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFFD500F9)]),
                  ),
                  child: const Icon(Icons.edit_note_rounded, size: 28, color: Colors.black),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('xNotes Ultimate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Local Offline Engine v5.0', style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                )
              ],
            ),
            const Divider(color: Colors.white12, height: 36),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded, color: Color(0xFF00E5FF)),
              title: const Text('Secret Vault Folder'),
              subtitle: Text(_isVaultUnlocked ? 'Unlocked' : 'Locked'),
              trailing: Switch(
                value: _isVaultUnlocked,
                activeColor: const Color(0xFF00E5FF),
                onChanged: (val) {
                  if (val) {
                    _promptVaultPassword();
                  } else {
                    setState(() => _isVaultUnlocked = false);
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_rounded, color: Colors.amber),
              title: const Text('Incognito Mode'),
              subtitle: const Text('Session memory only (No save)'),
              trailing: Switch(
                value: _isIncognitoMode,
                activeColor: Colors.amber,
                onChanged: (val) {
                  setState(() => _isIncognitoMode = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(val ? 'Incognito Mode Activated' : 'Normal Persistence Restored')),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.merge_type_rounded, color: Colors.purpleAccent),
              title: const Text('Merge Multiple Notes'),
              onTap: () {
                Navigator.pop(context);
                _mergeNotesDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.paste_rounded, color: Colors.lightGreenAccent),
              title: const Text('Quick Import Clipboard'),
              onTap: () {
                Navigator.pop(context);
                _importFromClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.orangeAccent),
              title: const Text('Archive View'),
              onTap: () {
                Navigator.pop(context);
                _showArchiveOrTrashModal(isTrashView: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Recycle Bin'),
              onTap: () {
                Navigator.pop(context);
                _showArchiveOrTrashModal(isTrashView: true);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: Colors.tealAccent),
              title: const Text('Export JSON Backup'),
              onTap: () {
                Navigator.pop(context);
                _exportJsonBackup();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_rounded, color: Colors.cyanAccent),
              title: const Text('Restore from Backup'),
              onTap: () {
                Navigator.pop(context);
                _restoreJsonBackupDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded, color: Colors.pinkAccent),
              title: const Text('Glass & Theme Tuning'),
              onTap: () {
                Navigator.pop(context);
                _showThemeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptVaultPassword() {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F30),
        title: const Text('Unlock Secret Vault'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter Vault Password (default: vault)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text == _vaultPassword) {
                setState(() => _isVaultUnlocked = true);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault Unlocked!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password!')));
              }
            },
            child: const Text('Unlock'),
          )
        ],
      ),
    );
  }

  void _showArchiveOrTrashModal({required bool isTrashView}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final list = _allNotes.where((n) => isTrashView ? n.isTrash : (!n.isTrash && n.isArchived)).toList();
        return FrostedGlassBox(
          blur: 24,
          borderRadius: 24,
          surfaceColor: const Color(0xFF131422).withValues(alpha: 0.95),
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                Text(isTrashView ? 'Recycle Bin' : 'Archived Notes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: list.isEmpty
                      ? Center(child: Text('No ${isTrashView ? 'deleted' : 'archived'} items.'))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (c, i) {
                            final n = list[i];
                            return ListTile(
                              title: Text(n.title.isEmpty ? 'Untitled' : n.title),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore_rounded, color: Colors.greenAccent),
                                    onPressed: () {
                                      setState(() {
                                        if (isTrashView) n.isTrash = false;
                                        n.isArchived = false;
                                      });
                                      _saveNotes();
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  if (isTrashView)
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          _allNotes.removeWhere((item) => item.id == n.id);
                                        });
                                        _saveNotes();
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161726),
            title: const Text('Theme & Glass Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('True OLED Black Mode'),
                  value: widget.isOledMode,
                  onChanged: (v) {
                    widget.onThemeChanged(isOled: v);
                    setDlgState(() {});
                  },
                ),
                const SizedBox(height: 12),
                const Text('Frosted Blur Intensity'),
                Slider(
                  min: 5.0,
                  max: 35.0,
                  value: widget.blurIntensity,
                  onChanged: (v) {
                    widget.onThemeChanged(blur: v);
                    setDlgState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
            ],
          );
        },
      ),
    );
  }

  // Main Notes Feed with Category Filter
  Widget _buildNotesMainFeed() {
    final categories = ['All', 'Ideas', 'Work', 'Personal', 'Journal', 'Goals'];
    final displayList = _filteredNotes;

    return Column(
      children: [
        // Category Chips Bar
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: FrostedGlassBox(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  borderRadius: 20,
                  surfaceColor: isSel ? const Color(0xFF00E5FF).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                  borderColor: isSel ? const Color(0xFF00E5FF) : Colors.white12,
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSel ? const Color(0xFF00E5FF) : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
          child: displayList.isEmpty
              ? _buildEmptyState()
              : _currentLayout == ViewLayout.grid
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: displayList.length,
                      itemBuilder: (c, i) => _buildNoteCard(displayList[i]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayList.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildNoteCard(displayList[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notes_rounded, size: 72, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text('No notes found in this view', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isCompact = _currentLayout == ViewLayout.compact;
    return FrostedGlassBox(
      borderRadius: 20,
      borderColor: note.isPinned ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : null,
      onTap: () => _openNoteEditor(note),
      onLongPress: () => _showQuickActionSheet(note),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.isPinned) const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFF00E5FF)),
              if (note.isFavorite) const Icon(Icons.favorite_rounded, size: 16, color: Colors.pinkAccent),
              if (note.isVaulted) const Icon(Icons.lock_rounded, size: 16, color: Colors.amberAccent),
              const Spacer(),
              _buildPriorityBadge(note.priority),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.title.isEmpty ? 'Untitled Note' : note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          if (!isCompact)
            Expanded(
              child: Text(
                note.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
              ),
            ),
          if (note.checklist.isNotEmpty) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: note.checklist.where((x) => x.isDone).length / note.checklist.length,
              backgroundColor: Colors.white10,
              color: const Color(0xFF00E5FF),
              minHeight: 4,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d').format(note.modifiedAt),
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
              Text(
                note.mood,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(PriorityLevel priority) {
    Color col;
    String label;
    switch (priority) {
      case PriorityLevel.urgent:
        col = Colors.redAccent;
        label = 'Urgent';
        break;
      case PriorityLevel.high:
        col = Colors.orangeAccent;
        label = 'High';
        break;
      case PriorityLevel.medium:
        col = Colors.tealAccent;
        label = 'Med';
        break;
      case PriorityLevel.low:
        col = Colors.blueGrey;
        label = 'Low';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col, width: 0.8),
      ),
      child: Text(label, style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _showQuickActionSheet(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassBox(
        surfaceColor: const Color(0xFF131422).withValues(alpha: 0.96),
        borderRadius: 24,
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: const Color(0xFF00E5FF)),
              title: Text(note.isPinned ? 'Unpin' : 'Pin to Top'),
              onTap: () {
                setState(() => note.isPinned = !note.isPinned);
                _saveNotes();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(note.isFavorite ? Icons.favorite_border_rounded : Icons.favorite_rounded, color: Colors.pinkAccent),
              title: Text(note.isFavorite ? 'Remove Favorite' : 'Mark Favorite'),
              onTap: () {
                setState(() => note.isFavorite = !note.isFavorite);
                _saveNotes();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.lightGreenAccent),
              title: const Text('Duplicate Note'),
              onTap: () {
                Navigator.pop(ctx);
                _duplicateNote(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: Colors.orangeAccent),
              title: const Text('Archive Note'),
              onTap: () {
                setState(() => note.isArchived = true);
                _saveNotes();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Move to Recycle Bin'),
              onTap: () {
                Navigator.pop(ctx);
                _softDelete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Tab 2: Quick Idea Scratchpad
  Widget _buildScratchpadView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FrostedGlassBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text('Instant Scratchpad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Auto-saves every keystroke locally.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const Divider(color: Colors.white12, height: 24),
            Expanded(
              child: TextFormField(
                initialValue: _scratchpadText,
                maxLines: null,
                expands: true,
                onChanged: (v) => _saveScratchpad(v),
                style: const TextStyle(fontSize: 16, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Dump ideas, thoughts, temporary numbers...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 3: Event & Calendar Mapping View
  Widget _buildCalendarView() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FrostedGlassBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMMM yyyy').format(now), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF00E5FF)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Notes Mapped by Day Created

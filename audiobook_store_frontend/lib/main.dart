import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// PUBLIC_INTERFACE
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AudiobookStoreApp());
}

/// Colors & Theme constants
const Color kPrimaryColor = Color(0xFF1976D2);
const Color kAccentColor = Color(0xFFFFD600);
const Color kSecondaryColor = Color(0xFFFF7043);
const kThemeTextStyleHeader = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

/// ---- DATA MODELS ----
class Audiobook {
  final String id;
  final String title;
  final String author;
  final String cover;
  final Duration duration;
  final String audioAsset;

  Audiobook({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.duration,
    required this.audioAsset,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'cover': cover,
        'duration': duration.inSeconds,
        'audioAsset': audioAsset,
      };

  factory Audiobook.fromJson(Map<String, dynamic> json) => Audiobook(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        cover: json['cover'],
        duration: Duration(seconds: json['duration']),
        audioAsset: json['audioAsset'],
      );
}

class PurchasedAudiobook {
  final Audiobook book;
  Duration position;

  PurchasedAudiobook({
    required this.book,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'book': book.toJson(),
        'position': position.inSeconds,
      };

  factory PurchasedAudiobook.fromJson(Map<String, dynamic> json) => PurchasedAudiobook(
        book: Audiobook.fromJson(json['book']),
        position: Duration(seconds: json['position']),
      );
}

/// ---- STORE DATA ----
/// Normally, data would come from server, but here we define audiobooks statically.
final List<Audiobook> kSampleAudiobooks = [
  Audiobook(
    id: 'book1',
    title: 'The Art of Focus',
    author: 'Jane Doe',
    cover: 'assets/covers/focus.jpg',
    duration: Duration(minutes: 43, seconds: 20),
    audioAsset: 'assets/audio/audio1.mp3',
  ),
  Audiobook(
    id: 'book2',
    title: 'Flutter for Beginners',
    author: 'John Smith',
    cover: 'assets/covers/flutter.jpg',
    duration: Duration(minutes: 57, seconds: 5),
    audioAsset: 'assets/audio/audio2.mp3',
  ),
  Audiobook(
    id: 'book3',
    title: 'Minimal Living',
    author: 'Mary Living',
    cover: 'assets/covers/minimal.jpg',
    duration: Duration(minutes: 35, seconds: 36),
    audioAsset: 'assets/audio/audio3.mp3',
  ),
  Audiobook(
    id: 'book4',
    title: 'Deep Work',
    author: 'Cal Newport',
    cover: 'assets/covers/deepwork.jpg',
    duration: Duration(hours: 1, minutes: 15),
    audioAsset: 'assets/audio/audio4.mp3',
  ),
];

/// ---- LOCAL STORAGE HELPER ----
class LocalStore {
  static Future<String> get _localDir async =>
      (await getApplicationDocumentsDirectory()).path;

  static Future<File> _getPurchasedFile() async {
    final dir = await _localDir;
    return File('$dir/purchased_audiobooks.json');
  }

  static Future<File> _getLastPlayedFile() async {
    final dir = await _localDir;
    return File('$dir/last_played.json');
  }

  // PUBLIC_INTERFACE
  static Future<List<PurchasedAudiobook>> loadPurchasedAudiobooks() async {
    try {
      final file = await _getPurchasedFile();
      if (await file.exists()) {
        final str = await file.readAsString();
        final list = jsonDecode(str) as List;
        return list.map((e) => PurchasedAudiobook.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // PUBLIC_INTERFACE
  static Future<void> savePurchasedAudiobooks(List<PurchasedAudiobook> books) async {
    final file = await _getPurchasedFile();
    await file.writeAsString(jsonEncode(books.map((e) => e.toJson()).toList()));
  }

  // PUBLIC_INTERFACE
  static Future<String?> loadLastPlayedBookId() async {
    try {
      final file = await _getLastPlayedFile();
      if (await file.exists()) {
        final str = await file.readAsString();
        return str.isNotEmpty ? str : null;
      }
    } catch (_) {}
    return null;
  }

  // PUBLIC_INTERFACE
  static Future<void> saveLastPlayedBookId(String bookId) async {
    final file = await _getLastPlayedFile();
    await file.writeAsString(bookId);
  }
}

/// ---- MAIN APP ----
class AudiobookStoreApp extends StatefulWidget {
  const AudiobookStoreApp({super.key});
  @override
  State<AudiobookStoreApp> createState() => _AudiobookStoreAppState();
}

class _AudiobookStoreAppState extends State<AudiobookStoreApp> {
  ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.light(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          tertiary: kAccentColor,
        ),
        brightness: Brightness.light,
        primaryColor: kPrimaryColor,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: kAccentColor),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          margin: const EdgeInsets.all(8),
        ),
        useMaterial3: true,
      );

  late Future<_AppData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _AppData.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audiobook Store',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<_AppData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return AudiobookRoot(appData: snapshot.data!);
        },
      ),
    );
  }
}

class _AppData {
  final List<Audiobook> allBooks;
  final List<PurchasedAudiobook> purchased;
  final String? lastPlayedId;

  _AppData({
    required this.allBooks,
    required this.purchased,
    required this.lastPlayedId,
  });

  static Future<_AppData> load() async {
    final purchased = await LocalStore.loadPurchasedAudiobooks();
    final lastPlayedId = await LocalStore.loadLastPlayedBookId();
    return _AppData(
      allBooks: kSampleAudiobooks,
      purchased: purchased,
      lastPlayedId: lastPlayedId,
    );
  }
}

/// Root widget with BottomNavigation
class AudiobookRoot extends StatefulWidget {
  final _AppData appData;
  const AudiobookRoot({Key? key, required this.appData}) : super(key: key);

  @override
  State<AudiobookRoot> createState() => _AudiobookRootState();
}

class _AudiobookRootState extends State<AudiobookRoot> {
  int _navIndex = 0;
  late List<PurchasedAudiobook> _purchased;
  late List<Audiobook> _allBooks;
  String? _lastPlayedId;

  PurchasedAudiobook? get _lastPlayedBook {
    try {
      return _purchased.firstWhere((b) => b.book.id == _lastPlayedId);
    } catch (_) {
      if (_purchased.isNotEmpty) return _purchased.first;
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _allBooks = widget.appData.allBooks;
    _purchased = widget.appData.purchased;
    _lastPlayedId = widget.appData.lastPlayedId;
  }

  // PUBLIC_INTERFACE
  void purchaseAudiobook(Audiobook book) async {
    if (_purchased.any((b) => b.book.id == book.id)) return;
    setState(() {
      _purchased.add(PurchasedAudiobook(book: book, position: Duration.zero));
    });
    await LocalStore.savePurchasedAudiobooks(_purchased);
  }

  // PUBLIC_INTERFACE
  void onSelectPlayer(PurchasedAudiobook pBook) async {
    setState(() {
      _lastPlayedId = pBook.book.id;
    });
    await LocalStore.saveLastPlayedBookId(_lastPlayedId!);
  }

  // PUBLIC_INTERFACE
  void updatePlaybackPosition(String bookId, Duration pos) async {
    final idx = _purchased.indexWhere((b) => b.book.id == bookId);
    if (idx != -1) {
      setState(() {
        _purchased[idx] = PurchasedAudiobook(book: _purchased[idx].book, position: pos);
      });
      await LocalStore.savePurchasedAudiobooks(_purchased);
    }
  }

  // PUBLIC_INTERFACE
  void deleteFromLibrary(String bookId) async {
    setState(() {
      _purchased.removeWhere((b) => b.book.id == bookId);
      if (_lastPlayedId == bookId) _lastPlayedId = null;
    });
    await LocalStore.savePurchasedAudiobooks(_purchased);
    await LocalStore.saveLastPlayedBookId(_lastPlayedId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      StoreTab(
        books: _allBooks,
        purchasedIds: _purchased.map((e) => e.book.id).toSet(),
        onPurchase: purchaseAudiobook,
      ),
      LibraryTab(
        purchased: _purchased,
        onOpen: (b) {
          onSelectPlayer(b);
          setState(() {
            _navIndex = 2;
          });
        },
        onDelete: deleteFromLibrary,
      ),
      PlayerTab(
        purchasedBook: _lastPlayedBook,
        onPositionUpdate: updatePlaybackPosition,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: tabs[_navIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (idx) {
          setState(() => _navIndex = idx);
        },
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Player'),
        ],
      ),
    );
  }
}

/// ---- STORE TAB ----
class StoreTab extends StatelessWidget {
  final List<Audiobook> books;
  final Set<String> purchasedIds;
  final void Function(Audiobook) onPurchase;

  const StoreTab({
    Key? key,
    required this.books,
    required this.purchasedIds,
    required this.onPurchase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Audiobook Store', style: kThemeTextStyleHeader),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, idx) {
                final book = books[idx];
                final isPurchased = purchasedIds.contains(book.id);
                return AudiobookCard(
                  book: book,
                  isPurchased: isPurchased,
                  onBuy: () => onPurchase(book),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AudiobookCard extends StatelessWidget {
  final Audiobook book;
  final bool isPurchased;
  final VoidCallback onBuy;

  const AudiobookCard({
    Key? key,
    required this.book,
    required this.isPurchased,
    required this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return Card(
      shape: border,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100],
              width: double.infinity,
              child: book.cover.startsWith('assets/')
                  ? Image.asset(
                      book.cover,
                      fit: BoxFit.cover,
                    )
                  : Container(color: kAccentColor, child: const Icon(Icons.book, size: 50)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
            child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(book.author, style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(book.duration), style: const TextStyle(fontSize: 12)),
                isPurchased
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(color: kSecondaryColor, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Owned', style: TextStyle(fontSize: 12, color: Colors.white)),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          backgroundColor: kAccentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onBuy,
                        child: const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// ---- LIBRARY TAB ----
class LibraryTab extends StatelessWidget {
  final List<PurchasedAudiobook> purchased;
  final void Function(PurchasedAudiobook) onOpen;
  final void Function(String) onDelete;

  const LibraryTab({
    Key? key,
    required this.purchased,
    required this.onOpen,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (purchased.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 120.0),
          child: Column(
            children: [
              const Icon(Icons.library_books, size: 70, color: kSecondaryColor),
              const SizedBox(height: 30),
              Text(
                'No audiobooks in your library.\nGo to the Store tab and buy one!',
                style: TextStyle(color: Colors.grey[800], fontSize: 17), 
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Your Library', style: kThemeTextStyleHeader),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: purchased.length,
            separatorBuilder: (_, __) => const Divider(indent: 80, endIndent: 12),
            itemBuilder: (context, idx) {
              final pBook = purchased[idx];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: pBook.book.cover.startsWith('assets/')
                      ? Image.asset(pBook.book.cover, height: 55, width: 55, fit: BoxFit.cover)
                      : const Icon(Icons.book, size: 55, color: kAccentColor),
                ),
                title: Text(pBook.book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pBook.book.author, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    ProgressBarTiny(
                      value: pBook.position.inSeconds.toDouble(),
                      max: pBook.book.duration.inSeconds.toDouble(),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle, color: kPrimaryColor),
                      tooltip: 'Open Player',
                      onPressed: () => onOpen(pBook),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: kSecondaryColor),
                      tooltip: 'Remove from library',
                      onPressed: () => onDelete(pBook.book.id),
                    ),
                  ],
                ),
                onTap: () => onOpen(pBook),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ---- PLAYER TAB ----
/// Feature: Dedicated full-screen audio player with skip, progress, track title, etc.
class PlayerTab extends StatefulWidget {
  final PurchasedAudiobook? purchasedBook;
  final void Function(String, Duration) onPositionUpdate;

  const PlayerTab({
    Key? key,
    required this.purchasedBook,
    required this.onPositionUpdate,
  }) : super(key: key);

  @override
  State<PlayerTab> createState() => _PlayerTabState();
}

class _PlayerTabState extends State<PlayerTab> with WidgetsBindingObserver {
  AudioPlayerController? _controller;
  StreamSubscription? _positionSub;

  @override
  void dispose() {
    _positionSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _subscribeToPosition() {
    if (_controller == null) return;
    _positionSub?.cancel();
    _positionSub = _controller!.onPositionChanged.listen((pos) {
      widget.onPositionUpdate(widget.purchasedBook!.book.id, pos);
    });
  }

  @override
  void didUpdateWidget(covariant PlayerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final book = widget.purchasedBook;
    if (oldWidget.purchasedBook?.book.id != book?.book.id) {
      _controller?.dispose();
      _controller = book != null
          ? AudioPlayerController(asset: book.book.audioAsset, start: book.position)
          : null;
      _subscribeToPosition();
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.purchasedBook;
    if (book == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 140.0),
          child: Column(
            children: [
              const Icon(Icons.play_circle_outline, size: 80, color: kPrimaryColor),
              const SizedBox(height: 40),
              Text(
                'No audiobook selected.\nSelect from your Library.',
                style: TextStyle(color: Colors.grey[800], fontSize: 17),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final ctrl = _controller ??
        (() {
          _controller = AudioPlayerController(
            asset: book.book.audioAsset,
            start: book.position,
          );
          _subscribeToPosition();
          return _controller!;
        })();

    return AudiobookPlayer(
      purchasedBook: book,
      controller: ctrl,
    );
  }
}

/// ---- AUDIO PLAYER UI + CONTROLLER ----
class AudiobookPlayer extends StatefulWidget {
  final PurchasedAudiobook purchasedBook;
  final AudioPlayerController controller;
  const AudiobookPlayer({Key? key, required this.purchasedBook, required this.controller}) : super(key: key);

  @override
  State<AudiobookPlayer> createState() => _AudiobookPlayerState();
}

class _AudiobookPlayerState extends State<AudiobookPlayer> {
  late AudioPlayerController _controller;
  late PurchasedAudiobook _pBook;

  Duration _current = Duration.zero;
  late Duration _total;
  bool _seeking = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _pBook = widget.purchasedBook;
    _total = _pBook.book.duration;
    _controller.onPositionChanged.listen((pos) {
      if (!_seeking) {
        setState(() => _current = pos);
      }
    });
    _controller.onComplete.listen((_) {
      setState(() => _current = _total);
    });
    if (!_controller.isPlaying) {
      _controller.play();
    }
    _current = _controller.position;
  }

  @override
  void dispose() {
    _controller.pause();
    super.dispose();
  }

  void _seekRel(int seconds) {
    final int minSec = 0;
    final int maxSec = _total.inSeconds;
    final int toSec = (_current.inSeconds + seconds).clamp(minSec, maxSec);
    final Duration to = Duration(seconds: toSec);
    _controller.seek(to);
    setState(() {
      _current = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = _pBook.book;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 25),
            SizedBox(
              width: 180,
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: book.cover.startsWith('assets/')
                    ? Image.asset(book.cover, fit: BoxFit.cover)
                    : Container(color: kAccentColor, child: const Icon(Icons.book, size: 60)),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  Text(book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
                      maxLines: 2,
                      textAlign: TextAlign.center),
                  Text(book.author, style: const TextStyle(fontSize: 15, color: kPrimaryColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  ProgressBarFancy(
                    value: _current.inSeconds.toDouble(),
                    max: _total.inSeconds.toDouble(),
                    onChangedStart: (_) => setState(() => _seeking = true),
                    onChangedEnd: (d) {
                      _controller.seek(Duration(seconds: d.toInt()));
                      setState(() {
                        _current = Duration(seconds: d.toInt());
                        _seeking = false;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_current), style: const TextStyle(fontSize: 14)),
                      Text('-${_formatDuration(_total - _current)}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.rotate_left, size: 32, color: kPrimaryColor),
                  tooltip: 'Back 15s',
                  onPressed: () => _seekRel(-15),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _controller.isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 52,
                    color: kSecondaryColor,
                  ),
                  tooltip: _controller.isPlaying ? 'Pause' : 'Play',
                  onPressed: () {
                    setState(() {
                      _controller.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.rotate_right, size: 32, color: kPrimaryColor),
                  tooltip: 'Forward 15s',
                  onPressed: () => _seekRel(15),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(indent: 50, endIndent: 50, color: Colors.black12),
            const SizedBox(height: 18),
            Text(
              'Enjoy your audiobook!',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// ---- PROGRESS BAR WIDGETS ----
class ProgressBarTiny extends StatelessWidget {
  final double value;
  final double max;
  const ProgressBarTiny({Key? key, required this.value, required this.max}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = max == 0 ? 0 : value / max;
    return LinearProgressIndicator(
      value: percent.clamp(0.0, 1.0),
      backgroundColor: kAccentColor.withAlpha((0.32 * 255).toInt()),
      color: kAccentColor,
      minHeight: 5,
    );
  }
}

class ProgressBarFancy extends StatelessWidget {
  final double value;
  final double max;
  final void Function(double)? onChangedStart;
  final void Function(double)? onChangedEnd;
  const ProgressBarFancy({
    Key? key,
    required this.value,
    required this.max,
    this.onChangedStart,
    this.onChangedEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = max == 0 ? 0 : value / max;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: kAccentColor,
        inactiveTrackColor: kAccentColor.withAlpha((0.24 * 255).toInt()),
        thumbColor: kPrimaryColor,
        overlayColor: kAccentColor.withAlpha((0.22 * 255).toInt()),
        trackHeight: 6,
      ),
      child: Slider(
        value: value.clamp(0.0, max.toDouble()),
        min: 0.0,
        max: max > 0 ? max : 1.0,
        onChanged: (d) => onChangedStart?.call(d),
        onChangeEnd: (d) => onChangedEnd?.call(d),
      ),
    );
  }
}

/// ---- SIMPLE AUDIOPLAYER CONTROLLER USING AUDIOCACHE ----
/// Replace this with "audioplayers" or "just_audio" in a real app.
/// For this exercise, we'll use platform channels to mildly simulate audio playback and seeking.

typedef AudioPositionCallback = void Function(Duration);
typedef AudioCompleteCallback = void Function();

class AudioPlayerController {
  final String asset;
  final StreamController<Duration> _positionStream = StreamController.broadcast();
  final StreamController<void> _completeStream = StreamController.broadcast();
  Duration position;
  late final Duration length;
  bool _playing = false;
  Timer? _timer;

  AudioPlayerController({required this.asset, Duration? start})
      : position = start ?? Duration.zero {
    // Simulate asset lookup for length
    length = _findSampleAssetDuration(asset);
  }

  bool get isPlaying => _playing;

  Duration get duration => length;

  // PUBLIC_INTERFACE
  Stream<Duration> get onPositionChanged => _positionStream.stream;

  // PUBLIC_INTERFACE
  Stream<void> get onComplete => _completeStream.stream;

  // PUBLIC_INTERFACE
  void play() {
    _playing = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!_playing) return;
      position += const Duration(seconds: 1);
      if (position >= length) {
        position = length;
        _playing = false;
        _completeStream.add(null);
        timer.cancel();
      }
      _positionStream.add(position);
    });
  }

  // PUBLIC_INTERFACE
  void pause() {
    _playing = false;
    _timer?.cancel();
  }

  // PUBLIC_INTERFACE
  void seek(Duration pos) {
    final minSec = 0;
    final maxSec = length.inSeconds;
    final clamped = Duration(seconds: pos.inSeconds.clamp(minSec, maxSec));
    position = clamped;
    _positionStream.add(position);
  }

  // PUBLIC_INTERFACE
  void dispose() {
    _timer?.cancel();
    _positionStream.close();
    _completeStream.close();
  }
}

/// Fakes the duration of an audio asset.
/// In a real app, you'd use audioplayers/audio_service and fetch the mp3 duration properly.
Duration _findSampleAssetDuration(String asset) {
  final book = kSampleAudiobooks.firstWhere((b) => b.audioAsset == asset, orElse: () => kSampleAudiobooks.first);
  return book.duration;
}

/// ---- UTILITIES ----
String _formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$m:$s';
  }
  return '$m:$s';
}

/// ---- Placeholders for ASSETS ----
// In a real app, you must:
///  1. Place sample cover images in assets/covers/ (e.g., minimal.jpg, flutter.jpg, focus.jpg, deepwork.jpg)
///  2. Place sample mp3 files in assets/audio/
///  3. Update pubspec.yaml to include these assets

// end

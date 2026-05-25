import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html; // For web file picker and standard html tools
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'emulator_view/emulator_view.dart';

// ==========================================================================
// Web Database Bridge (IndexedDB wrapper using JS-Interop)
// ==========================================================================
class WebDbHelper {
  static bool get isWebPlatform => kIsWeb;

  static Future<void> saveGame({
    required String title,
    required String system,
    required int year,
    required String publisher,
    required String description,
    required Uint8List romBytes,
    Uint8List? coverBytes,
  }) async {
    if (!isWebPlatform) return;
    
    await js_util.promiseToFuture(
      js.context.callMethod('saveRomToDb', [
        title,
        system,
        year,
        publisher,
        description,
        romBytes,
        coverBytes ?? Uint8List(0),
      ])
    );
  }

  static Future<List<Map<String, dynamic>>> fetchGames() async {
    if (!isWebPlatform) return [];
    
    try {
      final String jsonResult = await js_util.promiseToFuture(
        js.context.callMethod('fetchRomsFromDb', [])
      );
      
      final List<dynamic> decoded = jsonDecode(jsonResult);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print("fetchGames error: $e");
      return [];
    }
  }

  static Future<String> getRomUrl(int id) async {
    if (!isWebPlatform) return "";
    
    final String url = await js_util.promiseToFuture(
      js.context.callMethod('getRomBlobUrl', [id])
    );
    return url;
  }

  static Future<void> deleteGame(int id) async {
    if (!isWebPlatform) return;
    
    await js_util.promiseToFuture(
      js.context.callMethod('deleteRomFromDb', [id])
    );
  }

  static Future<void> clearAll() async {
    if (!isWebPlatform) return;
    
    await js_util.promiseToFuture(
      js.context.callMethod('clearAllRomsFromDb', [])
    );
  }
}

// ==========================================================================
// Main App Entry
// ==========================================================================
void main() {
  runApp(const RoRetroApp());
}

class RoRetroApp extends StatefulWidget {
  const RoRetroApp({super.key});

  @override
  State<RoRetroApp> createState() => _RoRetroAppState();
}

class _RoRetroAppState extends State<RoRetroApp> {
  String _activeTheme = "purple"; // purple, blue, crimson

  void _changeTheme(String theme) {
    setState(() {
      _activeTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData;
    
    if (_activeTheme == "blue") {
      themeData = ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617),
        primaryColor: const Color(0xFF0ea5e9),
        cardColor: const Color(0xFF0f172a),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0ea5e9),
          secondary: Color(0xFF06b6d4),
          surface: Color(0xFF0f172a),
        ),
      );
    } else if (_activeTheme == "crimson") {
      themeData = ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090204),
        primaryColor: const Color(0xFFe11d48),
        cardColor: const Color(0xFF1f0710),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFe11d48),
          secondary: Color(0xFFbe123c),
          surface: Color(0xFF1f0710),
        ),
      );
    } else {
      // Default Purple-Black theme
      themeData = ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF060409),
        primaryColor: const Color(0xFF822faf),
        cardColor: const Color(0xFF120b1f),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFa855f7),
          secondary: Color(0xFF6366f1),
          surface: Color(0xFF120b1f),
        ),
      );
    }

    return MaterialApp(
      title: 'Ro-Retro | Retro Oyun Merkezi',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: GameHubScreen(
        activeTheme: _activeTheme,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

// ==========================================================================
// Game Hub Screen UI
// ==========================================================================
enum ActiveTab { discover, library, settings, emulator }

class GameHubScreen extends StatefulWidget {
  final String activeTheme;
  final Function(String) onThemeChanged;

  const GameHubScreen({
    super.key,
    required this.activeTheme,
    required this.onThemeChanged,
  });

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  ActiveTab _currentTab = ActiveTab.discover;
  String _libraryFilter = "all";
  String _searchQuery = "";
  
  List<Map<String, dynamic>> _customGames = [];
  Map<String, dynamic>? _activeGame; // The game currently playing in emulator
  
  final TextEditingController _searchController = TextEditingController();

  // Preloaded Classic Homebrew Games
  final List<Map<String, dynamic>> _preloadGames = [
    {
      "id": "preload-1",
      "title": "Alter Ego",
      "system": "nes",
      "year": 2011,
      "publisher": "RetroSouls",
      "description": "Alter Ego, her biri kendi zekice tasarlanmış bulmacalara sahip ekranlarda geçen bir platform bulmaca oyunudur. Oyuncu, kendi 'alter ego'su (gölgesi) ile yer değiştirerek engelleri aşmaya ve tüm pikselleri toplamaya çalışır.",
      "romUrl": "https://raw.githubusercontent.com/nesbox/emulator.nes/master/roms/alter_ego.nes",
      "coverUrl": "https://raw.githubusercontent.com/nesbox/emulator.nes/master/roms/alter_ego.png",
      "isCustom": false
    },
    {
      "id": "preload-2",
      "title": "Tobu Tobu Girl",
      "system": "gb",
      "year": 2017,
      "publisher": "Tangram Games",
      "description": "Tobu Tobu Girl, Game Boy için geliştirilmiş açık kaynaklı, sevimli ve tempolu bir arcade platform oyunudur. Amacınız gökyüzüne uçan kedinizi kurtarmak için engellerin üzerinden zıplayarak zamana karşı yarışmaktır.",
      "romUrl": "https://github.com/tangramgames/tobutobugirl/releases/download/v1.0.1/tobutobugirl-1.0.1.gb",
      "coverUrl": "https://tangramgames.dk/img/tobutobugirl/artwork.png",
      "isCustom": false
    },
    {
      "id": "preload-3",
      "title": "Anguna: Warriors",
      "system": "gba",
      "year": 2008,
      "publisher": "Nathan Tolbert",
      "description": "Anguna, Game Boy Advance için yapılmış Zelda tarzı efsanevi bir aksiyon-macera RPG oyunudur. Büyük zindanları keşfedin, silahlar edinin, canavarlarla savaşın ve bulmacaları çözün.",
      "romUrl": "https://raw.githubusercontent.com/reachtokishore/GBA-Homebrew/master/super_mario_land.gba",
      "coverUrl": "assets/icon.svg",
      "isCustom": false
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final games = await WebDbHelper.fetchGames();
    setState(() {
      _customGames = games;
    });
  }

  List<Map<String, dynamic>> get _displayGames {
    List<Map<String, dynamic>> games = [];
    if (_currentTab == ActiveTab.discover) {
      games = _preloadGames;
    } else {
      games = _customGames;
    }

    // Apply platform filter
    if (_libraryFilter != "all") {
      games = games.where((g) => g['system'] == _libraryFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      games = games.where((g) {
        final title = (g['title'] as String).toLowerCase();
        final system = (g['system'] as String).toLowerCase();
        return title.contains(_searchQuery.toLowerCase()) || 
               system.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return games;
  }

  // ROM Import variables
  String _importTitle = "";
  String _importSystem = "nes";
  int _importYear = 1990;
  String _importPublisher = "";
  String _importDescription = "";
  Uint8List? _importRomBytes;
  String _importRomName = "";
  Uint8List? _importImgBytes;
  String _importImgName = "";

  void _triggerRomImport() {
    // Reset import states
    setState(() {
      _importTitle = "";
      _importSystem = "nes";
      _importYear = DateTime.now().year;
      _importPublisher = "";
      _importDescription = "";
      _importRomBytes = null;
      _importRomName = "";
      _importImgBytes = null;
      _importImgName = "";
    });

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple.withOpacity(0.2), width: 1.5),
              ),
              title: const Text(
                'Yeni Retro ROM İçe Aktar',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Oyun Adı *',
                          labelStyle: TextStyle(color: Colors.grey),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.purpleAccent),
                          ),
                        ),
                        onChanged: (val) {
                          _importTitle = val;
                        },
                      ),
                      const SizedBox(height: 16),
                      // System & Year Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _importSystem,
                              dropdownColor: Theme.of(context).cardColor,
                              decoration: const InputDecoration(labelText: 'Sistem *'),
                              items: const [
                                DropdownMenuItem(value: "nes", child: Text("Nintendo (NES)")),
                                DropdownMenuItem(value: "snes", child: Text("Super Nintendo (SNES)")),
                                DropdownMenuItem(value: "genesis", child: Text("Sega Genesis")),
                                DropdownMenuItem(value: "gb", child: Text("Game Boy")),
                                DropdownMenuItem(value: "gba", child: Text("Game Boy Advance")),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    _importSystem = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: _importYear.toString(),
                              decoration: const InputDecoration(labelText: 'Yayın Yılı'),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                _importYear = int.tryParse(val) ?? 1990;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Publisher input
                      TextField(
                        decoration: const InputDecoration(labelText: 'Yayımcı / Geliştirici'),
                        onChanged: (val) {
                          _importPublisher = val;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Description input
                      TextField(
                        decoration: const InputDecoration(labelText: 'Kısa Açıklama'),
                        maxLines: 2,
                        onChanged: (val) {
                          _importDescription = val;
                        },
                      ),
                      const SizedBox(height: 24),
                      // ROM File Picker
                      InkWell(
                        onTap: () {
                          final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
                            ..accept = '.nes,.sfc,.smc,.bin,.md,.gb,.gba';
                          uploadInput.click();
                          uploadInput.onChange.listen((e) {
                            final files = uploadInput.files;
                            if (files != null && files.isNotEmpty) {
                              final file = files[0];
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              reader.onLoadEnd.listen((e) {
                                setModalState(() {
                                  _importRomBytes = reader.result as Uint8List;
                                  _importRomName = file.name;
                                  // Auto populate game name if empty
                                  if (_importTitle.isEmpty) {
                                    _importTitle = file.name.split('.').first.replaceAll('_', ' ').replaceAll('-', ' ');
                                  }
                                });
                              });
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _importRomBytes != null ? Colors.green : Colors.purple.withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1.5
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.01),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _importRomBytes != null ? Icons.check_circle : Icons.upload_file,
                                color: _importRomBytes != null ? Colors.green : Colors.purpleAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _importRomBytes != null
                                      ? 'Seçilen ROM: $_importRomName'
                                      : 'ROM Dosyası Yükle (.nes, .gba vb.) *',
                                  style: TextStyle(
                                    color: _importRomBytes != null ? Colors.green : Colors.grey,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cover Image Picker
                      InkWell(
                        onTap: () {
                          final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()
                            ..accept = 'image/*';
                          uploadInput.click();
                          uploadInput.onChange.listen((e) {
                            final files = uploadInput.files;
                            if (files != null && files.isNotEmpty) {
                              final file = files[0];
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);
                              reader.onLoadEnd.listen((e) {
                                setModalState(() {
                                  _importImgBytes = reader.result as Uint8List;
                                  _importImgName = file.name;
                                });
                              });
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _importImgBytes != null ? Colors.green : Colors.purple.withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1.5
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.01),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _importImgBytes != null ? Icons.check_circle : Icons.image,
                                color: _importImgBytes != null ? Colors.green : Colors.purpleAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _importImgBytes != null
                                      ? 'Kapak Görseli: $_importImgName'
                                      : 'Kapak Görseli Seç (Opsiyonel)',
                                  style: TextStyle(
                                    color: _importImgBytes != null ? Colors.green : Colors.grey,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_importTitle.isEmpty || _importRomBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen oyun adı ve ROM dosyasını seçin!')),
                      );
                      return;
                    }

                    Navigator.of(context).pop(); // Close modal
                    
                    // Show progress loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Oyun kaydediliyor...')),
                    );

                    try {
                      await WebDbHelper.saveGame(
                        title: _importTitle,
                        system: _importSystem,
                        year: _importYear,
                        publisher: _importPublisher,
                        description: _importDescription,
                        romBytes: _importRomBytes!,
                        coverBytes: _importImgBytes,
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$_importTitle başarıyla kütüphaneye eklendi!')),
                      );
                      
                      _loadLibrary(); // Reload
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kayıt esnasında hata oluştu!')),
                      );
                    }
                  },
                  child: const Text('Kütüphaneye Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Play preloaded online game
  Future<void> _addPreloadToLibrary(Map<String, dynamic> game) async {
    // Check if already exists in database
    bool exists = _customGames.any((g) => g['title'] == game['title']);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu oyun zaten kütüphanenizde ekli!')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oyun kütüphaneye indiriliyor, lütfen bekleyin...')),
    );

    try {
      // Fetch ROM from online URL
      final romRequest = await html.window.fetch(game['romUrl']);
      final romBlob = await romRequest.blob();
      
      // Read Blob into bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(romBlob);
      await reader.onLoadEnd.first;
      final romBytes = reader.result as Uint8List;

      // Fetch cover image bytes
      Uint8List? coverBytes;
      if (game['coverUrl'].startsWith("http")) {
        try {
          final imgRequest = await html.window.fetch(game['coverUrl']);
          final imgBlob = await imgRequest.blob();
          final imgReader = html.FileReader();
          imgReader.readAsArrayBuffer(imgBlob);
          await imgReader.onLoadEnd.first;
          coverBytes = imgReader.result as Uint8List;
        } catch (_) {}
      }

      await WebDbHelper.saveGame(
        title: game['title'],
        system: game['system'],
        year: game['year'],
        publisher: game['publisher'],
        description: game['description'],
        romBytes: romBytes,
        coverBytes: coverBytes,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game['title']} başarıyla indirildi ve kütüphanenize eklendi! Çevrimdışı oynayabilirsiniz.')),
      );

      _loadLibrary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oyun indirilemedi, lütfen bağlantınızı kontrol edin.')),
      );
    }
  }

  // Play execution bridge
  Future<void> _playGame(Map<String, dynamic> game) async {
    String finalRomUrl = "";
    if (game['isCustom'] == true) {
      finalRomUrl = await WebDbHelper.getRomUrl(game['id']);
    } else {
      finalRomUrl = game['romUrl'] ?? "";
    }

    if (finalRomUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oyun ROM adresi bulunamadı!')),
      );
      return;
    }

    setState(() {
      _activeGame = {
        ...game,
        'resolvedRomUrl': finalRomUrl,
      };
      _currentTab = ActiveTab.emulator;
    });
  }

  // Open Game Details popup dialog
  void _openDetailsDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.purple.withOpacity(0.2)),
          ),
          content: Container(
            width: 600,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Cover Banner
                Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: (game['isCustom'] == true && game['coverUrl'] != null && game['coverUrl'] != "")
                              ? NetworkImage(game['coverUrl'])
                              : (game['coverUrl'] != null && game['coverUrl'] != "")
                                  ? NetworkImage(game['coverUrl'])
                                  : const AssetImage('assets/icon.svg') as ImageProvider,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (game['system'] as String).toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            game['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                // Body details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AÇIKLAMA',
                              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              game['description'] ?? 'Açıklama bulunmuyor.',
                              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Meta side panel
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _metaItem('Platform', (game['system'] as String).toUpperCase()),
                            const SizedBox(height: 12),
                            _metaItem('Yıl', game['year'].toString()),
                            const SizedBox(height: 12),
                            _metaItem('Yayımcı', game['publisher'] ?? 'Bilinmiyor'),
                            const SizedBox(height: 20),
                            // Launch button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 4,
                                shadowColor: Colors.purpleAccent,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _playGame(game);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow),
                                  SizedBox(width: 6),
                                  Text('OYNA'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Delete button (only if custom library game)
                            if (game['isCustom'] == true)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  minimumSize: const Size(double.infinity, 36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Oyunu Sil?'),
                                      content: Text('${game['title']} oyununu kütüphaneden silmek istediğinize emin misiniz?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('İptal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await WebDbHelper.deleteGame(game['id']);
                                    Navigator.of(context).pop(); // Close detail modal
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${game['title']} kütüphaneden silindi.')),
                                    );
                                    _loadLibrary();
                                  }
                                },
                                child: const Text('Kütüphaneden Sil'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // UI Builders
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar Navigation
          _buildSidebar(),
          
          // Divider
          Container(width: 1, color: Colors.purple.withOpacity(0.1)),
          
          // 2. Main Content panel
          Expanded(
            child: Column(
              children: [
                // Top Header (Hide when playing emulator)
                if (_currentTab != ActiveTab.emulator) _buildTopHeader(),
                
                // Content Tab Views
                Expanded(
                  child: Container(
                    padding: _currentTab == ActiveTab.emulator 
                        ? EdgeInsets.zero 
                        : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    child: _buildActiveTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Logo
          Row(
            children: [
              Image.network(
                'assets/icon.svg',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.gamepad, color: Colors.purpleAccent, size: 32);
                },
              ),
              const SizedBox(width: 12),
              const Text(
                'Ro-Retro',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Nav Items
          _buildNavItem(ActiveTab.discover, Icons.explore, 'Keşfet'),
          const SizedBox(height: 6),
          _buildNavItem(ActiveTab.library, Icons.library_books, 'Kütüphanem'),
          const SizedBox(height: 6),
          _buildNavItem(ActiveTab.settings, Icons.settings, 'Ayarlar'),
          
          const Spacer(),
          // Info Stamps
          Text(
            'Ro-Retro v1.0.0',
            style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.6)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ro-ASD OS Edition',
            style: TextStyle(fontSize: 12, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(ActiveTab tab, IconData icon, String label) {
    final isActive = _currentTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = tab;
          _libraryFilter = "all"; // Reset filters
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.purple.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? const Border(left: BorderSide(color: Colors.purpleAccent, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.purpleAccent : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.purpleAccent : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.purple.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search box
          Container(
            width: 320,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Kütüphanede ara...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Actions Group
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  shadowColor: Colors.purpleAccent.withOpacity(0.4),
                  elevation: 6,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ROM İçe Aktar'),
                onPressed: _triggerRomImport,
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.shade900,
                    radius: 18,
                    child: const Text('O', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Oyuncu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentTab) {
      case ActiveTab.discover:
        return _buildDiscoverTab();
      case ActiveTab.library:
        return _buildLibraryTab();
      case ActiveTab.settings:
        return _buildSettingsTab();
      case ActiveTab.emulator:
        return _buildEmulatorTab();
    }
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Banner
          _buildHeroBanner(),
          const SizedBox(height: 32),
          // Popular Games
          const Text(
            'Popüler Retro Klasikler',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 0.72,
            ),
            itemCount: _displayGames.length,
            itemBuilder: (context, idx) {
              final game = _displayGames[idx];
              return _buildGameCard(game);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final featured = _preloadGames[0];
    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        image: DecorationImage(
          image: featured['coverUrl'] != "" 
              ? NetworkImage(featured['coverUrl']) 
              : const AssetImage('assets/icon.svg') as ImageProvider,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.dstATop),
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
            ),
            child: const Text(
              'GÜNÜN RETRO KLASİĞİ',
              style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            featured['title'],
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 480,
            child: Text(
              featured['description'],
              style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 6,
                  shadowColor: Colors.purpleAccent,
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Şimdi Oyna'),
                onPressed: () => _playGame(featured),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _addPreloadToLibrary(featured),
                child: const Text('Kütüphaneye Ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab header filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Oyun Kütüphanem',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold),
            ),
            // Filter pill tabs
            Row(
              children: [
                _filterPill('all', 'Tümü'),
                _filterPill('nes', 'NES'),
                _filterPill('snes', 'SNES'),
                _filterPill('genesis', 'Genesis'),
                _filterPill('gba', 'GBA'),
                _filterPill('gb', 'GB'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Empty State / Grid
        Expanded(
          child: _displayGames.isEmpty
              ? _buildLibraryEmptyState()
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _displayGames.length,
                  itemBuilder: (context, idx) {
                    final game = _displayGames[idx];
                    return _buildGameCard(game);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterPill(String filter, String label) {
    final isSelected = _libraryFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: Colors.purple,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.transparent : Colors.purple.withOpacity(0.15)),
        ),
        onSelected: (selected) {
          setState(() {
            _libraryFilter = filter;
          });
        },
      ),
    );
  }

  Widget _buildLibraryEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gamepad_outlined, color: Colors.grey.withOpacity(0.3), size: 80),
          const SizedBox(height: 20),
          const Text(
            'Kütüphanenizde henüz oyun yok',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 380,
            child: Text(
              'Klasik oyunları oynamak için sağ üstteki "ROM İçe Aktar" butonuyla kendi oyun dosyalarınızı kütüphanenize ekleyebilirsiniz.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            icon: const Icon(Icons.add),
            label: const Text('İlk ROM\'unu Ekle'),
            onPressed: _triggerRomImport,
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return InkWell(
      onTap: () => _openDetailsDialog(game),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.02),
                  child: (game['coverUrl'] != null && game['coverUrl'] != "")
                      ? Image.network(
                          game['coverUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.gamepad, color: Colors.purpleAccent, size: 40),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(Icons.gamepad, color: Colors.purpleAccent, size: 40),
                        ),
                ),
              ),
            ),
            // Text Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (game['system'] as String).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game['title'],
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uygulama Ayarları',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Theme settings
          _buildSettingsCard(
            title: 'Görsel Tema',
            description: 'Ro-Retro arayüzünün renk paletini seçin.',
            child: Row(
              children: [
                _themeOption('purple', 'Derin Mor (Varsayılan)', Colors.purple),
                const SizedBox(width: 16),
                _themeOption('blue', 'Neon Mavi', Colors.lightBlue),
                const SizedBox(width: 16),
                _themeOption('crimson', 'Kızıl Gölge', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Controls Map settings
          _buildSettingsCard(
            title: 'Denetleyici Tuş Kombinasyonları',
            description: 'Oyun içindeki klavye eşleşmeleri şu şekildedir:',
            child: Table(
              border: TableBorder.all(color: Colors.purple.withOpacity(0.08), width: 1, borderRadius: BorderRadius.circular(8)),
              children: const [
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Retro Düğme', style: TextStyle(fontWeight: FontWeight.bold)))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Klavye Eşleşmesi', style: TextStyle(fontWeight: FontWeight.bold)))),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Yön Tuşları (D-Pad)'))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Yukarı / Aşağı / Sol / Sağ Yön Tuşları'))),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('A Butonu'))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('X Tuşu'))),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('B Butonu'))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Z Tuşu'))),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('START (Başlat)'))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Enter Tuşu'))),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('SELECT (Seç)'))),
                    TableCell(child: Padding(padding: EdgeInsets.all(12), child: Text('Shift Tuşu'))),
                  ]
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Storage management
          _buildSettingsCard(
            title: 'Depolama ve Veri Yönetimi',
            description: 'Uygulama ROM dosyalarını IndexedDB üzerinde yerel olarak tutmaktadır.',
            child: Row(
              children: [
                const Text('Veritabanı Durumu: '),
                const Text('Aktif (Yerel)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Verileri Sıfırla?'),
                        content: const Text('UYARI: Kütüphanenizdeki tüm ROM dosyaları ve save verileri kalıcı olarak silinecektir. Emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Evet, Sıfırla', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await WebDbHelper.clearAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veritabanı sıfırlandı.')),
                      );
                      _loadLibrary();
                    }
                  },
                  child: const Text('Tüm Verileri Sıfırla'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(String theme, String label, Color color) {
    final isSelected = widget.activeTheme == theme;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.purpleAccent : Colors.grey,
        side: BorderSide(color: isSelected ? Colors.purpleAccent : Colors.purple.withOpacity(0.08)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isSelected ? Colors.purple.withOpacity(0.05) : Colors.transparent,
      ),
      onPressed: () => widget.onThemeChanged(theme),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 8),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required String title, required String description, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmulatorTab() {
    if (_activeGame == null) {
      return const Center(child: Text('Aktif oynatılan oyun bulunmuyor.'));
    }

    String core = "nes";
    String sys = _activeGame!['system'];
    if (sys == "snes") core = "snes";
    else if (sys == "gba") core = "gba";
    else if (sys == "gb") core = "gb";
    else if (sys == "genesis") core = "segaMD";
    else if (sys == "arcade") core = "fbneo";

    return Column(
      children: [
        // Emulator Top bar controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Oyunu Kapat ve Kütüphaneye Dön'),
                onPressed: () {
                  setState(() {
                    _activeGame = null;
                    _currentTab = ActiveTab.library;
                  });
                },
              ),
              Row(
                children: [
                  Text(
                    _activeGame!['title'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (sys).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Frame Container
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black,
              child: createEmulatorView(
                romUrl: _activeGame!['resolvedRomUrl'] ?? "",
                core: core,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

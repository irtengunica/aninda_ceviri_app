// main.dart

import 'dart:convert';
import 'dart:io'; // Hata kontrolü için eklendi
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Panoya kopyalama için eklendi
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- MODELLER ---
class Language {
  final String name;
  final String translateCode;
  final String speechCode;

  Language(this.name, this.translateCode, this.speechCode);

  @override
  bool operator ==(Object other) =>
      other is Language && other.translateCode == translateCode;

  @override
  int get hashCode => translateCode.hashCode;
}

class TranslationHistoryItem {
  final String sourceText;
  final String translatedText;
  final String sourceLangCode;
  final String targetLangCode;

  TranslationHistoryItem({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLangCode,
    required this.targetLangCode,
  });

  Map<String, dynamic> toJson() => {
    'sourceText': sourceText,
    'translatedText': translatedText,
    'sourceLangCode': sourceLangCode,
    'targetLangCode': targetLangCode,
  };

  factory TranslationHistoryItem.fromJson(Map<String, dynamic> json) =>
      TranslationHistoryItem(
        sourceText: json['sourceText'],
        translatedText: json['translatedText'],
        sourceLangCode: json['sourceLangCode'],
        targetLangCode: json['targetLangCode'],
      );
}

// --- UYGULAMA BAŞLANGICI ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anında Çeviri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TranslationScreen(),
    );
  }
}

// --- ANA EKRAN ---
class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  // Paketlerin ve Controller'ların Nesneleri
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();
  final TextEditingController _sourceTextController = TextEditingController();

  // Durum Değişkenleri
  String _translatedText = "";
  bool _isListening = false;
  bool _isTranslating = false; // YENİ: Yükleme animasyonu için
  List<TranslationHistoryItem> _history = [];

  final List<Language> languages = [
    Language("Türkçe", "tr", "tr-TR"),
    Language("English", "en", "en-US"),
    Language("Deutsch", "de", "de-DE"),
    Language("Español", "es", "es-ES"),
    Language("Français", "fr", "fr-FR"),
    Language("Italiano", "it", "it-IT"),
    Language("Русский", "ru", "ru-RU"),
  ];

  late Language _selectedSourceLanguage;
  late Language _selectedTargetLanguage;

  @override
  void initState() {
    super.initState();
    _selectedSourceLanguage = languages[0];
    _selectedTargetLanguage = languages[1];
    _initSpeech();
    _loadHistory();
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    super.dispose();
  }

  // --- ANA FONKSİYONLAR ---

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (!_isListening) {
      // Başlamadan önce temizlik
      _sourceTextController.clear();
      setState(() {
        _translatedText = "";
        _isListening = true;
      });

      bool available = await _speechToText.initialize();
      if (available) {
        _speechToText.listen(
          localeId: _selectedSourceLanguage.speechCode,
          onResult: (result) {
            setState(() {
              _sourceTextController.text = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
              _translateAndSpeak();
            }
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _translateAndSpeak() async {
    final textToTranslate = _sourceTextController.text;
    if (textToTranslate.isEmpty) return;

    FocusScope.of(context).unfocus(); // Klavyeyi kapat
    setState(() {
      _isTranslating = true;
      _isListening = false;
      _translatedText = ""; // Önceki çeviriyi temizle
    });

    try {
      var translation = await _translator.translate(
        textToTranslate,
        from: _selectedSourceLanguage.translateCode,
        to: _selectedTargetLanguage.translateCode,
      );

      final translatedTextValue = translation.text;
      _saveToHistory(textToTranslate, translatedTextValue);

      setState(() {
        _translatedText = translatedTextValue;
      });

      if (_translatedText.isNotEmpty) {
        _speak(_translatedText, _selectedTargetLanguage.speechCode);
      }
    } on SocketException catch (_) {
      _showErrorDialog(
        "İnternet Bağlantı Hatası",
        "Lütfen internet bağlantınızı kontrol edip tekrar deneyin.",
      );
    } catch (e) {
      _showErrorDialog("Çeviri Hatası", "Bir hata oluştu: ${e.toString()}");
    } finally {
      setState(() => _isTranslating = false);
    }
  }

  // --- YARDIMCI FONKSİYONLAR ---

  void _speak(String text, String langCode) async {
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Çeviri panoya kopyalandı!")));
  }

  void _showErrorDialog(String title, String content) {
    setState(() {
      _translatedText = ""; // Hata durumunda çeviri alanını temizle
    });
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Tamam"),
              ),
            ],
          ),
    );
  }

  // --- GEÇMİŞ YÖNETİMİ ---

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('translation_history');
    if (historyString != null) {
      final List<dynamic> historyJson = jsonDecode(historyString);
      setState(() {
        _history =
            historyJson
                .map((item) => TranslationHistoryItem.fromJson(item))
                .toList();
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyString = jsonEncode(
      _history.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('translation_history', historyString);
  }

  void _saveToHistory(String sourceText, String translatedText) {
    final historyItem = TranslationHistoryItem(
      sourceText: sourceText,
      translatedText: translatedText,
      sourceLangCode: _selectedSourceLanguage.translateCode,
      targetLangCode: _selectedTargetLanguage.translateCode,
    );
    setState(() {
      _history.removeWhere((item) => item.sourceText == sourceText);
      _history.insert(0, historyItem);
      if (_history.length > 20) _history.removeLast();
    });
    _saveHistory();
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (_history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Henüz çeviri geçmişiniz yok.",
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Çeviri Geçmişi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return ListTile(
                    title: Text(
                      item.sourceText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.translatedText,
                      style: const TextStyle(
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sourceTextController.text = item.sourceText;
                      setState(() {
                        _translatedText = item.translatedText;
                        _selectedSourceLanguage = languages.firstWhere(
                          (lang) => lang.translateCode == item.sourceLangCode,
                        );
                        _selectedTargetLanguage = languages.firstWhere(
                          (lang) => lang.translateCode == item.targetLangCode,
                        );
                      });
                      _speak(item.translatedText, item.targetLangCode);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- ARAYÜZ (BUILD METODU) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anında Sesli Çeviri'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Çeviri Geçmişi',
            onPressed: _showHistorySheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dil Seçimi
              _buildLanguageSelector(),
              const SizedBox(height: 20),
              // Kaynak Metin Alanı
              _buildSourceCard(),
              const SizedBox(height: 20),
              // Hedef Metin Alanı
              _buildTranslationCard(),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed:
            _isTranslating
                ? null
                : (_isListening ? _stopListening : _startListening),
        backgroundColor:
            _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child:
            _isListening
                ? const Icon(Icons.mic_off, size: 36)
                : const Icon(Icons.mic, size: 36),
      ),
    );
  }

  // --- ARAYÜZ (YARDIMCI WIDGET'LAR) ---

  Card _buildLanguageSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildLanguageDropdown(true)),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.blue, size: 30),
              onPressed: () {
                setState(() {
                  final tempLang = _selectedSourceLanguage;
                  _selectedSourceLanguage = _selectedTargetLanguage;
                  _selectedTargetLanguage = tempLang;
                  // Metinleri de takas et (isteğe bağlı)
                  final tempText = _sourceTextController.text;
                  _sourceTextController.text = _translatedText;
                  _translatedText = tempText;
                });
              },
            ),
            Expanded(child: _buildLanguageDropdown(false)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(bool isSource) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Language>(
        value: isSource ? _selectedSourceLanguage : _selectedTargetLanguage,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: (Language? newValue) {
          if (newValue != null) {
            setState(() {
              if (isSource) {
                if (newValue != _selectedTargetLanguage)
                  _selectedSourceLanguage = newValue;
              } else {
                if (newValue != _selectedSourceLanguage)
                  _selectedTargetLanguage = newValue;
              }
            });
          }
        },
        items:
            languages.map<DropdownMenuItem<Language>>((Language language) {
              return DropdownMenuItem<Language>(
                value: language,
                child: Center(
                  child: Text(language.name, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
      ),
    );
  }

  Card _buildSourceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Söylediğiniz / Yazdığınız (${_selectedSourceLanguage.translateCode.toUpperCase()}):",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            TextField(
              controller: _sourceTextController,
              maxLines: null,
              onSubmitted: (_) => _translateAndSpeak(),
              decoration: InputDecoration(
                hintText: "Çevirmek için yazın veya konuşun...",
                border: InputBorder.none,
                suffixIcon: IconButton(
                  tooltip: "Metni Temizle",
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _sourceTextController.clear(),
                ),
              ),
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Card _buildTranslationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Çeviri (${_selectedTargetLanguage.translateCode.toUpperCase()}):",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: "Tekrar Dinle",
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        color: Colors.grey,
                      ),
                      onPressed:
                          () => _speak(
                            _translatedText,
                            _selectedTargetLanguage.speechCode,
                          ),
                    ),
                    IconButton(
                      tooltip: "Panoya Kopyala",
                      icon: const Icon(Icons.copy_outlined, color: Colors.grey),
                      onPressed: () => _copyToClipboard(_translatedText),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Yükleme animasyonu veya çeviri metni
            _isTranslating
                ? const Center(child: CircularProgressIndicator())
                : Text(
                  _translatedText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranReciter {
  const QuranReciter({
    required this.id,
    required this.name,
    required this.shortName,
    required this.verseFolder,
    this.surahFolder,
  });

  final String id;
  final String name;
  final String shortName;
  final String verseFolder;
  final String? surahFolder;

  bool get supportsSurahDownload => surahFolder != null;
}

class DownloadedSurahAudio {
  const DownloadedSurahAudio({
    required this.surah,
    required this.reciter,
    required this.file,
    required this.bytes,
    required this.updatedAt,
  });

  final int surah;
  final QuranReciter reciter;
  final File file;
  final int bytes;
  final DateTime updatedAt;
}

class QuranAudioStorage {
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const String _selectedReciterKey = 'quran_audio_selected_reciter';
  static const String _surahBaseUrl = 'https://download.quranicaudio.com/quran';
  static const String _verseBaseUrl = 'https://everyayah.com/data';

  static const List<QuranReciter> availableReciters = [
    QuranReciter(
      id: 'alafasy',
      name: 'مشاري راشد العفاسي',
      shortName: 'العفاسي',
      verseFolder: 'Alafasy_128kbps',
      surahFolder: 'mishaari_raashid_al_3afaasee',
    ),
    QuranReciter(
      id: 'minshawi',
      name: 'محمد صديق المنشاوي',
      shortName: 'المنشاوي',
      verseFolder: 'Minshawy_Murattal_128kbps',
      surahFolder: 'muhammad_siddeeq_al-minshaawee',
    ),
    QuranReciter(
      id: 'husary',
      name: 'محمود خليل الحصري',
      shortName: 'الحصري',
      verseFolder: 'Husary_128kbps',
      surahFolder: 'mahmood_khaleel_al-husaree',
    ),
    QuranReciter(
      id: 'abdulbasit',
      name: 'عبد الباسط عبد الصمد',
      shortName: 'عبد الباسط',
      verseFolder: 'Abdul_Basit_Murattal_192kbps',
      surahFolder: 'abdul_basit_murattal',
    ),
    QuranReciter(
      id: 'hudhaify',
      name: 'علي الحذيفي',
      shortName: 'الحذيفي',
      verseFolder: 'Hudhaify_128kbps',
      surahFolder: 'huthayfi',
    ),
    QuranReciter(
      id: 'ayyoub',
      name: 'محمد أيوب',
      shortName: 'محمد أيوب',
      verseFolder: 'Muhammad_Ayyoub_128kbps',
      surahFolder: 'muhammad_ayyoob',
    ),
  ];

  static QuranReciter get defaultReciter => availableReciters.first;

  static QuranReciter reciterById(String? id) {
    return maybeReciterById(id) ?? defaultReciter;
  }

  static QuranReciter? maybeReciterById(String? id) {
    if (id == null) {
      return null;
    }

    for (final reciter in availableReciters) {
      if (reciter.id == id) {
        return reciter;
      }
    }
    return null;
  }

  static Future<QuranReciter> loadSelectedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    return reciterById(prefs.getString(_selectedReciterKey));
  }

  static Future<void> saveSelectedReciter(QuranReciter reciter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterKey, reciter.id);
  }

  static String surahAudioUrl(int surah, {QuranReciter? reciter}) {
    final selectedReciter = reciter ?? defaultReciter;
    final folder = selectedReciter.surahFolder;
    if (folder == null) {
      throw UnsupportedError(
        'Whole-surah audio is unavailable for ${selectedReciter.id}.',
      );
    }

    final paddedSurah = surah.toString().padLeft(3, '0');
    return '$_surahBaseUrl/$folder/$paddedSurah.mp3';
  }

  static String verseAudioUrl(
    int surah,
    int ayah, {
    QuranReciter? reciter,
  }) {
    final selectedReciter = reciter ?? defaultReciter;
    final paddedSurah = surah.toString().padLeft(3, '0');
    final paddedAyah = ayah.toString().padLeft(3, '0');
    return '$_verseBaseUrl/${selectedReciter.verseFolder}/$paddedSurah$paddedAyah.mp3';
  }

  static Future<File> surahFile(int surah, {QuranReciter? reciter}) async {
    final selectedReciter = reciter ?? defaultReciter;
    final directory = await _audioDirectory();
    final paddedSurah = surah.toString().padLeft(3, '0');
    return File('${directory.path}/${selectedReciter.id}_$paddedSurah.mp3');
  }

  static Future<bool> isSurahDownloaded(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final file = await surahFile(surah, reciter: reciter);
    if (!await file.exists()) {
      return false;
    }

    return await file.length() > 0;
  }

  static Future<List<DownloadedSurahAudio>> downloadedSurahs() async {
    final directory = await _audioDirectory();
    if (!await directory.exists()) {
      return const [];
    }

    final downloads = <DownloadedSurahAudio>[];
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final match = RegExp(
        r'^([a-z0-9_]+)_(\d{3})\.mp3$',
      ).firstMatch(entity.uri.pathSegments.last);
      if (match == null) {
        continue;
      }

      final reciter = maybeReciterById(match.group(1)!);
      if (reciter == null) {
        continue;
      }

      final surah = int.tryParse(match.group(2)!);
      if (surah == null || surah < 1 || surah > 114) {
        continue;
      }

      final bytes = await entity.length();
      if (bytes <= 0) {
        continue;
      }

      final stat = await entity.stat();
      downloads.add(
        DownloadedSurahAudio(
          surah: surah,
          reciter: reciter,
          file: entity,
          bytes: bytes,
          updatedAt: stat.modified,
        ),
      );
    }

    downloads.sort((first, second) {
      final reciterCompare = first.reciter.name.compareTo(second.reciter.name);
      if (reciterCompare != 0) {
        return reciterCompare;
      }
      return first.surah.compareTo(second.surah);
    });
    return downloads;
  }

  static Future<void> deleteSurah(int surah, {QuranReciter? reciter}) async {
    final file = await surahFile(surah, reciter: reciter);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<Uri> playableSurahUri(
    int surah, {
    QuranReciter? reciter,
  }) async {
    final selectedReciter = reciter ?? defaultReciter;
    final file = await surahFile(surah, reciter: selectedReciter);
    if (await file.exists() && await file.length() > 0) {
      return file.uri;
    }

    return Uri.parse(surahAudioUrl(surah, reciter: selectedReciter));
  }

  static Future<void> downloadSurah(
    int surah, {
    QuranReciter? reciter,
    void Function(double progress)? onProgress,
  }) async {
    final selectedReciter = reciter ?? defaultReciter;
    if (!selectedReciter.supportsSurahDownload) {
      throw UnsupportedError(
        'Whole-surah download is unavailable for ${selectedReciter.id}.',
      );
    }

    final target = await surahFile(surah, reciter: selectedReciter);
    await target.parent.create(recursive: true);

    final tempFile = File('${target.path}.part');
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = http.Client();
    IOSink? sink;
    try {
      final downloadUri = Uri.parse(
        surahAudioUrl(surah, reciter: selectedReciter),
      );
      final request = http.Request('GET', downloadUri);
      final response = await client.send(request).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw HttpException(
          'Quran audio download failed: ${response.statusCode}',
          uri: downloadUri,
        );
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;
      sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress?.call(downloadedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      onProgress?.call(1);
    } catch (_) {
      await sink?.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  static bool isConnectionError(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }

  static Future<Directory> _audioDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return Directory('${supportDirectory.path}/quran_audio');
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_audio_storage.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';

class DownloadedAudioScreen extends StatefulWidget {
  const DownloadedAudioScreen({super.key});

  @override
  State<DownloadedAudioScreen> createState() => _DownloadedAudioScreenState();
}

class _DownloadedAudioScreenState extends State<DownloadedAudioScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  List<DownloadedSurahAudio> _downloads = const [];
  String? _playingAudioKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingAudioKey = null);
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final downloads = await QuranAudioStorage.downloadedSurahs();
    if (!mounted) return;
    setState(() {
      _downloads = downloads;
      _isLoading = false;
    });
  }

  Future<void> _play(DownloadedSurahAudio audio) async {
    final key = _audioKey(audio);
    if (_playingAudioKey == key && _audioPlayer.playing) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _playingAudioKey = null);
      return;
    }

    await _audioPlayer.setFilePath(audio.file.path);
    await _audioPlayer.play();
    if (!mounted) return;
    setState(() => _playingAudioKey = key);
  }

  Future<void> _delete(DownloadedSurahAudio audio) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الصوت؟'),
          content: Text(
            'سيتم حذف صوت سورة ${quran.getSurahNameArabic(audio.surah)} بصوت ${audio.reciter.shortName} من الجهاز.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (_playingAudioKey == _audioKey(audio)) {
      await _audioPlayer.stop();
      _playingAudioKey = null;
    }
    await QuranAudioStorage.deleteSurah(audio.surah, reciter: audio.reciter);
    await _loadDownloads();
  }

  String _audioKey(DownloadedSurahAudio audio) {
    return '${audio.reciter.id}:${audio.surah}';
  }

  void _openReader(int surah) {
    openQuranReader(context, surahNumber: surah);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'الصوتيات المحملة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _loadDownloads,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _downloads.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadDownloads,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _downloads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildAudioCard(_downloads[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_for_offline_outlined,
                color: AppTheme.primaryColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد صوتيات محملة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'افتح أي سورة واضغط زر التحميل بجانب المشغل، وستظهر هنا للاستماع إليها دون إنترنت.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard(DownloadedSurahAudio audio) {
    final isPlaying = _playingAudioKey == _audioKey(audio) &&
        _audioPlayer.playing;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.softBorderColor(context)),
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: () => _play(audio),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _openReader(audio.surah),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quran.getSurahNameArabic(audio.surah),
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${audio.reciter.shortName} • ${_formatSize(audio.bytes)} • ${DateFormat('yyyy/MM/dd').format(audio.updatedAt)}',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 12,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open') {
                _openReader(audio.surah);
              } else if (value == 'delete') {
                _delete(audio);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'open', child: Text('فتح السورة')),
              PopupMenuItem(value: 'delete', child: Text('حذف الصوت')),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    if (megabytes >= 1) {
      return '${megabytes.toStringAsFixed(1)} MB';
    }
    final kilobytes = bytes / 1024;
    return '${kilobytes.toStringAsFixed(0)} KB';
  }
}

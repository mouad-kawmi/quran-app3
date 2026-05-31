import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_audio_storage.dart';
import 'package:quran_app/core/theme.dart';

class QuranAudioController extends ChangeNotifier {
  int? requestSurah;
  int? requestVerse;
  int? currentPlayingSurah;
  int? currentPlayingVerse;

  void playVerseRequest(int surah, int ayah) {
    requestSurah = surah;
    requestVerse = ayah;
    notifyListeners();
  }

  void consumeRequest() {
    requestSurah = null;
    requestVerse = null;
  }

  void updateHighlight(int surah, int ayah) {
    currentPlayingSurah = surah;
    currentPlayingVerse = ayah;
    notifyListeners();
  }

  void clearHighlight() {
    currentPlayingSurah = null;
    currentPlayingVerse = null;
    notifyListeners();
  }
}

class QuranAudioPlayer extends StatefulWidget {
  const QuranAudioPlayer({
    super.key,
    required this.surahNumber,
    this.controller,
  });

  final int surahNumber;
  final QuranAudioController? controller;

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isSurahMode = true;
  int? _currentVerse;
  int _playlistSurah = 1;
  List<int> _playlistVerses = const [];
  double _downloadProgress = 0;
  QuranReciter _selectedReciter = QuranAudioStorage.defaultReciter;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _playlistSurah = widget.surahNumber;
    _currentVerse = 1;
    _audioPlayer = AudioPlayer();
    widget.controller?.addListener(_onControllerChanged);
    _setupListeners();
    unawaited(_loadReciterAndDownloadState());
  }

  @override
  void didUpdateWidget(covariant QuranAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _playlistSurah = widget.surahNumber;
      _currentVerse = 1;
      _playlistVerses = const [];
      widget.controller?.clearHighlight();
      _audioPlayer.stop();
      unawaited(_loadDownloadState());
    }
  }

  Future<void> _loadReciterAndDownloadState() async {
    final reciter = await QuranAudioStorage.loadSelectedReciter();
    if (!mounted) return;
    setState(() => _selectedReciter = reciter);
    await _loadDownloadState();
  }

  Future<void> _loadDownloadState() async {
    final reciter = _selectedReciter;
    final downloaded = await QuranAudioStorage.isSurahDownloaded(
      widget.surahNumber,
      reciter: reciter,
    );
    if (!mounted || _selectedReciter.id != reciter.id) return;
    setState(() {
      _isDownloaded = downloaded;
      _downloadProgress = downloaded ? 1 : 0;
    });
  }

  Future<void> _selectReciter(QuranReciter reciter) async {
    if (_isDownloading || reciter.id == _selectedReciter.id) {
      return;
    }

    await QuranAudioStorage.saveSelectedReciter(reciter);
    await _audioPlayer.stop();
    widget.controller?.clearHighlight();
    if (!mounted) return;

    setState(() {
      _selectedReciter = reciter;
      _isPlaying = false;
      _isLoading = false;
      _isDownloaded = false;
      _downloadProgress = 0;
      _playlistVerses = const [];
      _currentVerse = 1;
      _errorMessage = null;
    });
    await _loadDownloadState();
  }

  void _setupListeners() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state.playing;
        if (state.processingState != ProcessingState.loading &&
            state.processingState != ProcessingState.buffering) {
          _isLoading = false;
        }
      });

      if (state.processingState == ProcessingState.completed) {
        widget.controller?.clearHighlight();
      }
    });

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _playlistVerses.length) {
        return;
      }

      final verse = _playlistVerses[index];
      widget.controller?.updateHighlight(_playlistSurah, verse);
      if (mounted) {
        setState(() => _currentVerse = verse);
      }
    });
  }

  void _onControllerChanged() {
    final requestedSurah = widget.controller?.requestSurah;
    final requestedVerse = widget.controller?.requestVerse;
    if (requestedSurah == null || requestedVerse == null) {
      return;
    }

    widget.controller?.consumeRequest();
    _startPlayback(
      surah: requestedSurah,
      startVerse: requestedVerse,
      surahMode: false,
    );
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    if (_audioPlayer.audioSource == null || _playlistVerses.isEmpty) {
      await _startPlayback(
        surah: widget.surahNumber,
        startVerse: 1,
        surahMode: true,
      );
      return;
    }

    if (_audioPlayer.processingState == ProcessingState.completed) {
      await _audioPlayer.seek(Duration.zero, index: 0);
    }

    await _audioPlayer.play();
  }

  Future<void> _playWholeSurah() async {
    await _startPlayback(
      surah: widget.surahNumber,
      startVerse: 1,
      surahMode: true,
    );
  }

  Future<void> _startPlayback({
    required int surah,
    required int startVerse,
    required bool surahMode,
  }) async {
    final totalVerses = quran.getVerseCount(surah);
    if (startVerse < 1 || startVerse > totalVerses) {
      return;
    }

    final verses = [
      for (var verse = startVerse; verse <= totalVerses; verse++) verse,
    ];
    final sources = [
      for (final verse in verses)
        AudioSource.uri(Uri.parse(_verseAudioUrl(surah, verse)), tag: verse),
    ];

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isSurahMode = surahMode;
        _playlistSurah = surah;
        _playlistVerses = verses;
        _currentVerse = startVerse;
      });
    }

    widget.controller?.updateHighlight(surah, startVerse);

    try {
      await _audioPlayer.setAudioSources(sources, preload: true);
      await _audioPlayer.play();
    } catch (error) {
      widget.controller?.clearHighlight();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
        _errorMessage = _audioErrorMessage(error);
      });
    }
  }

  Future<void> _downloadSurah() async {
    if (_isDownloading || _isDownloaded) {
      return;
    }

    if (!_selectedReciter.supportsSurahDownload) {
      setState(() {
        _errorMessage =
            'التحميل غير متاح لهذا القارئ حاليا. يمكنك الاستماع بالاتصال بالإنترنت.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _errorMessage = null;
    });

    try {
      await QuranAudioStorage.downloadSurah(
        widget.surahNumber,
        reciter: _selectedReciter,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _downloadProgress = progress.clamp(0, 1));
        },
      );
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
        _downloadProgress = 1;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = false;
        _downloadProgress = 0;
        _errorMessage = _audioErrorMessage(error);
      });
    }
  }

  String _verseAudioUrl(int surah, int ayah) {
    return QuranAudioStorage.verseAudioUrl(
      surah,
      ayah,
      reciter: _selectedReciter,
    );
  }

  String _audioErrorMessage(Object error) {
    if (QuranAudioStorage.isConnectionError(error)) {
      return 'يلزم الاتصال بالإنترنت لتشغيل الصوت أول مرة. حمّل السورة للاستماع إليها دون إنترنت.';
    }

    return 'الصوت يحتاج اتصالا بالإنترنت. إذا كان الاتصال متاحا ولم يعمل، حاول مرة أخرى.';
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.25 : 0.08,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              tooltip: _isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
              icon: Icon(
                _isLoading
                    ? Icons.hourglass_top_rounded
                    : _isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 44,
                color: AppTheme.primaryColor,
              ),
              onPressed: _togglePlayback,
            ),
            IconButton(
              tooltip: _isDownloaded
                  ? 'السورة محملة'
                  : _isDownloading
                  ? 'يتم تحميل السورة'
                  : 'تحميل السورة',
              disabledColor: _isDownloaded
                  ? AppTheme.primaryColor
                  : Colors.grey[400],
              icon: _isDownloading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: _downloadProgress == 0
                            ? null
                            : _downloadProgress,
                        strokeWidth: 2.5,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : Icon(
                      _isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_for_offline_outlined,
                      color: _isDownloaded ? AppTheme.primaryColor : null,
                    ),
              onPressed: _isDownloading || _isDownloaded
                  ? null
                  : _downloadSurah,
            ),
            PopupMenuButton<String>(
              tooltip: 'اختيار القارئ',
              enabled: !_isDownloading,
              icon: const Icon(
                Icons.record_voice_over_rounded,
                color: AppTheme.primaryColor,
              ),
              onSelected: (id) {
                final reciter = QuranAudioStorage.reciterById(id);
                unawaited(_selectReciter(reciter));
              },
              itemBuilder: (context) => [
                for (final reciter in QuranAudioStorage.availableReciters)
                  PopupMenuItem<String>(
                    value: reciter.id,
                    child: Row(
                      children: [
                        Icon(
                          reciter.id == _selectedReciter.id
                              ? Icons.check_rounded
                              : Icons.mic_none_rounded,
                          size: 20,
                          color: reciter.id == _selectedReciter.id
                              ? AppTheme.primaryColor
                              : AppTheme.mutedTextColor(context),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          reciter.name,
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleText,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _subtitleColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!_isSurahMode)
              TextButton(
                onPressed: _isLoading ? null : _playWholeSurah,
                child: const Text('السورة', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  String get _titleText {
    if (_isLoading) {
      return 'يتم تحميل الصوت...';
    }

    if (_isSurahMode) {
      return 'السورة كاملة';
    }

    return 'من الآية ${_currentVerse ?? 1}';
  }

  String get _subtitleText {
    if (_errorMessage != null) {
      return _errorMessage!;
    }

    if (!_isDownloading && !_isDownloaded) {
      if (_selectedReciter.supportsSurahDownload) {
        return '${_selectedReciter.shortName} • يمكن تحميل السورة للاستماع دون إنترنت';
      }
      return '${_selectedReciter.shortName} • يحتاج اتصالا بالإنترنت للتشغيل';
    }

    if (_isDownloading) {
      final percent = (_downloadProgress * 100).round().clamp(0, 100);
      return 'يتم تحميل السورة... $percent%';
    }

    if (_isDownloaded) {
      return 'السورة محملة وتعمل دون إنترنت';
    }

    return 'مشاري راشد العفاسي • يحتاج اتصالا، ويمكن تحميل السورة للاستماع دون إنترنت';
  }

  Color? get _subtitleColor {
    if (_errorMessage != null) {
      return Colors.red[700];
    }

    if (_isDownloaded || _isDownloading) {
      return AppTheme.primaryColor;
    }

    return Colors.grey[600];
  }
}

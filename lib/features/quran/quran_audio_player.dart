import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_audio_storage.dart';
import 'package:quran_app/core/theme.dart';

class QuranAudioController extends ChangeNotifier {
  QuranAudioController() {
    _setupListeners();
    unawaited(_loadReciterAndDownloadState());
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  bool _isDisposed = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isSurahMode = true;
  bool _isWholeSurahSource = false;
  bool _hasPlayableSource = false;
  int _controlSurah = 1;
  int? _controlInitialAyah;
  int? _currentVerse = 1;
  int _playlistSurah = 1;
  List<int> _playlistVerses = const [];
  double _downloadProgress = 0;
  QuranReciter _selectedReciter = QuranAudioStorage.defaultReciter;
  String? _errorMessage;

  int? requestSurah;
  int? requestVerse;
  int? currentPlayingSurah;
  int? currentPlayingVerse;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  bool get isDownloaded => _isDownloaded;
  bool get isSurahMode => _isSurahMode;
  int? get currentVerse => _currentVerse;
  double get downloadProgress => _downloadProgress;
  QuranReciter get selectedReciter => _selectedReciter;
  String? get errorMessage => _errorMessage;

  void configure({required int surahNumber, int? initialAyah}) {
    final changed =
        _controlSurah != surahNumber || _controlInitialAyah != initialAyah;
    _controlSurah = surahNumber;
    _controlInitialAyah = initialAyah;

    if (!_hasPlayableSource && !_isLoading) {
      _playlistSurah = surahNumber;
      _currentVerse = initialAyah ?? 1;
      _isSurahMode = initialAyah == null;
      _isWholeSurahSource = false;
    }

    if (changed) {
      unawaited(_loadDownloadState());
      _safeNotifyListeners();
    }
  }

  void playVerseRequest(int surah, int ayah) {
    requestSurah = surah;
    requestVerse = ayah;
    configure(surahNumber: surah, initialAyah: ayah);
    unawaited(
      _startPlayback(surah: surah, startVerse: ayah, surahMode: false),
    );
  }

  void consumeRequest() {
    requestSurah = null;
    requestVerse = null;
  }

  void updateHighlight(int surah, int ayah) {
    currentPlayingSurah = surah;
    currentPlayingVerse = ayah;
    _safeNotifyListeners();
  }

  void clearHighlight() {
    currentPlayingSurah = null;
    currentPlayingVerse = null;
    _safeNotifyListeners();
  }

  Future<void> togglePlayback() async {
    if (_isLoading) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    if (!_hasPlayableSource) {
      if (_controlInitialAyah == null) {
        await _startSurahPlayback(_controlSurah);
      } else {
        await _startPlayback(
          surah: _controlSurah,
          startVerse: _controlInitialAyah!,
          surahMode: false,
        );
      }
      return;
    }

    if (_audioPlayer.processingState == ProcessingState.completed) {
      if (_isWholeSurahSource) {
        await _audioPlayer.seek(Duration.zero);
      } else {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }
    }

    await _audioPlayer.play();
  }

  Future<void> playWholeSurah() async {
    await _startSurahPlayback(_controlSurah);
  }

  Future<void> selectReciter(QuranReciter reciter) async {
    if (_isDownloading || reciter.id == _selectedReciter.id) {
      return;
    }

    await QuranAudioStorage.saveSelectedReciter(reciter);
    await _audioPlayer.stop();
    clearHighlight();

    _selectedReciter = reciter;
    _isPlaying = false;
    _isLoading = false;
    _isDownloaded = false;
    _downloadProgress = 0;
    _playlistVerses = const [];
    _currentVerse = _controlInitialAyah ?? 1;
    _isSurahMode = _controlInitialAyah == null;
    _isWholeSurahSource = false;
    _hasPlayableSource = false;
    _errorMessage = null;
    _safeNotifyListeners();
    await _loadDownloadState();
  }

  Future<void> downloadSurah() async {
    if (_isDownloading || _isDownloaded) {
      return;
    }

    if (!_selectedReciter.supportsSurahDownload) {
      _errorMessage =
          'التحميل غير متاح لهذا القارئ حاليا. يمكنك الاستماع بالاتصال بالإنترنت.';
      _safeNotifyListeners();
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await QuranAudioStorage.downloadSurah(
        _controlSurah,
        reciter: _selectedReciter,
        onProgress: (progress) {
          if (_isDisposed) return;
          _downloadProgress = progress.clamp(0, 1);
          _safeNotifyListeners();
        },
      );
      if (_isDisposed) return;
      _isDownloading = false;
      _isDownloaded = true;
      _downloadProgress = 1;
      _errorMessage = null;
      _safeNotifyListeners();
    } catch (error) {
      if (_isDisposed) return;
      _isDownloading = false;
      _isDownloaded = false;
      _downloadProgress = 0;
      _errorMessage = _audioErrorMessage(error);
      _safeNotifyListeners();
    }
  }

  void _setupListeners() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (_isDisposed) return;

      _isPlaying = state.playing;
      if (state.processingState != ProcessingState.loading &&
          state.processingState != ProcessingState.buffering) {
        _isLoading = false;
      }

      if (state.processingState == ProcessingState.completed) {
        clearHighlight();
      } else {
        _safeNotifyListeners();
      }
    });

    _currentIndexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      if (_isDisposed ||
          index == null ||
          index < 0 ||
          index >= _playlistVerses.length) {
        return;
      }

      final verse = _playlistVerses[index];
      _currentVerse = verse;
      updateHighlight(_playlistSurah, verse);
    });
  }

  Future<void> _loadReciterAndDownloadState() async {
    final reciter = await QuranAudioStorage.loadSelectedReciter();
    if (_isDisposed) return;
    _selectedReciter = reciter;
    _safeNotifyListeners();
    await _loadDownloadState();
  }

  Future<void> _loadDownloadState() async {
    final reciter = _selectedReciter;
    final surah = _controlSurah;
    final downloaded = await QuranAudioStorage.isSurahDownloaded(
      surah,
      reciter: reciter,
    );
    if (_isDisposed ||
        _selectedReciter.id != reciter.id ||
        _controlSurah != surah) {
      return;
    }

    _isDownloaded = downloaded;
    _downloadProgress = downloaded ? 1 : 0;
    _safeNotifyListeners();
  }

  Future<void> _startSurahPlayback(int surah) async {
    _isLoading = true;
    _errorMessage = null;
    _isSurahMode = true;
    _isWholeSurahSource = true;
    _hasPlayableSource = false;
    _playlistSurah = surah;
    _playlistVerses = const [];
    _currentVerse = 1;
    _safeNotifyListeners();
    updateHighlight(surah, 1);

    try {
      final uri = await QuranAudioStorage.playableSurahUri(
        surah,
        reciter: _selectedReciter,
      );
      if (_isDisposed) return;
      await _audioPlayer.setAudioSource(AudioSource.uri(uri, tag: 1));
      _hasPlayableSource = true;
      await _audioPlayer.play();
    } catch (error) {
      clearHighlight();
      if (_isDisposed) return;
      _isLoading = false;
      _isPlaying = false;
      _isWholeSurahSource = false;
      _hasPlayableSource = false;
      _errorMessage = _audioErrorMessage(error);
      _safeNotifyListeners();
    }
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

    _isLoading = true;
    _errorMessage = null;
    _isSurahMode = surahMode;
    _isWholeSurahSource = false;
    _hasPlayableSource = false;
    _playlistSurah = surah;
    _playlistVerses = verses;
    _currentVerse = startVerse;
    _safeNotifyListeners();
    updateHighlight(surah, startVerse);

    try {
      await _audioPlayer.setAudioSources(sources, preload: true);
      _hasPlayableSource = true;
      await _audioPlayer.play();
    } catch (error) {
      clearHighlight();
      if (_isDisposed) return;
      _isLoading = false;
      _isPlaying = false;
      _hasPlayableSource = false;
      _errorMessage = _audioErrorMessage(error);
      _safeNotifyListeners();
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

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playerStateSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class QuranAudioPlayer extends StatefulWidget {
  const QuranAudioPlayer({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.controller,
  });

  final int surahNumber;
  final int? initialAyah;
  final QuranAudioController? controller;

  @override
  State<QuranAudioPlayer> createState() => _QuranAudioPlayerState();
}

class _QuranAudioPlayerState extends State<QuranAudioPlayer> {
  QuranAudioController? _ownedController;

  QuranAudioController get _controller =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = QuranAudioController();
    }
    _configureController();
  }

  @override
  void didUpdateWidget(covariant QuranAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    } else if (oldWidget.controller != null && widget.controller == null) {
      _ownedController = QuranAudioController();
    }
    _configureController();
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _configureController() {
    _controller.configure(
      surahNumber: widget.surahNumber,
      initialAyah: widget.initialAyah,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
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
                  tooltip: controller.isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                  icon: Icon(
                    controller.isLoading
                        ? Icons.hourglass_top_rounded
                        : controller.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 44,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: controller.togglePlayback,
                ),
                IconButton(
                  tooltip: controller.isDownloaded
                      ? 'السورة محملة'
                      : controller.isDownloading
                      ? 'يتم تحميل السورة'
                      : 'تحميل السورة',
                  disabledColor: controller.isDownloaded
                      ? AppTheme.primaryColor
                      : Colors.grey[400],
                  icon: controller.isDownloading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            value: controller.downloadProgress == 0
                                ? null
                                : controller.downloadProgress,
                            strokeWidth: 2.5,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : Icon(
                          controller.isDownloaded
                              ? Icons.download_done_rounded
                              : Icons.download_for_offline_outlined,
                          color: controller.isDownloaded
                              ? AppTheme.primaryColor
                              : null,
                        ),
                  onPressed:
                      controller.isDownloading || controller.isDownloaded
                      ? null
                      : controller.downloadSurah,
                ),
                PopupMenuButton<String>(
                  tooltip: 'اختيار القارئ',
                  enabled: !controller.isDownloading,
                  icon: const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  onSelected: (id) {
                    final reciter = QuranAudioStorage.reciterById(id);
                    unawaited(controller.selectReciter(reciter));
                  },
                  itemBuilder: (context) => [
                    for (final reciter in QuranAudioStorage.availableReciters)
                      PopupMenuItem<String>(
                        value: reciter.id,
                        child: Row(
                          children: [
                            Icon(
                              reciter.id == controller.selectedReciter.id
                                  ? Icons.check_rounded
                                  : Icons.mic_none_rounded,
                              size: 20,
                              color: reciter.id == controller.selectedReciter.id
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
                        _titleText(controller),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _subtitleText(controller),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _subtitleColor(controller),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!controller.isSurahMode)
                  TextButton(
                    onPressed: controller.isLoading
                        ? null
                        : controller.playWholeSurah,
                    child: const Text(
                      'السورة',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _titleText(QuranAudioController controller) {
    if (controller.isLoading) {
      return 'يتم تحميل الصوت...';
    }

    if (controller.isSurahMode) {
      return 'السورة كاملة';
    }

    return 'من الآية ${controller.currentVerse ?? 1}';
  }

  String _subtitleText(QuranAudioController controller) {
    if (controller.errorMessage != null) {
      return controller.errorMessage!;
    }

    if (!controller.isDownloading && !controller.isDownloaded) {
      if (controller.selectedReciter.supportsSurahDownload) {
        return '${controller.selectedReciter.shortName} - يمكن تحميل السورة للاستماع دون إنترنت';
      }
      return '${controller.selectedReciter.shortName} - يحتاج اتصالا بالإنترنت للتشغيل';
    }

    if (controller.isDownloading) {
      final percent = (controller.downloadProgress * 100).round().clamp(0, 100);
      return 'يتم تحميل السورة... $percent%';
    }

    if (controller.isDownloaded) {
      return 'السورة محملة وتعمل دون إنترنت';
    }

    return '${controller.selectedReciter.shortName} - يحتاج اتصالا، ويمكن تحميل السورة للاستماع دون إنترنت';
  }

  Color? _subtitleColor(QuranAudioController controller) {
    if (controller.errorMessage != null) {
      return Colors.red[700];
    }

    if (controller.isDownloaded || controller.isDownloading) {
      return AppTheme.primaryColor;
    }

    return Colors.grey[600];
  }
}

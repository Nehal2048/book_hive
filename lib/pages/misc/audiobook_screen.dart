import 'package:book_hive/models/book.dart';
import 'package:book_hive/models/book_details.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudiobookScreen extends StatefulWidget {
  final Book book;
  final BookDetails bookDetails;

  const AudiobookScreen({
    super.key,
    required this.book,
    required this.bookDetails,
  });

  @override
  State<AudiobookScreen> createState() => _AudiobookScreenState();
}

class _AudiobookScreenState extends State<AudiobookScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  double playbackSpeed = 1.0;
  double _volume = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() async {
    try {
      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            isPlaying = state.playing;
          });
        }
      });

      // Set the audio source and load it
      await _audioPlayer.setUrl(widget.bookDetails.audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load audio: $e')));
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _skipForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      await _seek(newPosition);
    }
  }

  Future<void> _skipBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _seek(newPosition);
    } else {
      await _seek(Duration.zero);
    }
  }

  Future<void> _changeSpeed(double value) async {
    setState(() {
      playbackSpeed = value;
    });
    await _audioPlayer.setSpeed(playbackSpeed);
  }

  Future<void> _changeVolume(double value) async {
    setState(() {
      _volume = value;
    });
    await _audioPlayer.setVolume(value);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listening: ${widget.book.title} by ${widget.book.author}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Book Cover
            Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade200,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.headphones, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            // Book Info
            Text(
              widget.book.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(widget.book.author, style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            // Progress Bar
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    activeTrackColor: Colors.deepPurple,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: Colors.deepPurple,
                    overlayColor: Colors.deepPurple.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ),
                  ),
                  child: Slider(
                    value: _duration.inSeconds > 0
                        ? (_position.inSeconds / _duration.inSeconds).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      final position = Duration(
                        seconds: (_duration.inSeconds * value).round(),
                      );
                      _seek(position);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // All Controls in One Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Volume Control
                IconButton(
                  icon: Icon(_volume > 0 ? Icons.volume_up : Icons.volume_off),
                  iconSize: 28,
                  onPressed: () {
                    _changeVolume(_volume > 0 ? 0.0 : 1.0);
                  },
                ),
                SizedBox(
                  width: 150,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      activeTrackColor: Colors.deepPurple,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.deepPurple,
                      overlayColor: Colors.deepPurple.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: _changeVolume,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 28,
                  onPressed: _skipBackward,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32,
                  onPressed: () async {
                    await _audioPlayer.seek(Duration.zero);
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: _togglePlayPause,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  onPressed: () async {
                    await _audioPlayer.seek(_duration);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 28,
                  onPressed: _skipForward,
                ),
                const SizedBox(width: 8),
                // Speed Control
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed, size: 28),
                    Text(
                      '${playbackSpeed.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 150,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      activeTrackColor: Colors.deepPurple,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.deepPurple,
                      overlayColor: Colors.deepPurple.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.0,
                      ),
                    ),
                    child: Slider(
                      value: playbackSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      onChanged: _changeSpeed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final Map<String, AudioPlayer> _players = {};
  static AudioPlayer? _backgroundMusicPlayer;
  
  static const Map<String, String> _sounds = {
    'dice': 'assets/sounds/piecemove.wav',
    'move': 'assets/sounds/piecemove.wav',
    'capture': 'assets/sounds/capture.wav',
    'win': 'assets/sounds/endgame.wav',
    'click': 'assets/sounds/piecemove.wav',
    'error': 'assets/sounds/endgame.mp3',
    'background': 'assets/sounds/startgame.mp3',
  };
  
  // ========== BACKGROUND MUSIC METHODS ==========
  
  /// Start playing background music (looped)
  static Future<void> startBackgroundMusic() async {
    try {
      await stopBackgroundMusic();
      
      _backgroundMusicPlayer = AudioPlayer();
      
      // ✅ Use setSource() then play() for better reliability
      await _backgroundMusicPlayer!.setSource(AssetSource(_sounds['background']!));
      await _backgroundMusicPlayer!.setVolume(0.5);
      await _backgroundMusicPlayer!.setReleaseMode(ReleaseMode.loop);
      
      // ✅ Play after setting everything
      await _backgroundMusicPlayer!.resume();
      
      print('🎵 Background music started');
    } catch (e) {
      print('Error starting background music: $e');
    }
  }
  
  /// Stop background music
  static Future<void> stopBackgroundMusic() async {
    if (_backgroundMusicPlayer != null) {
      await _backgroundMusicPlayer!.stop();
      await _backgroundMusicPlayer!.dispose();
      _backgroundMusicPlayer = null;
      print('🎵 Background music stopped');
    }
  }
  
  /// Pause background music
  static Future<void> pauseBackgroundMusic() async {
    if (_backgroundMusicPlayer != null) {
      await _backgroundMusicPlayer!.pause();
      print('🎵 Background music paused');
    }
  }
  
  /// Resume background music
  static Future<void> resumeBackgroundMusic() async {
    if (_backgroundMusicPlayer != null) {
      await _backgroundMusicPlayer!.resume();
      print('🎵 Background music resumed');
    }
  }
  
  /// Set background music volume (0.0 to 1.0)
  static Future<void> setBackgroundVolume(double volume) async {
    if (_backgroundMusicPlayer != null) {
      await _backgroundMusicPlayer!.setVolume(volume.clamp(0.0, 1.0));
    }
  }
  
  /// Check if background music is playing
  static bool isBackgroundMusicPlaying() {
    return _backgroundMusicPlayer != null && 
           (_backgroundMusicPlayer!.state == PlayerState.playing);
  }
  
  // ========== SOUND EFFECTS METHODS ==========
  
  static Future<void> play(String soundKey) async {
    try {
      final player = AudioPlayer();
      
      // ✅ Wait for playback to start
      await player.setSource(AssetSource(_sounds[soundKey]!));
      await player.resume();
      
      _players[soundKey] = player;
      
      // Clean up when done
      player.onPlayerComplete.listen((_) {
        player.dispose();
        _players.remove(soundKey);
      });
      
      // Also clean up on error
      player.onPlayerError.listen((error) {
        print('🎵 Sound error: $error');
        player.dispose();
        _players.remove(soundKey);
      });
      
    } catch (e) {
      print('Error playing sound $soundKey: $e');
    }
  }
  
  static Future<void> playDiceRoll() async => await play('dice');
  static Future<void> playTokenMove() async => await play('move');
  static Future<void> playCapture() async => await play('capture');
  static Future<void> playWin() async => await play('win');
  static Future<void> playClick() async => await play('click');
  static Future<void> playError() async => await play('error');
  
  static Future<void> stopAll() async {
    // Stop sound effects
    for (var player in _players.values) {
      await player.stop();
      player.dispose();
    }
    _players.clear();
    
    // Stop background music
    await stopBackgroundMusic();
  }
}

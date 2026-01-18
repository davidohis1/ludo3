import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final Map<String, AudioPlayer> _players = {};
  static AudioPlayer? _backgroundMusicPlayer; // Add this
  
  static const Map<String, String> _sounds = {
    'dice': 'assets/sounds/piecemove.wav',
    'move': 'assets/sounds/piecemove.wav',
    'capture': 'assets/sounds/capture.wav',
    'win': 'assets/sounds/endgame.wav',
    'click': 'assets/sounds/piecemove.wav',
    'error': 'assets/sounds/endgame.mp3',
    'background': 'assets/sounds/startgame.mp3', // Add background music
  };
  
  // ========== BACKGROUND MUSIC METHODS ==========
  
  /// Start playing background music (looped)
  static Future<void> startBackgroundMusic() async {
    try {
      // Stop any existing background music
      await stopBackgroundMusic();
      
      // Create new player for background music
      _backgroundMusicPlayer = AudioPlayer();
      
      // Set volume (0.0 to 1.0)
      await _backgroundMusicPlayer!.setVolume(0.5);
      
      // Set to loop
      await _backgroundMusicPlayer!.setReleaseMode(ReleaseMode.loop);
      
      // Play the background music
      await _backgroundMusicPlayer!.play(AssetSource(_sounds['background']!));
      
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
    return _backgroundMusicPlayer != null;
  }
  
  // ========== SOUND EFFECTS METHODS (KEEP YOUR EXISTING CODE) ==========
  
  static Future<void> play(String soundKey) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(_sounds[soundKey]!));
      _players[soundKey] = player;
      
      // Clean up when done
      player.onPlayerComplete.listen((_) {
        player.dispose();
        _players.remove(soundKey);
      });
    } catch (e) {
      print('Error playing sound $soundKey: $e');
    }
  }
  
  static Future<void> playDiceRoll() async => play('dice');
  static Future<void> playTokenMove() async => play('move');
  static Future<void> playCapture() async => play('capture');
  static Future<void> playWin() async => play('win');
  static Future<void> playClick() async => play('click');
  static Future<void> playError() async => play('error');
  
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
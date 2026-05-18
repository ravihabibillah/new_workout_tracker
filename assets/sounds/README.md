# Assets - Sounds

This directory is for audio files used in the IronLog app.

## Rest Timer Sound

Add a sound file here for the rest timer completion alert:
- Recommended format: MP3 or WAV
- Suggested filename: `timer_complete.mp3`
- Duration: 1-3 seconds
- Volume: Medium (will be controlled by device volume)

## Usage

The sound is played when the rest timer completes in the active workout screen.

## Free Sound Resources

You can download free timer sounds from:
- [Freesound.org](https://freesound.org/)
- [Zapsplat.com](https://www.zapsplat.com/)
- [Mixkit.co](https://mixkit.co/free-sound-effects/)

## Example Implementation

```dart
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();
await player.play(AssetSource('sounds/timer_complete.mp3'));
```

# Original game audio

Generated with `python tools/generate_game_audio.py` and `python tools/generate_boss_music.py` (NumPy, SciPy, SoundFile). All 23 effects are mono 44.1 kHz PCM16 WAV. Three original stereo Ogg Vorbis scores: refuge 64 seconds; expedition 51.2 seconds; boss 32 seconds. Music uses circular placement and wrapped room reflections for continuous full-file looping. No sampled material, voices, third-party music, Higgsfield or other AI audio service was used.

The deterministic seed and per-file measurements/hashes are recorded in manifest.json. The scores use original motifs, bass and dockyard percussion. The preview in output/audio-refresh/preview.wav demonstrates the expedition score with selected effects.

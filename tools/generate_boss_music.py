"""Generate the original, looping Almirante battle score (no external samples)."""
import numpy as np
import soundfile as sf

from generate_game_audio import SR, ROOT, env, noise, note, place, sweep


def compose():
    beat = 0.5
    bars = 16
    track = np.zeros((int(bars * 4 * beat * SR), 2), dtype=np.float64)
    roots = [38, 38, 34, 36, 38, 41, 34, 36,
             38, 38, 34, 33, 36, 34, 33, 38]
    for bar, root in enumerate(roots):
        start = bar * 4 * beat
        # Low brass and an insistent two-note figure give the fight its own motif.
        for pitch, pan in [(root + 12, -0.35), (root + 19, 0.3), (root + 24, -0.1)]:
            place(track, note(pitch, beat * 4, "pad"), start, 0.06, pan)
        for step in range(8):
            at = start + step * beat / 2
            pitch = root if step % 4 != 3 else root + 7
            place(track, note(pitch, beat * 0.75, "bass"), at, 0.16)
            if step % 2 == 0:
                place(track, note(root + (24 if step % 4 == 0 else 25), beat * 0.65, "pluck"), at, 0.055, -0.5 if step % 4 == 0 else 0.5)
            hat_t = np.arange(int(0.09 * SR)) / SR
            hat = noise(hat_t, 5000, 14000) * env(hat_t, 0.014)
            place(track, hat, at, 0.028, 0.4 if step % 2 else -0.4)
        for step in range(4):
            at = start + step * beat
            drum_t = np.arange(int(0.3 * SR)) / SR
            if step % 2 == 0:
                drum = sweep(drum_t, 105, 36, 0.025) * env(drum_t, 0.09)
                place(track, drum, at, 0.19)
            else:
                drum = noise(drum_t, 400, 6000) * env(drum_t, 0.055)
                place(track, drum, at, 0.085, 0.1)
        if bar % 4 == 3:
            for step in range(4):
                roll_t = np.arange(int(0.15 * SR)) / SR
                roll = noise(roll_t, 300, 4500) * env(roll_t, 0.035)
                place(track, roll, start + (3 + step / 4) * beat, 0.045 + step * 0.018)
    dry = track.copy()
    for delay, gain in [(0.125, 0.11), (0.25, 0.07), (0.5, 0.04)]:
        track += np.roll(dry[:, ::-1], int(delay * SR), axis=0) * gain
    track -= track.mean(axis=0)
    track = np.tanh(track)
    track *= 0.72 / np.max(np.abs(track))
    return track.astype(np.float32)


def main():
    path = ROOT / "assets/audio/generated/music_boss.ogg"
    path.parent.mkdir(parents=True, exist_ok=True)
    music = compose()
    with sf.SoundFile(path, "w", samplerate=SR, channels=2, format="OGG", subtype="VORBIS") as target:
        for start in range(0, len(music), SR):
            target.write(music[start:start + SR])
    print(f"{path}: {len(music) / SR:.1f}s looping boss score")


if __name__ == "__main__":
    main()

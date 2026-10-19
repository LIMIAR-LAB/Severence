"""Original deterministic synthesis for the occult dockyard game.

Requires numpy, scipy, soundfile. Run from any directory with Python 3.
No sampled recordings, external compositions, voices or generative services.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from scipy.signal import butter, sosfilt
import soundfile as sf

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/audio/generated'
SOURCE = ROOT / 'art/source/audio'
PREVIEW = ROOT / 'output/audio-refresh'
SR = 44100
RNG = np.random.default_rng(19410930)


def timeline(d):
    return np.arange(round(d * SR), dtype=np.float64) / SR


def noise(t, low=70, high=7000):
    return sosfilt(butter(2, [low, high], btype='bandpass', fs=SR, output='sos'), RNG.standard_normal(len(t)))


def env(t, decay, attack=.001):
    return (1 - np.exp(-t / attack)) * np.exp(-t / decay)


def sweep(t, f, end, decay=.04):
    phase = end * t + (f - end) * decay * (1 - np.exp(-t / decay))
    return np.sin(2 * np.pi * phase)


def ring(t, freq, decay, count=5):
    return sum(np.sin(2 * np.pi * freq * r * t) * env(t, decay / (1 + i * .45)) / (1 + i)
               for i, r in enumerate([1, 1.493, 2.137, 2.891, 4.07][:count]))


def finish(x, peak=.78):
    x = np.nan_to_num(x)
    x -= x.mean()
    x = np.tanh(x * 1.15)
    fade = min(round(.012 * SR), len(x) // 8)
    x[:80] *= np.linspace(0, 1, 80)
    x[-fade:] *= np.linspace(1, 0, fade) ** 2
    return x * (peak / max(np.max(np.abs(x)), 1e-9))


def shot(d, weight=1, metal=1700):
    t = timeline(d)
    x = 1.1 * noise(t, 400, 12000) * env(t, .012)
    x += weight * .9 * sweep(t, 170, 48, .017) * env(t, .055)
    x += .55 * noise(t, 90, 1700) * env(t, .06)
    x += .24 * ring(t, metal, .029, 3)
    # Delayed breech mechanism, separate from muzzle transient.
    q = np.maximum(t - .045, 0)
    x += .18 * ring(q, metal * .62, .018, 3) * (t >= .045)
    return x


def creature(d, base, wet=1, metal=0, magic=0):
    t = timeline(d)
    pitch = base * (1 + .15 * np.sin(2*np.pi*8*t)) * (1 - .3 * t / d)
    phase = 2*np.pi*np.cumsum(pitch) / SR
    growl = np.sin(phase + 1.7*np.sin(phase*.51)) + .32*np.sin(phase*2.01)
    x = .6 * growl * env(t, d / 3, .009)
    x += wet * noise(t, 200, 2300) * (.4 + .6*np.sin(2*np.pi*29*t)**4) * env(t, d/4, .006)
    x += metal * ring(t, base*8.3, .18)
    x += magic * (np.sin(phase*5.013) + .5*np.sin(phase*7.07)) * env(t, d/3, .023)
    return x


def make_sfx():
    sounds = {}
    sounds['pistol'] = shot(.25, .85)
    sounds['shotgun'] = shot(.43, 1.5, 1130)
    sounds['smg'] = shot(.16, .55, 2370)
    sounds['mech'] = shot(.32, 1.8, 780)
    t = timeline(.6)
    sounds['bazooka'] = .8*sweep(t, 190, 38)*env(t,.16) + noise(t,100,5000)*env(t,.13,.008)
    t = timeline(.39)
    sounds['sword'] = noise(t,850,10500)*np.sin(np.pi*np.minimum(t/.24,1))**2*np.exp(-t*8) + .4*ring(t,1270,.09)
    t = timeline(.27)
    sounds['melee'] = noise(t,90,2900)*env(t,.035,.003) + .8*sweep(t,120,40)*env(t,.05)
    t = timeline(.58)
    sounds['spectre'] = creature(.58,180,.12,0,.7) + .3*noise(t,1800,7000)*env(t,.1)
    for key, duration, base, wet, metal, magic in [
        ('enemy_cult',.65,122,.2,0,.8), ('enemy_fish',.48,162,.6,.65,0),
        ('enemy_crawler',.5,73,1.4,0,0), ('enemy_brute',.72,48,.7,.18,0),
        ('enemy_guard',.33,97,.05,.9,0), ('enemy_bomber',.48,205,.3,.5,.15),
        ('enemy_warden',.7,62,.25,.6,.3), ('enemy_boss',1.12,39,1,.2,.5),
        ('enemy_die',.52,95,.8,0,.08)]:
        sounds[key] = creature(duration,base,wet,metal,magic)
    sounds['enemy_guard'] += shot(.33,.8,950)*.9
    t = timeline(1.15)
    sounds['explosion'] = 1.4*sweep(t,100,28,.09)*env(t,.24)+noise(t,40,4800)*env(t,.18)+.3*noise(t,150,1300)*env(t,.4,.07)
    t = timeline(.19)
    sounds['hit'] = noise(t,100,2400)*env(t,.03)+.8*sweep(t,140,55)*env(t,.033)
    t = timeline(.25)
    sounds['jump'] = .4*sweep(t,120,380,.1)*env(t,.08,.005)+noise(t,150,1700)*env(t,.055,.01)
    t = timeline(.36)
    sounds['dash'] = noise(t,300,7500)*env(t,.07,.015)+.25*sweep(t,280,60,.09)*env(t,.08,.01)
    t = timeline(.56)
    sounds['pickup'] = sum(np.sin(2*np.pi*f*t)*env(t,.14,.003)*a for f,a in [(659.25,.45),(987.77,.3),(1318.51,.2)])
    t = timeline(.12)
    sounds['dry_fire'] = ring(t,1850,.015,4)*.3+noise(t,900,9000)*env(t,.006)
    # Lore das Docas (Passo 1): sussurro da fissura — sílabas mudas em ruído filtrado,
    # formação "consonantal" espectral e um deslize grave que resolve como água escura.
    t = timeline(1.9)
    breath = noise(t, 700, 3600)
    syllables = (.28 + .72*np.sin(2*np.pi*2.7*t)**2) * (.55 + .45*np.sin(2*np.pi*4.6*t + 1.3)**2)
    formant = noise(t, 1800, 2600) * np.sin(2*np.pi*6.1*t)**4
    slide = sweep(t, 95, 62, .9) * env(t, 1.3, .5)
    sounds['whisper'] = breath * syllables * env(t, 1.15, .4) + .35*formant*env(t, 1.0, .3) + .22*slide
    return {k:finish(v, .5 if k == 'whisper' else (.62 if k in ['pickup','dry_fire','jump'] else .78)) for k,v in sounds.items()}


def hz(midi):
    return 440 * 2**((midi-69)/12)


def place(track, sound, at, gain=1, pan=0):
    indices = (np.arange(len(sound)) + round(at*SR)) % len(track)
    np.add.at(track[:,0],indices,sound*gain*np.sqrt((1-pan)/2))
    np.add.at(track[:,1],indices,sound*gain*np.sqrt((1+pan)/2))


def note(midi, duration, kind):
    t = timeline(duration)
    f = hz(midi)
    if kind == 'pad':
        x = sum(np.sin(2*np.pi*f*r*t + .22*np.sin(2*np.pi*.19*t)) * a for r,a in [(1,.65),(1.003,.3),(.998,.3),(2,.12),(3,.045)])
        e = np.sin(np.pi*t/duration)**1.6
    elif kind == 'bass':
        x = np.sin(2*np.pi*f*t)+.15*np.sin(4*np.pi*f*t)
        e = env(t,duration*.35,.014) * np.minimum((duration-t)/.1,1)
    else:
        x = np.sin(2*np.pi*f*t)+.27*np.sin(2*np.pi*f*2.001*t)+.08*np.sin(2*np.pi*f*3.998*t)
        e = env(t,.8 if kind == 'bell' else .24,.003)
        e *= np.minimum((duration-t)/.12,1)
    return x*e


def music(expedition):
    beat = .8 if expedition else 1.
    duration = beat*64
    track = np.zeros((round(duration*SR),2))
    # Original sixteen-bar D-minor progression; suspended colors leave room for effects.
    chords = [[50,57,60,64],[46,53,57,60],[53,60,64,67],[48,55,58,62],
              [50,57,60,65],[46,53,57,62],[43,50,58,62],[45,52,57,61]]
    motif = [74,None,72,69,65,None,69,72,74,77,None,76,72,69,65,69]
    for bar in range(16):
        chord = chords[bar//2]
        for j,m in enumerate(chord):
            place(track,note(m,beat*6,'pad'),bar*beat*4,.052, (j-1.5)*.42)
        for b in range(4):
            place(track,note(chord[0]-12,beat*1.5,'bass'),(bar*4+b)*beat,.115 if expedition else .055)
        for b in range(4 if expedition else 2):
            m = chord[(b+bar)%4]+12
            place(track,note(m,beat*2,'pluck'),(bar*4+b*(1 if expedition else 2)+.5)*beat,.035 if expedition else .025,np.sin(bar+b)*.65)
        # Sparse glass/electric-piano phrase, never a continuous alarm tone.
        if bar % 2 == 0:
            for b in range(4):
                m = motif[(bar*2+b)%len(motif)]
                if m is not None:
                    place(track,note(m,beat*3,'bell'),(bar*4+b)*beat,.045,-.2)
        if expedition:
            for b in [0,2]:
                t = timeline(.4)
                kick = sweep(t,95,39,.026)*env(t,.075)+noise(t,600,3000)*env(t,.006)*.2
                place(track,kick,(bar*4+b)*beat,.15)
            for b in [1,3]:
                t = timeline(.33)
                snare = noise(t,650,6000)*env(t,.055)+ring(t,410,.06)*.3
                place(track,snare,(bar*4+b)*beat,.064,.12)
            for b in range(8):
                t = timeline(.12)
                hat = noise(t,5000,14000)*env(t,.012 if b%2 else .022)
                place(track,hat,(bar*4+b*.5)*beat,.034,-.35 if b%2 else .35)
    # A genuinely circular room response: reflections from the end continue at start.
    dry = track.copy()
    for delay, gain in [(.117,.12),(.239,.1),(.431,.075),(.683,.055),(.947,.033),(1.331,.018)]:
        track += np.roll(dry[:,::-1],round(delay*SR),axis=0)*gain
    track -= track.mean(axis=0)
    track = np.tanh(track*.95)
    track *= .66 / np.max(np.abs(track))
    return track


def metrics(x):
    return {'duration_seconds':round(len(x)/SR,5), 'peak_dbfs':round(float(20*np.log10(np.max(np.abs(x))+1e-12)),2),
            'rms_dbfs':round(float(20*np.log10(np.sqrt(np.mean(x*x))+1e-12)),2),
            'boundary_sample_delta':round(float(np.max(np.abs(x[0]-x[-1]))),7)}


def main():
    for p in (OUT,SOURCE,PREVIEW): p.mkdir(parents=True,exist_ok=True)
    sounds = make_sfx()
    manifest = {'version':1,'method':'Original deterministic procedural sound design and composition; no external samples or AI service',
                'seed':19410930,'sample_rate':SR,'rights':'Original project assets, unrestricted use within this project and its releases.',
                'generator':'tools/generate_game_audio.py','dependencies':['numpy','scipy','soundfile'],'assets':{}}
    for key,x in sounds.items():
        path = OUT / (key+'.wav')
        sf.write(path,x,SR,subtype='PCM_16')
        manifest['assets'][key] = {'file':path.relative_to(ROOT).as_posix(),'format':'WAV PCM16 mono',**metrics(x)}
    for key,exp in [('music_refuge',False),('music_expedition',True)]:
        x = music(exp)
        path = OUT / (key+'.ogg')
        # Bounded writes also avoid libsndfile/Vorbis large-buffer failures on Windows.
        with sf.SoundFile(path,'w',samplerate=SR,channels=2,format='OGG',subtype='VORBIS') as target:
            for start in range(0,len(x),SR):
                target.write(x[start:start+SR].astype(np.float32))
        decoded,rate = sf.read(path)
        assert rate == SR and len(decoded) == len(x)
        manifest['assets'][key] = {'file':path.relative_to(ROOT).as_posix(),'format':'Ogg Vorbis stereo','loop':True,**metrics(decoded)}
        if exp: bed = decoded
    boss_path = OUT / 'music_boss.ogg'
    if boss_path.exists():
        decoded,rate = sf.read(boss_path)
        assert rate == SR
        manifest['assets']['music_boss'] = {'file':boss_path.relative_to(ROOT).as_posix(),'format':'Ogg Vorbis stereo','loop':True,
                                            'generator':'tools/generate_boss_music.py',**metrics(decoded)}
    preview = bed[:SR*24].copy()*.52
    for i,key in enumerate(['pistol','shotgun','smg','bazooka','mech','sword','spectre','enemy_cult','enemy_fish','enemy_crawler','enemy_guard','enemy_boss','explosion','pickup']):
        x = sounds[key]
        place(preview,x,1+i*1.5,.28,np.sin(i)*.35)
    preview[:SR//2] *= np.linspace(0,1,SR//2)[:,None]
    preview[-SR:] *= np.linspace(1,0,SR)[:,None]
    sf.write(PREVIEW/'preview.wav',preview,SR,subtype='PCM_16')
    for item in manifest['assets'].values():
        item['sha256'] = hashlib.sha256((ROOT/item['file']).read_bytes()).hexdigest()
    (SOURCE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    (SOURCE/'README.md').write_text('# Original game audio\n\nGenerated with `python tools/generate_game_audio.py` and `python tools/generate_boss_music.py` (NumPy, SciPy, SoundFile). All 23 effects are mono 44.1 kHz PCM16 WAV. Three original stereo Ogg Vorbis scores: refuge 64 seconds; expedition 51.2 seconds; boss 32 seconds. Music uses circular placement and wrapped room reflections for continuous full-file looping. No sampled material, voices, third-party music, Higgsfield or other AI audio service was used.\n\nThe deterministic seed and per-file measurements/hashes are recorded in manifest.json. The scores use original motifs, bass and dockyard percussion. The preview in output/audio-refresh/preview.wav demonstrates the expedition score with selected effects.\n',encoding='utf-8')
    print(json.dumps(manifest,indent=2))


if __name__ == '__main__':
    main()

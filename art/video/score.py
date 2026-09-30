import numpy as np, wave
sr=48000
t=np.arange(sr*60)/sr
bed=np.zeros_like(t)
def note(start,dur,freq,amp):
 a=int(start*sr); n=int(dur*sr); q=np.arange(n)/sr
 env=np.minimum(q/.18,1)*np.exp(-q/(dur*.45))*np.minimum((dur-q)/.3,1)
 tone=(np.sin(2*np.pi*freq*q)+.25*np.sin(2*np.pi*freq*2*q)+.1*np.sin(2*np.pi*freq*3*q))*env*amp
 bed[a:a+n]+=tone[:len(bed[a:a+n])]
for start in [0.3,3,39,49,56]:
 for j,f in enumerate([220,261.63,329.63,293.66]):
  note(start+j*.55,min(3,60-start-j*.55),f,.025 if start<15 else .018)
env=np.interp(t,[0,3,14,15,23,29,30,31,39,49,56,59.4,60],[0,.4,.3,.55,.8,1,0,.25,.2,.35,.7,.2,0])
bed+=(np.sin(2*np.pi*55*t)+.4*np.sin(2*np.pi*82.41*t))*.012*env
bed*=np.minimum(t/.3,1)*np.minimum((60-t)/.6,1)
stereo=np.stack([bed,bed],axis=1)
with wave.open('/tmp/severence/score.wav','wb') as w:
 w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr);w.writeframes((np.clip(stereo,-1,1)*32767).astype('<i2').tobytes())

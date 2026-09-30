import subprocess,numpy as np,wave,json
sr=48000
mix=np.zeros((sr*60,2),dtype=np.float64)
cuts=[(1,3,2,0),(2,5,3,1),(3,8,7,0),(4,15,8,0),(5,23,8,0),(6,31,2,0),(7,33,2,0),(8,35,2,0),(9,37,2,0),(10,39,10,0),(11,49,7,0)]
stats=[]
for i,at,dur,src in cuts:
 raw=subprocess.check_output(['ffmpeg','-v','error','-i',f'/tmp/smooth/{i}.mp4','-f','f32le','-ac','2','-ar',str(sr),'-'])
 x=np.frombuffer(raw,dtype='<f4').reshape(-1,2).astype(np.float64)[int(src*sr):]
 # Carry genuine ambience beyond the visual cut when the source provides handles.
 length=min(len(x),int((dur+.5)*sr))
 x=x[:length].copy()
 rms=np.sqrt(np.mean(x*x))
 gain=np.clip(.09/max(rms,.0001),.75,1.25)
 x*=gain
 fadein=min(int(.12*sr),len(x)); x[:fadein]*=np.linspace(0,1,fadein)[:,None]
 extra=max(0,length-int(dur*sr))
 fadeout=extra if extra>int(.08*sr) else int((.025 if i==2 else .10)*sr)
 fadeout=min(fadeout,len(x))
 x[-fadeout:]*=np.linspace(1,0,fadeout)[:,None]
 # Quiet reverberation trails soften abrupt changes without repeating words clearly.
 tail=np.zeros((len(x)+int(.36*sr),2));tail[:len(x)]+=x
 for delay,amp in [(.071,.055),(.137,.035),(.229,.02),(.347,.01)]:
  shift=int(delay*sr);tail[shift:shift+len(x)]+=x*amp
 offset=int(at*sr); n=min(len(tail),len(mix)-offset);mix[offset:offset+n]+=tail[:n]
 stats.append({'scene':i,'rms':round(float(rms),4),'gain':round(float(gain),3),'tail':round(extra/sr,3)})
with wave.open('/tmp/smooth/score.wav','rb') as w:
 score=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').reshape(-1,2)/32768.
mix+=score*1.5
mix[-int(.65*sr):]*=np.linspace(1,0,int(.65*sr))[:,None]
peak=np.max(np.abs(mix))
if peak>.95:mix*=.95/peak
with wave.open('/tmp/smooth/mix.wav','wb') as w:
 w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr);w.writeframes((mix*32767).astype('<i2').tobytes())
print(json.dumps({'mix_peak':float(np.max(np.abs(mix))),'scenes':stats}),flush=True)

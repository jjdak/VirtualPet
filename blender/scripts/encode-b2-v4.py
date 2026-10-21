"""Encode and inspect completed v4/v5 frames using the existing local FFmpeg."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path

root=Path(__file__).resolve().parents[2]
out=root/'PrivateAssets/Courtyard/Blender/B2'
parser=argparse.ArgumentParser()
parser.add_argument('--version',choices=['v4','v5'],default='v4')
parser.add_argument('--master',action='store_true')
args=parser.parse_args()
stem='b2-body-v5' if args.version=='v5' else 'b2-presence-v4'
frames=out/('frames-body-v5' if args.version=='v5' else 'frames-presence-v4')
project=out/('courtyard-'+stem+'.blend')
video=out/(stem+('-review.mp4' if args.version=='v5' else '.mp4'))
ffmpeg=shutil.which('ffmpeg');ffprobe=shutil.which('ffprobe')
assert ffmpeg and ffprobe
assert all((frames/f'{i:04d}.png').is_file() for i in range(1,193))
assert len(list(frames.glob('*.png')))==192
config=json.loads((frames/'render-config.json').read_text())
assert config['project_sha256']==hashlib.sha256(project.read_bytes()).hexdigest()
assert not video.exists(),'Preserve existing movies; inspect before replacing'
subprocess.run([ffmpeg,'-hide_banner','-loglevel','error','-n','-framerate','24',
    '-start_number','1','-i',str(frames/'%04d.png'),'-frames:v','192',
    '-c:v','libx264','-crf','6' if args.version=='v5' else '18','-pix_fmt','yuv420p','-movflags','+faststart',str(video)],check=True)
probe=json.loads(subprocess.check_output([ffprobe,'-v','error','-show_entries',
    'stream=codec_type,width,height,avg_frame_rate,nb_frames:format=duration','-of','json',str(video)]))
assert len(probe['streams'])==1
s=probe['streams'][0]
assert (s['width'],s['height'],s['avg_frame_rate'],s['nb_frames'])==(960,540,'24/1','192')
assert float(probe['format']['duration'])==8
subprocess.run([ffmpeg,'-v','error','-i',str(video),'-f','null','-'],check=True)
subprocess.run([ffmpeg,'-v','error','-n','-i',str(video),'-vf',
    "select='eq(n,0)+eq(n,48)+eq(n,95)+eq(n,144)+eq(n,191)',scale=640:360,tile=3x2",'-frames:v','1',
    str(out/(stem+'-contact-sheet.png'))],check=True)
report={'project_sha256':config['project_sha256'],'video':str(video),'metadata':probe,
        'video_sha256':hashlib.sha256(video.read_bytes()).hexdigest(),'sequence_complete':True,
        'decode':'pass','samples':config['samples'],'visual_review':'pending',
        'owner_acceptance':'pending','limitations':'No audio, face animation, interaction or learning.'}
# Whole-clip brightness diagnostics catch gross flashes; they are not a flicker verdict.
raw=subprocess.check_output([ffmpeg,'-v','error','-i',str(video),'-vf','scale=160:90',
    '-pix_fmt','gray','-f','rawvideo','-'])
size=160*90
assert len(raw)==192*size
gray=[raw[i*size:(i+1)*size] for i in range(192)]
mean=[sum(f)/size for f in gray]
deltas=[sum(abs(a-b) for a,b in zip(gray[i-1],gray[i]))/size for i in range(1,192)]
report['temporal_diagnostics']={
    'gray_scale':'0..255, downsampled 160x90',
    'max_global_mean_brightness_step':max(abs(a-b) for a,b in zip(mean,mean[1:])),
    'mean_adjacent_frame_absolute_difference':sum(deltas)/len(deltas),
    'max_adjacent_frame_absolute_difference':max(deltas),
    'last_to_first_absolute_difference':sum(abs(a-b) for a,b in zip(gray[-1],gray[0]))/size,
    'interpretation':'Diagnostic only; local shimmer and naturalness still need playback review.'}
if args.master:
    master=out/(stem+'-master.mov')
    subprocess.run([ffmpeg,'-v','error','-n','-framerate','24','-i',str(frames/'%04d.png'),
        '-frames:v','192','-c:v','prores_ks','-profile:v','3','-pix_fmt','yuv422p10le',
        '-vendor','apl0',str(master)],check=True)
    subprocess.run([ffmpeg,'-v','error','-i',str(master),'-f','null','-'],check=True)
    meta=json.loads(subprocess.check_output([ffprobe,'-v','error','-show_entries',
        'stream=nb_frames,avg_frame_rate:format=duration','-of','json',str(master)]))
    assert meta['streams'][0]['nb_frames']=='192' and float(meta['format']['duration'])==8
    report['master']={'path':str(master),'metadata':meta,'decode':'pass',
                      'sha256':hashlib.sha256(master.read_bytes()).hexdigest()}
(out/(stem+'-delivery.json')).write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

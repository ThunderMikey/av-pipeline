# Required software:
# * ffmpeg
# * sox
# * ffmpeg-normalize

# configs
#
presentation_start_time := 00:07:46

noise_start_time := 00:18:42
noise_duration := 00:00:01

# cut av
av-cut.avi: av-original.avi
	ffmpeg -i $< -ss $(presentation_start_time) -c copy $@

# extract video from av
video.avi: av-cut.avi
	ffmpeg -i $< -vcodec copy -an $@

# extract audio from av
audio.wav: av-cut.avi
	ffmpeg -i $< -acodec copy -vn $@

# band pass 500Hz to 3000Hz to filter noise
audio-bandpassed.wav: audio.wav
	ffmpeg -i $< -af 'highpass=f=500, lowpass=f=3000' $@

# get noisesample
noise_sample.wav: audio-bandpassed.wav
	ffmpeg -i $< -ss $(noise_start_time) -t $(noise_duration) $@

# generate noise profile
# use SOX, see https://unix.stackexchange.com/questions/140398/cleaning-voice-recordings-from-command-line
noise.profile: noise_sample.wav
	sox $< -n noiseprof $@

audio-denoised.wav: audio-bandpassed.wav noise.profile
	sox $< $@ noisered noise.profile 0.21

# apply EBU R128 normalization to audio
# need to install `ffmpeg-normalize`
# see https://github.com/slhck/ffmpeg-normalize 
audio-normalized.wav: audio-denoised.wav
	ffmpeg-normalize $< -o $@

audio-final.mp3: audio-normalized.wav
	ffmpeg -i $< -codec:a libmp3lame -qscale:a 2 $@

audio-final.flac: audio-normalized.wav
	ffmpeg -i $< -af aformat=s16:44100 $@

# iMovie can only process yuv420, not yuv444 :(
# -crf 0 will result in high 4:4:4 predictive video with yuv420
video-final.mp4: video.avi
	ffmpeg -i $< -c:v libx264 -crf 10 -pix_fmt yuv420p $@ 

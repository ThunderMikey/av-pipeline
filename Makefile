# Required software:
# * ffmpeg
# * sox
# * ffmpeg-normalize

## Binaries
NORMALIZER := ffmpeg-normalize

# configs
#
presentation_start_time := 00:09:27
presentation_end_time := 00:56:22

# list of choices:
# * mixed
# * ext_mic
# * laptop_mic
# * desktop
# * phone
use_audio_track := desktop

noise_start_time := 00:18:42
noise_duration := 00:00:01

# cut av
av-cut.mkv: av-original.mkv
	ffmpeg -i $< -ss $(presentation_start_time) \
		-to $(presentation_end_time) \
		-map 0 \
		-c copy $@

# extract video from av
video.mp4: av-cut.mkv
	ffmpeg -i $< -c:v copy -an $@

# extract audio from av
mixed.aac ext_mic.aac laptop_mic.aac desktop.aac: av-cut.mkv
	ffmpeg -i $< -vn \
		-map 0:a:0 -c copy mixed.aac \
		-map 0:a:1 -c copy ext_mic.aac \
		-map 0:a:2 -c copy laptop_mic.aac \
		-map 0:a:3 -c copy desktop.aac

phone.aac: phone-original.m4a
	ffmpeg -i $< -c:a copy $@

# band pass 500Hz to 3000Hz to filter noise
%-bandpassed.aac: %.aac
	ffmpeg -i $< -af 'highpass=f=500, lowpass=f=3000' $@

# apply EBU R128 normalization to audio
# need to install `ffmpeg-normalize`
# see https://github.com/slhck/ffmpeg-normalize 
%-normalized.aac: %-bandpassed.aac
	$(NORMALIZER) -f $< -o $@ \
		-c:a aac

###############################################
# If there is excessive noise in the audio
# de-noise it
###############################################
# get noisesample
%-noise_sample.wav: %-bandpassed.wav
	ffmpeg -i $< -ss $(noise_start_time) -t $(noise_duration) $@

# generate noise profile
# use SOX, see https://unix.stackexchange.com/questions/140398/cleaning-voice-recordings-from-command-line
%-noise.profile: %-noise_sample.wav
	sox $< -n noiseprof $@

%-denoised.wav: %-bandpassed.wav %-noise.profile
	sox $< $@ noisered $*-noise.profile 0.21


###################################
# final products
###################################

video-final.mp4: video.mp4
	cp $< $@

%-final.aac: %-normalized.aac
	cp $< $@


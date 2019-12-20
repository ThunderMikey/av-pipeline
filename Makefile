# Required software:
# * ffmpeg
# * sox
# * ffmpeg-normalize

## Binaries
NORMALIZER := ffmpeg-normalize

# configs
#
presentation_start_time := 00:05:52
presentation_end_time := 00:51:15

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
phone-bandpassed.aac: phone.aac
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
desktop-normalized.aac: desktop.aac
	$(NORMALIZER) -f $< -o $@ \
		-c:a aac

phone-normalized.aac: phone-bandpassed.aac
	$(NORMALIZER) -f $< -o $@ \
		-c:a aac


###################################
# final products
###################################

video-final.mp4: video.mp4
	cp $< $@

desktop-final.aac: desktop-normalized.aac
	cp $< $@

phone-final.aac: phone-normalized.aac
	cp $< $@

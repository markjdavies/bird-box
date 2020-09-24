
if [$MODE=='STILL']
then
    modprobe v4l2_common && python bird-box.py &
    cd /data
    python -m http.server 80
else
    echo Exposure settings: br: ${BRIGHTNESS:=70} contrast: ${CONTRAST:=75} ISO: ${ISO:=800} ev: ${EV:=0}
    echo Region of interest: $ROI
    echo Starting YouTube stream
    raspivid -o - -t 0 \
            -w ${WIDTH:=1280} \
            -h ${HEIGHT:=720} \
            -fps ${FPS:=24} \
            -b ${BITRATE:=3000000} \
            -g ${INTRA:=48} \
            --brightness $BRIGHTNESS \
            --contrast $CONTRAST \
            --ISO $ISO \
            --ev $EV \
            --exposure ${EXPOSURE:=night} \
            --awb ${AWB:=greyworld} \
            --rotation ${ROTATION:=0} \
            --roi ${ROI:=0,0,1,1} \
        | \
        ffmpeg \
            -fflags +genpts \
            -f lavfi -i anullsrc=r=48000:cl=mono \
            -re \
            -ar 44100 \
            -ac 2 \
            -acodec pcm_s16le \
            -f s16le \
            -ac 2 \
            -i /dev/zero \
            -f h264 \
            -thread_queue_size ${THREAD_QUEUE_SIZE:=1024} \
            -i - \
            -vcodec \
        copy \
            -acodec aac \
            -ab 128k \
            -g 50 \
            -strict experimental \
            -f \
        flv rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY
fi

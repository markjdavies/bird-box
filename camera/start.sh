while :
do
    echo Taking still picture
    modprobe v4l2_common && python bird-box.py

    nextBreakHoursPart=$(((6 - ($(date +%H) % 6) - 1) * 3600))
    nextBreakMinutesPart=$(((60 - ($(date +%M))) * 60 - 120))
    nextBreakSeconds=$((nextBreakHoursPart + nextBreakMinutesPart))

    echo 'Minutes until next break:' $((nextBreakSeconds / 60))

    if [ $nextBreakSeconds -lt 0 ]
    then
        echo Sleeping...
        sleep 20s
    else
        echo Startng YouTube stream
        echo Exposure settings: br: ${BRIGHTNESS:=70} contrast: ${CONTRAST:=75} ISO: ${ISO:=800} ev: ${EV:=0}
        echo Region of interest: $ROI
        echo Starting YouTube stream
        raspivid -o - -t 0 \
            -n \
            -ih \
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
        ffmpeg -re \
            -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero \
            -re \
            -f h264 \
            -thread_queue_size ${THREAD_QUEUE_SIZE:=1024} \
            -i - \
            -vcodec copy \
            -acodec aac \
            -ab 128k \
            -g 50 \
            -strict normal \
            -t $nextBreakSeconds \
            -f flv rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY
    fi

done

#  \
#         -vf " \
#                 drawtext=fontfile=/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans-Bold.ttf: \
#                 text='\%T': fontcolor=black@0.8: x=7: y=700 \
#             "

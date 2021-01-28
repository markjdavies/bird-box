#!/bin/sh
while :
do
    echo Taking still picture
    modprobe v4l2_common && python bird-box.py

    streamData=$(python getCurrentStream.py)

    if [ -z "$streamData" ]
    then
        echo Sleeping...
        sleep 20s
    else
        streamId=$(echo streamData | jq '.streamId')
        secondsRemaining=$(echo streamData | jq '.secondsRemaining')
        millisecondsRemaining=$((secondsRemaining * 1000))

        echo Starting YouTube stream $streamId for $((nextBreakSeconds / 60)) minutes
        echo Exposure settings: br: ${BRIGHTNESS:=70} contrast: ${CONTRAST:=75} ISO: ${ISO:=800} ev: ${EV:=0}
        echo Region of interest: $ROI
        echo Starting YouTube stream
        raspivid -o - -t $millisecondsRemaining \
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
            -t $secondsRemaining \
            -f flv rtmp://a.rtmp.youtube.com/live2/$streamId
        echo Streaming finished
    fi
done

#  \
#         -vf " \
#                 drawtext=fontfile=/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans-Bold.ttf: \
#                 text='\%T': fontcolor=black@0.8: x=7: y=700 \
#             "

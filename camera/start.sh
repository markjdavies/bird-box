#!/bin/sh
while :
do
    echo Taking still picture
    modprobe v4l2_common && python bird-box.py

    streamData=$(python getCurrentStream.py)

    if [ -z "$streamData" ]
    then
        streamData=$( python3 create-broadcast.py \
            --broadcast-title "Bird Nesting Box" \
            --privacy-status "public"  \
            --stream-title "Nesting Box Stream" \
            --description "Oxfordshire, UK")
        echo $streamData
        errorMessage=$(echo $streamData | jq '.error.message')
        if [ -n "$errorMessage" ]
        then
            echo Success
            streamId=$(echo $streamData | jq -r '.stream')
            secondsRemaining=$(echo $streamData | jq -r '.timeRemaining')
        else
            echo $errorMessage
            echo Trying default stream
            streamId=${YOU_TUBE_API_KEY}
            secondsRemaining=21540
        fi
    else
        streamId=$(echo $streamData | jq -r '.stream')
        secondsRemaining=$(echo $streamData | jq -r '.timeRemaining')
    fi
    millisecondsRemaining=$(($secondsRemaining * 1000))

    echo Starting YouTube stream $streamId for $((secondsRemaining / 60)) minutes
    echo Exposure settings: br: ${BRIGHTNESS:=70} contrast: ${CONTRAST:=75} ISO: ${ISO:=800} ev: ${EV:=0}
    echo Region of interest: $ROI
    echo Sleeping...
    sleep 20s
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
        -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -t $secondsRemaining -i /dev/zero \
        -re \
        -f h264 \
        -t $secondsRemaining \
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

    while [ $(($(date +%H) % 6)) != 5 ]:
    do
        echo Taking still picture
        modprobe v4l2_common && python bird-box.py
        echo Sleeping...
        sleep 20s
    done
done

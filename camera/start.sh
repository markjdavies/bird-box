# #!/bin/sh

echo Taking still picture
modprobe v4l2_common && python3 bird-box.py

streamData=$(python3 getCurrentStream.py)

if [ -z "$streamData" ]
then
    echo "No current broadcast found"
    streamStartHoursOffset=${STREAM_START_HOURS_OFFSET: 0} % 6
    currentHour=$(date +%H)
    streamEnd=$((((23 - ${streamStartHoursOffset} - $currentHour) % 6 ) + $currentHour)):59:00
    echo "Creating broadcast from now until $streamEnd"
    streamData=$( python3 create-broadcast.py \
        --broadcast-title "Bird Nesting Box" \
        --privacy-status "${PRIVACY_STATUS:=public}"  \
        --stream-title "Nesting Box Stream" \
        --description "Oxfordshire, UK" \
        --streamId ${FIXED_STREAM_ID} \
        --streamName ${FIXED_STREAM_NAME} \
        --end-time $streamEnd \
    )
    echo $streamData
    errorMessage=$(echo $streamData | jq '.error.message')
    if [ "$errorMessage" = "null" ]
    then
        echo Success
        echo "[$streamData]" > /schedule/streams.json
        streamName=$(echo $streamData | jq -r '.streamName')
        secondsRemaining=$(echo $streamData | jq -r '.timeRemaining')
    else
        echo $errorMessage
        echo Trying default stream
        streamName=${YOU_TUBE_API_KEY}
        secondsRemaining=21540
    fi
else
    streamName=$(echo $streamData | jq -r '.streamName')
    secondsRemaining=$(echo $streamData | jq -r '.timeRemaining')
fi
millisecondsRemaining=$(($secondsRemaining * 1000))
streamLength=$(date -d@$secondsRemaining -u +%H:%M:%S)

echo Starting YouTube stream $streamName for $streamLength
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
    -loglevel debug \
    -i - \
    -vcodec copy \
    -acodec aac \
    -ab 128k \
    -g 50 \
    -strict normal \
    -t $streamLength \
    -f flv rtmp://a.rtmp.youtube.com/live2/$streamName
echo Streaming finished

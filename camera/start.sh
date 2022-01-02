#!/bin/sh
vcdbg set awb_mode 0

echo Starting web server
python3 -m http.server -d /pics 80 > /dev/null 2>&1 &

echo listing drivers
lsmod

echo Taking still picture
modprobe v4l2_mem2mem && python3 bird-box.py

# streamData=$(python3 getCurrentStream.py)

if [ -z "$streamData" ]
then
    echo "No current broadcast found"
    streamStartHoursOffset=$((${STREAM_START_HOURS_OFFSET:=0} % 6))
    currentHour=$(date +%H)
    finishHour=$(((23 - streamStartHoursOffset - currentHour) % 6 + currentHour))
    streamEnd=$((finishHour)):59:00
    if [ $finishHour -lt "$currentHour" ]
    then
        finishDate=$(date -d "1 day" +%Y-%m-%d)
    else
        finishDate=$(date +%Y-%m-%d)
    fi
    echo "Creating broadcast from now until $finishDate $streamEnd"
    streamData=$( python3 create-broadcast.py \
        --broadcast-title "Bird Nesting Box" \
        --privacy-status "${PRIVACY_STATUS:=public}"  \
        --stream-title "Nesting Box Stream" \
        --description "Oxfordshire, UK - ${BALENA_RELEASE_HASH}" \
        --streamId "${FIXED_STREAM_ID}" \
        --streamName "${FIXED_STREAM_NAME}" \
        --end-time "$finishDate $streamEnd" \
    )
    echo "$streamData"
    errorMessage=$(echo "$streamData" | jq '.error.message')
    if [ "$errorMessage" = "null" ]
    then
        echo Success
        echo "[$streamData]" > /schedule/streams.json
        streamName=$(echo "$streamData" | jq -r '.streamName')
        secondsRemaining=$(echo "$streamData" | jq -r '.timeRemaining')
    else
        echo "$errorMessage"
        echo Trying default stream
        streamName=${YOU_TUBE_API_KEY}
        secondsRemaining=21540
    fi
else
    echo 'Found scheduled broadcast'
    echo "$streamData"
    streamName=$(echo "$streamData" | jq -r '.streamName')
    secondsRemaining=$(echo "$streamData" | jq -r '.timeRemaining')
fi
millisecondsRemaining=$((secondsRemaining * 1000))
streamLength=$(date -d@$secondsRemaining -u +%H:%M:%S)

echo "Starting YouTube stream $streamName for $streamLength"
echo "Exposure settings: br: ${BRIGHTNESS:=70} contrast: ${CONTRAST:=75} ISO: ${ISO:=800} ev: ${EV:=0}"
echo "Region of interest: $ROI"

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
    -nostats \
    -loglevel ${LOG_LEVEL:=info} \
    -i - \
    -vcodec copy \
    -acodec aac \
    -ab 128k \
    -g 50 \
    -strict normal \
    -t $streamLength \
    -f flv rtmp://a.rtmp.youtube.com/live2/$streamName
echo Streaming finished

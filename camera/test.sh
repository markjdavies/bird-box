    streamStartHoursOffset=$((${STREAM_START_HOURS_OFFSET:=0} % 6))
    currentHour=$(date -u +%H)
    finishHour=$(((23 - $streamStartHoursOffset - $currentHour) % 6 + $currentHour))
    streamEnd=$(($finishHour)):59:00
    echo $streamEnd
    if [ $finishHour -lt $currentHour ]
    then
        finishDate=$(date -d "1 day" +%Y-%m-%d)
    else
        finishDate=$(date +%Y-%m-%d)
    fi
    echo "Creating broadcast from now until $finishDate $streamEnd"
    streamData=$( python3 ./create-broadcast.py \
        --broadcast-title "Bird Nesting Box" \
        --privacy-status "${PRIVACY_STATUS:=public}"  \
        --stream-title "Nesting Box Stream" \
        --description "Oxfordshire, UK - ${BALENA_RELEASE_HASH}" \
        --streamId ${FIXED_STREAM_ID} \
        --streamName ${FIXED_STREAM_NAME} \
        --end-time "$finishDate $streamEnd" \
        --dry-run True \
        --auth-path ~/Desktop/birdbox-auth-secrets/
    )
    echo $streamData

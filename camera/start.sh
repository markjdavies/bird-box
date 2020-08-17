
if [$MODE=='STILL']
then
    modprobe v4l2_common && python bird-box.py &
    cd /data
    python -m http.server 80
else
    raspivid -o - -t 0 -w 1280 -h 720 -fps 25 -b 4000000 -g 50 | ffmpeg -re -ar 44100 -ac 2 -acodec pcm_s16le -f s16le -ac 2 -i /dev/zero -f h264 -i - -vcodec copy -acodec aac -ab 128k -g 50 -strict experimental -f flv rtmp://a.rtmp.youtube.com/live2/$YOUTUBE_KEY
fi

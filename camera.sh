#!/bin/bash
die() { echo "$@" 1>&2 ; exit 1; }
WEATHER=$(curl -sS -X GET 'http://api.openweathermap.org/data/2.5/weather?id=4371582&APPID=xxx')
echo "$WEATHER" > weather.json
echo "RAW JSON: $WEATHER" >> weather.log
LIVE=$(jq .weather[0].main weather.json)
ID=$(jq .weather[0].id weather.json)
LIVE=$(echo $LIVE | xargs)
ID=$(echo $ID | xargs)
OLD=$(cat weather.$ID)
echo "Last Run for $ID: $OLD" >> weather.log
echo $LIVE > weather.$ID
echo "Current Run For $ID: $LIVE" >> weather.log
# remove old file
rm -f raw.jpeg
rm -f snapshot.jpeg
rm -f snapshot.jpg
# download from camera
wget --user yyy --password xxx http://10.1.10.8/snapshot.cgi
# rename for web server use
cp snapshot.cgi raw.jpg
mv snapshot.cgi raw.jpeg
# watermark with date
convert -undercolor Black -pointsize 15 -fill white -draw  "text 0,240 '$LIVE by station $ID on $(date)'" raw.jpeg snapshot.jpeg
convert -undercolor Black -pointsize 15 -fill white -draw  "text 0,240 '$LIVE by station $ID on $(date)'" raw.jpg snapshot.jpg
# upload to webserver
sshpass -p xxx scp snapshot.jpeg root@towsonmaker.space:/var/www/html/snapshot.jpeg
sshpass -p xxx scp snapshot.jpg root@towsonmaker.space:/var/www/html/snapshot.jpg

if [ "$LIVE" == "$OLD" ]; then
        echo "FAIL: weather unchanged - $OLD is still $LIVE do not post" >> weather.log
        die "weather unchanged - $OLD is still $LIVE do not post"
fi

echo "PASS: weather changed from $OLD to $LIVE" >> weather.log
# post to facebook
sshpass -p xxx ssh root@towsonmaker.space "facebook-cli post --image=https://www.towsonmaker.space/snapshot.jpg 'Weather is now $LIVE in Towson, MD #towsonmakerspace'"
die "Run Complete"

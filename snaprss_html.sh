#!/bin/bash

# Request gps coordinates
echo "GPS coordinate inputs(exemple 0.000,0.000) :"
read lat_lon
lat=$(echo $lat_lon | sed 's/ //g' | cut -d ',' -f1)
lon=$(echo $lat_lon | sed 's/ //g' | cut -d ',' -f2)

epoch=$(curl -X POST "https://ms.sc-jpl.com/web/getLatestTileSet" -H "Content-Type: application/json" -d '{}' | jq -r .tileSetInfos[1].id.epoch)
# or grep -oE '{"type":"HEAT","flavor":"default","epoch":"[0-9]+"\}' | grep -o "[0-9]*")

curl -X POST "https://ms.sc-jpl.com/web/getPlaylist" -H "Content-Type: application/json" -d '{"requestGeoPoint": {"lat": '$lat', "lon": '$lon'}, "zoomLevel": 5, "tileSetId": {"flavor": "default", "epoch": "'$epoch'", "type": 1}, "radiusMeters": 1000, "maximumFuzzRadius": 0}' | jq '[.manifest.elements[] | {create_time: .timestamp, snap_id: .id, duration: .duration, file_type: .snapInfo.snapMediaType, url: .snapInfo.streamingMediaInfo.mediaUrl, mignature: .snapInfo.streamingThumbnailInfo.infos[].thumbnailUrl }]' > archive.json

sed -i -e 's/SNAP_MEDIA_TYPE_VIDEO_NO_SOUND/mp4/g' -e 's/SNAP_MEDIA_TYPE_VIDEO/mp4/g' -e 's/null/"jpg"/g' archive.json

jq -r '.[] | .create_time, .snap_id, .file_type, .url' archive.json > archive.json.tempo

nom_fichier="snap.html"

echo "<html>" > "$nom_fichier"
echo "<head>" >> "$nom_fichier"
echo "<title>SNAPRSS HTML</title>" >> "$nom_fichier"
echo "</head>" >> "$nom_fichier"
echo "<body>" >> "$nom_fichier"
echo "<h1>Report Snaprss</h1>" >> "$nom_fichier"

echo "<table border='1'>" >> "$nom_fichier"
echo "<tr><th>Snap html</th></tr>" >> "$nom_fichier"

#Work
while [ "$(wc -l < archive.json.tempo)" -gt 0 ];do
json=($(head -n 4 archive.json.tempo))
declare -a json
datesnap=$(echo ${json[0]} | cut -c 1-10)
realdate=$(date -d @$datesnap) # add 'u' for universal time UTC
# shorturl=$(echo ${json[3]} | rev | cut -c13- | rev)

if grep -q "${json[1]}" "snap.html";then #verification que l'id existe pas déjà
sed -i '1,4d' archive.json.tempo
else

sleep $((3 + RANDOM % 5))
echo "Work with, create time: ${json[0]}, snap id : ${json[1]}, file type : ${json[2]}, url : ${json[3]}"

curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" "https://www.snapchat.com/spotlight/${json[1]}" > urltempo  # /spotlight/ fonctionne aussi. avec www ou https://story.snapchat.com/o/
titre=$(grep -o '"title":"[^"]*"' urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ':' -f 2)
titre2=$(grep -o '"title":"[^"]*"' urltempo | head -n 1 | sed 's/"//g' | cut -d ':' -f 2)
pseudo=$(grep -o '"subtitle":"[^"]*"' urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ":" -f 2)
pseudo2=$(grep -o '"subtitle":"[^"]*"' urltempo | head -n 1 | sed 's/"//g' | cut -d ":" -f 2)
pageTitle=$(grep -o 'pageTitle":".[^"]*' urltempo | sed 's/pageTitle":"//' | sed 's/ | Our Story on Snapchat//' | sed 's/ | Spotlight on Snapchat//' | sed 's/| Spotlight on Snapchat//')
datareacthelmet=$(grep -o 'data-react-helmet="true">.[^<]*' urltempo | sed 's/data-react-helmet="true">//' | sed 's/ | Our Story on Snapchat//' | sed 's/|Spotlight on Snapchat//' | sed 's/ | Spotlight on Snapchat//')

if [ "${json[2]}" == "jpg" ];then
echo "<tr><td><img src=\"${json[3]}\"/><br >" >> "$nom_fichier"
else [ "${json[2]}" == "mp4" ];
echo "<tr><td><video controls width=\"1080\" height=\"1920\" src=\"${json[3]}\"/></video><br >" >> "$nom_fichier"
fi

if echo "$titre" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "Titre1 :<br >" >> "$nom_fichier"
else
echo "Titre1 : $titre<br >" >> "$nom_fichier"
fi
if echo "$titre2" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "Titre2 :<br >" >> "$nom_fichier"
else
echo "Titre2 : $titre2<br >" >> "$nom_fichier"
fi
if echo "$pseudo" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "Pseudo1 :<br >" >> "$nom_fichier"
else
echo "Pseudo1 : $pseudo<br >" >> "$nom_fichier"
fi

if echo "$pseudo2" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "Pseudo2 :<br >" >> "$nom_fichier"
else
echo "Pseudo2 : $pseudo2<br >" >> "$nom_fichier"
fi

if echo "$pageTitle" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "PageTitle :<br >" >> "$nom_fichier"
else
echo "PageTitle : $pageTitle<br >" >> "$nom_fichier"
fi

if echo "$datareacthelmet" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
echo "data-react-helmet :<br >" >> "$nom_fichier"
else
echo "data-react-helmet : $datareacthelmet<br >" >> "$nom_fichier"
fi

myliste=("$titre" "$titre2" "$pseudo" "$pseudo2" "$pageTitle" "$datareacthelmet")
last=""
for var in "${myliste[@]}"; do
if [[ "$var" != "$last" ]]; then
    echo "1 - $last = $var"
    if [[ ! $var =~ [[:space:]] && $var =~ ([a-z]|-_\.|[0-9]) && ! $var =~ [A-Z] ]]; then
    echo "Probable Owner: https://www.snapchat.com/add/$var<br >" >> "$nom_fichier"
    last="$var"
    echo "3 - $last = $var"
    fi
fi
done

sed -i '1,4d' archive.json.tempo
fi

echo "Source: https://story.snapchat.com/o/${json[1]}<br >" >> "$nom_fichier"
echo "Snap date : $realdate<br >" >> "$nom_fichier"
echo "</td></tr>" >> "$nom_fichier"
done
rm archive.json.tempo
echo "</table>" >> "$nom_fichier"

echo "</body>" >> "$nom_fichier"
echo "</html>" >> "$nom_fichier"

echo "New page html : $nom_fichier"

exit

#!/bin/bash
#"location" doit avoir LIEU + GEOLOCALISATION GPS + distance 500 / 1000 ou +
current_dir=$(dirname $(realpath -s $0))
var_location=$(awk 'NR % 3 == 1' $current_dir/location)
IFS=$'\n'
lines=($var_location)

#FOLDER CREATION WITH LOCATION FILE
for line in "${lines[@]}"; do
    if [ ! -d $current_dir/$line ]; then
    mkdir -p $line
    fi
done

# XML CREATION
if [ ! -f $current_dir/monitoring.xml ]; then
    touch "$current_dir/monitoring.xml"
fi

if [ $(wc -l < $current_dir/monitoring.xml) -lt 2 ]; then
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > $current_dir/monitoring.xml
    echo "<rss version=\"2.0\">" >> $current_dir/monitoring.xml
    echo "<channel>" >> $current_dir/monitoring.xml
    echo "<title>SNAPRSS</title>" >> $current_dir/monitoring.xml
    echo "<link>http://map.snapchat.com</link>" >> $current_dir/monitoring.xml
    echo "<description>The New snap</description>" >> $current_dir/monitoring.xml
fi

if grep -q "</rss>" $current_dir/monitoring.xml;then
sed -i '$d' $current_dir/monitoring.xml
sed -i '$d' $current_dir/monitoring.xml
fi

# UTILISATION DE SNAPMAP-ARCHIVER EN UTILISANT UN LOCATION TEMPO
cp "$current_dir/location" "$current_dir/tempo1"
cp "$current_dir/location" "$current_dir/tempo2"

while [ "$(wc -l < $current_dir/tempo1)" -gt 0 ];do
tempo=($(head -n 3 $current_dir/tempo1))
declare -a tempo
# {tempo[0]} : name {tempo[1]} : gps {tempo[2} distance

lat=$(echo ${tempo[1]} | sed 's/ //g' | cut -d ',' -f1)
lon=$(echo ${tempo[1]} | sed 's/ //g' | cut -d ',' -f2)

epoch=$(curl -s -X POST "https://ms.sc-jpl.com/web/getLatestTileSet" -H "Content-Type: application/json" -d '{}' | jq -r .tileSetInfos[1].id.epoch)
# or grep -oE '{"type":"HEAT","flavor":"default","epoch":"[0-9]+"\}' | grep -o "[0-9]*")

curl -s -X POST "https://ms.sc-jpl.com/web/getPlaylist" -H "Content-Type: application/json" -d '{"requestGeoPoint": {"lat": '$lat', "lon": '$lon'}, "zoomLevel": 5, "tileSetId": {"flavor": "default", "epoch": "'$epoch'", "type": 1}, "radiusMeters": '${tempo[2]}', "maximumFuzzRadius": 0}' | jq '[.manifest.elements[] | {create_time: .timestamp, snap_id: .id, duration: .duration, file_type: .snapInfo.snapMediaType, url: .snapInfo.streamingMediaInfo.mediaUrl, mignature: .snapInfo.streamingThumbnailInfo.infos[].thumbnailUrl }]' > $current_dir/${tempo[0]}/archive.json
sed -i -e 's/SNAP_MEDIA_TYPE_VIDEO_NO_SOUND/mp4/g' -e 's/SNAP_MEDIA_TYPE_VIDEO/mp4/g' -e 's/null/"jpg"/g' $current_dir/${tempo[0]}/archive.json

jq -r '.[] | .create_time, .snap_id, .file_type, .url' $current_dir/${tempo[0]}/archive.json > $current_dir/${tempo[0]}/archive.json.tempo

    if [ $(wc -l < $current_dir/${tempo[0]}/archive.json) -lt 2 ]; then
    echo "Le fichier archive.json de ${tempo[0]} n'a pas de nouveaux snaps"
    # si moins de 2 lignes pas de nouvelles données, suppression de archive.json.tempo.
    rm $current_dir/${tempo[0]}/archive.json.tempo
    else
    jq -r '.[] | .create_time, .snap_id, .file_type, .url' $current_dir/${tempo[0]}/archive.json > $current_dir/${tempo[0]}/archive.json.tempo
    fi

sleep $((5 + RANDOM % 10))
sed -i '1,3d' $current_dir/tempo1
done
rm $current_dir/tempo1

#Traitement monitoring$
while [ "$(wc -l < $current_dir/tempo2)" -gt 0 ];do
tempo=($(head -n 3 $current_dir/tempo2))
declare -a tempo
# echo "$tempo est en cours de traitement"

# si le fichier archive.json.tempo existe le script continue
if [ ! -f $current_dir/${tempo[0]}/archive.json.tempo ];then
sed -i '1,3d' $current_dir/tempo2

else
    echo "$tempo est en cours de traitement"
    while [ "$(wc -l < $current_dir/${tempo[0]}/archive.json.tempo)" -gt 0 ];do
            json=($(head -n 4 $current_dir/${tempo[0]}/archive.json.tempo)) # a modifier
            declare -a json
            datesnap=$(echo ${json[0]} | cut -c 1-10)
            datexml=$(date -Ru)
            realdate=$(date -d @$datesnap) # ajouter 'u' pour la date universel UTC
            shorturl=$(echo ${json[3]} | rev | cut -c13- | rev)
            #creation du tableau
                if grep -q "${json[1]}" $current_dir/monitoring.xml;then #verification que le fichier existe pas déjà
                sed -i '1,4d' $current_dir/${tempo[0]}/archive.json.tempo
                else

                sleep $((3 + RANDOM % 5))

                curl -o $current_dir/${tempo[0]}/${json[1]}.${json[2]} "${json[3]}"

                sleep $((3 + RANDOM % 7))

                curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" "https://www.snapchat.com/spotlight/${json[1]}" > $current_dir/${tempo[0]}/urltempo  #https://story.snapchat.com/o/
                title1=$(grep -o '"title":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ':' -f 2)
                title2=$(grep -o '"title":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 1 | sed 's/"//g' | cut -d ':' -f 2)

                subtitle1=$(grep -o '"subtitle":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ":" -f 2)
                subtitle2=$(grep -o '"subtitle":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 1 | sed 's/"//g' | cut -d ":" -f 2)
                pageTitle=$(grep -o 'pageTitle":".[^"]*' $current_dir/${tempo[0]}/urltempo | sed 's/pageTitle":"//' | sed 's/ | Our Story on Snapchat//' | sed 's/ | Spotlight on Snapchat//' | sed 's/| Spotlight on Snapchat//')
                datareacthelmet=$(grep -o 'data-react-helmet="true">.[^<]*' $current_dir/${tempo[0]}/urltempo | sed 's/data-react-helmet="true">//' | sed 's/ | Our Story on Snapchat//' | sed 's/|Spotlight on Snapchat//' | sed 's/ | Spotlight on Snapchat//')

                echo "<item>" >> $current_dir/monitoring.xml
                echo "<title>${tempo[0]} - ${json[1]}</title>" >> $current_dir/monitoring.xml
                echo "<link>$shorturl</link>" >> $current_dir/monitoring.xml
                    if [ "${json[2]}" == "jpg" ];then
                    echo -e '<description><![CDATA[<img src="\c' >> $current_dir/monitoring.xml
                    else [ "${json[2]}" == "mp4" ];
                    echo -e '<description><![CDATA[<iframe width="1080" height="1920" src="\c' >> $current_dir/monitoring.xml
                    fi
#local server OR nginx local server
#                   echo -e "http://127.0.0.1:8556/${tempo[0]}/${json[1]}.${json[2]}\c" >> $current_dir/monitoring.xml
#                   echo -e "http://localhost/snaprss/${tempo[0]}/${json[1]}.${json[2]}\c" >> $current_dir/monitoring.xml
                    echo '"/><br >' >> $current_dir/monitoring.xml

                if echo "$title1" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Title1 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Title1 : $title1<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$title2" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Title2 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Title2 : $title2<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$subtitle1" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Subtitle1 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Subtitle1 : $subtitle1<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$subtitle2" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Subtitle2 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Subtitle2 : $subtitle2<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$pageTitle" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "PageTitle :<br >" >> $current_dir/monitoring.xml
                else
                    echo "PageTitle : $pageTitle<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$datareacthelmet" | grep -Eq "'s Sound|Spotlight Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "data-react-helmet :<br >" >> $current_dir/monitoring.xml
                else
                    echo "data-react-helmet : $datareacthelmet<br >" >> $current_dir/monitoring.xml
                fi

                myliste=("$title1" "$title2" "$subtitle1" "$subtitle2" "$pageTitle" "$datareacthelmet")
                last=""
                    for var in "${myliste[@]}"; do
                    if [[ "$var" != "$last" ]]; then
                    if [[ ! $var =~ [[:space:]] && $var =~ ([a-z]|-_\.|[0-9]) && ! $var =~ [A-Z] ]]; then
                    echo "Probable Owner: https://www.snapchat.com/add/$var<br >" >> $current_dir/monitoring.xml
                    last="$var"
                            fi
                        fi
                    done

                echo "Source: https://www.snapchat.com/spotlight/${json[1]}<br >" >> $current_dir/monitoring.xml
                echo "Date du snap : $realdate" >> $current_dir/monitoring.xml

                echo -e "]]>\c" >> $current_dir/monitoring.xml
                echo -e "</description>\c" >> $current_dir/monitoring.xml
                echo "<pubDate>$datexml</pubDate>" >> $current_dir/monitoring.xml
                echo "</item>" >> $current_dir/monitoring.xml
                sed -i '1,4d' $current_dir/${tempo[0]}/archive.json.tempo
                #rm $current_dir/${tempo[0]}/urltempo
                fi
    done
sed -i '1,3d' $current_dir/tempo2
rm $current_dir/${tempo[0]}/archive.json.tempo
fi
done
rm $current_dir/tempo2

if ! grep -q "</rss>" $current_dir/monitoring.xml;then
echo "</channel>" >> $current_dir/monitoring.xml
echo "</rss>" >> $current_dir/monitoring.xml
fi
#timeout 60 python3 -m http.server 8556 --bind 127.0.0.1 -d $current_dir/
#pkill -9 -f 'python3 -m http.server'

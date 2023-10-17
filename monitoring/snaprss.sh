#!/bin/bash

current_dir=$(dirname $(realpath -s $0))
var_location=$(awk 'NR % 3 == 1' $current_dir/location)
IFS=$'\n'
lines=($var_location)

#FOLDER CREATION
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

cp "$current_dir/location" "$current_dir/tempo1"
cp "$current_dir/location" "$current_dir/tempo2"

while [ "$(wc -l < $current_dir/tempo1)" -gt 0 ];do
tempo=($(head -n 3 $current_dir/tempo1))
declare -a tempo

snapmap-archiver -o $current_dir/${tempo[0]}/ -l="${tempo[1]}" -r ${tempo[2]} --write-json
    if [ $(wc -l < $current_dir/${tempo[0]}/archive.json) -lt 2 ]; then
    echo "Le fichier archive.json n'a pas de nouveaux snaps"
        if [ -e $current_dir/${tempo[0]}/archive.json.tempo ]; then rm $current_dir/${tempo[0]}/archive.json.tempo; fi
    else
    jq -r '.[] | .create_time, .snap_id, .file_type, .url' $current_dir/${tempo[0]}/archive.json > $current_dir/${tempo[0]}/archive.json.tempo
    fi
sed -i '1,3d' $current_dir/tempo1
done
rm $current_dir/tempo1

#monitoring
while [ "$(wc -l < $current_dir/tempo2)" -gt 0 ];do
tempo=($(head -n 3 $current_dir/tempo2))
declare -a tempo
echo "$tempo est en cours de traitement"

# si le fichier archive.json.tempo existe le script continue
if [ ! -f $current_dir/${tempo[0]}/archive.json.tempo ];then
sed -i '1,3d' $current_dir/tempo2

else
    while [ "$(wc -l < $current_dir/${tempo[0]}/archive.json.tempo)" -gt 0 ];do
            json=($(head -n 4 $current_dir/${tempo[0]}/archive.json.tempo))
            declare -a json
            datesnap=$(echo ${json[0]} | cut -c 1-10)
            datexml=$(date -Ru)
            realdate=$(date -d @$datesnap) # add 'u' for universal TIME UTC
            shorturl=$(echo ${json[3]} | rev | cut -c13- | rev)

                if grep -q "${json[1]}" $current_dir/monitoring.xml;then
                sed -i '1,4d' $current_dir/${tempo[0]}/archive.json.tempo
                else
                curl -s "https://story.snapchat.com/o/${json[1]}" > $current_dir/${tempo[0]}/urltempo
                titre=$(grep -o '"title":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ':' -f 2)
                titre2=$(grep -o '"title":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 1 | sed 's/"//g' | cut -d ':' -f 2)

                pseudo=$(grep -o '"subtitle":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 2 | tail -n 1 | sed 's/"//g' | cut -d ":" -f 2)
                pseudo2=$(grep -o '"subtitle":"[^"]*"' $current_dir/${tempo[0]}/urltempo | head -n 1 | sed 's/"//g' | cut -d ":" -f 2)
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
                    echo -e "http://127.0.0.1:8556/${tempo[0]}/${json[1]}.${json[2]}\c" >> $current_dir/monitoring.xml
#                   echo -e "http://localhost/snaprss/${tempo[0]}/${json[1]}.${json[2]}\c" >> $current_dir/monitoring.xml
                    echo '"/><br >' >> $current_dir/monitoring.xml

                if echo "$titre" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Titre1 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Titre1 : $titre<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$titre2" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Titre2 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Titre2 : $titre2<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$pseudo" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Pseudo1 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Pseudo1 : $pseudo<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$pseudo2" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "Pseudo2 :<br >" >> $current_dir/monitoring.xml
                else
                    echo "Pseudo2 : $pseudo2<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$pageTitle" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "PageTitle :<br >" >> $current_dir/monitoring.xml
                else
                    echo "PageTitle : $pageTitle<br >" >> $current_dir/monitoring.xml
                fi

                if echo "$datareacthelmet" | grep -Eq "'s Sound|Our Story on Snapchat|OVF Editor|Created for Spotlight|Tap to try it out\!|Spotlight on Snapchat|Create My Bitmoji|Your identity on Snapchat"; then
                    echo "data-react-helmet :<br >" >> $current_dir/monitoring.xml
                else
                    echo "data-react-helmet : $datareacthelmet<br >" >> $current_dir/monitoring.xml
                fi

                myliste=("$titre" "$titre2" "$pseudo" "$pseudo2" "$pageTitle" "$datareacthelmet")
                    for var in "${myliste[@]}"; do
                    if [[ ! $var =~ [[:space:]] && $var =~ ([a-z]|-_\.|[0-9]) && ! $var =~ [A-Z] ]]; then
                        echo "Probable Owner: https://www.snapchat.com/add/$var<br >" >> $current_dir/monitoring.xml
                        fi
                    done

                echo "Source: https://story.snapchat.com/o/${json[1]}<br >" >> $current_dir/monitoring.xml
                echo "Date du snap : $realdate" >> $current_dir/monitoring.xml

                echo -e "]]>\c" >> $current_dir/monitoring.xml
                echo -e "</description>\c" >> $current_dir/monitoring.xml
                echo "<pubDate>$datexml</pubDate>" >> $current_dir/monitoring.xml
                echo "</item>" >> $current_dir/monitoring.xml
                sed -i '1,4d' $current_dir/${tempo[0]}/archive.json.tempo
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
timeout 60 python3 -m http.server 8556 --bind 127.0.0.1 -d $current_dir/
pkill -9 -f 'python3 -m http.server'

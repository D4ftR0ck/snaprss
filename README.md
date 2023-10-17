# snaprss_html.sh

A stand-alone program that requires the jq library and creates an array in an html page containing the elements.

Pivot from the snap snap_ID retrieved from the Snapmap.

https://www.snapchat.com/spotlight/(snap_ID)

https://www.snapchat.com/add/(User)

---

# snaprss.sh (monitoring)

When you retrieve a snap ID from the snapmap, you can identify the snap owner. Several identification elements are available on the snapchat web application.
I give 6 different elements that can provide information about the snap's user.

It can happen that "pseudo pseudo2 title or title 2" contain non-personal and advertising elements. I give a "probable identification" Everything is not fixed in the result. The other elements "pageTitle" and "datareacthelmet" are the most reliable.

My script gives the probable snap owner.

![Screenshot_20230921_232446](https://github.com/D4ftR0ck/snaprss/assets/86687768/6e93333f-7662-4ac2-9bb0-47d82b9a0109)

---

The data is then put into an XML file "monitoring.xml" which you can add to an rss feed aggregator.

My program requires the JQ librairy

An example is available in the location file. You can either use python's temporary html server or set up a local server with apache or nginx.

---

Install requierement :
- apt install jq

---

The scripts are self-contained and only require JQ. Originally I used the king-millez script: https://github.com/king-millez/snapmap-archiver
I thank him for what he created.

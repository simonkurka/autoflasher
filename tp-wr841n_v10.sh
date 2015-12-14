#!/usr/bin/env sh

# TP-Link Autoflasher for TL-WR841N v9 with firmware 3.16.9
#
# only use this if you understand what you are doing
# there are no safeguards against flashing bad images
#
# usage: ./autoflash.sh /full/path/to/firmware-image.bin
#
# alternatively, set a fixed path below

#FIRMWARE_PATH=$1
#FIRMWARE_PATH=/Users/macbook/Downloads/gluon-ffac-2014.4-stable-01-tp-link-tl-wr841n-nd-v9.bin
FIRMWARE_PATH=gluon-ffnw-0.7-tp-link-tl-wr841n-nd-v10.bin

ROUTER_IP=192.168.0.1

# this should not need to be changed, unless TP-Link once again
# thinks of a "clever" new security mechanism
COOKIE="Authorization=Basic%20YWRtaW46MjEyMzJmMjk3YTU3YTVhNzQzODk0YTBlNGE4MDFmYzM%3D"

echo -en "waiting for router to come up "
while ! ping -n -c 1 -W 2 192.168.0.1 > /dev/null; do
	echo -en "."
	sleep 1
done
echo " \o/"

# get "secret" session string
TPLINK_SESSION=$(curl --silent --cookie ${COOKIE} "${ROUTER_IP}/userRpm/LoginRpm.htm?Save=Save" | sed 's|.*/\([A-Z]*\)/.*|\1|' | head -n 1)
echo "Logged in, Session string: ${TPLINK_SESSION}"

# initiate FW update
echo "About to post firmware"
curl --cookie ${COOKIE} \
     --referer "http://${ROUTER_IP}/${TPLINK_SESSION}/userRpm/SoftwareUpgradeRpm.htm" \
     "${ROUTER_IP}/${TPLINK_SESSION}/incoming/Firmware.htm" \
     --form "Filename=@${FIRMWARE_PATH}" \
     --form "Upgrade=Upgrade" | grep --silent "system reboots"
if [ $? -eq 0 ]; then
	echo "Firmware-Upload OK"
	echo "Firmware sent. Router should flash and reboot. DO NOT DISCONNECT POWER!"
else
	echo 
	exit 4
fi

echo -en "waiting for router to come up again "
while ! ping -n -c 1 -W 2 192.168.1.1 > /dev/null; do
	echo -en "."
	sleep 1
done
echo " \o/"

FF_HOSTNAME=$(curl 'http://192.168.1.1/cgi-bin/luci/gluon-config-mode/' -H 'DNT: 1' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: http://192.168.1.1/cgi-bin/luci/gluon-config-mode/' -H 'Connection: keep-alive' --compressed | sed -E 's|.*id="cbid\.wizard\.1\._hostname" value="([A-Za-z0-9\-]*)" />.*\|.*|\1|' | sed '/^\s*$/d')

curl 'http://192.168.1.1/cgi-bin/luci/admin/remote' -H 'Origin: http://192.168.1.1' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryIrWPrYUKZ2NkTFKt' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://192.168.1.1/cgi-bin/luci/admin/remote' -H 'Connection: keep-alive' -H 'DNT: 1' --data-binary $'------WebKitFormBoundaryIrWPrYUKZ2NkTFKt\r\nContent-Disposition: form-data; name="cbi.submit"\r\n\r\n1\r\n------WebKitFormBoundaryIrWPrYUKZ2NkTFKt\r\nContent-Disposition: form-data; name="cbid.system._keys._data"\r\n\r\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAEAQDBXXFnzFb8JIZiXaEFafahs0Lq54KUlae3ysAPPpcDZcRok17Qem83LHN3avGxH2w62xwxJbnXjtnNz411UzXLAsnwSXbMB79k0gM0MlkGIac28Kq6NHSlJQwANsGlVbNiV4mRIy4wU6+TsxKpabXsWSBfluTymy6JpyTsipUwFyeNwSlmT+Nj8wI9/1L1EtbCXp5HLvELa91x8rceRiGWlO+h9Aa3tx5jkAswRz9M7HmV/yPUnF9/Mtux64ftEPPhfXQKo9/ZRwoCod8idwnfBAy8h9G09QaODTmtEhjG665on9yc4NTDbEPATDfXtRVJsBC0RCH4Iat7sHI6fpaqZr012AUlfKJyTi+ZnQr+8mDw5p7nuNemRplG2w+LgSu2W86/NoO5Uwb8n+vE173ltj8/OYB3LA2HIzJYNPKVrYqQcoykO2iBMZUoiKVY6Op2fR/1QXMzp2hsnV60Zvq3YwEqXXHj2ldJEVU8jnF/9JCRO379ygAudu8gIqblWjy0UN8CbrQDNT70r9xRr7iA6f8kqImXu+tH1lLM9VvZ8msoEfi+lWjbtQYpY/Rip1g75OAClCkMr7Gt6By3EzCII9/NWAimOGczK5dHWh997aXxpxsogyVPQC9PnitaRp0zp5lDruc4wRLXlREFo6gyp0yVxExz6rq9lpWQaN0hHAoazeGlnmY1H7FN+xGtuWXKu/rSHWDP3I+pPk9ASuJIJDNxXy8kzAPpT1qEVSLj1jPF7O0NBVZAcMX3DMhgNcWrUnJAny50Q7tU3X23U6LWKOSO1CnzqOXzOWJuZLoatr2eMBYcyeQZe8neAaUJxoKwmIPxIPhTDGuQFnOMzUSCERvYYNma89yAWaZ2EQHoEYehtsqQzvKgQlYoK6w+8PzXXBJNDQDZ4pmXZuHzT0dX7LCOJFkwcABk/zA5tQ8ziXERkF1u1iHgWujIwFwMun3MiAd4TLGK5IoF2vMiPmeeGhow9A4yq8mbM24wckSpujVXnQm6grH+7JKFokPm9t+ZRtTzHoP958v89B4ax5fPHbde43mfamqcAQXKqJrzvwifA5czU+KlW06CvZPnpNQPNaGsLEGy42aU4bv2T+frO/4pGGc90Dr5A0bSOcmsNQypabPLzJSlZ94EqZ8D04Jtptsg46wusXFAxRXbW1163oo3jYa67x/iiHhkYIu1L3Kty1kwd1aVLqxzcQ/oHDTiPRYlKH9e+RIc4hhXcVU+7j01B1lOGOBZPweoib8t0705CQjAOYiLzfT12qepFssJaT7d7eyTz/4d3XZlxGo1sdKVfFzDG0i9qnfb5nhYWuat39J1vhpI87lx6f1HpxSmpYo3ALPtqsMmIf5V4CQR simon@Nottebuck-Ubuntu\r\n------WebKitFormBoundaryIrWPrYUKZ2NkTFKt\r\nContent-Disposition: form-data; name="cbi.apply"\r\n\r\nAbsenden\r\n------WebKitFormBoundaryIrWPrYUKZ2NkTFKt--\r\n' --compressed > /dev/null
if [ $? -eq 0 ]; then
	echo "Remote-Access OK"
else
	exit 4
fi

curl 'http://192.168.1.1/cgi-bin/luci/gluon-config-mode' -H 'Origin: http://192.168.1.1' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryknZ6dhsxbyR56acS' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: http://192.168.1.1/cgi-bin/luci/gluon-config-mode/' -H 'Connection: keep-alive' -H 'DNT: 1' --data-binary $'------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbi.submit"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbid.wizard.1._hostname"\r\n\r\n'"${FF_HOSTNAME}"$'\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbi.cbe.wizard.1._meshvpn"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbid.wizard.1._meshvpn"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbi.cbe.wizard.1._limit_enabled"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbi.cbe.wizard.1._autolocation"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbid.wizard.1._autolocation"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbid.wizard.1._interval"\r\n\r\n1000\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbi.cbe.wizard.1._staticlocation"\r\n\r\n1\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS\r\nContent-Disposition: form-data; name="cbid.wizard.1._contact"\r\n\r\nfreifunk@simon.kurka.cc\r\n------WebKitFormBoundaryknZ6dhsxbyR56acS--\r\n' --compressed > /dev/null
if [ $? -eq 0 ]; then
	echo "Wizard OK"
else
	exit 4
fi

curl 'http://192.168.1.1/cgi-bin/luci/gluon-config-mode/reboot' -H 'DNT: 1' -H 'Accept-Encoding: gzip, deflate, sdch' -H 'Accept-Language: de-DE,de;q=0.8,en-US;q=0.6,en;q=0.4' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.80 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: http://192.168.1.1/cgi-bin/luci/gluon-config-mode/' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed > /dev/null
if [ $? -eq 0 ]; then
	echo "Reboot OK"
else
	exit 4
fi

exit 0

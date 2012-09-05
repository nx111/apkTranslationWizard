#!/bin/bash
#rem parameters: zipfile
#cd /home/esteban/Escritorio/lazarus
[ -d place-apk-here-for-modding ] || mkdir place-apk-here-for-modding
/usr/bin/7za -tzip e $1 -o./place-apk-here-for-modding @./FilesToTranslate.txt -y

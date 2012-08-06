#!/bin/bash
/bin/rm ./resources.arsc
/usr/bin/7za -tzip e $1 -o./ resources.arsc -y
/usr/bin/7za -tzip U $2 ./resources.arsc
/bin/rm ./resources.arsc
/bin/rm $1

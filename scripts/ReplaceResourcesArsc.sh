#!/bin/bash
rm ./resources.arsc
other/7za -tzip e $1 -o./ resources.arsc -y
other/7za -tzip U $2 ./resources.arsc
rm ./resources.arsc
rm $1

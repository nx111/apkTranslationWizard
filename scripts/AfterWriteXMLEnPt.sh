#!/bin/bash
mkdir ./projects/Launcher2.apk/res/xml-pt -p
/bin/sed -f ./Scripts/WorkSpacePt.sed "./projects/Launcher2.apk/res/xml/default_workspace.xml" > "./projects/Launcher2.apk/res/xml-pt/default_workspace.xml"

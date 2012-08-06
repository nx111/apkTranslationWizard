#!/bin/sh
#GTK
#solve scrollbar problem
#sudo apt-get remove --purge overlay-scrollbar liboverlay-scrollbar-0.*
/usr/bin/lazbuild ApkTranslationWizard.lpi --bm=BetaGTK2
/usr/bin/strip --strip-all ApkTranslationWizard-GTK2
/usr/bin/upx ApkTranslationWizard-GTK2
#QT
/usr/bin/lazbuild ApkTranslationWizard.lpi --bm=BetaQT
/usr/bin/strip --strip-all ApkTranslationWizard-QT
/usr/bin/upx ApkTranslationWizard-QT

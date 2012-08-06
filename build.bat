@echo off
rem the next line must be changed before run on your computer 
set lazpath=c:\Lazarus

set PATH=%PATH%;%lazpath%;

if not "%OS_TARGET%" == "" (
  set DC_ARCH=%DC_ARCH% --os=%OS_TARGET%
)
if not "%CPU_TARGET%" == "" (
  set DC_ARCH=%DC_ARCH% --cpu=%CPU_TARGET%
)


rem c:\lazarus\fpc\2.4.4\bin\i386-win32\make "ApkTranslationWizard.lpi" OS_TARGET=win32 CPU_TARGET=x86
c:\lazarus\lazbuild "ApkTranslationWizard.lpi" --bm=betaWin32 %DC_ARCH%
c:\lazarus\fpc\2.4.4\bin\i386-win32\strip -s ApkTranslationWizard.exe
upx ApkTranslationWizard.exe
copy ApkTranslationWizard.exe .\releases\win32\ /y
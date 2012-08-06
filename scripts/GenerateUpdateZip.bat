rem parameters: Update.zip 
.\other\7za -tzip a %1 .\update\* -r -y
rem del .\update\system\app\*.*
rem del .\update\system\framework\*.*
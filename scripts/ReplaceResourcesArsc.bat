del .\resources.arsc
.\other\7za -tzip e %1 -o.\ resources.arsc -y
.\other\7za -tzip U %2 .\resources.arsc -y
del .\resources.arsc
del %1
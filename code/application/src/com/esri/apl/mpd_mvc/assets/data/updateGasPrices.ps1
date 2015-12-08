# Change destFile to your desired destination and filename. This must be a fully qualified path.
$destPath = 'D:\Projects\2011_MilesPerDollar_NewUI\code\application\src\com\esri\apl\mpd_mvc\assets\data\'
$destFile = 'PET_PRI_GND_A_EPM0_PTE_DPGAL_W.xls'
$destFilePath = $destPath + $destFile
copy $destFilePath $destPath$destFile.old
$wclnt = new-object System.Net.WebClient
$wclnt.DownloadFile('http://www.eia.gov/dnav/pet/xls/PET_PRI_GND_A_EPM0_PTE_DPGAL_W.xls', $destFilePath)
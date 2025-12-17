# fix_asc.ps1
$inputFile  = "C:\Users\amgraber\Documents\02_GAMMA2\master_thesis\EAT8a1\grid.asc"
$outputFile = "C:\Users\amgraber\Documents\02_GAMMA2\master_thesis\EAT8a1\grid_fixed.asc"

(Get-Content $inputFile) |
ForEach-Object {
    if ($_ -match 'dx') {}
    elseif ($_ -match 'dy') { 'cellsize     5' }
    else { $_ }
} |
ForEach-Object {
    if ($_ -match '^cellsize') { $_; 'NODATA_value  -9999' }
    else { $_ }
} | Set-Content $outputFile
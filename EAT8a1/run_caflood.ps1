$workdir = Split-Path $MyInvocation.MyCommand.Path

# Run CAFlood directly
& "$workdir\caflood.exe" /sim "$workdir" eat8a.csv "$workdir\output" > "$workdir\caflood.log" 2>&1

Write-Output "CAFlood finished."
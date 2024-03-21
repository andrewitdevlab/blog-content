$disk = Get-WmiObject Win32_DiskDrive
$capacity = 0;
for($i = 0;$i -lt $disk.Count; $i++){
    $capacity = $capacity + [math]::round(($disk[$i].Size/1GB),2)
}
#("{0}GB" -f $capacity) | Out-File ("{0}\DiskCapacity.txt" -f [Environment]::GetFolderPath("MyDocuments"))
("{0}GB" -f $capacity) | Out-File ("{0}\DiskCapacity.txt" -f "C:\Users\SILCOCA0\Documents\POC")

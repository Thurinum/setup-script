$studentId = $env:UserName

$pathRoot = $null
$pathOneDrive = "C:\Users\${studentId}\OneDrive - Cégep Édouard-Montpetit\Startup\"
$pathLab = "\\laboratoire.collegeem.qc.ca\Stockage\usagers\Etudiants\${studentId}\Startup\"
$pathDesktop = "C:\Users\${studentId}\Desktop\Startup\" 

if (Test-Path $pathOneDrive) { 
	$pathRoot = $pathOneDrive
}
elseif (Test-Path $pathLab) {
	$pathRoot = $pathLab
}
elseif (Test-Path $pathDesktop) {
	$pathRoot = $pathDesktop
} 
else {
	Output "setup" "No storage available! Is user name '$studentId' correct?" Red
	Write-Host $pathOneDrive
}

$config = Get-Content "$pathRoot\config.ini" | ConvertFrom-StringData

Export-ModuleMember -Variable config
Export-ModuleMember -Variable studentId
Export-ModuleMember -Variable pathRoot
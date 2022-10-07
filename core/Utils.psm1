function Output {
	param (
		[String] $Category, 
		[String] $Message,
		[ConsoleColor] $Color, 

		[parameter(Mandatory = $false)]
		[switch] $NoNewline,

		[parameter(Mandatory = $false)]
		[switch] $NoAnimation
	)

	$header = if ($Category -eq "") { "" } else { "[$($Category.ToUpper())] " }
	$color = if ($PSBoundParameters.ContainsKey("Color")) { $Color } else { "White" }
	$newline = if (-not($PSBoundParameters.ContainsKey("NoNewLine"))) { "`n" } else { "" }
	$text = "$header$Message$newline"

	if ($PSBoundParameters.ContainsKey("NoAnimation")) {
		Write-Host $text -NoNewline -ForegroundColor $Color
		Start-Sleep -Milliseconds 50
		return
	}

	for ($i = 0; $i -lt $text.Length; $i++) {
		$c = $text[$i]

		Write-Host $c -NoNewline -ForegroundColor $Color
		Start-Sleep -Milliseconds 1
	}
}

function CheckForAdmin() {
	if (-Not((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
		Output "error" "Script must be run as admin. Aborting..." Red
		Start-Sleep -Seconds 2
		exit -1
	}
}

function GetRootPath() {
	$pathRoot     = $null
	$pathOneDrive = "C:\Users\${studentId}\OneDrive - C�gep �douard-Montpetit\Startup\"
	$pathLab      = "\\laboratoire.collegeem.qc.ca\Stockage\usagers\Etudiants\${studentId}\Startup\"
	$pathDesktop  = "C:\Users\${studentId}\Desktop\Startup\" 
	
	if (Test-Path $pathOneDrive) { 
	    Output "setup" "Using OneDrive for storage at '$pathOneDrive'." Yellow
	    $pathRoot = $pathOneDrive
	} elseif (Test-Path $pathLab) {
	    Output "setup" "Using Laboratoire storage at '$pathLab'." Yellow
	    $pathRoot = $pathLab
	} elseif (Test-Path $pathDesktop) {
	    Output "setup" "Using desktop for storage at '$pathDesktop'." Yellow    
	    $pathRoot = $pathFallback
	}
  
	return $pathRoot
  }

Export-ModuleMember -Function Output
Export-ModuleMember -Function CheckForAdmin
Export-ModuleMember -Function GetRootPath
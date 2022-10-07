function Output {
	param (
		[String] $Category, 
		[String] $Message,
		[ConsoleColor] $Color, 

		[parameter(Mandatory = $false)]
		[switch] $NoNewline,

		[parameter(Mandatory = $false)]
		[switch] $Animate
	)

	$header = if ($Category -eq "") { "" } else { "[$($Category.ToUpper())] " }
	$color = if ($PSBoundParameters.ContainsKey("Color")) { $Color } else { "White" }
	$newline = if (-not($PSBoundParameters.ContainsKey("NoNewLine"))) { "`n" } else { "" }
	$text = "$header$Message$newline"

	if ($PSBoundParameters.ContainsKey("Animate")) {
		for ($i = 0; $i -lt $text.Length; $i++) {
			$c = $text[$i]
	
			Write-Host $c -NoNewline -ForegroundColor $Color
			Start-Sleep -Milliseconds 1
		}
		return
	}

	Write-Host $text -NoNewline -ForegroundColor $Color
	Start-Sleep -Milliseconds 50
}

function CheckForAdmin() {
	if (-Not((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
		Output "error" "Script must be run as admin. Aborting..." Red
		Start-Sleep -Seconds 2
		exit -1
	}
}

Export-ModuleMember -Function *
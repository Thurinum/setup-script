Import-Module -Name $PSScriptRoot\Env

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

function Set-Env() {
	param(
		[String] $Name,
		[String] $Value
	)

	[Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Machine)
}

function Start-Operation() {
	param (
		[String] $Scope,
		[String] $Message,
		[PSObject] $Context,
		[ScriptBlock] $Action,
		[ScriptBlock] $OnError
	)

	Output -NoNewLine "$Scope" "$Message" Cyan

	$count = 0
	$job = Start-Job $Action -InputObject $Context

	while ($count -ne 3 -or (($job | Select-Object -Property JobStateInfo) | Out-String).Contains("Running")) {
		$char = "."

		if ($count -eq 3) {
			$char = "`b`b`b   `b`b`b"
			$count = 0
		}
		else {
			$count++
		}

		Output -NoNewline "" "$char" Cyan
		Start-Sleep -Seconds 0.5
	}

	$status = ($job | Select-Object -Property JobStateInfo) | Out-String

	if ($status.Contains("Blocked") -or $status.Contains("Failed")) {
		Invoke-Command -ScriptBlock $OnError
		Output "" " failed!" Red -Animate
	} else {
		Output "" " done." Cyan -Animate
	}
}

function UseBundle() {
	param(
		# name of the 7z archive, without extension
		[String] $name,

		# path to the output folder
		[String] $pathOutput,

		# path to the output executable
		[parameter(Mandatory = $false)]
		[String] $pathExec
	)
	#$path7z = "C:\Program Files\7-Zip\7zG.exe"
	$path7z = "C:\Program Files\Manually Installed\7-Zip\7z.exe"

	if (-not(Test-Path $path7z)) {
		Output "$name" "Cannot find a 7-zip installation at '$path7z'. Verify 7z path." Red
		return
	}

	if ($pathExec -and (Test-Path $pathExec)) {
		Output "$name" "Found already installed $name. Launching now..." Green
		try {
			Start-Process $pathExec 			
		}
		catch {
			Output "$name" "Failed to launch $name process!" Red
			return
		}
		return
	} 
	if (!$pathExec -and (Test-Path $pathOutput)) {
		Output "$name" "Found already installed $name. Skipping installation." Green
		return
	}

	$pathBundle = Join-Path $pathRoot "\software\$name.7z"

	if (-not(Test-Path $pathBundle)) {
		Output "$name" "Cannot find a bundle for $name in '$pathBundle'." Red
		return
	}
		
	$context = @($path7z, $pathBundle, $pathOutput)
	Start-Operation "$name" "Installing $name" -Context $context -Action {
		$arg = @($input)[0]	
		&"$($arg[0])" x "$($arg[1])" -o"$($arg[2])"	
	} -OnError {
		Output "$name" "Could not extract $name from archive '$pathBundle'. Are the paths correct?" Red
		return
	}

	$extraAction = ""

	if ($pathExec) {
		$extraAction = " Launching now..."
		try {
			Start-Process $pathExec
		}
		catch {
			Output "$name" "Failed to install $name process!" Red
			return
		}
	}

	Output "$name" "Successfully installed $name.$extraAction" Green
}

Export-ModuleMember -Function *
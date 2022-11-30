Import-Module -Name $PSScriptRoot\Utils
Import-Module -Name $PSScriptRoot\Env

# Set input language to US
function SetUSKeyboard() {
	Set-WinUserLanguageList -LanguageList en-US -Force
	Output "keyboard" "Set keyboard disposition to en-US." Green
}
  
# Set input language to FR
function SetFRKeyboard() {
	Set-WinUserLanguageList -LanguageList fr-CA -Force
	Output "keyboard" "Set keyboard disposition to fr-CA." Green
}
  
# Set dark theme
function SetDarkTheme() {
	try {
		Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
	}
	catch {
		Output "theme" "Could not enable dark theme: $_" Red
		return
	}
  
	Output "theme" "Enabled dark theme." Green
}

# Set Git user and email
function SetGitUser() {
	$email = If ($null -eq $config.email) {"$studentId@cegepmontpetit.ca"} Else {$config.email}

	git config --global user.name  $studentId
	git config --global user.email $email
	Output "git" "Set global username and email ($email)." Green
}

# Setup signing of Git commits using a GPG key (based on github.com/theodore-lheureux/setup-script)
function SetGitSigning() {
	$gnupg = "${pathRoot}software\GnuPG\bin\gpg.exe"

	Output "git" "Importing Git keys into gpg..." Cyan
	.$gnupg -q --import ${pathRoot}public.gpg
	.$gnupg -q --import ${pathRoot}private.gpg

	git config --global user.signingkey $config.keyid 
	git config --global commit.gpgsign true
	git config --global gpg.program $gnupg

	Output "git" "Setup signing of Git commits." Green
}
  
# Set a wallpaper from the wallpapers folder
function SetRandomWallpaper() {
	$pathWallpapers = "${pathRoot}wallpapers"

	try {
		Set-Location $pathWallpapers -ErrorAction Stop
	}
	catch {
		Output "theme" "Could not find wallpapers folder. Please place JPEG wallpapers in '$pathWallpapers'." Yellow
		return
	}

	if ([int](Get-ChildItem | Measure-Object).Count -eq 0) {
		Output "theme" "Wallpapers folder '$pathWallpapers' is empty. Please place JPEG wallpapers in it." Yellow
	}
  
	try {
		$count = [int](Get-ChildItem | Measure-Object).Count + 1
		$rand = Get-Random -Minimum 1 -Maximum $count
	}
	catch {
		Output "theme" "Could not generate random number: $_" Red
		return
	}

	$wallpaper = "$pathWallpapers\$rand.jpg"

	if (-not(Test-Path $wallpaper)) {
		Output "theme" "Wallpaper '$wallpaper' does not exist. Please number JPEG wallpapers in ascending order." Yellow
	}
  
	try {
		Set-ItemProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\" -Name "Wallpaper" -Value $wallpaper
		Stop-Process -Name explorer -Force
	}
	catch {
		Output "theme" "Could not set required registry key: $_" Red
		return
	}
  
	Output "theme" "Set wallpaper to $wallpaper." Green
}
  
# clean up VS Code by removing useless extensions
# idea credit: https://github.com/TheodoreLHeureux/setup-script
function CleanVSCode() {
	$pathVSCodeExtensions = "C:\Program Files\Microsoft VS Code\data\extensions\"
	$vscodeExtWhitelist = @(
		"editorconfig.editorconfig"
		"angular.ng-template"
		"syler.sass-indented"
<<<<<<< HEAD
		"haskell.haskell"
		"redhat.vscode-xml",
		"ms-vscode.powershell",
		"tobysmith568.run-in-powershell"
=======
		"redhat.vscode-xml",
		"ms-vscode.powershell",
		"tobysmith568.run-in-powershell",
		"github.copilot"
>>>>>>> 832f654417782236dfc4b89a2808fbb2301eec60
	)

	# remove unwanted extensions
	Output "vs code" "Uninstalling useless extensions..." Cya
	Remove-Item $pathVSCodeExtensions\* -Recurse -Force -ErrorAction SilentlyContinue
	
	# install wanted extensions
	Output -NoNewLine "vs code" "Installing new extensions...      " Cyan
  
	for ($i = 0; $i -lt $vscodeExtWhitelist.Length; $i++) {
		$progress = ([string]([math]::Round($($i + 1) * 100 / $vscodeExtWhitelist.Length))).PadLeft(3, " ")   
		code --force --install-extension $vscodeExtWhitelist[$i] > $null  
		Output -NoNewline "" "`b`b`b`b`b$progress %"
	}
 
	Write-Host
	Output "vs code" "Cleaned up VS Code extensions." Green
}
  
# Install the Qt framework
function SetupQt() {
	$path7z = "C:\Program Files\7-Zip\7zG.exe"
	$pathQt = "$($pathRoot)software"
	$pathQtBundle = "$($pathRoot)software\Qt.7z"
	$pathQtProject = "$($pathRoot)software\QtProject"
	$pathQtProjectOutput = "C:\Users\${studentId}\AppData\Roaming\QtProject"
	$pathQtCreator = "C:\Qt\Tools\QtCreator\bin\qtcreator.exe"

	if (-not(Test-Path $pathQtBundle)) {
		Output "qt" "Cannot find a bundled Qt installation at '$pathSrc'. Verify source path." Red
		return
	}
  
	if (-not(Test-Path $path7z)) {
		Output "qt" "Cannot find a 7-zip installation at '$path7z'. Verify 7z path." Red
		return
	}
  
	if (-not(Test-Path $pathQtCreator)) {
		try {
			Set-Location $pathQt
			Start-Process $path7z -ArgumentList "x Qt.7z -oC:\" -Wait
			Copy-Item ($pathQtProject) $pathQtProjectOutput -Recurse -Force
		}
		catch {
			Output "qt" "Could not extract Qt from archive. Are the paths correct?" Red
			return
		}
  
		Output "qt" "Setup Qt successfully, launching Qt Creator." Green
		Start-Process $pathQtCreator
	}
	else {
		Output "qt" "Found Qt Creator at ${pathQtCreator}, launching it..." Green
		Start-Process $pathQtCreator
	}
}

Export-ModuleMember -Function *
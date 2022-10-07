Import-Module -Name $PSScriptRoot\Utils

$studentId = $env:UserName
$pathRoot = GetRootPath

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
	git config --global user.name   $studentId
	git config --global user.email "$studentId@cegepmontpetit.ca"
	Output "git" "Set global username and email." Green
}
  
# Set a wallpaper from the wallpapers folder
function SetRandomWallpaper() {
	$pathWallpapers = "$pathRoot\wallpapers"

	try {
		Set-Location $pathWallpapers -ErrorAction Stop
	}
	catch {
		Output "wallpaper" "Could not find wallpapers folder. Please place JPEG wallpapers in '$pathWallpapers'." Yellow
		return
	}

	if ([int](Get-ChildItem | Measure-Object).Count -eq 0) {
		Output "wallpaper" "Wallpapers folder '$pathWallpapers' is empty. Please place JPEG wallpapers in it." Yellow
	}
  
	try {
		$count = [int](Get-ChildItem | Measure-Object).Count + 1
		$rand = Get-Random -Minimum 1 -Maximum $count
	}
	catch {
		Output "wallpaper" "Could not generate random number: $_" Red
		return
	}

	$wallpaper = "$pathWallpapers\$rand.jpg"

	if (-not(Test-Path $wallpaper)) {
		Output "wallpaper" "Wallpaper '$wallpaper' does not exist. Please number JPEG wallpapers in ascending order." Yellow
	}
  
	try {
		Set-ItemProperty "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\" -Name "Wallpaper" -Value $wallpaper
		Stop-Process -Name explorer -Force
	}
	catch {
		Output "wallpaper" "Could not set required registry key: $_" Red
		return
	}
  
	Output "wallpaper" "Set wallpaper to $rand.jpg." Green
}
  
# clean up VS Code by removing useless extensions
# idea credit: https://github.com/TheodoreLHeureux/setup-script
function CleanVSCode() {
	$pathVSCodeExtensions = "C:\Program Files\Microsoft VS Code\data\extensions\"
	$vscodeExtWhitelist = @(
		"editorconfig.editorconfig"
		"angular.ng-template"
		"syler.sass-indented"
		"haskell.haskell"
		"redhat.vscode-xml"
	)

	# remove unwanted extensions
	Output "vs code" "Uninstalling useless extensions..." Cya
	Remove-Item $pathVSCodeExtensions\* -Recurse -Force -ErrorAction SilentlyContinue
	
	# install wanted extensions
	Output -NoNewLine "vs code" "Installing new extensions...   0 %" Cyan
  
	for ($i = 0; $i -lt $vscodeExtWhitelist.Length; $i++) {
		$progress = ([string]([math]::Round($i * 100 / $vscodeExtWhitelist.Length))).PadLeft(3, " ")   
		code --force --install-extension $vscodeExtWhitelist[$i] > $null  
		Output -NoNewline "" "`b`b`b`b`b$progress %"
	}
 
	Write-Host
	Output "vs code" "Cleaned up VS Code extensions." Green
}
  
# Install the Qt framework
function SetupQt() {
	$path7z = "C:\Program Files\7-Zip\7zG.exe"
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
			Copy-Item ($pathQtProject) $pathQtProjectOutput -Recurse -Force
			Start-Process $path7z -ArgumentList "x $pathQtBundle -oC:\" -Wait
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
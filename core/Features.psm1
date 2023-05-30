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
	$pathVSCodeExtensions = $config.vscodeExtensionsPath
	$vscodeExtWhitelist = $($config.vscodeExtensions).Split(",")

	Stop-Process -Name "code" -ErrorAction SilentlyContinue

	# remove unwanted extensions
	Start-Operation -Scope "vs code" -Message "Uninstalling useless extensions" -Context @($pathVSCodeExtensions) -Action {
		$arg = @($input)[0]
		Remove-Item -Path "$($arg[0])*" -Recurse -Force -ErrorAction SilentlyContinue
	}

	# install wanted extensions
	if ($config.vscodeExtensionsUseCache -eq "true") {
		UseBundle "VSCodeExtensions" "$pathVSCodeExtensions"
	} else {
		Output -NoNewLine "vs code" "Installing new extensions...      " Cyan
  
		for ($i = 0; $i -lt $vscodeExtWhitelist.Length; $i++) {
			$progress = ([string]([math]::Round($($i + 1) * 100 / $vscodeExtWhitelist.Length))).PadLeft(3, " ")   
			code --force --install-extension $vscodeExtWhitelist[$i] > $null  
			Output -NoNewline "" "`b`b`b`b`b$progress %"
		}

		Write-Host
	}	

	Start-Process "code"
 
	Output "vs code" "Cleaned up VS Code extensions." Green
}

# Install IntelliJ IDEA, the Android SDK version 33, and an Android emulator image
function Install-Android() {
	$homePath = "C:\Users\${studentId}"
	
	Set-Env "ANDROID_HOME" "$homePath\AppData\Local\Android\Sdk"
	Set-Env "ANDROID_ROOT" "$homePath\AppData\Local\Android\Sdk"
	Set-Env "ANDROID_AVD_HOME" "$homePath\.android"

	UseBundle "IntelliJ" "C:\JetBrains\apps" "C:\JetBrains\apps\IDEA-U\ch-0\223.8617.56\bin\idea64.exe"
	UseBundle "AndroidSdk" "$homePath\AppData\Local\Android"
	UseBundle "AndroidEmulator" "$homePath\.android\avd"
	UseBundle "GradleCache" "$homePath\.gradle"
}

# Install the Flutter SDK alongside IntelliJ IDEA, the Android SDK version 33, and an Android emulator image
function Install-Flutter() {
	$flutterPath = "C:\Users\${studentId}\Flutter"

	Install-Android
	Set-Env "PATH" "${Env:PATH};$flutterPath"
	UseBundle "Flutter" "$flutterPath"

	try {
		flutter --disable-telemetry
	}
	catch {
		Output "flutter" "Failed to install Flutter." Red
		return
	}

	Output "flutter" "Installing the Android SDK manager..." Cyan
	Start-Process "C:\Users\${studentId}\AppData\Local\Android\Sdk\tools\bin\sdkmanager.bat" -ArgumentList "--install `"cmdline-tools;latest`"" -Wait

	Output "flutter" "Accepting Flutter's Google evil megacorp licenses..." Cyan
	Start-Process "C:\Users\${studentId}\AppData\Local\Android\Sdk\tools\bin\sdkmanager.bat" -ArgumentList "--licenses" -Wait

	Output "flutter" "Flutter installed successfully. Running Flutter doctor..." Cyan
	flutter doctor
}

# Install the Qt framework
function Install-Qt() {
	$pathQtProject = "$($pathRoot)software\QtProject"
	$pathQtProjectOutput = "C:\Users\${studentId}\AppData\Roaming\QtProject"

	UseBundle "Qt" "C:\" "C:\Qt\Tools\QtCreator\bin\qtcreator.exe"
	Copy-Item ($pathQtProject) $pathQtProjectOutput -Recurse -Force
}

Export-ModuleMember -Function *
# ====================================================================== Maxime Gagnon ==
# Automated utility for configuring CEM stations                                 v.2.0
# =======================================================================================

Import-Module -Name $PSScriptRoot\core\Utils.psm1
Import-Module -Name $PSScriptRoot\core\Features.psm1

# 	 basic	function name 		description
$features = 
	($true,	"SetFRKeyboard", 		"Change keyboard layout to FR"),
	($false,	"SetUSKeyboard", 		"Change keyboard layout to US"),
    	($false, 	"SetGitUser", 		"Set the git user and email"),
    	($false, 	"SetDarkTheme", 		"Enable dark mode"),
    	($false, 	"SetRandomWallpaper", 	"Set a random wallpaper"),
    	($false, 	"CleanVSCode", 		"Clean up the mess of vs code"),
    	($true, 	"SetupQt", 			"Setup the Qt framework and launch Qt Creator")

# Show main menu
function ShowMenu() {
	Output "welcome" "$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`n" Cyan
	Output -NoAnimation "A" "Execute common tweaks"
	Output -NoAnimation "B" "Execute everything"
	Output -NoAnimation "C" "Execute individual tweaks"
	Output -NoAnimation "Q" "Never mind"
  
	$userInput = Read-Host "`n    Choose an option"
	Write-Host ""
  
	switch ($userInput) {
		{ $_ -in 'b', 'B' } {
			foreach ($feature in $features) {                                      
				Invoke-Expression $feature[0]
			}           
			break    
		}
		{ $_ -in 'a', 'A' } {
			foreach ($feature in $features) {
				# skip features marked as uncommon
				if ($feature[0] -eq $true) {
					continue 
				}   
  
				Invoke-Expression $feature[1]
			}
			break        
		}
		{ $_ -in 'c', 'C' } {
			Write-Host ""
			Output "advanced tweaks" "`n" Cyan
			ShowAdvancedMenu
			break
		}
		{ $_ -in 'q', 'Q' } {
			Output "done" "Goodbye." Cyan
			exit 0
		}
		Default {
			Output "error" "Invalid input '$userInput'.`n`n" Yellow
			ShowMenu
			break
		}
	}
  
	ConfirmMenu
}
  
# Show individual selection menu
function ShowAdvancedMenu() {
	for ($i = 0; $i -lt $features.Length; $i++) {
		Output -NoAnimation "$($i)" $features[$i][2]
	}
	Output -NoAnimation "Q" "Go back"
  
	# get user input
	$userInput = Read-Host "`n    Choose an option"
	Write-Host ""
  
	if ($userInput -in 'q', "Q") {
		ShowMenu 
		return
	}
  
	# sanitize input
	try {
		$userInput = [int]$userInput
	}
	catch {
		Output "error" "Invalid input '$userInput'.`n`n" Yellow
		ShowAdvancedMenu
		return
	}
  
	if (!(($userInput -ge 0) -and ($userInput -lt $features.Length))) {
		Output "error" "Invalid input '$userInput'.`n`n" Yellow
		ShowAdvancedMenu
		return
	}
  
	# run associated command from $features array (see Features section)
	Invoke-Expression $features[$userInput][1]
}
  
# Ask for confirm after applying changes
function ConfirmMenu() {
	$userInput = Read-Host "`n[Y/N] Is that all?"
  
	switch ($userInput) {
		{ $_ -in 'y', 'Y', 'yes', 'yea', 'yeah', 'ay', 'si' } {
			Output "done" "Goodbye." Cyan
			exit 0
		}
		Default {
			ShowMenu
			Break
		}
	}
}

Set-StrictMode -Version 3.0
CheckForAdmin
ShowMenu
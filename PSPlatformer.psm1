Set-StrictMode -Version Latest

. "$($PSScriptRoot)\Enums\GameState.ps1"

. "$($PSScriptRoot)\Classes\Player.ps1"

. "$($PSScriptRoot)\Public\Variables.ps1"

. "$($PSScriptRoot)\Public\Functions.ps1"

# . "$($PSScriptRoot)\Public\Start-PSPlatformer.ps1"

Export-ModuleMember -Function Start-PSPlatformer
using namespace System
using namespace System.Collections.Generic

Set-StrictMode -Version Latest

<#
.SYNOPSIS
TRANSITIONS THE CURRENT STATE OF THE GAME TO THE ONE SPECIFIED BY THE CALLER,
ENSURING THE PREVIOUS STATE IS RETAINED.

.PARAM NextState
THE NEW STATE TO TRANSITION TO. BOUND TO THE ENUMERATION GAMESTATE.
#>
Function Set-NextGameState {
    Param(
        [GameState]$NextState
    )
    
    $Script:PreviousGlobalState = $Script:GlobalState
    $Script:GlobalState         = $NextState
}

<#
.SYNOPSIS
"RENDERS" AND DRAWS A "FRAME" TO THE TERMINAL SCREEN.
#>
Function Draw-Screen {    
    [Console]::SetCursorPosition(0, 0)
    
    [List[String]]$Frame = [List[String]]::new()

    For([Int]$Y = 0; $Y -LT $Script:MapHeight; $Y++) {
        [Char[]]$Line       = $Script:LevelData[$Script:CurrentLevel][$Y].ToCharArray()
        [String]$AddToFrame = ''
        
        # DRAW PLAYER IF ON THIS LINE
        If($Y -EQ $Script:ThePlayer.Y) {
            If($Script:ThePlayer.X -GE 0 -AND $Script:ThePlayer.X -LT $Line.Length) {
                $Line[$Script:ThePlayer.X] = $Script:ThePlayer.Symbol
            }
            $AddToFrame = "$(Format-ConsoleColor24 -Color $Script:ThePlayer.LineColor -Type Fg)"
        }
        
        $Frame.Add([String]::new("$($AddToFrame)$([String]::new($Line))"))
    }

    $Frame.Add("$($Script:MapNames[$Script:CurrentLevel])")
    $Frame.Add("POS: $($Script:ThePlayer.X),$($Script:ThePlayer.Y) | SPACE: Jump | Q: Quit ")
    
    ForEach($L in $Frame) {
        If($L -MATCH 'X') {
            Write-Host $L -ForegroundColor Yellow -NoNewline
        } ElseIf($L -MATCH $Script:ThePlayer.Symbol) { 
            Write-Host $L -NoNewLine
        } Else {
            Write-Host $L -ForegroundColor Gray -NoNewline
        }
        
        Write-Host ''
    }
}

<#
.SYNOPSIS
PERFORMS COLLISION DETECTION WITH DIFFERENT CHARACTERS IN ADJACENT CELLS.

.PARAM X
THE "NEXT X" TO CHECK FOR A COLLISION AGAINST.

.PARAM Y
THE "NEXT Y" TO CHECK FOR A COLLISION AGAINST.
#>
Function Test-Collision {
    Param(
        [Int]$X,
        [Int]$Y
    )

    If($Y -LT 0 -OR $Y -GE $Script:MapHeight -OR $X -LT 0 -OR $X -GE $Script:MapWidth) {
        Return $true
    }
    
    [Char]$C = $Script:LevelData[$Script:CurrentLevel][$Y][$X]
    
    If($C -EQ 'X') {
        Start-SfxPlayback "$($PSScriptRoot)\..\Resources\SFX\Pickup\Pickup0001.wav" $Script:GoalSfxPlaying
        Set-NextGameState GameWin

        Return $false
    }
    
    If($C -EQ '^') {
        Start-SfxPlayback "$($PSScriptRoot)\..\Resources\SFX\Damage\Damage029.wav" $Script:DamageSfxPlaying
        Set-NextGameState GameLose
        
        Return $false
    }

    If($C -EQ '#') {
        Return $true
    }
    
    Return $false
}

<#
.SYNOPSIS
PRIMES THE SFX PLAYER TO PLAY A SOUND EFFECT.

.PARAM FILELOCATION
THE LOCATION OF A WAV FILE TO LOAD INTO THE SFX PLAYER.

.PARAM PLAYBACKFLAG
THE PLAYBACK FLAG TO TOGGLE WHEN PLAYING THE WAVE FILE.
#>
Function Start-SfxPlayback {
    Param(
        [String]$FileLocation,
        [Boolean]$PlaybackFlag
    )

    Switch($Script:PwshEdition) {
        'Desktop' {
            If($PlaybackFlag -EQ $false) {
                Invoke-SfxPlayer $FileLocation
                $PlaybackFlag = $true
            }

            Break
        }

        'Core' {
            If($IsWindows -EQ $true -AND $PlaybackFlag -EQ $false) {
                Invoke-SfxPlayer $FileLocation
                $PlaybackFlag = $true
            }

            Break
        }

        Default {
            Break
        }
    }
}

<#
.SYNOPSIS
STOPS THE SFX PLAYER, REGARDLESS OF WHAT'S PLAYING.

.PARAM PLAYBACKFLAG
THE PLAYBACK FLAG TO TOGGLE WHEN STOPPING THE SFX PLAYER.
#>
Function Stop-SfxPlayback {
    Param(
        [Boolean]$PlaybackFlag
    )

    Switch($Script:PwshEdition) {
        'Desktop' {
            $PlaybackFlag = $false

            Break
        }
        
        'Core' {
            If($IsWindows -EQ $true) {
                $PlaybackFlag = $false
            }

            Break
        }

        Default {
            Break
        }
    }
}

<#
.SYNOPSIS
ACTUALLY PLAYS A WAV FILE.

.PARAM FILELOCATION
A FILE TO LOAD INTO THE SFX PLAYER TO PLAY.
#>
Function Invoke-SfxPlayer {
    Param(
        [String]$FileLocation
    )

    If($null -NE $Script:SfxPlayer) {
        $Script:SfxPlayer.SoundLocation = $FileLocation
        $Script:SfxPlayer.LoadAsync()
        $Script:SfxPlayer.Play()
    }
}

<#
.SYNOPSIS
STARTS THE PSPLATFORMER GAME.
#>
Function Start-PSPlatformer {
    Clear-Host; Write-Host "`e[?25l"
 
    While($Script:Running -EQ $true) {
        $Script:FrameStartMs = $Script:TheTicker.ElapsedTicks
        
        & $Script:TheGameStateTable[$Script:GlobalState]

        Draw-Screen

        $Script:FrameEndMs   = $Script:TheTicker.ElapsedTicks
        $Script:FrameDelayMs = $Script:FrameMs - ($Script:FrameEndMs - $Script:FrameStartMs)
        
        Start-Sleep -Milliseconds $Script:FrameDelayMs
    }
    
    Clear-Host
}
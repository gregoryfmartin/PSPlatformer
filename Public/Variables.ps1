using namespace System
using namespace System.Diagnostics

Set-StrictMode -Version Latest

[Int]     $Script:GRAVITY          = 1
[Int]     $Script:JUMP_STRENGTH    = -4
[Int]     $Script:MAX_FALL_SPEED   = 1
[Int]     $Script:CurrentLevel     = -1
[Int]     $Script:MapHeight        = 0
[Int]     $Script:MapWidth         = 0
[Int]     $Script:TargetFps        = 30
[Boolean] $Script:Running          = $true
[Boolean] $Script:JumpSfxPlaying   = $false
[Boolean] $Script:DamageSfxPlaying = $false
[Boolean] $Script:GoalSfxPlaying   = $false
[Float]   $Script:TargetFrameTicks = 1000.0 / $Script:TargetFps
[Float]   $Script:CurrentFps       = 0.0
[TimeSpan]$Script:FrameDelta       = [TimeSpan]::new(0)
[Long]    $Script:FrameStart       = 0
[Long]    $Script:FrameEnd         = 0
[Double]  $Script:SleepTime        = 0

[GameState]$Script:GlobalState         = [GameState]::Init
[GameState]$Script:PreviousGlobalState = $Script:GlobalState

[Object]$Script:SfxPlayer = $null

[String]$Script:PwshEdition = $PSVersionTable.PSEdition

[Hashtable]$Script:TheGameStateTable = @{}

[Stopwatch]$Script:TheTicker = [Stopwatch]::new()

. "$($PSScriptRoot)\LevelData.ps1"

[ScriptBlock]$Script:GameStateInitAction = {
    # SETUP THE GAME HERE
    Switch($PwshEdition) {
        'Desktop' {
            # THIS VERSION ONLY RUNS ON WINDOWS, SO WE DON'T NEED TO CHECK FOR OS SHIT HERE
            Add-Type -AssemblyName PresentationCore
            $Script:SfxPlayer = [System.Media.SoundPlayer]::new()

            Break
        }

        'Core' {
            # THIS VERSION CAN RUN ANYWHERE, SO WE NEED TO CHECK THE OS
            If($IsWindows -EQ $true) {
                Add-Type -AssemblyName PresentationCore
                $Script:SfxPlayer = [System.Media.SoundPlayer]::new()
            }

            # PRESENTATIONCORE WON'T WORK ON ANYTHING OTHER THAN WINDOWS, SO WE NEED DIFFERENT AUDIO
            # PLAYBACK MECHANISMS HERE.

            Break
        }

        Default {
            # DO NOTHING HERE
            Break
        }
    }

    # NON-OS SPECIFIC INIT CODE HERE

    Set-NextGameState SetupMap
}

[ScriptBlock]$Script:GameStateSetupMapAction = {
    # INCREMENT THE LEVEL COUNTER
    $Script:CurrentLevel += 1
    
    # GENERATE THE DIMENSIONS DATA
    $Script:MapHeight = $Script:LevelData[$Script:CurrentLevel].Count
    $Script:MapWidth  = $Script:LevelData[$Script:CurrentLevel][0].Length

    # RUN THE LOGIC THAT CONFIGURES THE (CURRENT) MAP
    # REALLY, ALL WE'RE DOING HERE IS ENSURING THAT THE START POSITION
    # CHARACTER IN THE MAP IS REMOVED SO THAT WE DON'T CAUSE A PROBLEM
    # WHEN STARTING THE (CURRENT) MAP.
    
    For([Int]$R = 0; $R -LT $Script:MapHeight; $R++) {
        If($Script:LevelData[$Script:CurrentLevel][$R].Contains('!')) {
            $Script:ThePlayer.Y = $R
            $Script:ThePlayer.X = $Script:LevelData[$Script:CurrentLevel][$R].IndexOf('!')

            # REMOVE @ FROM MAP DATA SO WE DON'T COLLIDE WITH OUR SPAWN POINT
            $Script:LevelData[$Script:CurrentLevel][$R] = $Script:LevelData[$Script:CurrentLevel][$R].Replace('!', ' ')
        }
    }
    
    # CLEAR THE LEVEL STATUS LINE
    [Console]::SetCursorPosition(0, $Script:MapHeight + 2); Write-Host '          '
    
    # TRANSITION TO THE NEXT STATE
    Set-NextGameState GameLoop
}

[ScriptBlock]$Script:GameStateGameLoopAction = {
    $Key = $null
    If([Console]::KeyAvailable -EQ $true) {
        $Key = [Console]::ReadKey($true).Key

        While([Console]::KeyAvailable -EQ $true) {
            $Dummy = [Console]::ReadKey($true)
        }
    }

    If($Key -EQ "Q") {
        # CHANGE THE GAME STATE TO GAMELOSE
        # I KNOW, THE PLAYER DIDN'T ACTUALLY LOSE,
        # BUT THEY NEED TO FEEL BAD FOR QUITTING.
        # WE AVOID TERMINATING THE GAME LOOP HERE
        # BECAUSE THAT'S NOT WHAT THIS STATE SHOULD
        # BE DOING.
        Set-NextGameState GameLose
    }

    # HORIZONTAL MOVEMENT
    If($Key -EQ "LeftArrow") {
        $Script:ThePlayer.VX = -1
    } ElseIf($Key -EQ "RightArrow") {
        $Script:ThePlayer.VX = 1
    } Else {
        $Script:ThePlayer.VX = 0
    }

    # APPLY HORIZONTAL VELOCITY
    [Int]$NextX = $Script:ThePlayer.X + $Script:ThePlayer.VX
    If(-NOT (Test-Collision $NextX $Script:ThePlayer.Y)) {
        $Script:ThePlayer.X = $NextX
    }

    # VERTICAL MOVEMENT (GRAVITY)
    $Script:ThePlayer.VY += $Script:GRAVITY
    
    # CAP FALLING SPEED
    If($Script:ThePlayer.VY -GT $Script:MAX_FALL_SPEED) {
        $Script:ThePlayer.VY = $Script:MAX_FALL_SPEED
    }

    # JUMP HANDLER
    If($Key -EQ "Spacebar" -AND $Script:ThePlayer.IsGrounded) {
        # CHECK FOR A FLOOR DIRECTLY ABOVE THE PLAYER
        # THIS IS PROBABLY A REALLY BAD WAY TO CHECK FOR THIS STATE,
        # BUT IDGAF
        
        # BIIIIIG NOPE HERE! LOOK DOWN!
        # STILL HAVE THE N + 2 BUG WITH THE JUMPING. I DIDN'T WANT TO DO THIS,
        # BUT I THINK I'LL HAVE TO CHECK THE ENTIRE PROJECTED SEGMENT FOR COLLISIONS
        If((Test-Collision $Script:ThePlayer.X ($Script:ThePlayer.Y - 1)) -EQ $false) {
            Start-SfxPlayback "$($PSScriptRoot)\..\Resources\SFX\Jump\Jump0001.wav" $Script:JumpSfxPlaying

            $Script:ThePlayer.VY         = $Script:JUMP_STRENGTH
            $Script:ThePlayer.IsGrounded = $false
        }
    }

    # APPLY VERTICAL VELOCITY
    # COMMENTED OUT. WE'RE STEPPING INDIVIDUAL CELLS TO ENSURE
    # MID JUMPS ARE SUPPORTED.
    # [Int]$NextY = $Script:ThePlayer.Y + $Script:ThePlayer.VY
    [Int]$NextY = $Script:ThePlayer.Y + [Math]::Sign($Script:ThePlayer.VY)
    
    # VERTICAL COLLISION DETECTION ATTEMPT...
    If(Test-Collision $Script:ThePlayer.X $NextY) {
        # MOVING DOWN...
        If($Script:ThePlayer.VY -GT 0) {
            $Script:ThePlayer.IsGrounded = $true

            Stop-SfxPlayback $Script:JumpSfxPlaying
        }

        # MOVING UP...
        $Script:ThePlayer.VY = 0 
    } Else {
        $Script:ThePlayer.Y          = $NextY
        $Script:ThePlayer.IsGrounded = $false
    }
    
    # PERFORM ANIMATION LOGIC UPDATES
    $Script:ThePlayer.Symbol.Update()
}

[ScriptBlock]$Script:GameStateGameWinAction = {
    Stop-SfxPlayback $Script:GoalSfxPlaying
    
    [Console]::SetCursorPosition(0, $Script:MapHeight + 2); Write-Host 'GOT ''EM!' -ForegroundColor Green
    
    If($Script:CurrentLevel -LT $Script:LevelData.Length - 1) {
        Start-Sleep -Seconds 1.0
        Set-NextGameState SetupMap
    } Else {
        Set-NextGameState Deinit
    }
}

[ScriptBlock]$Script:GameStateGameLoseAction = {
    Stop-SfxPlayback $Script:DamageSfxPlaying
    
    [Console]::SetCursorPosition(0, $Script:MapHeight + 2); Write-Host 'YOU SUCK!' -ForegroundColor Red

    Start-Sleep -Seconds 1.0
    
    Clear-HostFancily -Mode Flipping
    Set-NextGameState Deinit
}

[ScriptBlock]$Script:GameStateDeinitAction = {
    Write-Host "`e[?25h"
    $Script:Running = $false
}

# MAP STATE FUNCTIONS WITH STATE
$Script:TheGameStateTable = @{
    [GameState]::Init     = $Script:GameStateInitAction
    [GameState]::SetupMap = $Script:GameStateSetupMapAction
    [GameState]::GameLoop = $Script:GameStateGameLoopAction
    [GameState]::GameWin  = $Script:GameStateGameWinAction
    [GameState]::GameLose = $Script:GameStateGameLoseAction
    [GameState]::Deinit   = $Script:GameStateDeinitAction
}
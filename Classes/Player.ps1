using namespace System

Set-StrictMode -Version Latest

Class Player {
    [Int]$X
    [Int]$Y
    [Int]$VX
    [Int]$VY
    [Boolean]$IsGrounded
    [AnimatedString]$Symbol
    [Object]$LineColor

    Player() {
        $this.X          = 0
        $this.Y          = 0
        $this.VX         = 0
        $this.VY         = 0
        $this.IsGrounded = $false
        $this.LineColor  = $Global:PSRainbowColors.SpringGreen
        $this.Symbol     = [AnimatedString]@{
            Frames        = ([Char[]]('A'..'Z') + ('!', '@', '%', '&'))
            FrameDuration = 60.0
        }
    }
}

[Player]$Script:ThePlayer = [Player]@{
    X = 2
    Y = 2
}

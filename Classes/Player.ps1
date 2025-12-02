using namespace System

Set-StrictMode -Version Latest

Class Player {
    [Int]$X
    [Int]$Y
    [Int]$VX
    [Int]$VY
    [Boolean]$IsGrounded
    [Char]$Symbol
    [Object]$LineColor

    Player() {
        $this.X          = 0
        $this.Y          = 0
        $this.VX         = 0
        $this.VY         = 0
        $this.IsGrounded = $false
        $this.Symbol     = '!'
        $this.LineColor  = $Global:PSRainbowColors.SpringGreen
    }
}

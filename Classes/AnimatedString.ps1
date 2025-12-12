using namespace System

Set-StrictMode -Version Latest


Class AnimatedString {
    [Int]$CurrentFrame
    [Char[]]$Frames
    [Float]$FrameCounter
    [Float]$FrameDuration
    
    AnimatedString() {
        $this.CurrentFrame  = 0
        $this.Frames        = @()
        $this.FrameCounter  = 0.0
        $this.FrameDuration = 0.0
    }
    
    [Void]Update() {
        If(($this.FrameCounter += $Script:FrameDelta.TotalMilliseconds) -GE $this.FrameDuration) {
            $this.FrameCounter = 0.0
            
            If(($this.CurrentFrame + 1) -LT ($this.Frames.Length)) {
                $this.CurrentFrame++
            } Else {
                $this.CurrentFrame = 0
            }
        }
    }
    
    [Char]GetCurrentFrame() {
        Return $this.Frames[$this.CurrentFrame]
    }
}

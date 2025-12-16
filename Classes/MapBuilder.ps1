using namespace System

Set-StrictMode -Version Latest


Class MapBuilder {
    [Hashtable]$CharacterMap
    
    MapBuilder() {}
    
    [Void]ParseMap() {
        Foreach($Level in $Script:LevelData) {
            [String[]]$ConvertedMap = @()
            
            Foreach($Line in $Level[0]) {}
        }
    }
}

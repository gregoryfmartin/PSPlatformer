using namespace System

Set-StrictMode -Version Latest

Enum GameState {
    Init
    SetupMap
    GameLoop
    GameWin
    GameLose
    Deinit
}

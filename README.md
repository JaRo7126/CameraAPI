# CameraAPI

A The Binding of Isaac modding library, that was made primarily for manipulating the game camera's position without [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON). But it also adds various useful features even with [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON) installed

# Features

- Get current camera position
- Change camera position
- Make camera follow specific entity
- Remove camera movement limits from the base game

# How does it work?

CameraAPI uses invisible Hush entity to manipulate all camera movements. It works because when Hush's NpcState is equal to NpcState.STATE_APPEAR_CUSTOM(2) the game automatically snaps camera position to it's position. All you have to do is to spawn this invisible entity on first update and make it persistent between rooms. 

CameraMode.FREE works by adding FLAG_NO_WALLS to RoomDescriptor entry. In that case room borders limit is disabled only for camera and projectiles(for some reason).

# Adding library to the mod

To be able to use CameraAPI you simply need to

1. Download latest release from [Releases page](https://github.com/JaRo7126/CameraAPI/releases)
2. Place `camerapi.lua` file anywhere in your mod
3. `require` the lib in your main.lua file and attach it to a variable\
`local CameraAPI = require("scripts.utils.camerapi")`
4. Initialize the lib ONCE for callback registry\
`CameraAPI:Init(YourModVariable)`

**Congratulations!**
Now you can use any lib functions as you wish

# Are there any limits?
No, there are no actual limits. However, I must say, that with active camera option enabled camera movements will be MUCH slower. I've already implemented auto-disabling it on camera init, but if you for whatever reason want to remove this feature, you can delete the corresponding code(other CameraAPI instances just disable it anyway).

#### Special thanks to [Guantol](https://github.com/Guantol-Lemat) for making [LuaDecomps](https://github.com/Guantol-Lemat/Isaac.LuaDecomps) and Goganidze on [The Modding of Isaac discord server](https://discord.gg/modding-of-isaac-962027940131008653) for describing FLAG_NO_WALLS trick!




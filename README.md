# CameraAPI

A The Binding of Isaac modding library, that was made primarily for manipulating the game camera's position without [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON). But it also adds various useful features even with [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON) installed

# Features

- Change camera position
- Make camera follow specific entity
- Remove camera movement limits from the base game
- Doesn't require [REPENTOGON](https://github.com/TeamREPENTOGON/REPENTOGON)

# How does it work?

CameraAPI is using invisible Hush entity to manipulate all camera movements. It works because when Hush's NpcState is equal to NpcState.STATE_APPEAR_CUSTOM(2) the game automatically snaps camera position to it's position. All you have to do is to spawn this invisible entity on first update and make it persistent between rooms. 

How CameraMode.FREE works? It uses trick with adding FLAG_NO_WALLS to RoomDescriptor entry. In that case only room camera limit is gone, nothing more. "Beast crawlspace" also uses this flag if this helps to understand.

# Adding library to the mod

To add CameraAPI to your mod you simply need to

1. Download latest release from Releases page
2. Place the file anywhere in your mod
3. `require` it in your main.lua file and attach to a variable\
`local CameraAPI = require("scripts.utils.camerapi")`
4. Before using any functions don't forget to initialize the lib(for callbacks register)\
`CameraAPI:Init(YourModVariable)`

#### Congratulations!
Now you can use any lib functions as you wish

# Are there any limits?
Basically no. With CameroMode.FREE you can move game camera ANYWHERE you want. However, I must say, that with active camera option enabled camera movements will be MUCH slower. I've already implemented auto-disabling it on camera init, but if you for whatever reason don't want to disable it, you can delete the corresponding code(other CameraAPI instances might just disable it anyway).

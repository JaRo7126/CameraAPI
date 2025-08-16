-- CameraAPI by JaRo7126
-- Version 1.0

-- Works by spawning invisible Hush entity with NpcState constantly equal NpcState.STATE_APPEAR_CUSTOM(2)
-- Because of this CameraAPI doesn't require REPENTOGON to work.
-- But if you're using REPENTOGON, this library still has useful features

-- More info on Github: https://github.com/JaRo7126/CameraAPI

local CameraAPI = {}

CameraAPI.CameraMode = {
	ROOM_BORDER = 1,
	FREE = 2
}

local ROOM_DATA = {}
local RGON = REPENTOGON

local function SpawnCamera()
	local camera = Isaac.Spawn(RGON and EntityType.ENTITY_SHOPKEEPER 
								or EntityType.ENTITY_HUSH, 0, 0,
								Vector.Zero, Vector.Zero, nil):ToNPC()
	camera.Size = 0
	camera.Visible = false
	camera.CanShutDoors = false
	camera.State = 1000
	camera.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	camera.GridCollisionClass = GridCollisionClass.COLLISION_NONE
	camera:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	camera:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
	camera:GetData()["CameraAPI.CAMERA_DATA"] = {
		timeout = -1,
		locked = true,
		mode = 1
	}

	if Options.CameraStyle == 1 then
		Options.CameraStyle = 2
	end

	return camera
end

local function GetCamera()
	local camera

	for _, entity in ipairs(Isaac.FindByType(RGON and EntityType.ENTITY_SHOPKEEPER 
							or EntityType.ENTITY_HUSH)) do
		if entity:GetData()["CameraAPI.CAMERA_DATA"] then
			if camera then
				entity:Remove()
			else
				camera = entity:ToNPC()
			end
		end
	end

	if not camera then
		camera = SpawnCamera()
	end

	return camera
end

local function SetCameraPosition(pos)
	if not pos or not (pos.X and pos.Y) then
		error("bad argument #1 to CameraAPI_SetCameraPosition (vector expected, got " .. type(value) .. ")")
	end

	if RGON then
		Game():GetRoom():GetCamera():SetFocusPosition(pos)
	elseif tostring(GetCamera().Position) ~= tostring(pos) then
		GetCamera().Position = pos
	end
end

local function PostCameraUpdate()
	local camera = GetCamera()
	local rooms = Game():GetLevel():GetRooms()

	if not CameraAPI:IsCameraLocked() then
		camera.State = NpcState.STATE_APPEAR_CUSTOM
	else
		camera.State = 1000
	end

	if camera:GetSprite():GetFrame() > 2 then
		camera:GetSprite():SetFrame(2)
	end

	if camera.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
		camera.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	end

	if CameraAPI:GetCameraTimeout() > 0 then
		CameraAPI:SetCameraTimeout(CameraAPI:GetCameraTimeout() - 1)
	end

	for i = 0, rooms.Size - 1 do
		if ROOM_DATA[i] ~= rooms:Get(i).SafeGridIndex then
			ROOM_DATA[i] = rooms:Get(i).SafeGridIndex
		end
	end

	for i = GridRooms.ROOM_ANGEL_SHOP_IDX, GridRooms.ROOM_DEVIL_IDX do
		if ROOM_DATA[i] ~= i then
			ROOM_DATA[i] = i
		end
	end


	for i = GridRooms.ROOM_ANGEL_SHOP_IDX, #ROOM_DATA do
		local roomDesc = Game():GetLevel():GetRoomByIdx(ROOM_DATA[i])

		if roomDesc and roomDesc.Data then
			if roomDesc.Flags & RoomDescriptor.FLAG_NO_WALLS ~= 0
				and CameraAPI:GetCameraMode() == CameraAPI.CameraMode.ROOM_BORDER then

				roomDesc.Flags = roomDesc.Flags ~ RoomDescriptor.FLAG_NO_WALLS

			elseif roomDesc.Flags & RoomDescriptor.FLAG_NO_WALLS == 0
				and CameraAPI:GetCameraMode() == CameraAPI.CameraMode.FREE then

				roomDesc.Flags = roomDesc.Flags | RoomDescriptor.FLAG_NO_WALLS
			end
		end
	end
end

local function PostCameraRender()
	local camera = GetCamera()

	if camera.FrameCount < 2 and SFXManager():IsPlaying(SoundEffect.SOUND_HUSH_LOW_ROAR) then
		SFXManager():Stop(SoundEffect.SOUND_HUSH_LOW_ROAR)
	end

	if CameraAPI:IsCameraLocked() then
		if CameraAPI:GetCameraTimeout() ~= -1 then
			CameraAPI:SetCameraTimeout(-1)
		end

	else
		local data = camera:GetData()["CameraAPI.CAMERA_DATA"]
		local follow = CameraAPI:GetCameraFollowPoint()

		if follow.Entity then

			if follow.Entity:Exists() then
				SetCameraPosition(follow.Position + follow.Entity.Velocity 
											+ follow.PositionOffset)
			else
				data.follow = data.follow and nil
				data.follow_offset = data.follow_offset and nil
				CameraAPI:SetCameraLocked(true)
			end
		elseif follow.Position then
			SetCameraPosition(follow.Position)
		end

		if CameraAPI:GetCameraTimeout() == 0 then
			CameraAPI:SetCameraLocked(true)
			CameraAPI:SetCameraTimeout(-1)

			data.follow = data.follow and nil
			data.follow_offset = data.follow_offset and nil
		end

		if CameraAPI:GetCameraTimeout() < -1 then
			CameraAPI:SetCameraTimeout(-1)
		end
	end
end

function CameraAPI:Init(mod)
	if not mod.CameraAPIInit then
		mod.CameraAPIInit = true
		CameraAPI.Mod = mod

		mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostCameraUpdate)
		mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, CallbackPriority.LATE, PostCameraRender)
	else
		local warn = "[" .. CameraAPI.Mod.Name .. "] WARNING!: CameraAPI is already initialized!"

		if RGON then
			Console.PrintWarning(warn)
		else
			print(warn)
			Isaac.DebugString(warn)
		end
	end
end

function CameraAPI:IsCameraLocked()
	return GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked
end

function CameraAPI:SetCameraLocked(value)
	if not value then
		value = false
	elseif type(value) ~= "boolean" then
		error("bad argument #1 to CameraAPI_SetCameraLocked (boolean expected, got " .. type(value) .. ")")
		return
	end

	GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked = value
end

function CameraAPI:GetCameraTimeout()
	return GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout
end

function CameraAPI:SetCameraTimeout(value)
	if not value or type(value) ~= "number" then
		error("bad argument #1 to CameraAPI_SetCameraTimeout (number expected, got " .. type(value) .. ")")
		return
	end

	GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout = value
end

function CameraAPI:GetCameraWorldPosition()
	local screen_width = Isaac.GetScreenWidth()
	local screen_height = Isaac.GetScreenHeight()

	local screen_center = Vector(screen_width / 2, screen_height / 2)
	screen_center = screen_center - Game():GetRoom():GetRenderScrollOffset()
	screen_center = screen_center - Game().ScreenShakeOffset
	
	local x = (screen_center.X - (screen_width - 338) * 0.5) / 0.65 + 60
	local y = (screen_center.Y - (screen_height - 182) * 0.5) / 0.65 + 140

	return Vector(x, y)
end

function CameraAPI:GetCameraFollowPoint()
	local data = GetCamera():GetData()["CameraAPI.CAMERA_DATA"]
	local follow_point = {}

	if not CameraAPI:IsCameraLocked() and data.follow then
		if tostring(data.follow):sub(1, 8) == "userdata"
			and data.follow.Type then

			follow_point.Position = data.follow.Position
			follow_point.Entity = data.follow
			follow_point.PositionOffset = data.follow_offset or Vector.Zero

		else
			follow_point.Position = data.follow
			follow_point.PositionOffset = Vector.Zero
		end
	end

	return follow_point
end

function CameraAPI:CameraFollowPosition(pos, duration, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:GetCameraFollowPoint().Position) then
		GetCamera():GetData()["CameraAPI.CAMERA_DATA"].follow = pos
		SetCameraPosition(pos)
		CameraAPI:SetCameraTimeout(duration)
		CameraAPI:SetCameraLocked(false)
	end

end

function CameraAPI:CameraFollowEntity(entity, duration, offset, force)
	if not offset then offset = Vector.Zero end
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:GetCameraFollowPoint().Position) then
		local camera = GetCamera()

		SetCameraPosition(entity.Position)
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow = entity
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow_offset = offset
		CameraAPI:SetCameraTimeout(duration)
		CameraAPI:SetCameraLocked(false)
	end

end

function CameraAPI:GetCameraMode()
	return GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode
end

function CameraAPI:SetCameraMode(mode)
	if not mode
		or type(mode) ~= "number"
		or mode > 2
		or mode < 1 then

		error("bad argument #1 to CameraAPI_SetCameraMode (CameraMode expected, got " .. type(mode) .. ")")
		return
	end

	GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode = mode
end


return CameraAPI
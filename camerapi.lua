-- CameraAPI by JaRo7126
-- Version 1.0

-- Works by spawning invisible Hush entity with NpcState constantly equal NpcState.STATE_APPEAR_CUSTOM(2)
-- Because of this CameraAPI doesn't require REPENTOGON to work.
-- But if you're using REPENTOGON, this library still has useful features

--More info on Github: https://github.com/JaRo7126/CameraAPI

local CameraAPI = {}
local CAMERA_VARIANT = Isaac.GetEntityVariantByName("[CameraAPI] Camera Entity")
local CAMERA_DATA = {
	timeout = -1,
	locked = true,
	mode = 1
}

CameraAPI.CameraMode = {
	ROOM_BORDER = 1,
	FREE = 2
}

local function PostCameraUpdate()
	local camera = CameraAPI:GetCamera()
	camera.State = NpcState.STATE_APPEAR_CUSTOM

	if CameraAPI:GetCameraTimeout() > 0 then
		CameraAPI:SetCameraTimeout(CameraAPI:GetCameraTimeout() - 1)
	end

	for i = 0, 168 do
		local roomDesc = Game():GetLevel():GetRoomByIdx(i)

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
	local camera = CameraAPI:GetCamera()
	local roomDesc = Game():GetLevel():GetCurrentRoomDesc()

	if camera.FrameCount < 2 and SFXManager():IsPlaying(SoundEffect.SOUND_HUSH_LOW_ROAR) then
		SFXManager():Stop(SoundEffect.SOUND_HUSH_LOW_ROAR)
	end

	if roomDesc and roomDesc.Data then
		if roomDesc.Flags & RoomDescriptor.FLAG_NO_WALLS ~= 0
			and CameraAPI:GetCameraMode() == CameraAPI.CameraMode.ROOM_BORDER then

			roomDesc.Flags = roomDesc.Flags ~ RoomDescriptor.FLAG_NO_WALLS

		elseif roomDesc.Flags & RoomDescriptor.FLAG_NO_WALLS == 0
			and CameraAPI:GetCameraMode() == CameraAPI.CameraMode.FREE then

			roomDesc.Flags = roomDesc.Flags | RoomDescriptor.FLAG_NO_WALLS
		end
	end

	if CameraAPI:IsCameraLocked() then

		for _, entity in ipairs(Isaac.GetRoomEntities()) do

			if entity.Type == EntityType.ENTITY_HUSH 
				and entity.Variant ~= CAMERA_VARIANT
				and entity:ToNPC().State == NpcState.STATE_APPEAR_CUSTOM then

				camera.Position = entity.Position + entity.Velocity
				return
			elseif entity.Type == EntityType.ENTITY_ULTRAGREED
				and entity:ToNPC().State == NpcState.STATE_APPEAR_CUSTOM then

				camera.Position = entity.Position + entity.Velocity - Vector(0, 100)
				return
			elseif entity.Type == EntityType.ENTITY_MOTHER
				and (entity.Variant == 0 or entity.Variant == 10) then

				camera.Position = entity.Position + entity.Velocity + Vector(0, 200)
				return
			elseif entity.Type == EntityType.ENTITY_BEAST
				and entity.Variant == 0 then

				if entity:ToNPC().State == 18 then
					camera.Position = entity.Position + entity.Velocity
				else
					camera.Position = Game():GetRoom():GetCenterPos()
				end
				return
			end
		end

		local camera_pos = Isaac.GetPlayer(0).Position + Isaac.GetPlayer(0).Velocity

		for i = 0, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)

			camera_pos = camera_pos * 0.5 + (player.Position + player.Velocity) * 0.5
		end

		camera.Position = camera_pos

	else
		if CAMERA_DATA.follow then
			local entity = CAMERA_DATA.follow

			if entity:Exists() then
				camera.Position = entity.Position + entity.Velocity
			else
				CAMERA_DATA.follow = nil
				CameraAPI:SetCameraLocked(true)
			end
		end

		if CameraAPI:GetCameraTimeout() == 0 then
			CameraAPI:SetCameraLocked(true)

			if CAMERA_DATA.follow then
				CAMERA_DATA.follow = nil
			end
		end
	end
end

function CameraAPI:Init(mod)
	if not mod.CameraAPIInit then
		CameraAPI.Mod = mod

		mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostCameraUpdate)
		mod:AddCallback(ModCallbacks.MC_POST_RENDER, PostCameraRender)
	end
end

function CameraAPI:GetCamera()
	local camera

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_HUSH, CAMERA_VARIANT)) do
		if camera then
			entity:Remove()
		else
			camera = entity:ToNPC()
		end
	end

	if not camera then
		camera = CameraAPI:SpawnCamera()
	end

	return camera
end

function CameraAPI:SpawnCamera()
	local camera = Isaac.Spawn(EntityType.ENTITY_HUSH, CAMERA_VARIANT, 0,
							Vector(0, 0), Vector(0, 0), nil):ToNPC()
	camera.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	camera.GridCollisionClass = GridCollisionClass.COLLISION_NONE
	camera:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	camera:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

	if Options.CameraStyle == 1 then
		Options.CameraStyle = 2
	end

	return camera
end

function CameraAPI:IsCameraLocked()
	return CAMERA_DATA.locked
end

function CameraAPI:SetCameraLocked(value)
	if not value then
		value = false
	elseif type(value) ~= "boolean" then
		print(CameraAPI.Mod.Name .. " error in SetCameraLocked(): value is not a boolean (" .. tostring(value or "nil") .. ")")
		Isaac.DebugString(CameraAPI.Mod.Name .. " error in SetCameraLocked(): value is not a boolean (" .. tostring(value or "nil") .. ")")
		return
	end

	CAMERA_DATA.locked = value
end

function CameraAPI:GetCameraTimeout()
	return CAMERA_DATA.timeout
end

function CameraAPI:SetCameraTimeout(value)
	if not value or type(value) ~= "number" then
		print(CameraAPI.Mod.Name .. " error in SetCameraTimeout(): value is NAN (" .. tostring(value or "nil") .. ")")
		Isaac.DebugString(CameraAPI.Mod.Name .. " error in SetCameraTimeout(): value is NAN (" .. tostring(value or "nil") .. ")")
		return
	end

	CAMERA_DATA.timeout = value
end

function CameraAPI:SetCameraPosition(pos, duration, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:IsCameraLocked()) then
		CameraAPI:GetCamera().Position = pos
		CameraAPI:SetCameraLocked(false)
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:CameraFollowEntity(entity, duration, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:IsCameraLocked()) then
		CameraAPI:GetCamera().Position = entity.Position
		CAMERA_DATA.follow = entity
		CameraAPI:SetCameraLocked(false)
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:GetCameraMode()
	return CAMERA_DATA.mode
end

function CameraAPI:SetCameraMode(mode)
	if not mode
		or type(mode) ~= "number"
		or mode > 2
		or mode < 1 then

		print(CameraAPI.Mod.Name .. " error in SetCameraMode(): unknown CameraMode (" .. tostring(mode or "nil") .. ")")
		Isaac.DebugString(CameraAPI.Mod.Name .. " error in SetCameraMode(): unknown CameraMode (" .. tostring(mode or "nil") .. ")")
		return
	end

	CAMERA_DATA.mode = mode
end


return CameraAPI

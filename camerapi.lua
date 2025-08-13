-- CameraAPI by JaRo7126
-- Version 1.0

-- Works by spawning invisible Hush entity with NpcState constantly equal NpcState.STATE_APPEAR_CUSTOM(2)
-- Because of this CameraAPI doesn't require REPENTOGON to work.
-- But if you're using REPENTOGON, this library still has useful features

--More info on Github: https://github.com/JaRo7126/CameraAPI

local CameraAPI = {}

CameraAPI.CameraMode = {
	ROOM_BORDER = 1,
	FREE = 2
}

local ROOM_DATA = {}

if REPENTOGON then
	if not CAMERAPI_REPENTOGON_DATA then
		CAMERAPI_REPENTOGON_DATA = {
			timeout = -1,
			mode = 1,
			follow_offset = Vector.Zero
		}
	else
		CAMERAPI_REPENTOGON_DATA.timeout = -1
		CAMERAPI_REPENTOGON_DATA.mode = 1
		CAMERAPI_REPENTOGON_DATA.follow_offset = Vector.Zero
	end
end

local function PostCameraUpdate()
	local rooms = Game():GetLevel():GetRooms()

	if CameraAPI:GetCameraTimeout() > 0 then
		CameraAPI:SetCameraTimeout(CameraAPI:GetCameraTimeout() - 1)
	end

	for i = 0, rooms.Size - 1 do
		if ROOM_DATA[i] ~= rooms:Get(i).SafeGridIndex then
			ROOM_DATA[i] = rooms:Get(i).SafeGridIndex
		end
	end

	for i = 0, #ROOM_DATA do
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

	if CAMERAPI_REPENTOGON_DATA then
		if CameraAPI:GetCameraTimeout() ~= 0 then
			local pos

			if CAMERAPI_REPENTOGON_DATA.follow then

				if type(CAMERAPI_REPENTOGON_DATA.follow) == "Vector" then
					pos = CAMERAPI_REPENTOGON_DATA.follow

				elseif CAMERAPI_REPENTOGON_DATA.follow.Type then
					pos = CAMERAPI_REPENTOGON_DATA.follow.Position + CAMERAPI_REPENTOGON_DATA.follow_offset
				end
			end

			Game():GetRoom():GetCamera():SetFocusPosition(pos)
		else
			if CAMERAPI_REPENTOGON_DATA.follow then
				CAMERAPI_REPENTOGON_DATA.follow = nil
			end

			if tostring(CAMERAPI_REPENTOGON_DATA.follow_offset) ~= "0.0 0.0" then
				CAMERAPI_REPENTOGON_DATA.follow_offset = Vector.Zero
			end
		end

	else
		local camera = CameraAPI:GetCamera()
		camera.State = NpcState.STATE_APPEAR_CUSTOM

		if camera:GetSprite():GetFrame() > 2 then
			camera:GetSprite():SetFrame(2)
		end

		if camera.EntityCollisionClass ~= EntityCollisionClass.ENTCOLL_NONE then
			camera.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
	end
end

local function PostCameraRender()
	local camera = CameraAPI:GetCamera()
	local data = camera:GetData()["CameraAPI.CAMERA_DATA"]

	if camera.FrameCount < 2 and SFXManager():IsPlaying(SoundEffect.SOUND_HUSH_LOW_ROAR) then
		SFXManager():Stop(SoundEffect.SOUND_HUSH_LOW_ROAR)
	end

	if CameraAPI:IsCameraLocked() then

		for _, entity in ipairs(Isaac.GetRoomEntities()) do

			if (entity.Type == EntityType.ENTITY_MEGA_SATAN 
					or entity.Type == EntityType.ENTITY_MEGA_SATAN_2
				) 
				and entity.Variant == 0
				and (entity:ToNPC().State == NpcState.STATE_APPEAR_CUSTOM 
					or entity:ToNPC().State == NpcState.STATE_SPECIAL
				) then

				camera.Position = entity.Position + entity.Velocity
				return
			elseif entity.Type == EntityType.ENTITY_HUSH 
				and not entity:GetData()["CameraAPI.CAMERA_DATA"]
				and entity:ToNPC().State == NpcState.STATE_APPEAR_CUSTOM then

				camera.Position = entity.Position + entity.Velocity
				return
			elseif entity.Type == EntityType.ENTITY_ULTRAGREED
				and entity:ToNPC().State == NpcState.STATE_APPEAR_CUSTOM then

				camera.Position = entity.Position + entity.Velocity - Vector(0, 100)
				return
			elseif entity.Type == EntityType.ENTITY_MOTHER then
				
				if entity.Variant == 0 and entity.SubType == 0 then
					camera.Position = Game():GetRoom():GetCenterPos()
					return
				elseif entity.Variant == 10 and entity:ToNPC().State == NpcState.STATE_SPECIAL then
					camera.Position = entity.Position + entity.Velocity + Vector(0, 100)
					return
				end
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
		if data.follow then
			if type(data.follow) == "Vector" then
				if tostring(camera.Position) ~= tostring(data.follow) then
					camera.Position = data.follow
				end

			elseif data.follow.Type then
				local entity = data.follow

				if entity:Exists() then
					camera.Position = entity.Position + entity.Velocity + data.follow_offset
				else
					data.follow = nil
					data.follow_offset = Vector.Zero
					CameraAPI:SetCameraLocked(true)
				end
			end
		end

		if CameraAPI:GetCameraTimeout() == 0 then
			CameraAPI:SetCameraLocked(true)

			if data.follow then
				data.follow = nil
			end

			if tostring(data.follow_offset) ~= "0.0 0.0" then
				data.follow_offset = Vector.Zero
			end
		end
	end
end

function CameraAPI:GetCamera()
	if REPENTOGON then
		Console.PrintWarning("[" .. CameraAPI.Mod.Name .. "] Warning in CameraAPI_GetCamera: this function will do nothing if REPENTOGON is enabled.")
		return
	end

	local camera

	for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_HUSH)) do
		if entity:GetData()["CameraAPI.CAMERA_DATA"] then
			if camera then
				entity:Remove()
			else
				camera = entity:ToNPC()
			end
		end
	end

	if not camera then
		camera = CameraAPI:SpawnCamera()
	end

	return camera
end

function CameraAPI:SpawnCamera()
	if REPENTOGON then
		Console.PrintWarning("[" .. CameraAPI.Mod.Name .. "] Warning in CameraAPI_SpawnCamera: this function will do nothing if REPENTOGON is enabled.")
		return
	end

	local camera = Isaac.Spawn(EntityType.ENTITY_HUSH, 0, 0,
							Vector(0, 0), Vector(0, 0), nil):ToNPC()
	camera.Size = 0
	camera.Visible = false
	camera.CanShutDoors = false
	camera.Friction = 0
	camera.Mass = 100
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

function CameraAPI:IsCameraLocked()
	if REPENTOGON then
		Console.PrintWarning("[" .. CameraAPI.Mod.Name .. "] Warning in CameraAPI_IsCameraLocked: this function will do nothing if REPENTOGON is enabled.")
		return
	end

	return CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked
end

function CameraAPI:SetCameraLocked(value)
	if REPENTOGON then
		Console.PrintWarning("[" .. CameraAPI.Mod.Name .. "] Warning in CameraAPI_SetCameraLocked: this function will do nothing if REPENTOGON is enabled.")
		return
	end

	if not value then
		value = false
	elseif type(value) ~= "boolean" then
		error("[" .. CameraAPI.Mod.Name .. "] bad argument #1 to CameraAPI_SetCameraLocked (boolean expected, got " .. type(value) .. ")")
		return
	end

	CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked = value
end

function CameraAPI:GetCameraTimeout()
	return CAMERAPI_REPENTOGON_DATA and CAMERAPI_REPENTOGON_DATA.timeout
	or CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout
end

function CameraAPI:SetCameraTimeout(value)
	if not value or type(value) ~= "number" then
		error("[" .. CameraAPI.Mod.Name .. "] bad argument #1 to CameraAPI_SetCameraTimeout (number expected, got " .. type(value) .. ")")
		return
	end

	if CAMERAPI_REPENTOGON_DATA then
		CAMERAPI_REPENTOGON_DATA.timeout = value
	else
		CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout = value
	end
end

function CameraAPI:SetCameraPosition(pos, duration, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if not CAMERAPI_REPENTOGON_DATA 
		and (force or (not force and not CameraAPI:IsCameraLocked())) then
		CameraAPI:GetCamera().Position = pos
		CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].follow = pos
		CameraAPI:SetCameraLocked(false)
	elseif CAMERAPI_REPENTOGON_DATA  then
		CAMERAPI_REPENTOGON_DATA.follow = pos
		CAMERAPI_REPENTOGON_DATA.timeout = duration
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:CameraFollowEntity(entity, duration, offset, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if not CAMERAPI_REPENTOGON_DATA 
		and (force or (not force and not CameraAPI:IsCameraLocked())) then
		local camera = CameraAPI:GetCamera()

		camera.Position = entity.Position
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow = entity
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow_offset = offset
		CameraAPI:SetCameraLocked(false)
	elseif CAMERAPI_REPENTOGON_DATA  then
		CAMERAPI_REPENTOGON_DATA.follow = entity
		CAMERAPI_REPENTOGON_DATA.follow_offset = offset
		CAMERAPI_REPENTOGON_DATA.timeout = duration
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:GetCameraMode()
	return CAMERAPI_REPENTOGON_DATA and CAMERAPI_REPENTOGON_DATA.mode
	or CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode
end

function CameraAPI:SetCameraMode(mode)
	if not mode
		or type(mode) ~= "number"
		or mode > 2
		or mode < 1 then

		error("[" .. CameraAPI.Mod.Name .. "] bad argument #1 to CameraAPI_SetCameraMode (CameraMode expected, got " .. type(value) .. ")")
		return
	end

	if CAMERAPI_REPENTOGON_DATA then
		CAMERAPI_REPENTOGON_DATA.mode = mode
	else
		CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode = mode
	end
end


function CameraAPI:Init(mod)
	if not mod.CameraAPIInit then
		CameraAPI.Mod = mod

		mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostCameraUpdate)

		if not CAMERAPI_REPENTOGON_DATA then
			mod:AddCallback(ModCallbacks.MC_POST_RENDER, PostCameraRender)
		end
	end
end


return CameraAPI
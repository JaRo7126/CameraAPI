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

local function PostCameraUpdate()
	local camera = CameraAPI:GetCamera()
	local rooms = Game():GetLevel():GetRooms()
	camera.State = NpcState.STATE_APPEAR_CUSTOM

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
			if tostring(data.follow):sub(1, 8) == "userdata"
				and data.follow.Type then

				if data.follow:Exists() then
					local offset = data.follow_offset or Vector.Zero

					CameraAPI:SetCameraPosition(data.follow.Position + data.follow.Velocity + offset)
				else
					data.follow = nil
					data.follow_offset = nil
					CameraAPI:SetCameraLocked(true)
				end
			elseif data.follow.Zero then
				CameraAPI:SetCameraPosition(data.follow)
			end
		end

		if CameraAPI:GetCameraTimeout() == 0 then
			CameraAPI:SetCameraLocked(true)

			if data.follow then
				data.follow = nil
			end
			if data.follow_offset then
				data.follow_offset = nil
			end
		end
	end
end

function CameraAPI:Init(mod)
	if not mod.CameraAPIInit then
		CameraAPI.Mod = mod

		mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostCameraUpdate)
		mod:AddPriorityCallback(ModCallbacks.MC_POST_RENDER, CallbackPriority.LATE, PostCameraRender)
	end
end

function CameraAPI:GetCamera()
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
		camera = CameraAPI:SpawnCamera()
	end

	return camera
end

function CameraAPI:SpawnCamera()
	local camera = Isaac.Spawn(RGON and EntityType.ENTITY_SHOPKEEPER 
								or EntityType.ENTITY_HUSH, 0, 0,
								Vector.Zero, Vector.Zero, nil):ToNPC()
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
	return CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked
end

function CameraAPI:SetCameraLocked(value)
	if not value then
		value = false
	elseif type(value) ~= "boolean" then
		error("bad argument #1 to CameraAPI_SetCameraLocked (boolean expected, got " .. type(value) .. ")")
		return
	end

	CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].locked = value
end

function CameraAPI:GetCameraTimeout()
	return CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout
end

function CameraAPI:SetCameraTimeout(value)
	if not value or type(value) ~= "number" then
		error("bad argument #1 to CameraAPI_SetCameraTimeout (number expected, got " .. type(value) .. ")")
		return
	end

	CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].timeout = value
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
	local data = CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"]
	local follow_point = {}

	if data.follow then
		if tostring(data.follow):sub(1, 8) == "userdata"
			and data.follow.Type then

			follow_point.Position = data.follow.Position
			follow_point.Entity = data.follow
			follow_point.PositionOffset = data.follow_offset or Vector.Zero

		elseif data.follow.Zero then
			follow_point.Position = data.follow
			follow_point.PositionOffset = Vector.Zero
		end
	end

	return follow_point
end

function CameraAPI:SetCameraPosition(pos)
	if not pos or not pos.Zero then
		error("bad argument #1 to CameraAPI_SetCameraPosition (vector expected, got " .. type(value) .. ")")
	end

	if RGON then
		Game():GetRoom():GetCamera():SetFocusPosition(pos)
	elseif tostring(CameraAPI:GetCameraPosition()) ~= tostring(pos) then
		CameraAPI:GetCamera().Position = pos
	end
end

function CameraAPI:CameraFollowPosition(pos, duration, force)
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:IsCameraLocked()) then
		CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].follow = pos
		CameraAPI:SetCameraPosition(pos)
		CameraAPI:SetCameraLocked(false)
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:CameraFollowEntity(entity, duration, offset, force)
	if not offset then offset = Vector.Zero end
	if duration == nil then duration = -1 end
	if force == nil then force = true end

	if force or (not force and not CameraAPI:IsCameraLocked()) then
		local camera = CameraAPI:GetCamera()

		CameraAPI:SetCameraPosition(entity.Position)
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow = entity
		camera:GetData()["CameraAPI.CAMERA_DATA"].follow_offset = offset
		CameraAPI:SetCameraLocked(false)
	end

	CameraAPI:SetCameraTimeout(duration)
end

function CameraAPI:GetCameraMode()
	return CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode
end

function CameraAPI:SetCameraMode(mode)
	if not mode
		or type(mode) ~= "number"
		or mode > 2
		or mode < 1 then

		error("bad argument #1 to CameraAPI_SetCameraMode (CameraMode expected, got " .. type(mode) .. ")")
		return
	end

	CameraAPI:GetCamera():GetData()["CameraAPI.CAMERA_DATA"].mode = mode
end


return CameraAPI
--[[	Author: Firetoad
		Date:	16.05.2015	]]

function RapierToggle( keys )
	local caster = keys.caster
	local ability = keys.ability
	local next_item = keys.next_item
	local next_stacks = keys.next_stacks
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- If this is a courier, do nothing
	if caster:GetUnitName() == "npc_dota_courier" then
		return nil
	end

	-- Flag this hero as toggling a rapier
	caster.rapier_toggling_happening = true
	Timers:CreateTimer(0.01, function()
		caster.rapier_toggling_happening = nil
	end)

	-- Count current stacks
	local current_stacks = caster:GetModifierStackCount(modifier_phys, caster) + caster:GetModifierStackCount(modifier_magic, caster)

	-- Remove existing stacks
	caster:RemoveModifierByName(modifier_phys)
	caster:RemoveModifierByName(modifier_magic)

	-- Swap to next rapier
	SwapToItem(caster, ability, next_item)

	-- Find new rapier's ability handle
	local next_ability
	for i = 0, 5 do
		local item = caster:GetItemInSlot(i)
		if item and item:GetAbilityName() == next_item then
			next_ability = item
			break
		end
	end

	-- Add stacks of the next rapier
	AddStacks(next_ability, caster, caster, next_stacks, current_stacks, true)
end

function RapierMagicSpellPowerEnd( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- If this is an illusion, do nothing
	if caster:IsIllusion() then
		return nil
	end

	-- Remove all bonus spell power
	local spell_power = ability:GetSpecialValueFor("spell_power")
	if not caster.magic_rapier_level_tracker then
		caster.magic_rapier_level_tracker = 0
	end
	ChangeSpellPower(caster, (-1) * spell_power * caster.magic_rapier_level_tracker)
	caster.magic_rapier_level_tracker = nil
end

function RapierParticleMagic( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- If this is a courier, do nothing
	if caster:GetUnitName() == "npc_dota_courier" then
		return nil
	end

	-- Fetch current rapier level
	local rapier_level = caster:GetModifierStackCount(modifier_phys, caster) + caster:GetModifierStackCount(modifier_magic, caster)

	-- Update granted spell power if necessary
	local spell_power = ability:GetSpecialValueFor("spell_power")
	if not caster.magic_rapier_level_tracker then
		caster.magic_rapier_level_tracker = 0
	end
	if caster.magic_rapier_level_tracker ~= rapier_level then
		ChangeSpellPower(caster, spell_power * (rapier_level - caster.magic_rapier_level_tracker))
		caster.magic_rapier_level_tracker = rapier_level
	end
	
	-- If rapier level is enough, grant vision of the caster to all teams
	if rapier_level >= 3 then

		-- Destroy physical rapier particle
		if caster.rapier_phys_particle then
			ParticleManager:DestroyParticle(caster.rapier_phys_particle, true)
			ParticleManager:ReleaseParticleIndex(caster.rapier_phys_particle)
			caster.rapier_phys_particle = nil
		end

		-- Create magical rapier particle if necessary
		if not caster.rapier_magic_particle then
			caster.rapier_magic_particle = ParticleManager:CreateParticle("particles/item/rapier/rapier_trail_arcane.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(caster.rapier_magic_particle, 0, caster:GetAbsOrigin())

		-- Else, update its position
		else
			ParticleManager:SetParticleControl(caster.rapier_magic_particle, 0, caster:GetAbsOrigin())
		end
	end
end

function RapierParticlePhys( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- If this is a courier, do nothing
	if caster:GetUnitName() == "npc_dota_courier" then
		return nil
	end

	-- Fetch current rapier level
	local rapier_level = caster:GetModifierStackCount(modifier_phys, caster) + caster:GetModifierStackCount(modifier_magic, caster)
	
	-- If rapier level is enough, grant vision of the caster to all teams
	if rapier_level >= 3 then

		-- Destroy physical rapier particle
		if caster.rapier_magic_particle then
			ParticleManager:DestroyParticle(caster.rapier_magic_particle, true)
			ParticleManager:ReleaseParticleIndex(caster.rapier_magic_particle)
			caster.rapier_magic_particle = nil
		end

		-- Create magical rapier particle if necessary
		if not caster.rapier_phys_particle then
			caster.rapier_phys_particle = ParticleManager:CreateParticle("particles/item/rapier/rapier_trail_regular.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(caster.rapier_phys_particle, 0, caster:GetAbsOrigin())

		-- Else, update its position
		else
			ParticleManager:SetParticleControl(caster.rapier_phys_particle, 0, caster:GetAbsOrigin())
		end
	end
end

function RapierVision( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- If this is a courier, do nothing
	if caster:GetUnitName() == "npc_dota_courier" then
		return nil
	end

	-- Fetch current rapier level
	local rapier_level = caster:GetModifierStackCount(modifier_phys, caster) + caster:GetModifierStackCount(modifier_magic, caster)
	
	-- If rapier level is enough, grant vision of the caster to all teams
	if rapier_level >= 3 then
		caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.1)
		caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.1)
		if not caster.rapier_vision_pfx then
			caster.rapier_vision_pfx = ParticleManager:CreateParticle("particles/econ/items/effigies/status_fx_effigies/gold_effigy_ambient_dire_lvl2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleAlwaysSimulate(caster.rapier_vision_pfx)
		end
	end

	-- Fetch rapiers in inventory
	local rapiers = {}
	for i = 0, 5 do
		local item = caster:GetItemInSlot(i)
		if item and ( item:GetAbilityName() == "item_imba_rapier" or item:GetAbilityName() == "item_imba_rapier_magic" ) then
			rapiers[#rapiers+1] = item
		end
	end

	-- If there is more than one rapier, condense them
	if #rapiers > 1 then
	
		-- Add stacks
		if caster:HasModifier(modifier_phys) then
			AddStacks(rapiers[1], caster, caster, modifier_phys, #rapiers - 1, true)
		elseif caster:HasModifier(modifier_magic) then
			AddStacks(rapiers[1], caster, caster, modifier_magic, #rapiers - 1, true)
		end

		-- Delete extra rapiers
		Timers:CreateTimer(0.01, function()
			for i = 2, #rapiers do
				caster:RemoveItem(rapiers[i])
			end
		end)
	end
end

function RapierBuy( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- If this is not a real hero, do nothing
	if ( not caster:IsRealHero() and not IsHeroCreep(caster) ) or caster:IsIllusion() then
		caster:RemoveModifierByName("modifier_item_imba_rapier_unique")
		return nil
	end

	-- If this hero does not have a rapier, add its first stack and flag it as a rapier owner
	if not caster.has_rapier then
		AddStacks(ability, caster, caster, modifier_phys, 1, true)
		caster.has_rapier = true
	end
end

function RapierPickUp( keys )
	local caster = keys.caster
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic
	
	-- If a rapier was already picked up, or this is an illusion, do nothing
	if caster.rapier_picked_up then
		return nil
	end

	-- Double pick-up safety variable
	caster.rapier_picked_up = true
	Timers:CreateTimer(0.01, function()
		caster.rapier_picked_up = nil
	end)

	-- If this is a courier, drop another rapier on the ground and do nothing else
	if caster:GetUnitName() == "npc_dota_courier" then
		local drop = CreateItem("item_imba_rapier_dummy", nil, nil)
		CreateItemOnPositionSync(caster:GetAbsOrigin(), drop)
		drop:LaunchLoot(false, 250, 0.5, caster:GetAbsOrigin())

		-- Remove the dummy item from the courier's inventory
		Timers:CreateTimer(0.01, function()
			for i = 0, 18 do
				local item = caster:GetItemInSlot(i)
				if item and item:GetAbilityName() == "item_imba_rapier_dummy" then
					caster:RemoveItem(item)
				end
			end
		end)
		return nil
	end

	-- Global message colors
	local level_color = {
		"#FFE5E5",
		"#FFCCCC",
		"#FFB2B2",
		"#FF9999",
		"#FF7F7F",
		"#FF6666",
		"#FF4C4C",
		"#FF3333",
		"#FF1A1A",
		"#FF0000"
	}

	-- If the hero picking this up already has a rapier, add a divine power stack to it
	if caster.has_rapier then
		
		-- Find the rapier's ability handle
		local rapier_ability
		for i = 0, 5 do
			local item = caster:GetItemInSlot(i)
			if item and ( item:GetAbilityName() == "item_imba_rapier" or item:GetAbilityName() == "item_imba_rapier_magic" ) then
				rapier_ability = item
				break
			end
		end

		-- Add stack
		local rapier_level
		if caster:HasModifier(modifier_phys) then
			AddStacks(rapier_ability, caster, caster, modifier_phys, 1, true)
			rapier_level = caster:GetModifierStackCount(modifier_phys, caster)
		elseif caster:HasModifier(modifier_magic) then
			AddStacks(rapier_ability, caster, caster, modifier_magic, 1, true)
			rapier_level = caster:GetModifierStackCount(modifier_magic, caster)
		end

		-- Global message parameters
		local line_duration = 7
		local vision_duration = 5
		local rapier_color = math.min(rapier_level, 10)

		-- Memorize this global message's level for later
		caster.rapier_picked_up_level = rapier_level

		-- After some time, if this is the right message call, show the message
		Timers:CreateTimer(1.5, function()
			if caster.rapier_picked_up_level == rapier_level then
				
				-- Erase the call
				caster.rapier_picked_up_level = nil

				-- Show global message
				Notifications:BottomToAll({hero = caster:GetName(), duration = line_duration})
				Notifications:BottomToAll({text = PlayerResource:GetPlayerName(caster:GetPlayerID()).." ", duration = line_duration, continue = true})
				Notifications:BottomToAll({text = "#imba_player_rapier_pickup_01", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
				Notifications:BottomToAll({text = rapier_level.." ", duration = line_duration, style = {color = level_color[rapier_color]}, continue = true})
				Notifications:BottomToAll({text = "#imba_player_rapier_pickup_02", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
			end
		end)

	-- Else, if this is a creep with an inventory attempting to pick up rapiers, prevent it from doing so
	elseif not caster:IsRealHero() then
		local drop = CreateItem("item_imba_rapier_dummy", nil, nil)
		CreateItemOnPositionSync(caster:GetAbsOrigin(), drop)
		drop:LaunchLoot(false, 250, 0.5, caster:GetAbsOrigin() + RandomVector(100))

	-- Else, if it has a free slot, create a rapier on it
	elseif caster:HasAnyAvailableInventorySpace() then

		-- Create the rapier
		caster:AddItem(CreateItem("item_imba_rapier", caster, caster))

		-- Global message parameters
		local line_duration = 7
		local vision_duration = 5
		local rapier_level = 1
		local rapier_color = 1

		-- Memorize this global message's level for later
		caster.rapier_picked_up_level = rapier_level

		-- After some time, if this is the right message call, show the message
		Timers:CreateTimer(1.5, function()
			if caster.rapier_picked_up_level == rapier_level then

				-- Erase the call
				caster.rapier_picked_up_level = nil

				-- Show global message
				Notifications:BottomToAll({hero = caster:GetName(), duration = line_duration})
				Notifications:BottomToAll({text = PlayerResource:GetPlayerName(caster:GetPlayerID()).." ", duration = line_duration, continue = true})
				Notifications:BottomToAll({text = "#imba_player_rapier_pickup_01", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
				Notifications:BottomToAll({text = rapier_level.." ", duration = line_duration, style = {color = level_color[rapier_color]}, continue = true})
				Notifications:BottomToAll({text = "#imba_player_rapier_pickup_02", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
			end
		end)

	-- Else, drop another dummy on the ground
	else
		local drop = CreateItem("item_imba_rapier_dummy", nil, nil)
		CreateItemOnPositionSync(caster:GetAbsOrigin(), drop)
		drop:LaunchLoot(false, 250, 0.5, caster:GetAbsOrigin() + RandomVector(100))
	end

	-- Remove the dummy item from the hero's inventory
	Timers:CreateTimer(0.01, function()
		for i = 0, 18 do
			local item = caster:GetItemInSlot(i)
			if item and item:GetAbilityName() == "item_imba_rapier_dummy" then
				caster:RemoveItem(item)
			end
		end
	end)
end

function RapierDrop( keys )
	local caster = keys.caster
	local caster_pos = caster:GetAbsOrigin()
	local ability = keys.ability
	local modifier_phys = keys.modifier_phys
	local modifier_magic = keys.modifier_magic

	-- Flag hero as a rapier non-owner
	caster.has_rapier = nil

	-- Destroy rapier particles, if existing
	if caster.rapier_vision_pfx then
		ParticleManager:DestroyParticle(caster.rapier_vision_pfx, false)
		caster.rapier_vision_pfx = nil
	end
	if caster.rapier_phys_particle then
		ParticleManager:DestroyParticle(caster.rapier_phys_particle, false)
		caster.rapier_phys_particle = nil
	end
	if caster.rapier_magic_particle then
		ParticleManager:DestroyParticle(caster.rapier_magic_particle, false)
		caster.rapier_magic_particle = nil
	end

	-- Fetch rapier level
	local rapier_level = caster:GetModifierStackCount(modifier_phys, caster) + caster:GetModifierStackCount(modifier_magic, caster)
	
	-- Remove damage amp stacks
	caster:RemoveModifierByName(modifier_phys)
	caster:RemoveModifierByName(modifier_magic)

	-- Remove the rapiers from the player's inventory
	for i = 0, 5 do
		local item = caster:GetItemInSlot(i)
		if item and ( item:GetAbilityName() == "item_imba_rapier" or item:GetAbilityName() == "item_imba_rapier_magic" ) then
			caster:RemoveItem(item)
		end
	end

	-- Drop dummy rapiras
	for i = 1, rapier_level do
		local drop = CreateItem("item_imba_rapier_dummy", nil, nil)
		CreateItemOnPositionSync(caster_pos, drop)
		drop:LaunchLoot(false, 250, 0.5, caster_pos + RandomVector(100))
	end

	-- Global message parameters
	local line_duration = 7
	local vision_duration = 5
	local rapier_color = math.min(rapier_level, 10)
	local level_color = {
		"#FFE5E5",
		"#FFCCCC",
		"#FFB2B2",
		"#FF9999",
		"#FF7F7F",
		"#FF6666",
		"#FF4C4C",
		"#FF3333",
		"#FF1A1A",
		"#FF0000"
	}

	-- Show global message
	Timers:CreateTimer(0.1, function()
		Notifications:BottomToAll({hero = caster:GetName(), duration = line_duration})
		Notifications:BottomToAll({text = PlayerResource:GetPlayerName(caster:GetPlayerID()).." ", duration = line_duration, continue = true})
		Notifications:BottomToAll({text = "#imba_player_rapier_drop_01", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
		Notifications:BottomToAll({text = rapier_level.." ", duration = line_duration, style = {color = level_color[rapier_color]}, continue = true})
		Notifications:BottomToAll({text = "#imba_player_rapier_drop_02", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})

		-- Ping and grant vision of the location for both teams
		caster:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, vision_duration)
		caster:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, vision_duration)
		MinimapEvent(DOTA_TEAM_GOODGUYS, caster, caster_pos.x, caster_pos.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, vision_duration)
		MinimapEvent(DOTA_TEAM_BADGUYS, caster, caster_pos.x, caster_pos.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, vision_duration)
	end)
end
--[[	Author: d2imba
		Date:	24.03.2015	]]

function Midas( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local sound_cast = keys.sound_cast

	-- If this unit is not a real hero, do nothing
	if not caster:IsRealHero() then
		ability:RefundManaCost()
		ability:EndCooldown()
		return nil
	end

	-- Parameters and calculations
	local creep_XP = target:GetDeathXP()
	local bonus_gold = ability:GetLevelSpecialValueFor("bonus_gold", ability:GetLevel() - 1)
	local xp_multiplier = ability:GetLevelSpecialValueFor("xp_multiplier", ability:GetLevel() - 1)
	local bonus_xp = creep_XP * xp_multiplier

	-- Multiply gold by the lobby's parameters
	bonus_gold = bonus_gold * ( 100 + CREEP_GOLD_BONUS ) / 100

	-- Play sound and show gold gain message to the owner
	target:EmitSound(sound_cast)
	SendOverheadEventMessage(PlayerResource:GetPlayer(caster:GetPlayerID()), OVERHEAD_ALERT_GOLD, target, bonus_gold, nil)

	-- Draw the midas gold conversion particle
	local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)	
	ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)

	-- Grant gold and XP only to the caster
	target:SetDeathXP(0)
	target:SetMinimumGoldBounty(0)
	target:SetMaximumGoldBounty(0)
	target:Kill(ability, caster)
	caster:AddExperience(bonus_xp, false, false)
	caster:ModifyGold(bonus_gold, true, 0)
end

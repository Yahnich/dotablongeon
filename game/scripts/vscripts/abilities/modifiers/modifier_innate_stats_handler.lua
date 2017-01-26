modifier_innate_stats_handler = class({})

function modifier_innate_stats_handler:IsHidden()
	return true
end

function modifier_innate_stats_handler:RemoveOnDeath()
	return false
end

function modifier_innate_stats_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ABILITY_START,
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_innate_stats_handler:GetModifierAttackSpeedBonus_Constant()
	return 25
end

function modifier_innate_stats_handler:GetModifierPercentageCooldown()
	if IsServer() then
		local cdr = self:GetParent():GetCooldownReduction()
		return cdr
	else
		local cdr = CustomNetTables:GetTableValue( "hero", self:GetParent():GetUnitName()).cooldownReduction
		return cdr
	end
end

function modifier_innate_stats_handler:GetModifierConstantHealthRegen()
	return self:GetParent():GetStrength() * HP_REGEN_PER_STR - self:GetParent():GetStrength() * 0.03
end

function modifier_innate_stats_handler:OnAbilityStart(params)
	if params.unit == self:GetParent() then
	end
end

function modifier_innate_stats_handler:GetModifierTotalDamageOutgoing_Percentage(params)
	if IsServer() and params.attacker == self:GetParent() and params.inflictor then
		if RollPercentage(self:GetParent():GetCritChance()) then
			PlayCrit(params.attacker, params.target, params.inflictor, params.damage * self:GetParent():GetCritAmount())
			return self:GetParent():GetCritAmount() * 100 - 100
		end
		return nil
	end
end



function modifier_innate_stats_handler:OnAbilityFullyCast(params)
	if params.unit == self:GetParent() then
		if params.ability.IsBasicAttack and params.ability:IsBasicAttack() then
			self:GetParent():IncreasePrimaryResourceAmount(self:GetParent():GetPrimaryResourceGainOnHit())
		end
		self:GetParent().lastEventTime = GameRules:GetGameTime()
	elseif params.target and params.target == self:GetParent() then
		self:GetParent():IncreasePrimaryResourceAmount(1)
		self:GetParent().lastEventTime = GameRules:GetGameTime()
	end
end

function PlayCrit( hAttacker, hVictim, hAbility, flDamage )
	local ability = hAbility
	local color = Vector(0,0,0)
	if ability:GetAbilityDamageType() == 1 then
		local bloodEffect = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
		if not (hVictim:IsCreature() or hVictim:IsCreep()) or hVictim:IsTower() then
			bloodEffect = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf"
		end
		local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
		ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
		local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
		ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
		ParticleManager:SetParticleControlEnt( nFXIndex, 10, hVictim, PATTACH_ABSORIGIN_FOLLOW, "", hVictim:GetAbsOrigin(), true )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
		color = Vector(255,0,0)
		EmitSoundOn("Hero_Juggernaut.BladeDance", hVictim)
	elseif ability:GetAbilityDamageType() == 4 then
		local trueDamageType = ability:GetElementalDamageType()
		if trueDamageType - DAMAGE_TYPE_NATURE >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_NATURE
			local bloodEffect = "particles/phantom_assassin_naturecrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			if color == Vector(0,0,0) then color = Vector(154,205,50) end
			color = (color + Vector(154,205,50)) /2
			EmitSoundOn("Hero_Treant.LeechSeed.Target", hVictim)
		end
		if trueDamageType - DAMAGE_TYPE_SPIRIT >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_SPIRIT
			local bloodEffect = "particles/phantom_assassin_spiritcrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			if color == Vector(0,0,0) then color = Vector(255,255,224) end
			color = (color + Vector(255,255,224)) /2
			EmitSoundOn("Hero_Pugna.NetherWard.Attack.Wight", hVictim)
		end
		if trueDamageType - DAMAGE_TYPE_LIGHTNING >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_LIGHTNING
			local bloodEffect = "particles/phantom_assassin_lightningcrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			if color == Vector(0,0,0) then color = Vector(255,255,0) end
			color = (color + Vector(255,255,0)) /2
			EmitSoundOn("Hero_Zuus.GodsWrath.PreCast", hVictim)
		end
		if trueDamageType - DAMAGE_TYPE_ICE >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_ICE
			local bloodEffect = "particles/phantom_assassin_icecrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			if color == Vector(0,0,0) then color = Vector(240,248,255) end
			color = (color + Vector(200,200,255)) /2
			EmitSoundOn("Hero_Crystal.Death", hVictim)
		end
		if trueDamageType - DAMAGE_TYPE_FIRE >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_FIRE
			local bloodEffect = "particles/phantom_assassin_firecrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			if color == Vector(0,0,0) then color = Vector(200,69,0) end
			color = (color + Vector(200,69,0)) /2
			EmitSoundOn("Hero_Jakiro.LiquidFire", hVictim)
		end
		if trueDamageType - DAMAGE_TYPE_PURE >= 0 then
			trueDamageType = trueDamageType - DAMAGE_TYPE_NATURE
			local bloodEffect = "particles/phantom_assassin_arcanecrit_impact.vpcf"
			local nFXIndex = ParticleManager:CreateParticle( bloodEffect, PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hVictim, PATTACH_POINT_FOLLOW, "attach_hitloc", hVictim:GetAbsOrigin(), true )
			ParticleManager:SetParticleControl( nFXIndex, 1, hVictim:GetAbsOrigin() )
			local flHPRatio = math.min( 1.0, hVictim:GetMaxHealth() / 200 )
			ParticleManager:SetParticleControlForward( nFXIndex, 1, RandomFloat( 0.5, 1.0 ) * flHPRatio * ( hAttacker:GetAbsOrigin() - hVictim:GetAbsOrigin() ):Normalized() )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
			color = Vector(255,0,255)
			EmitSoundOn("Hero_Invoker.EMP.Discharge", hVictim)
		end
	end
	hVictim:ShowPopup( {
						PostSymbol = 4,
						Color = color,
						Duration = 2,
						Number = flDamage,
						pfx = "spell"} )
end


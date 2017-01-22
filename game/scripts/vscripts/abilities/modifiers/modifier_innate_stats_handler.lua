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
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK,
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

function modifier_innate_stats_handler:OnAttackStart(params)
	if params.attacker == self:GetParent() then
		self:GetParent():RemoveModifierByName("modifier_innate_stats_handler_critical")
		if RollPercentage( self:GetParent():GetCritChance() ) then
			self:GetParent():AddNewModifier( self:GetParent(), nil, "modifier_innate_stats_handler_critical", {})
		end
	end
end

function modifier_innate_stats_handler:OnAttack(params)
	if params.attacker == self:GetParent() then
		self:GetParent():IncreasePrimaryResourceAmount(self:GetParent():GetPrimaryResourceGainOnHit())
		self:GetParent().lastAbilityUsedTime = GameRules:GetGameTime()
	elseif params.target == self:GetParent() then
		self:GetParent():IncreasePrimaryResourceAmount(1)
		self:GetParent().lastAbilityUsedTime = GameRules:GetGameTime()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

modifier_innate_stats_handler_critical = class({})

function modifier_innate_stats_handler_critical:IsHidden()
	return true
end

function modifier_innate_stats_handler_critical:OnCreated()
	if IsServer() then
		self.criticalhit = self:GetParent():GetCritAmount() * 100
	end
end

function modifier_innate_stats_handler_critical:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
	}
	return funcs
end

function modifier_innate_stats_handler_critical:OnAttackFail(params)
	if params.attacker == self:GetParent() then
		self:Destroy()
	end
end

function modifier_innate_stats_handler_critical:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		EmitSoundOn("Hero_Juggernaut.BladeDance", self:GetParent())
		PlayCrit(self:GetParent(), params.target)
		self:Destroy()
	end
end

function modifier_innate_stats_handler_critical:GetModifierPreAttack_CriticalStrike()
	return self.criticalhit
end

function PlayCrit( hAttacker, hVictim )
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
end


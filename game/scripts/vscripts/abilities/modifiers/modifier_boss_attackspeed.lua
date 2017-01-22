modifier_boss_attackspeed = class({})

function modifier_boss_attackspeed:IsHidden()
	return true
end

function modifier_boss_attackspeed:OnCreated()
	self.criticalChance = self:GetParent():GetCritChance()
	self.cooldownReduction = self:GetParent():GetCooldownReduction()
	self.criticalAmount = self:GetParent():GetCritAmount()
end

function modifier_boss_attackspeed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_boss_attackspeed:GetModifierAttackSpeedBonus_Constant( params )
	return 100
end

function modifier_boss_attackspeed:GetCriticalHitAmount( params )
	return self.criticalAmount
end

function modifier_boss_attackspeed:GetCriticalHitChance( params )
	return self.criticalChance
end

function modifier_boss_attackspeed:GetModifierPercentageCooldown()
	return self.cooldownReduction
end




spellsword_spark_slice = spellsword_spark_slice or class({})


function spellsword_spark_slice:StopSwingGesture()
	if self.nCurrentGesture ~= nil then
		self:GetCaster():RemoveGesture( self.nCurrentGesture )
		self.nCurrentGesture = nil
	end
end

function spellsword_spark_slice:StartSwingGesture( nAction, bDelayed )
	if self.nCurrentGesture ~= nil then
		self:GetCaster():RemoveGesture( self.nCurrentGesture )
	end
	local playbackRate = self:GetCaster():GetAttackAnimationPoint() / self:GetCaster():GetCastPoint(true)
	if bDelayed then playbackRate = playbackRate * 3 end
	self.nCurrentGesture = nAction
	self:SetOverrideCastPoint(self:GetCaster():GetCastPoint(true))
	self:GetCaster():StartGestureWithPlaybackRate( nAction, playbackRate )
end

if IsServer() then
	function spellsword_spark_slice:OnAbilityPhaseStart()
		local result = self.BaseClass.OnAbilityPhaseStart( self )
		local distance = (self:GetCursorTarget():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D()
		if distance <= self:GetCaster():GetAttackRange() + 25 and result then
			self:StartSwingGesture( ACT_DOTA_ATTACK, false )
		elseif distance <= self:GetSpecialValueFor("teleport_distance") and distance >= self:GetCaster():GetAttackRange()  + 25 then
			self:StartSwingGesture( ACT_DOTA_IDLE_RARE, true )
		end
		return result
	end

	function spellsword_spark_slice:OnAbilityPhaseInterrupted()
		self:StopSwingGesture()
	end

	function spellsword_spark_slice:OnSpellStart()
		local hTarget = self:GetCursorTarget()
		local distance = (hTarget:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D()	
		if distance <= self:GetSpecialValueFor("teleport_distance") and distance >= self:GetCaster():GetAttackRange() + 25 then
			FindClearSpaceForUnit(self:GetCaster(), hTarget:GetAbsOrigin(), true)
			self:StartSwingGesture( ACT_DOTA_ATTACK, true )
		end
		local nDamageAmount = self:GetCaster():GetRandomBaseDamage() 
		ApplyDamage( {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = nDamageAmount,
			damage_type = DAMAGE_TYPE_PURE,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
			ability = self
		} )
	end
end

function spellsword_spark_slice:GetCastRange( vLocation, hTarget )
	if hTarget then
		local distance = (hTarget:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Length2D()
		if distance <= self:GetSpecialValueFor("teleport_distance") and distance >= self:GetCaster():GetAttackRange() then
			return self:GetSpecialValueFor("teleport_distance")
		end	
	end
	return self:GetCaster():GetAttackRange() + 25
end

function spellsword_spark_slice:GetCooldown()
	return tonumber(string.format("%.2f", self:GetCaster():GetSecondsPerAttack()))
end

function spellsword_spark_slice:IsBasicAttack()
	return true
end



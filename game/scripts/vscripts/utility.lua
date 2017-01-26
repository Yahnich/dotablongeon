-- CUSTOM STATS
INNATE_CRIT_CHANCE = 10
INNATE_CRIT_AMOUNT = 120
CRIT_AMOUNT_PER_STR = 0.75
HP_REGEN_PER_STR = 0.5
CRIT_CHANCE_PER_AGI = 0.2
ELEMENTAL_RESIST_PER_INT = 0.143
CDR_PER_INT = 0.2
DAMAGE_TYPE_FIRE = 16
DAMAGE_TYPE_ICE = 32
DAMAGE_TYPE_LIGHTNING = 64
DAMAGE_TYPE_SPIRIT = 128
DAMAGE_TYPE_NATURE = 256

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

function PrintAll(t)
	for k,v in pairs(t) do
		print(k,v)
	end
end

function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
        t1[name] = info
    end
end

function SendClientSync(key, value)
	CustomNetTables:SetTableValue( "syncing_purposes",key, {value = value} )
end

function GetClientSync(key)
 	local value = CustomNetTables:GetTableValue( "syncing_purposes", key).value
	return value
end

function CalculateDistance(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local distance = (pos1 - pos2):Length2D()
	return distance
end

function CalculateDirection(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local direction = (pos1 - pos2):Normalized()
	return direction
end

----- BASE NPC ---------

function CDOTA_BaseNPC:ShowPopup( data )
    if not data then return end

    local target = self
    if not target then error( "ShowNumber without target" ) end
    local number = tonumber( data.Number or nil )
    local pfx = data.Type or "miss"
    local player = data.Player or false
    local color = data.Color or Vector( 255, 255, 255 )
    local duration = tonumber( data.Duration or 1 )
    local presymbol = tonumber( data.PreSymbol or nil )
    local postsymbol = tonumber( data.PostSymbol or nil )

    local path = "particles/msg_fx/msg_" .. pfx .. ".vpcf"
    local particle = ParticleManager:CreateParticle(path, PATTACH_OVERHEAD_FOLLOW, target)
    if player then
		local playerent = PlayerResource:GetPlayer( self:GetPlayerID() )
        local particle = ParticleManager:CreateParticleForPlayer( path, PATTACH_OVERHEAD_FOLLOW, target, playerent)
    end
	
	if number then
		number = math.floor(number+0.5)
	end

    local digits = 0
    if number ~= nil then digits = string.len(number) end
    if presymbol ~= nil then digits = digits + 1 end
    if postsymbol ~= nil then digits = digits + 1 end

    ParticleManager:SetParticleControl( particle, 1, Vector( presymbol, number, postsymbol ) )
    ParticleManager:SetParticleControl( particle, 2, Vector( duration, digits, 0 ) )
    ParticleManager:SetParticleControl( particle, 3, color )
end

function CDOTA_BaseNPC:GetBaseElementalArmor()
	if self:IsHero() then
		self.baseElementalArmor = self:GetIntellect()*ELEMENTAL_RESIST_PER_INT
	else
		self.baseElementalArmor = 0
	end
	return self.baseElementalArmor or 0
end

function CDOTA_BaseNPC:GetBaseFireArmor()
	local baseArmor = self:GetBaseElementalArmor()
	local fireArmor = GameRules.UnitKV[self:GetUnitName()]["FireResistance"] or 0
	self.baseFireArmor = baseArmor + fireArmor
	return self.baseFireArmor
end

function CDOTA_BaseNPC:GetBaseIceArmor()
	local baseArmor = self:GetBaseElementalArmor()
	local iceArmor = GameRules.UnitKV[self:GetUnitName()]["IceResistance"] or 0
	self.baseIceArmor = baseArmor + iceArmor
	return self.baseIceArmor
end

function CDOTA_BaseNPC:GetBaseLightningArmor()
	local baseArmor = self:GetBaseElementalArmor()
	local lightningArmor = GameRules.UnitKV[self:GetUnitName()]["LightningResistance"] or 0
	self.baseLightningArmor = baseArmor + lightningArmor
	return self.baseLightningArmor
end

function CDOTA_BaseNPC:GetBaseSpiritArmor()
	local baseArmor = self:GetBaseElementalArmor()
	local spiritArmor = GameRules.UnitKV[self:GetUnitName()]["SpiritResistance"] or 0
	self.baseSpiritArmor = baseArmor + spiritArmor
	return self.baseSpiritArmor
end

function CDOTA_BaseNPC:GetBaseNatureArmor()
	local baseArmor = self:GetBaseElementalArmor()
	local natureArmor = GameRules.UnitKV[self:GetUnitName()]["NatureResistance"] or 0
	self.baseNatureArmor = baseArmor + natureArmor
	return self.baseNatureArmor
end

function CDOTA_BaseNPC:GetFireArmor()
	local baseArmor = self:GetBaseFireArmor()
	local bonusArmor = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetBonusFireArmor and v:GetName() ~= "modifier_innate_stats_handler" then
			bonusArmor = bonusArmor + v:GetBonusFireArmor()
		end
	end
	local armor = baseArmor + bonusArmor
	return armor
end

function CDOTA_BaseNPC:GetIceArmor()
	local baseArmor = self:GetBaseIceArmor()
	local bonusArmor = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetBonusIceArmor and v:GetName() ~= "modifier_innate_stats_handler" then
			bonusArmor = bonusArmor + v:GetBonusIceArmor()
		end
	end
	local armor = baseArmor + bonusArmor
	return armor
end

function CDOTA_BaseNPC:GetLightningArmor()
	local baseArmor = self:GetBaseLightningArmor()
	local bonusArmor = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetBonusLightningArmor and v:GetName() ~= "modifier_innate_stats_handler" then
			bonusArmor = bonusArmor + v:GetBonusLightningArmor()
		end
	end
	local armor = baseArmor + bonusArmor
	return armor
end

function CDOTA_BaseNPC:GetSpiritArmor()
	local baseArmor = self:GetBaseSpiritArmor()
	local bonusArmor = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetBonusSpiritArmor and v:GetName() ~= "modifier_innate_stats_handler" then
			bonusArmor = bonusArmor + v:GetBonusSpiritArmor()
		end
	end
	local armor = baseArmor + bonusArmor
	return armor
end

function CDOTA_BaseNPC:GetNatureArmor()
	local baseArmor = self:GetBaseNatureArmor()
	local bonusArmor = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetBonusNatureArmor and v:GetName() ~= "modifier_innate_stats_handler" then
			bonusArmor = bonusArmor + v:GetBonusNatureArmor()
		end
	end
	local armor = baseArmor + bonusArmor
	return armor
end

function CDOTA_BaseNPC:GetFireResistance()
	local fireArmor = self:GetFireArmor()
	local resistance = 	0.06*fireArmor/(1+(0.06*fireArmor))
	return resistance
end

function CDOTA_BaseNPC:GetIceResistance()
	local iceArmor = self:GetIceArmor()
	local resistance = 	0.06*iceArmor/(1+(0.06*iceArmor))
	return resistance
end

function CDOTA_BaseNPC:GetLightningResistance()
	local lightningArmor = self:GetLightningArmor()
	local resistance = 	0.06*lightningArmor/(1+(0.06*lightningArmor))
	return resistance
end

function CDOTA_BaseNPC:GetSpiritResistance()
	local spiritArmor = self:GetSpiritArmor()
	local resistance = 	0.06*spiritArmor/(1+(0.06*spiritArmor))
	return resistance
end

function CDOTA_BaseNPC:GetNatureResistance()
	local natureArmor = self:GetNatureArmor()
	local resistance = 	0.06*natureArmor/(1+(0.06*natureArmor))
	return resistance
end


function CDOTA_BaseNPC:GetLastActionTime()
	self.lastEventTime = self.lastEventTime or GameRules:GetGameTime()
	local lastActionTime = self.lastEventTime
	if self:GetLastAttackTime() > self.lastEventTime then
		lastActionTime = self:GetLastAttackTime()
	end
	return lastActionTime
end


function CDOTA_BaseNPC:GetAverageBaseDamage()
	return (self:GetBaseDamageMax() + self:GetBaseDamageMin())/2
end

function CDOTA_BaseNPC:GetRandomBaseDamage()
	local rndDamage = RandomInt(self:GetBaseDamageMin(), self:GetBaseDamageMax())
	return rndDamage
end

function CDOTA_BaseNPC:SetAverageBaseDamage(average, variance) -- variance is in percent (50 not 0.5)
	local var = variance or 0
	self:SetBaseDamageMax(average*(1+(var/100)))
	self:SetBaseDamageMin(average*(1+(var/100)))
end

---- BASE HERO -----

function CDOTA_BaseNPC_Hero:GetInnateCritChance()
	local chance = (1-INNATE_CRIT_CHANCE/100) * (1-CRIT_CHANCE_PER_AGI/100)^(self:GetAgility()) -- Calculate chance to not crit
	self.innateCritChance = (1 - chance) * 100 -- Transform into chance to crit
	return self.innateCritChance
end

function CDOTA_BaseNPC_Hero:GetInnateCritAmount()
	self.innateCritAmount = (INNATE_CRIT_AMOUNT + (self:GetStrength() * CRIT_AMOUNT_PER_STR)) / 100
	return self.innateCritAmount
end

function CDOTA_BaseNPC_Hero:GetInnateCooldownReduction()
	self.innateCooldownReduction = math.floor(self:GetIntellect() * CDR_PER_INT)
	return self.innateCooldownReduction
end

function CDOTA_BaseNPC_Hero:GetCritChance()
	self.addedCritChance = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetCriticalHitAmount then
			self.addedCritChance = self.addedCritChance + v:GetCriticalHitChance()
		end
	end
	local chance = (1 - self:GetInnateCritChance()) * (1 - self.addedCritChance) -- Calculate chance to not crit
	self.trueCritChance = 1 - chance -- Transform into chance to crit
	return self.innateCritChance
end

function CDOTA_BaseNPC_Hero:GetCritAmount()
	local allmodifiers = self:FindAllModifiers()
	self.addedCritAmount = 0
	for k,v in pairs(allmodifiers) do
		if v.GetCriticalHitAmount then
			self.addedCritAmount = self.addedCritAmount + v:GetCriticalHitAmount()
		end
	end
	self.trueCritAmount = self:GetInnateCritAmount() + (self.addedCritAmount / 100)
	return self.innateCritAmount
end

function CDOTA_BaseNPC_Hero:GetCooldownReduction()
	self.addedCooldownReduction = 0
	local allmodifiers = self:FindAllModifiers()
	for k,v in pairs(allmodifiers) do
		if v.GetCriticalHitAmount and v:GetName() ~= "modifier_innate_stats_handler" then
			self.addedCooldownReduction = self.addedCooldownReduction + v:GetCooldownReduction()
		end
	end
	self.trueCooldownReduction = math.floor( self:GetInnateCooldownReduction() * (100+self.addedCooldownReduction)/100 )
	return self.innateCooldownReduction
end

function CDOTA_BaseNPC_Hero:GetPrimaryResource()
	self.primaryResourceType = self.primaryResourceType or GameRules.UnitKV[self:GetUnitName()]["StatusResource"] or "Mana"
	return self.primaryResourceType
end

function CDOTA_BaseNPC_Hero:GetBasePrimaryResource()
	return GameRules.UnitKV[self:GetUnitName()]["StatusResource"] or "Mana"
end

function CDOTA_BaseNPC_Hero:GetPrimaryResourceAmount()
	if self:GetPrimaryResource() ~= "Mana" then
		self.currPrimaryResource = self.currPrimaryResource
		if not self.currPrimaryResource then
			if self:GetPrimaryResource() == "Rage" then
				self.currPrimaryResource = 0
			else
				self.currPrimaryResource = self:GetMaxPrimaryResourceAmount()
			end
		end
		return self.currPrimaryResource
	else
		return self:GetMana()
	end
end

function CDOTA_BaseNPC_Hero:GetMaxPrimaryResourceAmount()
	if self:GetPrimaryResource() ~= "Mana" then
		self.maxPrimaryResource = self.maxPrimaryResource or GameRules.UnitKV[self:GetUnitName()]["Status"..self:GetPrimaryResource()]
		return self.maxPrimaryResource
	else
		return self:GetMaxMana()
	end
end

function CDOTA_BaseNPC_Hero:GetPrimaryResourceRegen()
	if self:GetPrimaryResource() ~= "Mana" then
		self.primaryResourceRegeneration = self.primaryResourceRegeneration or GameRules.UnitKV[self:GetUnitName()]["Status"..self:GetPrimaryResource().."Regen"] or 0
		return self.primaryResourceRegeneration
	else
		return self:GetManaRegen()
	end
end

function CDOTA_BaseNPC_Hero:GetPrimaryResourceGainOnHit()
	self.primaryResourceOnHit = self.primaryResourceOnHit or GameRules.UnitKV[self:GetUnitName()]["Status"..self:GetPrimaryResource().."OnHit"] or 0
	return self.primaryResourceOnHit
end

function CDOTA_BaseNPC_Hero:ReducePrimaryResourceAmount(amount)
	if self.currPrimaryResource >= 0 then
		self.currPrimaryResource = self.currPrimaryResource - amount
	end
	if self.currPrimaryResource < 0 then
		self.currPrimaryResource = 0
	end
	if self:GetPrimaryResourceAmount() > self:GetMaxPrimaryResourceAmount() then
		self.currPrimaryResource = self.maxPrimaryResource
	end
end

function CDOTA_BaseNPC_Hero:IncreasePrimaryResourceAmount(amount)
	self.currPrimaryResource = self.currPrimaryResource or self:GetMaxPrimaryResourceAmount()
	self.maxPrimaryResource = self.maxPrimaryResource or self:GetMaxPrimaryResourceAmount()
	if self.currPrimaryResource < self.maxPrimaryResource then
		self.currPrimaryResource = self.currPrimaryResource + amount
	end
	if self:GetPrimaryResourceAmount() > self:GetMaxPrimaryResourceAmount() then
		self.currPrimaryResource = self.maxPrimaryResource
	end
end


---------- Abilities -------------

function CDOTABaseAbility:GetPrimaryResourceCost()
	if GameRules.AbilityKV[self:GetName()] then
		return GameRules.AbilityKV[self:GetName()]["Ability"..self:GetCaster():GetPrimaryResource().."Cost"] or 0
	else
		return 0
	end
end

function CDOTABaseAbility:GetElementalDamageType()
	if not self.elementalDamageType then
		if GameRules.AbilityKV[self:GetName()] then
			local stringCheck = split(GameRules.AbilityKV[self:GetName()]["AbilityElementalDamageType"], " | ")
			local damageType = 0
			for _, damageTypeVal in pairs(stringCheck) do
				damageType = damageType + GameRules.ElementalDamageEnum[damageTypeVal]
			end
			self.elementalDamageType = damageType
		end
	end
	return self.elementalDamageType
end

function CDOTABaseAbility:SetElementalDamageType(newVal)
	self.elementalDamageType = newVal
end

function CDOTABaseAbility:Refresh()
	if not self:IsActivated() then
		self:SetActivated(true)
	end
    self:EndCooldown()
end
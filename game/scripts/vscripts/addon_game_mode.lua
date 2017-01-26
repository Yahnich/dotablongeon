-- SETUP GLOBAL VARIABLES
DAMAGE_TYPE_FIRE = 16
DAMAGE_TYPE_ICE = 32
DAMAGE_TYPE_LIGHTNING = 64
DAMAGE_TYPE_SPIRIT = 128
DAMAGE_TYPE_NATURE = 256

GameRules.ElementalDamageEnum = {["DAMAGE_TYPE_ARCANE"] = DAMAGE_TYPE_PURE,
								 ["DAMAGE_TYPE_FIRE"] = DAMAGE_TYPE_FIRE,
								 ["DAMAGE_TYPE_ICE"] = DAMAGE_TYPE_ICE,
								 ["DAMAGE_TYPE_LIGHTNING"] = DAMAGE_TYPE_LIGHTNING,
								 ["DAMAGE_TYPE_SPIRIT"] = DAMAGE_TYPE_SPIRIT,
								 ["DAMAGE_TYPE_NATURE"] = DAMAGE_TYPE_NATURE}

RAGE_DECAY_RATE = 10
RAGE_DECAY_TIME = 4

-- LINK GLOBAL MODIFIERS
LinkLuaModifier( "modifier_innate_stats_handler", "abilities/modifiers/modifier_innate_stats_handler.lua" ,LUA_MODIFIER_MOTION_NONE )


require('utility')

if CDotabloGameMode == nil then
	CDotabloGameMode = class({})
end

function Precache( context )
	-- PARTICLE PRECACHE
	PrecacheResource( "particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_naturecrit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_spiritcrit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_icecrit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_lightningcrit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_firecrit_impact.vpcf", context)
	PrecacheResource( "particle", "particles/phantom_assassin_arcanecrit_impact.vpcf", context)
	-- SOUND PRECACHE
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts", context)
end

function Activate()
	GameRules.CGameMode = CDotabloGameMode()
	GameRules.CGameMode:InitGameMode()
end

function CDotabloGameMode:InitGameMode()
	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	MergeTables(GameRules.UnitKV, LoadKeyValues("scripts/npc/npc_units_custom.txt"))
	MergeTables(GameRules.UnitKV, LoadKeyValues("scripts/npc/npc_units.txt"))
	
	GameRules.AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
	MergeTables(GameRules.AbilityKV, LoadKeyValues("scripts/npc/npc_items_custom.txt"))
	
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 0.1 )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap( CDotabloGameMode, "FilterOrders" ), self )
	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap( CDotabloGameMode, "FilterDamage" ), self )
	
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap( CDotabloGameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap( CDotabloGameMode, "OnHeroPick"), self )
end

function CDotabloGameMode:FilterDamage( filterTable )
    local total_damage_team = 0
    local dps = 0
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end
	local inflictor = filterTable["entindex_inflictor_const"]
	local damageType = filterTable["damagetype_const"]
	local damage = filterTable["damage"]
	
    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
	if inflictor then
		local ability = EntIndexToHScript( inflictor )
		if damageType == 4 then -- PURE DAMAGE IS ELEMENTAL DAMAGE, GETS REDUCED BY SPECIAL RESISTANCES, FILTER OUT TYPES FOR COMPOSITE DAMAGE TYPES
			local trueDamageType = ability:GetElementalDamageType()
			if trueDamageType - DAMAGE_TYPE_NATURE >= 0 then
				trueDamageType = trueDamageType - DAMAGE_TYPE_NATURE
				local reduction = 1 - victim:GetNatureResistance()
				filterTable["damage_const"] = damage * reduction
			end
			if trueDamageType - DAMAGE_TYPE_SPIRIT >= 0 then
				trueDamageType = trueDamageType - DAMAGE_TYPE_SPIRIT
				local reduction = 1 - victim:GetSpiritResistance()
				filterTable["damage_const"] = damage * reduction
			end
			if trueDamageType - DAMAGE_TYPE_LIGHTNING >= 0 then
				trueDamageType = trueDamageType - DAMAGE_TYPE_LIGHTNING
				local reduction = 1 - victim:GetLightningResistance()
				filterTable["damage_const"] = damage * reduction
			end
			if trueDamageType - DAMAGE_TYPE_ICE >= 0 then
				trueDamageType = trueDamageType - DAMAGE_TYPE_ICE
				local reduction = 1 - victim:GetIceResistance()
				filterTable["damage_const"] = damage * reduction
			end
			if trueDamageType - DAMAGE_TYPE_FIRE >= 0 then
				trueDamageType = trueDamageType - DAMAGE_TYPE_FIRE
				local reduction = 1 - victim:GetFireResistance()
				filterTable["damage_const"] = damage * reduction
			end
		end
	else
	end
	return true
end

function CDotabloGameMode:OnAbilityUsed(event)
	local hero = PlayerResource:GetSelectedHeroEntity(event.PlayerID)
	if not hero or not hero:IsHero() then return end
	local abilityused = hero:FindAbilityByName(event.abilityname)
	hero.lastEventTime = GameRules:GetGameTime()
	if not abilityused then return end
	if hero:GetPrimaryResource() ~= "Mana" then
		hero:ReducePrimaryResourceAmount(abilityused:GetPrimaryResourceCost())
	end
end

function CDotabloGameMode:FilterOrders( filterTable )
	if filterTable["order_type"] > 4 and filterTable["order_type"] < 10 and filterTable["queue"] == 0 then -- check if CAST is valid
		local ability = EntIndexToHScript( filterTable["entindex_ability"] )
		local unit = EntIndexToHScript( filterTable["units"]["0"] )
		if not (ability or unit:IsHero() or ability:IsItem()) then return true end
		if unit:GetPrimaryResourceAmount() < ability:GetPrimaryResourceCost() then
			return false
		end
	end
	return true
end

-- Evaluate the state of the game
function CDotabloGameMode:OnThink()
	if not GameRules:IsGamePaused() then
		for _,hero in pairs ( Entities:FindAllByName( "npc_dota_hero*")) do
			SendCurrentStatus(hero)
			if hero:GetPrimaryResource() ~= "Rage" then
				hero:IncreasePrimaryResourceAmount(hero:GetPrimaryResourceRegen()*0.1)
			elseif hero:GetLastActionTime() + RAGE_DECAY_TIME < GameRules:GetGameTime() then
				hero:ReducePrimaryResourceAmount(RAGE_DECAY_RATE*0.1)
			end
		end
	end
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 0.1
end

function CDotabloGameMode:OnHeroPick(event)
	local hero = EntIndexToHScript(event.heroindex)
	local player = hero:GetPlayerOwner()
	CustomGameEventManager:Send_ServerToPlayer( player, "Update_HPBar", {} )
	hero:AddNewModifier( hero, nil, "modifier_innate_stats_handler", {})
	
end

function SendCurrentStatus(hero)
	local key = hero:GetUnitName()
	CustomNetTables:SetTableValue( "hero", key, {HP = hero:GetHealth(), 
												maxHP = hero:GetMaxHealth(), 
												resourceType = hero:GetPrimaryResource(), 
												resource = hero:GetPrimaryResourceAmount(), 
												maxResource = hero:GetMaxPrimaryResourceAmount(), 
												resourceRegen = hero:GetPrimaryResourceRegen(),
												cooldownReduction = hero:GetCooldownReduction()})
end
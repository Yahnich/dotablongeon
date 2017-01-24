var ID = Players.GetLocalPlayer()
var playerHero = Players.GetPlayerSelectedHero(ID)
var newUI = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block")
UpdateHB(playerHero)
function UpdateHB(playerHero)
{
	var index = Players.GetLocalPlayerPortraitUnit()
	if(index != null){
		if (Entities.IsHero( index )){
			var netTable = CustomNetTables.GetTableValue( "hero", Entities.GetUnitName( Players.GetLocalPlayerPortraitUnit() ) )
			if (netTable != null){
				var resourceBar = newUI.FindChildTraverse("health_mana").FindChildTraverse("HealthManaContainer").FindChildTraverse("ManaContainer");
				resourceBar.style.hueRotation = null
				var color = "0deg"
				if(netTable.resourceType == "Arcane"){
					color = "35deg"
				} else if(netTable.resourceType == "Rage"){
					color = "125deg"
					resourceBar.style.brightness = "0.45"
					resourceBar.style.saturation = "1.35"
				} else if(netTable.resourceType == "Stamina"){
					color = "180deg"
				}
				resourceBar.style.hueRotation = color
				var resource = Math.floor(netTable.resource)
				var maxResource = Math.floor(netTable.maxResource)
				resourceBar.FindChildTraverse("ManaLabel").text = resource + " / " + maxResource;
				if(netTable.resourceRegen != null && netTable.resourceRegen != 0){
					resourceBar.FindChildTraverse("ManaRegenLabel").text = "+" + netTable.resourceRegen;
					resourceBar.FindChildTraverse("ManaRegenLabel").style.visibility = "visible"
				} else if(netTable.resourceRegen == 0){
					resourceBar.FindChildTraverse("ManaRegenLabel").style.visibility = "collapse"
				}
				var resourceProgress = resourceBar.FindChildTraverse("ManaProgress");
				resourceProgress.value = resource / maxResource;
			}
		} else {
			var resourceBar = newUI.FindChildTraverse("health_mana").FindChildTraverse("HealthManaContainer").FindChildTraverse("ManaContainer");
			resourceBar.style.hueRotation = null
			var resource = Entities.GetMana( index )
			var maxResource = Entities.GetMaxMana( index )
			resourceBar.FindChildTraverse("ManaLabel").text = resource + " / " + maxResource;
			if(Entities.GetManaThinkRegen( index ) != 0){
				resourceBar.FindChildTraverse("ManaRegenLabel").text = "+" +  Entities.GetManaThinkRegen( index ).toFixed(2);
				resourceBar.FindChildTraverse("ManaRegenLabel").style.visibility = "visible"
			} else if(Entities.GetManaThinkRegen( index ) == 0){
				resourceBar.FindChildTraverse("ManaRegenLabel").style.visibility = "collapse"
			}
			var resourceProgress = resourceBar.FindChildTraverse("ManaProgress");
			resourceProgress.value = resource / maxResource;
		}
	}
	$.Schedule(1/120, function() {
             UpdateHB(playerHero);
        });
}

		
		
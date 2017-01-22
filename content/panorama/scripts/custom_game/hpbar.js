var ID = Players.GetLocalPlayer()
var playerHero = Players.GetPlayerSelectedHero(ID)
var newUI = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block")
UpdateHB(playerHero)
function UpdateHB(playerHero)
{
	if (playerHero != null){
		var netTable = CustomNetTables.GetTableValue( "hero", playerHero )
		if (netTable != null){
			var resourceBar = newUI.FindChildTraverse("health_mana").FindChildTraverse("HealthManaContainer").FindChildTraverse("ManaContainer");
			var color = "#FFFFFF"
			if(netTable.resourceType == "Arcane"){
				color = "#F000F0"
			} else if(netTable.resourceType == "Rage"){
				color = "#FF0000"
			} else if(netTable.resourceType == "Stamina"){
				color = "#FFFF00"
			}
			resourceBar.style.washColor = color
			var resource = Math.floor(netTable.resource)
			resourceBar.FindChildTraverse("ManaLabel").text = resource + " / " + netTable.maxResource;
			var resourceProgress = resourceBar.FindChildTraverse("ManaProgress");
			resourceProgress.value = netTable.resource / netTable.maxResource;
		}
	}
	
	$.Schedule(1/120, function() {
             UpdateHB(playerHero);
        });
}

		
		
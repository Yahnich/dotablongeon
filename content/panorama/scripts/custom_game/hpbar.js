var ID = Players.GetLocalPlayer()
var PlayerEntityIndex = Players.GetPlayerHeroEntityIndex(ID)
var team = Entities.GetTeamNumber( PlayerEntityIndex )
GameEvents.Subscribe( "Update_HPBar", UpdateHB);
function UpdateHB(data)
{
	if (typeof data != 'undefined') {
		if (data.HP == 0 ){ $("#hp_bar_general").visibility = false}
		$("#hp_bar_parent_hp_clip").style.clip = "rect(" + (100 - data.HP/data.Max_HP*100) + "% ," + "100%" + ", 100% ,0% )";
		$("#hp_bar_current").text = Number((data.HP).toFixed(0));
		$("#hp_bar_total").text = Number((data.Max_HP).toFixed(0));
		$("#hp_bar_avatarhero").heroname = data.Name;
		$("#hp_bar_name").text = $.Localize("#" + data.Name);
		if (data.Max_Resource != 0){
			$("#hp_bar_parent_resource_clip").style.clip = "rect(" + (100 - data.Resource/data.Max_Resource*100) + "% ," + "100%" + ", 100% ,0% )";
			if (data.ResourceType == "Stamina"){$("#mana_bar_dynamic_container").style.washColor = "#FFFF00"}
			else if (data.ResourceType == "Rage"){$("#mana_bar_dynamic_container").style.washColor = "#FF0000"}
			else if (data.ResourceType == "Arcane"){$("#mana_bar_dynamic_container").style.washColor = "#551A8B"}
			else {$("#mana_bar_dynamic_container").style.washColor = "#0000FF"}
			$("#hp_bar_current_mana").text = Number((data.Resource).toFixed(0));
			$("#hp_bar_total_mana").text = Number((data.Max_Resource).toFixed(0));
		} else{
			$("#hp_bar_parent_mana").style.clip = "rect( 0% , 100%, 100% ,0% )";
		}

	} else { $("#hp_bar_general").visibility = false}
}

		
		
exec function ahdal_reset()
{
	var UserSettings : CInGameConfigWrapper;
	
	UserSettings = theGame.GetInGameConfigWrapper();
	UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'isLoaded', "false" );
	theGame.SaveUserSettings();
	
	GetWitcherPlayer().GetAutoLootConfig().Init();
}

exec function ahdal_loadpreset( preset : name )
{
	var UserSettings : CInGameConfigWrapper;
	
	UserSettings = theGame.GetInGameConfigWrapper();
	UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', preset, "true" );
	theGame.SaveUserSettings();
	
	GetWitcherPlayer().GetAutoLootConfig().TryLoadPreset();
}

exec function ahdal_clearnotifications()
{
	var temp : array<float>;
	var msg : string;
	
	msg = "";
	temp = GetWitcherPlayer().GetAutoLootNotificationManager().DebugReset();
	
	msg += "AutoLoot DEBUG: Clearing notification manager...<br/>";
	msg += "- Names Cleared: " + FloatToString(temp[0]) + "<br/>";
	msg += "- Quantites Cleared: " + FloatToString(temp[1]) + "<br/>";
	msg += "- Icons Cleared: " + FloatToString(temp[2]) + "<br/>";
	msg += "- Descriptions Cleared: " + FloatToString(temp[3]) + "<br/>";
	msg += "- Sounds Cleared: " + FloatToString(temp[4]) + "<br/>";
	msg += "- Items Looted Before Reset: " + FloatToString(temp[5]);
	
	theGame.GetGuiManager().ShowNotification( msg, 7500.0 );
}

exec function getconfigval( group : name, setting : name, optional time : int )
{
	var UserSettings : CInGameConfigWrapper;
	var msg : string;
	var newTime : float;
	var val : string;
	
	UserSettings = theGame.GetInGameConfigWrapper();
	
	msg += "Checking config value...<br/>";
	val = UserSettings.GetVarValue( group, setting );
	
	if( val == "" )
	{
		theGame.GetGuiManager().ShowNotification( msg + "Invalid group/setting names!", 5000.0 );
		return;
	}
	
	if(time)
		newTime = time * 1000.0;
	else
		newTime = 7500.0;
	
	msg += "Group: " + group + "<br/>";
	msg += "Setting: " + setting + "<br/>";
	msg += "Value: " + val;
	theGame.GetGuiManager().ShowNotification( msg, newTime );
}

exec function setconfigval( group : name, setting : name , val : string, optional time : int, optional save : bool )
{
	var UserSettings : CInGameConfigWrapper;
	var msg : string;
	var newTime : float;
	var oldVal : string;
	
	UserSettings = theGame.GetInGameConfigWrapper();
	
	msg += "Setting config value...<br/>";
	oldVal = UserSettings.GetVarValue( group, setting );
	
	if( oldVal == "" )
	{
		theGame.GetGuiManager().ShowNotification( msg + "Invalid group/setting names!", 5000.0 );
		return;
	}
	
	if( oldVal == val )
	{
		theGame.GetGuiManager().ShowNotification( msg + "New value == config value!", 5000.0 );
		return;
	}
	
	if(time)
		newTime = time * 1000.0;
	else
		newTime = 7500.0;
	
	msg += "Group: " + group + "<br/>";
	msg += "Setting: " + setting + "<br/>";
	msg += "Value (OLD): " + oldVal + "<br/>";
	msg += "Value (NEW): " + val + "<br/>";
	UserSettings.SetVarValue( group, setting, val );
	
	if(save)
	{
		theGame.SaveUserSettings();
		msg += "(Saved to user config)";
	}
	else
		msg += "(Not saved to user config)";
	
	theGame.GetGuiManager().ShowNotification( msg, newTime );
}

exec function getplayerpos( optional mode : string, optional showTarget : bool, optional time : int )
{
	var coordType, msg : string;
	var vec1, vec2 : Vector;
	var newTime : float;
	
	if(mode == "local")
	{
		vec1 = thePlayer.GetLocalPosition();
		vec2 = theGame.GetInteractionsManager().GetActiveInteraction().GetEntity().GetLocalPosition();
		coordType = "local coords:<br/>";
	}
	else
	{
		vec1 = thePlayer.GetWorldPosition();
		vec2 = theGame.GetInteractionsManager().GetActiveInteraction().GetEntity().GetWorldPosition();
		coordType = "world coords:<br/>";
	}
	
	msg += "Player " + coordType;
	msg += "X: " + vec1.X + "<br/>";
	msg += "Y: " + vec1.Y + "<br/>";
	msg += "Z: " + vec1.Z;
	
	if(showTarget)
	{
		if( vec2.X == 0.0 && vec2.Y == 0.0 && vec2.Z == 0.0 )
		{
			msg += "<br/><br/>No target!";
		}
		else
		{
			msg += "<br/><br/>Target " + coordType;
			msg += "X: " + vec2.X + "<br/>";
			msg += "Y: " + vec2.Y + "<br/>";
			msg += "Z: " + vec2.Z;
		}
	}
	
	if(time)
		newTime = time * 1000.0;
	else
		newTime = 5000.0;
	
	theGame.GetGuiManager().ShowNotification( msg, newTime );
}
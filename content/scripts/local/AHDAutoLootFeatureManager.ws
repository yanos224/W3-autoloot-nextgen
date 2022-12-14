/***********************************************************************/
/** 	AHDAutoLootFeatureManager.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/***********************************************************************/



class CAHDAutoLootFeatureManager
{
	private var isInitialized : bool;
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var AutoLootNotificationManager : CAHDAutoLootNotificationManager;
	private var UserSettings : CInGameConfigWrapper;
	
	private var AHDAL_TRUE_AUTOLOOT_MODE,
				AHDAL_RADIUS_LOOT : string;
				
		default AHDAL_TRUE_AUTOLOOT_MODE = "true_autoloot_mode";
		default AHDAL_RADIUS_LOOT = "radius_loot";
	
	/*
	 *  Registers the keybinding listeners
	 */
	public function Init()
	{
		theInput.RegisterListener( this, 'OnAutoLootRadiusLoot', 'AutoLootRadius' );
		theInput.RegisterListener( this, 'OnTrueAutoLoot', 'ToggleTrueAutoLoot' );
		
		isInitialized = true;
	}
	
	/*
	 *  Handles the Radius Loot keybinding
	 */
	public final function OnAutoLootRadiusLoot(action : SInputAction)
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
			TryAreaLooting( AHDAL_RADIUS_LOOT );
	}
	
	/*
	 *  Handles the True AutoLoot Mode keybinding
	 */
	public final function OnTrueAutoLoot(action : SInputAction)
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		if( AutoLootConfig.ModEnabled() && IsPressed(action) )
		{
			if( !AutoLootConfig.TrueAutoLootEnabled() )
			{
				AutoLootConfig.ToggleTrueAutoLoot();
				TrueAutoLootStart();
			}
			else
			{
				AutoLootConfig.ToggleTrueAutoLoot();
				TrueAutoLootStop();
			}
		}
	}
	
	/* 
	 *  Activates True AutoLoot Mode
	 */
	public function TrueAutoLootStart()
	{
		theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_trueAutoLootEnableMsg") , 3000 );
		thePlayer.AddTimer('TrueAutoLootMode', 3.0 );
	}
	
	/* 
	 *  Deactivates True AutoLoot Mode
	 */
	public function TrueAutoLootStop()
	{
		theGame.GetGuiManager().ShowNotification( GetLocStringByKeyExt("ahdal_trueAutoLootDisableMsg") );
		thePlayer.RemoveTimer('TrueAutoLootMode');
	}
	
	/*
	 *  Tries to loot all containers in the area based on the specified mode
	 */
	public function TryAreaLooting( mode : string )
	{
		var i, containerListSize, maxContainers : int;
		var distance : float;
		var enabled, allowInCombat : bool;
		var container : W3Container;
		var containerList : array<CGameplayEntity>;
		
		if(!isInitialized)
			return;
		
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		AutoLootNotificationManager = GetWitcherPlayer().GetAutoLootNotificationManager();
		
		if( mode == AHDAL_RADIUS_LOOT )
		{
			enabled = true;
			allowInCombat = AutoLootConfig.RadiusLootInCombat();
			distance = AutoLootConfig.GetRadiusLootDistance();
			maxContainers = AutoLootConfig.GetRadiusLootMaxContainers();
		}
		else if( mode == AHDAL_TRUE_AUTOLOOT_MODE )
		{
			enabled = AutoLootConfig.TrueAutoLootEnabled();
			allowInCombat = AutoLootConfig.TrueAutoLootInCombat();
			distance = AutoLootConfig.GetTrueAutoLootDistance();
			maxContainers = AutoLootConfig.GetTrueAutoLootMaxContainers();
		}
		else
			enabled = false;
		
		if ( !enabled || ( thePlayer.IsInCombat() && !allowInCombat ) )
			return;
		
		FindGameplayEntitiesInRange( containerList, thePlayer, distance, maxContainers, , FLAG_ExcludePlayer, , 'W3Container' );
		containerListSize = containerList.Size();
		
		for( i = 0; i < containerListSize; i += 1)
		{
			container = (W3Container) containerList[i];
			
			if( !AutoLootConfig.GetFilters().IsContainerProtected(container) && !container.IsEmpty() )
			{
				container.mergeNotification = true;
				container.OnInteraction("Container", thePlayer);
				container.mergeNotification = false;
			}
		}
		
		AutoLootNotificationManager.ShowNotification();
	}
}
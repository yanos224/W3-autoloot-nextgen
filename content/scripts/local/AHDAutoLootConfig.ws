/***********************************************************************/
/** 	AHDAutoLootConfig.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/***********************************************************************/



class CAHDAutoLootConfig {
	
	private var UserSettings : CInGameConfigWrapper;
	private var features : CAHDAutoLootFeatureManager;
	private var filters : CAHDAutoLootFilters;
	private var actions : CAHDAutoLootActions;
	
	private var		modEnabled,
					useFilters,
					useNoAccidentalStealing,
					disableStealing,
					useIsHerb,
					useIsCorpse,
					useIsArmor,
					useIsWeapon,
					useIsUpgrade,
					useIsFood,
					useIsFormula,
					useIsReadable,
					useIsIngredient,
					useIsMoney,
					useIsNotJunk,
					useQuantity,
					useWeight,
					useValue,
					useItemQuality,
					enableTrueAutoLoot,
					enableTrueAutoLootOnStart	: bool;
	
	private var		filterLogic,
					quantityLogic,
					weightLogic,
					valueAmount,
					valueLogic,
					qualityLogic,
					quantityAmount,
					qualityThreshold			: int;
	
	private var		weightAmount				: float;
	
	private const var 	AHDAL_LOGIC_ANY,
						AHDAL_LOGIC_ALL,
						AHDAL_COMPARE_LESS,
						AHDAL_COMPARE_EQUAL,
						AHDAL_COMPARE_GREATER	: int;
	
				default AHDAL_LOGIC_ANY = 0;
				default AHDAL_LOGIC_ALL = 1;
				default AHDAL_COMPARE_LESS = 0;
				default AHDAL_COMPARE_EQUAL = 1;
				default AHDAL_COMPARE_GREATER = 2;
	
	private var		modInitalized,
					modLoaded_base,
					modLoaded_v200,
					modLoaded_v210,
					modLoaded_v300				: bool;
					
			default modInitalized = false;
			default modLoaded_base = false;
			default modLoaded_v200 = false;
			default modLoaded_v210 = false;
			default modLoaded_v300 = false;
	
	private var updateMsgParams : array<string>;
	
	/* 
	 *  Initializes all parts of the mod, with listeners and some error checking
	 */
	public function Init()
	{
		var isUpdated, displayMsg : bool;
		isUpdated = false;
		displayMsg = false;
		
		filters = new CAHDAutoLootFilters in this;
		actions = new CAHDAutoLootActions in this;
		features = new CAHDAutoLootFeatureManager in this;
		features.Init();
		
		TryFullReset();
		
		UserSettings = theGame.GetInGameConfigWrapper();
		
		if( !UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'isLoaded' ) )
		{
			LoadDefaultSettings();
			displayMsg = true;
		}
		
		else if( !UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'isLoaded' ))
		{
			updateMsgParams.PushBack( "3.0.0" );
			LoadDefaultSettings_v300();
			displayMsg = true;
			isUpdated = true;
		}
		
		GetAutoLootSettings();
		
		modInitalized = true;
		
		if(displayMsg)
			DisplayWelcomeMsg(isUpdated);
		
		InitTrueAutoLoot();
		TryLoadPreset();
	}
	
	/*
	 *  Initializes the True AutoLoot Mode and checks if it should be started when loading the game
	 */
	private function InitTrueAutoLoot()
	{
		if( enableTrueAutoLootOnStart && enableTrueAutoLoot )
			features.TrueAutoLootStart();
		else
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot', "false" );
			theGame.SaveUserSettings();
			enableTrueAutoLoot = false;
		}
	}
	
	/*
	 *  Displays the appropriate welcome (or error) message when the mod is loaded/reset
	 */
	private function DisplayWelcomeMsg( updated : bool )
	{
		if( !IsModLoaded() )
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_menuErrorMsg") );
		
		else if( updated )
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExtWithParams( "ahdal_updateLoadedMsg" ,,, updateMsgParams ) );
		
		else
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_defaultLoadedMsg") );
	}
	
	/* 
	 *  Sets all default values in user.settings and saves it
	 */
	private function LoadDefaultSettings()
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useNoAccidentalStealing', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'disableStealing', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'enableOnKillLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'fullReset', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'quantityAmount', 15 );
		UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'Virtual_quantityLogic', 0 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'weightAmount', 1 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_weightLogic', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'valueAmount', 100 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_valueLogic', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_qualityThreshold', 0 );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_qualityLogic', 0 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'enableRadiusLootCombat', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'radiusLootMaxDistance', 10 );
		UserSettings.SetVarValue( 'AHDAutoLoot_radius', 'radiusMaxContainers', 20 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLootOnStart', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLootCombat', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootTime', 5 );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootMaxDistance', 10 );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootMaxContainers', 20 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableNotification', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'hideNotificationCombat', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNewNotification', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationImage', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationDesc', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationQuantity', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationTime', 5 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem', 150 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationFontSize', 24 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableColors', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'enableLootSound', "true" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'isLoaded', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'isLoaded', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'isLoaded', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'isLoaded', "true" );
		
		theGame.SaveUserSettings();
	}
	
	/* 
	 *  Loads all default menu settings into the user config for the 2.0.x update
	 */
	private function LoadDefaultSettings_v200()
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'fullReset', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem', 150 );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'notificationFontSize', 24 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLootOnStart', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLootCombat', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootTime', 5 );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootMaxDistance', 10 );
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'trueAutoLootMaxContainers', 5 );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_true', 'isLoaded', "true" );
	}
	
	/* 
	 *  Loads all default menu settings into the user config for the 2.1.x update
	 */
	private function LoadDefaultSettings_v210()
	{
		if( !UserSettings.GetVarValue( 'AHDAutoLoot_true', 'isLoaded' ))
			LoadDefaultSettings_v200();
		
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationImage', "true" );
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'useNotificationDesc', "true" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'isLoaded', "true" );
		
		theGame.SaveUserSettings();
	}
	
	/* 
	 *  Loads all default menu settings into the user config for the 3.0.x update
	 */
	private function LoadDefaultSettings_v300()
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		if( !UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'isLoaded' ))
			LoadDefaultSettings_v210();
		
		UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'hideNotificationCombat', "true" );
		
		UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'isLoaded', "true" );
		
		theGame.SaveUserSettings();
	}
	
	/* 
	 *  Loads all relevant menu settings into local variables
	 */
	private function GetAutoLootSettings()
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		modEnabled					= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot' );
		useFilters					= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'useFilters' );
		filterLogic					= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic' ));
		useNoAccidentalStealing		= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'useNoAccidentalStealing' );
		disableStealing				= UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'disableStealing' );
		
		useIsHerb					= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useIsHerb' );
		useIsCorpse					= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse' );
		useQuantity					= UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'useQuantity' );
		quantityAmount				= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'quantityAmount' ));
		quantityLogic				= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_containers', 'Virtual_quantityLogic' ));
		
		useIsArmor					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsArmor' );
		useIsWeapon					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon' );
		useIsUpgrade				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade' );
		useIsFood					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsFood' );
		useIsFormula				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsFormula' );
		useIsReadable				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsReadable' );
		useIsIngredient				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient' );
		useIsMoney					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsMoney' );
		useIsNotJunk				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk' );
		useWeight					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useWeight' );
		weightAmount				= StringToFloat(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'weightAmount' ));
		weightLogic					= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'Virtual_weightLogic' ));
		useValue					= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useValue' );
		valueAmount					= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'valueAmount' ));
		valueLogic					= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'Virtual_valueLogic' ));
		useItemQuality				= UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'useItemQuality' );
		qualityThreshold			= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'Virtual_qualityThreshold' )) + 1;
		qualityLogic				= StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_filters', 'Virtual_qualityLogic' ));
		
		enableTrueAutoLoot			= UserSettings.GetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot' );
		enableTrueAutoLootOnStart	= UserSettings.GetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLootOnStart' );
	}
	
	/* 
	 *  Does a full reset of all settings if the option is enabled (from closing the menu)
	 */
	public function TryFullReset()
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		if ( SettingEnabled( 'AHDAutoLoot_settings', 'fullReset' ) )
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'fullReset', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_notifications', 'isLoaded', "false" );
			thePlayer.AddTimer('InitAHDAutoLoot', 1.0);
		}
	}
	
	/* 
	 *  Attempts to load the selected preset from the menu (since items are on multiple pages)
	 */
	public function TryLoadPreset()
	{
		var loadPresetHerb, loadPresetCorpse, loadPresetHerbCorpse, loadPresetOneItem, loadPresetValuableGear, loadPresetWeightless : bool;
		
		UserSettings = theGame.GetInGameConfigWrapper();
		
		loadPresetHerb = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetHerb' );
		loadPresetCorpse = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetCorpse' );
		loadPresetHerbCorpse = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetHerbCorpse' );
		loadPresetOneItem = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetOneItem' );
		loadPresetValuableGear = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetValuableGear' );
		loadPresetWeightless = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetWeightless' );
		
		if(loadPresetHerb)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadHerbMsg") );
		}
		
		else if(loadPresetCorpse)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadCorpseMsg") );
		}
		
		else if(loadPresetHerbCorpse)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadHerbCorpseMsg") );
		}
		
		else if(loadPresetOneItem)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'quantityAmount', 1 );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'Virtual_quantityLogic', 1 );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadOneItemMsg") );
		}
		
		else if(loadPresetValuableGear)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 1 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'valueAmount', 300 );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_valueLogic', 2 );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadValuableGearMsg") );
		}
		
		else if(loadPresetWeightless)
		{
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useAutoLoot', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'useFilters', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'Virtual_filterLogic', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_settings', 'forceQuestLoot', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsHerb', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useIsCorpse', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsArmor', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsWeapon', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsUpgrade', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFood', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsFormula', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsReadable', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsIngredient', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsMoney', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useIsNotJunk', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_containers', 'useQuantity', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useWeight', "true" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'weightAmount', 0 );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'Virtual_weightLogic', 1 );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useValue', "false" );
			UserSettings.SetVarValue( 'AHDAutoLoot_filters', 'useItemQuality', "false" );
			
			GetWitcherPlayer().DisplayHudMessage( GetLocStringByKeyExt("ahdal_presetLoadWeightlessMsg") );
		}
		
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetHerb', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetCorpse', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetHerbCorpse', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetOneItem', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetValuableGear', "false" );
		UserSettings.SetVarValue( 'AHDAutoLoot_loadpresets', 'loadPresetWeightless', "false" );
		
		theGame.SaveUserSettings();
	}
	
	/* 
	 *  Returns if the specified item can be looted from the container based on menu configuration
	 */
	public function AutoLootLogic(container : W3Container, itemID : SItemUniqueId, count : int) : bool
	{
		GetAutoLootSettings();
		
		if(modEnabled)
		{
			if(useFilters)
			{
				if(filterLogic == AHDAL_LOGIC_ANY)
				{
					return ( (	GetContainerLogic(container, itemID) ||
								(GetTypeLogic(container, itemID) &&
								GetJunkLogic(container, itemID)) ||
								GetQuantityLogic(count) ||
								GetWeightLogic(container, itemID) ||
								GetValueLogic(container, itemID) ||
								GetQualityLogic(container, itemID) ) &&
								GetStealingLogic(container) );
				}
				
				if(filterLogic == AHDAL_LOGIC_ALL)
				{
					return (	GetContainerLogic(container, itemID) &&
								GetTypeLogic(container, itemID) &&
								GetJunkLogic(container, itemID) &&
								GetQuantityLogic(count) &&
								GetWeightLogic(container, itemID) &&
								GetValueLogic(container, itemID) &&
								GetQualityLogic(container, itemID) &&
								GetStealingLogic(container) );
				}
				
				return false;
			}
			
			return GetStealingLogic(container);
		}
		
		return false;
	}
	
	/* 
	 *  Checks if we can loot the container based on stealing options
	 */
	private function GetStealingLogic(container : W3Container) : bool
	{
		if(disableStealing)			{ return true; }
		if(useNoAccidentalStealing)	{ return filters.IsNotStealing(container); }
		
		return true;
	}
	
	/*
	 *  Checks what type the container is and if we can loot it
	 */
	private function GetContainerLogic(container : W3Container, itemID : SItemUniqueId) : bool
	{
		var temp1, temp2 : bool;
		temp1 = false;
		temp2 = false;
		
		if(useIsHerb) 	{ temp1 = filters.IsHerb(container, itemID); }
		if(useIsCorpse)	{ temp2 = filters.IsCorpse(container); }

		if(!useIsHerb && !useIsCorpse && filterLogic == AHDAL_LOGIC_ALL)
			return true;
		
		return ( temp1 || temp2 );
	}
	
	/*
	 *  Checks if the item in the container fits certain categories (Armor, Weapon, Food, etc.)
	 */
	private function GetTypeLogic(container : W3Container, itemID : SItemUniqueId) : bool
	{
		var temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8, temp9 : bool;
		temp1 = false;
		temp2 = false;
		temp3 = false;
		temp4 = false;
		temp5 = false;
		temp6 = false;
		temp7 = false;
		//temp8 = false;
		temp9 = false;
		
		if(useIsArmor)		{ temp1 = filters.IsArmor(container, itemID); }
		if(useIsWeapon)		{ temp2 = filters.IsWeapon(container, itemID); }
		if(useIsUpgrade)	{ temp3 = filters.IsUpgrade(container, itemID); }
		if(useIsFood)		{ temp4 = filters.IsFood(container, itemID); }
		if(useIsFormula)	{ temp5 = filters.IsFormula(container, itemID); }
		if(useIsIngredient)	{ temp6 = filters.IsIngredient(container, itemID); }
		if(useIsMoney)		{ temp7 = filters.IsCurrency(container, itemID); }
		//if(useIsNotJunk)	{ temp8 = filters.IsNotJunk(container, itemID); }
		if(useIsReadable)	{ temp9 = filters.IsReadable(container, itemID); }

		if( !useIsArmor && !useIsWeapon && !useIsUpgrade && !useIsFood && !useIsFormula &&
			!useIsIngredient && !useIsMoney && !useIsNotJunk && !useIsReadable && filterLogic == AHDAL_LOGIC_ALL )
			return true;

		return ( temp1 || temp2 || temp3 || temp4 || temp5 || temp6 || temp7 || temp8 || temp9 );
	}
	
	private function GetJunkLogic(container : W3Container, itemID : SItemUniqueId) : bool
	{
		if(useIsNotJunk) { return filters.IsNotJunk(container, itemID); }
		
		return true;
	}
	
	/*
	 *  Checks how many items are in the container with the selected menu options
	 */
	private function GetQuantityLogic(count : int) : bool
	{
		if(useQuantity)
		{
			if(quantityLogic == AHDAL_COMPARE_LESS)		{ return ( count <= quantityAmount ); }
			if(quantityLogic == AHDAL_COMPARE_EQUAL)	{ return ( count == quantityAmount ); }
			if(quantityLogic == AHDAL_COMPARE_GREATER)	{ return ( count >= quantityAmount ); }
		}
		
		if(!useQuantity && filterLogic == AHDAL_LOGIC_ALL)
			return true;
		
		return false;
	}

	/*
	 *  Checks the weight of the item in the container with the selected menu options
	 */	
	private function GetWeightLogic( container : W3Container, itemID: SItemUniqueId ) : bool
	{
		if(useWeight)
		{
			if(weightLogic == AHDAL_COMPARE_LESS)		{ return ( container.GetInventory().GetItemEncumbrance( itemID ) <= weightAmount ); }
			if(weightLogic == AHDAL_COMPARE_EQUAL)		{ return ( container.GetInventory().GetItemEncumbrance( itemID ) == weightAmount ); }
			if(weightLogic == AHDAL_COMPARE_GREATER)	{ return ( container.GetInventory().GetItemEncumbrance( itemID ) >= weightAmount ); }
		}
		
		if(!useWeight && filterLogic == AHDAL_LOGIC_ALL)
			return true;
		
		return false;
	}
	
	/*
	 *  Checks the value of the item in the container with the slected menu options
	 */
	private function GetValueLogic( container : W3Container, itemID: SItemUniqueId ) : bool
	{
		if(useValue)
		{
			if(valueLogic == AHDAL_COMPARE_LESS)		{ return ( container.GetInventory().GetItemPrice( itemID ) <= valueAmount ); }
			if(valueLogic == AHDAL_COMPARE_EQUAL)		{ return ( container.GetInventory().GetItemPrice( itemID ) == valueAmount ); }
			if(valueLogic == AHDAL_COMPARE_GREATER)		{ return ( container.GetInventory().GetItemPrice( itemID ) >= valueAmount ); }
		}
		
		if(!useValue && filterLogic == AHDAL_LOGIC_ALL)
			return true;
		
		return false;
	}
	
	/*
	 *  Uses menu options to see if the item is the right quality to loot.
	 */
	private function GetQualityLogic( container : W3Container, itemID: SItemUniqueId ) : bool
	{
		if(useItemQuality)
		{
			if( useIsHerb && filters.IsHerb( container, itemID ) ) { return true; }
			if( useIsUpgrade && filters.IsUpgrade( container, itemID ) ) { return true; }
			if( useIsFood && filters.IsFood(container, itemID) ) { return true; }
			if( useIsFormula && filters.IsFormula( container, itemID ) ) { return true; }
			if( useIsMoney && filters.IsCurrency( container, itemID ) ) { return true; }
			if( useIsReadable && filters.IsReadable( container, itemID ) ) { return true; }
			
			if(qualityLogic == AHDAL_COMPARE_LESS)		{ return ( container.GetInventory().GetItemQuality( itemID ) <= qualityThreshold ); }
			if(qualityLogic == AHDAL_COMPARE_EQUAL)		{ return ( container.GetInventory().GetItemQuality( itemID ) == qualityThreshold ); }
			if(qualityLogic == AHDAL_COMPARE_GREATER)	{ return ( container.GetInventory().GetItemQuality( itemID ) >= qualityThreshold ); }
		}

		if(!useItemQuality && filterLogic == AHDAL_LOGIC_ALL)
			return true;
		
		return false;
	}
	
	/*
	 *  Determines if the menu settings were saved, and that it matches the current version
	 */
	public function IsModLoaded() : bool
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		modLoaded_base = UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'isLoaded' );
		modLoaded_v200 = UserSettings.GetVarValue( 'AHDAutoLoot_true', 'isLoaded' );
		modLoaded_v210 = UserSettings.GetVarValue( 'AHDAutoLoot_loadpresets', 'isLoaded' );
		modLoaded_v300 = UserSettings.GetVarValue( 'AHDAutoLoot_settings', 'isLoaded' );
		
		return ( modInitalized && modLoaded_base && modLoaded_v200 && modLoaded_v210 && modLoaded_v300 );
	}
	
	/* 
	 *  Returns whether stealing from containers is allowed or not
	 */
	public function NoAccidentalStealingEnabled() : bool
	{
		if( SettingEnabled( 'AHDAutoLoot_settings', 'disableStealing' ) )
			return false;
		
		return SettingEnabled( 'AHDAutoLoot_settings', 'useNoAccidentalStealing' );
	}
	
	/* 
	 *  Tries to activate/deactivate True AutoLoot Mode, based on changed settings (from closing the menu)
	 */
	public function TryTrueAutoLoot()
	{
		var old : bool;
		
		old = enableTrueAutoLoot;
		enableTrueAutoLoot = TrueAutoLootEnabled();
		
		if ( old != enableTrueAutoLoot )
		{
			if( enableTrueAutoLoot )
				features.TrueAutoLootStart();
			else
				features.TrueAutoLootStop();
		}
	}
	
	/*
	 *  Toggles the true autoloot mode and saves it to user.settings
	 */
	public function ToggleTrueAutoLoot()
	{
		var enabled : bool;
		
		enabled = TrueAutoLootEnabled();
		UserSettings = theGame.GetInGameConfigWrapper();
		
		if ( enabled )
			UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot', "false" );
		else
			UserSettings.SetVarValue( 'AHDAutoLoot_true', 'enableTrueAutoLoot', "true" );
		
		theGame.SaveUserSettings();
	}
	
	public function GetFeatureManager() : CAHDAutoLootFeatureManager { return features; }
	public function GetFilters() : CAHDAutoLootFilters { return filters; }
	public function GetActions() : CAHDAutoLootActions { return actions; }
	public function ModEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'useAutoLoot' ); }
	public function StealingDisabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'disableStealing' ); }
	public function ForceQuestLoot() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'forceQuestLoot' ); }
	public function LootOnKillEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_settings', 'enableOnKillLoot' ); }
	public function RadiusLootInCombat() : bool { return SettingEnabled( 'AHDAutoLoot_radius', 'enableRadiusLootCombat' ); }
	public function GetRadiusLootDistance() : float { return GetSettingAsFloat( 'AHDAutoLoot_radius', 'radiusLootMaxDistance' ); }
	public function GetRadiusLootMaxContainers() : int { return GetSettingAsInt( 'AHDAutoLoot_radius', 'radiusMaxContainers' ); }
	public function TrueAutoLootEnabled() : bool { return SettingEnabled( 'AHDAutoLoot_true', 'enableTrueAutoLoot' ); }
	public function TrueAutoLootInCombat() : bool { return SettingEnabled( 'AHDAutoLoot_true', 'enableTrueAutoLootCombat' ); }
	public function GetTrueAutoLootDistance() : float { return GetSettingAsFloat( 'AHDAutoLoot_true', 'trueAutoLootMaxDistance' ); }
	public function GetTrueAutoLootMaxContainers() : int { return GetSettingAsInt( 'AHDAutoLoot_true', 'trueAutoLootMaxContainers' ); }
	public function GetTrueAutoLootTime() : float { return GetSettingAsFloat( 'AHDAutoLoot_true', 'trueAutoLootTime' ); }
	
	/*
	 *  Returns if the specified setting is enabled (helper function)
	 */
	public function SettingEnabled( group : name, setting : name ) : bool
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		return UserSettings.GetVarValue( group, setting );
	}
	
	/*
	 *  Returns the specified setting as a float (helper function)
	 */
	private function GetSettingAsFloat( group : name, setting : name ) : float
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		return StringToFloat( UserSettings.GetVarValue( group, setting ) );
	}
	
	/*
	 *  Returns the specified setting as an int (helper function)
	 */
	private function GetSettingAsInt( group : name, setting : name ) : int
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		return StringToInt( UserSettings.GetVarValue( group, setting ) );
	}
	
}
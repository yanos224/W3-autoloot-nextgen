/***********************************************************************/
/** 	AHDAutoLootNotificationManager.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/***********************************************************************/



class CAHDAutoLootNotificationManager
{
	private var UserSettings : CInGameConfigWrapper;
	private var itemNames, itemIcons, itemDescriptions : array<string>;
	private var itemCounts : array<int>;
	private var soundCategories : array<name>;
	private var totalSize : int;
	private var AHDAL_READ_SUFFIX, AHDAL_KNOWN_SUFFIX : string;
	
	/*
	 *  Resets all local values, initializes static strings
	 */
	public function Reset()
	{
		itemNames.Clear();
		itemCounts.Clear();
		itemIcons.Clear();
		itemDescriptions.Clear();
		soundCategories.Clear();
		totalSize = 0;
		AHDAL_READ_SUFFIX = GetLocStringByKeyExt( "ahdal_readTag" );
		AHDAL_KNOWN_SUFFIX = GetLocStringByKeyExt( "ahdal_knownTag" );
	}
	
	/*
	 *  Returns the index of the first occurence of the specified item (string), -1 if not found
	 */
	private function GetIndexByString( itemName : string ) : int
	{
		var i : int;
		
		for (i=0; i<totalSize; i+=1 )
			if( StrReplace(itemName, AHDAL_READ_SUFFIX, "") == itemNames[i] ||
				StrReplace(itemName, AHDAL_KNOWN_SUFFIX, "") == itemNames[i] )
				return i;
			
		return -1;
	}
	
	/*
	 *  Adds an item to the list and updates all related values (the item name is stored as a formatted string)
	 */
	public function AddItem( container : W3Container, itemID : SItemUniqueId )
	{
		var itemIndex, count : int;
		var itemName : string;
		var soundName : name;
		
		itemName = FormatItem( container, itemID );
		count = container.GetInventory().GetItemQuantity( itemID );
		
		itemIndex = GetIndexByString(itemName);
		
		if ( itemIndex <= -1 )
		{
			itemNames.PushBack( itemName );
			itemCounts.PushBack( count );
			itemIcons.PushBack(container.GetInventory().GetItemIconPathByUniqueID(itemID));
			itemDescriptions.PushBack(GetLocStringByKeyExt(container.GetInventory().GetItemLocalizedDescriptionByUniqueID(itemID)));
			totalSize += 1;
		}
		else
			itemCounts[itemIndex] += count;
		
		if( container.GetInventory().ItemHasTag(itemID, 'HerbGameplay') )
			soundName = 'herb';
		else
			soundName = container.GetInventory().GetItemCategory( itemID );
		
		if( soundCategories.FindFirst(soundName) == -1 )
			soundCategories.PushBack( soundName );
	}
	
	/*
	 *  Returns the item name, formatted with all appropriate rarity color formatting (if applicable) and suffixes
	 */
	private function FormatItem( container : W3Container, itemID : SItemUniqueId ) : string
	{
		var itemStr, rarityStr : string;
		var itemQuality, fontSize : int;
		
		itemStr = container.GetInventory().GetItemLocalizedNameByUniqueID( itemID );
		itemStr = GetLocStringByKeyExt(itemStr);
		
		if( itemStr == "" )
			itemStr = " ";
		
		itemQuality = container.GetInventory().GetItemQuality( itemID );
		rarityStr = FormatItemRarirty(itemStr, itemQuality);
		
		if( container.GetInventory().IsBookRead(itemID) )
		{
			if( container.GetInventory().IsRecipeOrSchematic(itemID) )
				rarityStr += AHDAL_KNOWN_SUFFIX;
			else if( container.GetInventory().IsItemReadable(itemID) )
				rarityStr += AHDAL_READ_SUFFIX;
		}
		
		return rarityStr;
	}
	
	/*
	 *  Returns the string formatted with the specified rarity color
	 */
	private function FormatItemRarirty( itemStr : string, quality : int ) : string
	{
		if ( SettingEnabled('enableColors') )
		{
			switch(quality)
			{
				case 1:
					return "<font color='#000000'>" + itemStr + "</font>";
				case 2:
					return "<font color='#3661dc'>" + itemStr + "</font>";
				case 3:
					return "<font color='#909000'>" + itemStr + "</font>";
				case 4:
					return "<font color='#934913'>" + itemStr + "</font>";
				case 5:
					return "<font color='#197319'>" + itemStr + "</font>";
				default:
					return itemStr;
			}
		}
		
		return itemStr;
	}
	
	/*
	 *  Returns the formatted array with font size and quantities based on user.settings
	 */
	private function FormatItemList() : array<string>
	{
		var temp : array<string>;
		var i : int;
		
		for ( i=0; i<totalSize; i+=1 )
		{
			if ( SettingEnabled('useNotificationQuantity') )
			{
				if ( itemCounts[i] > 1 )
					temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + " x" + itemCounts[i] + "</font>");
				else
					temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + "</font>");
			}
			else
			{
				temp.PushBack("<font size='" + GetNotificationFontSize() + "'>" + itemNames[i] + "</font>");
			}
		}
		
		return temp;
	}
	
	/*
	 *  Returns the formatted image for the specified item index
	 */
	private function FormatLootIcon( index : int ) : string
	{
		var temp : string;
		temp = "";
		
		if( SettingEnabled('useNotificationImage') )
			temp += "<img src='img://" + itemIcons[index] + "' height='" + GetNotificationFontSize() + "' width='" + GetNotificationFontSize() + "' vspace='-10' />&nbsp;";
		
		return temp;
	}
	
	/*
	 *  Returns the item description for the specified index
	 */
	private function GetLootDesc( index : int ) : string
	{
		var temp : string;
		temp = "";
		
		if( SettingEnabled('useNotificationDesc') && (itemDescriptions[index] != "" || itemDescriptions[index] != " ") )
			temp += "<br/><font size='" + (GetNotificationFontSize()-6) + "'>" + itemDescriptions[index] + "</font>";
		
		return temp;
	}
	
	/*
	 *  Returns the formatted notification message based on all items and appropriate user.settings options
	 */
	private function FormatNotification( combat : bool ) : string
	{
		var AutoLootConfig : CAHDAutoLootConfig;
		var itemList : array<string>;
		var i : int;
		var msg : string;
		
		msg = "";
		
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		if( !AutoLootConfig.IsModLoaded() )
			return GetLocStringByKeyExt("ahdal_menuErrorMsg");
		
		if( GetNotificationFontSize() < 1 )
			return GetLocStringByKeyExt("ahdal_fontErrorMsg");
		
		if( totalSize <= 0 )
			return msg;
		
		itemList = FormatItemList();
		
		msg += "<font size='" + GetNotificationFontSize() + "'>" + GetNotificationHeader(combat) + "</font>";
		
		for ( i=0; i<totalSize; i+=1)
		{
			msg += FormatLootIcon(i) + itemList[i];
			msg += GetLootDesc(i);
			
			if ( i+1 < totalSize )
				msg += "<br/>";
		}
		
		return msg;
	}
	
	/*
	 *  Plays the appropriate sound based on what items have been looted
	 */
	private function PlayAutoLootSound()
	{
		if( SettingEnabled('enableLootSound') && soundCategories.Size() > 0 )
		{
			if( soundCategories.Size() == 1 )
				PlayItemEquipSound(soundCategories[0]);
			else
				PlayItemEquipSound('generic');
		}
	}
	
	/*
	 *  Returns the total time to display the loot notification based on user.settings
	 */
	private function GetTotalNotificationTime() : float { return GetNotificationTime() + (GetNotificationTimeAddPerItem() * totalSize); }
	
	/*
	 *  Displays the loot notification if applicable; everything is reset once the notification is shown
	 */
	public function ShowNotification( optional combat : bool )
	{
		if( ( !thePlayer.IsInCombat() || 
			(thePlayer.IsInCombat() && !SettingEnabled('hideNotificationCombat')) )
			&& totalSize > 0 )
		{
			if( SettingEnabled('enableNotification') )
				theGame.GetGuiManager().ShowNotification( FormatNotification(combat), GetTotalNotificationTime() );
			
			PlayAutoLootSound();
			Reset();
		}
	}
	
	/* 
	 *  Returns if the user has enabled the specified setting
	 */
	private function SettingEnabled( setting : name ) : bool
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		return UserSettings.GetVarValue( 'AHDAutoLoot_notifications', setting );
	}
	
	/* 
	 *  Returns font size from menu settings (with error checking)
	 */
	private function GetNotificationFontSize() : int
	{
		var fontSize : int;
		
		UserSettings = theGame.GetInGameConfigWrapper();
		fontSize = StringToInt(UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'notificationFontSize' ));
		
		if( fontSize < 14 || fontSize > 34 )
			return -1;
		
		return fontSize;
	}
	
	/* 
	 *  Returns how long to display loot notifications (in ms)
	 */
	private function GetNotificationTime() : float
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		return StringToFloat(UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'notificationTime' )) * 1000.0;
	}
	
	/* 
	 *  Returns extra amount of time to display the notification per item looted (in ms)
	 */
	private function GetNotificationTimeAddPerItem() : float
	{
		UserSettings = theGame.GetInGameConfigWrapper();

		if( UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'useNotificationDesc' ) )
			return StringToFloat(UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem' )) * 2;
		
		return StringToFloat(UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'notificationTimeAddPerItem' ));
	}
	
	/* 
	 *  Returns the notification header for loot messages
	 */
	private function GetNotificationHeader( combat : bool ) : string
	{
		UserSettings = theGame.GetInGameConfigWrapper();
		
		if( UserSettings.GetVarValue( 'AHDAutoLoot_notifications', 'useNewNotification' ) )
		{
			if(combat)
				return GetLocStringByKeyExt("ahdal_lootHeaderCombat") + "<br/>";
			else
				return GetLocStringByKeyExt("ahdal_lootHeader") + "<br/>";
		}
		
		return "";
	}
	
	/* 
	 *  Returns all values prior to being reset; used by console command
	 */
	public function DebugReset() : array<float>
	{
		var temp : array<float>;
		
		temp.PushBack(itemNames.Size());
		temp.PushBack(itemCounts.Size());
		temp.PushBack(itemIcons.Size());
		temp.PushBack(itemDescriptions.Size());
		temp.PushBack(soundCategories.Size());
		temp.PushBack(totalSize);
		
		Reset();
		
		return temp;
	}
	
}
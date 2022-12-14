/***********************************************************************/
/** 	AHDAutoLootFilters.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/***********************************************************************/



class CAHDAutoLootFilters
{
	/*
	 *  Checks if the container shouldn't be interacted with by AutoLoot
	 */
	public function IsContainerProtected( container: W3Container ) : bool
	{
		var AutoLootConfig : CAHDAutoLootConfig;
		
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		
		if(	container.lockedByKey || container.disableLooting )
			return true;
		
		if( container.HasQuestItem() ||
			container.factOnContainerOpened != "" ||
			container.focusModeHighlight == FMV_Clue ||
			((W3ActorRemains)container).HasTrophyItems() )
		{
			if ( AutoLootConfig.ForceQuestLoot() )
				return false;
			else
				return true;
		}
		
		if( !container.disableStealing && AutoLootConfig.NoAccidentalStealingEnabled() )
			return true;
		
		return false;
	}
	
	/*
	 *  Checks if looting the container would be considered stealing
	 */
	public function IsNotStealing( container : W3Container ) : bool
	{
		if( container.disableStealing )
			return true;
		
		return false;
	}
	
	/*
	 *  Checks if the container is a plant, or if the item in the container is a plant
	 */
	public function IsHerb( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if( (W3Herb)container )
			return true;
		
		if( container.GetInventory().ItemHasTag(itemID, 'HerbGameplay') )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the container is a corpse
	 */
	public function IsCorpse( container : W3Container ) : bool
	{
		if( (W3ActorRemains)container )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the item is armor
	 */
	public function IsArmor( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if( container.GetInventory().IsItemAnyArmor( itemID ) )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the item is a weapon
	 */
	public function IsWeapon( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if( container.GetInventory().IsItemWeapon( itemID ) )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the item is a glyph/runestone/mutagen
	 */
	public function IsUpgrade( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if(	container.GetInventory().IsItemUpgrade(itemID) ||
			container.GetInventory().ItemHasTag(itemID, 'MutagenIngredient') )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the item is food/drink
	 */
	public function IsFood( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if( container.GetInventory().IsItemFood( itemID ) )
			return true;
		
		return false;
	}
	
	/*
	 *  Checks if the item is an ingredient. Additionally checks if some "junk" has crafting parts (like hides and pelts)
	 */
	public function IsIngredient( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		var i : int;
		var parts : array<SItemParts>;
		var defMgr : CDefinitionsManagerAccessor;
		
		if(	container.GetInventory().IsItemIngredient( itemID ) &&
			!container.GetInventory().ItemHasTag(itemID, 'MutagenIngredient') )
			return true;
		
		parts = container.GetInventory().GetItemRecyclingParts( itemID );
		defMgr = theGame.GetDefinitionsManager();
		
		if( container.GetInventory().IsItemJunk(itemID) )
			for ( i = 0; i < parts.Size(); i += 1 )
				if(defMgr.IsItemIngredient( parts[i].itemName ))
					return true;
		
		return false;
	}
	
	/*
	 *  Checks if the item is a recipe or schematic
	 */
	public function IsFormula( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if(	container.GetInventory().IsRecipeOrSchematic(itemID) )
			return true;

		return false;
	}
	
	/*
	 *  Checks if the item can be read (books, maps, etc.)
	 */
	public function IsReadable( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if( (container.GetInventory().IsItemReadable( itemID ) || 
			container.GetInventory().ItemHasTag(itemID, 'Painting')) &&
			!container.GetInventory().IsRecipeOrSchematic(itemID) )
			return true;
		
		return false;
	}

	/*
	 *  Checks if the item is a form of currency
	 */
	public function IsCurrency( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if(	container.GetInventory().GetItemName( itemID ) == 'Crowns' ||
			container.GetInventory().GetItemName( itemID ) == 'Florens' ||
			container.GetInventory().GetItemName( itemID ) == 'Orens')
			return true;

		return false;
	}

	/*
	 *  Checks if the item is NOT junk (if using Match ANY Filter mode, this will override a lot of other options)
	 */
	public function IsNotJunk( container : W3Container, itemID : SItemUniqueId ) : bool
	{
		if(	!container.GetInventory().IsItemJunk(itemID) )
			return true;

		return false;
	}
	
}
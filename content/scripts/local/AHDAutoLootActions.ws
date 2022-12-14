/***********************************************************************/
/** 	AHDAutoLootActions.ws
/** 	by AeroHD
/**		Original AutoLoot code by JupiterTheGod
/***********************************************************************/



class CAHDAutoLootActions
{
	private var AutoLootConfig : CAHDAutoLootConfig;
	private var AutoLootNotificationManager : CAHDAutoLootNotificationManager;
	private var cInv : CInventoryComponent;
	private var invItemList : array<SItemUniqueId>;
	
	/*
	 *  Initializes/resets variables used in various functions
	 */
	private function Init( container : W3Container )
	{
		AutoLootConfig = GetWitcherPlayer().GetAutoLootConfig();
		AutoLootNotificationManager = GetWitcherPlayer().GetAutoLootNotificationManager();
		cInv = container.GetInventory();
		invItemList.Clear();
		cInv.GetAllItems( invItemList );
	}
	
	/*
	 *  Determines if the container should be looted. Returns if loot was taken from the container
	 */
	public function ProcessContainer( container : W3Container ) : bool
	{
		var i : int;
		var wasLooted : bool;
		
		Init(container);
		
		if ( !AutoLootConfig.ModEnabled() || AutoLootConfig.GetFilters().IsContainerProtected(container) )
			return true;
		
		if( IsInvEmpty(cInv) )
			return false;
		
		wasLooted = LootContainer(container);
		
		if( !container.mergeNotification )
			AutoLootNotificationManager.ShowNotification();
		
		CleanAndFix(container, wasLooted);
		
		return !IsInvEmpty(cInv);
	}
	
	/*
	 *  Determines if the container's inventory component is empty
	 */
	private function IsInvEmpty( inventory : CInventoryComponent ) : bool { return inventory.GetAllItemsQuantity() <= 0; }
	
	/*
	 *  Stores the container's inventory list and cleans it of items we shouldn't loot
	 */
	private function GetAndCleanInvList( container : W3Container )
	{
		var i : int;
		
		cInv.GetAllItems( invItemList );
		
		for( i = invItemList.Size()-1; i >= 0; i -= 1)
			if( cInv.ItemHasTag(invItemList[i], theGame.params.TAG_DONT_SHOW ) &&
				!cInv.ItemHasTag(invItemList[i], 'Lootable' ) )
				invItemList.Erase(i);
	}
	
	/*
	 *  Tries to take items from the container in accordance with the user's filters
	 */
	private function LootContainer( container : W3Container ) : bool
	{
		var totalItems, i : int;
		var looted : bool;
		
		totalItems = invItemList.Size();
		looted = false;
		
		GetWitcherPlayer().StartInvUpdateTransaction();
		for( i = 0; i < totalItems; i += 1 )
		{
			if( cInv.ItemHasTag(invItemList[i], 'QuickSlot') )
				continue;
			
			if( AutoLootConfig.AutoLootLogic( container, invItemList[i], totalItems ) )
			{
				AutoLootNotificationManager.AddItem( container, invItemList[i] );
				LootItem( container, invItemList[i] );
				looted = true;
			}
		}
		GetWitcherPlayer().FinishInvUpdateTransaction();
		
		return looted;
	}
	
	/*
	 *  Takes the specified item from the container and gives it to the player
	 */
	private function LootItem( container : W3Container, itemID : SItemUniqueId )
	{
		var quantity : int;
		
		quantity = container.GetInventory().GetItemQuantity( itemID );
		
		if( container.GetInventory().ItemHasTag(itemID, 'Lootable' ) ||
			!container.GetInventory().ItemHasTag(itemID, 'NoDrop') &&
			!container.GetInventory().ItemHasTag(itemID, theGame.params.TAG_DONT_SHOW) )
		{
			container.GetInventory().NotifyItemLooted( itemID );
			container.GetInventory().GiveItemTo( GetWitcherPlayer().inv, itemID, quantity, true, false, true );
		}
		
		if( container.GetInventory().ItemHasTag(itemID, 'GwintCard') )
			GetWitcherPlayer().AddGwentCard( container.GetInventory().GetItemName(itemID), quantity);
		
		container.InformClueStash();
	}
	
	/*
	 *  Cleans the updated inventory list and applies various bug fixes
	 */
	private function CleanAndFix( container : W3Container, shouldClean : bool )
	{
		var i : int;
		
		cInv.GetAllItems( invItemList );
		
		for( i = invItemList.Size() - 1; i >= 0; i -= 1 )
			if((cInv.ItemHasTag(invItemList[i],theGame.params.TAG_DONT_SHOW) ||
				cInv.ItemHasTag(invItemList[i],'NoDrop') ) &&
				!cInv.ItemHasTag(invItemList[i], 'Lootable'))
				invItemList.Erase(i);
		
		if( shouldClean || IsInvEmpty(cInv) )
			container.AutoLootCleanup();
		
		if( (W3treasureHuntContainer)container )
			((W3treasureHuntContainer)container).ProcessOnLootedEvents();
	}
	
}
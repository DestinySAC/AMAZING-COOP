/**************************************************************************
 *                                                                        *
 *                 			   Shop System Native						  *
 *                            Author: pan0s                               *
 *                            Version: v1.0                               *
 *                                                                        *
 **************************************************************************/

#if defined l4d2_shop
 #endinput
#endif
#define l4d2_shop

/**
 * Gets the version of Shop
 * @param buffer		string buffer
 * @return				current version of rank system in form of a float
 */
native float Shop_GetVersion();

/**
 *  Get client points
 *
 * @param client			client index
 * @return					client points
 */
native int Shop_GetPoints(int client);

/**
 * Buy item
 *
 * @param client			client index
 * @param buffer			item name
 * @param price				item price
 * @param team				team (default: survivor)
 * @return					true if buying item is successful
 */
native bool Shop_BuyItem(int client, char[] buffer, int price, int team = 2);

/**
 *  Upgrade Weapon
 *
 * @param client			client index
 * @param buffer			item name
 * @param price				item price
 * @return					true if buying item is successful
 */
native bool Shop_UpgradeWeapon(int client, char[] buffer, int price);

/**
 *  Upgrade Weapon
 *
 * @param client			client index
 * @param index				SF index
 * @param price				SF price
 * @param isPermanent		is Permanent
 * @return					void
 */
native bool Shop_BuySF(int client, int index, int price, bool isPermanent);

/**
 *  Check is sf on
 *
 * @param client			client index
 * @param index				SF index
 * @return					true if sf is on
 */
native bool Shop_IsSFOn(int client, int index);

/**
 * Get SF Index by function no.
 *
 * @param client			functionNo (string)
 * @return					index of functionNo
 */
native int Shop_GetFunctionIndex(char[] functionNo);

/**
 *  Check is sf on
 *
 * @param client			client index
 * @param index				SF index
 * @param isPermanent		isPermanent (default: false)
 * @return					index of functionNo
 */
native bool Shop_GetClientSFOn(int client, int index, bool isPermanent = false);

/**
 * Get Eanbled Ammo Color Index 
 *
 * @param client			client index
 * @return					-1 if not found
 */
native int Shop_GetEanbledAmmoColorIndex(int client);

/**
 * Buy function (reduce points)
 *
 * @param client			client index
 * @param price				client index
 * @param item				item name
 * @param bPrint			print purchase is successful?
 * @return					true if reduciing point is successful
 */
native bool Shop_Checkout(const int client, const int price, const char[] item, bool bPrint = true);


/**
* Registers a module for points system
*
* @param modulename	String that contains the module to be registered's name
* @return			false if successful true if already registered, true should never happen.
*/
native bool Shop_RegisterModule(const char[] modulename);

/**
* Unregisters a module for points system
*
* @param modulename	String that contains the module to be unregistered's name
* @return			none
*/
native void Shop_UnregisterModule(const char[] modulename);

/**
* Called when Points System is loaded
*
* @return			none
*/
forward void OnShopLoaded();

/**
* Called when Points System is unloaded
*
* @return			none
*/
forward void OnShopUnloaded();

public SharedPlugin L4D2_SHOP = 
{
	name = "l4d2_shop_native",
	file = "l4d2_shop.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
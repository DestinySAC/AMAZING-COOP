/**
 * =============================================================================
 * [L4D2] VIP Manager by Aceleración
 * Creation or update of vip commands by means of flags and levels
 *
 * Copyrigth (C)2020 Aceleración. All rights reserved.
 * =============================================================================
 */

// ----------------------- Command sm_vip -----------------------------
public Action:Command_PanelVIP(client, args) 
{
	if (!IsValidClient(client) || IsClientBot(client))
	{
		return Plugin_Handled;
	}

	if (IsPlayerVip(client))
	{
		BuildgGeneralMenuVIP(client);
	}
	else
	{
		ShowMessageNotVIP(client);
	}

	return Plugin_Handled;
}

/*================= BUILD MENU VIP FOR ADMIN ROOTS =========================*/
/*
stock BuildMenuVIPsDev(client)
{
	decl String:Title[50];
	//decl String:itemMenu[32];
	decl String:grpName[MAX_GROUPS_VIP][32];
	decl grpLevel[MAX_GROUPS_VIP];
	
	Format(Title, sizeof(Title), "%T:", "Title Menu VIP Root", client);
	
	new Handle:menu = CreateMenu(Menu_VIPRoot);

	SetMenuTitle(menu, Title);
	SetMenuExitButton(menu, true);

	GetGroupsVIPQuery(grpName, grpLevel, MAX_GROUPS_VIP, sizeof(grpName[]));

	for (new i = 0; i < sizeof(grpName); i++)
	{
		new String:strLevel[2];
		IntToString(grpLevel[i], strLevel, sizeof(strLevel));
		AddMenuItem(menu, strLevel, grpName[i]);
	}

	DisplayMenu(menu, client, 30);
}
*/
/*================== BUILD GENERAL MENU VIP =========================*/
stock BuildgGeneralMenuVIP(client)
{
	if(g_hmVip[client] == INVALID_HANDLE)
		return;

	//Build panel
	new String:titlePanel[50], String:textPanel[100];
	new String:levelName[32], unixTimeExpired;

	new Handle:panel = CreatePanel();

	Format(titlePanel, sizeof(titlePanel), "%T", "Title Menu Gen VIP", client);
	SetPanelTitle(panel, titlePanel);

	Format(textPanel, sizeof(textPanel), "%T", "VIP account is active from", client);
	DrawPanelText(panel, textPanel);

	GetTrieString(g_hmVip[client], "join_date", textPanel, sizeof(textPanel));
	DrawPanelText(panel, textPanel);

	Format(textPanel, sizeof(textPanel), "%T", "And expires on", client);
	DrawPanelText(panel, textPanel);

	GetTrieString(g_hmVip[client], "expired_date", textPanel, sizeof(textPanel));
	DrawPanelText(panel, textPanel);

	GetTrieValue(g_hmVip[client], "expired_unix", unixTimeExpired);
	new timeLeft = unixTimeExpired - GetTime();

	if (timeLeft <= 0)
	{
		Format(textPanel, sizeof(textPanel), "%T", "Your VIP has expired", client);
		DrawPanelText(panel, textPanel);
		Format(textPanel, sizeof(textPanel), "%T", "It will no longer be valid on the following map", client);
		DrawPanelText(panel, textPanel);
	}
	else 
	{
		Format(textPanel, sizeof(textPanel), "%T", "Before the end of the VIP account", client);
		DrawPanelText(panel, textPanel);
		GetTimeLeft(textPanel, sizeof(textPanel), unixTimeExpired);
		DrawPanelText(panel, textPanel);
	}

	GetTrieString(g_hmVip[client], "level_name", levelName, sizeof(levelName));
	Format(textPanel, sizeof(textPanel), "%T", "Your level VIP: %s", client, levelName);
	DrawPanelText(panel, textPanel);
	DrawPanelText(panel, " \n");

	new it = 0;
	if (GetConVarBool(g_cvarUseTagVipChat))
	{
		Format(textPanel, sizeof(textPanel), "%T", "Item TAG", client);
		DrawPanelItem(panel, textPanel);
		strcopy(sItemsMenuVip[client][it], sizeof(sItemsMenuVip[][]), "item_tag");
		it++;
	}
	// Check if the "sm_aura" command exists
	if (GetCommandFlags("sm_aura") != INVALID_FCVAR_FLAGS)
	{
		Format(textPanel, sizeof(textPanel), "%T", "Item Auras", client);
		DrawPanelItem(panel, textPanel);
		strcopy(sItemsMenuVip[client][it], sizeof(sItemsMenuVip[][]), "item_auras");
		it++;
	}
	// Check if the "sm_light" command exists
	if (GetConVarBool(FindConVar("l4d_flashlight_allow")) && GetCommandFlags("sm_light") != INVALID_FCVAR_FLAGS) 
	{
		Format(textPanel, sizeof(textPanel), "%T", "Item Flashlights", client);
		DrawPanelItem(panel, textPanel);
		strcopy(sItemsMenuVip[client][it], sizeof(sItemsMenuVip[][]), "item_light");
		it++;
	}
	Format(textPanel, sizeof(textPanel), "%T", "Item Store", client);
	DrawPanelItem(panel, textPanel);
	strcopy(sItemsMenuVip[client][it], sizeof(sItemsMenuVip[][]), "item_store");
	//Format(textPanel, sizeof(textPanel), "%T", "Item Available commands for VIP", client);
	//DrawPanelItem(panel, textPanel);

	SendPanelToClient(panel, client, Menu_GeneralVIPHandler, 30);
}

/*================== BUILD TAG CHAT MENU VIP ======================*/
stock BuildTagChatMenu(client) 
{
	if (!IsPlayerVip(client))
		return;

	decl String:title[50];
	decl String:item[MAX_STRING_WIDTH];

	new Handle:menu = CreateMenu(Menu_TagChatHandler);

	Format(title, sizeof(title), "%T:", "TAG_Menu", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	Format(item, sizeof(item), "%T", "Chat TAG VIP", client);
	AddMenuItem(menu, "give_tag_vip", item);
	Format(item, sizeof(item), "%T", "Chat Name only", client);
	AddMenuItem(menu, "name_only", item);

	DisplayMenu(menu, client, 30);
}

/*================== BUILD STORE MENU VIP =========================*/
stock BuildMenuStore(client)
{
	if (!IsPlayerVip(client))
		return;

	new level = GetTypeVip(client);

	if(level == 0)
		return;

	if(g_hmStore[level] == INVALID_HANDLE)
		return;

	g_hmCurrItem[client] = INVALID_HANDLE;

	//Build Menu Store
	decl String:title[50];
	decl String:info[MAX_STRING_WIDTH];
	decl String:item[MAX_STRING_WIDTH];

	new Handle:menu = CreateMenu(Menu_StoreHandler);

	Format(title, sizeof(title), "%T:", "Store_Menu", client);

	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	new Handle:tSnStore = CreateTrieSnapshot(g_hmStore[level]);
	new tamSn = TrieSnapshotLength(tSnStore);
	for (new i=0; i < tamSn; i++)
	{
		decl String:buffer[MAX_STRING_WIDTH];
		GetTrieSnapshotKey(tSnStore, i, buffer, sizeof(buffer));
		strcopy(info, sizeof(info), buffer);
		Format(item, sizeof(item), "%T", buffer, client);
		AddMenuItem(menu, info, item);
	}

	CloseHandle(tSnStore);

	DisplayMenu(menu, client, 30);
}

/*================ BUILD ITEM STORE MENU VIP ======================*/
stock BuildMenuItemStore(client, const Handle:hashMap, String:title[])
{	
	if (!IsPlayerVip(client))
		return;

	if (hashMap == INVALID_HANDLE)
		return;

	g_hmCurrItem[client] = hashMap;

	//Build Item Store (Weapons | Melee | Upgrades | Misc)
	//decl String:title[50];
	decl String:info[MAX_STRING_WIDTH];
	decl String:item[MAX_STRING_WIDTH];

	new Handle:menu = CreateMenu(Menu_StoreItemHandler);

	//Format(title, sizeof(title), "%T:", strTrad, client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	new Handle:tSnHash = CreateTrieSnapshot(hashMap);
	new tamSn = TrieSnapshotLength(tSnHash);
	for (new i=0; i < tamSn; i++)
	{
		decl String:buffer[MAX_STRING_WIDTH];
		GetTrieSnapshotKey(tSnHash, i, buffer, sizeof(buffer));
		strcopy(info, sizeof(info), buffer);
		Format(item, sizeof(item), "%T", buffer, client);
		AddMenuItem(menu, info, item);
	}

	CloseHandle(tSnHash);

	DisplayMenu(menu, client, 30);
}

/*========================== MENU HANDLERS ================================*/

// MENU GENERAL VIP HANDLER
public Menu_GeneralVIPHandler(Handle:menu, MenuAction:action, param1, param2)
{	
	if (!IsValidClient(param1))
		return;

	if (action == MenuAction_Select)
	{
		if (param2 <= 0 || param2 > MAX_ITEMS_MENUVIP)
		{
			return;
		}

		if (StrEqual(sItemsMenuVip[param1][param2-1], "item_tag"))
		{
			if (FindConVar("scc_version")) 
			{
				new Handle:scc_enabled = FindConVar("scc_enabled");
				if (!scc_enabled && GetConVarInt(scc_enabled) != 1) {
					return;
				}
			}
			else 
			{
				if (GetConVarBool(g_cvarUseTagVipChat))
				{
					BuildTagChatMenu(param1);
				}
			}
		}
		if (StrEqual(sItemsMenuVip[param1][param2-1], "item_auras"))
		{
			CheatCommand(param1, "sm_aura");
		}
		else if (StrEqual(sItemsMenuVip[param1][param2-1], "item_light"))
		{
			CheatCommand(param1, "sm_light");
		}
		else if (StrEqual(sItemsMenuVip[param1][param2-1], "item_store"))
		{
			if (GetClientTeam(param1) == TEAM_SURVIVORS)
			{
				BuildMenuStore(param1);
			}
		}
		//else if (param2 == 5)
		//{

		//}
	}
}

// MENU TAG CHAT HANDLER
public Menu_TagChatHandler(Handle:menu, MenuAction:action, param1, param2) {
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (!IsValidClient(param1) || IsFakeClient(param1))
		return;

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildgGeneralMenuVIP(param1);
			return;
		}
	}

	if (action != MenuAction_Select)
		return;

	decl String:info[30];

	GetMenuItem(menu, param2, info, sizeof(info));

	if (StrEqual(info, "give_tag_vip")) 
	{
		hasTagVIP[param1] = true;
	}
	else if (StrEqual(info, "name_only")) 
	{
		hasTagVIP[param1] = false;
	}

	if (GetConVarBool(g_cvarCookieTagVip))
	{
		decl String:sHasTag[10];
		IntToString((hasTagVIP[param1] ? 1: 0), sHasTag, sizeof(sHasTag));
		SetClientCookie(param1, g_hTagVIPCookie, sHasTag);
	}

	BuildTagChatMenu(param1);
}

// MENU STORE HANDLER
public Menu_StoreHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (!IsValidClient(param1) || IsFakeClient(param1) || !IsPlayerAlive(param1))
		return;

	new level = GetTypeVip(param1);
	if (g_hmStore[level] == INVALID_HANDLE)
		return;

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildgGeneralMenuVIP(param1);
			return;
		}
	}

	if (action != MenuAction_Select)
		return;

	decl String:info[100];

	GetMenuItem(menu, param2, info, sizeof(info));

	new Handle:hmItem = INVALID_HANDLE;
	GetTrieValue(g_hmStore[level], info, hmItem);

	if (hmItem != INVALID_HANDLE)
	{
		decl String:title[50];
		Format(title, sizeof(title), "%T:", info, param1);
		BuildMenuItemStore(param1, hmItem, title);
	}
}

// MENU STORE ITEM HANDLER
public Menu_StoreItemHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (menu == INVALID_HANDLE)
		return;

	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			BuildMenuStore(param1);
			return;
		}
	}

	if (action != MenuAction_Select || !IsValidClient(param1) || IsFakeClient(param1) || !IsPlayerAlive(param1))
		return;

	if (g_hmCurrItem[param1] == INVALID_HANDLE)
		return;

	decl String:item[100];

	GetMenuItem(menu, param2, item, sizeof(item));

	new maxPerRound;
	if (GetTrieValue(g_hmCurrItem[param1], item, maxPerRound))
	{
		new Handle:hmStoreClient;
		GetTrieValue(g_hmVip[param1], "Store", hmStoreClient);

		if (hmStoreClient != INVALID_HANDLE)
		{
			new nItem = 0;
			GetTrieValue(hmStoreClient, item, nItem);

			if (nItem < maxPerRound)
			{
				decl String:command[20];

				// Get article
				if (StrEqual(item, "laser_sight") || StrEqual(item, "explosive_ammo") || StrEqual(item, "incendiary_ammo"))
				{
					strcopy(command, sizeof(command), "upgrade_add");
					CheatCommand(param1, command, item);
				}
				else if (StrEqual(item, "helicopter_drone"))
				{
					DAV_CallDroneToPlayer(param1, g_fTimeHelicopter, DAVModel_Helicopter);
				}
				else if (StrEqual(item, "f18_drone"))
				{
					DAV_CallDroneToPlayer(param1, g_fTimeHelicopter, DAVModel_JetF18);
				}
				else
				{
					strcopy(command, sizeof(command), "give");
					CheatCommand(param1, command, item);
				}

				// Save the number of times you get the item
				nItem++;
				SetTrieValue(hmStoreClient, item, nItem, true);

				// Save the current hash map
				SetTrieValue(g_hmVip[param1], "Store", hmStoreClient, true);
			}
			else
			{
				// Message that you cannot get the item
				ShowMessageExceededItem(param1, item);
			}
		}
	}

	decl String:title[50];
	GetMenuTitle(menu, title, sizeof(title));

	//Redraw menu after item selection
	BuildMenuItemStore(param1, g_hmCurrItem[param1], title);
	//DisplayMenu(menu, param1, 30);
}

/*=================== PRIVATE FUNCTIONS =========================*/

GetTimeLeft(String:strDate[], maxlength, expiredTime)
{
	new theTime = expiredTime - GetTime();

	if (theTime < 0)
	{
		return;
	}

	new days = theTime /60/60/24;
	new hours = theTime/60/60%24;
	new minutes = (theTime/60)%60;
	//new Float:fmin = theTime/60.0;
	//new res = RoundToFloor(fmin);
	//new seconds = RoundFloat((fmin - res) * 60);
	//new milli         = RoundToZero( (theTime - days - hours - minutes - seconds) * 1000);
	
	Format(strDate, maxlength, "%d d %d h %d min", days, hours, minutes);
}
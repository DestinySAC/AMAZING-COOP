/**
 * =============================================================================
 * [L4D2] VIP Manager by Aceleración
 * Admin commands to manage VIP players
 *
 * Copyrigth (C)2020 Aceleración. All rights reserved.
 * =============================================================================
 */

// ------------------------ Command sm_addvip --------------------------
public Action:Command_AddVIP(client, args)
{
	if(db == INVALID_HANDLE) 
	{
		ReplyToCommand(client, "[%s] No connection to MySQL server", TAG_CONSOLE);
		return Plugin_Handled;
	}

	if(args < 2) 
	{
		ReplyToCommand(client, "[SM] Usage: sm_addvip <# level> <#userid|name|steamid> [minutes]");
		return Plugin_Handled;
	}

	decl String:sArg1[5];
	decl String:sArg2[MAX_STRING_WIDTH];
	decl String:steamId[64];
	new level;
	new timeVip;
	new target;
	new bool:isSteamId, bool:inGame;

	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	level = StringToInt(sArg1);

	if (level == 0 || !IsValidLevelVIP(level))
	{
		ReplyToCommand(client, "[SM] The entered level is incorrect. Enter only numbers and within the level range of the vip");
		return Plugin_Handled;
	}

	if ((StrContains(sArg2, "STEAM_") == 0) || (strncmp("0:", sArg2, 2) == 0) || (strncmp("1:", sArg2, 2) == 0))
	{
		target = GetClientByAuthId(sArg2);
		isSteamId = true;
	}
	else
	{
		target = FindTarget(client, sArg2, true, false);
		isSteamId = false;
	}

	if (isSteamId && target == -1)
	{
		inGame = false;
	}
	else
	{
		if (target == -1)
		{
			return Plugin_Handled;
		}

		inGame = true;

		if (IsPlayerVip(target))
		{
			ReplyToCommand(client, "[%s] Player %N is already a VIP", TAG_CONSOLE, target);
			return Plugin_Handled;
		}

		GetClientAuthId(target, g_AuthType, steamId, sizeof(steamId));
	}

	if (args == 3)
	{	
		decl String:sArg3[10];
		GetCmdArg(3, sArg3, sizeof(sArg3));
		timeVip = StringToInt(sArg3);

		if (timeVip == 0)
		{
			ReplyToCommand(client, "[SM] The entered time is incorrect. Enter only numbers");
			return Plugin_Handled;
		}
	}
	else
	{
		timeVip = g_iTimeAutoDelete;
	}

	new Handle:pack = CreateDataPack();
	WritePackString(pack, steamId);
	WritePackCell(pack, client);
	WritePackCell(pack, target);
	WritePackCell(pack, timeVip);
	WritePackCell(pack, level);
	WritePackCell(pack, inGame);

	SearchVIP(SearchVIP_Active, VIPAddCallback, pack);

	return Plugin_Handled;
}

// ------------------------ Command sm_rmvip ---------------------------
public Action:Command_RemoveVIP(client, args)
{
	if(db == INVALID_HANDLE) 
	{
		ReplyToCommand(client, "[%s] No connection to MySQL server", TAG_CONSOLE);
		return Plugin_Handled;
	}

	if(args < 1) 
	{
		ReplyToCommand(client, "[SM] Usage: sm_rmvip <#userid|name|steamid>");
		return Plugin_Handled;
	}

	decl String:sArg1[MAX_STRING_WIDTH];
	decl String:steamId[64];
	new target;
	new bool:isSteamId, bool:inGame;

	GetCmdArg(1, sArg1, sizeof(sArg1));

	if ((StrContains(sArg1, "STEAM_") == 0) || (strncmp("0:", sArg1, 2) == 0) || (strncmp("1:", sArg1, 2) == 0))
	{
		target = GetClientByAuthId(sArg1);
		isSteamId = true;
	}
	else
	{
		target = FindTarget(client, sArg1, true, false);
		isSteamId = false;
	}

	if (isSteamId && target == -1)
	{
		inGame = false;
	}
	else
	{
		if (target == -1)
		{
			return Plugin_Handled;
		}

		inGame = true;

		if (!IsPlayerVip(target))
		{
			ReplyToCommand(client, "[%s] Player %N is not already a VIP", TAG_CONSOLE, target);
			return Plugin_Handled;
		}

		GetClientAuthId(target, g_AuthType, steamId, sizeof(steamId));
	}

	new Handle:pack = CreateDataPack();
	WritePackString(pack, steamId);
	WritePackCell(pack, client);
	WritePackCell(pack, target);
	WritePackCell(pack, inGame);

	SearchVIP(SearchVIP_Active, VIPRemoveCallback, pack);

	return Plugin_Handled;
}

// --------------------- Command sm_changetimevip ----------------------
public Action:Command_ChangeVIPDuration(client, args)
{
	if(db == INVALID_HANDLE) 
	{
		ReplyToCommand(client, "[%s] No connection to MySQL server", TAG_CONSOLE);
		return Plugin_Handled;
	}

	if(args != 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_changetimevip or sm_chtvip <set|add|sub> <#userid|name|steamid> <minutes>");
		return Plugin_Handled;
	}

	decl String:mode[8];
	decl String:sArg2[MAX_NAME_LENGTH];
	decl String:steamId[64];
	decl String:sArg3[8];
	new target;
	new bool:isSteamId, bool:inGame;

	GetCmdArg(1, mode, sizeof(mode));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	int minutes = StringToInt(sArg3);

	if (minutes <= 0)
	{
		ReplyToCommand(client, "[SM] The entered time is incorrect. Enter only numbers greater than zero");
		return Plugin_Handled;
	}

	if ((StrContains(sArg2, "STEAM_") == 0) || (strncmp("0:", sArg2, 2) == 0) || (strncmp("1:", sArg2, 2) == 0))
	{
		target = GetClientByAuthId(sArg2);
		isSteamId = true;
	}
	else
	{
		target = FindTarget(client, sArg2, true, false);
		isSteamId = false;
	}

	if (isSteamId && target == -1)
	{
		inGame = false;
	}
	else
	{
		if (target == -1)
		{
			return Plugin_Handled;
		}

		inGame = true;

		if (!IsPlayerVip(target))
		{
			ReplyToCommand(client, "[%s] Player %N is not a VIP", TAG_CONSOLE, target);
			return Plugin_Handled;
		}

		GetClientAuthId(target, g_AuthType, steamId, sizeof(steamId));
	}

	if(!StrEqual(mode, "set", false) && !StrEqual(mode, "add", false) && !StrEqual(mode, "sub", false))
	{
		ReplyToCommand(client, "Unknown mode '%s'! Please use 'set', 'add' or 'sub'.", mode);
		return Plugin_Handled;
	}

	new Handle:pack = CreateDataPack();
	WritePackString(pack, steamId);
	WritePackCell(pack, client);
	WritePackCell(pack, target);
	WritePackCell(pack, minutes);
	WritePackCell(pack, inGame);
	WritePackString(pack, mode);

	SearchVIP(SearchVIP_Active, VIPDurationCallback, pack);

	return Plugin_Handled;
}

// ---------------------- Command sm_checkvips -------------------------


// ---------------------- Command sm_vipmhelp --------------------------
public Action:Command_PrintHelp(client, args)
{
	ReplyToCommand(client, "sm_vipmhelp | Lists all commands to configure vips");
	ReplyToCommand(client, "sm_addvip <# level> <#userid|name|steamid> [minutes] | Add a VIP");
	ReplyToCommand(client, "sm_rmvip <#userid|name|steamid> | Remove a VIP");
	ReplyToCommand(client, "sm_changetimevip or sm_chtvip <set|add|sub> <#userid|name|steamid> <minutes> | Change the duration for a VIP.");
	//ReplyToCommand(client, "sm_checkvips | Checks for expired VIPs.");

	return Plugin_Handled;
}

/*=================== PRIVATE FUNCTIONS =========================*/

public VIPAddCallback(Handle:data, bool:exists, bool:active)
{
	decl String:steamId[64];
	decl String:buffTarget[MAX_STRING_WIDTH];

	ResetPack(data);
	ReadPackString(data, steamId, sizeof(steamId));
	new client = ReadPackCell(data);
	new target = ReadPackCell(data);
	new duration = ReadPackCell(data);
	new level = ReadPackCell(data);
	new bool:inGame = ReadPackCell(data);
	CloseHandle(data);

	if (inGame)
	{
		GetClientName(target, buffTarget, sizeof(buffTarget));
	}
	else
	{
		strcopy(buffTarget, sizeof(buffTarget), steamId);
	}

	if (!exists)
	{
		AddVIP(client, target, steamId, duration, level, inGame);
	}
	else
	{
		if (!active)
		{
			//Update VIP
			UpdateVIP(client, target, steamId, duration, level, inGame);
		}
		else
		{
			ReplyClient(client, "[%s] Player '%s' is already a active VIP", TAG_CONSOLE, buffTarget);
		}
	}
}

public VIPRemoveCallback(Handle:data, bool:exists, bool:active)
{
	decl String:steamId[64];
	decl String:buffTarget[MAX_STRING_WIDTH];

	ResetPack(data);
	ReadPackString(data, steamId, sizeof(steamId));
	new client = ReadPackCell(data);
	new target = ReadPackCell(data);
	new bool:inGame = ReadPackCell(data);
	CloseHandle(data);

	if (inGame)
	{
		GetClientName(target, buffTarget, sizeof(buffTarget));
	}
	else
	{
		strcopy(buffTarget, sizeof(buffTarget), steamId);
	}

	if (!exists)
	{
		ReplyClient(client, "[%s] Player '%s' does not have a VIP to remove", TAG_CONSOLE, buffTarget);
	}
	else
	{
		if (active)
		{
			//Remove VIP -> Change Status VIP to 'inactive'
			ChangeStatusVIP(client, target, steamId, STATUS_INACTIVE, inGame);
		}
		else
		{
			ReplyClient(client, "[%s] Player '%s' is not already a VIP", TAG_CONSOLE, buffTarget);
		}
	}
}

public VIPDurationCallback(Handle:data, bool:exists, bool:active)
{
	decl String:steamId[64];
	decl String:mode[8];
	decl String:buffTarget[MAX_STRING_WIDTH];

	ResetPack(data);
	ReadPackString(data, steamId, sizeof(steamId));
	new client = ReadPackCell(data);
	new target = ReadPackCell(data);
	new duration = ReadPackCell(data);
	new bool:inGame = ReadPackCell(data);
	ReadPackString(data, mode, sizeof(mode));
	CloseHandle(data);

	if (inGame)
	{
		GetClientName(target, buffTarget, sizeof(buffTarget));
	}
	else
	{
		strcopy(buffTarget, sizeof(buffTarget), steamId);
	}

	if (!exists)
	{
		ReplyClient(client, "[%s] Player '%s' does not have a VIP to change duration", TAG_CONSOLE, buffTarget);
		return;
	}

	if (active)
	{
		//Remove VIP -> Change Status VIP to 'inactive'
		ChangeVIPDuration(client, target, steamId, mode, duration, inGame);
	}
	else
	{
		ReplyClient(client, "[%s] Player '%s' is not already a VIP", TAG_CONSOLE, buffTarget);
	}

}

GetClientByAuthId(const String:steamid[])
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			decl String:tSteamId[64];
			GetClientAuthId(i, g_AuthType, tSteamId, sizeof(tSteamId));

			if (StrEqual(tSteamId, steamid))
			{
				return i;
			}
		}
	}

	return -1;
}

 
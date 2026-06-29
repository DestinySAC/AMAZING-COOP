/**
 * =============================================================================
 * [L4D2] VIP Manager by Aceleración
 * Read, update, select and delete vips using SQL
 *
 * Copyrigth (C)2020 Aceleración. All rights reserved.
 * =============================================================================
 */

// database connect -------------------------------------------------
bool:ConnectDB()
{
	if (db != INVALID_HANDLE)
		return true;

	if (SQL_CheckConfig(DATABASE_CONFIG))
	{
		new String:Error[256];
		db = SQL_Connect(DATABASE_CONFIG, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
		{
			LogError("[%s] Failed to connect to database: %s", TAG_CONSOLE, Error);
			return false;
		}

		SQL_LockDatabase(db);
		if (!SQL_FastQuery(db, "SET NAMES 'utf8'"))
		{
			SQL_UnlockDatabase(db);
			if (SQL_GetError(db, Error, sizeof(Error)))
			{
				LogError("[%s] Failed to update encoding to UTF8: %s", TAG_CONSOLE, Error);
			}
			else
			{
				LogError("[%s] Failed to update encoding to UTF8: unknown", TAG_CONSOLE);
			}
		}

		SQL_UnlockDatabase(db);

		if (!CheckDatabaseValidity())
		{
			LogError("[%s] CheckDatabaseValidity failure", TAG_CONSOLE);
			return false;
		}
	}
	else
	{
		LogError("[%s] Databases.cfg missing '%s' entry!", TAG_CONSOLE, DATABASE_CONFIG);
		return false;
	}

	return true;
}

// check the database (if has the table of vips)
bool:CheckDatabaseValidity()
{
	if (!DoFastQuery("SELECT * FROM vips_groups WHERE 1 = 2"))
	{
		return false;
	}

	if (!DoFastQuery("SELECT * FROM vips_players WHERE 1 = 2"))
	{
		new String:query[400];
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS vips_players (identity VARCHAR(64) PRIMARY KEY, name tinyblob NOT NULL, lastJoinDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, duration INT NOT NULL, lastExpiredDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, unixTimeExpired INT NOT NULL, status ENUM('active', 'inactive', 'expired') NOT NULL, id_vipGroup INT, FOREIGN KEY(id_vipGroup) REFERENCES vips_groups(idGroup)) ENGINE=MyISAM DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");
		if (!DoQuery(query))
		{
			return false;
		}
	}

	if (!DoFastQuery("SELECT * FROM vips_historial WHERE 1 = 2"))
	{
		new String:query[400];
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS vips_historial (identity VARCHAR(64) NOT NULL, joinDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, duration INT NOT NULL, expiredDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP, id_vipGroup INT, FOREIGN KEY(id_vipGroup) REFERENCES vips_groups(idGroup)) ENGINE=MyISAM DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;");
		if (!DoQuery(query))
		{
			return false;
		}
	}

	return true;
}

// To do quick SQL queries
bool:DoFastQuery(const String:query[], any:...)
{
	new String:sBufferQuery[1024];
	VFormat(sBufferQuery, sizeof(sBufferQuery), query, 2);

	new String:Error[256];

	SQL_LockDatabase(db);
	if (!SQL_FastQuery(db, sBufferQuery))
	{
		SQL_UnlockDatabase(db);
		if (SQL_GetError(db, Error, sizeof(Error)))
		{
			LogError("[%s] Database is missing required table or tables: %s", TAG_CONSOLE, Error);
		}
		else{
			LogError("[%s] Database is missing required table or tables: unknown", TAG_CONSOLE);
		}

		return false;
	}

	SQL_UnlockDatabase(db);

	return true;
}

// To make simple SQL queries
bool:DoQuery(const String:query[], any:...)
{
	new String:sBufferQuery[1024];
	VFormat(sBufferQuery, sizeof(sBufferQuery), query, 2);

	new String:Error[256];
	
	SQL_LockDatabase(db);

	new Handle:hndl1 = SQL_Query(db, sBufferQuery);

	if (hndl1 == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);

		if(SQL_GetError(db, Error, sizeof(Error)))
		{
			LogError("[%s] Query failed!: %s", TAG_CONSOLE, Error);
		}
		else{
			LogError("[%s] Query failed!: unknown", TAG_CONSOLE);
		}
		return false;
	}

	SQL_UnlockDatabase(db);
	CloseHandle(hndl1);

	return true;
}

SearchVIP(SearchVIPType:selectType, Function:callback, any:data)
{	
	decl String:query[512];
	decl String:steamId[64];

	ResetPack(data);
	ReadPackString(data, steamId, sizeof(steamId));

	new Handle:pack = CreateDataPack();
	WritePackCell(pack, selectType);

	if (selectType == SearchVIP_Active)
	{
		WritePackCell(pack, data);
		WritePackFunction(pack, callback);
		Format(query, sizeof(query), "SELECT status = 'active' as active FROM vips_players WHERE identity = '%s';", steamId);
	}
	else if (selectType == SearchVIP_Expired)
	{
		WritePackCell(pack, ReadPackCell(data));
		WritePackFunction(pack, callback);
		Format(query, sizeof(query), "SELECT lastExpiredDate <= NOW() as expired FROM vips_players WHERE identity = '%s' AND status = 'active' AND duration >= 0;", steamId);
	}

	SQL_TQuery(db, SQL_SearchVIPCallback, query, pack);
}

public SQL_SearchVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);
	new SearchVIPType:selectType = ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Query SQL_SearchVIPCallback failed!: %s", TAG_CONSOLE, error);
		if (selectType == SearchVIP_Expired)
		{
			new client = ReadPackCell(data);
			RunAdminCacheChecks(client);
			NotifyPostAdminCheck(client);
		}
		CloseHandle(data);
		return;
	}

	decl bool:plExists;

	if (!SQL_GetRowCount(hndl))
	{
		plExists = false;
	}
	else
	{
		plExists = true;
	}

	decl String:strFuncName[40];
	decl bool:vStatus;
	while(SQL_FetchRow(hndl))
	{
		vStatus = view_as<bool>(SQL_FetchInt(hndl, 0));
	}

	new any:received = ReadPackCell(data);
	//ReadPackString(data, strFuncName, sizeof(strFuncName));

	//new Function:funcAction = GetFunctionByName(INVALID_HANDLE, strFuncName);
	new Function:funcAction = ReadPackFunction(data);

	if (funcAction != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, funcAction);
		Call_PushCell(received);
		Call_PushCell(plExists);
		Call_PushCell(vStatus);
		Call_Finish();
	}
	else
	{
		LogError("[%s] Invalid function: %s", TAG_CONSOLE, strFuncName);
	}

	

	CloseHandle(data);
}

FetchVipPlayer(client)
{
	if(client < 1 || !IsClientConnected(client) || IsClientBot(client))
		return;

	decl String:query[512], String:steamId[64];

	GetClientAuthId(client, g_AuthType, steamId, sizeof(steamId));

	Format(query, sizeof(query), "SELECT v.lastJoinDate, v.lastExpiredDate, v.unixTimeExpired, g.groupName, g.alias, g.level FROM vips_players as v JOIN vips_groups as g ON v.id_vipGroup = g.idGroup WHERE v.identity = '%s' AND v.status = 'active' AND v.lastExpiredDate > NOW() AND v.duration >= 0;", steamId);

	/**
	 * Send the actual query.
	 */	
	playerSeq[client] = ++g_sequence;

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, playerSeq[client]);

	SQL_TQuery(db, SQL_CheckVIPCallback, query, pack);
}

public SQL_CheckVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:data) 
{	
	ResetPack(data);
	new client = ReadPackCell(data);
	new currentSequence =  ReadPackCell(data);
	CloseHandle(data);

	/**
	 * Check if this is the latest result request.
	 */
	if (playerSeq[client] != currentSequence)
	{
		/* Discard everything, since we're out of sequence. */
		return;
	}

	/**
     * If we need to use the results, make sure they succeeded.
     */
	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Query SQL_CheckVIPCallback failed!: %s", TAG_CONSOLE, error);
		RunAdminCacheChecks(client);
		NotifyPostAdminCheck(client);
		return;
	}

	if (!SQL_GetRowCount(hndl))
	{
		//LogMessage("[%s] There are no vips in the database", TAG_CONSOLE);
		RunAdminCacheChecks(client);
		NotifyPostAdminCheck(client);
		return;
	}

	decl String:lastJoinDate[20];
	decl String:lastExpiredDate[20];
	decl unixTimeExpired;
	decl String:groupName[32];
	decl String:aliasLevel[32];
	decl level;

	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, lastJoinDate, sizeof(lastJoinDate));
		SQL_FetchString(hndl, 1, lastExpiredDate, sizeof(lastExpiredDate));
		unixTimeExpired = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, groupName, sizeof(groupName));
		SQL_FetchString(hndl, 4, aliasLevel, sizeof(aliasLevel));
		level = SQL_FetchInt(hndl, 5);
	}

	// DataPack
	Handle pack = CreateDataPack();
	WritePackString(pack, groupName);
	WritePackString(pack, aliasLevel);
	WritePackString(pack, lastJoinDate);
	WritePackString(pack, lastExpiredDate);
	WritePackCell(pack, unixTimeExpired);
	WritePackCell(pack, level);

	if (AddVIPToAdminCache_PreAdmCheck(client, pack))
	{
		LogDebug("¡Se agregó con éxito %N como VIP!", client);
	}
	else
	{
		LogDebug("¡No se puede agregar VIP al jugador %N en el caché de administrador!", client);
		LogError("[%s] Can't add VIP to player %N in admin cache!", TAG_CONSOLE, client);
	}
}

FetchVipGroups(sequence)
{
	decl String:query[256];

	Format(query, sizeof(query), "SELECT groupName, flags, immunity FROM vips_groups");

	SQL_TQuery(db, SQL_CheckGroupVIPCallback, query, sequence, DBPrio_High);
}

public SQL_CheckGroupVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:sequence) 
{
	if (rebuildCachePart[AdminCache_Groups] != sequence)
	{
		LogDebug("SQL_CheckGroupVIPCallback >> Discard everything, since we're out of sequence");
		/* Discard everything, since we're out of sequence. */
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Query SQL_CheckGroupVIPCallback failed!: %s", TAG_CONSOLE, error);
		return;
	}

	if (!SQL_GetRowCount(hndl))
	{
		LogError("[%s] Not founds vip groups", TAG_CONSOLE);
		return;
	}
	
	decl String:groupName[32];
	decl String:flags[32];
	decl immunity;

	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, groupName, sizeof(groupName));
		SQL_FetchString(hndl, 1, flags, sizeof(flags));
		immunity = SQL_FetchInt(hndl, 2);

		// DataPack
		new Handle:pack = CreateDataPack();
		WritePackString(pack, groupName);
		WritePackString(pack, flags);
		WritePackCell(pack, immunity);

		LogDebug("SQL_CheckGroupVIPCallback >> Found Group: %s | %s | %i", groupName, flags, immunity);

		AddGroupVIPToGroupAdmCache(pack);
	}

	/* Clear the sequence so another connect doesn't refetch */
	rebuildCachePart[AdminCache_Groups] = 0;
}

// To get the names and levels of each group of vips
bool:GetGroupsVIPQuery(String:grpName[][], grpLevels[], int maxArray, int maxStringLength)
{	
	if(maxArray < 1)
	{
		return false;
	}
	
	new String:query[256];

	Format(query, sizeof(query), "SELECT groupName, level FROM vips_groups");

	new String:error[256];
	
	SQL_LockDatabase(db);

	new Handle:hndl = SQL_Query(db, query);

	if (hndl == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);

		if(SQL_GetError(db, error, sizeof(error)))
		{
			LogError("[%s] GetGroupsVIPQuery >> Groups VIP fetching failed!: %s", TAG_CONSOLE, error);
		}
		else{
			LogError("[%s] GetGroupsVIPQuery >> Groups VIP fetching failed!: unknown", TAG_CONSOLE);
		}
		return false;
	}

	SQL_UnlockDatabase(db);

	if (SQL_GetRowCount(hndl) == 0)
	{
		LogError("[%s] GetGroupsVIPQuery >> No VIP groups found in database", TAG_CONSOLE);
		return false;
	}

	new i = 0;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, grpName[i], maxStringLength);
		grpLevels[i] = SQL_FetchInt(hndl, 1);
		i++;
	}

	CloseHandle(hndl);

	return true;
}

FindIdGroupVIPQuery(level)
{
	new String:query[256];

	Format(query, sizeof(query), "SELECT idGroup FROM vips_groups WHERE level = %d", level);

	new String:error[256];
	
	SQL_LockDatabase(db);

	new Handle:hndl = SQL_Query(db, query);

	if (hndl == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);

		if(SQL_GetError(db, error, sizeof(error)))
		{
			LogError("[%s] FindLevelGroupVIPQuery >> Find level group failed!: %s", TAG_CONSOLE, error);
		}
		else{
			LogError("[%s] FindLevelGroupVIPQuery >> Find level group failed!: unknown", TAG_CONSOLE);
		}
		return false;
	}

	SQL_UnlockDatabase(db);

	if (SQL_GetRowCount(hndl) == 0)
	{
		//LogError("[%s] FindLevelGroupVIPQuery >> No group in database with level %d", TAG_CONSOLE, level);
		return 0;
	}

	decl idGroup;
	while(SQL_FetchRow(hndl))
	{
		idGroup = SQL_FetchInt(hndl, 0);
	}

	return idGroup;
}

AddVIP(caller, player, const String:identity[], duration, level, bool:inGame=true)
{
	if (player == -1 && inGame)
		return;

	if (inGame && !IsValidClient(player))
		return;

	if (!IsValidSteamId(identity))
		return;

	if (duration < 1)
		return;

	decl String:playerName[MAX_NAME_LENGTH];

	if (inGame)
	{
		GetClientName(player, playerName, sizeof(playerName));
	}
	else
	{
		strcopy(playerName, sizeof(playerName), "Anonymous");
	}

	new idGroup = FindIdGroupVIPQuery(level);

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, caller);
	WritePackCell(pack, player);
	WritePackCell(pack, inGame);
	WritePackString(pack, identity);

	decl String:query[512];
	Format(query, sizeof(query), "INSERT INTO vips_players (identity, name, duration, lastExpiredDate, unixTimeExpired, status, id_vipGroup) VALUES ('%s', '%s', %d, DATE_ADD(NOW(), INTERVAL `duration` MINUTE), UNIX_TIMESTAMP(`lastExpiredDate`), 'active', %d)", identity, playerName, duration, idGroup);

	SQL_TQuery(db, SQL_AddVIPCallback, query, pack);
}

public SQL_AddVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:data) 
{	
	decl String:steamId[64];

	ResetPack(data);
	new caller = ReadPackCell(data);
	new player =  ReadPackCell(data);
	new bool:inGame =  ReadPackCell(data);
	ReadPackString(data, steamId, sizeof(steamId));
	CloseHandle(data);

	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Error in insert a vip!. Query failed: %s", TAG_CONSOLE, error);
		PrintToChat(caller, "%s %t", CHAT_TAG, "Add Vip Offline Failed", steamId);
		return;
	}
	
	if(inGame)
	{
		data = CreateDataPack();
		WritePackCell(data, caller);
		WritePackCell(data, player);

		decl String:query[512];
		Format(query, sizeof(query), "SELECT v.lastJoinDate, v.lastExpiredDate, v.unixTimeExpired, g.groupName, g.alias, g.level FROM vips_players as v JOIN vips_groups as g ON v.id_vipGroup = g.idGroup WHERE v.identity = '%s' AND v.status = 'active' AND v.lastExpiredDate > NOW() AND v.duration >= 0;", steamId);
		SQL_TQuery(db, SQL_CheckVIPCallback_InGame, query, data);
	}
	else
	{
		PrintToChat(caller, "%s %t", CHAT_TAG, "Add Vip Offline Success", steamId);
	}
}

public SQL_CheckVIPCallback_InGame(Handle:owner, Handle:hndl, const String:error[], any:data) 
{	
	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Query SQL_CheckVIPCallback failed!: %s", TAG_CONSOLE, error);
		CloseHandle(data);
		return;
	}

	if (SQL_GetRowCount(hndl) != 1)
	{
		CloseHandle(data);
		return;
	}

	ResetPack(data);
	new caller = ReadPackCell(data);
	new player =  ReadPackCell(data);
	CloseHandle(data);

	decl String:lastJoinDate[20];
	decl String:lastExpiredDate[20];
	decl unixTimeExpired;
	decl String:groupName[32];
	decl String:aliasLevel[32];
	decl level;

	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, lastJoinDate, sizeof(lastJoinDate));
		SQL_FetchString(hndl, 1, lastExpiredDate, sizeof(lastExpiredDate));
		unixTimeExpired = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, groupName, sizeof(groupName));
		SQL_FetchString(hndl, 4, aliasLevel, sizeof(aliasLevel));
		level = SQL_FetchInt(hndl, 5);
	}

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackString(pack, groupName);
	WritePackString(pack, aliasLevel);
	WritePackString(pack, lastJoinDate);
	WritePackString(pack, lastExpiredDate);
	WritePackCell(pack, unixTimeExpired);
	WritePackCell(pack, level);

	if (AddVipPlayerToAdminCache_InGame(player, pack))
	{
		LogDebug("¡Se agregó con éxito %N como VIP!", player);
		PrintToChat(caller, "%s %t", CHAT_TAG, "Add Vip InGame Success", player);
	}
	else
	{
		LogDebug("¡No se puede agregar VIP al jugador %N en el caché de administrador!", player);
		PrintToChat(caller, "%s %t", CHAT_TAG, "Add Vip InGame Failed", player);
	}
}

ChangeStatusVIP(caller, player, const String:steamId[], StatusVIP:status, bool:InGame)
{
	decl String:query[512];
	decl String:strStatus[15];

	switch(status)
	{
		case STATUS_ACTIVE:
		{
			strcopy(strStatus, sizeof(strStatus), "active");
		}
		case STATUS_INACTIVE:
		{
			strcopy(strStatus, sizeof(strStatus), "inactive");
		}
		case STATUS_EXPIRED:
		{
			strcopy(strStatus, sizeof(strStatus), "expired");
		}
	}

	Format(query, sizeof(query), "UPDATE vips_players SET status = '%s' WHERE identity = '%s';", strStatus, steamId);

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, caller);
	WritePackCell(pack, player);
	WritePackString(pack, steamId);
	WritePackString(pack, strStatus);
	WritePackCell(pack, InGame);

	SQL_TQuery(db, SQL_ChangeStatusVIPCallback, query, pack);
}

public SQL_ChangeStatusVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Query SQL_ChangeStatusVIPCallback failed!: %s", TAG_CONSOLE, error);
		CloseHandle(data);
		return;
	}

	decl String:steamId[64];
	decl String:strStatus[15];

	ResetPack(data);
	new caller = ReadPackCell(data);
	new player = ReadPackCell(data);
	ReadPackString(data, steamId, sizeof(steamId));
	ReadPackString(data, strStatus, sizeof(strStatus));
	new bool:InGame =  ReadPackCell(data);
	CloseHandle(data);

	ReplyClient(caller, "%s %t", CHAT_TAG, "Change Status VIP", steamId, strStatus);
	LogDebug("%t", "Change Status VIP", steamId, strStatus);

	if (StrEqual(strStatus, "active"))
	{
		return;
	}
	
	if (InGame)
	{
		if (RemoveVIPFromAdminCache(player))
		{
			ReplyClient(caller, "%s %t", CHAT_TAG, "Remove Vip InGame Success", player);
		}
		else
		{
			ReplyClient(caller, "%s %t", CHAT_TAG, "Remove Vip InGame Failed", player);
		}
	}
}

UpdateVIP(caller, player, const String:identity[], duration, level, bool:inGame=true)
{
	if (player == -1 && inGame)
		return;

	if (inGame && !IsValidClient(player))
		return;

	if (!IsValidSteamId(identity))
		return;

	if (duration < 1)
		return;

	decl String:playerName[MAX_NAME_LENGTH];
	decl String:UpSQLName[MAX_NAME_LENGTH];

	if (inGame)
	{
		GetClientName(player, playerName, sizeof(playerName));
		Format(UpSQLName, sizeof(UpSQLName), ", name = '%s'", playerName);
	}
	else
	{
		strcopy(UpSQLName, sizeof(UpSQLName), "");
	}

	new idGroup = FindIdGroupVIPQuery(level);

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, caller);
	WritePackCell(pack, player);
	WritePackCell(pack, inGame);
	WritePackString(pack, identity);

	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE vips_players SET duration = %d, lastJoinDate = CURRENT_TIMESTAMP(), lastExpiredDate = DATE_ADD(NOW(), INTERVAL `duration` MINUTE), unixTimeExpired = UNIX_TIMESTAMP(`lastExpiredDate`), status = 'active', id_vipGroup = %i%s WHERE identity = '%s';", duration, idGroup, UpSQLName, identity);

	SQL_TQuery(db, SQL_UpdateVIPCallback, query, pack);
}

public SQL_UpdateVIPCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:steamId[64];

	ResetPack(data);
	new caller = ReadPackCell(data);
	new player =  ReadPackCell(data);
	new bool:inGame =  ReadPackCell(data);
	ReadPackString(data, steamId, sizeof(steamId));
	CloseHandle(data);

	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Error in update a vip!. Query failed: %s", TAG_CONSOLE, error);
		PrintToChat(caller, "%s %t", CHAT_TAG, "Update Vip Offline Failed", steamId);
		return;
	}
	
	if (inGame)
	{
		new Handle:pack = CreateDataPack();
		WritePackCell(pack, caller);
		WritePackCell(pack, player);

		decl String:query[512];
		Format(query, sizeof(query), "SELECT v.lastJoinDate, v.lastExpiredDate, v.unixTimeExpired, g.groupName, g.alias, g.level FROM vips_players as v JOIN vips_groups as g ON v.id_vipGroup = g.idGroup WHERE v.identity = '%s' AND v.status = 'active' AND v.lastExpiredDate > NOW() AND v.duration >= 0;", steamId);
		SQL_TQuery(db, SQL_CheckVIPCallback_InGame, query, pack);
	}
	else
	{
		PrintToChat(caller, "%s %t", CHAT_TAG, "Update Vip Offline Success", steamId);
	}
}

ChangeVIPDuration(caller, player, const String:identity[], const String:mode[], duration, bool:inGame=true)
{
	decl String:sbufferDuration[50];

	if(StrEqual(mode, "set", false))
		Format(sbufferDuration, sizeof(sbufferDuration), "duration = %i", duration);
	else if(StrEqual(mode, "add", false))
		Format(sbufferDuration, sizeof(sbufferDuration), "duration = duration + %i", duration);
	else if(StrEqual(mode, "sub", false))
		Format(sbufferDuration, sizeof(sbufferDuration), "duration = duration - %i", duration);

	decl String:query[512];

	Format(query, sizeof(query), "UPDATE vips_players SET %s, lastExpiredDate = DATE_ADD(NOW(), INTERVAL `duration` MINUTE), unixTimeExpired = UNIX_TIMESTAMP(`lastExpiredDate`) WHERE identity = '%s';", sbufferDuration, identity);

	// DataPack
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, caller);
	WritePackCell(pack, player);
	WritePackCell(pack, inGame);
	WritePackString(pack, identity);

	SQL_TQuery(db, SQL_ChangeVIPDurationCallback, query, pack);
}

public SQL_ChangeVIPDurationCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:steamId[64];

	ResetPack(data);
	new caller = ReadPackCell(data);
	new player =  ReadPackCell(data);
	new bool:inGame =  ReadPackCell(data);
	ReadPackString(data, steamId, sizeof(steamId));
	CloseHandle(data);

	if (hndl == INVALID_HANDLE)
	{
		LogError("[%s] Error in change duration a vip!. Query failed: %s", TAG_CONSOLE, error);
		ReplyClient(caller, "%s %t", CHAT_TAG, "Change Duration Vip Offline Failed", steamId);
		return;
	}
	
	if (inGame)
	{
		ReplyClient(caller, "%s %t", CHAT_TAG, "Change Duration Vip InGame Success", player);
		PrintToChat(player, "%s %t", CHAT_TAG, "Target Change Duration");
	}
	else
	{
		ReplyClient(caller, "%s %t", CHAT_TAG, "Change Duration Vip Offline Success", steamId);
	}
}
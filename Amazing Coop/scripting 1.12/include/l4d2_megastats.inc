#if defined _megastats_included
  #endinput
#endif
#define _megastats_included

/**
 * Return the client rank
 * @param client Client index
 * @return Client rank on sucess.
 * @error Throw error if client is invalid.
 */
native MS_GetPlayerRank(client);

/**
 * Return the client points
 * @param client Client index
 * @return Client points on success
 * @error Throw error if client is invalid.
 */
native MS_GetPlayerPoints(client);

/**
 * Return the client points of the current round
 * @param client Client index
 * @return Client points of the round on success
 * @error Throw error if client is invalid.
 */
native MS_GetPlayerCurrentPoints(client);

/**
 * Return the client points of the current map
 * @param client Client index
 * @return Client points of the map on success
 * @error Throw error if client is invalid.
 */
native MS_GetPlayerMapPoints(client);

/**
 * Add points to a player
 * @param client Client index
 * @param points Points to add
 * @noreturn
 * @error Throw error if client is invalid or points be less than or equal to zero
 */
native MS_AddPlayerPoints(client, points);

/**
 * Returns if the client belongs to the specified top
 * @param client Client index
 * @param top Top player index
 * @return True if the client belongs to the top, otherwise it is false
 * @error Throw error if client is invalid or if top index is invalid
 */
native bool:MS_IsPlayerTop(client, top);

/**
 * Returns if the megastats is enabled
 * @return True if the megastats is enabled, otherwise it is false
 */
native bool:MS_IsStatsEnabled();

/**
 * Called when a client has changed rank
 * @param client		Client index
 * @param newRank		The new rank of the client
 * @noreturn
 */
forward MS_OnChangeRank(client, newRank);

public SharedPlugin:__pl_megastats =
{
	name = "l4d2_megastats",
	file = "l4d2_megastats.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_megastats_SetNTVOptional()
{
	MarkNativeAsOptional("MS_GetPlayerRank");
	MarkNativeAsOptional("MS_GetPlayerPoints");
	MarkNativeAsOptional("MS_IsPlayerTop");
	MarkNativeAsOptional("MS_IsStatsEnabled");
}
#endif
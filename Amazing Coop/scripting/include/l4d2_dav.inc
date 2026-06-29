#if defined _l4d2dav_included
  #endinput
#endif
#define _l4d2dav_included

#define MINTIME_DRONELIFE	20.0
#define MAXTIME_DRONELIFE	600.0

/**
 *  DAVModelType: The type of Drone Aerial Vehicles to create
 */
enum DAVModelType
{
	DAVModel_Random = 0,
    DAVModel_JetF18 = 1,
    DAVModel_Helicopter = 2,
};


/**
 * Creates an Drone Aerial Vehicles to the specified player.
 *
 * @param client Client index
 * @param time Drone life time. It must not be greater than MAXTIME DRONELIFE or less than MINTIME_DRONELIFE.
 * @param modelType DAV Model Type to use.
 * @return True if the drone was created, false otherwise.
 */
native bool:DAV_CallDroneToPlayer(client, Float:time, DAVModelType:modelType);

public SharedPlugin:__pl_l4d2dav =
{
	name = "l4d2_dav",
	file = "l4d2_drone_aerial_vehicles.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_l4d2dav_SetNTVOptional()
{
	MarkNativeAsOptional("DAV_CallDroneToPlayer");
}
#endif
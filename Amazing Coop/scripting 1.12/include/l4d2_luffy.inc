/*
todo list?
- 
// sm_cvar l4d2_luffy_airstrike_num 10000
// sm_cvar l4d2_luffy_homing_num 1000
*/

#define ZOMBIE_NONE				0
#define ZOMBIE_SMOKER			1		// team that give so much blast ingame
#define ZOMBIE_BOOMER			2
#define ZOMBIE_HUNTER			3
#define ZOMBIE_SPITTER			4
#define ZOMBIE_JOCKEY			5
#define ZOMBIE_CHARGER			6
#define ZOMBIE_UNKNOWN			7
#define ZOMBIE_TANK				8

#define TEAM_SURVIVOR			2		// biden
#define TEAM_INFECTED			3		// trump

#define WEAPON_TIER1			0
#define WEAPON_TIER2			1
#define WEAPON_TIERALL			2

#define PROPTYPE_DYNAMIC		"prop_dynamic_override"					// CreatEntRenderModel
#define PROPTYPE_MOLOTOVE		"molotov_projectile"					// CreatEntRenderModel

#define PARTICLE_CREATEFIRE		"models/props_junk/gascan001a.mdl"		// model to create fire for CreatPointDamageRadius
#define PARTICLE_EXPLOSIVE		"gas_explosion_pump"					// CreatePointParticle and CreatPointDamageRadius
#define PARTICLE_ELECTRIC1		"electrical_arc_01_system"				// CreatePointParticle and CreatPointDamageRadius
#define PARTICLE_ELECTRIC2		"electrical_arc_01_cp0"					// CreatePointParticle and CreatPointDamageRadius

#define DAMAGE_EXPLOSIVE		-2122317758
#define INVALID_VALUE			-1

#define SHIELD_TYPE_DAMAGE		1		// shield type
#define SHIELD_TYPE_DECO		2		// type 2 so far unused. just for decoration. also untested.( should be working fine from the previous version)
#define SHIELD_TYPE_PUSH		3

#define AXIS_PITCH				0			// axis rotation of our angle manipulation
#define AXIS_YAW				1
#define AXIS_ROLL				2

#define POS_CLOCK				0			// track our model position in array
#define POS_SPEED				1
#define POS_POISON				2
#define POS_REGEN				3
#define POS_SHIELD				4
#define POS_STRENGTH			5
#define POS_GIFT				6
#define POS_HOMING				7
#define POS_JETF18				8
#define POS_SDKHOOK				9

int g_iColor_White[3]	= { 255, 255, 255 };	//<< hardcode this instead for re-use and tweak.
int g_iColor_Red[3]		= { 255, 000, 000 };	//<< appology.. my OCD kicks in. let that zero be. << Dont you dare change that..!!!
int g_iColor_LRed[3]	= { 255, 128, 128 };
int g_iColor_Green[3]	= { 000, 255, 000 };
int g_iColor_LGreen[3]	= { 128, 255, 128 };
int g_iColor_Blue[3]	= { 000, 000, 255 };
int g_iColor_LBlue[3]	= { 000, 128, 255 };
int g_iColor_Pinky[3]	= { 255, 000, 255 };
int g_iColor_Yellow[3]	= { 255, 255, 000 };
int g_iColor_Dark[3]	= { 128, 128, 128 };
int g_iColor_Exaust[3]	= { 060, 080, 200 };

stock void CreatePointHurt( int attacker, int victim, int damage, int damage_type, float pos[3], float radius )  //<< ok
{
	int  pointHurt = CreateEntityByName( "point_hurt" );
	if ( pointHurt )
	{
		SetOwner( pointHurt, attacker );
		
		char dmname[16];
		Format( dmname, sizeof( dmname ), "luffy_hurt%d", pointHurt );
		
		char dmg[8];
		IntToString( damage, dmg, sizeof( dmg ));
		
		char rad[8];
		FloatToString( radius, rad, sizeof( rad ));
		
		char type[16];
		IntToString( damage_type, type, sizeof( type ));  //<< damage explosive
	
		DispatchKeyValue( pointHurt, "DamageTarget", dmname );
		DispatchKeyValue( victim, "targetname", dmname );
		DispatchKeyValue( pointHurt, "DamageRadius", rad );
		DispatchKeyValue( pointHurt, "Damage", dmg );
		DispatchKeyValue( pointHurt, "DamageType", type );
		//DispatchKeyValue( pointHurt, "classname", "weapon_grenade_launcher" );
		DispatchKeyValue( pointHurt, "DamageDelay", "0.0" );
		TeleportEntity( pointHurt, pos, NULL_VECTOR, NULL_VECTOR );
		DispatchSpawn( pointHurt );
		AcceptEntityInput( pointHurt, "Hurt", attacker );
		//DispatchKeyValue( pointHurt, "classname", "point_hurt" );
		//DispatchKeyValue( pointHurt, "targetname", "target_none");
		RemoveEntity_Kill( pointHurt );
	}
}

stock void CreatePointPush( float force, float radius, float pos[3], float life )
{
	int  push = CreateEntityByName( "point_push" );
	if ( push != -1 )
	{
		char frc[8];
		FloatToString( force, frc, sizeof( frc ));
		
		char rad[8];
		FloatToString( radius, rad, sizeof( rad ));
		
		char ptname[16];
		Format( ptname, sizeof( ptname ), "luffy_push%d", push );

		DispatchKeyValue( push, "targetname", ptname );
		DispatchKeyValue( push, "magnitude", frc );
		DispatchKeyValue( push, "radius", rad );
		SetVariantString( "spawnflags 24" );
		AcceptEntityInput( push, "AddOutput" );
		DispatchSpawn( push );
		TeleportEntity( push, pos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( push, "Enable" );
		CreateTimer( life, Timer_DeletePointCreated, EntIndexToEntRef( push ));
	}
}

stock bool CreatePointParticle( float pos[3], const char[] particle_type, float life ) //<< can use to precache particle
{
	// the explosion effect
	int  particle = CreateEntityByName( "info_particle_system" );
	if ( particle > 0 && IsValidEdict( particle ))
	{
		char ptname[16];
		Format( ptname, sizeof( ptname ), "luffy_particle%d", particle );
		DispatchKeyValue( particle, "targetname", ptname );
		DispatchKeyValue( particle, "effect_name", particle_type );
		TeleportEntity( particle, pos, NULL_VECTOR, NULL_VECTOR );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start" );
		CreateTimer( life,  Timer_DeletePointCreated, EntIndexToEntRef( particle ));
		return true;
	}
	return false;
}

public Action Timer_DeletePointCreated( Handle timer, any entref )
{
	int entity = EntRefToEntIndex( entref );
	if( entity > 0 && IsValidEdict( entity ))
	{
		RemoveEdict( entity );
	}
	return Plugin_Continue
}

stock bool CreatPointDamageRadius( float pos[3], const char[] model, int damage, int radius, int damage_owner )
{
	int  entity = CreateEntityByName( "prop_physics" );
	if ( IsValidEntity( entity ))
	{
		char dmg[8];
		IntToString( damage, dmg, sizeof( dmg ));
		
		char rad[8];
		IntToString( radius, rad, sizeof( rad ));
		
		DispatchKeyValue( entity, "model", model );
		DispatchKeyValue( entity, "ExplodeDamage", dmg );
		DispatchKeyValue( entity, "ExplodeRadius", rad );
		SetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity", damage_owner );
		SetEntData( entity, GetEntSendPropOffs( entity, "m_CollisionGroup" ), 1, 1, true );
		DispatchSpawn( entity );
		TeleportEntity( entity, pos, NULL_VECTOR, NULL_VECTOR );
		AcceptEntityInput( entity, "break" );
		CreateTimer( 0.1,  Timer_DeletePointCreated, EntIndexToEntRef( entity ));
		return true;
	}
	return false;
}

stock int CreatEntRenderModel( const char[] prop_type, const char[] model, float pos[3], float ang[3], float scale ) //<< ok
{
	int entity = CreateEntityByName( prop_type );
	if( entity != -1 )
	{
		DispatchKeyValue( entity, "model", model );
		SetEntPropFloat( entity, Prop_Send,"m_flModelScale", scale );
		DispatchKeyValueFloat( entity, "fademindist", 10000.0 );
		DispatchKeyValueFloat( entity, "fademaxdist", 10000.0 );
		DispatchKeyValueFloat( entity, "fadescale", 0.0 );
		DispatchSpawn( entity );
		TeleportEntity( entity, pos, ang, NULL_VECTOR );
		SetEntProp( entity, Prop_Send, "m_CollisionGroup", 0 ); 
		return entity;
	}
	return -1;
}

stock int CreateExaust( int parent, float pos[3], float ang[3], int tail_color[3] )
{ 
	int  exaust = CreateEntityByName( "env_steam" );
	if ( exaust != -1 )
	{
		char colorbuff[16];
		Format( colorbuff, sizeof( colorbuff ), "%d %d %d", tail_color[0], tail_color[1], tail_color[2] );
		
		char exname[16];
		Format( exname, sizeof( exname ), "exaust%d", parent );
		DispatchKeyValue( parent, "targetname", exname );
		DispatchKeyValue( exaust, "SpawnFlags", "1" );
		DispatchKeyValue( exaust, "Type", "0" );
		DispatchKeyValue( exaust, "Spreadspeed", "10" );
		DispatchKeyValue( exaust, "Speed", "350" );		
		DispatchKeyValue( exaust, "Startsize", "5" );
		DispatchKeyValue( exaust, "EndSize", "30" );
		DispatchKeyValue( exaust, "Rate", "555" );
		DispatchKeyValue( exaust, "JetLength", "50" );		
		DispatchKeyValue( exaust, "rendercolor", colorbuff );
		DispatchKeyValue( exaust, "InitialState", "1" );

 
		DispatchKeyValue( exaust, "RenderAmt", "180" );
		DispatchSpawn( exaust );
		SetVariantString( exname );
		AcceptEntityInput( exaust, "SetParent", exaust, exaust, 0 );
		TeleportEntity( exaust, pos, ang, NULL_VECTOR );
		AcceptEntityInput( exaust, "TurnOn" );
		return exaust;
	}
	return -1;
}

stock int CreateEntParent( const char[] model, float pos[3], float ang[3], float scale )
{
	// this part critical. change somthing might lead SDKHook_StartTouchPost to crush
	int parent	= CreateEntityByName( "prop_dynamic_override" );
	if ( parent != -1 )
	{
		DispatchKeyValueVector( parent, "origin", pos );
		DispatchKeyValueVector( parent, "Angles", ang );
		DispatchKeyValue( parent, "model", model );
		SetEntPropFloat( parent, Prop_Send,"m_flModelScale", scale );
		SetEntProp( parent, Prop_Send, "m_usSolidFlags", 12 );
		SetEntProp( parent, Prop_Data, "m_nSolidType", 6 );
		SetEntProp( parent, Prop_Send, "m_CollisionGroup", 1 );
		DispatchSpawn( parent );
		return parent;
	}
	return -1;
}

stock int CreatEntChild( int parent, const char[] model, float pos_world[3], float pos_parent[3], float ang[3], float scale )
{
	int child = CreateEntityByName( "prop_dynamic_override" );
	if ( child != -1 )
	{
		DispatchKeyValueVector( child, "origin", pos_world );
		
		char namE[20];
		Format( namE, sizeof( namE ), "luffy%d", parent );
		DispatchKeyValue( parent, "targetname", namE );
		DispatchKeyValue( child, "parentname", namE );  
		//DispatchKeyValueVector( child, "origin", pos_parent );
		//DispatchKeyValueVector( child, "Angles", ang );
		SetVariantString( namE );
		AcceptEntityInput( child, "SetParent", child, child, 0 );
		DispatchKeyValue( child, "model", model );
		SetEntPropFloat( child, Prop_Send, "m_flModelScale", scale );
		// SetEntityModel( entity, modelSeq );
		DispatchSpawn( child );
		TeleportEntity( child, pos_parent, ang, NULL_VECTOR );
		return child;
	}
	return -1;
	

}

stock void SetOwner( int entity, int owner ) //<< ok
{
	SetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity", owner );
}

stock int GetOwner( int entity ) //<< ok
{
	return GetEntPropEnt( entity, Prop_Data, "m_hOwnerEntity" );
}

stock void RemoveEntity_Kill( int entity ) //<< ok
{
	if( entity > 0 && IsValidEntity( entity ))
	{
		AcceptEntityInput( entity, "Kill" );
	}
}

stock void RemoveEntity_KillHierarchy( int entity ) //<< ok
{
	if( entity > 0 && IsValidEntity( entity ))
	{
		AcceptEntityInput( entity, "KillHierarchy" );
	}
}

stock void RemoveEntity_ClearParent( int entity )
{
	if( entity > 0 && IsValidEntity( entity ))
	{
		AcceptEntityInput( entity, "ClearParent" );
		RemoveEntity_KillHierarchy( entity );
	}
}

stock void GetEntOrigin( int entity, float pos_output[3], float mod_array_3rd )
{
	float pos[3];
	GetEntPropVector( entity, Prop_Send, "m_vecOrigin", pos );
	pos[2] += mod_array_3rd;
	CopyArray3DF( pos, pos_output );
}

stock void GetEntAngle( int entity, float ang_output[3], float mod_array_val, int axis )
{
	float ang[3];
	GetEntPropVector( entity, Prop_Data, "m_angRotation", ang );
	ang[axis] += mod_array_val;
	CopyArray3DF( ang, ang_output );
}

stock int GetEntityParent( int entity )
{
	// get entity parent index
	return ( GetEntPropEnt( entity, Prop_Data, "m_hMoveParent" ));
}

stock int GetEntityChild( int entity )
{
	// get entity child index
	return ( GetEntPropEnt( entity, Prop_Data, "m_hMoveChild" ));
}

stock void SetRenderColour( int entity, int rgb[3], int alpha )
{
	SetEntityRenderMode( entity, RENDER_TRANSCOLOR );
	SetEntityRenderColor( entity, rgb[0], rgb[1], rgb[2], alpha );
}

stock void BoundAngleValue( float ang_input[3], float ang_output[3], float bound_value, int axis )
{
	if( ang_input[axis] > bound_value )
	{
		ang_input[axis] = bound_value - ang_input[axis];
	}
	if( ang_input[axis] < 0.0 )
	{
		ang_input[axis] *= -1;
	}
	ang_output[0] = ang_input[0];
	ang_output[1] = ang_input[1];
	ang_output[2] = ang_input[2];
}

stock void CopyColor( int array_source[3], int array_output[3] ) //<< ok
{
	array_output[0] = array_source[0];
	array_output[1] = array_source[1];
	array_output[2] = array_source[2];
}

stock void CopyColor_SetAlpha( int array_source[3], int array_output[4], int alpha ) //<< ok
{
	array_output[0] = array_source[0];
	array_output[1] = array_source[1];
	array_output[2] = array_source[2];
	array_output[3] = alpha;
}

stock void SetArray3DF( float array[3], float val_0, float val_1, float val_2 )
{
	array[0] = val_0;
	array[1] = val_1;
	array[2] = val_2;
}

stock void CopyArray3DF( float array_in[3], float array_out[3] )
{
	array_out[0] = array_in[0];
	array_out[1] = array_in[1];
	array_out[2] = array_in[2];
}

stock bool IsValidInfected( int client )
{
	return ( client > 0 && client <= MaxClients && IsClientConnected( client ) && IsClientInGame( client ) && GetClientTeam( client ) == 3 );
}

stock bool IsValidSurvivor( int client )
{
	return ( client > 0 && client <= MaxClients && IsClientConnected( client ) && IsClientInGame( client ) && GetClientTeam( client ) == 2 );
}

stock int GetClientIndex( int serial, bool toindex )
{
	if( toindex )								//toindex true convert serial to index 
	{
		return GetClientOfUserId( serial );
	}
	else										//toindex false convert index to serial
	{
		return GetClientUserId( serial );
	}
}

stock int GetEntIndex_IsValid( int entref )
{
	// convert entity ref to index and check if valid
	int index = EntRefToEntIndex( entref );
	if( index > 0 && IsValidEntity( index ))
	{
		return index;
	}
	return -1;
}

stock int GetZclass( int client )
{
	return ( GetEntProp( client, Prop_Send, "m_zombieClass" ));
}

stock int GetPlayerHealth( int client )
{
	return (GetEntProp( client, Prop_Data, "m_iHealth" ));
}

stock void SetPlayerHealth( int client, int amount )
{
	SetEntProp( client, Prop_Data, "m_iHealth", amount );
}

stock float GetPlayerHealthBuffer( int client )
{
	return (GetEntPropFloat( client, Prop_Send, "m_healthBuffer" ));
}

stock void SetPlayerHealthBuffer( int client, float amount )
{
	SetEntPropFloat( client, Prop_Send, "m_healthBuffer", amount );
}

stock bool IsPlayerIncap( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isIncapacitated" ) == 1 )
	{
		return true;
	}
	return false;
}

stock void ResetPlayerIncap( int client )
{
	SetEntProp( client, Prop_Send, "m_isIncapacitated", 0 );
}

stock bool IsPlayerLedge( int client )
{
	if ( GetEntProp( client, Prop_Send, "m_isHangingFromLedge" ) == 1 )
	{
		return true;
	}
	return false;
}

stock void ResetPlayerLedge( int client )
{
	SetEntProp( client, Prop_Send, "m_isHangingFromLedge", 0 );
}

stock void ResetPlayerLifeCount( int client )
{
	SetEntProp( client, Prop_Send, "m_currentReviveCount", 0 );
	SetEntProp( client, Prop_Send, "m_bIsOnThirdStrike", 0 );
}

stock int CreatEntModelSpin( const char[] model, int color[3], float pos[3], float ang[3] ) //<< not all model have spin animation
{
	int  entity = CreateEntityByName( PROPTYPE_DYNAMIC );
	if( entity != -1 )
	{
		DispatchKeyValue( entity, "model", model );
		DispatchKeyValueVector( entity, "origin", pos );
		DispatchKeyValueVector( entity, "Angles", ang );
		SetEntProp( entity, Prop_Send, "m_CollisionGroup", 1 ); 
		DispatchSpawn( entity );
		SetVariantString( "spin" );
		AcceptEntityInput( entity, "SetAnimation", -1, -1, 0 );
		
		//int color[4] = { 255, 255, 255, 255 };
    		//int color[4];
		//SetRenderColour(entity, color, 255);
	}
	return entity;
}

stock int CreateWeaponEntity( const char[] ent_name, float pos[3], float ang[3] )
{
	int item = CreateEntityByName( ent_name );
	if( item != -1 )
	{
		DispatchKeyValueVector( item, "Origin", pos );
		DispatchKeyValueVector( item, "Angles", ang );
		DispatchSpawn( item );
	}
	return item;
}

stock void SetupShieldDorm( int client, int color_sprite[3], int radius, int sprite, int alpha )	//<< ok
{
	float pos[3];
	GetEntOrigin( client, pos, 40.0 );
	
	int color[4];
	CopyColor_SetAlpha( color_sprite, color, alpha );
	
	TE_SetupBloodSprite( pos, NULL_VECTOR, color, radius, sprite, sprite );
	TE_SendToAll();
}

stock bool TraceRayGetEndpoint( float trace_pos_start[3], float trace_ang_start[3], any data, float trace_pos_output[3] )
{
	bool traced = false;
	Handle trace = TR_TraceRayFilterEx( trace_pos_start, trace_ang_start, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, data );
	if( TR_DidHit( trace ))
	{ 
		// we just check if there is endpoint. we dont do any code inside trace function incase the code error, the Handle leaked.
		TR_GetEndPosition( trace_pos_output, trace );
		traced = true;
	}
	CloseHandle( trace );
	return traced;
}

stock bool TraceRayBetweenPoints( int client, float trace_pos_start[3], float trace_pos_target[3] )
{
	// this wall check never tested but it should work for 1 way check. the idea as follow:
	// the problem is we are dealing with missile explosive radius, flying object and bunch more small size object
	// such as gascan, genome/toy, a stall column ect. Dosent make any sense for a toothpick stick that standing in between stopping a nuclear blast. << you get the idea.
	// so dont bother ask why the shield and missile damage goes thru imortal object.
	// sometimes i wish this is as easy as throwing 1 and/or 100 bullets projectile from New York to Tokyo and get a headshoot because its rather easier.
	float ang_buff[3];
	MakeVectorFromPoints( trace_pos_start, trace_pos_target, ang_buff );			// Get vector from our start position to the exact target position
	NormalizeVector( ang_buff, ang_buff );											// Always normalize a vector.
	GetVectorAngles( ang_buff, ang_buff );											// Get the vector angle. The angle where we are pointing at.
	
	float trace_endpoint[3];
	if( TraceRayGetEndpoint( trace_pos_start, ang_buff, client, trace_endpoint ))	// Now we have the angle, trace ray it from start pos towards endpoint direction,
	{																				// it return single point/position anyting it hits along the path.
		if( GetVectorDistance( trace_pos_target, trace_endpoint ) <= 10.0 )			// Get the distance between point we trace ray hit earlier and our actual target position.
		{																			// We allow 10 units of error tolerance. depend what value that make any human sense.
			// return false, there is no wall or object on the path.
			return false;
		}
	}
	return true; // return true, there is an Adrenaline Syrange or other object on the path..
}

stock int TraceRayGetEntity( float trace_pos_start[3], float trace_ang_start[3], any data )
{
	int entity = -1;
	Handle trace = TR_TraceRayFilterEx( trace_pos_start, trace_ang_start, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers, data );
	if( TR_DidHit( trace ))
	{ 
		entity = TR_GetEntityIndex( trace );
	}
	CloseHandle( trace );
	return entity;
}

stock bool TraceEntityFilterPlayers( int entity, int contentsMask, any data ) //<< ok
{
	return ( entity > MaxClients && entity != data );
}

stock void FreezePlayerButton( int client, bool set_freeze )
{
	int buttons = GetEntityFlags( client );
	if( set_freeze )
	{
		SetEntityFlags( client, ( buttons |= FL_FROZEN ));
	}
	else
	{
		if( buttons & FL_FROZEN )
		{
			SetEntityFlags( client, ( buttons &= ~FL_FROZEN ));
		}
	}
}

/*
CreateTimer( 0.1, Timer_Test, userid, TIMER_REPEAT );
public Action Timer_Test( Handle timer, any userid )
{
	int client = GetClientOfUserId( userid );
	if ( IsValidSurvivor( client ) && g_bIsRoundStart )
	{
		PCMasterRace_Render_ARGB( client, SHIELD_DORM_ALPHA );
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
*/

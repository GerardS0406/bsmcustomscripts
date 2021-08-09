#include maps/mp/zombies/_zm_zonemgr;
#include maps/mp/gametypes_zm/_zm_gametype;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;

init() //checked matches cerberus output
{
	flag_init( "zones_initialized" );
	level.zones = [];
	level.zone_flags = [];
	level.zone_scanning_active = 0;
	if ( !isDefined( level.create_spawner_list_func ) )
	{
		level.create_spawner_list_func = ::create_spawner_list;
	}
}

zone_is_enabled( zone_name ) //checked matches cerberus output
{
	if ( !isDefined( level.zones ) || !isDefined( level.zones[ zone_name ] ) || !level.zones[ zone_name ].is_enabled )
	{
		return 0;
	}
	return 1;
}

get_player_zone() //checked changed to match cerberus output
{
	player_zone = undefined;
	keys = getarraykeys( level.zones );
	for ( i = 0; i < keys.size; i++ )
	{
		if ( self entity_in_zone( keys[ i ] ) )
		{
			player_zone = keys[ i ];
			break;
		}
	}
	return player_zone;
}

get_zone_from_position( v_pos, ignore_enabled_check ) //checked changed to match cerberus output
{
	zone = undefined;
	scr_org = spawn( "script_origin", v_pos );
	keys = getarraykeys( level.zones );
	for ( i = 0; i < keys.size; i++ )
	{
		if ( scr_org entity_in_zone( keys[ i ], ignore_enabled_check ) )
		{
			zone = keys[ i ];
			break;
		}
	}
	scr_org delete();
	return zone;
}

get_zone_magic_boxes( zone_name ) //checked matches cerberus output
{
	if ( isDefined( zone_name ) && !zone_is_enabled( zone_name ) )
	{
		return undefined;
	}
	zone = level.zones[ zone_name ];
	return zone.magic_boxes;
}

get_zone_zbarriers( zone_name ) //checked matches cerberus output
{
	if ( isDefined( zone_name ) && !zone_is_enabled( zone_name ) )
	{
		return undefined;
	}
	zone = level.zones[ zone_name ];
	return zone.zbarriers;
}

get_players_in_zone( zone_name, return_players ) //checked changed to match cerberus output
{
	if(!zone_is_enabled(zone_name))
	{
		return 0;
	}
	zone = level.zones[zone_name];
	num_in_zone = 0;
	players_in_zone = [];
	players = get_players();
	for ( i = 0; i < zone.volumes.size; i++ )
	{
		for ( j = 0; j < players.size; j++ )
		{
			if ( players[ j ] istouching( zone.volumes[ i ] ) )
			{
				num_in_zone++;
				players_in_zone[ players_in_zone.size ] = players[ j ];
			}
		}
	}
	if ( isdefined( return_players ) )
	{
		return players_in_zone;
	}
	return num_in_zone;
}

player_in_zone( zone_name ) //checked changed to match cerberus output
{
	if ( !zone_is_enabled( zone_name ) )
	{
		return 0;
	}
	zone = level.zones[ zone_name ];
	for ( i = 0; i < zone.volumes.size; i++ )
	{
		players = get_players();
		for ( j = 0; j < players.size; j++ )
		{
			if ( players[ j ] istouching( zone.volumes[ i ]) && !players[ j ] .sessionstate == "spectator" )
			{
				return 1;
			}
		}
	}
	return 0;
}

entity_in_zone( zone_name, ignore_enabled_check ) //checked changed to match cerberus output
{
	if ( !zone_is_enabled( zone_name ) && isdefined( ignore_enabled_check ) && !ignore_enabled_check )
	{
		return 0;
	}
	zone = level.zones[zone_name];
	for ( i = 0; i < zone.volumes.size; i++ )
	{
		if ( self istouching( zone.volumes[ i ] ) )
		{
			return 1;
		}
	}
	return 0;
}

deactivate_initial_barrier_goals() //checked changed to match cerberus output
{
	special_goals = getstructarray( "exterior_goal", "targetname" );
	for ( i = 0; i < special_goals.size; i++ )
	{
		if ( isdefined( special_goals[ i ].script_noteworthy ) )
		{
			special_goals[ i ].is_active = 0;
			special_goals[ i ] trigger_off();
		}
	}
}

zone_init( zone_name ) //checked changed to match cerberus output
{

	if ( isDefined( level.zones[ zone_name ] ) )
	{
		return;
	}

	level.zones[ zone_name ] = spawnstruct();
	zone = level.zones[ zone_name ];
	zone.is_enabled = 0;
	zone.is_occupied = 0;
	zone.is_active = 0;
	zone.adjacent_zones = [];
	zone.is_spawning_allowed = 0;

	spawn_points = maps/mp/gametypes_zm/_zm_gametype::get_player_spawns_for_gametype();
	for( i = 0; i < spawn_points.size; i++ )
	{
		if ( spawn_points[ i ].script_noteworthy == zone_name )
		{
			spawn_points[ i ].locked = 0;
		}
	}
	
	
	zone.volumes = [];
	volumes = getentarray( zone_name, "targetname" );
	i = 0;
	for ( i = 0; i < volumes.size; i++ )
	{
		if ( volumes[ i ].classname == "info_volume" )
		{
			zone.volumes[ zone.volumes.size ] = volumes[ i ];
		}
	}
	if ( isdefined( zone.volumes[ 0 ].target ) )
	{
		spots = getstructarray( zone.volumes[ 0 ].target, "targetname" );
		zone.spawn_locations = [];
		zone.dog_locations = [];
		zone.screecher_locations = [];
		zone.avogadro_locations = [];
		zone.inert_locations = [];
		zone.quad_locations = [];
		zone.leaper_locations = [];
		zone.brutus_locations = [];
		zone.mechz_locations = [];
		zone.astro_locations = [];
		zone.napalm_locations = [];
		zone.zbarriers = [];
		zone.magic_boxes = [];
		barricades = getstructarray( "exterior_goal", "targetname" );
		box_locs = getstructarray( "treasure_chest_use", "targetname" );
		for (i = 0; i < spots.size; i++)
		{
			spots[ i ].zone_name = zone_name;
			if ( isDefined( spots[ i ].is_blocked ) && !spots[ i ].is_blocked || !isDefined( spots[ i ].is_blocked ) ) //spots[ i ].isblocked is not defined
			{
				spots[ i ].is_enabled = 1;
			}
			else
			{
				spots[ i ].is_enabled = 0;
			}
			tokens = strtok( spots[ i ].script_noteworthy, " " );
			foreach ( token in tokens )
			{
				if ( token == "dog_location" )
				{
					zone.dog_locations[ zone.dog_locations.size ] = spots[ i ];
				}
				else if ( token == "screecher_location" )
				{
					zone.screecher_locations[ zone.screecher_locations.size ] = spots[ i ];
				}
				else if ( token == "avogadro_location" )
				{
					zone.avogadro_locations[ zone.avogadro_locations.size ] = spots[ i] ;
				}
				else if ( token == "inert_location" )
				{
					zone.inert_locations[ zone.inert_locations.size ] = spots[ i ];
				}
				else if ( token == "quad_location" )
				{
					zone.quad_locations[ zone.quad_locations.size ] = spots[ i ];
				}
				else if ( token == "leaper_location" )
				{
					zone.leaper_locations[ zone.leaper_locations.size ] = spots[ i ];
				}
				else if ( token == "brutus_location" )
				{
					zone.brutus_locations[ zone.brutus_locations.size ] = spots[ i ];
				}
				else if ( token == "mechz_location" )
				{
					zone.mechz_locations[ zone.mechz_locations.size ] = spots[ i ];
				}
				else if ( token == "astro_location" )
				{
					zone.astro_locations[ zone.astro_locations.size ] = spots[ i ];
				}
				else if ( token == "napalm_location" )
				{
					zone.napalm_locations[ zone.napalm_locations.size ] = spots[ i ];
				}
				else
				{
					zone.spawn_locations[ zone.spawn_locations.size ] = spots[ i ];
				}
			}
			if ( isdefined( spots[ i ].script_string ) )
			{
				barricade_id = spots[ i ].script_string;
				for ( k = 0; k < barricades.size; k++ )
				{
					if ( isdefined( barricades[ k ].script_string ) && barricades[ k ].script_string == barricade_id )
					{
						nodes = getnodearray( barricades[ k ].target, "targetname" );
						for ( j = 0; j < nodes.size; j++ )
						{
							if ( isdefined( nodes[ j ].type ) && nodes[ j ].type == "Begin" )
							{
								spots[ i ].target = nodes[ j ].targetname;
							}
						}
					}
				}
			}
		}
		for ( i = 0; i < barricades.size; i++ )
		{
			targets = getentarray( barricades[ i ].target, "targetname" );
			for ( j = 0; j < targets.size; j++ )
			{
				if ( targets[ j ] iszbarrier() && isdefined( targets[ j ].script_string ) && targets[ j ].script_string == zone_name )
				{
					zone.zbarriers[ zone.zbarriers.size ] = targets[ j ];
				}
			}
		}
		for ( i = 0; i < box_locs.size; i++ )
		{
			chest_ent = getent( box_locs[ i ].script_noteworthy + "_zbarrier", "script_noteworthy" );
			if ( chest_ent entity_in_zone( zone_name, 1 ) )
			{
				zone.magic_boxes[zone.magic_boxes.size] = box_locs[ i ];
			}
		}
	}
}

//unused code
/*
reinit_zone_spawners() //checked changed to match cerberus output
{
	zkeys = getarraykeys( level.zones );
	for( i = 0; i < level.zones.size; i++ )
	{
		zone = level.zones[ zkeys[ i ] ];
		if ( isdefined( zone.volumes[ 0 ].target ) )
		{
			spots = getstructarray( zone.volumes[ 0 ].target, "targetname" );
			zone.spawn_locations = [];
			zone.dog_locations = [];
			zone.screecher_locations = [];
			zone.avogadro_locations = [];
			zone.quad_locations = [];
			zone.leaper_locations = [];
			zone.brutus_locations = [];
			zone.mechz_locations = [];
			zone.astro_locations = [];
			zone.napalm_locations = [];
			for ( j = 0; j < spots.size; j++ )
			{
				spots[ j ].zone_name = zkeys[ j ];
				if ( isdefined( spots[ j ].is_blocked ) && !spots[ j ].is_blocked )
				{
					spots[ j ].is_enabled = 1;
				}
				else
				{
					spots[ j ].is_enabled = 0;
				}
				tokens = strtok( spots[ j ].script_noteworthy, " " );
				foreach ( token in tokens )
				{
					if ( token == "dog_location" )
					{
						zone.dog_locations[ zone.dog_locations.size ] = spots[ j ];
					}
					else if ( token == "screecher_location" )
					{
						zone.screecher_locations[ zone.screecher_locations.size ] = spots[ j ];
					}
					else if ( token == "avogadro_location" )
					{
						zone.avogadro_locations[ zone.avogadro_locations.size ] = spots[ j ];
					}
					else if ( token == "quad_location" )
					{
						zone.quad_locations[ zone.quad_locations.size ] = spots[ j ];
					}
					else if ( token == "leaper_location" )
					{
						zone.leaper_locations[ zone.leaper_locations.size ] = spots[ j ];
					}
					else if ( token == "brutus_location" )
					{
						zone.brutus_locations[ zone.brutus_locations.size ] = spots[ j ];
					}
					else if ( token == "mechz_location" )
					{
						zone.mechz_locations[ zone.mechz_locations.size ] = spots[ j ];
					}
					else if ( token == "astro_location" )
					{
						zone.astro_locations[ zone.astro_locations.size ] = spots[ j ];
					}
					else if ( token == "napalm_location" )
					{
						zone.napalm_locations[ zone.napalm_locations.size ] = spots[ j ];
					}
					else
					{
						zone.spawn_locations[ zone.spawn_locations.size ] = spots[ j ];
					}
				}
			}
		}
	}
}
*/

enable_zone( zone_name ) //checked changed to match cerberus output
{
	if ( level.zones[ zone_name ].is_enabled )
	{
		return; 
	}
	level.zones[ zone_name ].is_enabled = 1;
	level.zones[zone_name].is_spawning_allowed = 1;
	level notify( zone_name );
	spawn_points = maps/mp/gametypes_zm/_zm_gametype::get_player_spawns_for_gametype();
	for( i = 0; i < spawn_points.size; i++ )
	{
		if ( spawn_points[ i ].script_noteworthy == zone_name )
		{
			spawn_points[ i ].locked = 0;
		}
	}
	entry_points = getstructarray( zone_name + "_barriers", "script_noteworthy" );
	for( i = 0; i < entry_points.size; i++ )
	{
		entry_points[ i ].is_active = 1;
		entry_points[ i ] trigger_on();
	}
}

make_zone_adjacent( main_zone_name, adj_zone_name, flag_name ) //checked matches cerberus output
{
	main_zone = level.zones[ main_zone_name ];
	if ( !isDefined( main_zone.adjacent_zones[ adj_zone_name ] ) )
	{
		main_zone.adjacent_zones[ adj_zone_name ] = spawnstruct();
		adj_zone = main_zone.adjacent_zones[ adj_zone_name ];
		adj_zone.is_connected = 0;
		adj_zone.flags_do_or_check = 0;
		if ( isarray( flag_name ) )
		{
			adj_zone.flags = flag_name;
		}
		else
		{
			adj_zone.flags[ 0 ] = flag_name;
		}
	}
	else
	{
		adj_zone = main_zone.adjacent_zones[ adj_zone_name ];
		size = adj_zone.flags.size;
		adj_zone.flags_do_or_check = 1;
		adj_zone.flags[ size ] = flag_name;
	}
}

add_zone_flags( wait_flag, add_flags ) //checked changed to match cerberus output
{
	if ( !isarray( add_flags ) )
	{
		temp = add_flags;
		add_flags = [];
		add_flags[ 0 ] = temp;
	}
	keys = getarraykeys( level.zone_flags );
	i = 0;
	for ( i = 0; i < keys.size; i++ )
	{
		if(keys[ i ] == wait_flag)
		{
			level.zone_flags[ keys[ i ] ] = arraycombine( level.zone_flags[ keys[ i ] ], add_flags, 1, 0 );
			return;
		}
	}
	level.zone_flags[ wait_flag ] = add_flags;
}

add_adjacent_zone( zone_name_a, zone_name_b, flag_name, one_way ) //checked matches cerberus output
{
	if ( !isDefined( one_way ) )
	{
		one_way = 0;
	}
	if ( !isDefined( level.flag[ flag_name ] ) )
	{
		flag_init( flag_name );
	}
	zone_init( zone_name_a );
	zone_init( zone_name_b );
	make_zone_adjacent( zone_name_a, zone_name_b, flag_name );
	if ( !one_way )
	{
		make_zone_adjacent( zone_name_b, zone_name_a, flag_name );
	}
}

setup_zone_flag_waits() //checked changed to match cerberus output
{
	flags = [];
	zkeys = getarraykeys( level.zones );
	for ( z = 0; z < level.zones.size; z++ )
	{
		zone = level.zones[ zkeys[ z ] ];
		azkeys = getarraykeys( zone.adjacent_zones );
		for ( az = 0; az < zone.adjacent_zones.size; az++ )
		{
			azone = zone.adjacent_zones[ azkeys[ az ] ];
			for ( f = 0; f < azone.flags.size; f++ )
			{
				flags = add_to_array( flags, azone.flags[ f ], 0);
			}
		}
	}
	for ( i = 0; i < flags.size; i++ )
	{
		level thread zone_flag_wait( flags[ i ] );
	}
}

zone_flag_wait( flag_name )
{
	if ( !isdefined( level.flag[ flag_name ] ) )
	{
		flag_init( flag_name );
	}
	flag_wait( flag_name );
	flags_set = 0;
	for ( z = 0; z < level.zones.size; z++ )
	{
		zkeys = getarraykeys( level.zones );
		zone = level.zones[ zkeys[ z ] ];
		for ( az = 0; az < zone.adjacent_zones.size; az++ )
		{
			azkeys = getarraykeys( zone.adjacent_zones );
			azone = zone.adjacent_zones[ azkeys[ az ] ];
			if ( !azone.is_connected )
			{
				if ( azone.flags_do_or_check )
				{
					flags_set = 0;
					for ( f = 0; f < azone.flags.size; f++ )
					{
						if ( flag( azone.flags[ f ] ) )
						{
							flags_set = 1;
							break;
						}
					}
				}
				else
				{
					flags_set = 1;
					for ( f = 0; f < azone.flags.size; f++ )
					{
						if ( !flag(azone.flags[ f ] ) )
						{
							flags_set = 0;
						}
					}
				}
				if ( flags_set )
				{
					enable_zone( zkeys[ z ] ); //essential priority over manage_zones //was disabled
					azone.is_connected = 1;
					if ( !level.zones[ azkeys[ az ] ].is_enabled )
					{
						enable_zone( azkeys[ az ] ); //essential priority over manage_zones //was disabled
					}
					if ( flag( "door_can_close" ) )
					{
						azone thread door_close_disconnect( flag_name );
					}
				}
			}
		}
	}
	keys = getarraykeys( level.zone_flags );
	for ( i = 0; i < keys.size; i++ )
	{
		if ( keys[ i ] == flag_name )
		{
			check_flag = level.zone_flags[ keys[ i ] ];
			for ( k = 0; k < check_flag.size; k++ )
			{
				flag_set( check_flag[ k ] );
			}
			//break;
		}
	}
}

door_close_disconnect( flag_name ) //checked matches cerberus output
{
	while ( flag( flag_name ) )
	{
		wait 1;
	}
	self.is_connected = 0;
	level thread zone_flag_wait( flag_name );
}

connect_zones( zone_name_a, zone_name_b, one_way ) //checked matches cerberus output
{
	if ( !isDefined( one_way ) )
	{
		one_way = 0;
	}
	zone_init( zone_name_a );
	zone_init( zone_name_b );
	enable_zone( zone_name_a );
	enable_zone( zone_name_b );
	if ( !isDefined( level.zones[ zone_name_a ].adjacent_zones[ zone_name_b ] ) )
	{
		level.zones[ zone_name_a ].adjacent_zones[ zone_name_b ] = spawnstruct();
		level.zones[ zone_name_a ].adjacent_zones[ zone_name_b ].is_connected = 1;
	}
	if ( !one_way )
	{
		if ( !isDefined( level.zones[ zone_name_b ].adjacent_zones[ zone_name_a ] ) )
		{
			level.zones[ zone_name_b ].adjacent_zones[ zone_name_a ] = spawnstruct();
			level.zones[ zone_name_b ].adjacent_zones[ zone_name_a ].is_connected = 1;
		}
	}
}

manage_zones( initial_zone ) //checked changed to match cerberus output
{

	deactivate_initial_barrier_goals();
	zone_choke = 0;
	spawn_points = maps/mp/gametypes_zm/_zm_gametype::get_player_spawns_for_gametype();
	for ( i = 0; i < spawn_points.size; i++ )
	{
		spawn_points[ i ].locked = 1;
	}
	if ( isDefined( level.zone_manager_init_func ) )
	{
		[[ level.zone_manager_init_func ]]();
	}
	if ( isDefined( level.customMap ) && level.customMap == "redroom" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_orange_level3b";
	}
	if ( isDefined( level.customMap ) && level.customMap == "rooftop" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_roof";
		initial_zone[ 1 ] = "zone_roof_infirmary";
		initial_zone[ 2 ] = "zone_infirmary";
	}
	else if ( isDefined( level.customMap ) && level.customMap == "docks" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_dock";
		initial_zone[ 1 ] = "zone_dock_puzzle";
		initial_zone[ 2 ] = "zone_dock_gondola";	
	}
	else if ( isDefined( level.customMap ) && level.customMap == "excavation" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_nml_2a";
		initial_zone[ 1 ] = "zone_nml_2";
		initial_zone[ 2 ] = "zone_bunker_tank_e";
		initial_zone[ 3 ] = "zone_bunker_tank_e1";
		initial_zone[ 4 ] = "zone_bunker_tank_e2";
		initial_zone[ 5 ] = "zone_bunker_tank_f";
		initial_zone[ 6 ] = "zone_nml_1";
		initial_zone[ 7 ] = "zone_nml_4";
		initial_zone[ 8 ] = "zone_nml_0";
		initial_zone[ 9 ] = "zone_nml_5";
		initial_zone[ 10 ] = "zone_nml_celllar";
		initial_zone[ 11 ] = "zone_bolt_stairs";
		initial_zone[ 12 ] = "zone_nml_3";
		initial_zone[ 13 ] = "zone_nml_2b";
		initial_zone[ 14 ] = "zone_nml_6";
		initial_zone[ 15 ] = "zone_nml_8";
		initial_zone[ 16 ] = "zone_nml_10a";
		initial_zone[ 17 ] = "zone_nml_10";
		initial_zone[ 18 ] = "zone_nml_7";
		initial_zone[ 19 ] = "zone_bunker_tank_a";
		initial_zone[ 20 ] = "zone_bunker_tank_a1";
		initial_zone[ 21 ] = "zone_bunker_tank_a2";
		initial_zone[ 22 ] = "zone_bunker_tank_b";
		initial_zone[ 23 ] = "zone_nml_9";
		initial_zone[ 24 ] = "zone_air_stairs";
		initial_zone[ 25 ] = "zone_nml_11";
		initial_zone[ 26 ] = "zone_nml_12";
		initial_zone[ 27 ] = "zone_nml_16";
		initial_zone[ 28 ] = "zone_nml_17";
		initial_zone[ 29 ] = "zone_nml_18";
		initial_zone[ 30 ] = "zone_nml_19";
		initial_zone[ 31 ] = "ug_bottom_zone";
		initial_zone[ 32 ] = "zone_nml_13";
		initial_zone[ 33 ] = "zone_nml_14";
		initial_zone[ 34 ] = "zone_nml_15";
	}
	else if ( isDefined( level.customMap ) && level.customMap == "tank" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_village_0";
		initial_zone[ 1 ] = "zone_village_5";
		initial_zone[ 2 ] = "zone_village_5a";
		initial_zone[ 3 ] = "zone_village_5b";
		initial_zone[ 4 ] = "zone_village_1";
		initial_zone[ 5 ] = "zone_village_4b";
		initial_zone[ 6 ] = "zone_village_4a";
		initial_zone[ 7 ] = "zone_village_4";
	}
	else if ( isDefined( level.customMap ) && level.customMap == "crazyplace" )
	{
		initial_zone = [];
		initial_zone[ 0 ] = "zone_chamber_0";
		initial_zone[ 1 ] = "zone_chamber_1";
		initial_zone[ 2 ] = "zone_chamber_2";
		initial_zone[ 3 ] = "zone_chamber_3";
		initial_zone[ 4 ] = "zone_chamber_4";
		initial_zone[ 5 ] = "zone_chamber_5";
		initial_zone[ 6 ] = "zone_chamber_6";
		initial_zone[ 7 ] = "zone_chamber_7";
		initial_zone[ 8 ] = "zone_chamber_8";
	}
	else if (isdefined(level.customMap) && level.customMap == "maze")
	{
		initial_zone[initial_zone.size] = "zone_maze";
		initial_zone[initial_zone.size] = "zone_mansion_backyard";
		initial_zone[initial_zone.size] = "zone_maze_staircase";
		initial_zone[initial_zone.size] = "zone_start";
		initial_zone[initial_zone.size] = "zone_mansion";
		initial_zone[initial_zone.size] = "zone_mansion_lawn";
	}
	if ( isarray( initial_zone ) )
	{
		for ( i = 0; i < initial_zone.size; i++ )
		{
			zone_init( initial_zone[ i ] );
			enable_zone( initial_zone[ i ] );
		}
	}
	else
	{
		zone_init( initial_zone );
		enable_zone( initial_zone );
	}
	setup_zone_flag_waits();
	zkeys = getarraykeys( level.zones );
	level.zone_keys = zkeys;
	level.newzones = [];
	for ( z = 0; z < zkeys.size; z++ )
	{
		level.newzones[ zkeys[ z ] ] = spawnstruct();
	}
	oldzone = undefined;
	flag_set( "zones_initialized" );
	flag_wait( "begin_spawning" );
	while ( getDvarInt( "noclip" ) == 0 || getDvarInt( "notarget" ) != 0 )
	{	
		for( z = 0; z < zkeys.size; z++ )
		{
			level.newzones[ zkeys[ z ] ].is_active = 0;
			level.newzones[ zkeys[ z ] ].is_occupied = 0;
		}
		a_zone_is_active = 0;
		a_zone_is_spawning_allowed = 0;
		level.zone_scanning_active = 1;
		z = 0;
		while ( z < zkeys.size )
		{
			zone = level.zones[ zkeys[ z ] ];
			newzone = level.newzones[ zkeys[ z ] ];
			if( !zone.is_enabled )
			{
				z++;
				continue;
			}
			if ( isdefined(level.zone_occupied_func ) )
			{
				newzone.is_occupied = [[ level.zone_occupied_func ]]( zkeys[ z ] );
			}
			else
			{
				newzone.is_occupied = player_in_zone( zkeys[ z ] );
			}
			if ( newzone.is_occupied )
			{
				newzone.is_active = 1;
				a_zone_is_active = 1;
				if ( zone.is_spawning_allowed )
				{
					a_zone_is_spawning_allowed = 1;
				}
				if ( !isdefined(oldzone) || oldzone != newzone )
				{
					level notify( "newzoneActive", zkeys[ z ] );
					oldzone = newzone;
				}
				azkeys = getarraykeys( zone.adjacent_zones );
				for ( az = 0; az < zone.adjacent_zones.size; az++ )
				{
					if ( zone.adjacent_zones[ azkeys[ az ] ].is_connected && level.zones[ azkeys[ az ] ].is_enabled )
					{
						level.newzones[ azkeys[ az ] ].is_active = 1;
						if ( level.zones[ azkeys[ az ] ].is_spawning_allowed )
						{
							a_zone_is_spawning_allowed = 1;
						}
					}
				}
			}
			zone_choke++;
			if ( zone_choke >= 3 )
			{
				zone_choke = 0;
				wait 0.05;
			}
			z++;
		}
		level.zone_scanning_active = 0;
		for ( z = 0; z < zkeys.size; z++ )
		{
			level.zones[ zkeys[ z ] ].is_active = level.newzones[ zkeys[ z ] ].is_active;
			level.zones[ zkeys[ z ] ].is_occupied = level.newzones[ zkeys[ z ] ].is_occupied;
		}
		if ( !a_zone_is_active || !a_zone_is_spawning_allowed )
		{
			if ( isarray( initial_zone ) )
			{
				level.zones[ initial_zone[ 0 ] ].is_active = 1;
				level.zones[ initial_zone[ 0 ] ].is_occupied = 1;
				level.zones[ initial_zone[ 0 ] ].is_spawning_allowed = 1;
			}
			else
			{
				level.zones[ initial_zone ].is_active = 1;
				level.zones[ initial_zone ].is_occupied = 1;
				level.zones[ initial_zone ].is_spawning_allowed = 1;
			}
		}
		[[ level.create_spawner_list_func ]]( zkeys );
		level.active_zone_names = maps/mp/zombies/_zm_zonemgr::get_active_zone_names();
		wait 1;
	}
}

debug_show_spawn_locations() //checked dev call deleted
{
}

//unused code
/*
old_manage_zones( initial_zone ) //checked changed to match cerberus output
{

	deactivate_initial_barrier_goals();
	spawn_points = maps/mp/gametypes_zm/_zm_gametype::get_player_spawns_for_gametype();
	for ( i = 0; i < spawn_points.size; i++ )
	{
		spawn_points[i].locked = 1;
	}
	if ( isDefined( level.zone_manager_init_func ) )
	{
		[[ level.zone_manager_init_func ]]();
	}
	if ( isarray( initial_zone ) )
	{
		for ( i = 0; i < initial_zone.size; i++ )
		{
			zone_init(initial_zone[ i ]);
			enable_zone(initial_zone[ i ]);
		}
	}
	else
	{
		zone_init( initial_zone );
		enable_zone( initial_zone );
	}
	setup_zone_flag_waits();
	zkeys = getarraykeys( level.zones );
	level.zone_keys = zkeys;
	flag_set( "zones_initialized" );
	flag_wait( "begin_spawning" );
	while ( getDvarInt( "noclip" ) == 0 || getDvarInt( "notarget" ) != 0 )
	{
		for(z = 0; z < zkeys.size; z++)
		{
			level.zones[ zkeys[ z ] ].is_active = 0;
			level.zones[ zkeys[ z ] ].is_occupied = 0;
		}
		a_zone_is_active = 0;
		a_zone_is_spawning_allowed = 0;
		for ( z = 0; z < zkeys.size; z++ )
		{
			zone = level.zones[ zkeys[ z ] ];
			if ( !zone.is_enabled )
			{
				continue;
			}
			if ( isdefined( level.zone_occupied_func ) )
			{
				zone.is_occupied = [[ level.zone_occupied_func ]]( zkeys[ z ] );
			}
			else
			{
				zone.is_occupied = player_in_zone( zkeys[ z ] );
			}
			if ( zone.is_occupied )
			{
				zone.is_active = 1;
				a_zone_is_active = 1;
				if ( zone.is_spawning_allowed )
				{
					a_zone_is_spawning_allowed = 1;
				}
				azkeys = getarraykeys(zone.adjacent_zones);
				for ( az = 0; az < zone.adjacent_zones.size; az++ )
				{
					if ( zone.adjacent_zones[ azkeys[ az ] ].is_connected && level.zones[ azkeys[ az ] ].is_enabled )
					{
						level.zones[ azkeys[ az ] ].is_active = 1;
						if ( level.zones[ azkeys[ az ] ].is_spawning_allowed )
						{
							a_zone_is_spawning_allowed = 1;
						}
					}
				}
			}
		}
		if ( !a_zone_is_active || !a_zone_is_spawning_allowed )
		{
			if ( isarray( initial_zone ) )
			{
				level.zones[ initial_zone[ 0 ] ].is_active = 1;
				level.zones[ initial_zone[ 0 ] ].is_occupied = 1;
				level.zones[ initial_zone[ 0 ] ].is_spawning_allowed = 1;
			}
			else
			{
				level.zones[ initial_zone ].is_active = 1;
				level.zones[ initial_zone ].is_occupied = 1;
				level.zones[ initial_zone ].is_spawning_allowed = 1;
			}
		}
		[[ level.create_spawner_list_func ]]( zkeys );
		level.active_zone_names = maps/mp/zombies/_zm_zonemgr::get_active_zone_names();
		wait 1;
	}
}
*/
create_spawner_list( zkeys ) //modified function
{
	level.zombie_spawn_locations = [];
	level.inert_locations = [];
	level.enemy_dog_locations = [];
	level.zombie_screecher_locations = [];
	level.zombie_avogadro_locations = [];
	level.quad_locations = [];
	level.zombie_leaper_locations = [];
	level.zombie_astro_locations = [];
	level.zombie_brutus_locations = [];
	level.zombie_mechz_locations = [];
	level.zombie_napalm_locations = [];
	for ( z = 0; z < zkeys.size; z++ )
	{
		zone = level.zones[ zkeys[ z ] ];
		if ( zone.is_enabled && zone.is_active && zone.is_spawning_allowed )
		{
			for ( i = 0; i < zone.spawn_locations.size; i++ )
			{
				if(level.script == "zm_transit" && level.customMap != "vanilla")
				{
					if ( zone.spawn_locations[ i ].origin == ( -11447, -3424, 254.2 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					if ( zone.spawn_locations[ i ].origin == ( -10944, -3846, 221.14 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					if ( zone.spawn_locations[ i ].origin == ( -11093, 393, 192 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					if ( zone.spawn_locations[ i ].origin == ( -11347, -3134, 283.9 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11332.9, -2876.95, 207 );
					}
					if ( zone.spawn_locations[ i ].origin == ( -11182, -4384, 196.7 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11115, -3152, 207 );
					}
					if ( zone.spawn_locations[ i ].origin == ( -11251, -4397, 200.02 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11107.8, -1301, 184 );
					}
					if ( zone.spawn_locations[ i ].origin == ( 8394, -2545, -205.16 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( 10015, 6931, -571.7 ) )
					{
						zone.spawn_locations[ i ].origin = ( 10249.4, 7691.71, -569.875 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( 9339, 6411, -566.9 ) )
					{
						zone.spawn_locations[ i ].origin = ( 9993.29, 7486.83, -582.875 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( 9914, 8408, -576 ) )
					{
						zone.spawn_locations[ i ].origin = ( 9993.29, 7550, -582.875 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( 9429, 5281, -539.6 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( 10015, 6931, -571.7 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( 13019.1, 7382.5, -754 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( -3825, -6576, -52.7 ) )
					{
						zone.spawn_locations[ i ].origin = ( -4061.03, -6754.44, -58.0897 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -3450, -6559, -51.9 ) )
					{
						zone.spawn_locations[ i ].origin = ( -4060.93, -6968.64, -65.3446 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -4165, -6098, -64 ) )
					{
						zone.spawn_locations[ i ].origin = ( -4239.78, -6902.81, -57.0494 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -5058, -5902, -73.4 ) )
					{
						zone.spawn_locations[ i ].origin = ( -4846.77, -6906.38, 54.8145 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -6462, -7159, -64 ) )
					{
						zone.spawn_locations[ i ].origin = ( -6201.18, -7107.83, -59.7182 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -5130, -6512, -35.4 ) )
					{
						zone.spawn_locations[ i ].origin = ( -5396.36, -6801.88, -60.0821 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -6531, -6613, -54.4 ) )
					{
						zone.spawn_locations[ i ].origin = ( -6116.62, -6586.81, -50.8905 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -5373, -6231, -51.9 ) )
					{
						zone.spawn_locations[ i ].origin = ( -4827.92, -7137.19, -62.9082 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -5752, -6230, -53.4 ) )
					{
						zone.spawn_locations[ i ].origin = ( -5572.47, -6426, -39.1894 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -5540, -6508, -42 ) )
					{
						zone.spawn_locations[ i ].origin = ( -5789.51, -6935.81, -57.875 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11093 , 393 , 192 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11431.3, -644.496, 192.125 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -10944, -3846, 221.14 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11351.7, -1988.58, 184.125 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11251, -4397, 200.02 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11431.3, -644.496, 192.125 );
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11334 , -5280, 212.7 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11600.6, -1918.41, 192.125 );
						zone.spawn_locations[ i ].script_noteworthy = "riser_location";
					}
					else if (zone.spawn_locations[ i ].origin == ( -10836, 1195, 209.7 ) )
					{
						zone.spawn_locations[ i ].origin = ( -11241.2, -1118.76, 184.125 );
					}
					/*
					else if ( zone.spawn_locations[ i ].origin == ( -10747, -63, 203.8 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11347, -3134, 283.9 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11447, -3424, 254.2 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( -10761, 155, 236.8 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if ( zone.spawn_locations[ i ].origin == ( -11110, -2921, 195.79 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					*/
					else if ( zone.spawn_locations[ i ].targetname == "zone_trans_diner_spawners")
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					if ( zone.spawn_locations[ i ].is_enabled )
					{
						level.zombie_spawn_locations[ level.zombie_spawn_locations.size ] = zone.spawn_locations[ i ];
					}
				}
				else if (level.script == "zm_prison" && level.customMap != "vanilla")
				{
					if( zone.spawn_locations[ i ].origin == ( -1880.2, 5419.9, -55 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
					else if( zone.spawn_locations[ i ].origin == ( -1852.2, 5307.9, -55 ) )
					{
						zone.spawn_locations[ i ].is_enabled = 0;
					}
				}
				if(zone.spawn_locations[ i ].is_enabled)
				{
					level.zombie_spawn_locations[level.zombie_spawn_locations.size] = zone.spawn_locations[i];
				}
			}
			for(x = 0; x < zone.inert_locations.size; x++)
			{
				if(zone.inert_locations[x].is_enabled)
				{
					level.inert_locations[level.inert_locations.size] = zone.inert_locations[x];
				}
			}
			for(x = 0; x < zone.dog_locations.size; x++)
			{
				if(zone.dog_locations[x].is_enabled)
				{
					level.enemy_dog_locations[level.enemy_dog_locations.size] = zone.dog_locations[x];
				}
			}
			for(x = 0; x < zone.screecher_locations.size; x++)
			{
				if(zone.screecher_locations[x].is_enabled)
				{
					level.zombie_screecher_locations[level.zombie_screecher_locations.size] = zone.screecher_locations[x];
				}
			}
			/*
			for(x = 0; x < zone.avogadro_locations.size; x++)
			{
				if(zone.avogadro_locations[x].is_enabled)
				{
					level.zombie_avogadro_locations[level.zombie_avogadro_locations.size] = zone.avogadro_locations[x];
				}
			}
			*/
			for(x = 0; x < zone.quad_locations.size; x++)
			{
				if(zone.quad_locations[x].is_enabled)
				{
					level.quad_locations[level.quad_locations.size] = zone.quad_locations[x];
				}
			}
			for(x = 0; x < zone.leaper_locations.size; x++)
			{
				if(zone.leaper_locations[x].is_enabled)
				{
					level.zombie_leaper_locations[level.zombie_leaper_locations.size] = zone.leaper_locations[x];
				}
			}
			for(x = 0; x < zone.astro_locations.size; x++)
			{
				if(zone.astro_locations[x].is_enabled)
				{
					level.zombie_astro_locations[level.zombie_astro_locations.size] = zone.astro_locations[x];
				}
			}
			for(x = 0; x < zone.napalm_locations.size; x++)
			{
				if(zone.napalm_locations[x].is_enabled)
				{
					level.zombie_napalm_locations[level.zombie_napalm_locations.size] = zone.napalm_locations[x];
				}
			}
			for(x = 0; x < zone.brutus_locations.size; x++)
			{
				if(zone.brutus_locations[x].is_enabled)
				{
					level.zombie_brutus_locations[level.zombie_brutus_locations.size] = zone.brutus_locations[x];
				}
			}
			for(x = 0; x < zone.mechz_locations.size; x++)
			{
				if(zone.mechz_locations[x].is_enabled)
				{
					level.zombie_mechz_locations[level.zombie_mechz_locations.size] = zone.mechz_locations[x];
				}
			}
		}
	}
}


get_active_zone_names() //checked changed to match cerberus output
{
	ret_list = [];
	if ( !isDefined( level.zone_keys ) )
	{
		return ret_list;
	}
	while ( level.zone_scanning_active )
	{
		wait 0.05;
	}
	for ( i = 0; i < level.zone_keys.size; i++ )
	{
		if ( level.zones[ level.zone_keys[ i ] ].is_active )
		{
			ret_list[ ret_list.size ] = level.zone_keys[ i ];
		}
	}
	return ret_list;
}

//commented out 
/*
_init_debug_zones() //checked changed to match cerberus output
{
	current_y = 30;
	current_x = 20;
	xloc = [];
	xloc[ 0 ] = 50;
	xloc[ 1 ] = 60;
	xloc[ 2 ] = 100;
	xloc[ 3 ] = 130;
	xloc[ 4 ] = 170;
	zkeys = getarraykeys( level.zones );
	for(i = 0; i < zkeys.size; i++)
	{
		zonename = zkeys[i];
		zone = level.zones[zonename];
		zone.debug_hud = [];
		for(j = 0; j < 5; j++)
		{
			zone.debug_hud[j] = newdebughudelem();
			if(!j)
			{
				zone.debug_hud[j].alignx = "right";
			}
			else
			{
				zone.debug_hud[j].alignx = "left";
			}
			zone.debug_hud[j].x = xloc[j];
			zone.debug_hud[j].y = current_y;
		}
		current_y = current_y + 10;
		zone.debug_hud[0] settext(zonename);
	}
}

_destroy_debug_zones() //checked changed to match cerberus output
{
	zkeys = getarraykeys(level.zones);
	for(i = 0; i < zkeys.size; i++)
	{
		zonename = zkeys[i];
		zone = level.zones[zonename];
		for(j = 0; j < 5; j++)
		{
			zone.debug_hud[j] destroy();
			zone.debug_hud[j] = undefined;
		}
	}
}

_debug_zones() //checked changed to match cerberus output
{
	enabled = 0;
	if ( getDvar( "zombiemode_debug_zones" ) == "" )
	{
		setdvar( "zombiemode_debug_zones", "0" );
	}
	while(1)
	{
		wasenabled = enabled;
		enabled = GetDvarInt(hash_10e35bc4);
		if(enabled && !wasenabled)
		{
			_init_debug_zones();
		}
		else if(!enabled && wasenabled)
		{
			_destroy_debug_zones();
		}
		if(enabled)
		{
			zkeys = getarraykeys(level.zones);
			for(i = 0; i < zkeys.size; i++)
			{
				zonename = zkeys[i];
				zone = level.zones[zonename];
				text = zonename;
				zone.debug_hud[0] settext(text);
				if(zone.is_enabled)
				{
					text = text + " Enabled";
					zone.debug_hud[1] settext("Enabled");
				}
				else
				{
					zone.debug_hud[1] settext("");
				}
				if(zone.is_active)
				{
					text = text + " Active";
					zone.debug_hud[2] settext("Active");
				}
				else
				{
					zone.debug_hud[2] settext("");
				}
				if(zone.is_occupied)
				{
					text = text + " Occupied";
					zone.debug_hud[3] settext("Occupied");
				}
				else
				{
					zone.debug_hud[3] settext("");
				}
				if(zone.is_spawning_allowed)
				{
					text = text + " SpawningAllowed";
					zone.debug_hud[4] settext("SpawningAllowed");
				}
				else
				{
					zone.debug_hud[4] settext("");
				}
			}
		}
		wait(0.1);
	}
}
*/

is_player_in_zone( zone_name ) //checked changed to match cerberus output
{
	zone = level.zones[ zone_name ];
	for ( i = 0; i < zone.volumes.size; i++ )
	{
		if ( self istouching( level.zones[ zone_name ].volumes[ i ] ) && self.sessionstate != "spectator")
		{
			return 1;
		}
	}
	return 0;
}
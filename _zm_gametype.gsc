#include maps/mp/zombies/_zm_spawner;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/zombies/_zm_pers_upgrades_functions;
#include maps/mp/zombies/_zm_blockers;
#include maps/mp/gametypes_zm/_spawning;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/gametypes_zm/_hud;
#include maps/mp/zombies/_zm_audio_announcer;
#include maps/mp/zombies/_zm_audio;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/gametypes_zm/_globallogic_ui;
#include maps/mp/gametypes_zm/_hud_message;
#include maps/mp/gametypes_zm/_globallogic_score;
#include maps/mp/gametypes_zm/_globallogic_defaults;
#include maps/mp/gametypes_zm/_gameobjects;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/gametypes_zm/_callbacksetup;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/_utility;

main() //checked matches cerberus output
{
	override_map();
	maps/mp/gametypes_zm/_globallogic::init();
	maps/mp/gametypes_zm/_callbacksetup::setupcallbacks();
	globallogic_setupdefault_zombiecallbacks();
	menu_init(); 
	registerroundlimit( 1, 1 );
	registertimelimit( 0, 0 );
	registerscorelimit( 0, 0 );
	registerroundwinlimit( 0, 0 );
	registernumlives( 1, 1 );
	maps/mp/gametypes_zm/_weapons::registergrenadelauncherduddvar( level.gametype, 10, 0, 1440 );
	maps/mp/gametypes_zm/_weapons::registerthrowngrenadeduddvar( level.gametype, 0, 0, 1440 );
	maps/mp/gametypes_zm/_weapons::registerkillstreakdelay( level.gametype, 0, 0, 1440 );
	maps/mp/gametypes_zm/_globallogic::registerfriendlyfiredelay( level.gametype, 15, 0, 1440 );
	init_spawnpoints_for_custom_survival_maps(); //custom function
	init_barriers_for_custom_maps(); //custom function
	level.takelivesondeath = 1;
	level.teambased = 1;
	level.disableprematchmessages = 1;
	level.disablemomentum = 1;
	level.overrideteamscore = 0;
	level.overrideplayerscore = 0;
	level.displayhalftimetext = 0;
	level.displayroundendtext = 0;
	level.allowannouncer = 0;
	level.endgameonscorelimit = 0;
	level.endgameontimelimit = 0;
	level.resetplayerscoreeveryround = 1;
	level.doprematch = 0;
	level.nopersistence = 1;
	level.scoreroundbased = 0;
	level.forceautoassign = 1;
	level.dontshowendreason = 1;
	level.forceallallies = 0;
	level.allow_teamchange = 0;
	setdvar( "scr_disable_team_selection", 1 );
	makedvarserverinfo( "scr_disable_team_selection", 1 );
	setmatchflag( "hud_zombie", 1 );
	setdvar( "scr_disable_weapondrop", 1 );
	setdvar( "scr_xpscale", 0 );
	level.onstartgametype = ::onstartgametype;
	level.onspawnplayer = ::blank;
	level.onspawnplayerunified = ::onspawnplayerunified; 
	level.onroundendgame = ::onroundendgame;
	level.mayspawn = ::mayspawn;
	set_game_var( "ZM_roundLimit", 1 );
	set_game_var( "ZM_scoreLimit", 1 );
	set_game_var( "_team1_num", 0 );
	set_game_var( "_team2_num", 0 );
	map_name = level.script;
	mode = getDvar( "ui_gametype" );
	if ( !isDefined( mode ) && isDefined( level.default_game_mode ) || mode == "" && isDefined( level.default_game_mode ) )
	{
		mode = level.default_game_mode;
	}
	set_gamemode_var_once( "mode", mode );
	set_game_var_once( "side_selection", 1 );
	location = getDvar( "ui_zm_mapstartlocation" );
	if ( location == "" && isDefined( level.default_start_location ) )
	{
		location = level.default_start_location;
	}
	set_gamemode_var_once( "location", location );
	set_gamemode_var_once( "randomize_mode", getDvarInt( "zm_rand_mode" ) );
	set_gamemode_var_once( "randomize_location", getDvarInt( "zm_rand_loc" ) );
	set_gamemode_var_once( "team_1_score", 0 );
	set_gamemode_var_once( "team_2_score", 0 );
	set_gamemode_var_once( "current_round", 0 );
	set_gamemode_var_once( "rules_read", 0 );
	set_game_var_once( "switchedsides", 0 );
	gametype = getDvar( "ui_gametype" );
	game[ "dialog" ][ "gametype" ] = gametype + "_start";
	game[ "dialog" ][ "gametype_hardcore" ] = gametype + "_start";
	game[ "dialog" ][ "offense_obj" ] = "generic_boost";
	game[ "dialog" ][ "defense_obj" ] = "generic_boost";
	set_gamemode_var( "pre_init_zombie_spawn_func", undefined );
	set_gamemode_var( "post_init_zombie_spawn_func", undefined );
	set_gamemode_var( "match_end_notify", undefined );
	set_gamemode_var( "match_end_func", undefined );
	setscoreboardcolumns( "score", "kills", "downs", "revives", "headshots" );
	onplayerconnect_callback( ::onplayerconnect_check_for_hotjoin );
	thread map_rotation();
}

game_objects_allowed( mode, location ) //checked partially changed to match cerberus output changed at own discretion
{
	allowed[ 0 ] = mode;
	entities = getentarray();
	location = getDvar( "customMap" );
	if ( location == "house" )
	{
		location = "hunters_cabin";
	}
	i = 0;
	while ( i < entities.size )
	{
		if ( isDefined( entities[ i ].script_gameobjectname ) )
		{
			isallowed = maps/mp/gametypes_zm/_gameobjects::entity_is_allowed( entities[ i ], allowed );
			isvalidlocation = maps/mp/gametypes_zm/_gameobjects::location_is_allowed( entities[ i ], location );
			if ( !isallowed || !isvalidlocation && !is_classic() )
			{
				if ( isDefined( entities[ i ].spawnflags ) && entities[ i ].spawnflags == 1 )
				{
					if ( isDefined( entities[ i ].classname ) && entities[ i ].classname != "trigger_multiple" )
					{
						entities[ i ] connectpaths();
					}
				}
				entities[ i ] delete();
				i++;
				continue;
			}
			if ( isDefined( entities[ i ].script_vector ) )
			{
				entities[ i ] moveto( entities[ i ].origin + entities[ i ].script_vector, 0.05 );
				entities[ i ] waittill( "movedone" );
				if ( isDefined( entities[ i ].spawnflags ) && entities[ i ].spawnflags == 1 )
				{
					entities[ i ] disconnectpaths();
				}
				i++;
				continue;
			}
			if ( isDefined( entities[ i ].spawnflags ) && entities[ i ].spawnflags == 1 )
			{
				if ( isDefined( entities[ i ].classname ) && entities[ i ].classname != "trigger_multiple" )
				{
					entities[ i ] connectpaths();
				}
			}
		}
		i++;
	}
}

post_init_gametype() //checked matches cerberus output
{
	if ( isDefined( level.gamemode_map_postinit ) )
	{
		if ( isDefined( level.gamemode_map_postinit[ level.scr_zm_ui_gametype ] ) )
		{
			[[ level.gamemode_map_postinit[ level.scr_zm_ui_gametype ] ]]();
		}
	}
}

post_gametype_main( mode ) //checked matches cerberus output
{
	set_game_var( "ZM_roundWinLimit", get_game_var( "ZM_roundLimit" ) * 0.5 );
	level.roundlimit = get_game_var( "ZM_roundLimit" );
	if ( isDefined( level.gamemode_map_preinit ) )
	{
		if ( isDefined( level.gamemode_map_preinit[ mode ] ) )
		{
			[[ level.gamemode_map_preinit[ mode ] ]]();
		}
	}
}

globallogic_setupdefault_zombiecallbacks() //checked matches cerberus output
{
	level.spawnplayer = maps/mp/gametypes_zm/_globallogic_spawn::spawnplayer;
	level.spawnplayerprediction = maps/mp/gametypes_zm/_globallogic_spawn::spawnplayerprediction;
	level.spawnclient = maps/mp/gametypes_zm/_globallogic_spawn::spawnclient;
	level.spawnspectator = maps/mp/gametypes_zm/_globallogic_spawn::spawnspectator;
	level.spawnintermission = maps/mp/gametypes_zm/_globallogic_spawn::spawnintermission;
	level.onplayerscore = ::blank;
	level.onteamscore = ::blank;
	
	//doesn't exist in any dump or any other script no idea what its trying to override to
	//level.wavespawntimer = ::wavespawntimer;
	level.onspawnplayer = ::blank;
	level.onspawnplayerunified = ::blank;
	level.onspawnspectator = ::onspawnspectator;
	level.onspawnintermission = ::onspawnintermission;
	level.onrespawndelay = ::blank;
	level.onforfeit = ::blank;
	level.ontimelimit = ::blank;
	level.onscorelimit = ::blank;
	level.ondeadevent = ::ondeadevent;
	level.ononeleftevent = ::blank;
	level.giveteamscore = ::blank;
	level.giveplayerscore = ::blank;
	level.gettimelimit = maps/mp/gametypes_zm/_globallogic_defaults::default_gettimelimit;
	level.getteamkillpenalty = ::blank;
	level.getteamkillscore = ::blank;
	level.iskillboosting = ::blank;
	level._setteamscore = maps/mp/gametypes_zm/_globallogic_score::_setteamscore;
	level._setplayerscore = ::blank;
	level._getteamscore = ::blank;
	level._getplayerscore = ::blank;
	level.onprecachegametype = ::blank;
	level.onstartgametype = ::blank;
	level.onplayerconnect = ::blank;
	level.onplayerdisconnect = ::onplayerdisconnect;
	level.onplayerdamage = ::blank;
	level.onplayerkilled = ::blank;
	level.onplayerkilledextraunthreadedcbs = [];
	level.onteamoutcomenotify = maps/mp/gametypes_zm/_hud_message::teamoutcomenotifyzombie;
	level.onoutcomenotify = ::blank;
	level.onteamwageroutcomenotify = ::blank;
	level.onwageroutcomenotify = ::blank;
	level.onendgame = ::onendgame;
	level.onroundendgame = ::blank;
	level.onmedalawarded = ::blank;
	level.autoassign = maps/mp/gametypes_zm/_globallogic_ui::menuautoassign;
	level.spectator = maps/mp/gametypes_zm/_globallogic_ui::menuspectator;
	level.class = maps/mp/gametypes_zm/_globallogic_ui::menuclass;
	level.allies = ::menuallieszombies;
	level.teammenu = maps/mp/gametypes_zm/_globallogic_ui::menuteam;
	level.callbackactorkilled = ::blank;
	level.callbackvehicledamage = ::blank;
}

setup_standard_objects( location ) //checked partially used cerberus output
{
	structs = getstructarray( "game_mode_object" );
	i = 0;
	while ( i < structs.size )
	{
		if ( isdefined( structs[ i ].script_noteworthy ) && structs[ i ].script_noteworthy != location )
		{
			i++;
			continue;
		}
		if ( isdefined( structs[ i ].script_string ) )
		{
			keep = 0;
			tokens = strtok( structs[ i ].script_string, " " );
			j = 0;
			while ( j < tokens.size )
			{
				if ( tokens[ j ] == level.scr_zm_ui_gametype && tokens[ j ] != "zstandard" )
				{
					keep = 1;
				}
				else if ( tokens[ j ] == "zstandard" )
				{
					keep = 1;
				}
				j++;
			}
			if ( !keep )
			{
				i++;
				continue;
			}
		}
		barricade = spawn( "script_model", structs[ i ].origin );
		barricade.angles = structs[ i ].angles;
		barricade setmodel( structs[ i ].script_parameters );
		i++;
	}
	objects = getentarray();
	i = 0;
	while ( i < objects.size )
	{
		if ( !objects[ i ] is_survival_object() )
		{	
			i++;
			continue;
		}
		if ( isdefined( objects[ i ].spawnflags ) && objects[ i ].spawnflags == 1 && objects[ i ].classname != "trigger_multiple" )
		{
			objects[ i ] connectpaths();
		}
		objects[ i ] delete();
		i++;
	}
	if ( isdefined( level._classic_setup_func ) )
	{
		[[ level._classic_setup_func ]]();
	}
}


is_survival_object() //checked changed to cerberus output
{
	if ( !isdefined( self.script_parameters ) )
	{
		return 0;
	}
	tokens = strtok( self.script_parameters, " " );
	remove = 0;
	foreach ( token in tokens )
	{
		if ( token == "survival_remove" )
		{
			remove = 1;
		}
	}
	return remove;
}

game_module_player_damage_callback( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime ) //checked partially changed output to cerberus output
{
	self.last_damage_from_zombie_or_player = 0;
	if ( isDefined( eattacker ) )
	{
		if ( isplayer( eattacker ) && eattacker == self )
		{
			return;
		}
		if ( isDefined( eattacker.is_zombie ) || eattacker.is_zombie && isplayer( eattacker ) )
		{
			self.last_damage_from_zombie_or_player = 1;
		}
	}
	if ( isDefined( self._being_shellshocked ) || self._being_shellshocked && self maps/mp/zombies/_zm_laststand::player_is_in_laststand() )
	{
		return;
	}
	if ( isplayer( eattacker ) && isDefined( eattacker._encounters_team ) && eattacker._encounters_team != self._encounters_team )
	{
		if ( isDefined( self.hasriotshield ) && self.hasriotshield && isDefined( vdir ) )
		{
			if ( isDefined( self.hasriotshieldequipped ) && self.hasriotshieldequipped )
			{
				if ( self maps/mp/zombies/_zm::player_shield_facing_attacker( vdir, 0.2 ) && isDefined( self.player_shield_apply_damage ) )
				{
					return;
				}
			}
			else if ( !isdefined( self.riotshieldentity ) )
			{
				if ( !self maps/mp/zombies/_zm::player_shield_facing_attacker( vdir, -0.2 ) && isdefined( self.player_shield_apply_damage ) )
				{
					return;
				}
			}
		}
		if ( isDefined( level._game_module_player_damage_grief_callback ) )
		{
			self [[ level._game_module_player_damage_grief_callback ]]( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime );
		}
		if ( isDefined( level._effect[ "butterflies" ] ) )
		{
			if ( isDefined( sweapon ) && weapontype( sweapon ) == "grenade" )
			{
				playfx( level._effect[ "butterflies" ], self.origin + vectorScale( ( 1, 1, 1 ), 40 ) );
			}
			else
			{
				playfx( level._effect[ "butterflies" ], vpoint, vdir );
			}
		}
		self thread do_game_mode_shellshock();
		self playsound( "zmb_player_hit_ding" );
	}
}

do_game_mode_shellshock() //checked matched cerberus output
{
	self endon( "disconnect" );
	self._being_shellshocked = 1;
	self shellshock( "grief_stab_zm", 0.75 );
	wait 0.75;
	self._being_shellshocked = 0;
}

add_map_gamemode( mode, preinit_func, precache_func, main_func ) //checked matches cerberus output
{
	if ( !isDefined( level.gamemode_map_location_init ) )
	{
		level.gamemode_map_location_init = [];
	}
	if ( !isDefined( level.gamemode_map_location_main ) )
	{
		level.gamemode_map_location_main = [];
	}
	if ( !isDefined( level.gamemode_map_preinit ) )
	{
		level.gamemode_map_preinit = [];
	}
	if ( !isDefined( level.gamemode_map_postinit ) )
	{
		level.gamemode_map_postinit = [];
	}
	if ( !isDefined( level.gamemode_map_precache ) )
	{
		level.gamemode_map_precache = [];
	}
	if ( !isDefined( level.gamemode_map_main ) )
	{
		level.gamemode_map_main = [];
	}
	level.gamemode_map_preinit[ mode ] = preinit_func;
	level.gamemode_map_main[ mode ] = main_func;
	level.gamemode_map_precache[ mode ] = precache_func;
	level.gamemode_map_location_precache[ mode ] = [];
	level.gamemode_map_location_main[ mode ] = [];
}

add_map_location_gamemode( mode, location, precache_func, main_func ) //checked matches cerberus output
{
	if ( !isDefined( level.gamemode_map_location_precache[ mode ] ) )
	{
	/*
/#
		println( "*** ERROR : " + mode + " has not been added to the map using add_map_gamemode." );
#/
	*/
		return;
	}
	level.gamemode_map_location_precache[ mode ][ location ] = precache_func;
	level.gamemode_map_location_main[ mode ][ location ] = main_func;
}

rungametypeprecache( gamemode ) //checked matches cerberus output
{
	if ( !isDefined( level.gamemode_map_location_main ) || !isDefined( level.gamemode_map_location_main[ gamemode ] ) )
	{
		return;
	}
	if ( isDefined( level.gamemode_map_precache ) )
	{
		if ( isDefined( level.gamemode_map_precache[ gamemode ] ) )
		{
			[[ level.gamemode_map_precache[ gamemode ] ]]();
		}
	}
	if ( isDefined( level.gamemode_map_location_precache ) )
	{
		if ( isDefined( level.gamemode_map_location_precache[ gamemode ] ) )
		{
			loc = getDvar( "ui_zm_mapstartlocation" );
			if ( loc == "" && isDefined( level.default_start_location ) )
			{
				loc = level.default_start_location;
			}
			if ( isDefined( level.gamemode_map_location_precache[ gamemode ][ loc ] ) )
			{
				[[ level.gamemode_map_location_precache[ gamemode ][ loc ] ]]();
			}
		}
	}
	if ( isDefined( level.precachecustomcharacters ) )
	{
		self [[ level.precachecustomcharacters ]]();
	}
}

rungametypemain( gamemode, mode_main_func, use_round_logic ) //checked matches cerberus output
{
	if ( !isDefined( level.gamemode_map_location_main ) || !isDefined( level.gamemode_map_location_main[ gamemode ] ) )
	{
		return;
	}
	level thread game_objects_allowed( get_gamemode_var( "mode" ), get_gamemode_var( "location" ) );
	if ( isDefined( level.gamemode_map_main ) )
	{
		if ( isDefined( level.gamemode_map_main[ gamemode ] ) )
		{
			level thread [[ level.gamemode_map_main[ gamemode ] ]]();
		}
	}
	if ( isDefined( level.gamemode_map_location_main ) )
	{
		if ( isDefined( level.gamemode_map_location_main[ gamemode ] ) )
		{
			loc = getDvar( "ui_zm_mapstartlocation" );
			if ( loc == "" && isDefined( level.default_start_location ) )
			{
				loc = level.default_start_location;
			}
			if ( isDefined( level.gamemode_map_location_main[ gamemode ][ loc ] ) )
			{
				level thread [[ level.gamemode_map_location_main[ gamemode ][ loc ] ]]();
			}
		}
	}
	if ( isDefined( mode_main_func ) )
	{
		if ( isDefined( use_round_logic ) && use_round_logic )
		{
			level thread round_logic( mode_main_func );
		}
		else
		{
			level thread non_round_logic( mode_main_func );
		}
	}
	level thread game_end_func();
}


round_logic( mode_logic_func ) //checked matches cerberus output
{
	level.skit_vox_override = 1;
	if ( isDefined( level.flag[ "start_zombie_round_logic" ] ) )
	{
		flag_wait( "start_zombie_round_logic" );
	}
	flag_wait( "start_encounters_match_logic" );
	if ( !isDefined( game[ "gamemode_match" ][ "rounds" ] ) )
	{
		game[ "gamemode_match" ][ "rounds" ] = [];
	}
	set_gamemode_var_once( "current_round", 0 );
	set_gamemode_var_once( "team_1_score", 0 );
	set_gamemode_var_once( "team_2_score", 0 );
	if ( isDefined( is_encounter() ) && is_encounter() )
	{
		[[ level._setteamscore ]]( "allies", get_gamemode_var( "team_2_score" ) );
		[[ level._setteamscore ]]( "axis", get_gamemode_var( "team_1_score" ) );
	}
	flag_set( "pregame" );
	waittillframeend;
	level.gameended = 0;
	cur_round = get_gamemode_var( "current_round" );
	set_gamemode_var( "current_round", cur_round + 1 );
	game[ "gamemode_match" ][ "rounds" ][ cur_round ] = spawnstruct();
	game[ "gamemode_match" ][ "rounds" ][ cur_round ].mode = getDvar( "ui_gametype" );
	level thread [[ mode_logic_func ]]();
	flag_wait( "start_encounters_match_logic" );
	level.gamestarttime = getTime();
	level.gamelengthtime = undefined;
	level notify( "clear_hud_elems" );
	level waittill( "game_module_ended", winner );
	game[ "gamemode_match" ][ "rounds" ][ cur_round ].winner = winner;
	level thread kill_all_zombies();
	level.gameendtime = getTime();
	level.gamelengthtime = level.gameendtime - level.gamestarttime;
	level.gameended = 1;
	if ( winner == "A" )
	{
		score = get_gamemode_var( "team_1_score" );
		set_gamemode_var( "team_1_score", score + 1 );
	}
	else
	{
		score = get_gamemode_var( "team_2_score" );
		set_gamemode_var( "team_2_score", score + 1 );
	}
	if ( isDefined( is_encounter() ) && is_encounter() )
	{
		[[ level._setteamscore ]]( "allies", get_gamemode_var( "team_2_score" ) );
		[[ level._setteamscore ]]( "axis", get_gamemode_var( "team_1_score" ) );
		if ( get_gamemode_var( "team_1_score" ) == get_gamemode_var( "team_2_score" ) )
		{
			level thread maps/mp/zombies/_zm_audio::zmbvoxcrowdonteam( "win" );
			level thread maps/mp/zombies/_zm_audio_announcer::announceroundwinner( "tied" );
		}
		else
		{
			level thread maps/mp/zombies/_zm_audio::zmbvoxcrowdonteam( "win", winner, "lose" );
			level thread maps/mp/zombies/_zm_audio_announcer::announceroundwinner( winner );
		}
	}
	level thread delete_corpses();
	level delay_thread( 5, ::revive_laststand_players );
	level notify( "clear_hud_elems" );
	while ( startnextzmround( winner ) )
	{
		level clientnotify( "gme" );
		while ( 1 )
		{
			wait 1;
		}
	}
	level.match_is_ending = 1;
	if ( isDefined( is_encounter() ) && is_encounter() )
	{
		matchwonteam = "";
		if ( get_gamemode_var( "team_1_score" ) > get_gamemode_var( "team_2_score" ) )
		{
			matchwonteam = "A";
		}
		else
		{
			matchwonteam = "B";
		}
		level thread maps/mp/zombies/_zm_audio::zmbvoxcrowdonteam( "win", matchwonteam, "lose" );
		level thread maps/mp/zombies/_zm_audio_announcer::announcematchwinner( matchwonteam );
		level create_final_score();
		track_encounters_win_stats( matchwonteam );
	}
	maps/mp/zombies/_zm::intermission();
	level.can_revive_game_module = undefined;
	level notify( "end_game" );
}

end_rounds_early( winner ) //checked matches cerberus output
{
	level.forcedend = 1;
	cur_round = get_gamemode_var( "current_round" );
	set_gamemode_var( "ZM_roundLimit", cur_round );
	if ( isDefined( winner ) )
	{
		level notify( "game_module_ended" );
	}
	else
	{
		level notify( "end_game" );
	}
}


checkzmroundswitch() //checked matches cerberus output
{
	if ( !isDefined( level.zm_roundswitch ) || !level.zm_roundswitch )
	{
		return 0;
	}
	
	return 1;
	return 0;
}

create_hud_scoreboard( duration, fade ) //checked matches cerberus output
{
	level endon( "end_game" );
	level thread module_hud_full_screen_overlay();
	level thread module_hud_team_1_score( duration, fade );
	level thread module_hud_team_2_score( duration, fade );
	level thread module_hud_round_num( duration, fade );
	respawn_spectators_and_freeze_players();
	waittill_any_or_timeout( duration, "clear_hud_elems" );
}

respawn_spectators_and_freeze_players() //checked changed to match cerberus output
{
	players = get_players();
	foreach ( player in players )
	{
		if ( player.sessionstate == "spectator" )
		{
			if ( isdefined( player.spectate_hud ) )
			{
				player.spectate_hud destroy();
			}
			player [[ level.spawnplayer ]]();
		}
		player freeze_player_controls(1);
	}
}

module_hud_team_1_score( duration, fade ) //checked matches cerberus output
{
	level._encounters_score_1 = newhudelem();
	level._encounters_score_1.x = 0;
	level._encounters_score_1.y = 260;
	level._encounters_score_1.alignx = "center";
	level._encounters_score_1.horzalign = "center";
	level._encounters_score_1.vertalign = "top";
	level._encounters_score_1.font = "default";
	level._encounters_score_1.fontscale = 2.3;
	level._encounters_score_1.color = ( 1, 1, 1 );
	level._encounters_score_1.foreground = 1;
	level._encounters_score_1 settext( "Team CIA:  " + get_gamemode_var( "team_1_score" ) );
	level._encounters_score_1.alpha = 0;
	level._encounters_score_1.sort = 11;
	level._encounters_score_1 fadeovertime( fade );
	level._encounters_score_1.alpha = 1;
	level waittill_any_or_timeout( duration, "clear_hud_elems" );
	level._encounters_score_1 fadeovertime( fade );
	level._encounters_score_1.alpha = 0;
	wait fade;
	level._encounters_score_1 destroy();
}

module_hud_team_2_score( duration, fade ) //checked matches cerberus output
{
	level._encounters_score_2 = newhudelem();
	level._encounters_score_2.x = 0;
	level._encounters_score_2.y = 290;
	level._encounters_score_2.alignx = "center";
	level._encounters_score_2.horzalign = "center";
	level._encounters_score_2.vertalign = "top";
	level._encounters_score_2.font = "default";
	level._encounters_score_2.fontscale = 2.3;
	level._encounters_score_2.color = ( 1, 1, 1 );
	level._encounters_score_2.foreground = 1;
	level._encounters_score_2 settext( "Team CDC:  " + get_gamemode_var( "team_2_score" ) );
	level._encounters_score_2.alpha = 0;
	level._encounters_score_2.sort = 12;
	level._encounters_score_2 fadeovertime( fade );
	level._encounters_score_2.alpha = 1;
	level waittill_any_or_timeout( duration, "clear_hud_elems" );
	level._encounters_score_2 fadeovertime( fade );
	level._encounters_score_2.alpha = 0;
	wait fade;
	level._encounters_score_2 destroy();
}

module_hud_round_num( duration, fade ) //checked matches cerberus output
{
	level._encounters_round_num = newhudelem();
	level._encounters_round_num.x = 0;
	level._encounters_round_num.y = 60;
	level._encounters_round_num.alignx = "center";
	level._encounters_round_num.horzalign = "center";
	level._encounters_round_num.vertalign = "top";
	level._encounters_round_num.font = "default";
	level._encounters_round_num.fontscale = 2.3;
	level._encounters_round_num.color = ( 1, 1, 1 );
	level._encounters_round_num.foreground = 1;
	level._encounters_round_num settext( "Round:  ^5" + get_gamemode_var( "current_round" ) + 1 + " / " + get_game_var( "ZM_roundLimit" ) );
	level._encounters_round_num.alpha = 0;
	level._encounters_round_num.sort = 13;
	level._encounters_round_num fadeovertime( fade );
	level._encounters_round_num.alpha = 1;
	level waittill_any_or_timeout( duration, "clear_hud_elems" );
	level._encounters_round_num fadeovertime( fade );
	level._encounters_round_num.alpha = 0;
	wait fade;
	level._encounters_round_num destroy();
}

createtimer() //checked matches cerberus output
{
	flag_waitopen( "pregame" );
	elem = newhudelem();
	elem.hidewheninmenu = 1;
	elem.horzalign = "center";
	elem.vertalign = "top";
	elem.alignx = "center";
	elem.aligny = "middle";
	elem.x = 0;
	elem.y = 0;
	elem.foreground = 1;
	elem.font = "default";
	elem.fontscale = 1.5;
	elem.color = ( 1, 1, 1 );
	elem.alpha = 2;
	elem thread maps/mp/gametypes_zm/_hud::fontpulseinit();
	if ( isDefined( level.timercountdown ) && level.timercountdown )
	{
		elem settenthstimer( level.timelimit * 60 );
	}
	else
	{
		elem settenthstimerup( 0.1 );
	}
	level.game_module_timer = elem;
	level waittill( "game_module_ended" );
	elem destroy();
}

revive_laststand_players() //checked changed to match cerberus output
{
	if ( isDefined( level.match_is_ending ) && level.match_is_ending )
	{
		return;
	}
	players = get_players();
	foreach ( player in players )
	{
		if ( player maps/mp/zombies/_zm_laststand::player_is_in_laststand() )
		{
			player thread maps/mp/zombies/_zm_laststand::auto_revive( player );
		}
	}
}

team_icon_winner( elem ) //checked matches cerberus output
{
	og_x = elem.x;
	og_y = elem.y;
	elem.sort = 1;
	elem scaleovertime( 0.75, 150, 150 );
	elem moveovertime( 0.75 );
	elem.horzalign = "center";
	elem.vertalign = "middle";
	elem.x = 0;
	elem.y = 0;
	elem.alpha = 0.7;
	wait 0.75;
}

delete_corpses() //checked changed to match cerberus output
{
	corpses = getcorpsearray();
	for(x = 0; x < corpses.size; x++)
	{
		corpses[x] delete();
	}
}

track_encounters_win_stats( matchwonteam ) //checked did not change to match cerberus output
{
	players = get_players();
	i = 0;
	while ( i < players.size )
	{
		if ( players[ i ]._encounters_team == matchwonteam )
		{
			players[ i ] maps/mp/zombies/_zm_stats::increment_client_stat( "wins" );
			players[ i ] maps/mp/zombies/_zm_stats::add_client_stat( "losses", -1 );
			players[ i ] adddstat( "skill_rating", 1 );
			players[ i ] setdstat( "skill_variance", 1 );
			if ( gamemodeismode( level.gamemode_public_match ) )
			{
				players[ i ] maps/mp/zombies/_zm_stats::add_location_gametype_stat( level.scr_zm_map_start_location, level.scr_zm_ui_gametype, "wins", 1 );
				players[ i ] maps/mp/zombies/_zm_stats::add_location_gametype_stat( level.scr_zm_map_start_location, level.scr_zm_ui_gametype, "losses", -1 );
			}
		}
		else
		{
			players[ i ] setdstat( "skill_rating", 0 );
			players[ i ] setdstat( "skill_variance", 1 );
		}
		players[ i ] updatestatratio( "wlratio", "wins", "losses" );
		i++;
	}
}

non_round_logic( mode_logic_func ) //checked matches cerberus output
{
	level thread [[ mode_logic_func ]]();
}

game_end_func() //checked matches cerberus output
{
	if ( !isDefined( get_gamemode_var( "match_end_notify" ) ) && !isDefined( get_gamemode_var( "match_end_func" ) ) )
	{
		return;
	}
	level waittill( get_gamemode_var( "match_end_notify" ), winning_team );
	level thread [[ get_gamemode_var( "match_end_func" ) ]]( winning_team );
}

setup_classic_gametype() //checked did not change to match cerberus output
{
	ents = getentarray();
	i = 0;
	while ( i < ents.size )
	{	
		if ( isDefined( ents[ i ].script_parameters ) )
		{
			parameters = strtok( ents[ i ].script_parameters, " " );
			should_remove = 0;
			foreach ( parm in parameters )
			{
				if ( parm == "survival_remove" )
				{
					should_remove = 1;
				}
			}
			if ( should_remove )
			{
				ents[ i ] delete();
			}
		}
		i++;
	}
	structs = getstructarray( "game_mode_object" );
	i = 0;
	while ( i < structs.size )
	{
		if ( !isdefined( structs[ i ].script_string ) )
		{
			i++;
			continue;
		}
		tokens = strtok( structs[ i ].script_string, " " );
		spawn_object = 0;
		foreach ( parm in tokens )
		{
			if ( parm == "survival" )
			{
				spawn_object = 1;
			}
		}
		if ( !spawn_object )
		{
			i++;
			continue;
		}
		barricade = spawn( "script_model", structs[ i ].origin );
		barricade.angles = structs[ i ].angles;
		barricade setmodel( structs[ i ].script_parameters );
		i++;
	}
	unlink_meat_traversal_nodes();
}

zclassic_main() //checked matches cerberus output
{
	level thread setup_classic_gametype();
	level thread maps/mp/zombies/_zm::round_start();
}

unlink_meat_traversal_nodes() //checked changed to match cerberus output
{
	meat_town_nodes = getnodearray( "meat_town_barrier_traversals", "targetname" );
	meat_tunnel_nodes = getnodearray( "meat_tunnel_barrier_traversals", "targetname" );
	meat_farm_nodes = getnodearray( "meat_farm_barrier_traversals", "targetname" );
	nodes = arraycombine( meat_town_nodes, meat_tunnel_nodes, 1, 0 );
	traversal_nodes = arraycombine( nodes, meat_farm_nodes, 1, 0 );
	foreach ( node in traversal_nodes )
	{
		end_node = getnode( node.target, "targetname" );
		unlink_nodes( node, end_node );
	}
}

canplayersuicide() //checked matches cerberus output
{
	return self hasperk( "specialty_scavenger" );
}

onplayerdisconnect() //checked matches cerberus output
{
	if ( isDefined( level.game_mode_custom_onplayerdisconnect ) )
	{
		level [[ level.game_mode_custom_onplayerdisconnect ]]( self );
	}
	level thread maps/mp/zombies/_zm::check_quickrevive_for_hotjoin( 1 );
	self maps/mp/zombies/_zm_laststand::add_weighted_down();
	level maps/mp/zombies/_zm::checkforalldead( self );
}

ondeadevent( team ) //checked matches cerberus output
{
	thread maps/mp/gametypes_zm/_globallogic::endgame( level.zombie_team, "" );
}

onspawnintermission() //checked matches cerberus output
{
	spawnpointname = "info_intermission";
	spawnpoints = getentarray( spawnpointname, "classname" );
	if ( spawnpoints.size < 1 )
	{
	/*
/#
		println( "NO " + spawnpointname + " SPAWNPOINTS IN MAP" );
#/
	*/
		return;
	}
	spawnpoint = spawnpoints[ randomint( spawnpoints.size ) ];
	if ( isDefined( spawnpoint ) )
	{
		self spawn( spawnpoint.origin, spawnpoint.angles );
	}
}

onspawnspectator( origin, angles ) //checked matches cerberus output
{
}

mayspawn() //checked matches cerberus output
{
	if ( isDefined( level.custommayspawnlogic ) )
	{
		return self [[ level.custommayspawnlogic ]]();
	}
	if ( self.pers[ "lives" ] == 0 )
	{
		level notify( "player_eliminated" );
		self notify( "player_eliminated" );
		return 0;
	}
	return 1;
}

onstartgametype() //checked matches cerberus output
{
	setclientnamemode( "auto_change" );
	level.displayroundendtext = 0;
	maps/mp/gametypes_zm/_spawning::create_map_placed_influencers();
	if ( !isoneround() )
	{
		level.displayroundendtext = 1;
		if ( isscoreroundbased() )
		{
			maps/mp/gametypes_zm/_globallogic_score::resetteamscores();
		}
	}
}

module_hud_full_screen_overlay() //checked matches cerberus output
{
	fadetoblack = newhudelem();
	fadetoblack.x = 0;
	fadetoblack.y = 0;
	fadetoblack.horzalign = "fullscreen";
	fadetoblack.vertalign = "fullscreen";
	fadetoblack setshader( "black", 640, 480 );
	fadetoblack.color = ( 1, 1, 1 );
	fadetoblack.alpha = 1;
	fadetoblack.foreground = 1;
	fadetoblack.sort = 0;
	if ( is_encounter() || getDvar( "ui_gametype" ) == "zcleansed" )
	{
		level waittill_any_or_timeout( 25, "start_fullscreen_fade_out" );
	}
	else
	{
		level waittill_any_or_timeout( 25, "start_zombie_round_logic" );
	}
	fadetoblack fadeovertime( 2 );
	fadetoblack.alpha = 0;
	wait 2.1;
	fadetoblack destroy();
}

create_final_score() //checked matches cerberus output
{
	level endon( "end_game" );
	level thread module_hud_team_winer_score();
	wait 2;
}

module_hud_team_winer_score() //checked changed to match cerberus output
{
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[ i ] thread create_module_hud_team_winer_score();
		if ( isDefined( players[ i ]._team_hud ) && isDefined( players[ i ]._team_hud[ "team" ] ) )
		{
			players[ i ] thread team_icon_winner( players[ i ]._team_hud[ "team" ] );
		}
		if ( isDefined( level.lock_player_on_team_score ) && level.lock_player_on_team_score )
		{
			players[ i ] freezecontrols( 1 );
			players[ i ] takeallweapons();
			players[ i ] setclientuivisibilityflag( "hud_visible", 0 );
			players[ i ].sessionstate = "spectator";
			players[ i ].spectatorclient = -1;
			players[ i ].maxhealth = players[ i ].health;
			players[ i ].shellshocked = 0;
			players[ i ].inwater = 0;
			players[ i ].friendlydamage = undefined;
			players[ i ].hasspawned = 1;
			players[ i ].spawntime = getTime();
			players[ i ].afk = 0;
			players[ i ] detachall();
		}
	}
	level thread maps/mp/zombies/_zm_audio::change_zombie_music( "match_over" );
}

create_module_hud_team_winer_score() //checked changed to match cerberus output
{
	self._team_winer_score = newclienthudelem( self );
	self._team_winer_score.x = 0;
	self._team_winer_score.y = 70;
	self._team_winer_score.alignx = "center";
	self._team_winer_score.horzalign = "center";
	self._team_winer_score.vertalign = "middle";
	self._team_winer_score.font = "default";
	self._team_winer_score.fontscale = 15;
	self._team_winer_score.color = ( 0, 1, 0 );
	self._team_winer_score.foreground = 1;
	if ( self._encounters_team == "B" && get_gamemode_var( "team_2_score" ) > get_gamemode_var( "team_1_score" ) )
	{
		self._team_winer_score settext( &"ZOMBIE_MATCH_WON" );
	}
	else
	{
		if ( self._encounters_team == "B" && get_gamemode_var( "team_2_score" ) < get_gamemode_var( "team_1_score" ) )
		{
			self._team_winer_score.color = ( 1, 0, 0 );
			self._team_winer_score settext( &"ZOMBIE_MATCH_LOST" );
		}
	}
	if ( self._encounters_team == "A" && get_gamemode_var( "team_1_score" ) > get_gamemode_var( "team_2_score" ) )
	{
		self._team_winer_score settext( &"ZOMBIE_MATCH_WON" );
	}
	else
	{
		if ( self._encounters_team == "A" && get_gamemode_var( "team_1_score" ) < get_gamemode_var( "team_2_score" ) )
		{
			self._team_winer_score.color = ( 1, 0, 0 );
			self._team_winer_score settext( &"ZOMBIE_MATCH_LOST" );
		}
	}
	self._team_winer_score.alpha = 0;
	self._team_winer_score.sort = 12;
	self._team_winer_score fadeovertime( 0.25 );
	self._team_winer_score.alpha = 1;
	wait 2;
	self._team_winer_score fadeovertime( 0.25 );
	self._team_winer_score.alpha = 0;
	wait 0.25;
	self._team_winer_score destroy();
}

displayroundend( round_winner ) //checked changed to match cerberus output
{
	players = get_players();
	foreach(player in players)
	{
		player thread module_hud_round_end(round_winner);
		if(isdefined(player._team_hud) && isdefined(player._team_hud["team"]))
		{
			player thread team_icon_winner(player._team_hud["team"]);
		}
		player freeze_player_controls(1);
	}
	level thread maps/mp/zombies/_zm_audio::change_zombie_music( "round_end" );
	level thread maps/mp/zombies/_zm_audio::zmbvoxcrowdonteam( "clap" );
	level thread play_sound_2d( "zmb_air_horn" );
	wait 2;
}

module_hud_round_end( round_winner ) //checked changed to match cerberus output
{
	self endon( "disconnect" );
	self._team_winner_round = newclienthudelem( self );
	self._team_winner_round.x = 0;
	self._team_winner_round.y = 50;
	self._team_winner_round.alignx = "center";
	self._team_winner_round.horzalign = "center";
	self._team_winner_round.vertalign = "middle";
	self._team_winner_round.font = "default";
	self._team_winner_round.fontscale = 15;
	self._team_winner_round.color = ( 1, 1, 1 );
	self._team_winner_round.foreground = 1;
	if ( self._encounters_team == round_winner )
	{
		self._team_winner_round.color = ( 0, 1, 0 );
		self._team_winner_round settext( "YOU WIN" );
	}
	else
	{
		self._team_winner_round.color = ( 1, 0, 0 );
		self._team_winner_round settext( "YOU LOSE" );
	}
	self._team_winner_round.alpha = 0;
	self._team_winner_round.sort = 12;
	self._team_winner_round fadeovertime( 0.25 );
	self._team_winner_round.alpha = 1;
	wait 1.5;
	self._team_winner_round fadeovertime( 0.25 );
	self._team_winner_round.alpha = 0;
	wait 0.25;
	self._team_winner_round destroy();
}

displayroundswitch() //checked changed to match cerberus output
{
	level._round_changing_sides = newhudelem();
	level._round_changing_sides.x = 0;
	level._round_changing_sides.y = 60;
	level._round_changing_sides.alignx = "center";
	level._round_changing_sides.horzalign = "center";
	level._round_changing_sides.vertalign = "middle";
	level._round_changing_sides.font = "default";
	level._round_changing_sides.fontscale = 2.3;
	level._round_changing_sides.color = ( 1, 1, 1 );
	level._round_changing_sides.foreground = 1;
	level._round_changing_sides.sort = 12;
	fadetoblack = newhudelem();
	fadetoblack.x = 0;
	fadetoblack.y = 0;
	fadetoblack.horzalign = "fullscreen";
	fadetoblack.vertalign = "fullscreen";
	fadetoblack setshader( "black", 640, 480 );
	fadetoblack.color = ( 0, 0, 0 );
	fadetoblack.alpha = 1;
	level thread maps/mp/zombies/_zm_audio_announcer::leaderdialog( "side_switch" );
	level._round_changing_sides settext( "CHANGING SIDES" );
	level._round_changing_sides fadeovertime( 0.25 );
	level._round_changing_sides.alpha = 1;
	wait 1;
	fadetoblack fadeovertime( 1 );
	level._round_changing_sides fadeovertime( 0.25 );
	level._round_changing_sides.alpha = 0;
	fadetoblack.alpha = 0;
	wait 0.25;
	level._round_changing_sides destroy();
	fadetoblack destroy();
}

module_hud_create_team_name() //checked matches cerberus ouput
{
	if ( !is_encounter() )
	{
		return;
	}
	if ( !isDefined( self._team_hud ) )
	{
		self._team_hud = [];
	}
	if ( isDefined( self._team_hud[ "team" ] ) )
	{
		self._team_hud[ "team" ] destroy();
	}
	elem = newclienthudelem( self );
	elem.hidewheninmenu = 1;
	elem.alignx = "center";
	elem.aligny = "middle";
	elem.horzalign = "center";
	elem.vertalign = "middle";
	elem.x = 0;
	elem.y = 0;
	if ( isDefined( level.game_module_team_name_override_og_x ) )
	{
		elem.og_x = level.game_module_team_name_override_og_x;
	}
	else
	{
		elem.og_x = 85;
	}
	elem.og_y = -40;
	elem.foreground = 1;
	elem.font = "default";
	elem.color = ( 1, 1, 1 );
	elem.sort = 1;
	elem.alpha = 0.7;
	elem setshader( game[ "icons" ][ self.team ], 150, 150 );
	self._team_hud[ "team" ] = elem;
}

nextzmhud( winner ) //checked matches cerberus output
{
	displayroundend( winner );
	create_hud_scoreboard( 1, 0.25 );
	if ( checkzmroundswitch() )
	{
		displayroundswitch();
	}
}

startnextzmround( winner ) //checked matches cerberus output
{
	if ( !isonezmround() )
	{
		if ( !waslastzmround() )
		{
			nextzmhud( winner );
			setmatchtalkflag( "DeadChatWithDead", level.voip.deadchatwithdead );
			setmatchtalkflag( "DeadChatWithTeam", level.voip.deadchatwithteam );
			setmatchtalkflag( "DeadHearTeamLiving", level.voip.deadhearteamliving );
			setmatchtalkflag( "DeadHearAllLiving", level.voip.deadhearallliving );
			setmatchtalkflag( "EveryoneHearsEveryone", level.voip.everyonehearseveryone );
			setmatchtalkflag( "DeadHearKiller", level.voip.deadhearkiller );
			setmatchtalkflag( "KillersHearVictim", level.voip.killershearvictim );
			game[ "state" ] = "playing";
			level.allowbattlechatter = getgametypesetting( "allowBattleChatter" );
			if ( isDefined( level.zm_switchsides_on_roundswitch ) && level.zm_switchsides_on_roundswitch )
			{
				set_game_var( "switchedsides", !get_game_var( "switchedsides" ) );
			}
			map_restart( 1 );
			return 1;
		}
	}
	return 0;
}

start_round() //checked changed to match cerberus output
{
	flag_clear( "start_encounters_match_logic" );
	if ( !isDefined( level._module_round_hud ) )
	{
		level._module_round_hud = newhudelem();
		level._module_round_hud.x = 0;
		level._module_round_hud.y = 70;
		level._module_round_hud.alignx = "center";
		level._module_round_hud.horzalign = "center";
		level._module_round_hud.vertalign = "middle";
		level._module_round_hud.font = "default";
		level._module_round_hud.fontscale = 2.3;
		level._module_round_hud.color = ( 1, 1, 1 );
		level._module_round_hud.foreground = 1;
		level._module_round_hud.sort = 0;
	}
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[ i ] freeze_player_controls( 1 );
	}
	level._module_round_hud.alpha = 1;
	label = &"Next Round Starting In  ^2";
	level._module_round_hud.label = label;
	level._module_round_hud settimer( 3 );
	level thread maps/mp/zombies/_zm_audio_announcer::leaderdialog( "countdown" );
	level thread maps/mp/zombies/_zm_audio::zmbvoxcrowdonteam( "clap" );
	level thread maps/mp/zombies/_zm_audio::change_zombie_music( "round_start" );
	level notify( "start_fullscreen_fade_out" );
	wait 2;
	level._module_round_hud fadeovertime( 1 );
	level._module_round_hud.alpha = 0;
	wait 1;
	level thread play_sound_2d( "zmb_air_horn" );
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[ i ] freeze_player_controls( 0 );
		players[ i ] sprintuprequired();
	}
	flag_set( "start_encounters_match_logic" );
	flag_clear( "pregame" );
	level._module_round_hud destroy();
}

isonezmround() //checked matches cerberus output
{
	if ( get_game_var( "ZM_roundLimit" ) == 1 )
	{
		return 1;
	}
	return 0;
}

waslastzmround() //checked changed to match cerberus output
{
	if ( isDefined( level.forcedend ) && level.forcedend )
	{
		return 1;
	}
	if ( hitzmroundlimit() || hitzmscorelimit() || hitzmroundwinlimit() )
	{
		return 1;
	}
	return 0;
}

hitzmroundlimit() //checked matches cerberus output
{
	if ( get_game_var( "ZM_roundLimit" ) <= 0 )
	{
		return 0;
	}
	return getzmroundsplayed() >= get_game_var( "ZM_roundLimit" );
}

hitzmroundwinlimit() //checked matches cerberus output
{
	if ( !isDefined( get_game_var( "ZM_roundWinLimit" ) ) || get_game_var( "ZM_roundWinLimit" ) <= 0 )
	{
		return 0;
	}
	if ( get_gamemode_var( "team_1_score" ) >= get_game_var( "ZM_roundWinLimit" ) || get_gamemode_var( "team_2_score" ) >= get_game_var( "ZM_roundWinLimit" ) )
	{
		return 1;
	}
	if ( get_gamemode_var( "team_1_score" ) >= get_game_var( "ZM_roundWinLimit" ) || get_gamemode_var( "team_2_score" ) >= get_game_var( "ZM_roundWinLimit" ) )
	{
		if ( get_gamemode_var( "team_1_score" ) != get_gamemode_var( "team_2_score" ) )
		{
			return 1;
		}
	}
	return 0;
}

hitzmscorelimit() //checked matches cerberus output
{
	if ( get_game_var( "ZM_scoreLimit" ) <= 0 )
	{
		return 0;
	}
	if ( is_encounter() )
	{
		if ( get_gamemode_var( "team_1_score" ) >= get_game_var( "ZM_scoreLimit" ) || get_gamemode_var( "team_2_score" ) >= get_game_var( "ZM_scoreLimit" ) )
		{
			return 1;
		}
	}
	return 0;
}

getzmroundsplayed() //checked matches cerberus output
{
	return get_gamemode_var( "current_round" );
}

onspawnplayerunified() //checked matches cerberus output
{
	onspawnplayer( 0 );
}

getMapString(map) //custom function
{
	if(map == "tunnel")
		return "Tunnel";
	if(map == "diner")
		return "Diner";
	if(map == "power")
		return "Power Station";
	if(map == "house")
		return "Cabin";
	if(map == "cornfield")
		return "Cornfield";
	if(map == "docks")
		return "Docks";
	if(map == "cellblock")
		return "Cellblock";
	if(map == "rooftop")
		return "Rooftop/Bridge";
	if(map == "trenches")
		return "Trenches";
	if(map == "excavation")
		return "No Man's Land";
	if(map == "tank")
		return "Tank/Church";
	if(map == "crazyplace")
		return "Crazy Place";
	if(map == "vanilla")
		return "Vanilla";
}

override_map()
{
	mapname = ToLower( GetDvar( "mapname" ) );
	if( GetDvar("customMap") == "" )
		SetDvar("customMap", "vanilla");
	if ( isdefined(mapname) && mapname == "zm_transit" )
	{
		if ( GetDvar("customMap") != "tunnel" && GetDvar("customMap") != "diner" && GetDvar("customMap") != "power" && GetDvar("customMap") != "cornfield" && GetDvar("customMap") != "house" && GetDvar("customMap") != "vanilla" && GetDvar("customMap") != "town" && GetDvar("customMap") != "farm" && GetDvar("customMap") != "busdepot" )
		{
			SetDvar( "customMap", "house" );
		}
	}
	else if ( isdefined(mapname) && mapname == "zm_nuked" )
	{
		if ( GetDvar("customMap") != "nuketown" && GetDvar("customMap") != "vanilla")
		{
			SetDvar("customMap", "nuketown");
		}
	}
	else if ( isdefined(mapname) && mapname == "zm_highrise" )
	{
		if ( GetDvar("customMap") != "building1top" && GetDvar("customMap") != "vanilla" )
		{
			SetDvar( "customMap", "building1top" );
		}
	}
	else if ( isdefined(mapname) && mapname == "zm_prison" )
	{
		if ( GetDvar("customMap") != "docks" && GetDvar("customMap") != "cellblock" && GetDvar("customMap") != "rooftop" && GetDvar("customMap") != "vanilla" )
		{
			SetDvar( "customMap", "docks" );
		}
	}
	else if ( isdefined(mapname) && mapname == "zm_buried" )
	{
		if ( GetDvar("customMap") != "maze" && GetDvar("customMap") != "vanilla")
		{
			SetDvar( "customMap", "maze" );
		}
	}
	else if ( isdefined(mapname) && mapname == "zm_tomb" )
	{
		if ( GetDvar("customMap") != "trenches" && GetDvar("customMap") != "crazyplace" && GetDvar("customMap") != "excavation" && GetDvar("customMap") != "vanilla" )
		{
			SetDvar( "customMap", "trenches" );
		}
	}
	map = ToLower(GetDvar("customMap"));
	if(map == "town" || map == "busdepot" || map == "farm" || map == "nuketown")
	{
		level.customMap = "vanilla";
	}
	else
	{
		level.customMap = map;
	}
}

map_rotation() //custom function
{
	level waittill( "end_game");
	wait 2;
	level.randomizeMapRotation = getDvarIntDefault( "randomizeMapRotation", 0 );
	level.customMapRotationActive = getDvarIntDefault( "customMapRotationActive", 0 );
	level.customMapRotation = getDvar( "customMapRotation" );
	level.mapList = strTok( level.customMapRotation, " " );
	if ( !level.customMapRotationActive )
	{
		return;
	}
	if ( !isDefined( level.customMapRotation ) || level.customMapRotation == "" )
	{
		if ( level.script == "zm_transit" )
		{
			level.customMapRotation = "cornfield diner house power tunnel";
		}
		else if ( level.script == "zm_highrise" )
		{
			level.customMapRotation = "building1top";
		}
		else if ( level.script == "zm_prison" )
		{
			level.customMapRotation = "docks cellblock rooftop";
		}
		else if (level.script == "zm_buried")
		{
			level.customMapRotation = "maze";
		}
		else if ( level.script == "zm_nuked" )
		{
			level.customMapRotation = "nuketown";
		}
		else if (level.script == "zm_tomb")
		{
			level.customMapRotation = "trenches";
		}
	}
	if ( level.randomizeMapRotation && level.mapList.size > 3 )
	{
		level thread random_map_rotation();
		return;
	}
	for(i=0;i<level.mapList.size;i++)
	{
		if(isdefined(level.mapList[i+1]) && getDvar("customMap") == level.mapList[i])
		{
			changeMap(level.mapList[i+1]);
			return;
		}
	}
	changeMap(level.mapList[0]);
}

changeMap(map)
{
	if(!isdefined(map))
		map = GetDvar("customMap");
	SetDvar("customMap", map);
	if(map == "tunnel" || map == "diner" || map == "power" || map == "cornfield" || map == "house")
		SetDvar("sv_maprotation","exec zm_classic_transit.cfg map zm_transit");
	else if(map == "town")
		SetDvar("sv_maprotation","exec zm_standard_town.cfg map zm_transit");
	else if(map == "farm")
		SetDvar("sv_maprotation","exec zm_standard_farm.cfg map zm_transit");
	else if(map == "busdepot")
		SetDvar("sv_maprotation","exec zm_standard_transit.cfg map zm_transit");
	else if(map == "nuketown")
		SetDvar("sv_maprotation","exec zm_standard_nuked.cfg map zm_nuked");
	else if(map == "docks" || map == "cellblock" || map == "rooftop")
		SetDvar("sv_maprotation","exec zm_classic_prison.cfg map zm_prison");
	else if(map == "building1top")
		SetDvar("sv_maprotation", "exec zm_classic_rooftop.cfg map zm_highrise");
	else if(map == "maze")
		SetDvar("sv_maprotation", "exec zm_classic_processing.cfg map zm_buried");
	else if(map == "trenches" || map == "crazyplace")
		SetDvar("sv_maprotation", "exec zm_classic_tomb.cfg map zm_tomb");
}

random_map_rotation() //custom function
{
	level.nextMap = RandomInt( level.mapList.size );
	level.lastMap = getDvar( "lastMap" );
	if( getDvar("customMap") == level.mapList[ level.nextMap ] || level.mapList[ level.nextMap ] == level.lastMap )
	{
		return random_map_rotation();
	}
	else
	{
		setDvar( "lastMap", getDvar("customMap") );
		changeMap(level.mapList[ level.nextMap ]);
		return;
	}
}

init_spawnpoints_for_custom_survival_maps() //custom function
{
	level.mapRestarted = getDvarIntDefault( "customMapsMapRestarted", 0 );
	level.disableBSMMagic = getDvarIntDefault("disableBSMMagic", 0);
	map = level.customMap;
	if ( level.script == "zm_transit" )
	{
		//TUNNEL
		level.tunnelSpawnpoints = [];
		level.tunnelSpawnpoints[ 0 ] = spawnstruct();
		level.tunnelSpawnpoints[ 0 ].origin = ( -11196, -837, 192 );
		level.tunnelSpawnpoints[ 0 ].angles = ( 0, -94, 0 );
		level.tunnelSpawnpoints[ 0 ].radius = 32;
		level.tunnelSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 0 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 1 ] = spawnstruct();
		level.tunnelSpawnpoints[ 1 ].origin = ( -11386, -863, 192 );
		level.tunnelSpawnpoints[ 1 ].angles = ( 0, -44, 0 );
		level.tunnelSpawnpoints[ 1 ].radius = 32;
		level.tunnelSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 1 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 2 ] = spawnstruct();
		level.tunnelSpawnpoints[ 2 ].origin = ( -11405, -1000, 192 );
		level.tunnelSpawnpoints[ 2 ].angles = ( 0, -32, 0 );
		level.tunnelSpawnpoints[ 2 ].radius = 32;
		level.tunnelSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 2 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 3 ] = spawnstruct();
		level.tunnelSpawnpoints[ 3 ].origin = ( -11498, -1151, 192 );
		level.tunnelSpawnpoints[ 3 ].angles = ( 0, 4, 0 );
		level.tunnelSpawnpoints[ 3 ].radius = 32;
		level.tunnelSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 3 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 4 ] = spawnstruct();
		level.tunnelSpawnpoints[ 4 ].origin = ( -11398, -1326, 191 );
		level.tunnelSpawnpoints[ 4 ].angles = ( 0, 50, 0 );
		level.tunnelSpawnpoints[ 4 ].radius = 32;
		level.tunnelSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 4 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 5 ] = spawnstruct();
		level.tunnelSpawnpoints[ 5 ].origin = ( -11222, -1345, 192 );
		level.tunnelSpawnpoints[ 5 ].angles = ( 0, 89, 0 );
		level.tunnelSpawnpoints[ 5 ].radius = 32;
		level.tunnelSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 5 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 6 ] = spawnstruct();
		level.tunnelSpawnpoints[ 6 ].origin = ( -10934, -1380, 192 );
		level.tunnelSpawnpoints[ 6 ].angles = ( 0, 157, 0 );
		level.tunnelSpawnpoints[ 6 ].radius = 32;
		level.tunnelSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 6 ].script_int = 2048;
		
		level.tunnelSpawnpoints[ 7 ] = spawnstruct();
		level.tunnelSpawnpoints[ 7 ].origin = ( -10999, -1072, 192 );
		level.tunnelSpawnpoints[ 7 ].angles = ( 0, -144, 0 );
		level.tunnelSpawnpoints[ 7 ].radius = 32;
		level.tunnelSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.tunnelSpawnpoints[ 7 ].script_int = 2048;
		
		//DINER
		level.dinerSpawnpoints = [];									 
		level.dinerSpawnpoints[ 0 ] = spawnstruct();
		level.dinerSpawnpoints[ 0 ].origin = ( -3991, -7317, -63 );
		level.dinerSpawnpoints[ 0 ].angles = ( 0, 161, 0 );
		level.dinerSpawnpoints[ 0 ].radius = 32;
		level.dinerSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 0 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 1 ] = spawnstruct();
		level.dinerSpawnpoints[ 1 ].origin = ( -4231, -7395, -60 );
		level.dinerSpawnpoints[ 1 ].angles = ( 0, 120, 0 );
		level.dinerSpawnpoints[ 1 ].radius = 32;
		level.dinerSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 1 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 2 ] = spawnstruct();
		level.dinerSpawnpoints[ 2 ].origin = ( -4127, -6757, -54 );
		level.dinerSpawnpoints[ 2 ].angles = ( 0, 217, 0 );
		level.dinerSpawnpoints[ 2 ].radius = 32;
		level.dinerSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 2 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 3 ] = spawnstruct();
		level.dinerSpawnpoints[ 3 ].origin = ( -4465, -7346, -58 );
		level.dinerSpawnpoints[ 3 ].angles = ( 0, 173, 0 );
		level.dinerSpawnpoints[ 3 ].radius = 32;
		level.dinerSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 3 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 4 ] = spawnstruct();
		level.dinerSpawnpoints[ 4 ].origin = ( -5770, -6600, -55 );
		level.dinerSpawnpoints[ 4 ].angles = ( 0, -106, 0 );
		level.dinerSpawnpoints[ 4 ].radius = 32;
		level.dinerSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 4 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 5 ] = spawnstruct();
		level.dinerSpawnpoints[ 5 ].origin = ( -6135, -6671, -56 );
		level.dinerSpawnpoints[ 5 ].angles = ( 0, -46, 0 );
		level.dinerSpawnpoints[ 5 ].radius = 32;
		level.dinerSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 5 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 6 ] = spawnstruct();
		level.dinerSpawnpoints[ 6 ].origin = ( -6182, -7120, -60 );
		level.dinerSpawnpoints[ 6 ].angles = ( 0, 51, 0 );
		level.dinerSpawnpoints[ 6 ].radius = 32;
		level.dinerSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 6 ].script_int = 2048;
		
		level.dinerSpawnpoints[ 7 ] = spawnstruct();
		level.dinerSpawnpoints[ 7 ].origin = ( -5882, -7174, -61 );
		level.dinerSpawnpoints[ 7 ].angles = ( 0, 99, 0 );
		level.dinerSpawnpoints[ 7 ].radius = 32;
		level.dinerSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.dinerSpawnpoints[ 7 ].script_int = 2048;
		
		//CORNFIELD
		level.cornfieldSpawnpoints = [];
		level.cornfieldSpawnpoints[ 0 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 0 ].origin = ( 7521, -545, -198 );
		level.cornfieldSpawnpoints[ 0 ].angles = ( 0, 40, 0 );
		level.cornfieldSpawnpoints[ 0 ].radius = 32;
		level.cornfieldSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 0 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 1 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 1 ].origin = ( 7751, -522, -202 );
		level.cornfieldSpawnpoints[ 1 ].angles = ( 0, 145, 0 );
		level.cornfieldSpawnpoints[ 1 ].radius = 32;
		level.cornfieldSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 1 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 2 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 2 ].origin = ( 7691, -395, -201 );
		level.cornfieldSpawnpoints[ 2 ].angles = ( 0, -131, 0 );
		level.cornfieldSpawnpoints[ 2 ].radius = 32;
		level.cornfieldSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 2 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 3 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 3 ].origin = ( 7536, -432, -199 );
		level.cornfieldSpawnpoints[ 3 ].angles = ( 0, -24, 0 );
		level.cornfieldSpawnpoints[ 3 ].radius = 32;
		level.cornfieldSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 3 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 4 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 4 ].origin = ( 13745, -336, -188 );
		level.cornfieldSpawnpoints[ 4 ].angles = ( 0, -178, 0 );
		level.cornfieldSpawnpoints[ 4 ].radius = 32;
		level.cornfieldSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 4 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 5 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 5 ].origin = ( 13758, -681, -188 );
		level.cornfieldSpawnpoints[ 5 ].angles = ( 0, -179, 0 );
		level.cornfieldSpawnpoints[ 5 ].radius = 32;
		level.cornfieldSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 5 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 6 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 6 ].origin = ( 13816, -1088, -189 );
		level.cornfieldSpawnpoints[ 6 ].angles = ( 0, -177, 0 );
		level.cornfieldSpawnpoints[ 6 ].radius = 32;
		level.cornfieldSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 6 ].script_int = 2048;
		
		level.cornfieldSpawnpoints[ 7 ] = spawnstruct();
		level.cornfieldSpawnpoints[ 7 ].origin = ( 13752, -1444, -182 );
		level.cornfieldSpawnpoints[ 7 ].angles = ( 0, -177, 0 ); 
		level.cornfieldSpawnpoints[ 7 ].radius = 32;
		level.cornfieldSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.cornfieldSpawnpoints[ 7 ].script_int = 2048;
		
		//POWER STATION
		level.powerStationSpawnpoints = [];
		level.powerStationSpawnpoints[ 0 ] = spawnstruct();
		level.powerStationSpawnpoints[ 0 ].origin = ( 11288, 7988, -550 );
		level.powerStationSpawnpoints[ 0 ].angles = ( 0, -137, 0 );
		level.powerStationSpawnpoints[ 0 ].radius = 32;
		level.powerStationSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 0 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 1 ] = spawnstruct();
		level.powerStationSpawnpoints[ 1 ].origin = ( 11284, 7760, -549 );
		level.powerStationSpawnpoints[ 1 ].angles = ( 0, 177, 0 );
		level.powerStationSpawnpoints[ 1 ].radius = 32;
		level.powerStationSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 1 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 2 ] = spawnstruct();
		level.powerStationSpawnpoints[ 2 ].origin = ( 10784, 7623, -584 );
		level.powerStationSpawnpoints[ 2 ].angles = ( 0, -10, 0 );
		level.powerStationSpawnpoints[ 2 ].radius = 32;
		level.powerStationSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 2 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 3 ] = spawnstruct();
		level.powerStationSpawnpoints[ 3 ].origin = ( 10866, 7473, -580 );
		level.powerStationSpawnpoints[ 3 ].angles = ( 0, 21, 0 );
		level.powerStationSpawnpoints[ 3 ].radius = 32;
		level.powerStationSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 3 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 4 ] = spawnstruct();
		level.powerStationSpawnpoints[ 4 ].origin = ( 10261, 8146, -580 );
		level.powerStationSpawnpoints[ 4 ].angles = ( 0, -31, 0 );
		level.powerStationSpawnpoints[ 4 ].radius = 32;
		level.powerStationSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 4 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 5 ] = spawnstruct();
		level.powerStationSpawnpoints[ 5 ].origin = ( 10595, 8055, -541 );
		level.powerStationSpawnpoints[ 5 ].angles = ( 0, -43, 0 );
		level.powerStationSpawnpoints[ 5 ].radius = 32;
		level.powerStationSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 5 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 6 ] = spawnstruct();
		level.powerStationSpawnpoints[ 6 ].origin = ( 10477, 7679, -567 );
		level.powerStationSpawnpoints[ 6 ].angles = ( 0, -9, 0 );
		level.powerStationSpawnpoints[ 6 ].radius = 32;
		level.powerStationSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 6 ].script_int = 2048;
		
		level.powerStationSpawnpoints[ 7 ] = spawnstruct();
		level.powerStationSpawnpoints[ 7 ].origin = ( 10165, 7879, -570 );
		level.powerStationSpawnpoints[ 7 ].angles = ( 0, -15, 0 );
		level.powerStationSpawnpoints[ 7 ].radius = 32;
		level.powerStationSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.powerStationSpawnpoints[ 7 ].script_int = 2048;
		
		level.houseSpawnpoints = [];
		level.houseSpawnpoints[ 0 ] = spawnstruct();
		level.houseSpawnpoints[ 0 ].origin = ( 5071, 7022, -20 );
		level.houseSpawnpoints[ 0 ].angles = ( 0, 315, 0 );
		level.houseSpawnpoints[ 0 ].radius = 32;
		level.houseSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 0 ].script_int = 2048;
		
		level.houseSpawnpoints[ 1 ] = spawnstruct();
		level.houseSpawnpoints[ 1 ].origin = ( 5358, 7034, -20 );
		level.houseSpawnpoints[ 1 ].angles = ( 0, 246, 0 );
		level.houseSpawnpoints[ 1 ].radius = 32;
		level.houseSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 1 ].script_int = 2048;
		
		level.houseSpawnpoints[ 2 ] = spawnstruct();
		level.houseSpawnpoints[ 2 ].origin = ( 5078, 6733, -20 );
		level.houseSpawnpoints[ 2 ].angles = ( 0, 56, 0 );
		level.houseSpawnpoints[ 2 ].radius = 32;
		level.houseSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 2 ].script_int = 2048;
		
		level.houseSpawnpoints[ 3 ] = spawnstruct();
		level.houseSpawnpoints[ 3 ].origin = ( 5334, 6723, -20 );
		level.houseSpawnpoints[ 3 ].angles = ( 0, 123, 0 );
		level.houseSpawnpoints[ 3 ].radius = 32;
		level.houseSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 3 ].script_int = 2048;
		
		level.houseSpawnpoints[ 4 ] = spawnstruct();
		level.houseSpawnpoints[ 4 ].origin = ( 5057, 6583, -10 );
		level.houseSpawnpoints[ 4 ].angles = ( 0, 0, 0 );
		level.houseSpawnpoints[ 4 ].radius = 32;
		level.houseSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 4 ].script_int = 2048;
		
		level.houseSpawnpoints[ 5 ] = spawnstruct();
		level.houseSpawnpoints[ 5 ].origin = ( 5305, 6591, -20 );
		level.houseSpawnpoints[ 5 ].angles = ( 0, 180, 0 );
		level.houseSpawnpoints[ 5 ].radius = 32;
		level.houseSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 5 ].script_int = 2048;
		
		level.houseSpawnpoints[ 6 ] = spawnstruct();
		level.houseSpawnpoints[ 6 ].origin = ( 5350, 6882, -20 );
		level.houseSpawnpoints[ 6 ].angles = ( 0, 180, 0 );
		level.houseSpawnpoints[ 6 ].radius = 32;
		level.houseSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 6 ].script_int = 2048;
		
		level.houseSpawnpoints[ 7 ] = spawnstruct();
		level.houseSpawnpoints[ 7 ].origin = ( 5102, 6851, -20 );
		level.houseSpawnpoints[ 7 ].angles = ( 0, 0, 0 );
		level.houseSpawnpoints[ 7 ].radius = 32;
		level.houseSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.houseSpawnpoints[ 7 ].script_int = 2048;

		level.townSpawnpoints = [];
		level.townSpawnpoints[ 0 ] = spawnstruct();
		level.townSpawnpoints[ 0 ].origin = ( 1475, -1405, -61 );
		level.townSpawnpoints[ 0 ].angles = ( 0, 79, 0 );
		level.townSpawnpoints[ 0 ].radius = 32;
		level.townSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 0 ].script_int = 2048;
		
		level.townSpawnpoints[ 1 ] = spawnstruct();
		level.townSpawnpoints[ 1 ].origin = (784.983, -482.281, -61.875);
		level.townSpawnpoints[ 1 ].angles = ( 0, 0, 0 );
		level.townSpawnpoints[ 1 ].radius = 32;
		level.townSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 1 ].script_int = 2048;
		
		level.townSpawnpoints[ 2 ] = spawnstruct();
		level.townSpawnpoints[ 2 ].origin = (1484.29, 386.917, -61.875);
		level.townSpawnpoints[ 2 ].angles = ( 0, 267, 0 );
		level.townSpawnpoints[ 2 ].radius = 32;
		level.townSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 2 ].script_int = 2048;
		
		level.townSpawnpoints[ 3 ] = spawnstruct();
		level.townSpawnpoints[ 3 ].origin = (2066.05, -483.1, -61.875);
		level.townSpawnpoints[ 3 ].angles = ( 0, 168, 0 );
		level.townSpawnpoints[ 3 ].radius = 32;
		level.townSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 3 ].script_int = 2048;
		
		level.townSpawnpoints[ 4 ] = spawnstruct();
		level.townSpawnpoints[ 4 ].origin = (1707.79, -458.352, -55.5342);
		level.townSpawnpoints[ 4 ].angles = ( 0, 180, 0 );
		level.townSpawnpoints[ 4 ].radius = 32;
		level.townSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 4 ].script_int = 2048;
		
		level.townSpawnpoints[ 5 ] = spawnstruct();
		level.townSpawnpoints[ 5 ].origin = (1486.61, -145.148, -61.875);
		level.townSpawnpoints[ 5 ].angles = ( 0, 255, 0 );
		level.townSpawnpoints[ 5 ].radius = 32;
		level.townSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 5 ].script_int = 2048;
		
		level.townSpawnpoints[ 6 ] = spawnstruct();
		level.townSpawnpoints[ 6 ].origin = (1044.67, -170.147, -55.875);
		level.townSpawnpoints[ 6 ].angles = ( 0, 324, 0 );
		level.townSpawnpoints[ 6 ].radius = 32;
		level.townSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 6 ].script_int = 2048;
		
		level.townSpawnpoints[ 7 ] = spawnstruct();
		level.townSpawnpoints[ 7 ].origin = (1273.88, -740.064, -55.875);
		level.townSpawnpoints[ 7 ].angles = ( 0, 60, 0 );
		level.townSpawnpoints[ 7 ].radius = 32;
		level.townSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.townSpawnpoints[ 7 ].script_int = 2048;

		level.farmSpawnpoints = [];
		level.farmSpawnpoints[ 0 ] = spawnstruct();
		level.farmSpawnpoints[ 0 ].origin = (7047.84, -5716.24, -48.6452);
		level.farmSpawnpoints[ 0 ].angles = ( 0, 0, 0 );
		level.farmSpawnpoints[ 0 ].radius = 32;
		level.farmSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 0 ].script_int = 2048;
		
		level.farmSpawnpoints[ 1 ] = spawnstruct();
		level.farmSpawnpoints[ 1 ].origin = (7780.54, -5534.08, 22.0331);
		level.farmSpawnpoints[ 1 ].angles = ( 0, 312, 0 );
		level.farmSpawnpoints[ 1 ].radius = 32;
		level.farmSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 1 ].script_int = 2048;
		
		level.farmSpawnpoints[ 2 ] = spawnstruct();
		level.farmSpawnpoints[ 2 ].origin = (8393.6, -5599.27, 45.5198);
		level.farmSpawnpoints[ 2 ].angles = ( 0, 210, 0 );
		level.farmSpawnpoints[ 2 ].radius = 32;
		level.farmSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 2 ].script_int = 2048;
		
		level.farmSpawnpoints[ 3 ] = spawnstruct();
		level.farmSpawnpoints[ 3 ].origin = (8435.45, -6051.42, 78.4683);
		level.farmSpawnpoints[ 3 ].angles = ( 0, 131, 0 );
		level.farmSpawnpoints[ 3 ].radius = 32;
		level.farmSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 3 ].script_int = 2048;
		
		level.farmSpawnpoints[ 4 ] = spawnstruct();
		level.farmSpawnpoints[ 4 ].origin = (7756.5, -6310.07, 117.125);
		level.farmSpawnpoints[ 4 ].angles = ( 0, 38, 0 );
		level.farmSpawnpoints[ 4 ].radius = 32;
		level.farmSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 4 ].script_int = 2048;
		
		level.farmSpawnpoints[ 5 ] = spawnstruct();
		level.farmSpawnpoints[ 5 ].origin = (7715.74, -4835.88, 37.6189);
		level.farmSpawnpoints[ 5 ].angles = ( 0, 278, 0 );
		level.farmSpawnpoints[ 5 ].radius = 32;
		level.farmSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 5 ].script_int = 2048;
		
		level.farmSpawnpoints[ 6 ] = spawnstruct();
		level.farmSpawnpoints[ 6 ].origin = (7931.78, -4819.38, 48.125);
		level.farmSpawnpoints[ 6 ].angles = ( 0, 291, 0 );
		level.farmSpawnpoints[ 6 ].radius = 32;
		level.farmSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 6 ].script_int = 2048;
		
		level.farmSpawnpoints[ 7 ] = spawnstruct();
		level.farmSpawnpoints[ 7 ].origin = (8474.06, -5218, 48.125);
		level.farmSpawnpoints[ 7 ].angles = ( 0, 215, 0 );
		level.farmSpawnpoints[ 7 ].radius = 32;
		level.farmSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.farmSpawnpoints[ 7 ].script_int = 2048;
	}
	else if ( level.script == "zm_highrise" )
	{
		//spawnpoints here
	}
	else if ( level.script == "zm_prison" )
	{
		level.docksSpawnpoints = [];
		level.docksSpawnpoints[ 0 ] = spawnstruct();
		level.docksSpawnpoints[ 0 ].origin = ( -335, 5512, -71 );
		level.docksSpawnpoints[ 0 ].angles = ( 0, -169, 0 );
		level.docksSpawnpoints[ 0 ].radius = 32;
		level.docksSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 0 ].script_int = 2048;
		
		level.docksSpawnpoints[ 1 ] = spawnstruct();
		level.docksSpawnpoints[ 1 ].origin = ( -589, 5452, -71 );
		level.docksSpawnpoints[ 1 ].angles = ( 0, -78, 0 );
		level.docksSpawnpoints[ 1 ].radius = 32;
		level.docksSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 1 ].script_int = 2048;
		
		level.docksSpawnpoints[ 2 ] = spawnstruct();
		level.docksSpawnpoints[ 2 ].origin = ( -1094, 5426, -71 );
		level.docksSpawnpoints[ 2 ].angles = ( 0, 170, 0 );
		level.docksSpawnpoints[ 2 ].radius = 32;
		level.docksSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 2 ].script_int = 2048;
		
		level.docksSpawnpoints[ 3 ] = spawnstruct();
		level.docksSpawnpoints[ 3 ].origin = ( -1200, 5882, -71 );
		level.docksSpawnpoints[ 3 ].angles = ( 0, -107, 0 );
		level.docksSpawnpoints[ 3 ].radius = 32;
		level.docksSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 3 ].script_int = 2048;
		
		level.docksSpawnpoints[ 4 ] = spawnstruct();
		level.docksSpawnpoints[ 4 ].origin = ( 669, 6785, 209 );
		level.docksSpawnpoints[ 4 ].angles = ( 0, -143, 0 );
		level.docksSpawnpoints[ 4 ].radius = 32;
		level.docksSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 4 ].script_int = 2048;
		
		level.docksSpawnpoints[ 5 ] = spawnstruct();
		level.docksSpawnpoints[ 5 ].origin = ( 476, 6774, 196 );
		level.docksSpawnpoints[ 5 ].angles = ( 0, -90, 0 );
		level.docksSpawnpoints[ 5 ].radius = 32;
		level.docksSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 5 ].script_int = 2048;
		
		level.docksSpawnpoints[ 6 ] = spawnstruct();
		level.docksSpawnpoints[ 6 ].origin = ( 699, 6562, 208 );
		level.docksSpawnpoints[ 6 ].angles = ( 0, 159, 0 );
		level.docksSpawnpoints[ 6 ].radius = 32;
		level.docksSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 6 ].script_int = 2048;
		
		level.docksSpawnpoints[ 7 ] = spawnstruct();
		level.docksSpawnpoints[ 7 ].origin = ( 344, 6472, 264 );
		level.docksSpawnpoints[ 7 ].angles = ( 0, 26, 0 );
		level.docksSpawnpoints[ 7 ].radius = 32;
		level.docksSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.docksSpawnpoints[ 7 ].script_int = 2048;
		
		level.cellblockSpawnpoints = [];
		level.cellblockSpawnpoints[ 0 ] = spawnstruct();
		level.cellblockSpawnpoints[ 0 ].origin = ( 954, 10521, 1338 );
		level.cellblockSpawnpoints[ 0 ].angles = ( 0, 12, 0 );
		level.cellblockSpawnpoints[ 0 ].radius = 32;
		level.cellblockSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 0 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 1 ] = spawnstruct();
		level.cellblockSpawnpoints[ 1 ].origin = ( 977, 10649, 1338 );
		level.cellblockSpawnpoints[ 1 ].angles = ( 0, 45, 0 );
		level.cellblockSpawnpoints[ 1 ].radius = 32;
		level.cellblockSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 1 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 2 ] = spawnstruct();
		level.cellblockSpawnpoints[ 2 ].origin = ( 1118, 10498, 1338 );
		level.cellblockSpawnpoints[ 2 ].angles = ( 0, 90, 0 );
		level.cellblockSpawnpoints[ 2 ].radius = 32;
		level.cellblockSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 2 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 3 ] = spawnstruct();
		level.cellblockSpawnpoints[ 3 ].origin = ( 1435, 10591, 1338 );
		level.cellblockSpawnpoints[ 3 ].angles = ( 0, 90, 0 );
		level.cellblockSpawnpoints[ 3 ].radius = 32;
		level.cellblockSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 3 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 4 ] = spawnstruct();
		level.cellblockSpawnpoints[ 4 ].origin = ( 1917, 10376, 1338 );
		level.cellblockSpawnpoints[ 4 ].angles = ( 0, 69, 0 );
		level.cellblockSpawnpoints[ 4 ].radius = 32;
		level.cellblockSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 4 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 5 ] = spawnstruct();
		level.cellblockSpawnpoints[ 5 ].origin = ( 2025, 10362, 1338 );
		level.cellblockSpawnpoints[ 5 ].angles = ( 0, 121, 0 );
		level.cellblockSpawnpoints[ 5 ].radius = 32;
		level.cellblockSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 5 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 6 ] = spawnstruct();
		level.cellblockSpawnpoints[ 6 ].origin = ( 2090, 10426, 1338 );
		level.cellblockSpawnpoints[ 6 ].angles = ( 0, 121, 0 );
		level.cellblockSpawnpoints[ 6 ].radius = 32;
		level.cellblockSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 6 ].script_int = 2048;
		
		level.cellblockSpawnpoints[ 7 ] = spawnstruct();
		level.cellblockSpawnpoints[ 7 ].origin = ( 1758, 10562, 1338 );
		level.cellblockSpawnpoints[ 7 ].angles = ( 0, 180, 0 );
		level.cellblockSpawnpoints[ 7 ].radius = 32;
		level.cellblockSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.cellblockSpawnpoints[ 7 ].script_int = 2048;
		
		level.rooftopSpawnpoints = [];
		level.rooftopSpawnpoints[ 0 ] = spawnstruct();
		level.rooftopSpawnpoints[ 0 ].origin = ( 2708, 9596, 1714 );
		level.rooftopSpawnpoints[ 0 ].angles = ( 0, 328, 0 );
		level.rooftopSpawnpoints[ 0 ].radius = 32;
		level.rooftopSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 0 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 1 ] = spawnstruct();
		level.rooftopSpawnpoints[ 1 ].origin = ( 2875, 9596, 1706 );
		level.rooftopSpawnpoints[ 1 ].angles = ( 0, 275, 0 );
		level.rooftopSpawnpoints[ 1 ].radius = 32;
		level.rooftopSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 1 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 2 ] = spawnstruct();
		level.rooftopSpawnpoints[ 2 ].origin = ( 3125.5, 9461.5, 1706 );
		level.rooftopSpawnpoints[ 2 ].angles = ( 0, 70, 0 );
		level.rooftopSpawnpoints[ 2 ].radius = 32;
		level.rooftopSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 2 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 3 ] = spawnstruct();
		level.rooftopSpawnpoints[ 3 ].origin = ( 3408, 9512.5, 1706 );
		level.rooftopSpawnpoints[ 3 ].angles = ( 0, 133, 0 );
		level.rooftopSpawnpoints[ 3 ].radius = 32;
		level.rooftopSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 3 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 4 ] = spawnstruct();
		level.rooftopSpawnpoints[ 4 ].origin = ( 3421, 9803.5, 1706 );
		level.rooftopSpawnpoints[ 4 ].angles = ( 0, 229, 0 );
		level.rooftopSpawnpoints[ 4 ].radius = 32;
		level.rooftopSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 4 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 5 ] = spawnstruct();
		level.rooftopSpawnpoints[ 5 ].origin = ( 3168, 9807, 1706 );
		level.rooftopSpawnpoints[ 5 ].angles = ( 0, 295, 0 );
		level.rooftopSpawnpoints[ 5 ].radius = 32;
		level.rooftopSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 5 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 6 ] = spawnstruct();
		level.rooftopSpawnpoints[ 6 ].origin = ( 2900, 9731.5, 1706 );
		level.rooftopSpawnpoints[ 6 ].angles = ( 0, 68, 0 );
		level.rooftopSpawnpoints[ 6 ].radius = 32;
		level.rooftopSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 6 ].script_int = 2048;
		
		level.rooftopSpawnpoints[ 7 ] = spawnstruct();
		level.rooftopSpawnpoints[ 7 ].origin = ( 2589, 9731.5, 1706 );
		level.rooftopSpawnpoints[ 7 ].angles = ( 0, 36, 0 );
		level.rooftopSpawnpoints[ 7 ].radius = 32;
		level.rooftopSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.rooftopSpawnpoints[ 7 ].script_int = 2048;
	}
	else if( level.script == "zm_buried" )
	{
		level.mazeSpawnpoints = [];
		level.mazeSpawnpoints[ 0 ] = spawnstruct();
		level.mazeSpawnpoints[ 0 ].origin = (6686.14, 870.338, 108.125);
		level.mazeSpawnpoints[ 0 ].angles = ( 0, 190, 0 );
		level.mazeSpawnpoints[ 0 ].radius = 32;
		level.mazeSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 0 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 1 ] = spawnstruct();
		level.mazeSpawnpoints[ 1 ].origin = (6929.56, 789.857, 108.125);
		level.mazeSpawnpoints[ 1 ].angles = ( 0, 280, 0 );
		level.mazeSpawnpoints[ 1 ].radius = 32;
		level.mazeSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 1 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 2 ] = spawnstruct();
		level.mazeSpawnpoints[ 2 ].origin = (6053.2, 568.066, 5.60614);
		level.mazeSpawnpoints[ 2 ].angles = ( 0, 180, 0 );
		level.mazeSpawnpoints[ 2 ].radius = 32;
		level.mazeSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 2 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 3 ] = spawnstruct();
		level.mazeSpawnpoints[ 3 ].origin = (6376.86, 578.717, 108.125);
		level.mazeSpawnpoints[ 3 ].angles = ( 0, 180, 0 );
		level.mazeSpawnpoints[ 3 ].radius = 32;
		level.mazeSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 3 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 4 ] = spawnstruct();
		level.mazeSpawnpoints[ 4 ].origin = (5113.05, 567.025, 11.132);
		level.mazeSpawnpoints[ 4 ].angles = ( 0, 180, 0 );
		level.mazeSpawnpoints[ 4 ].radius = 32;
		level.mazeSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 4 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 5 ] = spawnstruct();
		level.mazeSpawnpoints[ 5 ].origin = (3742.08, 142.653, 4.125);
		level.mazeSpawnpoints[ 5 ].angles = ( 0, 50, 0 );
		level.mazeSpawnpoints[ 5 ].radius = 32;
		level.mazeSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 5 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 6 ] = spawnstruct();
		level.mazeSpawnpoints[ 6 ].origin = (3715.18, 1001.04, 4.125);
		level.mazeSpawnpoints[ 6 ].angles = ( 0, 310, 0 );
		level.mazeSpawnpoints[ 6 ].radius = 32;
		level.mazeSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 6 ].script_int = 2048;
		
		level.mazeSpawnpoints[ 7 ] = spawnstruct();
		level.mazeSpawnpoints[ 7 ].origin = (3964.82, 570.998, 4.125);
		level.mazeSpawnpoints[ 7 ].angles = ( 0, 0, 0 );
		level.mazeSpawnpoints[ 7 ].radius = 32;
		level.mazeSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.mazeSpawnpoints[ 7 ].script_int = 2048;
	}
	else if( level.script == "zm_tomb" )
	{
		level.trenchesSpawnpoints = [];
		level.trenchesSpawnpoints[ 0 ] = spawnstruct();
		level.trenchesSpawnpoints[ 0 ].origin = (2096.84, 4961.77, -299.875);
		level.trenchesSpawnpoints[ 0 ].angles = ( 0, 300, 0 );
		level.trenchesSpawnpoints[ 0 ].radius = 32;
		level.trenchesSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 0 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 1 ] = spawnstruct();
		level.trenchesSpawnpoints[ 1 ].origin = (2050.48, 4656.4, -299.875);
		level.trenchesSpawnpoints[ 1 ].angles = ( 0, 47, 0 );
		level.trenchesSpawnpoints[ 1 ].radius = 32;
		level.trenchesSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 1 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 2 ] = spawnstruct();
		level.trenchesSpawnpoints[ 2 ].origin = (2340.41, 4614.65, -301.92);
		level.trenchesSpawnpoints[ 2 ].angles = ( 0, 134, 0 );
		level.trenchesSpawnpoints[ 2 ].radius = 32;
		level.trenchesSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 2 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 3 ] = spawnstruct();
		level.trenchesSpawnpoints[ 3 ].origin = (2328.26, 4904.16, -299.875);
		level.trenchesSpawnpoints[ 3 ].angles = ( 0, 210, 0 );
		level.trenchesSpawnpoints[ 3 ].radius = 32;
		level.trenchesSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 3 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 4 ] = spawnstruct();
		level.trenchesSpawnpoints[ 4 ].origin = (2554.91, 5155.65, -375.875);
		level.trenchesSpawnpoints[ 4 ].angles = ( 0, 50, 0 );
		level.trenchesSpawnpoints[ 4 ].radius = 32;
		level.trenchesSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 4 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 5 ] = spawnstruct();
		level.trenchesSpawnpoints[ 5 ].origin = (2895.25, 5159.11, -375.875);
		level.trenchesSpawnpoints[ 5 ].angles = ( 0, 137, 0 );
		level.trenchesSpawnpoints[ 5 ].radius = 32;
		level.trenchesSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 5 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 6 ] = spawnstruct();
		level.trenchesSpawnpoints[ 6 ].origin = (2878.78, 5451.09, -367.875);
		level.trenchesSpawnpoints[ 6 ].angles = ( 0, 220, 0 );
		level.trenchesSpawnpoints[ 6 ].radius = 32;
		level.trenchesSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 6 ].script_int = 2048;
		
		level.trenchesSpawnpoints[ 7 ] = spawnstruct();
		level.trenchesSpawnpoints[ 7 ].origin = (2572.78, 5430.02, -367.875);
		level.trenchesSpawnpoints[ 7 ].angles = ( 0, 310, 0 );
		level.trenchesSpawnpoints[ 7 ].radius = 32;
		level.trenchesSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.trenchesSpawnpoints[ 7 ].script_int = 2048;

		level.excavationSpawnpoints = [];
		level.excavationSpawnpoints[ 0 ] = spawnstruct();
		level.excavationSpawnpoints[ 0 ].origin = ( 1392, 802, 104 );
		level.excavationSpawnpoints[ 0 ].angles = ( 0, 226, 0 );
		level.excavationSpawnpoints[ 0 ].radius = 32;
		level.excavationSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 0 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 1 ] = spawnstruct();
		level.excavationSpawnpoints[ 1 ].origin = ( 480, 800, 83 );
		level.excavationSpawnpoints[ 1 ].angles = ( 0, 329, 0 );
		level.excavationSpawnpoints[ 1 ].radius = 32;
		level.excavationSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 1 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 2 ] = spawnstruct();
		level.excavationSpawnpoints[ 2 ].origin = ( -778, 936, 133 );
		level.excavationSpawnpoints[ 2 ].angles = ( 0, 320, 0 );
		level.excavationSpawnpoints[ 2 ].radius = 32;
		level.excavationSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 2 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 3 ] = spawnstruct();
		level.excavationSpawnpoints[ 3 ].origin = ( -1914, 512, 94 );
		level.excavationSpawnpoints[ 3 ].angles = ( 0, 11, 0 );
		level.excavationSpawnpoints[ 3 ].radius = 32;
		level.excavationSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 3 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 4 ] = spawnstruct();
		level.excavationSpawnpoints[ 4 ].origin = ( -1763, -319, 114 );
		level.excavationSpawnpoints[ 4 ].angles = ( 0, 24, 0 );
		level.excavationSpawnpoints[ 4 ].radius = 32;
		level.excavationSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 4 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 5 ] = spawnstruct();
		level.excavationSpawnpoints[ 5 ].origin = ( -907, -382, 100 );
		level.excavationSpawnpoints[ 5 ].angles = ( 0, 33, 0 );
		level.excavationSpawnpoints[ 5 ].radius = 32;
		level.excavationSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 5 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 6 ] = spawnstruct();
		level.excavationSpawnpoints[ 6 ].origin = ( 742, -945, 66 );
		level.excavationSpawnpoints[ 6 ].angles = ( 0, 131, 0 );
		level.excavationSpawnpoints[ 6 ].radius = 32;
		level.excavationSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 6 ].script_int = 2048;
		
		level.excavationSpawnpoints[ 7 ] = spawnstruct();
		level.excavationSpawnpoints[ 7 ].origin = ( 1286, -266, 99 );
		level.excavationSpawnpoints[ 7 ].angles = ( 0, 147, 0 );
		level.excavationSpawnpoints[ 7 ].radius = 32;
		level.excavationSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.excavationSpawnpoints[ 7 ].script_int = 2048;

		level.tankSpawnpoints = [];
		level.tankSpawnpoints[ 0 ] = spawnstruct();
		level.tankSpawnpoints[ 0 ].origin = ( 308, -2021, 247 );
		level.tankSpawnpoints[ 0 ].angles = ( 0, 129, 0 );
		level.tankSpawnpoints[ 0 ].radius = 32;
		level.tankSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 0 ].script_int = 2048;
		
		level.tankSpawnpoints[ 1 ] = spawnstruct();
		level.tankSpawnpoints[ 1 ].origin = ( 1285, -2074, 168 );
		level.tankSpawnpoints[ 1 ].angles = ( 0, 198, 0 );
		level.tankSpawnpoints[ 1 ].radius = 32;
		level.tankSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 1 ].script_int = 2048;
		
		level.tankSpawnpoints[ 2 ] = spawnstruct();
		level.tankSpawnpoints[ 2 ].origin = ( 1042, -2753, 51 );
		level.tankSpawnpoints[ 2 ].angles = ( 0, 142, 0 );
		level.tankSpawnpoints[ 2 ].radius = 32;
		level.tankSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 2 ].script_int = 2048;
		
		level.tankSpawnpoints[ 3 ] = spawnstruct();
		level.tankSpawnpoints[ 3 ].origin = ( 250, -2928, 62 );
		level.tankSpawnpoints[ 3 ].angles = ( 0, 81, 0 );
		level.tankSpawnpoints[ 3 ].radius = 32;
		level.tankSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 3 ].script_int = 2048;
		
		level.tankSpawnpoints[ 4 ] = spawnstruct();
		level.tankSpawnpoints[ 4 ].origin = ( 213, -2448, 52 );
		level.tankSpawnpoints[ 4 ].angles = ( 0, 259, 0 );
		level.tankSpawnpoints[ 4 ].radius = 32;
		level.tankSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 4 ].script_int = 2048;
		
		level.tankSpawnpoints[ 5 ] = spawnstruct();
		level.tankSpawnpoints[ 5 ].origin = ( -319, -2363, 112 );
		level.tankSpawnpoints[ 5 ].angles = ( 0, 328, 0 );
		level.tankSpawnpoints[ 5 ].radius = 32;
		level.tankSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 5 ].script_int = 2048;
		
		level.tankSpawnpoints[ 6 ] = spawnstruct();
		level.tankSpawnpoints[ 6 ].origin = ( 743, -2282, 51 );
		level.tankSpawnpoints[ 6 ].angles = ( 0, 350, 0 );
		level.tankSpawnpoints[ 6 ].radius = 32;
		level.tankSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 6 ].script_int = 2048;
		
		level.tankSpawnpoints[ 7 ] = spawnstruct();
		level.tankSpawnpoints[ 7 ].origin = ( 633, -2023, 235 );
		level.tankSpawnpoints[ 7 ].angles = ( 0, 143, 0 );
		level.tankSpawnpoints[ 7 ].radius = 32;
		level.tankSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.tankSpawnpoints[ 7 ].script_int = 2048;

		level.crazyplaceSpawnpoints = [];
		level.crazyplaceSpawnpoints[ 0 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 0 ].origin = ( 11164, -6942, -351 );
		level.crazyplaceSpawnpoints[ 0 ].angles = ( 0, 223, 0 );
		level.crazyplaceSpawnpoints[ 0 ].radius = 32;
		level.crazyplaceSpawnpoints[ 0 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 0 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 1 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 1 ].origin = ( 11301, -7129, -351 );
		level.crazyplaceSpawnpoints[ 1 ].angles = ( 0, 206, 0 );
		level.crazyplaceSpawnpoints[ 1 ].radius = 32;
		level.crazyplaceSpawnpoints[ 1 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 1 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 2 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 2 ].origin = ( 9531, -7056, -351 );
		level.crazyplaceSpawnpoints[ 2 ].angles = ( 0, 282, 0 );
		level.crazyplaceSpawnpoints[ 2 ].radius = 32;
		level.crazyplaceSpawnpoints[ 2 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 2 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 3 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 3 ].origin = ( 9683, -7028, -345 );
		level.crazyplaceSpawnpoints[ 3 ].angles = ( 0, 255, 0 );
		level.crazyplaceSpawnpoints[ 3 ].radius = 32;
		level.crazyplaceSpawnpoints[ 3 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 3 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 4 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 4 ].origin = ( 9469, -8501, -403 );
		level.crazyplaceSpawnpoints[ 4 ].angles = ( 0, 349, 0 );
		level.crazyplaceSpawnpoints[ 4 ].radius = 32;
		level.crazyplaceSpawnpoints[ 4 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 4 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 5 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 5 ].origin = ( 9480, -8635, -397 );
		level.crazyplaceSpawnpoints[ 5 ].angles = ( 0, 9, 0 );
		level.crazyplaceSpawnpoints[ 5 ].radius = 32;
		level.crazyplaceSpawnpoints[ 5 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 5 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 6 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 6 ].origin = ( 11198, -8728, -413 );
		level.crazyplaceSpawnpoints[ 6 ].angles = ( 0, 152, 0 );
		level.crazyplaceSpawnpoints[ 6 ].radius = 32;
		level.crazyplaceSpawnpoints[ 6 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 6 ].script_int = 2048;
		
		level.crazyplaceSpawnpoints[ 7 ] = spawnstruct();
		level.crazyplaceSpawnpoints[ 7 ].origin = ( 11318, -8613, -412 );
		level.crazyplaceSpawnpoints[ 7 ].angles = ( 0, 150, 0 );
		level.crazyplaceSpawnpoints[ 7 ].radius = 32;
		level.crazyplaceSpawnpoints[ 7 ].script_noteworthy = "initial_spawn";
		level.crazyplaceSpawnpoints[ 7 ].script_int = 2048;
	}
}

init_barriers_for_custom_maps() //custom function
{
	if(level.script == "zm_transit" && isDefined(level.customMap) && level.customMap != "vanilla")
	{
		//DINER CLIPS
		dinerclip1 = spawn("script_model", (-3952,-6957,-67));
		dinerclip1 setModel("collision_player_wall_256x256x10");
		dinerclip1 rotateTo((0,82,0), .1);

		dinerclip2 = spawn("script_model", (-4173,-6679,-60));
		dinerclip2 setModel("collision_player_wall_512x512x10");
		dinerclip2 rotateTo((0,0,0), .1);

		dinerclip3 = spawn("script_model", (-5073,-6732,-59));
		dinerclip3 setModel("collision_player_wall_512x512x10");
		dinerclip3 rotateTo((0,328,0), .1);

		dinerclip4 = spawn("script_model", (-6104,-6490,-38));
		dinerclip4 setModel("collision_player_wall_512x512x10");
		dinerclip4 rotateTo((0,2,0), .1);

		dinerclip5 = spawn("script_model", (-5850,-6486,-38));
		dinerclip5 setModel("collision_player_wall_256x256x10");
		dinerclip5 rotateTo((0,0,0), .1);

		dinerclip6 = spawn("script_model", (-5624,-6406,-40));
		dinerclip6 setModel("collision_player_wall_256x256x10");
		dinerclip6 rotateTo((0,226,0), .1);

		dinerclip7 = spawn("script_model", (-6348,-6886,-55));
		dinerclip7 setModel("collision_player_wall_512x512x10");
		dinerclip7 rotateTo((0,98,0), .1);

		//TUNNEL BARRIERS
		tunnelbarrier1 = spawn("script_model", (-11250,-520,255));
		tunnelbarrier1 setModel("veh_t6_civ_movingtrk_cab_dead");
		tunnelbarrier1 rotateTo((0,172,0),.1);
		tunnelclip1 = spawn("script_model", (-11250,-580,255));
		tunnelclip1 setModel("collision_player_wall_256x256x10");
		tunnelclip1 rotateTo((0,180,0), .1);
		tunnelclip2 = spawn("script_model", (-11506,-580,255));
		tunnelclip2 setModel("collision_player_wall_256x256x10");
		tunnelclip2 rotateTo((0,180,0), .1);

		tunnelbarrier4 = spawn("script_model", (-10770,-3240,255));
		tunnelbarrier4 setModel("veh_t6_civ_movingtrk_cab_dead");
		tunnelbarrier4 rotateTo((0,214,0),.1);
		tunnelclip3 = spawn("script_model", (-10840,-3190,255));
		tunnelclip3 setModel("collision_player_wall_256x256x10");
		tunnelclip3 rotateTo((0,214,0), .1);

		    //tunnelclip3 DisconnectPaths();

		//HOUSE BARRIERS
		housebarrier1 = spawn("script_model", (5568,6336,-70));
		housebarrier1 setModel("collision_player_wall_512x512x10");
		housebarrier1 rotateTo((0,266,0),.1);
		housebarrier1 ConnectPaths();

		housebarrier2 = spawn("script_model", (5074,7089,-24));
		housebarrier2 setModel("collision_player_wall_128x128x10");
		housebarrier2 rotateTo((0,0,0),.1);
		housebarrier2 ConnectPaths();

		housebarrier3 = spawn("script_model", (4985,5862,-64));
		housebarrier3 setModel("collision_player_wall_512x512x10");
		housebarrier3 rotateTo((0,159,0),.1);
		housebarrier3 ConnectPaths();

		housebarrier4 = spawn("script_model", (5207,5782,-64));
		housebarrier4 setModel("collision_player_wall_512x512x10");
		housebarrier4 rotateTo((0,159,0),.1);
		housebarrier4 ConnectPaths();

		housebarrier5 = spawn("script_model", (4819,6475,-64));
		housebarrier5 setModel("collision_player_wall_512x512x10");
		housebarrier5 rotateTo((0,258,0),.1);
		housebarrier5 ConnectPaths();

		housebarrier6 = spawn("script_model", (4767,6200,-64));
		housebarrier6 setModel("collision_player_wall_512x512x10");
		housebarrier6 rotateTo((0,258,0),.1);
		housebarrier6 ConnectPaths();

		housebarrier7 = spawn("script_model", (5459,5683,-64));
		housebarrier7 setModel("collision_player_wall_512x512x10");
		housebarrier7 rotateTo((0,159,0),.1);
		housebarrier7 ConnectPaths();
		
		housebush1 = spawn("script_model", (5548.5, 6358, -72));
		housebush1 setModel("t5_foliage_bush05");
		housebush1 rotateTo((0,271,0),.1);
		
		housebush2 = spawn("script_model", (5543.79, 6269.37, -64.75));
		housebush2 setModel("t5_foliage_bush05");
		housebush2 rotateTo((0,-45,0),.1);
		
		housebush3 = spawn("script_model", (5553.23, 6446, -76));
		housebush3 setModel("t5_foliage_bush05");
		housebush3 rotateTo((0,90,0),.1);
		
		housebush4 = spawn("script_model", (5534, 6190.8, -64));
		housebush4 setModel("t5_foliage_bush05");
		housebush4 rotateTo((0,180,0),.1);
		
		housebush5 = spawn("script_model", (5565.1, 5661, -64));
		housebush5 setModel("t5_foliage_bush05");
		housebush5 rotateTo((0,-45,0),.1);
		
		housebush6 = spawn("script_model", (5380.4, 5738, -64));
		housebush6 setModel("t5_foliage_bush05");
		housebush6 rotateTo((0,80,0),.1);
		
		housebush7 = spawn("script_model", (5467, 5702, -64));
		housebush7 setModel("t5_foliage_bush05");
		housebush7 rotateTo((0,40,0),.1);
		
		housebush8 = spawn("script_model", (5323.1, 5761.7, -64));
		housebush8 setModel("t5_foliage_bush05");
		housebush8 rotateTo((0,120,0),.1);
		
		housebush9 = spawn("script_model", (5261, 5787.5, -64));
		housebush9 setModel("t5_foliage_bush05");
		housebush9 rotateTo((0,150,0),.1);
		
		housebush10 = spawn("script_model", (5199, 5813.5, -64));
		housebush10 setModel("t5_foliage_bush05");
		housebush10 rotateTo((0,230,0),.1);
		
		housebush11 = spawn("script_model", (5137, 5839.5, -64)); //-62, +26
		housebush11 setModel("t5_foliage_bush05");
		housebush11 rotateTo((0,0,0),.1);
		
		housebush12 = spawn("script_model", (5075, 5865.5, -64));
		housebush12 setModel("t5_foliage_bush05");
		housebush12 rotateTo((0,70,0),.1);
		
		housebush13 = spawn("script_model", (5013, 5891.5, -64));
		housebush13 setModel("t5_foliage_bush05");
		housebush13 rotateTo((0,170,0),.1);
		
		housebush14 = spawn("script_model", (4951, 5917.5, -64));
		housebush14 setModel("t5_foliage_bush05");
		housebush14 rotateTo((0,0,0),.1);
		
		housebush15 = spawn("script_model", (4889, 5943.5, -64));
		housebush15 setModel("t5_foliage_bush05");
		housebush15 rotateTo((0,245,0),.1);
		
		housebush16 = spawn("script_model", (4810, 5926.5, -64));
		housebush16 setModel("t5_foliage_bush05");
		housebush16 rotateTo((0,53,0),.1);
		
		housebush17 = spawn("script_model", (4762, 6069, -64));
		housebush17 setModel("t5_foliage_bush05");
		housebush17 rotateTo((0,100,0),.1);
		
		housebush18 = spawn("script_model", (4777, 6149, -64)); //+15, +80
		housebush18 setModel("t5_foliage_bush05");
		housebush18 rotateTo((0,200,0),.1);
		
		housebush19 = spawn("script_model", (4792, 6229, -64));
		housebush19 setModel("t5_foliage_bush05");
		housebush19 rotateTo((0,100,0),.1);
		
		housebush20 = spawn("script_model", (4807, 6309, -64));
		housebush20 setModel("t5_foliage_bush05");
		housebush20 rotateTo((0,200,0),.1);
		
		housebush21 = spawn("script_model", (4822, 6389, -64));
		housebush21 setModel("t5_foliage_bush05");
		housebush21 rotateTo((0,100,0),.1);
		
		housebush22 = spawn("script_model", (4837, 6469, -64));
		housebush22 setModel("t5_foliage_bush05");
		housebush22 rotateTo((0,200,0),.1);
		
		housebush23 = spawn("script_model", (4852, 6549, -64));
		housebush23 setModel("t5_foliage_bush05");
		housebush23 rotateTo((0,100,0),.1);
		
		housebush24 = spawn("script_model", (4867, 6629, -64));
		housebush24 setModel("t5_foliage_bush05");
		housebush24 rotateTo((0,200,0),.1);
		
		housebush25 = spawn("script_model", (5557.4, 6524.5, -80));
		housebush25 setModel("t5_foliage_bush05");
		housebush25 rotateTo((0,200,0),.1);
		
		housebush26 = spawn("script_model", (5078.68, 7172.37, -64));
		housebush26 setModel("t5_foliage_bush05");
		housebush26 rotateTo((0,234,0),.1);
		
		housebush27 = spawn("script_model", (5017, 7130.22, -64));
		housebush27 setModel("t5_foliage_bush05");
		housebush27 rotateTo((0,45,0),.1);
		
		housebush28 = spawn("script_model", (5154.25, 7133.65, -64));
		housebush28 setModel("t5_foliage_bush05");
		housebush28 rotateTo((0,130,0),.1);
		
		housebush29 = spawn("script_model", (5105.25, 7166.65, -64));
		housebush29 setModel("t5_foliage_bush05");
		housebush29 rotateTo((0,292,0),.1);

		//POWER STATION BARRIERS
		powerbarrier1 = spawn("script_model", (9965,8133,-556));
		powerbarrier1 setModel("veh_t6_civ_60s_coupe_dead");
		powerbarrier1 rotateTo((15,5,0),.1);
		powerclip1 = spawn("script_model", (9955,8105,-575));
		powerclip1 setModel("collision_player_wall_256x256x10");
		powerclip1 rotateTo((0,0,0),.1);

		powerbarrier2 = spawn("script_model", (10056,8350,-584));
		powerbarrier2 setModel("veh_t6_civ_bus_zombie");
		powerbarrier2 rotateTo((0,340,0),.1);
		powerbarrier2 NotSolid();
		powerclip2 = spawn("script_model", (10267,8194,-556));
		powerclip2 setModel("collision_player_wall_256x256x10");
		powerclip2 rotateTo((0,340,0),.1);
		powerclip3 = spawn("script_model", (10409,8220,-181));
		powerclip3 setModel("collision_player_wall_512x512x10");
		powerclip3 rotateTo((0,250,0),.1);
		powerclip4 = spawn("script_model", (10409,8220,-556));
		powerclip4 setModel("collision_player_wall_128x128x10");
		powerclip4 rotateTo((0,250,0),.1);

		powerbarrier3 = spawn("script_model", (10281,7257,-575));
		powerbarrier3 setModel("veh_t6_civ_microbus_dead");
		powerbarrier3 rotateTo((0,13,0),.1);
		powerclip4 = spawn("script_model", (10268,7294,-569));
		powerclip4 setModel("collision_player_wall_256x256x10");
		powerclip4 rotateTo((0,13,0),.1);

		powerbarrier4 = spawn("script_model", (10100,7238,-575));
		powerbarrier4 setModel("veh_t6_civ_60s_coupe_dead");
		powerbarrier4 rotateTo((0,52,0),.1);
		powerclip5 = spawn("script_model", (10170,7292,-505));
		powerclip5 setModel("collision_player_wall_128x128x10");
		powerclip5 rotateTo((0,140,0),.1);
		powerclip6 = spawn("script_model", (10030,7216,-569));
		powerclip6 setModel("collision_player_wall_256x256x10");
		powerclip6 rotateTo((0,49,0),.1);

		powerclip7 = spawn("script_model", (10563,8630,-344));
		powerclip7 setModel("collision_player_wall_256x256x10");
		powerclip7 rotateTo((0,270,0),.1);

		//CORNFIELD BARRIERS
		cornfieldbarrier1 = spawn("script_model", (10190,135,-159));
		cornfieldbarrier1 setModel("veh_t6_civ_movingtrk_cab_dead");
		cornfieldbarrier1 rotateTo((0,172,0),.1);
		cornfieldclip1 = spawn("script_model", (10100,100,-159));
		cornfieldclip1 setModel("collision_player_wall_512x512x10");
		cornfieldclip1 rotateTo((0,172,0),.1);

		cornfieldbarrier2 = spawn("script_model", (10100,-1800,-217));
		cornfieldbarrier2 setModel("veh_t6_civ_bus_zombie");
		cornfieldbarrier2 rotateTo((0,126,0),.1);
		cornfieldbarrier2 NotSolid();
		cornfieldclip1 = spawn("script_model", (10045,-1607,-181));
		cornfieldclip1 setModel("collision_player_wall_512x512x10");
		cornfieldclip1 rotateTo((0,126,0),.1);
	}
	if(level.script == "zm_highrise" && level.customMap != "vanilla")
	{
		//BUILDING1TOP BARRIERS
		collision2 = Spawn( "script_model", (1195.34, 1281.47, 3392.13) + (0,50,0) );
		collision2 RotateTo((0,90,0), .1);
		collision2 SetModel( "zm_collision_perks1" );
		collision3 = Spawn( "script_model", (1195.34, 1281.47, 3392.13) + (0,-50,0) );
		collision3 RotateTo((0,90,0), .1);
		collision3 SetModel( "zm_collision_perks1" );
		building1topbarrier1 = Spawn("script_model", (2179.74, 1110.85, 3206.64));
		building1topbarrier1 SetModel("collision_player_wall_256x256x10");
		building1topbarrier1 RotateTo((0,0,0),.1);
		building1topbarrier2 = Spawn("script_model", (2248.78, 1541.87, 3350));
		building1topbarrier2 SetModel("collision_player_wall_256x256x10");
		building1topbarrier2 RotateTo((0,90,0),.1);
		elevatorbarrier1 = Spawn("script_model", (1651.49, 2168.44, 3392.01) + (0,0,32));
		elevatorbarrier1 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier1 RotateTo((0,0,0),.1);
		elevatorbarrier2 = Spawn("script_model", (1958.84, 1676.59, 3391.99) + (0,0,32));
		elevatorbarrier2 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier2 RotateTo((0,0,0),.1);
		elevatorbarrier3 = Spawn("script_model", (1957.68, 1676.22, 3216.03) + (0,0,32));
		elevatorbarrier3 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier3 RotateTo((0,0,0),.1);
		elevatorbarrier4 = Spawn("script_model", (1475.31, 1218.09, 3218.16) + (0,0,32));
		elevatorbarrier4 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier4 RotateTo((0,90,0),.1);
		elevatorbarrier5 = Spawn("script_model", (1647.22, 2171.76, 3215.57) + (0,0,32));
		elevatorbarrier5 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier5 RotateTo((0,0,0),.1);
		elevatorbarrier6 = Spawn("script_model", (1647.7, 2167.82, 3040.09) + (0,0,32));
		elevatorbarrier6 SetModel("collision_player_wall_64x64x10");
		elevatorbarrier6 RotateTo((0,0,0),.1);
	}
	if(level.script == "zm_buried" && level.customMap != "vanilla")
	{
		mansion_clip1 = Spawn( "script_model", (3546.72, 264.696, 47.2424) + (0,0,128) );
		mansion_clip1 RotateTo((0,90,0), .1);
		mansion_clip1 SetModel( "collision_player_wall_256x256x10" );
		mansion_clip2 = Spawn( "script_model", (3470.43, 1064.11, 61.5909) + (0,0,128) );
		mansion_clip2 RotateTo((0,90,0), .1);
		mansion_clip2 SetModel( "collision_player_wall_256x256x10" );
		gazebo_clip1 = Spawn( "script_model", (6500.32, 575.174, 124.087) + (0,0,64) );
		gazebo_clip1 RotateTo((0,90,0), .1);
		gazebo_clip1 SetModel( "collision_player_wall_128x128x10" );
		gazebo_clip2 = Spawn( "script_model", (6676.68, 791.984, 113.475) + (0,0,32) );
		gazebo_clip2 RotateTo((0,0,0), .1);
		gazebo_clip2 SetModel( "collision_player_wall_64x64x10" );
		gazebo_clip3 = Spawn( "script_model", (6932.09, 541.876, 116.221) + (0,0,32) );
		gazebo_clip3 RotateTo((0,90,0), .1);
		gazebo_clip3 SetModel( "collision_player_wall_64x64x10" );
	}
}

onspawnplayer( predictedspawn ) //modified function
{
	if ( !isDefined( predictedspawn ) )
	{
		predictedspawn = 0;
	}
	pixbeginevent( "ZSURVIVAL:onSpawnPlayer" );
	self.usingobj = undefined;
	self.is_zombie = 0;
	if ( isDefined( level.custom_spawnplayer ) && isDefined( self.player_initialized ) && self.player_initialized )
	{
		self [[ level.custom_spawnplayer ]]();
		return;
	}
	if ( flag( "begin_spawning" ) )
	{
		spawnpoint = maps/mp/zombies/_zm::check_for_valid_spawn_near_team( self, 1 );
	}
	if ( !isDefined( spawnpoint ) )
	{
		match_string = "";
		location = level.scr_zm_map_start_location;
		if ( ( location == "default" || location == "" ) && isDefined( level.default_start_location ) )
		{
			location = level.default_start_location;
		}
		match_string = level.scr_zm_ui_gametype + "_" + location;
		spawnpoints = [];
		if ( isDefined( level.customMap ) && level.customMap == "tunnel" )
		{
			for ( i = 0; i < level.tunnelSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.tunnelSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "diner" )
		{
			for ( i = 0; i < level.dinerSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.dinerSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "cornfield" )
		{
			for ( i = 0; i < level.cornfieldSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.cornfieldSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "power" )
		{
			for ( i = 0; i < level.powerStationSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.powerStationSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "house" )
		{
			for ( i = 0; i < level.houseSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.houseSpawnpoints[ i ];
			}
		}
		else if ( getDvar("customMap") == "town" )
		{
			for( i = 0; i < level.townSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.townSpawnpoints[ i ];
			}
		}
		else if ( getDvar("customMap") == "farm" )
		{
			for( i = 0; i < level.farmSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.farmSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "docks" )
		{
			for ( i = 0; i < level.docksSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.docksSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "cellblock" )
		{
			for ( i = 0; i < level.cellblockSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.cellblockSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "rooftop" )
		{
			for ( i = 0; i < level.rooftopSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.rooftopSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "trenches" )
		{
			for ( i = 0; i < level.trenchesSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.trenchesSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "excavation" )
		{
			for ( i = 0; i < level.excavationSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.excavationSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "tank" )
		{
			for ( i = 0; i < level.tankSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.tankSpawnpoints[ i ];
			}
		}
		else if ( isDefined( level.customMap ) && level.customMap == "crazyplace" )
		{
			for ( i = 0; i < level.crazyplaceSpawnpoints.size; i++ )
			{
				spawnpoints[ spawnpoints.size ] = level.crazyplaceSpawnpoints[ i ];
			}
		}
		else if ( isdefined( level.customMap ) && level.customMap == "maze" )
		{
			for(i=0; i<level.mazeSpawnpoints.size;i++)
			{
				spawnpoints[spawnpoints.size] = level.mazeSpawnpoints[i];
			}
		}
		else
		{
			spawnpoints = getstructarray( "initial_spawn_points", "targetname" );
		}
		spawnpoint = getfreespawnpoint( spawnpoints, self );
	}
	self spawn( spawnpoint.origin, spawnpoint.angles, "zsurvival" );
	self.entity_num = self getentitynumber();
	self thread maps/mp/zombies/_zm::onplayerspawned();
	self thread maps/mp/zombies/_zm::player_revive_monitor();
	self freezecontrols( 1 );
	self.spectator_respawn = spawnpoint;
	self.score = self maps/mp/gametypes_zm/_globallogic_score::getpersstat( "score" );
	self.pers[ "participation" ] = 0;
	
	self.score_total = self.score;
	self.old_score = self.score;
	self.player_initialized = 0;
	self.zombification_time = 0;
	self.enabletext = 1;
	self thread maps/mp/zombies/_zm_blockers::rebuild_barrier_reward_reset();
	if ( isDefined( level.host_ended_game ) && !level.host_ended_game )
	{
		self freeze_player_controls( 0 );
		self enableweapons();
	}
	if ( isDefined( level.game_mode_spawn_player_logic ) )
	{
		spawn_in_spectate = [[ level.game_mode_spawn_player_logic ]]();
		if ( spawn_in_spectate )
		{
			self delay_thread( 0.05, maps/mp/zombies/_zm::spawnspectator );
		}
	}
	pixendevent();
}

getfreespawnpoint( spawnpoints, player ) //checked changed to match cerberus output
{
	if ( !isDefined( spawnpoints ) )
	{
		return undefined;
	}
	if ( !isDefined( game[ "spawns_randomized" ] ) )
	{
		game[ "spawns_randomized" ] = 1;
		spawnpoints = array_randomize( spawnpoints );
		random_chance = randomint( 100 );
		if ( random_chance > 50 )
		{
			set_game_var( "side_selection", 1 );
		}
		else
		{
			set_game_var( "side_selection", 2 );
		}
	}
	side_selection = get_game_var( "side_selection" );
	if ( get_game_var( "switchedsides" ) )
	{
		if ( side_selection == 2 )
		{
			side_selection = 1;
		}
		else
		{
			if ( side_selection == 1 )
			{
				side_selection = 2;
			}
		}
	}
	if ( isdefined( player ) && isdefined( player.team ) )
	{
		i = 0;
		while ( isdefined( spawnpoints ) && i < spawnpoints.size )
		{
			if ( side_selection == 1 )
			{
				if ( player.team != "allies" && isdefined( spawnpoints[ i ].script_int ) && spawnpoints[ i ].script_int == 1 )
				{
					arrayremovevalue( spawnpoints, spawnpoints[ i ] );
					i = 0;
				}
				else if ( player.team == "allies" && isdefined( spawnpoints[ i ].script_int) && spawnpoints[ i ].script_int == 2 )
				{
					arrayremovevalue( spawnpoints, spawnpoints[ i ] );
					i = 0;
				}
				else
				{
					i++;
				}
			}
			else //changed to be like beta dump
			{
				if ( player.team == "allies" && isdefined( spawnpoints[ i ].script_int ) && spawnpoints[ i ].script_int == 1 )
				{
					arrayremovevalue(spawnpoints, spawnpoints[i]);
					i = 0;
				}
				else if ( player.team != "allies" && isdefined( spawnpoints[ i ].script_int ) && spawnpoints[ i ].script_int == 2 )
				{
					arrayremovevalue( spawnpoints, spawnpoints[ i ] );
					i = 0;
				}
				else
				{
					i++;
				}
			}
		}
	}
	if ( !isdefined( player.playernum ) )
	{
		if ( player.team == "allies" )
		{
			player.playernum = get_game_var( "_team1_num" );
			set_game_var( "_team1_num", player.playernum + 1 );
		}
		else
		{
			player.playernum = get_game_var( "_team2_num" );
			set_game_var( "_team2_num", player.playernum + 1 );
		}
	}
	for ( j = 0; j < spawnpoints.size; j++ )
	{
		if ( !isdefined( spawnpoints[ j ].en_num ) ) 
		{
			for ( m = 0; m < spawnpoints.size; m++ )
			{
				spawnpoints[m].en_num = m;
			}
		}
		else if ( spawnpoints[ j ].en_num == player.playernum )
		{
			return spawnpoints[ j ];
		}
	}
	return spawnpoints[ 0 ];
}

get_player_spawns_for_gametype() //modified function
{
	match_string = "";
	location = level.scr_zm_map_start_location;
	if ( ( location == "default" || location == "" ) && isDefined( level.default_start_location ) )
	{
		location = level.default_start_location;
	}
	match_string = level.scr_zm_ui_gametype + "_" + location;
	player_spawns = [];
	structs = getstructarray("player_respawn_point", "targetname");
	i = 0;
	while ( i < structs.size )
	{
		if ( isdefined( structs[ i ].script_string ) )
		{
			tokens = strtok( structs[ i ].script_string, " " );
			foreach ( token in tokens )
			{
				if ( token == match_string )
				{
					player_spawns[ player_spawns.size ] = structs[ i ];
				}
			}
			i++;
			continue;
		}
		player_spawns[ player_spawns.size ] = structs[ i ];
		i++;
	}
	custom_spawns = [];
	if ( isDefined( level.customMap ) && level.customMap == "tunnel" )
	{
		for(i=0;i<level.tunnelSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.tunnelSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "diner")
	{
		for(i=0;i<level.dinerSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.dinerSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "cornfield")
	{
		for(i=0;i<level.cornfieldSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.cornfieldSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "power")
	{
		for(i=0;i<level.powerStationSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.powerStationSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "house")
	{
		for(i=0;i<level.houseSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.houseSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if(getDvar("customMap") == "town")
	{
		for(i=0;i<level.townSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.townSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if(getDvar("customMap") == "farm")
	{
		for(i=0;i<level.farmSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.farmSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "docks")
	{
		for(i=0;i<level.docksSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.docksSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "cellblock")
	{
		for(i=0;i<level.cellblockSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.cellblockSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isDefined( level.customMap ) && level.customMap == "rooftop")
	{
		for(i=0;i<level.rooftopSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.rooftopSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if( isdefined( level.customMap ) && level.customMap == "maze" )
	{
		for(i=0;i<level.mazeSpawnpoints.size;i++)
		{
			custom_spawns[custom_spawns.size] = level.mazeSpawnpoints[i];
		}
		return custom_spawns;
	}
	else if ( isDefined( level.customMap ) && level.customMap == "crazyplace" )
	{
		for ( i = 0; i < level.crazyplaceSpawnpoints.size; i++ )
		{
			custom_spawns[ custom_spawns.size ] = level.crazyplaceSpawnpoints[ i ];
		}
		return custom_spawns;
	}
	else if ( isdefined( level.customMap ) && level.customMap == "excavation" )
	{
		for ( i = 0; i < level.excavationSpawnpoints.size; i++ )
		{
			custom_spawns[ custom_spawns.size ] = level.excavationSpawnpoints[ i ];
		}
		return custom_spawns;
	}
	return player_spawns;
}

onendgame( winningteam ) //checked matches cerberus output
{
}

onroundendgame( roundwinner ) //checked matches cerberus output
{
	if ( game[ "roundswon" ][ "allies" ] == game[ "roundswon" ][ "axis" ] )
	{
		winner = "tie";
	}
	else if ( game[ "roundswon" ][ "axis" ] > game[ "roundswon" ][ "allies" ] )
	{
		winner = "axis";
	}
	else
	{
		winner = "allies";
	}
	return winner;
}

menu_init() //checked matches cerberus output
{
	game[ "menu_team" ] = "team_marinesopfor";
	game[ "menu_changeclass_allies" ] = "changeclass";
	game[ "menu_initteam_allies" ] = "initteam_marines";
	game[ "menu_changeclass_axis" ] = "changeclass";
	game[ "menu_initteam_axis" ] = "initteam_opfor";
	game[ "menu_class" ] = "class";
	game[ "menu_changeclass" ] = "changeclass";
	game[ "menu_changeclass_offline" ] = "changeclass";
	game[ "menu_wager_side_bet" ] = "sidebet";
	game[ "menu_wager_side_bet_player" ] = "sidebet_player";
	game[ "menu_changeclass_wager" ] = "changeclass_wager";
	game[ "menu_changeclass_custom" ] = "changeclass_custom";
	game[ "menu_changeclass_barebones" ] = "changeclass_barebones";
	game[ "menu_controls" ] = "ingame_controls";
	game[ "menu_options" ] = "ingame_options";
	game[ "menu_leavegame" ] = "popup_leavegame";
	game[ "menu_restartgamepopup" ] = "restartgamepopup";
	precachemenu( game[ "menu_controls" ] );
	precachemenu( game[ "menu_options" ] );
	precachemenu( game[ "menu_leavegame" ] );
	precachemenu( game[ "menu_restartgamepopup" ] );
	precachemenu( "scoreboard" );
	precachemenu( game[ "menu_team" ] );
	precachemenu( game[ "menu_changeclass_allies" ] );
	precachemenu( game[ "menu_initteam_allies" ] );
	precachemenu( game[ "menu_changeclass_axis" ] );
	precachemenu( game[ "menu_class" ] );
	precachemenu( game[ "menu_changeclass" ] );
	precachemenu( game[ "menu_initteam_axis" ] );
	precachemenu( game[ "menu_changeclass_offline" ] );
	precachemenu( game[ "menu_changeclass_wager" ] );
	precachemenu( game[ "menu_changeclass_custom" ] );
	precachemenu( game[ "menu_changeclass_barebones" ] );
	precachemenu( game[ "menu_wager_side_bet" ] );
	precachemenu( game[ "menu_wager_side_bet_player" ] );
	precachestring( &"MP_HOST_ENDED_GAME" );
	precachestring( &"MP_HOST_ENDGAME_RESPONSE" );
	level thread menu_onplayerconnect();
}

menu_onplayerconnect() //checked matches cerberus output
{
	level endon("end_game");
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread menu_onmenuresponse();
	}
}

menu_onmenuresponse() //checked changed to match cerberus output
{
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "menuresponse", menu, response );
		if ( response == "back" )
		{
			self closemenu();
			self closeingamemenu();
			if ( level.console )
			{
				if ( game[ "menu_changeclass" ] != menu && game[ "menu_changeclass_offline" ] != menu || menu == game[ "menu_team" ] && menu == game[ "menu_controls" ] )
				{
					if ( self.pers[ "team" ] == "allies" )
					{
						self openmenu( game[ "menu_class" ] );
					}
					if ( self.pers[ "team" ] == "axis" )
					{
						self openmenu( game[ "menu_class" ] );
					}
				}
			}
			continue;
		}
		if ( response == "changeteam" && level.allow_teamchange == "1" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_team" ] );
		}
		if ( response == "changeclass_marines" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_changeclass_allies" ] );
			continue;
		}
		if ( response == "changeclass_opfor" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_changeclass_axis" ] );
			continue;
		}
		if ( response == "changeclass_wager" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_changeclass_wager" ] );
			continue;
		}
		if ( response == "changeclass_custom" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_changeclass_custom" ] );
			continue;
		}
		if ( response == "changeclass_barebones" )
		{
			self closemenu();
			self closeingamemenu();
			self openmenu( game[ "menu_changeclass_barebones" ] );
			continue;
		}
		if ( response == "changeclass_marines_splitscreen" )
		{
			self openmenu( "changeclass_marines_splitscreen" );
		}
		if ( response == "changeclass_opfor_splitscreen" )
		{
			self openmenu( "changeclass_opfor_splitscreen" );
		}
		if ( response == "endgame" )
		{
			if ( self issplitscreen() )
			{
				level.skipvote = 1;
				if ( isDefined( level.gameended ) && level.gameended )
				{
					self maps/mp/zombies/_zm_laststand::add_weighted_down();
					self maps/mp/zombies/_zm_stats::increment_client_stat( "deaths" );
					self maps/mp/zombies/_zm_stats::increment_player_stat( "deaths" );
					self maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_jugg_player_death_stat();
					level.host_ended_game = 1;
					maps/mp/zombies/_zm_game_module::freeze_players( 1 );
					level notify( "end_game" );
				}
			}
			continue;
		}
		if ( response == "restart_level_zm" )
		{
			self maps/mp/zombies/_zm_laststand::add_weighted_down();
			self maps/mp/zombies/_zm_stats::increment_client_stat( "deaths" );
			self maps/mp/zombies/_zm_stats::increment_player_stat( "deaths" );
			self maps/mp/zombies/_zm_pers_upgrades_functions::pers_upgrade_jugg_player_death_stat();
			missionfailed();
		}
		if ( response == "killserverpc" )
		{
			level thread maps/mp/gametypes_zm/_globallogic::killserverpc();
			continue;
		}
		if ( response == "endround" )
		{
			if ( isDefined( level.gameended ) && level.gameended )
			{
				self maps/mp/gametypes_zm/_globallogic::gamehistoryplayerquit();
				self maps/mp/zombies/_zm_laststand::add_weighted_down();
				self closemenu();
				self closeingamemenu();
				level.host_ended_game = 1;
				maps/mp/zombies/_zm_game_module::freeze_players( 1 );
				level notify( "end_game" );
			}
			else
			{
				self closemenu();
				self closeingamemenu();
				self iprintln( &"MP_HOST_ENDGAME_RESPONSE" );
			}
			continue;
		}
		if ( menu == game[ "menu_team" ] && level.allow_teamchange == "1" )
		{
			switch( response )
			{
				case "allies":
					self [[ level.allies ]]();
					break;
				case "axis":
					self [[ level.teammenu ]]( response );
					break;
				case "autoassign":
					self [[ level.autoassign ]]( 1 );
					break;
				case "spectator":
					self [[ level.spectator ]]();
					break;
			}
			continue;
		}
		else
		{
			if ( game[ "menu_changeclass" ] != menu && game[ "menu_changeclass_offline" ] != menu && game[ "menu_changeclass_wager" ] != menu || menu == game[ "menu_changeclass_custom" ] && menu == game[ "menu_changeclass_barebones" ] )
			{
				self closemenu();
				self closeingamemenu();
				if ( level.rankedmatch && issubstr( response, "custom" ) )
				{
				}
				self.selectedclass = 1;
				self [[ level.class ]]( response );
			}
		}
	}
}


menuallieszombies() //checked changed to match cerberus output
{
	self maps/mp/gametypes_zm/_globallogic_ui::closemenus();
	if ( !level.console && level.allow_teamchange == "0" && isDefined( self.hasdonecombat ) && self.hasdonecombat )
	{
		return;
	}
	if ( self.pers[ "team" ] != "allies" )
	{
		if ( level.ingraceperiod && !isDefined( self.hasdonecombat ) || !self.hasdonecombat )
		{
			self.hasspawned = 0;
		}
		if ( self.sessionstate == "playing" )
		{
			self.switching_teams = 1;
			self.joining_team = "allies";
			self.leaving_team = self.pers[ "team" ];
			self suicide();
		}
		self.pers["team"] = "allies";
		self.team = "allies";
		self.pers["class"] = undefined;
		self.class = undefined;
		self.pers["weapon"] = undefined;
		self.pers["savedmodel"] = undefined;
		self updateobjectivetext();
		if ( level.teambased )
		{
			self.sessionteam = "allies";
		}
		else
		{
			self.sessionteam = "none";
			self.ffateam = "allies";
		}
		self setclientscriptmainmenu( game[ "menu_class" ] );
		self notify( "joined_team" );
		level notify( "joined_team" );
		self notify( "end_respawn" );
	}
}


custom_spawn_init_func() //checked matches cerberus output
{
	array_thread( level.zombie_spawners, ::add_spawn_function, maps/mp/zombies/_zm_spawner::zombie_spawn_init );
	array_thread( level.zombie_spawners, ::add_spawn_function, level._zombies_round_spawn_failsafe );
}

kill_all_zombies() //changed to match cerberus output
{
	ai = getaiarray( level.zombie_team );
	foreach ( zombie in ai )
	{
		if ( isdefined( zombie ) )
		{
			zombie dodamage( zombie.maxhealth * 2, zombie.origin, zombie, zombie, "none", "MOD_SUICIDE" );
			wait 0.05;
		}
	}
}

init() //checked matches cerberus output
{

	flag_init( "pregame" );
	flag_set( "pregame" );
	level thread onplayerconnect();
}

onplayerconnect() //checked matches cerberus output
{
	level endon("end_game");
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread onplayerspawned();
		if ( isDefined( level.game_module_onplayerconnect ) )
		{
			player [[ level.game_module_onplayerconnect ]]();
		}
	}
}

onplayerspawned() //checked partially changed to cerberus output
{
	level endon( "end_game" );
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill_either( "spawned_player", "fake_spawned_player" );
		if ( isDefined( level.match_is_ending ) && level.match_is_ending )
		{
			return;
		}
		if ( self maps/mp/zombies/_zm_laststand::player_is_in_laststand() )
		{
			self thread maps/mp/zombies/_zm_laststand::auto_revive( self );
		}
		if ( isDefined( level.custom_player_fake_death_cleanup ) )
		{
			self [[ level.custom_player_fake_death_cleanup ]]();
		}
		self setstance( "stand" );
		self.zmbdialogqueue = [];
		self.zmbdialogactive = 0;
		self.zmbdialoggroups = [];
		self.zmbdialoggroup = "";
		if ( is_encounter() )
		{
			if ( self.team == "axis" )
			{
				self.characterindex = 0;
				self._encounters_team = "A";
				self._team_name = &"ZOMBIE_RACE_TEAM_1";
				break;
			}
			else
			{
				self.characterindex = 1;
				self._encounters_team = "B";
				self._team_name = &"ZOMBIE_RACE_TEAM_2";
			}
		}
		self takeallweapons();
		if ( isDefined( level.givecustomcharacters ) )
		{
			self [[ level.givecustomcharacters ]]();
		}
		self giveweapon( "knife_zm" );
		if ( isDefined( level.onplayerspawned_restore_previous_weapons ) && isDefined( level.isresetting_grief ) && level.isresetting_grief )
		{
			weapons_restored = self [[ level.onplayerspawned_restore_previous_weapons ]]();
		}
		if ( isDefined( weapons_restored ) && !weapons_restored || !isDefined( weapons_restored ) )
		{
			self give_start_weapon( 1 );
		}
		weapons_restored = 0;
		if ( isDefined( level._team_loadout ) )
		{
			self giveweapon( level._team_loadout );
			self switchtoweapon( level._team_loadout );
		}
		if ( isDefined( level.gamemode_post_spawn_logic ) )
		{
			self [[ level.gamemode_post_spawn_logic ]]();
		}
	}
}

wait_for_players() //checked matches cerberus output
{
	level endon( "end_race" );
	if ( getDvarInt( "party_playerCount" ) == 1 )
	{
		flag_wait( "start_zombie_round_logic" );
		return;
	}
	while ( !flag_exists( "start_zombie_round_logic" ) )
	{
		wait 0.05;
	}
	while ( !flag( "start_zombie_round_logic" ) && isDefined( level._module_connect_hud ) )
	{
		level._module_connect_hud.alpha = 0;
		level._module_connect_hud.sort = 12;
		level._module_connect_hud fadeovertime( 1 );
		level._module_connect_hud.alpha = 1;
		wait 1.5;
		level._module_connect_hud fadeovertime( 1 );
		level._module_connect_hud.alpha = 0;
		wait 1.5;
	}
	if ( isDefined( level._module_connect_hud ) )
	{
		level._module_connect_hud destroy();
	}
}

onplayerconnect_check_for_hotjoin() //checked matches cerberus output
{
/*
/#
	if ( getDvarInt( #"EA6D219A" ) > 0 )
	{
		return;
#/
	}
*/
	map_logic_exists = level flag_exists( "start_zombie_round_logic" );
	map_logic_started = flag( "start_zombie_round_logic" );
	if ( map_logic_exists && map_logic_started )
	{
		self thread hide_gump_loading_for_hotjoiners();
	}
}

hide_gump_loading_for_hotjoiners() //checked matches cerberus output
{
	self endon( "disconnect" );
	self.rebuild_barrier_reward = 1;
	self.is_hotjoining = 1;
	num = self getsnapshotackindex();
	while ( num == self getsnapshotackindex() )
	{
		wait 0.25;
	}
	wait 0.5;
	self maps/mp/zombies/_zm::spawnspectator();
	self.is_hotjoining = 0;
	self.is_hotjoin = 1;
	if ( is_true( level.intermission ) || is_true( level.host_ended_game ) )
	{
		setclientsysstate( "levelNotify", "zi", self );
		self setclientthirdperson( 0 );
		self resetfov();
		self.health = 100;
		self thread [[ level.custom_intermission ]]();
	}
}

blank() //this function is intentionally empty
{
	//empty function
}
/*
* CSDMsake
*/

#include <amxmisc>
#include <hamsandwich>
#include <cstrike>
#include <fakemeta_util>
#include <engine>

#define PLUGIN	"csdmsake"
#define AUTHOR	"sake"
#define VERSION	"1.0"

#define key_all      MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9

enum PrimaryWeapons
{
	M4A1,
	AK47,
	SG552,
	AUG,
	M3,
	MP5,
	PARA,
	AWP,
	SCOUT,
	P90
}

new const g_weapon_name_prim[PrimaryWeapons][] =
{
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_sg552",
	"weapon_aug",
	"weapon_m3",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_awp",
	"weapon_scout",
	"weapon_p90"
};

new const g_weapon_ammo_prim[PrimaryWeapons][] =
{
	"556nato",
	"762nato",
	"556nato",
	"556nato",
	"buckshot",
	"9mm",
	"556natobox",
	"338magnum",
	"762nato",
	"57mm"
};

enum SecondaryWeapons
{
	DEAGLE,
	USP,
	GLOCK,
	ELITE,
	FIVESEVEN
}


new const g_weapon_name_sec[SecondaryWeapons][] =
{
	"weapon_deagle",
	"weapon_usp",
	"weapon_glock18",
	"weapon_elite",
	"weapon_fiveseven"
}

new const g_weapon_ammo_sec[SecondaryWeapons][] =
{
	"50ae",
	"45acp",
	"9mm",
	"9mm",
	"57mm"
}

//vars for weapons
new PrimaryWeapons:g_primary[32] = M4A1;
new SecondaryWeapons:g_secondary[32] = DEAGLE;
new bool:g_remember[32] = {false, ...}

//pointer vor CVAR for spawnprotection
new sv_godmodetime;
new Float:g_godModeTime;

//vars for custom spawns
new Float:g_origin[64][3];
new Float:g_angle[64][3];
new g_iEnt[64];
new g_origins = 0;

//vars for RoundEndBlocking
new g_botnum = 0;
new g_bots[2];
new g_failCount = 0;
new const g_names[2][] = {"CSDM RoundEndBlocker1","CSDM RoundEndBlocker2"};
new const g_botCreateNumber = 6;
new const g_botKickNumber = 10;

//various global vars
new bool:g_firstTeamJoin[32] = {true, ...}
new g_players = 0;
new g_maxPlayers = 0;

//menus
new g_menu_main;
new g_menu_prim;
new g_menu_sec;

public plugin_init()
{
	if(cstrike_running())
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		RegisterHam(Ham_Spawn,"player","playerSpawned",1);
		register_event("DeathMsg", "playerKilled", "a");
		register_event("TeamInfo", "teamAssigned", "a");
		register_message(get_user_msgid("ClCorpse"),"blockBodies");
		register_event("SendAudio", "roundEnd", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin");
		register_clcmd("say /respawn", "respawnPlayer", 0);
		register_clcmd("say /createspawn", "createSpawn", 0);
		register_clcmd("say /guns", "reenableMenu",0);
		init_menus();
		sv_godmodetime = register_cvar("sv_godmodetime","1.5",FCVAR_SERVER);
		g_godModeTime = get_pcvar_float(sv_godmodetime);
		g_maxPlayers = get_maxplayers();
	}
}

public init_menus()
{
	g_menu_main = menu_create("Weapon Main Menu","mainMenuHandle");
	menu_additem(g_menu_main,"New Weapons","0",0);
	menu_additem(g_menu_main,"Last Weapons","1",0);
	menu_additem(g_menu_main,"Remember Weapons","2",0);
	menu_setprop(g_menu_main, MPROP_EXIT, MEXIT_ALL);
	g_menu_prim = menu_create("Primary Weapons","primaryWeaponPicked");
	menu_additem(g_menu_prim,"M4A1","0",0);
	menu_additem(g_menu_prim,"AK-47","1",0);
	menu_additem(g_menu_prim,"SG552","2",0);
	menu_additem(g_menu_prim,"AUG","3",0);
	menu_additem(g_menu_prim,"M3","4",0);
	menu_additem(g_menu_prim,"MP5","5",0);
	menu_additem(g_menu_prim,"PARA","6",0);
	menu_additem(g_menu_prim,"AWP","7",0);
	menu_additem(g_menu_prim,"Scout","8",0);
	menu_additem(g_menu_prim,"P90","9",0);
	menu_setprop(g_menu_prim, MPROP_EXIT, MEXIT_ALL);
	g_menu_sec = menu_create("Secondary Weapons","secondaryWeaponPicked");
	menu_additem(g_menu_sec,"Desert Eagle","0",0);
	menu_additem(g_menu_sec,"USP","1",0);
	menu_additem(g_menu_sec,"Glock18","2",0);
	menu_additem(g_menu_sec,"Dual Elites","3",0);
	menu_additem(g_menu_sec,"Five-Seven","4",0);
	menu_setprop(g_menu_prim, MPROP_EXIT, MEXIT_ALL);
}

/*
* If user connects the playercount + 1 and maybe kick RoundEndBlockers
*/
public client_putinserver(id)
{
	g_players++;
	if(g_botnum > 0 && g_players > g_botKickNumber)
	{
		kickBots();
	}
}

/*
* If user disconnects the weapon are set back to default
*/
public client_disconnect(id)
{
	if(id <= 32)
	{
		g_primary[id-1] = M4A1;
		g_secondary[id-1] = DEAGLE;
		g_remember[id-1] = false;
		g_firstTeamJoin[id-1] = true;
		g_players--;
	}
}

/*
* Kick all bots at the end of the map
*/
public plugin_end()
{
	kickBots();
}

/*
* Kick all bots on plugin_pause
*/
public plugin_pause()
{
	kickBots();
}

/*
* prevent bodies from appearing after user death
*/
public blockBodies(msg_id, msg_dest, msg_entity)
{
	return PLUGIN_HANDLED;
}

/*
* Kicks the bots
* //dllfunc(DLLFunc_ClientDisconnect, g_bots[0]);
* //engfunc(EngFunc_FreeEntPrivateData, g_bots[0]);
*/
public kickBots()
{
	if(g_bots[0] && is_user_connected(g_bots[0]))
	{
		server_print("[CSDM - RoundEndBlocker] Kicking bot!");
		server_cmd("kick #%d", get_user_userid(g_bots[0]));
		g_botnum--;
	}
	else if(g_bots[1] && is_user_connected(g_bots[1]))
	{
		server_print("[CSDM - RoundEndBlocker] Kicking bot!");
		server_cmd("kick #%d", get_user_userid(g_bots[1]));
		g_botnum--;
	}
}

/*
* create RoundEndBlockers at the end of the first round.
*/
public roundEnd()
{
	if(g_players >= g_maxPlayers -1 || g_players > g_botCreateNumber)
	{
		return;
	}
	while(g_botnum < 2 && g_failCount < 5)
	{
		createBot();
	}
}

/*
* Creates 1 RoundEndBlocker. If fails 4 times no more Bots will be created on this map
*/
public createBot()
{
	new bot;
	bot = engfunc(EngFunc_CreateFakeClient, g_names[g_botnum]);
	if(!bot) 
	{
		server_print("[CSDM - RoundEndblocker] Error!");
		g_failCount++;
		if(g_failCount > 4)
		{
			kickBots();
		}
		return;
	}
	new ptr[128];
	engfunc(EngFunc_FreeEntPrivateData, bot);
	dllfunc(DLLFunc_ClientConnect, bot, g_names[g_botnum], "127.0.0.1", ptr);
	if(!is_user_connected(bot)) 
	{
		server_print("[CSDM - RoundEndblocker] Error: %s", ptr);
		return;
	}
	dllfunc(DLLFunc_ClientPutInServer, bot);
	set_pev(bot, pev_spawnflags, pev(bot, pev_spawnflags) | FL_FAKECLIENT);
	set_pev(bot, pev_flags, pev(bot, pev_flags) | FL_FAKECLIENT);
	cs_set_user_team(bot, g_botnum % 2 ? CS_TEAM_T : CS_TEAM_CT);
	server_print("[CSDM - RoundEndblocker] ^"%s^" has been created.", g_names[g_botnum]);
	g_bots[g_botnum++] = bot;
	g_failCount = 0;
}

/*
* makes RoundEndBlockers to "Spectators"
*/
public hideBot(bot)
{
	set_pev(bot, pev_effects, pev(bot, pev_effects) | EF_NODRAW);
	set_pev(bot, pev_solid, SOLID_NOT);
	set_pev(bot, pev_takedamage, DAMAGE_NO);
	engfunc(EngFunc_SetOrigin, bot, Float:{9999.0, 9999.0, 9999.0});
	new msgTeamInfo = get_user_msgid("TeamInfo");
	message_begin(MSG_ALL, msgTeamInfo);
	write_byte(bot);
	write_string("SPECTATOR");
	message_end();
}

/*
* function for respawning on death
*/
public playerKilled()
{
	new victim = read_data(2);
	set_task(0.5,"spawnPlayer",victim);
	return PLUGIN_CONTINUE;
}

/*
* creates a spawn and makes the last created spawn glow
*/
public createSpawn(id)
{
	if(g_origins < 62 && is_user_admin(id))
	{
		entity_get_vector(id, EV_VEC_origin, g_origin[g_origins]);
		entity_get_vector(id, EV_VEC_angles, g_angle[g_origins]);
		
		if(g_origins > 0)
		{
			unglow(g_iEnt[g_origins-1]);
		}
		
		g_iEnt[g_origins] = create_entity("info_target" );
		entity_set_model(g_iEnt[g_origins],"models/player/gign/gign.mdl");
		engfunc(EngFunc_SetOrigin, g_iEnt[g_origins], g_origin[g_origins]);
		entity_set_vector(g_iEnt[g_origins], EV_VEC_angles, g_angle[g_origins]);
		
		glow(g_iEnt[g_origins],{0,255,0},255);
		
		g_origins++;
	}
	return PLUGIN_CONTINUE;
}

/*
* lets entities glow in a defined color
*/
public glow(id, color[3],amt)
{
	fm_set_user_rendering(id,kRenderFxGlowShell,color[0],color[1],color[2],kRenderNormal,amt);
}

/*
* unglows entities. back to normal
*/
public unglow(id)
{
	fm_set_user_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,0);
}

/*
* called after user says /guns, reenables the menu
*/
public reenableMenu(id)
{
	if(id > 32)
	{
		return PLUGIN_CONTINUE;
	}
	g_remember[id-1] = false;
	set_hudmessage(255, 0, 0, -1.0, 0.30, 0, 3.0, 6.0);
	show_hudmessage(id,"Weapon menu re-enabled on next respawn!");
	return PLUGIN_CONTINUE;
}

/*
* called on spawn, if user is bot he gets default weapons, if not he can decide (showWeapons).
* Spawnprotection is turned on
*/
public playerSpawned(id)
{
	if(id == g_bots[0])
	{
		cs_set_user_team(id,CS_TEAM_CT);
		hideBot(id);
	}
	else if(id == g_bots[1])
	{
		cs_set_user_team(id,CS_TEAM_T);
		hideBot(id);
	}
	if(is_user_alive(id) && id <= 32)
	{
		set_task(0.1,"startGodMode",id);
		set_task(g_godModeTime+0.1,"stopGodMode",id);
		setNewOrigin(id);
		if(!is_user_bot(id) && !g_remember[id-1])
		{
			//show the Menu for the Weapons
			menu_display(id,g_menu_main,0);
			//set_task(0.1,"showWeapons",id);
		}
		else
		{
			//Bots get standard Weapons, and if g_remember == true players get the last weapons they selected
			giveWeapons(id);
		}
	}	
}

/*
* spawns the player on the CSDM spawns if available
*/
public setNewOrigin(id)
{
	if(g_origins > 0 && id <= 32)
	{
		//origins-1 -> origins+1 when creating new origin
		new num = random_num(0,g_origins-1);
		engfunc(EngFunc_SetOrigin, id, g_origin[num]);
		//set_es(0,ES_Angles,angle[num]);
		entity_set_vector(id, EV_VEC_angles, g_angle[num]);
	}
}

/*
* used to start the godmode. Lets the user glow. (both only when he is alive (to prevent possible bug?))
*/
public startGodMode(id)
{
	if(!is_user_alive(id) || id > 32)
	{
		return;
	}
	fm_set_user_godmode(id,1);
	if(get_user_team(id) == 1)
	{
		glow(id,{255,0,0},25);
	}
	if(get_user_team(id) == 2)
	{
		glow(id,{0,0,255},25);
	}
}

/*
* used to stop the godmode. Only if user is connected (so he isn't dead or left the game)
*/
public stopGodMode(id)
{
	if(!is_user_connected(id) || id > 32)
	{
		return;
	}
	fm_set_user_godmode(id,0);
	unglow(id);
}

/*
* Handle for the main Menu
*/
public mainMenuHandle(id, menu ,item)
{
	if(id > 32 || item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	
	switch(str_to_num(data))
	{
		case 0:
		{
			menu_display(id,g_menu_prim,0);
		}
		case 1:
		{
			giveWeapons(id);
		}
		case 2:
		{
			g_remember[id-1] = true;
			giveWeapons(id);
			set_hudmessage(255, 0, 0, -1.0, 0.30, 0, 3.0, 6.0);
			show_hudmessage(id,"To re-enable the menu say /guns");
		}
	}
	return PLUGIN_HANDLED;
}

/*
* called after primary weapons menu is closed. Gives weapon to player
*/
public primaryWeaponPicked(id, menu, item)
{
	if(id > 32 || item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	g_primary[id-1] = PrimaryWeapons:str_to_num(data);
	
	//display the secondary weapons menu
	menu_display(id,g_menu_sec,0);
	return PLUGIN_HANDLED;
}

/*
* called after secondary weapons menu is closed. Gives weapon to player
*/
public secondaryWeaponPicked(id, menu, item)
{
	if(id > 32 || item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	g_secondary[id-1] = SecondaryWeapons:str_to_num(data);
	
	giveWeapons(id);
	return PLUGIN_HANDLED;
}

/*
* method for giving users weapons
*/
public giveWeapons(id)
{
	if(id <= 32 && is_user_alive(id) && pev(id,pev_weapons))
	{
		fm_strip_user_weapons(id);
		cs_set_user_armor(id,100,CS_ARMOR_VESTHELM);
		
		//give the user his knife back
		fm_give_item(id,"weapon_knife");
		
		//give the user the secondary weapon he has chosen
		fm_give_item(id,g_weapon_name_sec[g_secondary[id-1]]);
		ExecuteHam(Ham_GiveAmmo, id, 200, g_weapon_ammo_sec[g_secondary[id-1]], 200);
		
		//give the user the primary weapon he has chosen
		fm_give_item(id,g_weapon_name_prim[g_primary[id-1]]);
		ExecuteHam(Ham_GiveAmmo, id, 200, g_weapon_ammo_prim[g_primary[id-1]], 200);	
	}
}

/*
* simple spawnPlayer method. spawns player.
* credits:
* https://forums.alliedmods.net/showpost.php?p=678294&postcount=19
*/
public spawnPlayer(id)
{
	// Disconnected, already spawned, or switched to Spectator
	if (!is_user_connected(id) 
	|| is_user_alive(id) 
	|| cs_get_user_team(id) == CS_TEAM_SPECTATOR 
	|| cs_get_user_team(id) == CS_TEAM_UNASSIGNED
	|| id >32)
	{   
		return;
	}
	
	// Try to spawn the player setting the appropiate dead flag and forcing a think
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE);
	dllfunc(DLLFunc_Think, id);
	
	// Fix for Bots: DLLFunc_Think won't work on them,
	// but DLLFunc_Spawn does the job without any bugs.
	if (is_user_bot(id) && pev(id, pev_deadflag) == DEAD_RESPAWNABLE)
	{
		dllfunc(DLLFunc_Spawn, id);
	}
}


/*
* simple killUser method. kills player.
*/
public killUser(id)
{
	if(is_user_alive(id) && id <= 32)
	{
		user_kill(id);
	}
}

/*
* respawns player on say /respawn. -1 stats. 
* Player could connect and then is just dead and has to wait.
*/
public respawnPlayer(id)
{
	if(id > 32)
	{
		return PLUGIN_CONTINUE;
	}
	new CsTeams:team = cs_get_user_team(id);
	if(team == CS_TEAM_CT || team == CS_TEAM_T)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.30, 0, 3.0, 6.0);
		show_hudmessage(id,"respawning...!");
		set_task(0.5,"killUser",id);
	}
	return PLUGIN_CONTINUE;
}

/*
* called on change of TeamInfo. spawns player if neccessary
*/
public teamAssigned()
{
	new id = read_data(1);
	if(id > 32 || id == g_bots[0] || id == g_bots[1])
	{
		return;
	}
	if(is_user_connected(id) && !is_user_hltv(id))
	{
		if(is_user_alive(id))
		{
			g_firstTeamJoin[id-1] = true;
			return;
		}
		
		new szTeam[2];
		
		read_data(2, szTeam, charsmax(szTeam))
		
		switch(szTeam[0])
		{
			case 'T','C':
			{
				if(!g_firstTeamJoin[id-1])
				{
					dllfunc(DLLFunc_Spawn,id);
					g_firstTeamJoin[id-1] = true;
				}
				else
				{
					g_firstTeamJoin[id-1] = false;
				}
			}
			
			default:
			{
				g_firstTeamJoin[id-1] = true;
			}
		}
	}
}
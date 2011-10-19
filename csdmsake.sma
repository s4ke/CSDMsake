/*
* CSDMsake - CSDM for CS 1.5
    Copyright (C) 2011 sake

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>

#define PLUGIN	"csdmsake"
#define PLUGIN_IDENTIFIER "[CSDMsake]" 

#define ANNOUNCE_TIME 5.0
#define WEBSITE "http://csdmsake.dyndns.org/"

#define COLOR_T {255,0,0}
#define COLOR_CT {0,0,255}

#define BOT_ORIGIN Float:{9999.0, 9999.0, 9999.0}

#define RESPAWN_TIME 0.5

#define AUTHOR	"sake"
#define VERSION	"1.1a"

#define key_all      MENU_KEY_0 | MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9

enum PrimaryWeapon
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
	P90,
	XM1014,
	MAC10,
	UMP45,
	TMP,
	G3SG1,
	SG550
}

new const g_weapon_name_prim[PrimaryWeapon][] =
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
	"weapon_p90",
	"weapon_xm1014",
	"weapon_mac10",
	"weapon_ump45",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_sg550"
};

new const g_weapon_ammo_prim[PrimaryWeapon][] =
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
	"57mm",
	"buckshot",
	"45acp",
	"45acp",
	"9mm",
	"762nato",
	"556nato"
};

enum SecondaryWeapon
{
	DEAGLE,
	USP,
	GLOCK,
	ELITE,
	FIVESEVEN,
	P228
}


new const g_weapon_name_sec[SecondaryWeapon][] =
{
	"weapon_deagle",
	"weapon_usp",
	"weapon_glock18",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_p228"
}

new const g_weapon_ammo_sec[SecondaryWeapon][] =
{
	"50ae",
	"45acp",
	"9mm",
	"9mm",
	"57mm",
	"357sig"
}

//vars for weapons
new PrimaryWeapon:g_primary[32] = M4A1;
new SecondaryWeapon:g_secondary[32] = DEAGLE;
new bool:g_remember[32];
new bool:g_hasWeapons[32];

//pointer vor CVAR for spawnprotection
new sv_godmodetime;
new Float:g_godModeTime;

//vars for RoundEndBlocking
new g_botnum = 0;
new g_bots[2];
new g_failCount = 0;
new const g_names[2][] = {"CSDMsake RoundEndBlocker1","CSDMsake RoundEndBlocker2"};
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
		initVars();
		initMenus();
		blockMessages();
		registerEvents();	
		registerHamHooks();
		registerClCommands()
		registerSayCommands();
	}
}

initVars()
{
	sv_godmodetime = register_cvar("sv_godmodetime","1.5",FCVAR_SERVER);
	register_cvar("csdmsake_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	g_godModeTime = get_pcvar_float(sv_godmodetime);
	g_maxPlayers = get_maxplayers();
}

initMenus()
{
	g_menu_main = menu_create("Weapon Main Menu","mainMenuHandle");
	menu_additem(g_menu_main,"New Weapons");
	menu_additem(g_menu_main,"Last Weapons");
	menu_additem(g_menu_main,"Remember Weapons");
	menu_setprop(g_menu_main, MPROP_EXIT, MEXIT_NEVER);
	g_menu_prim = menu_create("Primary Weapons","primaryWeaponPicked");
	menu_additem(g_menu_prim,"M4A1");
	menu_additem(g_menu_prim,"AK-47");
	menu_additem(g_menu_prim,"SG552");
	menu_additem(g_menu_prim,"AUG");
	menu_additem(g_menu_prim,"M3");
	menu_additem(g_menu_prim,"MP5");
	menu_additem(g_menu_prim,"PARA");
	menu_additem(g_menu_prim,"AWP");
	menu_additem(g_menu_prim,"Scout");
	menu_additem(g_menu_prim,"P90");
	menu_additem(g_menu_prim,"XM1014");
	menu_additem(g_menu_prim,"Mac10");
	menu_additem(g_menu_prim,"UMP45");
	menu_additem(g_menu_prim,"TMP");
	menu_additem(g_menu_prim,"G3SG1");
	menu_additem(g_menu_prim,"SG550");
	menu_setprop(g_menu_prim, MPROP_EXIT, MEXIT_ALL);
	g_menu_sec = menu_create("Secondary Weapons","secondaryWeaponPicked");
	menu_additem(g_menu_sec,"Desert Eagle");
	menu_additem(g_menu_sec,"USP");
	menu_additem(g_menu_sec,"Glock18");
	menu_additem(g_menu_sec,"Dual Elites");
	menu_additem(g_menu_sec,"Five-Seven");
	menu_additem(g_menu_sec,"P228");
	menu_setprop(g_menu_sec, MPROP_EXIT, MEXIT_ALL);
}

registerSayCommands()
{
	register_clcmd("say /respawn", "respawnPlayer", 0);
	register_clcmd("say respawn", "respawnPlayer", 0);
	register_clcmd("say /guns", "reenableMenu",0);
	register_clcmd("say guns", "reenableMenu",0);
	register_clcmd("say /ammo","giveAmmo",0);
	register_clcmd("say ammo","giveAmmo",0);
}

registerHamHooks()
{
	RegisterHam(Ham_Spawn, "player", "playerSpawned", 1);
}

registerEvents()
{
	register_event("DeathMsg", "playerKilled", "a");
	register_event("TeamInfo", "teamAssigned", "a");
	register_event("SendAudio", "roundEnd", "a", "2&%!MRAD_terwin", "2&%!MRAD_ctwin");
}

blockMessages()
{
	set_msg_block(get_user_msgid("ClCorpse"),BLOCK_SET);
	set_msg_block(get_user_msgid("StatusIcon"),BLOCK_SET);
}

registerClCommands()
{
	register_clcmd("buy", "blockCmd");
	register_clcmd("buyequip", "blockCmd");
	register_clcmd("buyammo1", "blockCmd");
	register_clcmd("buyammo2", "blockCmd");
}

/////////////////////////////////////Forwarded Functions//////////////////////////////////////

/*
* make sure everything is back to default, playernumber+1, maybe kick bots
*/
public client_connect(id)
{
	g_primary[id-1] = M4A1;
	g_secondary[id-1] = DEAGLE;
	g_remember[id-1] = false;
	g_hasWeapons[id-1] = false;
	g_firstTeamJoin[id-1] = true;
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
	g_players--;
}

/*
* Do some advertising some time after the client has been put in the server.
*/
public client_putinserver(id)
{
	set_task(ANNOUNCE_TIME, "announce", id);
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

/////////////////////////////////////EventHandling Functions//////////////////////////////////////

/*
* prevents commands
*/
public blockCmd(id)
{
	return PLUGIN_HANDLED;
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
* function for respawning on death
*/
public playerKilled()
{
	new victim = read_data(2);
	set_task(RESPAWN_TIME,"spawnPlayer",victim);
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
		g_hasWeapons[id-1] = false;
		set_task(0.1,"startGodMode",id);
		set_task(g_godModeTime+0.1,"stopGodMode",id);
		if(!is_user_bot(id) && !g_remember[id-1])
		{
			new menu,keys;
			get_user_menu(id,menu,keys);
			//only show the menu if no other is being displayed
			if(menu == 0)
			{
				//show the Menu for the Weapons
				menu_display(id,g_menu_main,0);
			}
			else if(!(menu == g_menu_main || menu == g_menu_prim || g_menu_sec))
			{
				client_print(id,print_chat,"%s Another menu is being displayed, say /guns again after the menu has closed!", PLUGIN_IDENTIFIER);	
			}
		}
		else
		{
			//Bots get standard Weapons, and if g_remember == true players get the last weapons they selected
			giveWeapons(id);
		}
		if(callfunc_begin("spawn_Preset","csdm_spawn_preset.amxx") == 1)
		{
			callfunc_push_int(id);
			callfunc_push_int(1);
			callfunc_end();
		}
	}	
}

/////////////////////////////////////RoundendBlocker Functions//////////////////////////////////////

/*
* Kicks the bots
* //dllfunc(DLLFunc_ClientDisconnect, g_bots[0]);
* //engfunc(EngFunc_FreeEntPrivateData, g_bots[0]);
*/
public kickBots()
{
	if(g_bots[0] && is_user_connected(g_bots[0]))
	{
		server_print("[CSDMsake - RoundEndBlocker] Kicking bot!");
		server_cmd("kick #%d", get_user_userid(g_bots[0]));
		g_bots[0] = -1;
		g_botnum--;
	}
	if(g_bots[1] && is_user_connected(g_bots[1]))
	{
		server_print("[CSDMsake - RoundEndBlocker] Kicking bot!");
		server_cmd("kick #%d", get_user_userid(g_bots[1]));
		g_bots[1] = -1;
		g_botnum--;
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
		server_print("[CSDMsake - RoundEndblocker] Error!");
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
		server_print("[CSDMsake - RoundEndblocker] Error: %s", ptr);
		return;
	}
	dllfunc(DLLFunc_ClientPutInServer, bot);
	set_pev(bot, pev_spawnflags, pev(bot, pev_spawnflags) | FL_FAKECLIENT);
	set_pev(bot, pev_flags, pev(bot, pev_flags) | FL_FAKECLIENT);
	cs_set_user_team(bot, g_botnum % 2 ? CS_TEAM_T : CS_TEAM_CT);
	server_print("[CSDMsake - RoundEndblocker] ^"%s^" has been created.", g_names[g_botnum]);
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
	engfunc(EngFunc_SetOrigin, bot, BOT_ORIGIN);
	new msgTeamInfo = get_user_msgid("TeamInfo");
	message_begin(MSG_ALL, msgTeamInfo);
	write_byte(bot);
	write_string("SPECTATOR");
	message_end();
}

/////////////////////////////////////Spawnprotection & Color Functions//////////////////////////////////////

/*
* lets entities glow in a defined color
*/
public glow(id, color[3], amt)
{
	set_user_rendering(id,kRenderFxGlowShell,color[0],color[1],color[2],kRenderNormal,amt);
}

/*
* unglows entities. back to normal
*/
public unglow(id)
{
	set_user_rendering(id,kRenderFxNone,0,0,0,kRenderNormal,0);
}


/*
* used to start the godmode. Lets the user glow. (both only when he is alive (to prevent possible bug?))
*/
public startGodMode(id)
{
	if(!is_user_alive(id))
	{
		return;
	}
	fm_set_user_godmode(id,1);
	if(get_user_team(id) == 1)
	{
		glow(id,COLOR_T,25);
	}
	if(get_user_team(id) == 2)
	{
		glow(id,COLOR_CT,25);
	}
}

/*
* used to stop the godmode. Only if user is connected (so he isn't dead or left the game)
*/
public stopGodMode(id)
{
	if(!is_user_connected(id))
	{
		return;
	}
	fm_set_user_godmode(id,0);
	unglow(id);
}

/////////////////////////////////////Menu Handles//////////////////////////////////////

/*
* Handle for the main Menu
*/
public mainMenuHandle(id, menu ,item)
{
	switch(item)
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
			client_print(id,print_chat,"%s To re-enable the menu say /guns", PLUGIN_IDENTIFIER);
		}
	}
	return PLUGIN_HANDLED;
}

/*
* called after primary weapons menu is closed. Gives weapon to player
*/
public primaryWeaponPicked(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_display(id,g_menu_main,0);
		return PLUGIN_HANDLED;
	}
	
	g_primary[id-1] = PrimaryWeapon:item
	
	//display the secondary weapons menu
	menu_display(id,g_menu_sec,0);
	return PLUGIN_HANDLED;
}

/*
* called after secondary weapons menu is closed. Gives weapon to player
*/
public secondaryWeaponPicked(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_display(id,g_menu_main,0);
		return PLUGIN_HANDLED;
	}
	
	g_secondary[id-1] = SecondaryWeapon:item;
	
	giveWeapons(id);
	return PLUGIN_HANDLED;
}

/*
* called after user says /guns, reenables the menu
*/
public reenableMenu(id)
{
	g_remember[id-1] = false;
	if(g_hasWeapons[id-1])
	{
		client_print(id,print_chat,"%s Weapon menu re-enabled on next respawn!", PLUGIN_IDENTIFIER);
		return PLUGIN_CONTINUE;
	}
	new menu, keys;
	get_user_menu(id,menu,keys);
	if(menu == 0)
	{
		menu_display(id,g_menu_main,0);
	}
	return PLUGIN_CONTINUE;
}

/////////////////////////////////////Respawning, giving Weapons, Teams, etc.//////////////////////////////////////

/*
* method for giving users weapons
*/
public giveWeapons(id)
{
	if(is_user_alive(id))
	{
		strip_user_weapons(id);
		cs_set_user_armor(id,100,CS_ARMOR_VESTHELM);
		
		//give the user the primary weapon he has chosen
		fm_give_item(id,g_weapon_name_prim[g_primary[id-1]]);
		
		//give the user the secondary weapon he has chosen
		fm_give_item(id,g_weapon_name_sec[g_secondary[id-1]]);
		
		//give the user his knife back
		fm_give_item(id,"weapon_knife");	
		
		giveAmmo(id);
		g_hasWeapons[id-1] = true;
	}
}

/*
* Gives the user the ammo for his weapons
*/
public giveAmmo(id)
{
	ExecuteHamB(Ham_GiveAmmo, id, 200,g_weapon_ammo_prim[g_primary[id-1]],200);
	ExecuteHamB(Ham_GiveAmmo, id, 200,g_weapon_ammo_sec[g_secondary[id-1]],200);
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
	|| cs_get_user_team(id) == CS_TEAM_UNASSIGNED)
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
	if(is_user_alive(id))
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
	new CsTeams:team = cs_get_user_team(id);
	if(team == CS_TEAM_CT || team == CS_TEAM_T)
	{
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
	if(id == g_bots[0] || id == g_bots[1])
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
					dllfunc(DLLFunc_Spawn, id);
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

/*
* Announce Plugin info if player is still connected
*/
public announce(id)
{
	if(is_user_connected(id))
	{
		client_print(id,print_chat,"%s CSDMsake %s has been developed by sake, visit %s for more info!", PLUGIN_IDENTIFIER, VERSION, WEBSITE);
	}
}
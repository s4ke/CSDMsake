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

//TODO: Resetting variables via extra function because of multiple usage!!!

#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>

#define AUTHOR	"sake"
#define VERSION	"1.1d"
#define PLUGIN	"csdmsake"
#define PLUGIN_IDENTIFIER "[CSDMsake]" 

#define ANNOUNCE_TIME 5.0
#define WEBSITE "http://csdmsake.dyndns.org/"

#define COLOR_T {255,0,0}
#define COLOR_CT {0,0,255}

#define BOT_ORIGIN Float:{9999.0, 9999.0, 9999.0}

#define DEFAULT_GODMODETIME "1.5"
#define RESPAWN_TIME 0.5

//pointer for CVAR for spawnprotection
new sv_godmodetime;

//vars/constants for RoundEndBlocking
new g_botnum = 0;
new g_bots[2];
new g_failCount = 0;
new const g_names[2][] = {"CSDMsake RoundEndBlocker1","CSDMsake RoundEndBlocker2"};
new const g_botCreateNumber = 6;
new const g_botKickNumber = 10;

//various global vars
new bool:g_firstTeamJoin[32] = {true, ...};
new g_players = 0;
new g_maxPlayers = 0;

public plugin_init()
{
	if(cstrike_running())
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		initVars();
		blockMessages();
		registerEvents();
		registerHamHooks();
		registerSayCommands();
	}
}

initVars()
{
	sv_godmodetime = register_cvar("sv_godmodetime", DEFAULT_GODMODETIME ,FCVAR_SERVER);
	register_cvar("csdmsake_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	g_maxPlayers = get_maxplayers();	
}

registerSayCommands()
{
	register_clcmd("say /respawn", "respawnPlayer", 0);
	register_clcmd("say respawn", "respawnPlayer", 0);
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

registerHamHooks()
{
	RegisterHam(Ham_Spawn, "player", "playerSpawned", 1);
}

/////////////////////////////////////Forwarded Functions//////////////////////////////////////

/*
* make sure everything is back to default, playernumber+1, maybe kick bots
*/
public client_connect(id)
{
	
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
		set_task(get_pcvar_float(sv_godmodetime)+0.1,"stopGodMode",id);
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
				set_task(ANNOUNCE_TIME, "announce", id);
			}
			default:
			{
				g_firstTeamJoin[id-1] = true;
			}
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
	set_pev(bot, pev_flags, pev(bot, pev_flags) | FL_CUSTOMENTITY);
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



/////////////////////////////////////Respawning, giving Weapons, Teams, etc.//////////////////////////////////////

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
* Announce Plugin info if player is still connected
*/
public announce(id)
{
	if(is_user_connected(id))
	{
		client_print(id,print_chat,"%s CSDMsake %s has been developed by sake, visit %s for more info!", PLUGIN_IDENTIFIER, VERSION, WEBSITE);
	}
}
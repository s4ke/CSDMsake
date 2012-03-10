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
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define AUTHOR	"sake"
#define VERSION	"1.1e"
#define PLUGIN	"csdmsake"

#define ANNOUNCE_TIME 5.0

#define DEFAULT_GODMODETIME "1.5"
#define RESPAWN_TIME 0.5

#define BOT_CREATE_NUMBER 6
#define BOT_KICK_NUMBER 10
#define BOT_CREATE_FAIL_NUMBER 5

#define COLOR_T {255,0,0}
#define COLOR_CT {0,0,255}

//String constants that are used more than once
new const PLUGIN_IDENTIFIER[] = "[CSDMsake]";
new const PLUGIN_ROUNDENDBLOCKER[] = "[CSDMsake - RoundEndblocker]";
new const WEBSITE[] = "http://csdmsake.dyndns.org/";
new const BOT_NAMES[][] = {"CSDMsake RoundEndBlocker1","CSDMsake RoundEndBlocker2"}

//Float constants that are used more than once
new const Float:BOT_ORIGIN[] = {9999.0, 9999.0, 9999.0};

//pointer for CVAR for spawnprotection
new sv_godmodetime;

//vars/constants for RoundEndBlocking
new g_botnum = 0;
new g_bots[2];
new g_failCount = 0;

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
	//register_event("DeathMsg", "playerKilled", "a");
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
	RegisterHam(Ham_Killed,"player", "playerKilled", 1);
}

/////////////////////////////////////Forwarded Functions//////////////////////////////////////

/*
* make sure everything is back to default, playernumber+1, maybe kick bots
*/
public client_connect(id)
{
	
	g_firstTeamJoin[id-1] = true;
	++g_players;
	if(g_botnum > 0 && g_players > BOT_KICK_NUMBER)
	{
		kickBots();
	}
}

/*
* If user disconnects
*/
public client_disconnect(id)
{
	if(id == g_bots[0])
	{
		g_bots[0] = -1;
		--g_botnum;
	}
	else if(id == g_bots[1])
	{
		g_bots[1] = -1;
		--g_botnum;
	}
	--g_players;
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
	if(g_players < g_maxPlayers -1 && g_players <= BOT_CREATE_NUMBER)
	{
		while(g_botnum < 2 && g_failCount < BOT_CREATE_FAIL_NUMBER)
		{
			createBot();
		}
		if(g_failCount >= BOT_CREATE_FAIL_NUMBER)
		{
			server_print("%s RoundEndBlocker creation failed 5 times in a row. No RoundEndBlockers for this map!", PLUGIN_ROUNDENDBLOCKER);
			kickBots();
		}
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
	if(is_user_alive(id))
	{
		startGodMode(id);
		set_task(get_pcvar_float(sv_godmodetime),"stopGodMode",id);
	}
}	

/*
* function for respawning on death
*/
public playerKilled(id)
{
	set_task(RESPAWN_TIME,"spawnPlayer",id);
}

/*
* called on change of TeamInfo. spawns player if neccessary
*/
public teamAssigned()
{
	new id = read_data(1);
	if(id != g_bots[0] && id != g_bots[1] && !is_user_hltv(id) && is_user_connected(id))
	{
		if(is_user_alive(id))
		{
			g_firstTeamJoin[id-1] = true;
		}
		else
		{
			new szTeam[2];
			read_data(2, szTeam, charsmax(szTeam))
			switch(szTeam[0])
			{
				case 'T','C':
				{
					if(g_firstTeamJoin[id-1])
					{
						g_firstTeamJoin[id-1] = false;
						set_task(ANNOUNCE_TIME, "announce", id);
					}
					else
					{
						dllfunc(DLLFunc_Spawn, id);
						g_firstTeamJoin[id-1] = true;
					}
				}
				default:
				{
					g_firstTeamJoin[id-1] = true;
				}
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
	}
	if(g_bots[1] && is_user_connected(g_bots[1]))
	{
		server_print("[CSDMsake - RoundEndBlocker] Kicking bot!");
		server_cmd("kick #%d", get_user_userid(g_bots[1]));
	}
}

/*
* Creates 1 RoundEndBlocker. If fails 5 times no more Bots will be created on this map
*/
public createBot()
{
	new bot;
	bot = engfunc(EngFunc_CreateFakeClient, BOT_NAMES[g_botnum]);
	if(bot) 
	{
		new ptr[128];
		engfunc(EngFunc_FreeEntPrivateData, bot);
		dllfunc(DLLFunc_ClientConnect, bot, BOT_NAMES[g_botnum], "127.0.0.1", ptr);
		if(is_user_connected(bot)) 
		{
			dllfunc(DLLFunc_ClientPutInServer, bot);
			set_pev(bot, pev_spawnflags, pev(bot, pev_spawnflags) | FL_FAKECLIENT);
			set_pev(bot, pev_flags, pev(bot, pev_flags) | FL_FAKECLIENT);
			set_pev(bot, pev_flags, pev(bot, pev_flags) | FL_CUSTOMENTITY);
			cs_set_user_team(bot, g_botnum % 2 ? CS_TEAM_T : CS_TEAM_CT);
			server_print("%s ^"%s^" has been created.", PLUGIN_ROUNDENDBLOCKER, BOT_NAMES[g_botnum]);
			g_bots[g_botnum++] = bot;
			g_failCount = 0;
		}
		else
		{
			server_print("%s Error: %s", PLUGIN_ROUNDENDBLOCKER, ptr);
			++g_failCount;
		}
	}
	else
	{
		server_print("%s Error: Couldn't create FakeClient",PLUGIN_ROUNDENDBLOCKER);
		++g_failCount;
	}
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
	//new msgTeamInfo = get_user_msgid("TeamInfo");
	//message_begin(MSG_ALL, msgTeamInfo);
	//write_byte(bot);
	//write_string("SPECTATOR");
	//message_end();
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
	if(is_user_alive(id))
	{
		set_user_godmode(id,1);
		if(get_user_team(id) == 1)
		{
			glow(id,COLOR_T,25);
		}
		if(get_user_team(id) == 2)
		{
			glow(id,COLOR_CT,25);
		}
	}
}

/*
* used to stop the godmode. Only if user is connected (so he isn't dead or left the game)
*/
public stopGodMode(id)
{
	if(is_user_connected(id))
	{
		set_user_godmode(id,0);
		unglow(id);
	}
}



/////////////////////////////////////Respawning, giving Weapons, Teams, etc.//////////////////////////////////////

/*
* simple spawnPlayer method. spawns player.
* credits:
* https://forums.alliedmods.net/showpost.php?p=678294&postcount=19
*/
public spawnPlayer(id)
{
	// Disconnected, already spawned, or switched to Spectator -> do nothing
	if (is_user_connected(id) 
	&& !is_user_alive(id) 
	&& cs_get_user_team(id) != CS_TEAM_SPECTATOR 
	&& cs_get_user_team(id) != CS_TEAM_UNASSIGNED)
	{   
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
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

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>

#define PLUGIN	"csdmsake_fixes"
#define AUTHOR	"sake"
#define VERSION	"1.1e"

new const maps[12][] =
{
	"boot_camp",
	"bounce",
	"crossfire",
	"datacore",
	"frenzy",
	"lambda_bunker",
	"rapidcore",
	"snark_pit",
	"stalkyard",
	"subtransit",
	"undertow",
	"cs_deagle5"
}

new map[32];
new g_spawn = -1;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	if(!(g_spawn == -1))
	{
		unregister_forward(FM_Spawn, g_spawn);
	}
}

public plugin_precache()
{
	new bool:correct;
	get_mapname(map, 31);
	for(new i = 0; i < 12 && !correct; i++)
	{
		correct = bool:equal(map, maps[i],sizeof(map));
	}
	if(correct)
	{
		g_spawn = register_forward(FM_Spawn, "forward_spawn");
	}
}

public forward_spawn(ent) 
{
	if (!pev_valid(ent))
	{
		return FMRES_IGNORED;
	}
	static classname[32];
	pev(ent, pev_classname, classname, sizeof classname - 1);
	server_print("creating %s",classname);
	if (equal(classname, "info_player_deathmatch")) 
	{
		new ent2 = create_entity("info_player_start");
		new vec[3];
		
		pev(ent, pev_origin, vec);
		set_pev(ent2, pev_origin, vec);
		
		pev(ent, pev_angles, vec);
		set_pev(ent2, pev_angles, vec);
		
		pev(ent, pev_v_angle, vec)
		set_pev(ent2, pev_v_angle, vec);
	}
	else if(equal(classname, "ambient_generic"))
	{
		server_print("%s has been created and blocked",classname);
		return FMRES_SUPERCEDE;
	}
	if(equal(map,maps[11]))
	{
		if(equal(classname, "player_weaponstrip") 
			|| equal(classname, "game_player_equip") 
			|| equal(classname, "multi_manager"))
		{
			server_print("%s has been created and blocked",classname);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}
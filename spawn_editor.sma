/**
 * csdm_preset_editor.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Preset Spawn Editor
 *
 * By Freecode
 * (C)2003-2005 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 * 	
 * 	Edited by sake
 *  Just removed original CSDM dependencies.
 */

//Tampering with the author and name lines will violate copyrights
new PLUGINNAME[] = "CSDM Spawn Editor"
new VERSION[] = "2.00"
new AUTHORS[] = "CSDM Team"

#include <amxmisc>
#include <engine>

#define MAX_SPAWN_DISATNCE	2500
#define	MAX_SPAWNS 			60

//Menus
new g_MainMenu[] = "CSDM: Spawn Manager";	// Menu Name
new g_MainMenuID = -1;				// Menu ID
new g_cMain;

new g_EditMenu[] = "CSDM: Edit Spawns Menu";
new g_EditMenuID;

new g_SpawnVecs[MAX_SPAWNS][3];
new g_TotalSpawns;

new g_Ents[MAX_SPAWNS];
new g_Ent[33];					// Current closest spawn

new Float:red[3] = {255.0,0.0,0.0};
new Float:green[3] = {0.0,255.0,0.0};
new Float:yellow[3] = {255.0,200.0,20.0};

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);

// Create Menus
	g_MainMenuID = menu_create(g_MainMenu, "m_MainHandler");
	g_EditMenuID = menu_create(g_EditMenu, "m_EditHandler");

//Menu Callbacks
	g_cMain = menu_makecallback("c_Main");
	
	readSpawns()
	buildMenu()
	makeEnts(-1);
	
	//test
	register_concmd("edit_spawns", "showmen", ADMIN_MAP, "Edits spawn configuration");
}

public plugin_precache()
{
	precache_model("sprites/shadow_circle.spr");
}

readSpawns()
{
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 63, "%s\csdm\%s_spawns.cfg",config, Map);
	g_TotalSpawns = 0;
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[4][8];
    		
		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7);
			
			g_TotalSpawns++;
			
			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_num(pos[1]);
			g_SpawnVecs[g_TotalSpawns][1] = str_to_num(pos[2]);
			g_SpawnVecs[g_TotalSpawns][2] = str_to_num(pos[3]);
			
			
		}
	}
}

buildMenu()
{
//Main Menu
	menu_additem(g_MainMenuID, "Add Current Postion","1", 0, g_cMain);
	menu_additem(g_MainMenuID, "Edit Spawn","2", 0, g_cMain);
	menu_additem(g_MainMenuID, "Delete Spawn","3", 0, g_cMain);
	menu_additem(g_MainMenuID, "Refresh Closest Spawn", "4", 0, g_cMain);
	
//Edit Menu
	menu_additem(g_EditMenuID, "Edit selected spawn (yellow) to Current Position","1",0, -1);

}

makeEnts(id)
{
	new iEnt;

	if(id < 0)
	{
		for (new x = 1; x <= g_TotalSpawns; x++)
		{
	
			iEnt = create_entity("info_target" );

			entity_set_model(iEnt, "sprites/shadow_circle.spr");
			g_Ents[x] = iEnt;
			
			ent_unglow(x);
		}
	}
	else
	{
		iEnt = create_entity("info_target" );
		
		entity_set_model(iEnt, "sprites/shadow_circle.spr");
		g_Ents[id] = iEnt;
			
		ent_unglow(id);
	}
}

public m_MainHandler(id, menu, item)
{
	if (item < 0)
	{
		for (new x = 1; x <= g_TotalSpawns; x++)
		{
			ent_unglow(x);
		}
		return PLUGIN_CONTINUE;
	}
	
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	
	new iChoice = str_to_num(cmd);

	
	new Float:vecs[3], vec[3];
	new Float:angles[3], angle[3];
	new Float:vangles[3], vangle[3];
	
	switch(iChoice)
	{
		case 1:
		{
			entity_get_vector(id, EV_VEC_origin, vecs);
			entity_get_vector(id, EV_VEC_angles, angles);
			entity_get_vector(id, EV_VEC_v_angle, vangles);
			
			FVecIVec(vecs,vec);
			FVecIVec(angles,angle);
			FVecIVec(vangles,vangle);
			
			add_spawn(vec,angle,vangle);
			
			menu_display ( id, g_MainMenuID, 0);
		}
		case 2:
		{
			ent_glow(g_Ent[id],yellow);
			menu_display(id, g_EditMenuID, 0);
		}
		case 3:
		{
			delete_spawn(g_Ent[id]);
			
			menu_display(id, g_MainMenuID, 0);
		}
		case 4:
			menu_display(id, g_MainMenuID, 0);
	}
	
	return PLUGIN_HANDLED;
}

public c_Main(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE
	
	new cmd[6], fItem[326], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new num = str_to_num(cmd);
	g_Ent[id] = closest_spawn(id);
	
	illuminate_spawns(id)
	
	if (num == 1)
	{
		if (g_TotalSpawns == MAX_SPAWNS)
		{
			format(fItem,325,"Add Current Position   Max Spawn Limit Reached");
			menu_item_setname(menu, item, fItem );
			return ITEM_DISABLED;
		}
		else
		{
			format(fItem,325,"Add Current Position");
			menu_item_setname(menu, item, fItem );
			return ITEM_ENABLED;
		}
	}
	else if (num == 2)
	{
		if (g_TotalSpawns < 1)
		{
			format(fItem,325,"Edit Spawn   No spawns");
			menu_item_setname(menu, item, fItem );
			return ITEM_DISABLED;
		}
		else
		{
			format(fItem,325,"Edit Spawn");
			menu_item_setname(menu, item, fItem );
			return ITEM_ENABLED;
		}
	}
	else if (num == 3)
	{
		if (g_TotalSpawns < 1)
		{
			format(fItem,325,"Delete Spawn   No spawns");
			menu_item_setname(menu, item, fItem );
			return ITEM_DISABLED;
		}
		else
		{
			format(fItem,325,"Delete Spawn");
			menu_item_setname(menu, item, fItem );
			return ITEM_ENABLED;
		}
	}
	
	return PLUGIN_HANDLED;
}

public m_EditHandler(id, menu, item)
{
	if (item < 0)
	{
		for (new x = 1; x <= g_TotalSpawns; x++)
		{
			ent_unglow(x);
		}
		return PLUGIN_CONTINUE;
	}

	
	new Float:vecs[3], vec[3];
	new Float:angles[3], angle[3];
	new Float:vangles[3], vangle[3];
	
	entity_get_vector(id, EV_VEC_origin, vecs);
	entity_get_vector(id, EV_VEC_angles, angles);
	entity_get_vector(id, EV_VEC_v_angle, vangles);
			
	FVecIVec(vecs,vec);
	FVecIVec(angles,angle);
	FVecIVec(vangles,vangle);
			
	edit_spawn(g_Ent[id],vec,angle,vangle);

	
	menu_display ( id, g_MainMenuID, 0);
	
	return PLUGIN_HANDLED;
}

	
//:TODO: Add team support
add_spawn(vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir(config, 31 )
	format(MapFile, 63, "%s\csdm\%s_spawns.cfg",config, Map);

	new line[128];
	format(line, 127, "%d %d %d %d %d %d %d %d %d 0",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], vangles[0], vangles[1], vangles[2]);
	write_file(MapFile, line, -1);
	
	g_TotalSpawns++;
	g_SpawnVecs[g_TotalSpawns][0] = vecs[0];
	g_SpawnVecs[g_TotalSpawns][1] = vecs[1];
	g_SpawnVecs[g_TotalSpawns][2] = vecs[2];
	
	makeEnts(g_TotalSpawns);
	
}

edit_spawn(ent, vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 63, "%s\csdm\%s_spawns.cfg",config, Map);
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[4][8];
    		new currentVec[3], newSpawn[128];
    		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			
			parse(Data,pos[1],7,pos[2],7,pos[3],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			
			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && (g_SpawnVecs[ent][2] == currentVec[2]) )
			{	
				format(newSpawn, 127, "%d %d %d %d %d %d %d %d %d 0",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], vangles[0], vangles[1], vangles[2]);
				write_file(MapFile, newSpawn, line);
				
				g_SpawnVecs[ent][0] = vecs[0];
				g_SpawnVecs[ent][1] = vecs[1];
				g_SpawnVecs[ent][2] = vecs[2];
					
				ent_glow(ent,red);
				
				break
			}
		}
	}
}
	
delete_spawn(ent)
{
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir ( config, 31 )
	format(MapFile, 63, "%s\csdm\%s_spawns.cfg",config, Map);
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[4][8];
    		new currentVec[3];
    		
		while ((line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2) continue;
			
			parse(Data,pos[1],7,pos[2],7,pos[3],7);
			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);
			
			if ( (g_SpawnVecs[ent][0] == currentVec[0]) && (g_SpawnVecs[ent][1] == currentVec[1]) && (g_SpawnVecs[ent][2] == currentVec[2]) )
			{
				write_file(MapFile, "", line-1);
				
				for (new x = 1; x <= g_TotalSpawns; x++)
				{
					ent_remove(x);
				}
				readSpawns();
				makeEnts(-1);
				
				break
			}
		}
	}
}

closest_spawn(id)
{
	new origin[3];
	new lastDist = 999999;
	new closest;
	
	get_user_origin(id, origin);
	for (new x = 1; x <= g_TotalSpawns; x++)
	{
		new distance = get_distance(origin, g_SpawnVecs[x]);
		
		if (distance < lastDist)
		{
			lastDist = distance;
			closest = x;
		}
	}
	return closest;
}

illuminate_spawns(id)
{
	new origin[3];
	new lastDist = 999999;
	new closest;
	
	get_user_origin(id, origin);
	for (new x = 1; x <= g_TotalSpawns; x++)
	{
		new distance = get_distance(origin, g_SpawnVecs[x]);
		
		if (distance < MAX_SPAWN_DISATNCE && is_valid_ent(g_Ents[x]))
		{
			ent_glow(x,green);
			
			if(distance < lastDist)
			{
				lastDist = distance;
				closest = x;
			}
		}
	}
	
	ent_glow(closest,red)
}

ent_remove(ent)
{
	if ( is_valid_ent(g_Ents[ent]) )
	{
		remove_entity(g_Ents[ent]);
	}
}

ent_glow(ent,Float:color[3])
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		new Float:org[3];
		IVecFVec(g_SpawnVecs[ent],org);		
		entity_set_origin( iEnt, org);
		
		entity_set_int(	iEnt, EV_INT_renderfx, kRenderFxGlowShell); 
		entity_set_float(iEnt, EV_FL_renderamt, 255.0);
		entity_set_int(	iEnt, EV_INT_rendermode, kRenderTransAlpha);
		entity_set_vector(iEnt, EV_VEC_rendercolor, color) ;
	}
	
}

ent_unglow(ent)
{
	new iEnt = g_Ents[ent];
	
	if (iEnt)
	{
		new Float:org[3];
		IVecFVec(g_SpawnVecs[ent],org);		
		entity_set_origin( iEnt, org);
		
		entity_set_int(	iEnt, EV_INT_renderfx, kRenderFxGlowShell); 
		entity_set_float(iEnt, EV_FL_renderamt, 0.0);
		entity_set_int(	iEnt, EV_INT_rendermode, kRenderTransAlpha);
	}
	
}

public showmen(id)
{
	menu_display ( id, g_MainMenuID, 0);
	
	return PLUGIN_HANDLED;
}
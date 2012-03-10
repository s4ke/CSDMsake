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
#include <fakemeta>
#include <hamsandwich>
#include <fun>

#define PLUGIN	"csdmsake_equip"
#define AUTHOR	"sake"
#define VERSION	"1.1e"

#define PRIMARY_WEAPON_COUNT 16
#define SECONDARY_WEAPON_COUNT 6
#define TOTAL_WEAPON_COUNT 22
#define DEFAULT_WEAPONS "4194303"

//String constants that are used more than once
new const PLUGIN_IDENTIFIER[] = "[CSDMsake]";
new const WPN_KNIFE[] = "weapon_knife";

enum Weapon
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
	SG550,
	DEAGLE,
	USP,
	GLOCK,
	ELITE,
	FIVESEVEN,
	P228,
	NOWEAPON
}

new const WEAPON_NAME[Weapon][] =
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
	"weapon_sg550",
	"weapon_deagle",
	"weapon_usp",
	"weapon_glock18",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_p228",
	""
};

new const WEAPON_DISPLAY_NAME[Weapon][] = 
{
	"M4A1",
	"AK-47",
	"SG552",
	"AUG",
	"M3",
	"MP5",
	"PARA",
	"AWP",
	"Scout",
	"P90",
	"XM1014",
	"Mac10",
	"UMP45",
	"TMP",
	"G3SG1",
	"SG550",
	"Desert Eagle",
	"USP",
	"Glock18",
	"Dual Elites",
	"Five-Seven",
	"P228",
	""
};

new const WEAPON_AMMO[Weapon][] =
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
	"556nato",
	"50ae",
	"45acp",
	"9mm",
	"9mm",
	"57mm",
	"357sig",
	""
};

//vars for weapons
new Weapon:g_primary[32] = NOWEAPON;
new Weapon:g_secondary[32] = NOWEAPON;
new bool:g_remember[32];
new bool:g_hasWeapons[32];

//pointer for CVAR for Weapon-banning
new sv_weapons;
new g_weapons = 0;

//menus
new g_menu_main;
new g_menu_prim;
new g_menu_sec;

//banned weapon counters
new g_banned_count_prim;
new g_banned_count_sec;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	if(cstrike_running())
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);
		initVars();
		initMenus();
		registerHamHooks();
		registerClCommands()
		registerSayCommands();
	}
}

public client_connect(id)
{
	g_primary[id-1] = NOWEAPON;
	g_secondary[id-1] = NOWEAPON;
	g_remember[id-1] = false;
	g_hasWeapons[id-1] = false;
	if(is_user_bot(id))
	{
		g_primary[id-1] = M4A1;
		g_secondary[id-1] = DEAGLE;
	}
}

initVars()
{
	sv_weapons = register_cvar("sv_weapons", DEFAULT_WEAPONS , FCVAR_SERVER);
	g_weapons = get_pcvar_num(sv_weapons);
}

initMenus()
{
	//Main Menu Initialization
	g_menu_main = menu_create("Weapon Main Menu","mainMenuHandle");
	menu_additem(g_menu_main,"New Weapons");
	menu_additem(g_menu_main,"Last Weapons");
	menu_additem(g_menu_main,"Remember Weapons");	
	menu_setprop(g_menu_main, MPROP_EXIT, MEXIT_NEVER);
	
	new callback_prim = menu_makecallback("primaryMenuCallback");
	new callback_sec  = menu_makecallback("secondaryMenuCallback");
	
	//PrimaryWeapon Menu Initialization
	new i = 0;
	g_menu_prim = menu_create("Primary Weapons","primaryWeaponPicked");
	do
	{
		menu_additem(g_menu_prim,WEAPON_DISPLAY_NAME[Weapon:i], "", 0, callback_prim);
		if(!(g_weapons & (1<<i)))
		{
			++g_banned_count_prim;
		}
		++i;
	} while(i < PRIMARY_WEAPON_COUNT);
	if(g_banned_count_prim < PRIMARY_WEAPON_COUNT)
	{
		menu_setprop(g_menu_prim, MPROP_EXIT, MEXIT_ALL);
	}
	else
	{
		menu_destroy(g_menu_prim);
	}
	
	//SecondaryWeapon Menu Initialization
	//Start at the first Secondary Weapon
	i = PRIMARY_WEAPON_COUNT;
	g_menu_sec = menu_create("Secondary Weapons","secondaryWeaponPicked");
	do
	{
		menu_additem(g_menu_sec,WEAPON_DISPLAY_NAME[Weapon:i], "", 0, callback_sec);
		if(!(g_weapons & (1<<i)))
		{
			++g_banned_count_sec;
		}
		++i;
	} while(i < TOTAL_WEAPON_COUNT);
	if(g_banned_count_sec < TOTAL_WEAPON_COUNT)
	{
		menu_setprop(g_menu_sec, MPROP_EXIT, MEXIT_ALL);
	}
	else
	{
		menu_destroy(g_menu_sec);
	}
}

registerSayCommands()
{
	register_clcmd("say /guns", "reenableMenu",0);
	register_clcmd("say guns", "reenableMenu",0);
	register_clcmd("say /ammo","giveAmmo",0);
	register_clcmd("say ammo","giveAmmo",0);
}

registerHamHooks()
{
	RegisterHam(Ham_Spawn, "player", "playerSpawned", 1);
}

registerClCommands()
{
	register_clcmd("buy", "blockCmd");
	register_clcmd("buyequip", "blockCmd");
	register_clcmd("buyammo1", "blockCmd");
	register_clcmd("buyammo2", "blockCmd");
	//register_clcmd("amx_allow_weapon", "allowWeapon", ADMIN_ALL, "Allow CSDM Weapon for current map");
	//register_clcmd("amx_ban_weapon", "banWeapon", ADMIN_ALL, "Ban CSDM Weapon for current map");
}

/*
* prevents commands
*/
public blockCmd(id)
{
	return PLUGIN_HANDLED;
}

/*
* called on spawn, if user is bot he gets default weapons, if not he can decide (showWeapons).
* Spawnprotection is turned on
*/
public playerSpawned(id)
{
	//don't do anything if it is one of the roundendblockers who has been spawned
	if(pev(id, pev_flags) != FL_CUSTOMENTITY && is_user_alive(id))
	{
		g_hasWeapons[id-1] = false;
		if(!is_user_bot(id) && !g_remember[id-1])
		{
			strip_user_weapons(id);
			give_item(id, WPN_KNIFE);
			new menu,menu2;
			player_menu_info(id, menu, menu2);
			//only show the menu if no other is being displayed
			if(menu == 0)
			{
				menu_display(id,g_menu_main,0);
			}
			else if(menu &&  !(menu2 == g_menu_main || menu2 == g_menu_prim || menu2 == g_menu_sec))
			{
				client_print(id,print_chat,"%s Another menu is being displayed, say /guns again after the menu has closed!", PLUGIN_IDENTIFIER,menu, g_menu_main, g_menu_prim, g_menu_sec);	
			}
		}
		else
		{
			//Bots get standard Weapons, and if g_remember == true players get the last weapons they selected
			giveWeapons(id);
		}
	}
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
			if(g_banned_count_prim == PRIMARY_WEAPON_COUNT)
			{
				if(g_banned_count_sec < SECONDARY_WEAPON_COUNT)
				{
					menu_display(id, g_menu_sec, 0);
				}
				else
				{
					client_print(id, print_chat,"%s No Weapons available!", PLUGIN_IDENTIFIER);
					g_remember[id-1] = true;
				}
			}
			else
			{
				menu_display(id,g_menu_prim,0);
			}
		}
		case 1:
		{
			if(g_primary[id-1] != NOWEAPON || g_secondary[id-1] != NOWEAPON)
			{
				giveWeapons(id);
			}
			else
			{
				client_print(id, print_chat,"%s No Weapons to reuse!", PLUGIN_IDENTIFIER);
				menu_display(id,g_menu_main,0);
			}
		}
		case 2:
		{
			if(g_primary[id-1] != NOWEAPON || g_secondary[id-1] != NOWEAPON)
			{
				g_remember[id-1] = true;
				giveWeapons(id);
				client_print(id,print_chat,"%s To re-enable the menu say /guns", PLUGIN_IDENTIFIER);
			}
			else
			{
				client_print(id, print_chat,"%s No Weapons to remember!", PLUGIN_IDENTIFIER);
				menu_display(id,g_menu_main,0);
			}
		}
	}
}

/*
* called after primary weapons menu is closed. Gives weapon to player
*/
public primaryWeaponPicked(id, menu, item)
{
	if(item != MENU_EXIT)
	{
		g_primary[id-1] = Weapon:item
		//display the secondary weapons menu if possible
		if(g_banned_count_sec < SECONDARY_WEAPON_COUNT)
		{
			menu_display(id, g_menu_sec, 0);
		}
		else
		{
			giveWeapons(id);
		}
	}
	else
	{
		menu_display(id,g_menu_main,0);
	}
}

public primaryMenuCallback(id, menu, item)
{
	return g_weapons & (1<<item) ? ITEM_ENABLED : ITEM_DISABLED;
}

/*
* called after secondary weapons menu is closed. Gives weapon to player
*/
public secondaryWeaponPicked(id, menu, item)
{
	if(item != MENU_EXIT)
	{
		g_secondary[id-1] = Weapon:(item + PRIMARY_WEAPON_COUNT);
		giveWeapons(id);
	}
	else
	{
		menu_display(id,g_menu_main,0);
	}
}

public secondaryMenuCallback(id, menu, item)
{
	return g_weapons & (1<<item + PRIMARY_WEAPON_COUNT) ? ITEM_ENABLED : ITEM_DISABLED;
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
	}
	else
	{
		new menu, keys;
		get_user_menu(id,menu,keys);
		if(menu == 0)
		{
			menu_display(id,g_menu_main,0);
		}
	}
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
		if(isValidWeapon(g_primary[id-1]))
		{
			give_item(id,WEAPON_NAME[g_primary[id-1]]);
		}
		
		//give the user the secondary weapon he has chosen
		if(isValidWeapon(g_secondary[id-1]))
		{
			give_item(id,WEAPON_NAME[g_secondary[id-1]]);
		}
		
		//give the user his knife back
		give_item(id,WPN_KNIFE);	
		
		giveAmmo(id);
		g_hasWeapons[id-1] = true;
	}
}

/*
* Gives the user the ammo for his weapons
*/
public giveAmmo(id)
{
	if(isValidWeapon(g_primary[id-1]))
	{
		ExecuteHamB(Ham_GiveAmmo, id, 200,WEAPON_AMMO[g_primary[id-1]],200);
	}
	if(isValidWeapon(g_secondary[id-1]))
	{
		ExecuteHamB(Ham_GiveAmmo, id, 200,WEAPON_AMMO[g_secondary[id-1]],200);
	}
}

bool:isValidWeapon(Weapon:num)
{
	return num < NOWEAPON;
}
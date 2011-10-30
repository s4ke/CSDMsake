/* 
* csdmdisplay
* creates a display for Kills and Deaths instead of the Time
* some code from VEN and changed (noobjectives-Plugin)
*/

#include <amxmisc>
#include <cstrike>
#include <amxmodx>

#define PLUGIN	"csdmsake_display"
#define AUTHOR	"sake"
#define VERSION	"1.1"
#define taskID 23112
#define HIDE (1<<4) | (1<<5)

new g_msgid_hideweapon;
new g_hudSyncObject;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("ScoreInfo","scoreInfoChanged","a");
	g_msgid_hideweapon = get_user_msgid("HideWeapon");
	register_message(g_msgid_hideweapon, "messageHideWeapon");
	set_msg_block(get_user_msgid("RoundTime"),BLOCK_SET);
	register_event("ResetHUD", "eventHudReset", "b");
	set_msg_block(get_user_msgid("RoundTime"), BLOCK_SET);
	g_hudSyncObject = CreateHudSyncObj();
}

public scoreInfoChanged(id)
{
	new args[3];
	args[0] = read_data(1);
	args[1] = read_data(2);
	args[2] = read_data(3);
	set_task(0.1,"showScore",id+taskID, args, 3);
}

public showScore(args[3])
{
	new id = args[0];
	new task = id + taskID;
	if(task_exists(task))
	{
		remove_task(task);
	}
	set_hudmessage(255,255,255,0.5,1.0,0,0.0,120.0,0.0,0.0);
	ShowSyncHudMsg(id,g_hudSyncObject,"K/D: %i/%i",args[1],args[2]);
	set_task(100.0,"showScore",task, args, 3);
}

public messageHideWeapon() 
{
	set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | HIDE);
}

public eventHudReset(id) 
{
	removeGUI(id);
	new args[3];
	args[0] = id;
	args[1] = get_user_frags(id);
	args[2] = get_user_deaths(id);
	set_task(0.1,"showScore", id+taskID,args, 3);
}

public removeGUI(id)
{
	message_begin(MSG_ONE, g_msgid_hideweapon, _, id);
	write_byte(HIDE);
	message_end();
}

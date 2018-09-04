#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <levelup>

#define PLUGIN "Level-UP - Health"
#define VERSION "1.0"
#define AUTHOR "Sneaky@GlobalModders.net"

#define MAX_LEVEL 10
#define REQ_LEVEL 0

new skill_id;
new bool: round_started;

stock Float:CS_WEAPON_SPEED[31] =
{
	0.0,
	250.0,      // CSW_P228
	0.0,
	260.0,      // CSW_SCOUT
	250.0,      // CSW_HEGRENADE
	240.0,      // CSW_XM1014
	250.0,      // CSW_C4
	250.0,      // CSW_MAC10
	240.0,      // CSW_AUG
	250.0,      // CSW_SMOKEGRENADE
	250.0,      // CSW_ELITE
	250.0,      // CSW_FIVESEVEN
	250.0,      // CSW_UMP45
	210.0,      // CSW_SG550
	240.0,      // CSW_GALI
	240.0,      // CSW_FAMAS
	250.0,      // CSW_USP
	250.0,      // CSW_GLOCK18
	210.0,      // CSW_AWP
	250.0,      // CSW_MP5NAVY
	220.0,      // CSW_M249
	230.0,      // CSW_M3
	230.0,      // CSW_M4A1
	250.0,      // CSW_TMP
	210.0,      // CSW_G3SG1
	250.0,      // CSW_FLASHBANG
	250.0,      // CSW_DEAGLE
	235.0,      // CSW_SG552
	221.0,      // CSW_AK47
	250.0,      // CSW_KNIFE
	245.0       // CSW_P90
};

public plugin_precache()
{
	new skillid[7];
	create_skill("Speed", MAX_LEVEL, skillid, REQ_LEVEL);
	skill_id = str_to_num(skillid);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("levelup_speed", "10.0");
	
	register_logevent("round_start", 2, "1=Round_Start");
	register_logevent("round_end", 2, "1=Round_End");
	register_logevent("round_end", 2, "1&Restart_Round_");
}

public round_start()
{
	round_started = true;
}

public round_end()
{
	round_started = false;
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || !round_started)
		return;
	
	new wpn = get_user_weapon(id);
	new Float:speed;
	speed = CS_WEAPON_SPEED[wpn];
	speed += get_cvar_float("levelup_speed") * get_skill_level(id, skill_id);
	set_pev(id, pev_maxspeed, speed);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

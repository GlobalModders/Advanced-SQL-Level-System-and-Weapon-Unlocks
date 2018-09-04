#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <levelup>

#define PLUGIN "Level-UP - Health"
#define VERSION "1.0"
#define AUTHOR "Sneaky@GlobalModders.net"

#define MAX_LEVEL 50
#define REQ_LEVEL 0

new skill_id;

public plugin_precache()
{
	new skillid[7];
	create_skill("Health", MAX_LEVEL, skillid, REQ_LEVEL);
	skill_id = str_to_num(skillid);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("levelup_health", "2");
	
	RegisterHam( Ham_Spawn, "player", "on_Spawn", 1 );
}

public on_Spawn(id)
{
	set_pev(id, pev_health, 100.0 + (get_cvar_float("levelup_health") * get_skill_level(id, skill_id)));
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

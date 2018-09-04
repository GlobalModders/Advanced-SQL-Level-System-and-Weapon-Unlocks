#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <levelup>

#define PLUGIN "Level-UP - Damage"
#define VERSION "1.0"
#define AUTHOR "Sneaky@GlobalModders.net"

#define MAX_LEVEL 50
#define REQ_LEVEL 0

new skill_id;

public plugin_precache()
{
	new skillid[7];
	create_skill("Damage", MAX_LEVEL, skillid, REQ_LEVEL);
	skill_id = str_to_num(skillid);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_cvar("levelup_damage", "0.1");
	
	RegisterHam( Ham_TakeDamage, "info_target", "take_damage" );
}

public take_damage(Victim, idInflictor, iAttacker, Float: flDamage, bitsDamageType)
{
	if(!is_user_connected( iAttacker )) return;
	new Float: damage = flDamage + (flDamage * (get_skill_level(iAttacker, skill_id) * get_cvar_float("levelup_damage")));
	SetHamParamFloat(4, damage);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

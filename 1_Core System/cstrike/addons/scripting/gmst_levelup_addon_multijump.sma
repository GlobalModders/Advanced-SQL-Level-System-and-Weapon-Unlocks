#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <levelup>

#define PLUGIN "Level-UP - Multijump"
#define VERSION "1.0"
#define AUTHOR "Sneaky@GlobalModders.net"

#define MAX_LEVEL 3
#define REQ_LEVEL 0

new jumpnum[33] = 0;
new bool:dojump[33] = false;
new skill_id;

public plugin_precache()
{
	new skillid[7];
	create_skill("Multijump", MAX_LEVEL, skillid, REQ_LEVEL);
	skill_id = str_to_num(skillid);
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public client_putinserver(id)
{
	jumpnum[id] = 0;
	dojump[id] = false;
}

public client_disconnect(id)
{
	jumpnum[id] = 0;
	dojump[id] = false;
}

public client_PreThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	new nbut = get_user_button(id);
	new obut = get_user_oldbutton(id);
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[id] < get_skill_level(id, skill_id))
		{
			dojump[id] = true;
			jumpnum[id]++;
			return PLUGIN_CONTINUE;
		}
	}
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0;
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public client_PostThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	if(dojump[id] == true)
	{
		new Float:velocity[3];
		entity_get_vector(id,EV_VEC_velocity,velocity);
		velocity[2] = 275.0;
		entity_set_vector(id,EV_VEC_velocity,velocity);
		dojump[id] = false;
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

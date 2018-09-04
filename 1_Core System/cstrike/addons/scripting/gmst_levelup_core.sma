#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <dhudmessage>
#include <fun>
#include <cstrike>
#include <sqlvault>
#include <hamsandwich>
#include <fakezombiebot>

#define PLUGIN "Level-UP - Main"
#define VERSION "1.3"
#define AUTHOR "GlobalModders.net Dev Team"

#define MAX_LEVEL	100
#define MAX_SKILLS	32
#define POINT_PERLEVEL	2

#define LOGINDELAY 	60

#define SQL_HOST 	"globalmodders.net"
#define SQL_USER 	"globalmo_jaeger"
#define SQL_PASS 	"?.PU^gAaK&ch"
#define SQL_DB 		"globalmo_vergissmeinnicht"


new playerlevel[33], playerxp[33], playerpoints[33];
new levelup_skill[MAX_SKILLS][31], levelup_skill_max[MAX_SKILLS], req_level[MAX_SKILLS], num_skills;
new player_skill[MAX_SKILLS][33], skill_page[33], bool: lastpage[33];
new xp_ratio;
new levelspr, levelspr2;
new const gSoundLevel[] = "plats/elevbell1.wav";
new bool: is_primary[MAX_SKILLS], bool: has_primary[33], dropped_primary[33];
new bool: is_secondary[MAX_SKILLS], bool: has_secondary[33], dropped_secondary[33];
new bool: just_dropped[33], ammo[33];
new bool: is_melee[MAX_SKILLS], bool: has_melee[33];

  /////////////////////
 // test make bonus //
/////////////////////
new bool: is_bonus[MAX_SKILLS], bool: has_bonus[33], dropped_bonus[33];

new primary_name[33][32], secondary_name[33][32], melee_name[33][32], bonus_name[33][32];
new hudsync1;

new SZ_Password[33][192], SZ_Username[33][192], Registrado[33],
Registradoylogeado[33], bool: mudarcuenta[33], seguridad[33],
SQLVault: Vault;

new segundos[33];

public plugin_precache()
{
	levelspr = engfunc(EngFunc_PrecacheModel, "sprites/xfire.spr");
	levelspr2 = engfunc(EngFunc_PrecacheModel, "sprites/xfire2.spr");
	precache_sound(gSoundLevel);
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("jointeam", "login");
	register_clcmd("say /skills", "menu_skills");
	register_clcmd("say /resetskills", "reset_skills");
	register_clcmd("say /resetlevel", "reset_level");

	hudsync1 = CreateHudSyncObj( );
	set_task( 5.0, "game_hud" );
	
	RegisterHam(Ham_Killed, "player", "player_killed");
	register_touch("weaponbox", "player", "player_touch_weapon");
	
	register_cvar("xp_ratio", "3");
	register_concmd("givexp", "give_xp", ADMIN_LEVEL_D, "<name> <xp>")
	
	register_menucmd(register_menuid("Skills Menu"), 1023, "skill_menu_action");
	
	register_clcmd("drop", "justdropped");
	
	//SQL Accounts
	register_clcmd("EnterPassword", "CMDIntroducirContrasenia");
	register_clcmd("EnterUsername", "CMDEnterUsername");
	//register_clcmd("EnterNick", "CMDIntroducirNick");
	register_forward(FM_ClientUserInfoChanged, "FWClientUserInfoChanged");
	Vault = sqlv_open(SQL_HOST, SQL_USER, SQL_PASS, SQL_DB, "LevelUP");
}

public plugin_natives()
{
	register_native("create_skill", "native_create_skill");
	register_native("get_skill_level", "native_get_skill_level");
	register_native("give_xp", "native_give_xp");
	register_native("make_primary", "native_make_primary");
	register_native("make_secondary", "native_make_secondary");
	register_native("user_dropped_primary", "native_user_dropped_primary");
	register_native("user_dropped_secondary", "native_user_dropped_secondary");
	register_native("make_melee", "native_make_melee");
	register_native("get_has_primary", "native_get_has_primary");
	register_native("get_has_secondary", "native_get_has_secondary");
	register_native("get_has_melee", "native_get_has_melee");

	register_native("make_bonus", "native_make_bonus");
	register_native("user_dropped_bonus", "native_user_dropped_bonus");
	register_native("get_has_bonus", "native_get_has_bonus");
}

public game_hud()
{
	static sz_text[512], sz_xp[512];
	for( new i; i <= 32; i++ )
	{
		if(is_user_alive(i)) {
			if(playerlevel[i] < MAX_LEVEL)
				formatex(sz_xp, charsmax(sz_xp), "/%i", calculatexp(i));
			else
				formatex(sz_xp, charsmax(sz_xp), "");
			formatex( sz_text, charsmax( sz_text ), "Level: %i/%i^nXP: %i%s^n^nPrimary: %s^nSecondary: %s^nMelee: %s^nBonus: %s", playerlevel[i], MAX_LEVEL, playerxp[i], sz_xp, primary_name[i], secondary_name[i], melee_name[i], bonus_name[i] );
			set_hudmessage(255, 255, 255, 0.01, 0.09, 0, 0.0, 3.1, 0.0, 0.0)
			ShowSyncHudMsg( i, hudsync1, sz_text );
		}
		else {
			if(!is_valid_ent(i))
				continue;
			new spec_id = entity_get_int(i, EV_INT_iuser2);
			if(is_user_alive(spec_id)) {
				if(playerlevel[spec_id] < MAX_LEVEL)
					formatex(sz_xp, charsmax(sz_xp), "/%i", calculatexp(spec_id));
				else
					formatex(sz_xp, charsmax(sz_xp), "");
				formatex( sz_text, charsmax( sz_text ), "Level: %i/%i^nXP: %i%s^n^nPrimary: %s^nSecondary: %s^nMelee: %s^nBonus: %s", playerlevel[spec_id], MAX_LEVEL, playerxp[spec_id], sz_xp, primary_name[spec_id], secondary_name[spec_id], 
				melee_name[spec_id], bonus_name[spec_id] );
				set_hudmessage(255, 255, 255, 0.01, 0.09, 0, 0.0, 3.1, 0.0, 0.0);
				ShowSyncHudMsg(i, hudsync1, sz_text);
			}
		}
	}
	set_task( 0.1, "game_hud" );
}

public give_xp(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return
		
	new arg1[32], arg2[32]
	read_argv(1, arg1, 31)
	read_argv(2, arg2, 31)
	
	new playername[32], player = 0
	for(new i = 1; i <= 32; i++) {
		if(is_user_connected(i)) {
			get_user_name(i, playername, 31)
			if(equal(playername, arg1)) {
				player = i
				i = 33
			}
		}
	}
	
	if(player == 0) {
		console_print(id, "[Level-UP] You should type a connected player's name!")
		return
	}
	
	playerxp[player] += str_to_num(arg2)
}

public client_connect(id)
{
	if(id == get_bot_id()) return;
	client_cmd(id, "setinfo _vgui_menus ^"1^"");
	playerxp[id] = 0;
	playerlevel[id] = 0;
	has_primary[id] = false;
	primary_name[id] = "None";
	has_secondary[id] = false;
	secondary_name[id] = "None";
	has_bonus[id] = false;
	bonus_name[id] = "None";
	has_melee[id] = false;
	melee_name[id] = "None";
	for(new i; i < MAX_SKILLS; i++)
		player_skill[i][id] = 0;
	mudarcuenta[id] = false;
	Registrado[id] = 0;
	Registradoylogeado[id] = 0;
	skill_page[id] = 0;
	format(SZ_Username[id], charsmax(SZ_Username[]), "");
	format(SZ_Password[id], charsmax(SZ_Password[]), "");
	set_task(0.1, "clcmd_changeteam", id);
}

public client_putinserver(id)       
{
	if(is_user_connected(id) && !(get_user_flags(id) & ADMIN_IMMUNITY) && !is_user_hltv(id)) {
		client_cmd(id, "setinfo _vgui_menus ^"1^"");
		segundos[id] = LOGINDELAY;
		set_task(0.1, "timer", id);
	}
}

public timer(id)
{
	if(id == get_bot_id()) return;
	if(! is_user_bot (id)
	&& Registradoylogeado[id] == 0) {
		if(segundos[id] > 0) {
			segundos[id] --;
			set_task(1.0, "timer", id);
		}
		else {
			server_print("test debug")
			server_cmd("kick #%d Max time to log-in expired, try again.", get_user_userid(id));
		}
	}
}

public client_disconnect(id)
{
	if(Registradoylogeado[id] == 1) Save(id);
	playerxp[id] = 0;
	playerlevel[id] = 0;
	has_primary[id] = false;
	primary_name[id] = "None";
	has_secondary[id] = false;
	secondary_name[id] = "None";
	has_bonus[id] = false;
	bonus_name[id] = "None";
	has_melee[id] = false;
	melee_name[id] = "None";
	for(new i; i < MAX_SKILLS; i++)
		player_skill[i][id] = 0;
	skill_page[id] = 0;
	format(SZ_Username[id], charsmax(SZ_Username[]), "");
	format(SZ_Password[id], charsmax(SZ_Password[]), "");
}

public login(id)
{
	if(!Registradoylogeado[id]) {
		set_task(0.1, "clcmd_changeteam", id);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public check_user_xp(id)
{
	if(!is_user_connected(id))
		return;
	
	set_task(0.2, "check_user_xp", id);
	if(playerxp[id] >= calculatexp(id) && playerlevel[id] < MAX_LEVEL) {
		playerlevel[id]++;
		client_print(id, print_chat, "[Level-UP] Congratulations, You gained a level!!!");
		new name[32];
		get_user_name(id, name, 31);
		for(new i; i < 33; i++) {
			if(is_user_connected(i) && i != id)
				client_print(i, print_chat, "[Level-UP] %s just gained a level!", name);
		}
		new p_origin[3];
		get_user_origin(id, p_origin);
		set_sprite(p_origin, levelspr, 30);
		set_sprite(p_origin, levelspr2, 30);
		emit_sound(id, CHAN_ITEM, gSoundLevel, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		menu_skills(id);
	}
}

public reset_skills(id)
{
	for(new i; i < num_skills; i++)
		player_skill[i][id] = 0;
	
	has_primary[id] = false;
	primary_name[id] = "None";
	has_secondary[id] = false;
	secondary_name[id] = "None";
	has_bonus[id] = false;
	bonus_name[id] = "None";
	has_melee[id] = false;
	melee_name[id] = "None";
	menu_skills(id);
}

public reset_level(id)
{
	playerlevel[id] = 0;
	playerxp[id] = 0;
	has_primary[id] = false;
	primary_name[id] = "None";
	has_secondary[id] = false;
	secondary_name[id] = "None";
	has_bonus[id] = false;
	bonus_name[id] = "None";
	has_melee[id] = false;
	melee_name[id] = "None";
	for(new i; i < num_skills; i++)
		player_skill[i][id] = 0;
}

public menu_skills(id)
{
	new menu_body[320];
	new n = 0;
	new len = 319;
	
	playerpoints[id] = playerlevel[id] * POINT_PERLEVEL;
	for(new i; i < num_skills; i++) {
		playerpoints[id] -= player_skill[i][id];
	}
	
	n += formatex(menu_body[n], len - n, "\ySkills Menu:\w");
	if(playerpoints[id] > 0)
		n += formatex(menu_body[n], len - n, "\y^nSkill Points: \w%d/%d", playerpoints[id], playerlevel[id] * POINT_PERLEVEL);
	else
		n += formatex(menu_body[n], len - n, "\y^nSkill Points: \r%d/%d", playerpoints[id], playerlevel[id] * POINT_PERLEVEL);
	
	new num, max_pages;
	while(num < num_skills) {
		max_pages++;
		num += 2;
	}
	n += formatex(menu_body[n], len - n, "\y^nPage: \w%d/%d^n^n",skill_page[id] + 1, max_pages);
	for(new i = (skill_page[id] * 4); i < ((skill_page[id] * 4) + 4); i++) {
		new item_num = (i + 1) - (skill_page[id] * 4);
		new pri_sec[16];
		if(is_primary[i])
			format(pri_sec, 15, "(Primary)");
		else if(is_secondary[i])
			format(pri_sec, 15, "(Secondary)");
		else if(is_melee[i])
			format(pri_sec, 15, "(Melee)");
		else if(is_bonus[i])
			format(pri_sec, 15, "(Bonus)");
		if(playerlevel[id] >= req_level[i])
			n += formatex(menu_body[n], len - n, "\y%i.\w %s: %d/%d %s^n", item_num, levelup_skill[i], player_skill[i][id], levelup_skill_max[i], pri_sec);
		else
			n += formatex(menu_body[n], len - n, "\y%i.\r %s: %d/%d \y(Level %i) %s^n", item_num, levelup_skill[i], player_skill[i][id], levelup_skill_max[i], req_level[i], pri_sec);
		if(i == num_skills - 1) {
			lastpage[id] = true;
			break;
		}
	}
	if(skill_page[id] == 0)
		n += formatex(menu_body[n], len - n, "\y^n8.\r Previous");
	else
		n += formatex(menu_body[n], len - n, "\y^n8.\w Previous");
	if(lastpage[id])
		n += formatex(menu_body[n], len - n, "\y^n9.\r Next");
	else
		n += formatex(menu_body[n], len - n, "\y^n9.\w Next");
	n += formatex(menu_body[n], len - n, "\y^n^n0. Exit");
	
	new keys = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9);
	show_menu(id, keys, menu_body);
}

public skill_menu_action(id, key)
{
	key++;
	new skillname[32], skilllevel;
	new skillid = (key - 1) + (skill_page[id] * 4);
	
	switch(key) {
		case 8: {
			if(skill_page[id] == 0) {
				menu_skills(id);
				return;
			}
			skill_page[id]--;
			lastpage[id] = false;
			menu_skills(id);
			return;
		}
		case 9: {
			if(lastpage[id]) {
				menu_skills(id);
				return;
			}
			skill_page[id]++;
			menu_skills(id);
			return;
		}
		case 10: {
			return;
		}
		default: {
			if(player_skill[skillid][id] < levelup_skill_max[skillid] && playerpoints[id] > 0 && playerlevel[id] >= req_level[skillid]) {
				if(is_primary[skillid]) {
					if(has_primary[id] && !player_skill[skillid][id]) {
						client_print(id, print_chat, "[Level-UP] You can only get 1 primary skill!");
						menu_skills(id);
						return;
					}
					else {
						has_primary[id] = true;
						primary_name[id] = levelup_skill[skillid];
					}
				}
				else if(is_secondary[skillid]) {
					if(has_secondary[id] && !player_skill[skillid][id]) {
						client_print(id, print_chat, "[Level-UP] You can only get 1 secondary skill!");
						menu_skills(id);
						return;
					}
					else {
						has_secondary[id] = true;
						secondary_name[id] = levelup_skill[skillid];
					}
				}
				else if(is_melee[skillid]) {
					if(has_melee[id] && !player_skill[skillid][id]) {
						client_print(id, print_chat, "[Level-UP] You can only get 1 melee skill!");
						menu_skills(id);
						return;
					}
					else {
						has_melee[id] = true;
						melee_name[id] = levelup_skill[skillid];
					}
				}
				else if(is_bonus[skillid]) {
					if(has_bonus[id] && !player_skill[skillid][id]) {
						client_print(id, print_chat, "[Level-UP] You can only get 1 Bonus skill!");
						menu_skills(id);
						return;
					}
					else {
						has_bonus[id] = true;
						bonus_name[id] = levelup_skill[skillid];
					}
				}
				player_skill[skillid][id] ++;
				skillname = levelup_skill[skillid];
				skilllevel = player_skill[skillid][id];
			}
			else {
				menu_skills(id);
				return;
			}
		}
	}
	
	client_print(id, print_chat, "[Level-UP] Your %s is now level %d", skillname, skilllevel);
	playerpoints[id]--;
	
	if(playerpoints[id] > 0)
		menu_skills(id);
}

calculatexp(id)
{
	new Float: factor1 = float(playerlevel[id]) * 70.0;
	new Float: factor2 = float(playerlevel[id]) * float(playerlevel[id]) * 11.5;
	new neededxp = floatround(factor1 + factor2 + 30.0);
	return neededxp;
}

public player_killed(id, attacker)
{
	if(!is_user_connected(attacker))
		return;
	
	if(get_user_team(id) == get_user_team(attacker))
		return;
	
	xp_ratio = get_cvar_num("xp_ratio");
	playerxp[attacker] += (playerlevel[id] + 1) * xp_ratio;
}

Load(id)
{
	static SZ_Data[512], VAULT_Password[191],
	xp[8], level[8];
	
	sqlv_get_data(Vault, SZ_Username[id], SZ_Data, charsmax(SZ_Data));
	parse(SZ_Data, VAULT_Password, 190, xp, 7, level, 7);
	new skill[MAX_SKILLS][8], len = strlen(VAULT_Password) + 1 + strlen(xp) + 1 + strlen(level);
	console_print(id, "%i", len);
	for(new i; i < len; i++) {
		SZ_Data[i] = ' ';
	}
	for(new i; i < num_skills; i++) {
		parse(SZ_Data, skill[i], 7);
		len += strlen(skill[i]) + 1;
		console_print(id, "%i", len);
		for(new i; i <= len; i++)
			SZ_Data[i] = ' ';	
	}
	
	Registrado[id] = 1;
	Registradoylogeado[id] = 1;
	
	playerxp[id] = str_to_num(xp);
	playerlevel[id] = str_to_num(level);
	for(new i; i < num_skills; i++) {
		player_skill[i][id] = str_to_num(skill[i]);
		if(player_skill[i][id] > levelup_skill_max[i])
			player_skill[i][id] = levelup_skill_max[i];
			
		if(is_primary[i] && player_skill[i][id]) {
			if(has_primary[id])
				player_skill[i][id] = 0;
			else {
				has_primary[id] = true;
				primary_name[id] = levelup_skill[i];
			}
		}
		else if(is_secondary[i] && player_skill[i][id]) {
			if(has_secondary[id])
				player_skill[i][id] = 0;
			else {
				has_secondary[id] = true;
				secondary_name[id] = levelup_skill[i];
			}
		}
		else if(is_melee[i] && player_skill[i][id]) {
			if(has_melee[id])
				player_skill[i][id] = 0;
			else {
				has_melee[id] = true;
				melee_name[id] = levelup_skill[i];
			}
		}
		else if(is_bonus[i] && player_skill[i][id]) {
			if(has_bonus[id])
				player_skill[i][id] = 0;
			else {
				has_bonus[id] = true;
				bonus_name[id] = levelup_skill[i];
			}
		}
	}
	
	playerpoints[id] = playerlevel[id] * POINT_PERLEVEL;
	for(new i; i < num_skills; i++)
		playerpoints[id] -= player_skill[i][id];
	if(playerpoints[id] < 0) {
		client_print(id, print_chat, "[Level-UP] There was a problem loading your skills!");
		for(new i; i < num_skills; i++)
			player_skill[i][id] = 0;
		menu_skills(id);
	}
}

public Save(id)
{
	if(Registradoylogeado[id] == 1 
	&& !mudarcuenta[id] 
	&& Registrado[id]) {
		static SZ_Data[512];
		formatex(SZ_Data, charsmax(SZ_Data), "%s %i %i", SZ_Password[id], playerxp[id], playerlevel[id]);
		for(new i; i < MAX_SKILLS; i++)
			formatex(SZ_Data, charsmax(SZ_Data), "%s %i", SZ_Data, player_skill[i][id]);
		sqlv_set_data(Vault, SZ_Username[id], SZ_Data);
	}
}

public player_touch_weapon(ent, id)
{
	if(!is_user_alive(id) || !is_valid_ent(ent)) return;
	if(just_dropped[id]) return;
	
	new model[64], trash[4];
	entity_get_string(ent, EV_SZ_model, model, 63);
	replace(model, 63, "w_", " weapon_");
	replace(model, 63, ".mdl", "");
	strbreak(model, trash, 3, model, 63);
	if(equal(model, "weapon_mp5"))
		format(model, 63, "%snavy", model);
	new wep = get_weaponid(model);
	
	if(has_primary[id] && !dropped_primary[id] && get_weapon_slot(wep) == 1) {
		if(count_weaps(id, 1) >= 2) return;
		new ent2 = find_ent_by_owner(-1, model, ent);
		ammo[id] = cs_get_weapon_ammo(ent2);
		give_item(id, model);
		new classname[32];
		pev(ent2, pev_classname, classname,31);
		if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent);
		if(pev_valid(ent2)) engfunc(EngFunc_RemoveEntity, ent2);
		set_task(0.1, "give_ammo", id, classname, 31);
	}
	else if(has_secondary[id] && !dropped_secondary[id] && get_weapon_slot(wep) == 2) {
		console_print(0, "i'm here");
		if(count_weaps(id, 2) >= 2) return;
		new ent2 = find_ent_by_owner(-1, model, ent);
		ammo[id] = cs_get_weapon_ammo(ent2);
		give_item(id, model);
		new classname[32];
		pev(ent2, pev_classname, classname,31);
		if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent);
		if(pev_valid(ent2)) engfunc(EngFunc_RemoveEntity, ent2);
		set_task(0.1, "give_ammo", id, classname, 31);
	}
	//else if(has_bonus[id] && !dropped_bonus[id] && get_weapon_slot(wep) == 5) {
	//	console_print(0, "i'm here");
	//	if(count_weaps(id, 2) >= 2) return;
	//	new ent2 = find_ent_by_owner(-1, model, ent);
	//	ammo[id] = cs_get_weapon_ammo(ent2);
	//	give_item(id, model);
	//	new classname[32];
	//	pev(ent2, pev_classname, classname,31);
	//	if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent);
	//	if(pev_valid(ent2)) engfunc(EngFunc_RemoveEntity, ent2);
	//	set_task(0.1, "give_ammo", id, classname, 31);
	//}
}

public give_ammo(classname2[32],id)
{
	if(is_user_alive(id))
	{
		static Float:origin[3]
		pev(id,pev_origin,origin)
		new ent = engfunc(EngFunc_FindEntityInSphere,33,origin,20.0)
		while(ent && pev_valid(ent))
		{
			static classname[32]
			pev(ent,pev_classname,classname,31)
			if(equali(classname,classname2) && pev(ent,pev_owner)==id)
			{
				cs_set_weapon_ammo(ent,ammo[id])
				break;
			}
			ent = engfunc(EngFunc_FindEntityInSphere,ent,origin,20.0)
		}
	}
	ammo[id]=0
}

public justdropped(id)
{
	just_dropped[id] = true;
	set_task(0.5, "undrop", id);
}

public undrop(id) just_dropped[id] = false;

public clcmd_changeteam(id)
{
	set_task(0.1, "createmenu", id);
	return;
}

public count_weaps(id,type)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_HANDLED
	}
	new num, num2, weapons[32]
	cs_get_user_weapons(id,weapons,num2)
	switch(type)
	{
		case 2:
		{
			for(new i=0;i<num2;i++)
			{
				if(weapons[i]==1 || weapons[i]==10 || weapons[i]==11 || weapons[i]==16 || weapons[i]==26 || weapons[i]==17) num++
			}
		}
		default:
		{
			for(new i=0;i<num2;i++)
			{
				if(weapons[i]==30 || weapons[i]==8 || weapons[i]==12 || weapons[i]==13 || weapons[i]==14 || weapons[i]==15 || weapons[i]==18 || weapons[i]==19 || weapons[i]==20 || weapons[i]==21 || weapons[i]==22 || weapons[i]==23 || weapons[i]==24 || weapons[i]==27 || weapons[i]==28 || weapons[i]==3 || weapons[i]==5 || weapons[i]==7) num++
			}
		}
	}
	return num;
}

public cs_get_user_weapons(id,weapons[32],& num)
{
	num=0
	new ent, origin[3], classname[32], owner
	pev(id,pev_origin,origin)
	ent = engfunc(EngFunc_FindEntityInSphere,get_maxplayers(),origin,1.0)
	while(ent)
	{
		owner = pev(ent,pev_owner)
		if(owner==id)
		{
			pev(ent,pev_classname,classname,31)
			if(containi(classname,"weapon_")==0)
			{
				weapons[num] = get_weaponid(classname)
				num++
			}
		}
		ent = engfunc(EngFunc_FindEntityInSphere,ent,origin,1.0)
	}
	return 1;		
}

public createmenu(id)
{
	static Menu, text[512];
	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	Registradoylogeado[id] = 0;
	
	formatex(text, charsmax(text), "\yLevel-UP^nVersion \r%s^n\yAuthor: \r%s", VERSION, AUTHOR);
	Menu = menu_create(text, "menu1");
	menu_additem(Menu,"\wRegister", "1", 0);
	menu_additem(Menu,"\wLog in", "2", 0);
	//menu_additem(Menu,"\wChange nickname", "3", 0);
	menu_setprop(Menu, MPROP_EXITNAME, "Exit");
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, Menu, 0);
	
	return PLUGIN_HANDLED;
}

public menu1(id, Menu, item)
{
	if(item == MENU_EXIT) {
		menu_destroy(Menu);
		if(Registradoylogeado[id] == 0) set_task(0.1, "createmenu", id);
		return PLUGIN_HANDLED;
	}
	
	static iData[6], iAccess, iCallback, iName[64];
	menu_item_getinfo(Menu, item, iAccess, iData, 5, iName, 63, iCallback);
	
	switch(str_to_num(iData)) {
		case 1: {
			Registrado[id] = 0;
			CMDRegistrarse(id);
		}
		case 2: {
			Registrado[id] = 1;
			CMDRegistrarse(id);
		}
	}
	
	return PLUGIN_HANDLED;
}
/*
public suremenu(id)
{
	static Menu2;
	Menu2 = menu_create("\yAre you sure that you want a nickname change?", "menu22");
	menu_additem(Menu2,"\rYes", "1", 0);
	menu_additem(Menu2,"\rNo", "2", 0);
	menu_setprop(Menu2, MPROP_EXITNAME, "Exit");
	menu_setprop(Menu2, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, Menu2, 0);
}

public menu22(id, Menu2, item)
{
	if(item == MENU_EXIT) {		
		menu_destroy(Menu2);
		if(Registradoylogeado[id] == 0) set_task(0.1, "createmenu", id);
		return PLUGIN_HANDLED;
	}
	
	static iData[6], iAccess, iCallback, iName[64], SZ_Data[512], GlobalName[32];
	menu_item_getinfo(Menu2, item, iAccess, iData, 5, iName, 63, iCallback);
	get_user_name(id, GlobalName, 31);
	
	switch(str_to_num(iData)) {
		case 1: {
			if(sqlv_get_data(Vault, GlobalName, SZ_Data, charsmax(SZ_Data))) {
				Registrado[id] = 1;
				mudarcuenta[id] = true;
				CMDRegistrarse(id);
			}
			else {
				client_print(id, print_center, "That nickname does not exist!");
				set_task(0.1, "clcmd_changeteam", id);
			}
		}
		case 2:
			set_task(0.1, "clcmd_changeteam", id);
	}
	
	return PLUGIN_HANDLED;
}
*/
public CMDRegistrarse(id)
{
	if(Registradoylogeado[id] == 0) {
		seguridad[id] = 1;
		client_print(id, print_center, "Write the username!");
		client_cmd(id, "messagemode EnterUsername");
	}
	set_task(0.2, "check_user_xp", id);
}

public CMDEnterUsername(id)
{
	if(seguridad[id] == 0) return PLUGIN_HANDLED;
	read_args(SZ_Username[id], charsmax(SZ_Username[]));
	remove_quotes(SZ_Username[id]);
	trim(SZ_Username[id]);
	
	if(equal(SZ_Username[id], "") || contain(SZ_Username[id], " ") != -1 || containcharacters(SZ_Username[id])) {
		client_print(id, print_center, "Username needs atleast 1 character, no spaces and no special characters!");
		set_task(0.1, "clcmd_changeteam", id);
		return PLUGIN_HANDLED;
	}
	
	if(Registrado[id] == 1) {
		static SZ_Data[512];
		if(sqlv_get_data(Vault, SZ_Username[id], SZ_Data, charsmax(SZ_Data))) {
			client_print(id, print_center, "Write the password!");
			client_cmd(id, "messagemode EnterPassword");
		}
		else {
			client_print(id, print_center, "Username does not exist!");
			set_task(0.1, "clcmd_changeteam", id);
		}
		return PLUGIN_HANDLED;
	}
	else {
		static SZ_Data[512];
		if(!sqlv_get_data(Vault, SZ_Username[id], SZ_Data, charsmax(SZ_Data))) {
			client_print(id, print_center, "Write the password!");
			client_cmd(id, "messagemode EnterPassword");
		}
		else {
			client_print(id, print_center, "Username already exists!");
			set_task(0.1, "clcmd_changeteam", id);
		}
	}
   
	return PLUGIN_HANDLED;
}

public CMDIntroducirContrasenia(id)
{
	if(seguridad[id] == 0) return PLUGIN_HANDLED;
	read_args(SZ_Password[id], charsmax(SZ_Password[]));
	remove_quotes(SZ_Password[id]);
	trim(SZ_Password[id]);
	
	if(equal(SZ_Password[id], "") || contain(SZ_Password[id], " ") != -1) {
		client_print(id, print_center, "Password needs atleast 1 character and no spaces!");
		set_task(0.1, "clcmd_changeteam", id);
		return PLUGIN_HANDLED;
	}
	
	if(Registrado[id] == 1) {
		static SZ_Data[512], VAULT_Password[191];
		sqlv_get_data(Vault, SZ_Username[id], SZ_Data, charsmax(SZ_Data));
		parse(SZ_Data, VAULT_Password, 190);
		
		if(equal(SZ_Password[id], VAULT_Password)) {
			/*
			if(mudarcuenta[id]) {
				Load(id);
				client_print(id, print_center, "Write your new nickname!");
				client_cmd(id, "messagemode EnterNick");
				return PLUGIN_HANDLED;
			}
			*/
			client_cmd(id, "chooseteam");
			Load(id);
		}
		else {
			client_print(id, print_center, "Incorrect password!");
			set_task(0.1, "clcmd_changeteam", id);
		}
		return PLUGIN_HANDLED;
	}
	else {
		if(sqlv_connect(Vault)) {
			static SZ_Data[512];
			Registrado[id] = 1;
			Registradoylogeado[id] = 1;
		
			formatex(SZ_Data, charsmax(SZ_Data), "%s %i %i", SZ_Password[id], playerxp[id], playerlevel[id]);
			for(new i; i < num_skills; i++)
				formatex(SZ_Data, charsmax(SZ_Data), "%s %i", SZ_Data, levelup_skill[i][id]);
			
			sqlv_set_data(Vault, SZ_Username[id], SZ_Data);
			
			client_print(id, print_center, "Account created succesfully!");
			client_cmd(id, "chooseteam");
			
			sqlv_disconnect(Vault);
			return PLUGIN_HANDLED;
		}
		else {
			client_print(id, print_center, "DB problems, connection timed out, try again later!");
			set_task(0.1, "clcmd_changeteam", id);
			
			sqlv_disconnect(Vault);
			return PLUGIN_HANDLED;
		}
	}
   
	return PLUGIN_HANDLED;
}
/*
public CMDIntroducirNick(id)
{
	if(!is_user_connected(id)
	|| seguridad[id] == 0) return PLUGIN_HANDLED;
		
	read_args(SZ_Newnick[id], charsmax(SZ_Newnick[]));
	remove_quotes(SZ_Newnick[id]);
	trim(SZ_Newnick[id]);

	static ActualName[32], SZ_Data[512];
	get_user_name(id, ActualName, 31);
	
	if(containcharacters(SZ_Newnick[id])) {
		client_print(id, print_center, "Nickname need atleast 1 character and no spaces!");
		set_task(0.1, "clcmd_changeteam", id);
		mudarcuenta[id] = false;
		return PLUGIN_HANDLED;
	}
	
	if(sqlv_get_data(Vault, SZ_Newnick[id], SZ_Data, charsmax(SZ_Data))) {
		client_print(id, print_center, "Nickname used!");
		set_task(0.1, "clcmd_changeteam", id);
		mudarcuenta[id] = false;
		return PLUGIN_HANDLED;
	}
	
	if(equal(SZ_Newnick[id], ActualName)) {
		client_print(id, print_center, "You can't put your old name here!");
		set_task(0.1, "clcmd_changeteam", id);
		mudarcuenta[id] = false;
		return PLUGIN_HANDLED;
	}
	
	formatex(SZ_Data, charsmax(SZ_Data), "%s %i %i", SZ_Password[id], playerxp[id], playerlevel[id]);
	for(new i; i < num_skills; i++)
		formatex(SZ_Data, charsmax(SZ_Data), "%s %i", SZ_Data, levelup_skill[i][id]);
	
	sqlv_set_data(Vault, SZ_Newnick[id], SZ_Data);
	sqlv_remove(Vault, ActualName);
	client_cmd(id, "name '%s'", SZ_Newnick[id]);
	
	server_cmd("kick #%d Your new nickname: %s.", get_user_userid(id), SZ_Newnick[id]);
	
	return PLUGIN_HANDLED;
}
*/
containcharacters(name[])
{
	if(equal(name, "")
	|| contain(name, "'") != -1
	|| contain(name, " ") != -1
	|| contain(name, "*") != -1
	|| contain(name, "/") != -1
	|| contain(name, " ") != -1
	|| contain(name, "[") != -1
	|| contain(name, "]") != -1
	|| contain(name, "(") != -1
	|| contain(name, ")") != -1
	|| contain(name, "-") != -1
	|| contain(name, "`") != -1
	|| contain(name, "+") != -1
	|| contain(name, "?) != -1
	|| contain(name, ".") != -1)
		return true;
	return false;
}

public set_sprite(p_origin[3], sprite, radius)
{
        // Explosion
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY, p_origin)
        write_byte(TE_EXPLOSION)
        write_coord(p_origin[0])
        write_coord(p_origin[1])
        write_coord(p_origin[2])
        write_short(sprite)
        write_byte(radius)
        write_byte(15)
        write_byte(4)
        message_end()
}

stock get_weapon_slot(iCswId)
{
	static const iWeaponsSlots[] = {
		-1,
		2, //CSW_P228
		-1,
		1, //CSW_SCOUT
		4, //CSW_HEGRENADE
		1, //CSW_XM1014
		5, //CSW_C4
		1, //CSW_MAC10
		1, //CSW_AUG
		4, //CSW_SMOKEGRENADE
		2, //CSW_ELITE
		2, //CSW_FIVESEVEN
		1, //CSW_UMP45
		1, //CSW_SG550
		1, //CSW_GALIL
		1, //CSW_FAMAS
		2, //CSW_USP
		2, //CSW_GLOCK18
		1, //CSW_AWP
		1, //CSW_MP5NAVY
		1, //CSW_M249
		1, //CSW_M3
		1, //CSW_M4A1
		1, //CSW_TMP
		1, //CSW_G3SG1
		4, //CSW_FLASHBANG
		2, //CSW_DEAGLE
		1, //CSW_SG552
		1, //CSW_AK47
		3, //CSW_KNIFE
		1 //CSW_P90
	}

	return iWeaponsSlots[iCswId];
} 

public native_create_skill(plugin, params)
{
	new str[31];
	get_string(1, str, 30);
	format(levelup_skill[num_skills], 30, "%s", str);
	levelup_skill_max[num_skills] = get_param(2);
	new string[7];
	num_to_str(num_skills, string, 6);
	set_string(3, string, 6);
	req_level[num_skills] = get_param(4);
	num_skills++;
}

public native_get_skill_level(plugin, params)
{
	new id = get_param(1);
	new skillid = get_param(2);
	return player_skill[skillid][id];
}

public native_give_xp(plugin, params)
{
	new id = get_param(1);
	new xp = get_param(2);
	playerxp[id] += xp;
}

public native_make_primary(plugin, params)
{
	new skillid = get_param(1);
	is_primary[skillid] = true;
}

public native_make_secondary(plugin, params)
{
	new skillid = get_param(1);
	is_secondary[skillid] = true;
}

public native_make_melee(plugin, params)
{
	new skillid = get_param(1);
	is_melee[skillid] = true;
}

public native_user_dropped_primary(plugin, params)
{
	new id = get_param(1);
	dropped_primary[id] = get_param(2);
}

public native_user_dropped_secondary(plugin, params)
{
	new id = get_param(1);
	dropped_secondary[id] = get_param(2);
}

public native_get_has_primary(plugin, params)
{
	new id = get_param(1);
	return has_primary[id];
}

public native_get_has_secondary(plugin, params)
{
	new id = get_param(1);
	return has_secondary[id];
}

public native_get_has_melee(plugin, params)
{
	new id = get_param(1);
	return has_melee[id];
}

  /////////////////////
 // test make bonus //
/////////////////////
public native_make_bonus(plugin, params)
{
	new skillid = get_param(1);
	is_bonus[skillid] = true;
}

public native_user_dropped_bonus(plugin, params)
{
	new id = get_param(1);
	dropped_bonus[id] = get_param(2);
}

public native_get_has_bonus(plugin, params)
{
	new id = get_param(1);
	return has_bonus[id];
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/

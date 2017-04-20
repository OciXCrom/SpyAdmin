#include <amxmodx>

#define PLUGIN_NAME "Spy Admin"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "OciXCrom"

new const szPrefix[] = "^4[SPY]"

enum Color
{
	NORMAL = 1, // clients scr_concolor cvar color
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new bool:spy[33]
new bool:admin[33]
new flags_original[33]
new flag_z

new cvar_adminflag, cvar_autohide

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	
	cvar_adminflag = register_cvar("spyadmin_adminflag", "e")
	cvar_autohide = register_cvar("spyadmin_autohide", "0")
	
	register_clcmd("say /spy", "cmd_spy")
	register_clcmd("say_team /spy", "cmd_spy")
	register_clcmd("say /spyadmin", "cmd_spy")
	register_clcmd("say_team /spyadmin", "cmd_spy")
	register_clcmd("amx_spyadmin", "cmd_spy")
	
	flag_z = read_flags("z")
}

public client_putinserver(id)
	spyadmin_checkadmin(id)
	
public spyadmin_checkadmin(id)
{
	spy[id] = false
	flags_original[id] = get_user_flags(id)
	admin[id] = user_has_flag(id, cvar_adminflag) ? true : false
	
	if(get_pcvar_num(cvar_autohide) == 1)
	{
		if(admin[id])
			spyadmin_removeflags(id)
	}
}

public client_infochanged(id) 
{
	new newname[32], oldname[32]
	
	get_user_info(id, "name", newname, charsmax(newname))
	get_user_name(id, oldname, charsmax(oldname))
	
	if(!equali(newname, oldname))
		spyadmin_checkadmin(id)
}

public cmd_spy(id)
{
	if(!admin[id]) ColorChat(id, TEAM_COLOR, "%s ^1You have no access to this command.", szPrefix)
	else spy[id] ? spyadmin_setflags(id) : spyadmin_removeflags(id)
	return PLUGIN_HANDLED
}

public spyadmin_removeflags(id)
{
	remove_user_flags(id, flags_original[id], 0)
	set_user_flags(id, flag_z, 0)
	spy[id] = true
	ColorChat(id, BLUE, "%s ^1Spy Mode ^3activated^1.", szPrefix)
}

public spyadmin_setflags(id)
{
	remove_user_flags(id, flag_z, 0)
	set_user_flags(id, flags_original[id], 0)
	spy[id] = false
	ColorChat(id, RED, "%s ^1Spy Mode ^3deactivated^1.", szPrefix)
}

stock user_has_flag(id, cvar)
{
	new flags[32]
	get_flags(get_user_flags(id), flags, charsmax(flags))
	
	new vip_flag[2]
	get_pcvar_string(cvar, vip_flag, charsmax(vip_flag))
	
	return (contain(flags, vip_flag) != -1) ? true : false
}

/* ColorChat */

ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case NORMAL: // clients scr_concolor cvar color
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	static team, ColorChange, index, MSG_Type;
	
	if(id)
	{
		MSG_Type = MSG_ONE;
		index = id;
	} else {
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	}
	
	team = get_user_team(index);
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, get_user_msgid("SayText"), _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, get_user_msgid("TeamInfo"), _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	static i;
	i = -1;

	while(i <= get_maxplayers())
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}
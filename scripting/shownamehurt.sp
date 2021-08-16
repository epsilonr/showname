#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombiereloaded>
#include <csgocolors_fix>
#include <clientprefs>

#pragma semicolon 1

#define TAG " \x04[ShowName]\x01"
#define TAGG " \x04[ShowDamage]\x01"

public Plugin myinfo =
{
	name = "ShowName",
	author = "epsilonr",
	description = "Shows Player Info",
	version = "1.0",
	url = "https://steamcommunity.com/profiles/76561198309046124/"
}

Handle g_hClientCookie = INVALID_HANDLE;
bool g_SEnabled[MAXPLAYERS + 1];
bool g_DEnabled[MAXPLAYERS + 1];

bool g_Waiting[MAXPLAYERS + 1];

Handle HurtTimers[MAXPLAYERS+1];

public void OnPluginStart()
{
	g_hClientCookie = RegClientCookie("ShowName", "ShowName Menu", CookieAccess_Private);
	SetCookieMenuItem(PrefMenu, 0, "Show Name");

	RegConsoleCmd("sm_shownamee", Command_Pref);
	RegConsoleCmd("sm_showdamagee", Command_HurtPref);
	
	RegConsoleCmd("sm_showname", Command_OMenu);
	RegConsoleCmd("sm_showdamage", Command_OMenu);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		
		OnClientCookiesCached(i);
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	char dValue[8];
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
	GetClientCookie(client, g_hClientCookie, dValue, sizeof(dValue));
	
	g_SEnabled[client] = (sValue[0] != '\0' && StringToInt(sValue));
	g_DEnabled[client] = (sValue[0] != '\0' && StringToInt(dValue));
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if (actions == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "Show Name", client);
	}

	if (actions == CookieMenuAction_SelectOption)
	{
		settmenu(client);
	}
}

void settmenu(int client)
{
	Menu menu = new Menu(sn_Menu, MENU_ACTIONS_ALL);
	menu.SetTitle("Show Name\n ");
	menu.AddItem("sn", "Enable / Disable Show Name");
	menu.AddItem("sd", "Enable / Disable Show Damage\n ");
	menu.AddItem("hm", "Hitmarkers menu");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int sn_Menu (Menu menu, MenuAction action, int param1, int param2) //param1 = client param2 = item
{
	switch (action)
	{	

		case MenuAction_Display:
		{
			char buffer[255];
			Format(buffer, sizeof(buffer), "Show Name\n ", param1);
			
			Panel panel = view_as<Panel>(param2);
			panel.SetTitle(buffer);
		}

		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));

						if (StrEqual(item, "sn"))
			{
				FakeClientCommand(param1, "sm_shownamee");
			}
						if (StrEqual(item, "sd"))
			{
				FakeClientCommand(param1, "sm_showdamagee");
			}
						if (StrEqual(item, "hm"))
			{
				FakeClientCommand(param1, "sm_hitmarkers");
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(g_DEnabled[attacker] == true)
	{
		return;
	}
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int hp = event.GetInt("health");
	int dmg = event.GetInt("dmg_health");
    
	delete HurtTimers[attacker];
	g_Waiting[attacker] = true;
	Hurt(victim, attacker, hp, dmg);
	HurtTimers[attacker] = CreateTimer(3.0, TimerAction, attacker);
} 

public Action TimerAction(Handle timer, int attacker)
{
	g_Waiting[attacker] = false;
	HurtTimers[attacker] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Command_OMenu(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	settmenu(client);
	return Plugin_Handled;
}

public Action Command_Pref(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	if(g_SEnabled[client] == true)
	{
		PrintToChat(client, "%s Enabled.", TAG);
		g_SEnabled[client] = false;
		char sCookieValue[12];
		IntToString(0, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hClientCookie, sCookieValue);
		return Plugin_Handled;
	}
	
	if(g_SEnabled[client] == false)
	{
		PrintToChat(client, "%s Disabled.", TAG);
		g_SEnabled[client] = true;
		char sCookieValue[12];
		IntToString(1, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hClientCookie, sCookieValue);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_HurtPref(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	if(g_DEnabled[client] == true)
	{
		PrintToChat(client, "%s Enabled.", TAGG);
		g_DEnabled[client] = false;
		char dCookieValue[12];
		IntToString(0, dCookieValue, sizeof(dCookieValue));
		SetClientCookie(client, g_hClientCookie, dCookieValue);
		return Plugin_Handled;
	}
	
	if(g_DEnabled[client] == false)
	{
		PrintToChat(client, "%s Disabled.", TAGG);
		g_DEnabled[client] = true;
		char dCookieValue[12];
		IntToString(1, dCookieValue, sizeof(dCookieValue));
		SetClientCookie(client, g_hClientCookie, dCookieValue);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnPostThinkPost(int client)
{
	if(g_SEnabled[client] == false && IsValidClient(client) && g_Waiting[client] == false)
	{
		int target = GetClientAimTarget2(client);
		if(IsValidClient(target) && IsPlayerAlive(target))
		{
			Print(client, target);
		}
	}
}

stock int GetClientAimTarget2(int client) {
	float fPosition[3];
	float fAngles[3];
	GetClientEyePosition(client, fPosition);
	GetClientEyeAngles(client, fAngles);

	Handle hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

	if(TR_DidHit(hTrace)) {
		int entity = TR_GetEntityIndex(hTrace);
		delete hTrace;
		return entity;
	}

	delete hTrace;
	return -1;
}

public bool TraceRayFilter(int entity, int mask, any client) {
	if(entity == client)
		return false;

	return true;
}

stock bool IsValidClient(int iClient) 
{ 
	if (iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient)) return true; 
	return false; 
}

void Print(int client, int target)
{
	int hp = GetClientHealth(target);
	int id = GetClientUserId(target);

	char name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	if(ZR_IsClientHuman(target) && !IsPlayerAdmin(client))
	{
		PrintHintText(client, "Human: %s\nHealth: %i", name, hp);
	}
	if(ZR_IsClientZombie(target) && !IsPlayerAdmin(client))
	{
		PrintHintText(client, "Zombie: %s\nHealth: %i", name, hp);
	}
	if(ZR_IsClientHuman(target) && IsPlayerAdmin(client))
	{
		PrintHintText(client, "Human: %s\nHealth: %i\nUserID: #%i", name, hp, id);
	}
	if(ZR_IsClientZombie(target) && IsPlayerAdmin(client))
	{
		PrintHintText(client, "Zombie: %s\nHealth: %i\nUserID: #%i", name, hp, id);
	}
}

void Hurt(int victim, int attacker, int hp, int dmg)
{	
	if(IsValidClient(attacker) && IsValidClient(victim) && victim != attacker && ZR_IsClientHuman(attacker) && ZR_IsClientZombie(victim))
	{
		PrintHintText(attacker, "Zombie: %N\n%i - %i", victim, hp, dmg);
	}
}
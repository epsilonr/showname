#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombiereloaded>
#include <clientprefs>

#pragma semicolon 1

#define TAG " \x04[ShowName]\x01"

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

public void OnPluginStart()
{
	g_hClientCookie = RegClientCookie("ShowName", "Toggle ShowName", CookieAccess_Private);

	RegConsoleCmd("sm_showname", Command_Pref);
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		
		OnClientCookiesCached(i);
	}
}

public OnClientCookiesCached(client)
{
	char sValue[8];
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
	
	g_SEnabled[client] = (sValue[0] != '\0' && StringToInt(sValue));
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
	if(g_SEnabled[client] == false && IsValidClient(client))
	{
		int target = GetClientAimTarget(client);
		if(IsValidClient(target) && IsPlayerAlive(target))
		{
			Print(client, target);
		}
	}
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
		PrintHintText(client, "Human: %s\nHealth: %i\nUserid: #%i", name, hp, id);
	}
	if(ZR_IsClientZombie(target) && IsPlayerAdmin(client))
	{
		PrintHintText(client, "Zombie: %s\nHealth: %i\nUserid: #%i", name, hp, id);
	}
}
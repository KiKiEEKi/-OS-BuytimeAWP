#include <cstrike>
#include <sdkhooks>
#include <sdktools_functions>

#define CSSv34 false //Если нужно для CSSv34 то замените на true

#undef REQUIRE_PLUGIN
#if CSSv34 == false
#tryinclude <morecolors>
#tryinclude <csgo_colors>
#else
#tryinclude <clientmod>
#tryinclude <clientmod/multicolors>
#endif

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[OS] Buytime AWP",
	author = "KiKiEEKi ( DS: kikieeki | vk.com/kikieeki )",
	version = "( PUBLIC 1.1 )"
};

enum struct BuyTime
{
	bool bEnable;
	bool bTime;
	float fTime;
	char sMsg[256];
	char sMsg2[256];
}
BuyTime g_esBuyTime;

EngineVersion g_hVersion;

public void OnPluginStart()
{
	g_hVersion = GetEngineVersion();

	ConVar cvar;
	(cvar = CreateConVar("os_buytime_enable", "1", "Вкл/Выкл плагин", FCVAR_NOTIFY)).AddChangeHook(ConVarChanged_1);
	ConVarChanged_1(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("os_buytime_awp", "5.0", "Время закупки AWP", FCVAR_NOTIFY)).AddChangeHook(ConVarChanged_2);
	ConVarChanged_2(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("os_buytime_msg",
		"{lime}[Buytime] {fullred}Время на покупку AWP вышло!", "Сообщение в чат о запрете\nCSSv92 / CSSv34 CM / CSGO\nОставьте пустым для отключения сообщения", FCVAR_NOTIFY)).AddChangeHook(ConVarChanged_3);
	ConVarChanged_3(cvar, NULL_STRING, NULL_STRING);
	(cvar = CreateConVar("os_buytime_msg2",
		"{green}[Buytime] {red}Время на покупку AWP вышло!", "Сообщение в чат о запрете\nCSSv34 OLD", FCVAR_NOTIFY)).AddChangeHook(ConVarChanged_4);
	ConVarChanged_4(cvar, NULL_STRING, NULL_STRING);
	AutoExecConfig(true, "[OS]BuytimeAWP");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
}

void ConVarChanged_1(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_esBuyTime.bEnable = cvar.BoolValue;
}
void ConVarChanged_2(ConVar cvar, const char[] oldValue, const char[] newValue) {
	g_esBuyTime.fTime = cvar.FloatValue;
}
void ConVarChanged_3(ConVar cvar, const char[] oldValue, const char[] newValue) {
	cvar.GetString(g_esBuyTime.sMsg, sizeof(g_esBuyTime.sMsg));
}
void ConVarChanged_4(ConVar cvar, const char[] oldValue, const char[] newValue) {
	cvar.GetString(g_esBuyTime.sMsg2, sizeof(g_esBuyTime.sMsg2));
}

public void OnMapStart()
{
	OSBuytime();
}

void OSBuytime()
{
	g_esBuyTime.bTime = true;
	if(g_esBuyTime.bEnable) CreateTimer(g_esBuyTime.fTime, Timer_Buytime, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundStart(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	OSBuytime();
}

void Event_RoundEnd(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	g_esBuyTime.bTime = true;
}

Action Timer_Buytime(Handle timer)
{
	g_esBuyTime.bTime = false;
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int iClient, const char[] sWpnName)
{
	if(!g_esBuyTime.bTime) if(strcmp(sWpnName, "awp") == 0)
	{
		if(g_esBuyTime.sMsg[0]) {
			switch(g_hVersion) {
				
				#if CSSv34 == false
				case Engine_CSS: CPrintToChat(iClient, "%s", g_esBuyTime.sMsg);
				case Engine_CSGO: CGOPrintToChat(iClient, "%s", g_esBuyTime.sMsg);
				#else
				case Engine_SourceSDK2006: {
					MC_PrintToChat(iClient, "%s", g_esBuyTime.sMsg);
					C_PrintToChat(iClient, "%s", g_esBuyTime.sMsg2);
				}
				#endif
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

Action Hook_WeaponCanUse(int iClient, int iWpnIndex)
{
	if(!g_esBuyTime.bTime) {
		char sWpnName[16];
		GetEdictClassname(iWpnIndex, sWpnName, sizeof(sWpnName));
		if(strcmp(sWpnName, "weapon_awp") == 0) {
			//Eсли тут получать в зоне закупки игрок или нет то вернет 0
			//Через фрейм если делать то слишком быстро и тоже вернет 0
			//Так что таймер!
			CreateTimer(0.1, Timer_Use, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

Action Timer_Use(Handle timer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if(!iClient
		|| !(0 < iClient <= MaxClients)
		|| !IsClientInGame(iClient)
		|| !IsPlayerAlive(iClient)) return Plugin_Continue;

	if(!GetEntProp(iClient, Prop_Send, "m_bInBuyZone")) return Plugin_Continue;

	int iWpnIndex = GetPlayerWeaponSlot(iClient, 0);
	if(iWpnIndex == -1) return Plugin_Continue;

	RemovePlayerItem(iClient, iWpnIndex);
	FakeClientCommand(iClient, "use weapon_knife");

	return Plugin_Continue;
}

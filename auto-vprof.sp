//#include <xslow>

#pragma newdecls required;
#pragma semicolon 1;


public Plugin myinfo =
{
	name		= "Auto VPROF",
	author		= "xSLOW",
	description	= "Create vprof automatically",
	version		= "0.1 @ 31.05.2022",
	url			= "https://steamcommunity.com/id/imslow2k17/"
};

#define FOLDER_PATH "addons/sourcemod/logs/auto-vprof"

char g_sDate[32];
char g_sFilePath[PLATFORM_MAX_PATH];
char g_sDefaultConLogFile[PLATFORM_MAX_PATH];

ConVar con_logfile;
ConVar g_cvEnablePlugin;



public void OnPluginStart()
{
    con_logfile = FindConVar("con_logfile");
    con_logfile.GetString(g_sDefaultConLogFile, sizeof(g_sDefaultConLogFile));

    if(OpenDirectory(FOLDER_PATH, false) == null)
    {
        CreateDirectory(FOLDER_PATH, 511, false);
    }

    RegAdminCmd("sm_autovprof_test", Cmd_Test, ADMFLAG_ROOT); // debug only

    g_cvEnablePlugin = CreateConVar("sm_autovprof_enable", "1", "Enable auto vProf?\nAttention! Resources intensive!");

    AutoExecConfig(true, "auto-vprof");

    HookEvent("cs_win_panel_match", Event_CsWinPanelMatch);
}


public void Event_CsWinPanelMatch(Event event, const char[] name, bool dontBroadcast)
{
	ConVar mp_match_restart_delay = FindConVar("mp_match_restart_delay");

	CreateTimer(mp_match_restart_delay.FloatValue - 0.3, Delay_CsWinPanelMatch, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Delay_CsWinPanelMatch(Handle timer)
{
    DumpVPROF();
}

public Action Cmd_Test(int client, int args)
{
    ReplyToCommand(client, "----> VPROF Stopped");

    DumpVPROF();
    
    return Plugin_Handled;
}

public void OnMapStart()
{
    if(g_cvEnablePlugin.BoolValue)
    {
        CreateTimer(5.0, Timer_OnMapStart); // make sure OnPluginStart is finished processing
    }
    
}

public Action Timer_OnMapStart(Handle timer, any data)
{
    char sCurrentDate[32];
    char sBuffer[64];
    char sMapName[42];

    GetCurrentMap(sMapName, sizeof(sMapName));

    FormatTime(sCurrentDate, sizeof(sCurrentDate), "%d-%m-%Y-%Hh-%Mm", GetTime());

    strcopy(g_sDate, sizeof(g_sDate), sCurrentDate);

    Format(sBuffer, sizeof(sBuffer), "%s_%s.log", sCurrentDate, sMapName);
    Format(g_sFilePath, sizeof(g_sFilePath), "%s/%s", FOLDER_PATH, sBuffer);

    LogToFile(g_sFilePath, "**************************************");
    FormatTime(sBuffer, sizeof(sBuffer), "%dh %mm", GetTime());
    LogToFile(g_sFilePath, "- Started vProf @ %s", sBuffer);    

    ServerCommand("sm prof start");
}

public void OnPluginEnd()
{    
    ServerCommand("sm prof stop");
}


// ----> Moved to Event_CsWinPanel
/*
public void OnMapEnd()
{
    if(g_cvEnablePlugin.BoolValue)
    {    
        char sMapName[42];
        char sBuffer[64];

        GetCurrentMap(sMapName, sizeof(sMapName));

        FormatTime(sBuffer, sizeof(sBuffer), "%dh %mm", GetTime());
        LogToFile(g_sFilePath, "- Ended vProf @ %s", sBuffer);   
        LogToFile(g_sFilePath, "- Online players: %d", GetClientCount(true));
        LogToFile(g_sFilePath, "- Current map: %s", sMapName);
        LogToFile(g_sFilePath, "**************************************");

        SetConVarString(con_logfile, g_sFilePath);
        ServerCommand("sm prof stop");
        RequestFrame(NextFrame_MapEnd_Dumping);
    }
}
*/


void DumpVPROF()
{
    if(g_cvEnablePlugin.BoolValue)
    {    
        char sMapName[42];
        char sBuffer[64];

        GetCurrentMap(sMapName, sizeof(sMapName));

        FormatTime(sBuffer, sizeof(sBuffer), "%dh %mm", GetTime());
        LogToFile(g_sFilePath, "- Ended vProf @ %s", sBuffer);   
        LogToFile(g_sFilePath, "- Online players: %d", GetClientCount(true));
        LogToFile(g_sFilePath, "- Current map: %s", sMapName);
        LogToFile(g_sFilePath, "**************************************");

        SetConVarString(con_logfile, g_sFilePath);
        ServerCommand("sm prof stop");
        RequestFrame(NextFrame_MapEnd_Dumping);
    }    
}

public void NextFrame_MapEnd_Dumping()
{
    ServerCommand("sm prof dump vprof");
    RequestFrame(NextFrame_MapEnd_AfterDumping);
}

public void NextFrame_MapEnd_AfterDumping()
{
    SetConVarString(con_logfile, g_sDefaultConLogFile);
}


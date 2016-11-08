#include <cstrike>
#include <csgocolors>
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <updater>

ConVar g_hCvar_KW_Enable,
g_hCvar_KW_AdminOnly,
g_hCvar_KW_hp_max,
g_hCvar_KW_hp_kill,
g_hCvar_KW_hp_hs,
g_hCvar_KW_hp_knife,
g_hCvar_KW_hp_nade,
g_hCvar_KW_hp_messages,
g_hCvar_KW_ap_max,
g_hCvar_KW_ap_kill,
g_hCvar_KW_ap_hs,
g_hCvar_KW_ap_knife,
g_hCvar_KW_ap_nade,
g_hCvar_KW_ap_messages;

bool g_bCvar_KW_Enable,
g_bCvar_KW_AdminOnly,
g_bCvar_KW_ap_messages,
g_bCvar_KW_hp_messages;

int g_iCvar_KW_hp_max,
g_iCvar_KW_hp_kill,
g_iCvar_KW_hp_hs,
g_iCvar_KW_hp_knife,
g_iCvar_KW_hp_nade,
g_iCvar_KW_ap_max,
g_iCvar_KW_ap_kill,
g_iCvar_KW_ap_hs,
g_iCvar_KW_ap_knife,
g_iCvar_KW_ap_nade;

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "[CS:GO] Kill Rewards"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Awards players on a successful kill with health and/or armor."
#define PLUGIN_URL              "http://maxximou5.com/"
#define UPDATE_URL              "http://www.maxximou5.com/sourcemod/killrewards/update.txt"
#define CHAT_BANNER             "[\x04REWARD\x01]"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("killrewards.phrases");

    CreateConVar( "sm_killrewards_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );

    g_hCvar_KW_Enable = CreateConVar("sm_killrewards_enable", "1", "Enable or Disable all features of the plugin.", _, true, 0.0, true, 1.0);
    g_hCvar_KW_AdminOnly = CreateConVar("sm_killrewards_adminonly", "0", "Enable kill rewards only for clients (FLAG: A).", _, true, 0.0, true, 1.0);
    g_hCvar_KW_hp_max = CreateConVar("sm_killrewards_hp_max", "100", "Maximum Health Points (HP).");
    g_hCvar_KW_hp_kill = CreateConVar("sm_killrewards_hp_kill", "5", "Health Points (HP) per kill.");
    g_hCvar_KW_hp_hs = CreateConVar("sm_killrewards_hp_hs", "10", "Health Points (HP) per headshot kill.");
    g_hCvar_KW_hp_knife = CreateConVar("sm_killrewards_hp_knife", "50", "Health Points (HP) per knife kill.");
    g_hCvar_KW_hp_nade = CreateConVar("sm_killrewards_hp_nade", "30", "Health Points (HP) per nade kill.");
    g_hCvar_KW_hp_messages = CreateConVar("sm_killrewards_hp_messages", "1", "Display HP messages.");
    g_hCvar_KW_ap_max = CreateConVar("sm_killrewards_ap_max", "100", "Maximum Armor Points (AP).");
    g_hCvar_KW_ap_kill = CreateConVar("sm_killrewards_ap_kill", "5", "Armor Points (AP) per kill.");
    g_hCvar_KW_ap_hs = CreateConVar("sm_killrewards_ap_hs", "10", "Armor Points (AP) per headshot kill.");
    g_hCvar_KW_ap_knife = CreateConVar("sm_killrewards_ap_knife", "50", "Armor Points (AP) per knife kill.");
    g_hCvar_KW_ap_nade = CreateConVar("sm_killrewards_ap_nade", "30", "Armor Points (AP) per nade kill.");
    g_hCvar_KW_ap_messages = CreateConVar("sm_killrewards_ap_messages", "1", "Display AP messages.");

    HookConVarChange(g_hCvar_KW_Enable, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_AdminOnly, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_max, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_kill, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_hs, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_knife, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_nade, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_hp_messages, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_max, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_kill, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_hs, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_knife, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_nade, OnSettingsChange);
    HookConVarChange(g_hCvar_KW_ap_messages, OnSettingsChange);

    HookEvent("player_death", Event_PlayerDeath);

    AutoExecConfig(true, "killrewards");

    UpdateConVars();

    if (GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("ERROR: This plugin is designed only for CS:GO.");
    }

    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnConfigsExecuted()
{
    UpdateConVars();
}

public void OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_RemovePlugin();
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bCvar_KW_Enable)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (g_bCvar_KW_AdminOnly)
        {
            if (!CheckCommandAccess(attacker, "sm_killrewards_override", ADMFLAG_RESERVATION))
            {
                return Plugin_Handled;
            }
        }

        char weapon[6];
        char hegrenade[16];
        char decoygrenade[16];
        GetEventString(event, "weapon", weapon, sizeof(weapon));
        GetEventString(event, "weapon", hegrenade, sizeof(hegrenade));
        GetEventString(event, "weapon", decoygrenade, sizeof(decoygrenade));

        bool validAttacker = (attacker != 0) && IsPlayerAlive(attacker);

        /* Reward attacker with HP. */
        if (validAttacker)
        {
            bool knifed = StrEqual(weapon, "knife");
            bool nades = StrEqual(hegrenade, "hegrenade");
            bool headshot = GetEventBool(event, "headshot");

            if ((knifed && (g_iCvar_KW_hp_kill > 0)) || (!knifed && (g_iCvar_KW_hp_kill > 0)) || (headshot && (g_iCvar_KW_hp_hs > 0)) || (!headshot && (g_iCvar_KW_hp_kill > 0)))
            {
                int attackerHP = GetClientHealth(attacker);

                if (attackerHP < g_iCvar_KW_hp_max)
                {
                    int addHP;
                    if (knifed)
                        addHP = g_iCvar_KW_hp_knife;
                    else if (headshot)
                        addHP = g_iCvar_KW_hp_hs;
                    else if (nades)
                        addHP = g_iCvar_KW_hp_nade;
                    else
                        addHP = g_iCvar_KW_hp_kill;
                    int newHP = attackerHP + addHP;
                    if (newHP > g_iCvar_KW_hp_max)
                        newHP = g_iCvar_KW_hp_max;
                    SetEntProp(attacker, Prop_Send, "m_iHealth", newHP, 1);
                }

                if (g_bCvar_KW_hp_messages && !g_bCvar_KW_ap_messages)
                {
                    if (knifed)
                        CPrintToChat(attacker, "%s \x04+%i HP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_knife, "HP Knife Kill");
                    else if (headshot)
                        CPrintToChat(attacker, "%s \x04+%i HP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_hs, "HP Headshot Kill");
                    else if (nades)
                        CPrintToChat(attacker, "%s \x04+%i HP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_knife, "HP Nade Kill");
                    else
                        CPrintToChat(attacker, "%s \x04+%i HP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_kill, "HP Kill");
                }
            }

            /* Reward attacker with AP. */
            if ((knifed && (g_iCvar_KW_ap_knife > 0)) || (!knifed && (g_iCvar_KW_ap_kill > 0)) || (headshot && (g_iCvar_KW_ap_hs > 0)) || (!headshot && (g_iCvar_KW_ap_kill > 0)))
            {
                int attackerAP = GetClientArmor(attacker);

                if (attackerAP < g_iCvar_KW_ap_max)
                {
                    int addAP;
                    if (knifed)
                        addAP = g_iCvar_KW_ap_knife;
                    else if (headshot)
                        addAP = g_iCvar_KW_ap_hs;
                    else if (nades)
                        addAP = g_iCvar_KW_ap_nade;
                    else
                        addAP = g_iCvar_KW_ap_kill;
                    int newAP = attackerAP + addAP;
                    if (newAP > g_iCvar_KW_ap_max)
                        newAP = g_iCvar_KW_ap_max;
                    SetEntProp(attacker, Prop_Send, "m_ArmorValue", newAP, 1);
                }

                if (g_bCvar_KW_ap_messages && !g_bCvar_KW_hp_messages)
                {
                    if (knifed)
                        CPrintToChat(attacker, "%s \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_ap_knife, "AP Knife Kill");
                    else if (headshot)
                        CPrintToChat(attacker, "%s \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_ap_hs, "AP Headshot Kill");
                    else if (nades)
                        CPrintToChat(attacker, "%s \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_ap_nade, "AP Nade Kill");
                    else
                        CPrintToChat(attacker, "%s \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_ap_kill, "AP Kill");
                }
            }

            if (g_bCvar_KW_hp_messages && g_bCvar_KW_ap_messages)
            {
                if (knifed)
                    CPrintToChat(attacker, "%s \x04+%i HP\x01 & \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_knife, g_iCvar_KW_ap_knife, "HP Knife Kill", "AP Knife Kill");
                else if (headshot)
                    CPrintToChat(attacker, "%s \x04+%i HP\x01 & \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_hs, g_iCvar_KW_ap_hs, "HP Headshot Kill", "AP Headshot Kill");
                else if (nades)
                    CPrintToChat(attacker, "%s \x04+%i HP\x01 & \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_nade, g_iCvar_KW_ap_nade, "HP Nade Kill", "AP Nade Kill");
                else
                    CPrintToChat(attacker, "%s \x04+%i HP\x01 & \x04+%i AP\x01 %t", CHAT_BANNER, g_iCvar_KW_hp_kill, g_iCvar_KW_ap_kill, "HP Kill", "AP Kill");
            }
        }
    }
    return Plugin_Handled;
}

public OnSettingsChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_hCvar_KW_Enable)
        g_bCvar_KW_Enable = StringToInt(newValue) ? true : false;
    else if (convar == g_hCvar_KW_AdminOnly)
        g_bCvar_KW_AdminOnly = StringToInt(newValue) ? true : false;
    else if (convar == g_hCvar_KW_hp_messages)
        g_bCvar_KW_hp_messages = StringToInt(newValue) ? true : false;
    else if (convar == g_hCvar_KW_ap_messages)
        g_bCvar_KW_ap_messages = StringToInt(newValue) ? true : false;
    else if (convar == g_hCvar_KW_hp_max)
        g_iCvar_KW_hp_max = StringToInt(newValue);
    else if (convar == g_hCvar_KW_hp_kill)
        g_iCvar_KW_hp_kill = StringToInt(newValue);
    else if (convar == g_hCvar_KW_hp_hs)
        g_iCvar_KW_hp_hs = StringToInt(newValue);
    else if (convar == g_hCvar_KW_hp_knife)
        g_iCvar_KW_hp_knife = StringToInt(newValue);
    else if (convar == g_hCvar_KW_hp_nade)
        g_iCvar_KW_hp_nade = StringToInt(newValue);
    else if (convar == g_hCvar_KW_ap_max)
        g_iCvar_KW_ap_max = StringToInt(newValue);
    else if (convar == g_hCvar_KW_ap_kill)
        g_iCvar_KW_ap_kill = StringToInt(newValue);
    else if (convar == g_hCvar_KW_ap_hs)
        g_iCvar_KW_ap_hs = StringToInt(newValue);
    else if (convar == g_hCvar_KW_ap_knife)
        g_iCvar_KW_ap_knife = StringToInt(newValue);
    else if (convar == g_hCvar_KW_ap_nade)
        g_iCvar_KW_ap_nade = StringToInt(newValue);
}

UpdateConVars()
{
    g_bCvar_KW_Enable = GetConVarBool(g_hCvar_KW_Enable);
    g_bCvar_KW_AdminOnly = GetConVarBool(g_hCvar_KW_AdminOnly);
    g_iCvar_KW_hp_max = GetConVarInt(g_hCvar_KW_hp_max);
    g_iCvar_KW_hp_kill = GetConVarInt(g_hCvar_KW_hp_kill);
    g_iCvar_KW_hp_hs = GetConVarInt(g_hCvar_KW_hp_hs);
    g_iCvar_KW_hp_knife = GetConVarInt(g_hCvar_KW_hp_knife);
    g_iCvar_KW_hp_nade = GetConVarInt(g_hCvar_KW_hp_nade);
    g_bCvar_KW_hp_messages = GetConVarBool(g_hCvar_KW_hp_messages);
    g_iCvar_KW_ap_max = GetConVarInt(g_hCvar_KW_ap_max);
    g_iCvar_KW_ap_kill = GetConVarInt(g_hCvar_KW_ap_kill);
    g_iCvar_KW_ap_hs = GetConVarInt(g_hCvar_KW_ap_hs);
    g_iCvar_KW_ap_knife = GetConVarInt(g_hCvar_KW_ap_knife);
    g_iCvar_KW_ap_nade = GetConVarInt(g_hCvar_KW_ap_nade);
    g_bCvar_KW_ap_messages = GetConVarBool(g_hCvar_KW_ap_messages);
}
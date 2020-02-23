#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "TETRAGROMATON | github.com/tetragromaton"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <json>
#include <websocket>
#define foreach(%0) for (int %0 = 1; %0 <= MaxClients; %0++) if (IsClientInGame(%0))
public Plugin myinfo = 
{
	name = "Websocket Base", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
WebsocketHandle ServerSocket = INVALID_WEBSOCKET_HANDLE;
Handle CVAR_WebsocketPort;
Handle ClientSockets;

public void OnPluginStart()
{
	CVAR_WebsocketPort = CreateConVar("sm_discord_port", "1339", "WEBSOCKET PORT");
	ClientSockets = CreateArray();
}
public void OnPluginEnd()
{
	if (ServerSocket != INVALID_WEBSOCKET_HANDLE)
		Websocket_Close(ServerSocket);
}

OpenSocketStream()
{
	char serverIP[40];
	int longip = GetConVarInt(FindConVar("hostip"));
	FormatEx(serverIP, sizeof(serverIP), "%d.%d.%d.%d", (longip >> 24) & 0x000000FF, (longip >> 16) & 0x000000FF, (longip >> 8) & 0x000000FF, longip & 0x000000FF);
	
	if (ServerSocket == INVALID_WEBSOCKET_HANDLE)
		ServerSocket = Websocket_Open(serverIP, GetConVarInt(CVAR_WebsocketPort), OnWebsocketIncoming, OnWebsocketMasterError, OnWebsocketMasterClose);
	//CPrintToChatAll("{black}Binding at %s:%i", serverIP, GetConVarInt(CVAR_WebsocketPort));
}
public OnAllPluginsLoaded()
{
	OpenSocketStream();
}
public Action OnWebsocketIncoming(WebsocketHandle websocket, WebsocketHandle newWebsocket, const char[] remoteIP, int remotePort, char protocols[256])
{
	Format(protocols, sizeof(protocols), "");
	
	Websocket_HookChild(newWebsocket, OnWebsocketReceive, OnWebsocketDisconnect, OnChildWebsocketError);
	
	PushArrayCell(ClientSockets, newWebsocket);
	
	return Plugin_Continue;
}

public OnWebsocketMasterError(WebsocketHandle websocket, const errorType, const errorNum)
{
	LogError("MASTER SOCKET ERROR: handle: %d type: %d, errno: %d", _:websocket, errorType, errorNum);
	ServerSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnWebsocketMasterClose(WebsocketHandle websocket)
{
	ServerSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnChildWebsocketError(WebsocketHandle websocket, const errorType, const errorNum)
{
	LogError("CHILD SOCKET ERROR: handle: %d, type: %d, errno: %d", _:websocket, errorType, errorNum);
	
	RemoveFromArray(ClientSockets, FindValueInArray(ClientSockets, websocket));
}
public OnWebsocketReceive(WebsocketHandle websocket, WebsocketSendType iType, const char[] receiveData, const dataSize)
{
	bool IsArray = false;
	char fetch[16];
	strcopy(fetch, sizeof(fetch), receiveData);
	if (!StrEqual(fetch[0], "{"))
	{
		IsArray = true;
	}
	if (IsArray)
	{
		//Json things are here.
		//JSON_Object obj = json_decode(receiveData);
		//GetInts, do whatever you want.
	}
}
public OnWebsocketDisconnect(WebsocketHandle:websocket)
{
	RemoveFromArray(ClientSockets, FindValueInArray(ClientSockets, websocket));
}

public IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
} 
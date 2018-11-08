/**********************************
 *                                *
  *   Scripter:    CaptainBoi    *
  *   Version:     2.0           *
  *   Released:    07-11-2018    *
 *                                *
 **********************************/
 
/* Includes */
#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf2>
#include <zcmd>

/* MySQL Entities */
#define 	MYSQL_HOST		"127.0.0.1"
#define 	MYSQL_USER		"root"
#define 	MYSQL_PASS 		""
#define 	MYSQL_DB		"deathmatch"

/* Dialogs */
#define 	DIALOG_CONTROL_GPS 	100
#define 	DIALOG_ADD_GLOC    	101
#define 	DIALOG_DEL_GLOC    	102
#define     DIALOG_TP_GLOC     	103
#define     DIALOG_GPS          104
#define     DIALOG_GPS_LOC     	105

/* Database */
new MySQL: GPSDB;

/* Enumerator */
enum GPSData
{
    LocName[14],
	Float: Pos[3],
	Interior
}

/* Variables */
new gInfo[MAX_PLAYERS][GPSData];
new GPSMarker[MAX_PLAYERS];

public OnFilterScriptInit()
{
    new MySQLOpt: option_id = mysql_init_options(); 
	GPSDB = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB, option_id);
	if(GPSDB == MYSQL_INVALID_HANDLE || mysql_errno(GPSDB) != 0)
	{
		print("Cannot connect to mysql database"); 

		SendRconCommand("exit");
		return 1;
	}
	else print("Connected to mysql database."); 
	
	mysql_query(GPSDB, "CREATE TABLE IF NOT EXISTS `gpsdb` (\
	`S.No` INTEGER PRIMARY KEY AUTO_INCREMENT,\
	`LocationName` VARCHAR(100) NOT NULL,\
	`PositionX` FLOAT DEFAULT 0,\
	`PositionY` FLOAT DEFAULT 0,\
	`PositionZ` FLOAT DEFAULT 0,\
	`InteriorID` INT)", false);
	return 1;
}

public OnFilterScriptExit()
{
	mysql_close(GPSDB); 
	return 1;
}

public OnPlayerConnect(playerid)
{
	GPSMarker[playerid] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	GPSMarker[playerid] = 0;
	return 1;
}

/* Commands */
CMD:agps(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_CONTROL_GPS, DIALOG_STYLE_TABLIST_HEADERS, "Please select an option.", "\
	S.No\tOption\t-\tInformation\n\
	1.\tAdd GPS Location\t-\tYou can add gps location in /gps command.\n\
	2.\tDelete GPS Location\t-\tYou can remove/delete the gps locations.\n\
	3.\tGoto GPS Location\t-\tYou can teleport to the gps location.\n\
	4.\tShow GPS\t-\tYou can see all the locations created in gps.\n\
	5.\tTurn GPS Off\t-\tYou can turn gps off if its on.", "Select", "Cancel");
	return 1;
}

CMD:gps(playerid,params[])
{
	ShowPlayerDialog(playerid, DIALOG_GPS, DIALOG_STYLE_TABLIST_HEADERS, "Please select an option.", "\
	S.No\tOption\t-\tInformation\n\
	1.\tShow GPS Locations\t-\tYou can see all the available GPS locations.\n\
	2.\tTurn GPS Off\t-\tYou can turn gps off if its on.", "Select", "Cancel");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    new Query[216], Query2[216], string[216], string2[216];
    if(dialogid == DIALOG_CONTROL_GPS)
	{
		if(response)
		{
			if(listitem == 0)
			{
				SendClientMessage(playerid, 0xFFFF00FF, "Please enter the location name to add it in /gps.");
				ShowPlayerDialog(playerid, DIALOG_ADD_GLOC, DIALOG_STYLE_INPUT, "Add GPS Location", "Please enter the location name to add it in /gps.", "Add", "Cancel");
			}
			if(listitem == 1)
			{
				SendClientMessage(playerid, 0xFFFF00FF, "Please enter the location name to remove/delete the location in /gps.");
				ShowPlayerDialog(playerid, DIALOG_DEL_GLOC, DIALOG_STYLE_INPUT, "Delete GPS Location", "Please enter the location name to remove/delete the location in /gps.", "Delete", "Cancel");
			}
			if(listitem == 2)
			{
			    SendClientMessage(playerid, 0xFFFF00FF, "Please enter the location name to teleport through /gps location.");
				ShowPlayerDialog(playerid, DIALOG_TP_GLOC, DIALOG_STYLE_INPUT, "Teleport GPS Location", "Please enter the location name to teleport through /gps location.", "Teleport", "Cancel");
			}
			if(listitem == 3)
			{
				return cmd_gps(playerid, "");
			}
			if(listitem == 4)
			{
				if (GPSMarker[playerid] == 0) return SendClientMessage(playerid, 0xFF0000FF, "Error: Your GPS is already turned off!");
				DestroyDynamicMapIcon(GPSMarker[playerid]);
				GPSMarker[playerid] = 0;
				SendClientMessage(playerid, 0xFFFF00FF, "You have turned off your GPS.");
			}
		}
		return 1;
	}
	if(dialogid == DIALOG_ADD_GLOC)
	{
		if(response)
		{
			gInfo[playerid][Interior] = GetPlayerInterior(playerid);
			GetPlayerPos(playerid, gInfo[playerid][Pos][0], gInfo[playerid][Pos][1], gInfo[playerid][Pos][2]);
			mysql_format(GPSDB, Query, sizeof(Query), "SELECT * FROM `gpsdb` WHERE `LocationName` = '%s'", inputtext);
			new Cache:result = mysql_query(GPSDB, Query, true);
			
			if(cache_num_rows()) return SendClientMessage(playerid, 0xFF0000FF, "Error: That location name is already added.");
			mysql_format(GPSDB, Query2, sizeof(Query2), "INSERT INTO `gpsdb` (`LocationName`, `PositionX` , `PositionY` , `PositionZ`, `InteriorID`) VALUES ('%e', '%f', '%f', '%f', '%d')", inputtext, gInfo[playerid][Pos][0], gInfo[playerid][Pos][1], gInfo[playerid][Pos][2], gInfo[playerid][Interior]);
			mysql_query(GPSDB, Query2, false);
			
			format(string, sizeof(string), "You have added location: %s in /gps.", inputtext);
			SendClientMessage(playerid, 0xFFFF00FF, string);
			cache_delete(result);
		}
		return 1;
	}
	if(dialogid == DIALOG_DEL_GLOC)
	{
		if(response)
		{
			mysql_format(GPSDB, Query, sizeof(Query),"DELETE FROM `gpsdb` WHERE `LocationName` = '%s'", inputtext);
			mysql_query(GPSDB, Query, false);
			
			format(string, sizeof(string), "You have removed gps location: {F3FF02}%s", inputtext);
			SendClientMessage(playerid, 0xFFFF00FF, string);
		}
		return 1;
	}
	if(dialogid == DIALOG_TP_GLOC)
	{
		if(response)
		{
			mysql_format(GPSDB, Query, sizeof(Query), "SELECT * FROM `gpsdb` WHERE `LocationName` = '%s'", inputtext);
			new Cache:result = mysql_query(GPSDB, Query, true);
			if(cache_num_rows())
			{
				cache_get_value_name(0, "LocationName", gInfo[playerid][LocName]);
				cache_get_value_name_float(0, "PositionX", gInfo[playerid][Pos][0]);
				cache_get_value_name_float(0, "PositionY", gInfo[playerid][Pos][1]);
				cache_get_value_name_float(0, "PositionZ", gInfo[playerid][Pos][2]);
				cache_get_value_name_int(0, "InteriorID", gInfo[playerid][Interior]);
				SetPlayerPos(playerid, gInfo[playerid][Pos][0], gInfo[playerid][Pos][1], gInfo[playerid][Pos][2]);
				format(string, sizeof(string), "You have been teleported to gps location: {F3FF02}'%s'", gInfo[playerid][LocName]);
				SendClientMessage(playerid, 0xFFFF00FF, string);
			}
			else SendClientMessage(playerid, 0xFF0000FF,"Error: The location you entered does not exist.");
			cache_delete(result);
		}
		return 1;
	}
	if(dialogid == DIALOG_GPS)
	{
		if(response)
		{
			if(listitem == 0)
			{
				new Cache:result = mysql_query(GPSDB,"SELECT `LocationName` FROM `gpsdb` WHERE `S.No` > -1 LIMIT 100");
				if(!cache_num_rows())
				{
					cache_delete(result);
					SendClientMessage(playerid, 0xFF0000FF,"Error: There is no gps locations added yet.");
					return 1;
				}
				
				for(new i; i< cache_num_rows(); i++)
				{
					cache_get_value_name(i,"LocationName", gInfo[playerid][LocName]);
					format(string, sizeof(string), "%s%d\t%s\n", string, i, gInfo[playerid][LocName]);
				}
				format(string2, sizeof(string2), "S.No\tLocation Name\n%s", string);
				
				SendClientMessage(playerid, 0xFFFF00FF, "Please select a location.");
				ShowPlayerDialog(playerid, DIALOG_GPS_LOC, DIALOG_STYLE_TABLIST_HEADERS, "Please select an option.", string2, "Select", "Cancel");
			}
			if(listitem == 1)
			{
				if (GPSMarker[playerid] == 0) return SendClientMessage(playerid, 0xFF0000FF, "Error: Your GPS is already turned off!");
				DestroyDynamicMapIcon(GPSMarker[playerid]);
				GPSMarker[playerid] = 0;
				SendClientMessage(playerid, 0xFFFF00FF, "You have turned off your GPS.");
			}
		}
		return 1;
	}
	if(dialogid == DIALOG_GPS_LOC)
	{
	    if(response)
		{
			if (GPSMarker[playerid] != 0) 
			{
				DestroyDynamicMapIcon(GPSMarker[playerid]);
			}
			GPSMarker[playerid] = CreateDynamicMapIcon(gInfo[listitem][Pos][0], gInfo[listitem][Pos][1], gInfo[listitem][Pos][2], 41, 0, -1, -1, playerid, 100000.0);
			Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, GPSMarker[playerid], E_STREAMER_STYLE, MAPICON_GLOBAL);
			Streamer_Update(playerid);
			format(string, sizeof(string), "The location: %s, has been marked on your mini-map.", inputtext);
			SendClientMessage(playerid, 0xFFFF00FF, string);
		}
		return 1;
	}
	return 1;
}

/* Stocks */
stock playername(playerid)
{
	new pname[24];
	GetPlayerName(playerid, pname, sizeof(pname));
	return pname;
}

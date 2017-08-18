#include amxmodx
#include amxmisc
#include orpheu

#include orpheu_stocks

new const PLUGIN[]=		"InMessage"
new const VERSION[]=		"Alpha:v1"
new const AUTHOR[]=		"RevCrew & Leonidddd"

new const PREFIX[] = 	"InMessage"

#define is_valid_player(%0) (1<=%0<=32)
#define TYPE_INGAME_MESS 76
#define MESS_LEN 63 

new index_player = 0;

new OrpheuFunction:pfnMessageBegin;
new OrpheuFunction:pfnWriteString;

new const PF_MessageBegin_I[] = "orpheu/functions/PF_MessageBegin_I";
new const PF_WriteString_I[] = "orpheu/functions/PF_WriteString_I";

new g_cvar_checktype = 1;

enum _:INMessage
{
	szMain[64],
	szReplace[64]
}

new Array: g_InMessage, g_size = 0;

public plugin_precache()
{
	static const DIR[] = "addons/amxmodx/logs/InMessage/"
	if(!dir_exists(DIR))
		mkdir(DIR);
		
	g_InMessage = ArrayCreate(INMessage)
}
public plugin_end()
{
	ArrayDestroy(g_InMessage)
}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)	
	
	if( check_orpheu_functions() == false || ReadFiles() == false)
		set_fail_state("Fatal Error: Check Logs")
	
	pfnMessageBegin = OrpheuGetEngineFunction( "pfnMessageBegin","PF_MessageBegin_I" );
	pfnWriteString = OrpheuGetEngineFunction( "pfnWriteString","PF_WriteString_I" );
	
	OrpheuRegisterHook( pfnMessageBegin, "Hook_MessageBegin", OrpheuHookPre )
	OrpheuRegisterHook( pfnWriteString, "Hook_WriteString", OrpheuHookPre )
}
public Hook_WriteString( const szWriteString[])
{
	if(index_player == -1)
		return _:OrpheuIgnored;
		
	static data[INMessage], len;
	
	static size; size = g_size
	
	for(new i; i< size; i++)
	{
		
		ArrayGetArray(g_InMessage, i, data);
		
		if( (g_cvar_checktype == 0 && !equal(szWriteString, data[szMain],strlen(data[szMain]))) || (g_cvar_checktype != 0  && containi(szWriteString, data[szMain]) == -1))
			continue;
		
		len = strlen(data[szReplace])
		switch (len)
		{
			case 0: 
				return _:OrpheuSupercede;
			default: {
				static szStr[64];
				
				copy(szStr, charsmax(szStr), szWriteString)
				replace(szStr, charsmax(szStr), data[szMain], data[szReplace])
				
				OrpheuCall(pfnWriteString, szStr)
				return _:OrpheuSupercede;
			}
		}
	}

	
	return _:OrpheuIgnored;
}

public Hook_MessageBegin( const dest, const type, Float:f, const player_id)
{
	if(type != TYPE_INGAME_MESS) return _:OrpheuIgnored;
	
	index_player = is_valid_player(player_id) ? player_id : -1;
	return _:OrpheuIgnored;
}
stock bool:ReadFiles()
{
	new f = fopen("addons/amxmodx/configs/InMessage.ini", "r")
	
	if(!f)
		return bool:PrintMessage("File [InMessage.ini] not found in configs/");
	
	static filedata[128];
	
	new const START[] = "[INMESSAGE]", len = strlen(START);
	new const CVAR[] = "inmessage_check_type", len2 = strlen(CVAR)
	new bool:index = false, bool:check;
	
	static data[INMessage]
	
	while(!feof(f))
	{
		fgets(f, filedata, charsmax(filedata))
		trim(filedata)
		
		if(!filedata[0] || filedata[0] == '#')
			continue;
			
		if(equal(filedata, START, len))
		{
			index = true;
			continue;
		}
		
		check = bool:(equal(filedata,CVAR, len2))
		
		if(!index && !check)
			continue;
			
		if(check)
		{
			replace(filedata, charsmax(filedata), CVAR, "")
			replace(filedata, charsmax(filedata), "=", "");
			
			trim(filedata);
			
			
			g_cvar_checktype = str_to_num(filedata)
			continue;
		}
		
	
		strbreak(filedata, data[szMain], MESS_LEN, data[szReplace], MESS_LEN)
		
		remove_quotes(data[szMain])
		remove_quotes(data[szReplace])
		
		ArrayPushArray(g_InMessage,data)
		g_size ++;
	}
	
	fclose(f)
	return g_size > 0 ? true : false;
}
stock bool:check_orpheu_functions()
{
	static dir[64];
	get_configsdir(dir, charsmax(dir))
	
	static path_messagebegin[128];
	static path_writestring[128];
	
	formatex(path_messagebegin, sizeof(path_messagebegin) - 1, "%s/%s",dir,PF_MessageBegin_I)
	formatex(path_writestring, sizeof(path_writestring) - 1, "%s/%s",dir,PF_WriteString_I)
	
	if(!file_exists(path_messagebegin))
		return bool:PrintMessage("File [%s] not found | Plugin is off", path_messagebegin)
		 
	
	if(!file_exists(path_writestring))
		return bool:PrintMessage("File [%s] not found | Plugin is off", path_writestring)
	
	
	return true;
}
stock PrintMessage(const szMessage[], any:...)
{
	static szMsg[196];
	vformat(szMsg, charsmax(szMsg), szMessage, 2);
	
	static LogDat[16],LogFile[64]
	get_time("%Y_%m_%d", LogDat, 15);
	
	get_basedir(LogFile,63)
	formatex(LogFile,63,"%s/logs/InMessage/Log_%s.log",LogFile,LogDat)
	log_to_file(LogFile,"[%s] %s",PREFIX,szMsg)
	
	return 0;
}

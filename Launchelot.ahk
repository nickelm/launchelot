; --------------------------------------------------------------------------------
; Launchelot - DAoC Launcher for AHK by Madgrim Laeknir (BelomarFleetfoot#0319).
;
; Released July 2021 as Open Source on GitHub under the MIT License.
; 
; June 3, 2021 - Initial version.
; June 7, 2021 - Standalone launcher support.
; June 10, 2021 - First release: major features implemented.
; June 12, 2021 - Second release: adding context menus and bug fixes.
; June 16, 2021 - Fourth build: UI updates to avoid reloading.
; June 20, 2021 - Fifth build: saving sort order state.
; June 22, 2021 - Sixth build: launching teams
; --------------------------------------------------------------------------------

#SingleInstance, Force		; Force a single instance of this script
#NoEnv  					; For performance and compatibility with future AHK releases.
#Warn  						; Enable warnings to assist with detecting common errors.

LaunchelotInit: ; To prevent warnings because of auto-execute not reached when using the library

; -- Globals
global ToonView := "", AccountView := "", TeamView := ""
global ToonContextMenu, AccountContextMenu, TeamContextMenu
global LaunchTab
global EditMode := "Toon", EditIndex := -1, EditRow := -1
global ValueControl1, ValueControl2, ValueControl3, ValueControl4, ValueControl5, ValueControl6, ValueControl7, ValueControl8, ValueControl9

global realms   := ["Alb", "Mid", "Hib"]

global servers  := ["Ywain1", "Ywain2", "Ywain3", "Ywain4", "Ywain5", "Ywain6", "Ywain7", "Ywain8", "Ywain9", "Ywain10", "Gaheris"]

global classes  := ["Animist", "Armsman", "Bainshee", "Bard", "Berserker", "Blademaster", "Bonedancer", "Cabalist", "Champion", "Cleric", "Druid", "Eldritch", "Enchanter", "Friar", "Healer", "Heretic", "Hero", "Hunter", "Infiltrator", "Mauler", "Mentalist", "Mercenary", "Minstrel", "Necromancer", "Nightshade", "Paladin", "Ranger", "Reaver", "Runemaster", "Savage", "Scout", "Shadowblade", "Shaman", "Skald", "Sorcerer", "Spiritmaster", "Thane", "Theurgist", "Valewalker", "Valkyrie", "Vampiir", "Warden", "Warlock", "Warrior", "Wizard"]

global DefaultDAoCPath := "C:\Program Files (x86)\Electronic Arts\Dark Age of Camelot"
global LaunchelotBuild := "Build 6 - July 26, 2021"

; -- Run the launcher if the script is run standalone
if (IsStandalone()) {
	
	; If there is no .ini file, create it
	if (FileExist(A_ScriptDir . "\launchelot.ini") = "") {
		FileSelectFolder, tmp_path, *%DefaultDAoCPath%, 0, "Select the DAoC Game folder"
		if (ErrorLevel = 1) {
			ExitApp
		}
		IniWrite %tmp_path%, %A_ScriptDir%\launchelot.ini, Settings, game_path
	}

	; Now run the launcher
	RunLauncher()
}
Return

; -- Reload the script using Ctrl+Alt+R
; ^!r::Reload

; -- Launch DAoC -------------------------------------------------
; path - full path on your hard drive to DAoC 
; server - DAoC server (Gaheris, Ywain1, Ywain2, ..., Ywain10)
; account - your full account name
; password - your password in plain text
; toon - character name
; realm - "1" for Albion, "2" for Midgard, "3" for Hibernia
; --------------------------------------------------------------------
LaunchDAoC(path, server, account, password, toon := "", realm := "") {
	server_list := { "gaheris" : "107.21.60.95 10622 23", "ywain1" : "107.23.173.143 10622 41", "ywain2" : "107.23.173.143 10622 49", "ywain3" : "107.23.173.143 10622 50", "ywain4" : "107.23.173.143 10622 51", "ywain5" : "107.23.173.143 10622 52", "ywain6" : "107.23.173.143 10622 53", "ywain7" : "107.23.173.143 10622 54", "ywain8" : "107.23.173.143 10622 55","ywain9" : "107.23.173.143 10622 56", "ywain10" : "107.23.173.143 10622 57" }

	; Add a missing backslash if needed
	StringRight, checkvar, path, 1
	if (checkvar != "\") {
		path := path . "\"
	}

	; Make the server string lowercase
	StringLower, server, server

	; Run the game (setting and resetting the working directory)
	server_str := server_list[server]
	SetWorkingDir, %path%
	Run, %path%game.dll %server_str% %account% %password% %toon% %realm%
	SetWorkingDir, %A_ScriptDir%
}

; -- Launch Toon from Database ---------------------------------------
; toon - character name
; run_script - run the AHK script (if there is one) (optional)
; --------------------------------------------------------------------
LaunchToon(toon, run_script := true)
{
	; Find the path
	IniRead daoc_path, %A_ScriptDir%\launchelot.ini, Settings, game_path

	; Read the accounts
	accounts := GetAccounts()

	; Find the toon
	toon_ndx := FindValueIndex(toon, "Toons", "toon")
	if (toon_ndx = 0) {
		MsgBox, Didn't find toon %toon% in the database (launchelot.ini)!
	}

	; Read the toon data
	IniRead toon_data, %A_ScriptDir%\launchelot.ini, Toons, toon%toon_ndx%
	item := StrSplit(toon_data, ",")

	; Set up the values
	account := Trim(item[2])
	server := Trim(item[3])
	script := item.MaxIndex() > 5 ? item[6] : ""
	realm := (item[5] = "Alb") ? 1 : (item[5] = "Mid") ? 2 : 3

	; Look up the password
	if (!accounts.HasKey(account)) {
		MsgBox, Missing account information for %account%!
		Return
	}

	; Extract the password and launch
	Base64decUTF8(password, accounts[account][2])
	LaunchDAoC(daoc_path, server, account, password, toon, realm)

	; If there is an AHK script, call it too
	if (script != "" and run_script) 
		RunScript(script)	
}

; -- Launch Account from Database ---------------------------------------
; account - account name
; server - server name
; --------------------------------------------------------------------
LaunchAccount(account, server)
{
	; Find the path
	IniRead daoc_path, %A_ScriptDir%\launchelot.ini, Settings, game_path

	; Look up the password
	if (!accounts.HasKey(account)) {
		MsgBox, Missing account information for %account%!
		Return
	}

	; Extract the password and launch
	Base64decUTF8(password, accounts[account][2])
	LaunchDAoC(daoc_path, server, account, password)
}

; -- Launch Team from Database ---------------------------------------
; Launch a team (multiple toons). Kills mutexes to allow this to happen.
; toons - list of character names
; script - AHK script (optional)
; --------------------------------------------------------------------
LaunchTeam(toons, script := "")
{
	; Loop through the array of toons
	for index, element in toons {

		; Skip empty toons
		if (element == "")
			Continue

		; Launch this toon
		LaunchToon(element, false)

		; Sleep half a second
		Sleep, 500

		; Kill the mutex (if needed)
		KillMutex()
	}

	; If there is an AHK script, call it too
	if (script != "") 
		RunScript(script)
}

RunScript(script) 
{
	if (FileExist(A_ScriptDir . "\" . script) = "") {
		MsgBox, No script file %script% found in %A_ScriptDir%!
	}
	else {
		Run %A_ScriptDir%\%script%
		if (ErrorLevel = "ERROR") {
			MsgBox, Unable to start the AHK script %script%!
		}
	}	
}

KillMutex()
{
	; Check if the file exists
	if (FileExist(A_ScriptDir . "\kill_mutex_64.exe") == "")
		Return

	; Kill the mutex
	Run, %A_ScriptDir%\kill_mutex_64.exe "\BaseNamedObjects\DAoCi1" "\BaseNamedObjects\DAoCi2",, Hide
}

; Find the next free index in an .ini file
FindNextIndex(sec, key_prefix)
{
	IniRead num, %A_ScriptDir%\launchelot.ini, %sec%, max_index, 0
	Loop, %num% {
		IniRead data, %A_ScriptDir%\launchelot.ini, %sec%, %key_prefix%%A_Index%, ERROR
		if (data = "ERROR") {
			return A_Index
		}
	}
	return num + 1
}

; Find the index of a specific value
FindValueIndex(value, sec, key_prefix)
{
	IniRead num, %A_ScriptDir%\launchelot.ini, %sec%, max_index, 0
	Loop, %num% {
		IniRead data, %A_ScriptDir%\launchelot.ini, %sec%, %key_prefix%%A_Index%, ERROR
		if (data = "ERROR")
			continue
		if (SubStr(data, 1, StrLen(value)) = value)
			return A_Index
	}
	return 0
}

LaunchelotMenuHandler()
{
	switch (A_ThisMenuItem) {
	Case "Set &DAoC Path":
		IniRead daoc_path, %A_ScriptDir%\launchelot.ini, Settings, game_path
		FileSelectFolder, new_path, *%daoc_path%, 0, "Select the DAoC Game folder"
		if (ErrorLevel != 1)
			IniWrite %new_path%, %A_ScriptDir%\launchelot.ini, Settings, game_path
	Case "&Reload":
		Reload
	Case "E&xit":
		ExitApp
	Case "&About":
		MsgBox, 8192, Launchelot, Launchelot - a DAoC Launcher using AutoHotKey. `nCopyright 2021 by Madgrim Laeknir (BelomarFleetfoot#0319). `n%LaunchelotBuild%

	Default:
		return
	}
}

RunLauncher()
{
	; Read settings
	IniRead ToonSortColumn, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_column, -1
	IniRead ToonSortAscending, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_ascending, 1
	IniRead AccountSortColumn, %A_ScriptDir%\launchelot.ini, Settings, account_sort_column, -1
	IniRead AccountSortAscending, %A_ScriptDir%\launchelot.ini, Settings, account_sort_ascending, 1
	IniRead TeamSortColumn, %A_ScriptDir%\launchelot.ini, Settings, team_sort_column, -1
	IniRead TeamSortAscending, %A_ScriptDir%\launchelot.ini, Settings, team_sort_ascending, 1

	; Set up the menu bar
	Gui, Launchelot:+Resize MinSize400x400
	Menu, FileMenu, Add, Set &DAoC Path, LaunchelotMenuHandler
	Menu, FileMenu, Add, &Reload, LaunchelotMenuHandler
	Menu, FileMenu, Add, &Kill Mutex, KillMutex
	Menu, FileMenu, Add
	Menu, FileMenu, Add, E&xit, LaunchelotMenuHandler
	Menu, HelpMenu, Add, &About, LaunchelotMenuHandler
	Menu, LaunchelotMenuBar, Add, &File, :FileMenu
	Menu, LaunchelotMenuBar, Add, &Help, :HelpMenu

	; Attach it to the window
	Gui, Launchelot:Menu, LaunchelotMenuBar

	; Add tab control
	Gui, Launchelot:Add, Tab3, vLaunchTab w480 h380, Toons|Accounts|Teams

	; Set up the toons tab
	Gui, Launchelot:Tab, 1
	Gui, Launchelot:Add, Button, gAddToon w80 Section, Add
	Gui, Launchelot:Add, Button, gEditToon w80 ys, Edit
	Gui, Launchelot:Add, Button, gDeleteToon w80 ys, Delete

	; Add the toons to the toon tab
	toons := GetToons()
	Gui, Launchelot:Add, ListView, vToonView gHandleToonView -Multi w460 h300 xs, Toon|Account|Class|Server|Realm|Script|Note
	Gui, Launchelot:Default
	for index, elem in toons {
		curr_toon := toons[A_Index][1]
		curr_note := toons[A_Index].length() > 6 ? toons[A_Index][7] : ""
		LV_Add("", curr_toon, toons[A_Index][2], toons[A_Index][4], toons[A_Index][3], toons[A_Index][5], toons[A_Index][6], curr_note)
	}
	LV_ModifyCol()

	; Set the sorting state
	if (ToonSortColumn != -1) {
		LV_ModifyCol(ToonSortColumn, ToonSortAscending ? "sort" : "sortDesc")
	}

	; Create a toon popup menu
	Menu, ToonContextMenu, Add, Launch, Context
	Menu, ToonContextMenu, Add, Edit, Context
	Menu, ToonContextMenu, Add, Delete, Context
	Menu, ToonContextMenu, Default, Launch ; Make "Launch" a bold font to indicate that double-click does the same thing.	

	; Set up the account tab
	Gui, Launchelot:Tab, 2
	Gui, Launchelot:Add, Button, gAddAccount w80 Section, Add
	Gui, Launchelot:Add, Button, gEditAccount w80 ys, Edit
	Gui, Launchelot:Add, Button, gDeleteAccount w80 ys, Delete

	; Add the accounts to the account tab
	accounts := GetAccounts()
	Gui, Launchelot:Add, ListView, -Multi vAccountView gHandleAccountView w460 h300 xs, Account|Password
	Gui, Launchelot:Default
	for index, elem in accounts {
		LV_Add("", elem[1], "********")
	}
	LV_ModifyCol()

	; Set the sorting state
	if (AccountSortColumn != -1) {
		LV_ModifyCol(AccountSortColumn, AccountSortAscending ? "sort" : "sortDesc")
	}

	; Create an account popup menu
	for ndx, label in servers {
		Menu, ServerContextMenu, Add, %label%, Context
	}	
	Menu, AccountContextMenu, Add, Launch, :ServerContextMenu
	Menu, AccountContextMenu, Add, Edit, Context
	Menu, AccountContextMenu, Add, Delete, Context

	; Set up the team tab
	Gui, Launchelot:Tab, 3
	Gui, Launchelot:Add, Button, gAddTeam w80 Section, Add
	Gui, Launchelot:Add, Button, gEditTeam w80 ys, Edit
	Gui, Launchelot:Add, Button, gDeleteTeam w80 ys, Delete

	; Add the teams to the team tab
	teams := GetTeams()
	Gui, Launchelot:Add, ListView, -Multi vTeamView gHandleTeamView w460 h300 xs, Team|Script
	Gui, Launchelot:Default
	for index, elem in teams {
		script := elem[1]
		elem.RemoveAt(1)
		toon_data := Join(",", elem*)
		LV_Add("", toon_data, script)
	}
	LV_ModifyCol()

	; Set the sorting state
	if (TeamSortColumn != -1) {
		LV_ModifyCol(TeamSortColumn, TeamSortAscending ? "sort" : "sortDesc")
	}

	; Create a team popup menu
	Menu, TeamContextMenu, Add, Launch, Context
	Menu, TeamContextMenu, Add, Edit, Context
	Menu, TeamContextMenu, Add, Delete, Context
	Menu, TeamContextMenu, Default, Launch ; Make "Launch" a bold font to indicate that double-click does the same thing.

	; Show the window
	Gui, Launchelot:Show, w600 h400, Launchelot by Madgrim

	; Reset tab use
	Gui, Tab
}

Join(sep, params*) {
	str := ""
    for index, param in params
        str .= param . sep
    return SubStr(str, 1, -StrLen(sep))
}

Context() {
	; purposefully empty
}

LaunchelotGuiContextMenu() {
	if (A_GuiControl = "ToonView") {
		Gui, Launchelot:Tab, 1
		Gui, Launchelot:ListView, ToonView
		curr_row := LV_GetNext(0, "F")
		if (curr_row = 0)
			return
		LV_GetText(curr_toon, curr_row, 1)
		curr_ndx := FindValueIndex(curr_toon, "Toons", "toon")

		; Show the menu
		Menu, ToonContextMenu, Show, %A_GuiX%, %A_GuiY%

		Switch (A_ThisMenuItem) {
		Case "Launch":
			LaunchToon(curr_toon)

		Case "Edit":
			LV_GetText(curr_account, curr_row, 2)
			LV_GetText(curr_server, curr_row, 3)
			LV_GetText(curr_class, curr_row, 4)
			LV_GetText(curr_realm, curr_row, 5)
			LV_GetText(curr_script, curr_row, 6)
			LV_GetText(curr_note, curr_row, 7)
			ShowToonDialog("Edit Toon", curr_ndx, curr_row, curr_toon, curr_account, curr_server, curr_class, curr_realm, curr_script, curr_note)

		Case "Delete":
			MsgBox, 8196, Warning, Are you sure you want to delete toon %curr_toon%?
			IfMsgBox Yes
			{
				IniDelete, %A_ScriptDir%\launchelot.ini, Toons, toon%curr_ndx%
				LV_Delete(curr_row)
			}
		}

	}
	else if (A_GuiControl = "AccountView") {
		Gui, Launchelot:Tab, 2
		Gui, Launchelot:ListView, AccountView
		curr_row := LV_GetNext(0, "F")
		if (curr_row = 0)
			return
		LV_GetText(curr_account, curr_row, 1)
		curr_ndx := FindValueIndex(curr_account, "Accounts", "account")

		; Show the menu
		Menu, AccountContextMenu, Show, %A_GuiX%, %A_GuiY%

		Switch (A_ThisMenuItem) {
		Case "Edit":
			CreateEditDialog("Edit Account", curr_ndx, curr_row, [["Account name", curr_account], ["Password", ""]])

		Case "Delete":
			MsgBox, 8196, Warning, Are you sure you want to delete account %curr_account%?
			IfMsgBox Yes
			{
				IniDelete, %A_ScriptDir%\launchelot.ini, Accounts, account%curr_ndx%
				LV_Delete(curr_row)
			}

		Default:
			if (A_ThisMenuItem = "")
				return
			LaunchAccount(curr_account, A_ThisMenuItem)
		}
	}
	else if (A_GuiControl = "TeamView") {
		Gui, Launchelot:Tab, 3
		Gui, Launchelot:ListView, TeamView
		curr_row := LV_GetNext(0, "F")
		if (curr_row = 0)
			return
		LV_GetText(curr_team, curr_row, 1)
		LV_GetText(curr_script, curr_row, 2)
		curr_team_id := curr_script "," curr_team
		curr_ndx := FindValueIndex(curr_team_id, "Teams", "team")
		curr_toons := StrSplit(curr_team, ",")
		while curr_toons.length() < 8
		{
			curr_toons.push("")
		}

		; Show the menu
		Menu, TeamContextMenu, Show, %A_GuiX%, %A_GuiY%

		Switch (A_ThisMenuItem) {
		Case "Edit":
			CreateEditDialog("Edit Team", curr_ndx, curr_row, [["Script", curr_script], ["Toon 1", curr_toons[1]], ["Toon 2", curr_toons[2]], ["Toon 3", curr_toons[3]], ["Toon 4", curr_toons[4]], ["Toon 5", curr_toons[5]], ["Toon 6", curr_toons[6]], ["Toon 7", curr_toons[7]], ["Toon 8", curr_toons[8]]])

		Case "Delete":
			MsgBox, 8196, Warning, Are you sure you want to delete team %curr_team%?
			IfMsgBox Yes
			{
				IniDelete, %A_ScriptDir%\launchelot.ini, Teams, team%curr_ndx%
				LV_Delete(curr_row)
			}

		Default:
			if (A_ThisMenuItem = "")
				return
			LaunchTeam(curr_toons, curr_script)
		}
	}	
}

CreateEditDialog(title, curr_ndx, curr_row, fields) {
	; Save the editing mode
	EditMode := title
	EditIndex := curr_ndx
	EditRow := curr_row

	; Add the fields
	for index, elem in fields {

		; Extract the fields and values
		field := elem[1]
		value := elem[2]

		; Field label
		Gui, LaunchelotEdit:Add, Text, xm Section w92, %field%:

		; Set up the fields
		if (value.MaxIndex() == "") {
			passwd := field = "Password" ? "Password" : ""
			Gui, LaunchelotEdit:Add, Edit, vValueControl%A_Index% xs+92 ys w192 %passwd%, %value%
		}
		else {
			values := Join("|", value*)
			values .= "|"
			Gui, LaunchelotEdit:Add, DropDownList, vValueControl%A_Index% xs+92 ys w192, %values%
		}
	}

	; Add the control buttons
	Gui, LaunchelotEdit:Add, Button, gLaunchelotEditSave xm w80 Section Default, Save
	Gui, LaunchelotEdit:Add, Button, gLaunchelotEditGuiClose w80 ys, Cancel

	; Show the window
	height := fields.MaxIndex() * 30 + 32
	Gui, LaunchelotEdit:Show, w300 h%height%, %title%

	; Make it modal
	Gui, Launchelot:+Disabled
	Gui, LaunchelotEdit:+OwnerLaunchelot
}

LaunchelotEditSave()
{
	; Submit the associated data
	Gui, Submit, Nohide
	LaunchelotEditGuiClose()

	; Now save into the .ini file
	if (InStr(EditMode, "Toon")) {

		; Eliminate commas from notes
		notes := StrReplace(ValueControl7, ",")
		
		; Construct the data string
		data := Join(",", ValueControl1, ValueControl2, ValueControl4, ValueControl3, ValueControl5, ValueControl6, notes)

		; Now update the listview
		Gui, Launchelot:Tab, 1
		Gui, Launchelot:ListView, ToonView
		Gui, Launchelot:Default

	 	; Are we creating a new entry?
		if (EditIndex = -1) {
			IniRead, max_index, %A_ScriptDir%\launchelot.ini, Toons, max_index, 0
			next_ndx := FindNextIndex("Toons", "toon")
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Toons, toon%next_ndx%
			if (next_ndx > max_index) {
				IniWrite, %next_ndx%, %A_ScriptDir%\launchelot.ini, Toons, max_index
			}
			LV_Add("", ValueControl1, ValueControl2, ValueControl3, ValueControl4, ValueControl5, ValueControl6, notes)
		}
		; No, we are updating an old one
		else {
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Toons, toon%EditIndex%
			LV_Modify(EditRow, "", ValueControl1, ValueControl2, ValueControl3, ValueControl4, ValueControl5, ValueControl6, notes)
		}
	}
	else if (InStr(EditMode, "Account")) {

		; Encode the password
		Base64encUTF8(password, ValueControl2)

		; Construct the data string
		data := Join(",", ValueControl1, password)

		; Now update the listview
		Gui, Launchelot:Tab, 2
		Gui, Launchelot:ListView, AccountView
		Gui, Launchelot:Default

	 	; Are we creating a new entry?
		if (EditIndex = -1) {
			IniRead, max_index, %A_ScriptDir%\launchelot.ini, Accounts, max_index, 0
			next_ndx := FindNextIndex("Accounts", "account")
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Accounts, account%next_ndx%
			LV_Add("", ValueControl1, "********")			
			if (next_ndx > max_index) {
				IniWrite, %next_ndx%, %A_ScriptDir%\launchelot.ini, Accounts, max_index
			}
		}
		; No, we are updating an old one
		else {
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Accounts, account%EditIndex%
			LV_Modify(EditRow, "", ValueControl1, "********")			
		}
	}
	else if (InStr(EditMode, "Team")) {

		; Construct the data string
		toon_data := Join(",", ValueControl2, ValueControl3, ValueControl4, ValueControl5, ValueControl6, ValueControl7, ValueControl8, ValueControl9)
		data := Join(",", ValueControl1, toon_data)

		; Now update the listview
		Gui, Launchelot:Tab, 3
		Gui, Launchelot:ListView, TeamView
		Gui, Launchelot:Default

	 	; Are we creating a new entry?
		if (EditIndex = -1) {
			IniRead, max_index, %A_ScriptDir%\launchelot.ini, Teams, max_index, 0
			next_ndx := FindNextIndex("Teams", "team")
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Teams, team%next_ndx%
			if (next_ndx > max_index) {
				IniWrite, %next_ndx%, %A_ScriptDir%\launchelot.ini, Teams, max_index
			}
			LV_Add("", toon_data, ValueControl1)
		}
		; No, we are updating an old one
		else {
			IniWrite, %data%, %A_ScriptDir%\launchelot.ini, Teams, team%EditIndex%
			LV_Modify(EditRow, "", toon_data, ValueControl1)
		}

	}
}

LaunchelotEditGuiClose()
{	
	; Now enable the main window
	Gui, Launchelot:-Disabled

	; Destroy the edit window if it already exists
	Gui, LaunchelotEdit:Destroy	
}

MarkDDLOption(array, selected) {
	array_copy := []
	for ndx, value in array {
		array_copy[ndx] := value
		if (value = selected) {
			array_copy[ndx] := value . "|"
		}
	}
	return array_copy
}

GetKeys(object) {
	keys := []
	for key, value in object {
		keys.push(key)
	}
	return keys
}

ShowToonDialog(title, curr_ndx, curr_row, curr_toon, curr_account, curr_class, curr_server, curr_realm, curr_script, curr_note) {
	; Construct the DDL arrays
	accounts := GetAccounts()

	curr_accounts := MarkDDLOption(GetKeys(accounts), curr_account)
	curr_classes := MarkDDLOption(classes, curr_class)
	curr_servers := MarkDDLOption(servers, curr_server)
	curr_realms := MarkDDLOption(realms, curr_realm)

	; Create the dialog
	CreateEditDialog(title, curr_ndx, curr_row, [[ "Toon name", curr_toon ], [ "Account", curr_accounts ], [ "Class", curr_classes], ["Server", curr_servers], ["Realm", curr_realms], ["AHK Script (if any)", curr_script], ["Notes", curr_note]])
}

AddToon() {
	ShowToonDialog("Add Toon", -1, -1, "", "", "", "", "", "", "")
}

AddAccount() {
	CreateEditDialog("Add Account", -1, -1, [["Account name", ""], ["Password", ""]])
}

AddTeam() {
	CreateEditDialog("Add Team", -1, -1, [["Script", ""], ["Toon 1", ""], ["Toon 2", ""], ["Toon 3", ""], ["Toon 4", ""], ["Toon 5", ""], ["Toon 6", ""], ["Toon 7", ""], ["Toon 8", ""]])	
}

EditToon() {
	; Find the toon currently selected
	Gui, Launchelot:Tab, 1
	Gui, Launchelot:ListView, ToonView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0) 
		return
	LV_GetText(curr_toon, curr_row, 1)
	LV_GetText(curr_account, curr_row, 2)
	LV_GetText(curr_class, curr_row, 3)
	LV_GetText(curr_server, curr_row, 4)
	LV_GetText(curr_realm, curr_row, 5)
	LV_GetText(curr_script, curr_row, 6)
	LV_GetText(curr_note, curr_row, 7)

	curr_ndx := FindValueIndex(curr_toon, "Toons", "toon")

	; Show the dialog
	ShowToonDialog("Edit Toon", curr_ndx, curr_row, curr_toon, curr_account, curr_class, curr_server, curr_realm, curr_script, curr_note)
}

EditAccount() {
	; Find the account currently selected
	Gui, Launchelot:Tab, 2
	Gui, Launchelot:ListView, AccountView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0) 
		return
	LV_GetText(curr_account, curr_row, 1)

	curr_ndx := FindValueIndex(curr_account, "Accounts", "account")

	CreateEditDialog("Edit Account", curr_ndx, curr_row, [["Account name", curr_account], ["Password", ""]])
}

EditTeam() {
	; Find the team currently selected
	Gui, Launchelot:Tab, 3
	Gui, Launchelot:ListView, TeamView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0)
		return
	LV_GetText(curr_team, curr_row, 1)
	LV_GetText(curr_script, curr_row, 2)
	curr_team_id := curr_script "," curr_team

	curr_ndx := FindValueIndex(curr_team_id, "Teams", "team")
	curr_toons := StrSplit(curr_team, ",")
	while curr_toons.length() < 8
	{
		curr_toons.push("")
	}

	CreateEditDialog("Edit Team", curr_ndx, curr_row, [["Script", curr_script], ["Toon 1", curr_toons[1]], ["Toon 2", curr_toons[2]], ["Toon 3", curr_toons[3]], ["Toon 4", curr_toons[4]], ["Toon 5", curr_toons[5]], ["Toon 6", curr_toons[6]], ["Toon 7", curr_toons[7]], ["Toon 8", curr_toons[8]]])
}

DeleteToon() {
	; Find the toon currently selected
	Gui, Launchelot:Tab, 1
	Gui, Launchelot:ListView, ToonView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0) 
		return
	LV_GetText(curr_toon, curr_row, 1)

	; Look for the index
	curr_ndx := FindValueIndex(curr_toon, "Toons", "toon")
	if (curr_ndx = 0)
		return

	; Ask for confirmation
	MsgBox, 8196, Warning, Are you sure you want to delete toon %curr_toon%?
	IfMsgBox Yes
	{
		IniDelete, %A_ScriptDir%\launchelot.ini, Toons, toon%curr_ndx%
		LV_Delete(curr_row)
	}
}

DeleteAccount() {
	; Find the toon currently selected
	Gui, Launchelot:Tab, 2
	Gui, Launchelot:ListView, AccountView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0) 
		return
	LV_GetText(curr_account, curr_row, 1)

	; Look for the index
	curr_ndx := FindValueIndex(curr_account, "Accounts", "account")
	if (curr_ndx = 0)
		return

	; Ask for confirmation
	MsgBox, 8196, Warning, Are you sure you want to delete account %curr_account%?
	IfMsgBox Yes
	{
		IniDelete, %A_ScriptDir%\launchelot.ini, Accounts, account%curr_ndx%
		LV_Delete(curr_row)
	}
}

DeleteTeam() {
	; Find the team currently selected
	Gui, Launchelot:Tab, 3
	Gui, Launchelot:ListView, TeamView
	curr_row := LV_GetNext(0, "F")
	if (curr_row = 0)
		return
	LV_GetText(curr_team, curr_row, 1)
	LV_GetText(curr_script, curr_row, 2)
	curr_team_id := curr_script "," curr_team
	
	curr_ndx := FindValueIndex(curr_team_id, "Teams", "team")
	if (curr_ndx = 0)
		return
	
	MsgBox, 8196, Warning, Are you sure you want to delete team %curr_team%?
	IfMsgBox Yes
	{
		IniDelete, %A_ScriptDir%\launchelot.ini, Teams, team%curr_ndx%
		LV_Delete(curr_row)
	}
}

GetToons() {
	toons := []
	IniRead num_toons, %A_ScriptDir%\launchelot.ini, Toons, max_index, 0
	Loop, %num_toons% {
		IniRead, toon_data, %A_ScriptDir%\launchelot.ini, Toons, toon%A_Index%, ERROR
		if (toon_data = "ERROR")
			continue
		toons.push(StrSplit(toon_data, ","))
	}
	return toons
}

GetTeams() {
	teams := []
	IniRead num_teams, %A_ScriptDir%\launchelot.ini, Teams, max_index, 0
	Loop, %num_teams% {
		IniRead, team_data, %A_ScriptDir%\launchelot.ini, Teams, team%A_Index%, ERROR
		if (team_data = "ERROR")
			continue
		teams.push(StrSplit(team_data, ","))
	}
	return teams
}

GetAccounts() {
	accounts := []
	IniRead num_accounts, %A_ScriptDir%\launchelot.ini, Accounts, max_index, 0
	Loop, %num_accounts% {
		IniRead, account_data, %A_ScriptDir%\launchelot.ini, Accounts, account%A_Index%, ERROR
		if (account_data ="ERROR")
			continue
		fields := StrSplit(account_data, ",")
		accounts[fields[1]] := fields
	}
	return accounts
}

HandleToonView() {
	if (A_GuiEvent = "DoubleClick") {

		; Retrieve the selected toon
		Gui, Launchelot:Tab, 1
		Gui, Launchelot:ListView, ToonView
		curr_row := LV_GetNext(0)
		if (curr_row = 0) 
			return
		LV_GetText(toon, curr_row, 1)

		; Launch the toon
		LaunchToon(toon)
	}
	else if (A_GuiEvent = "ColClick") {
		IniRead SortColumn, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_column, -1
		IniRead SortAscending, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_ascending, 1
		if (SortColumn = A_EventInfo) {
			SortAscending := not SortAscending
		}
		else {
			SortColumn := A_EventInfo
			SortAscending := true
		}
		IniWrite %SortColumn%, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_column
		IniWrite %SortAscending%, %A_ScriptDir%\launchelot.ini, Settings, toon_sort_ascending
	}
}

HandleAccountView() {
	if (A_GuiEvent = "ColClick") {
		IniRead SortColumn, %A_ScriptDir%\launchelot.ini, Settings, account_sort_column, -1
		IniRead SortAscending, %A_ScriptDir%\launchelot.ini, Settings, account_sort_ascending, 1
		if (SortColumn = A_EventInfo) {
			SortAscending := not SortAscending
		}
		else {
			SortColumn := A_EventInfo
			SortAscending := true
		}
		IniWrite %SortColumn%, %A_ScriptDir%\launchelot.ini, Settings, account_sort_column
		IniWrite %SortAscending%, %A_ScriptDir%\launchelot.ini, Settings, account_sort_ascending
	}
}

HandleTeamView() {
	if (A_GuiEvent = "DoubleClick") {

		; Retrieve the selected team
		Gui, Launchelot:Tab, 3
		Gui, Launchelot:ListView, TeamView
		curr_row := LV_GetNext(0, "F")
		if (curr_row = 0)
			return
		LV_GetText(curr_team, curr_row, 1)
		LV_GetText(curr_script, curr_row, 2)
		curr_team_id := curr_script "," curr_team
		curr_ndx := FindValueIndex(curr_team_id, "Teams", "team")
		curr_toons := StrSplit(curr_team, ",")

		; Launch the team
		LaunchTeam(curr_toons, curr_script)
	}
	else if (A_GuiEvent = "ColClick") {
		IniRead SortColumn, %A_ScriptDir%\launchelot.ini, Settings, team_sort_column, -1
		IniRead SortAscending, %A_ScriptDir%\launchelot.ini, Settings, team_sort_ascending, 1
		if (SortColumn = A_EventInfo) {
			SortAscending := not SortAscending
		}
		else {
			SortColumn := A_EventInfo
			SortAscending := true
		}
		IniWrite %SortColumn%, %A_ScriptDir%\launchelot.ini, Settings, team_sort_column
		IniWrite %SortAscending%, %A_ScriptDir%\launchelot.ini, Settings, team_sort_ascending
	}	
}

IsStandalone() {
	return A_IsCompiled || A_LineFile == A_ScriptFullPath
}

; --------------------------------------------------------------------------
; Launchelot GUI events
; --------------------------------------------------------------------------
LaunchelotGuiSize() {
	; Has the window been minimized? If so, no action needed.
	if ErrorLevel = 1
	    return

    ; Get the new width
	NewWidth := A_GuiWidth - 20
	NewHeight := A_GuiHeight - 20

	; Resize the controls
	GuiControl, Move, LaunchTab, % "w" NewWidth "h" NewHeight
	GuiControl, Move, ToonView, % "w" NewWidth - 24 "h" NewHeight - 68
	GuiControl, Move, AccountView, % "w" NewWidth - 24 "h" NewHeight - 68
	GuiControl, Move, TeamView, % "w" NewWidth - 24 "h" NewHeight - 68
}

LaunchelotGuiClose() {
	; Destroy the window if it already exists
	Gui, Launchelot:Destroy

	; Close the script if this is a standalone
	if (IsStandalone()) {
		ExitApp
	}
}

; --------------------------------------------------------------------------
; Utility functions
; --------------------------------------------------------------------------

StrPutVar(string, ByRef var, encoding) {
    ; Ensure capacity
    VarSetCapacity( var, StrPut(string, encoding)
        ; StrPut returns char count, but VarSetCapacity needs bytes.
        * ((encoding="utf-16"||encoding="cp1200") ? 2 : 1) )
    ; Copy or convert the string.
    return StrPut(string, &var, encoding)
}

Base64encUTF8(ByRef OutData, ByRef InData) {
	TChars := ""
	; by SKAN + my modifications to encode to UTF-8
  	InDataLen := StrPutVar(InData, InData, "UTF-8") - 1
  	DllCall( "Crypt32.dll\CryptBinaryToStringW", UInt,&InData, UInt,InDataLen, UInt,1, UInt,0, UIntP,TChars, "CDECL Int" )
  	VarSetCapacity( OutData, Req := TChars * ( A_IsUnicode ? 2 : 1 ), 0 )
  	DllCall( "Crypt32.dll\CryptBinaryToStringW", UInt,&InData, UInt,InDataLen, UInt,1, Str,OutData, UIntP,Req, "CDECL Int" )
  	Return TChars
}

Base64decUTF8(ByRef OutData, ByRef InData) {
	Bytes := ""
	; by SKAN + my modifications to decode base64 whose text was encoded to utf-8 beforehand
  	DllCall( "Crypt32.dll\CryptStringToBinaryW", UInt,&InData, UInt,StrLen(InData), UInt,1, UInt,0, UIntP,Bytes, Int,0, Int,0, "CDECL Int" )
  	VarSetCapacity( OutData, Req := Bytes * ( A_IsUnicode ? 2 : 1 ), 0 )
  	DllCall( "Crypt32.dll\CryptStringToBinaryW", UInt,&InData, UInt,StrLen(InData), UInt,1, Str,OutData, UIntP,Req, Int,0, Int,0, "CDECL Int" )
  	OutData := StrGet(&OutData, "cp0")
  	Return Bytes
}

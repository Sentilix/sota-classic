--[[
--	SotA - State of the Art DKP Addon
--	By Mimma <EU-Pyrewood Village>
--
--	Unit: sota-options.lua
--	This holds the options (configuration) dialogue of SotA plus
--	underlying functionality to support changing the options.
--]]

local SOTA_MAX_MESSAGES			= 15
local ConfigurationDialogOpen	= false;



function SOTA_EchoEvent(msgKey, item, dkp, bidder, rank, param1, param2, param3)
	local msgInfo = SOTA_getConfigurableMessage(msgKey, item, dkp, bidder, rank, param1, param2, param3);
	publicEcho(msgInfo);
end;


function SOTA_GetEventText(eventName)
	local messages = SOTA_GetConfigurableTextMessages();

	for n = 1, table.getn(messages), 1 do
		if(messages[n][1] == eventName) then
			return messages[n];
		end;
	end

	return nil;
end;


--[[
--	Get configurable message and fill out placeholders:
--	Parameters:
--	%i: Item, %d: DKP, %b: Bidder, %r: Rank, $1,$2,$3: params (percent, players in range, players in queue etc)
--	Automatic gathered:
--	%m: Min DKP, %s: SotA master
--]]
function SOTA_getConfigurableMessage(msgKey, item, dkp, bidder, rank, param1, param2, param3)

	local msgInfo = SOTA_GetEventText(msgKey);

	if(not msgInfo) then
		localEcho("*** Oops, SOTA_CONFIG_Messages[".. msgKey .."] was not found");
		return nil;
	end;

	if not(item)	then item = ""; end;
	if not(dkp)		then dkp = ""; end;
	if not(bidder)	then bidder = ""; end;
	if not(rank)	then rank = ""; end;
	if not(param1)	then param1 = ""; end;
	if not(param2)	then param2 = ""; end;
	if not(param3)	then param3 = ""; end;

	local msg = msgInfo[3];
	msg = string.gsub(msg, "$i", ""..item);
	msg = string.gsub(msg, "$d", ""..dkp);
	msg = string.gsub(msg, "$b", ""..bidder);
	msg = string.gsub(msg, "$r", ""..rank);
	msg = string.gsub(msg, "$m", ""..SOTA_GetMinimumBid());
	msg = string.gsub(msg, "$s", UnitName("player"));
	msg = string.gsub(msg, "$1", ""..param1);
	msg = string.gsub(msg, "$2", ""..param2);
	msg = string.gsub(msg, "$3", ""..param3);
	
	return { msgInfo[1], msgInfo[2], msg };
end;

function SOTA_SetConfigurableMessage(event, channel, message)
	--echo("Saving new message: Event: "..event..", Channel: "..channel..", Message: "..message);
	local messages = SOTA_GetConfigurableTextMessages();

	for n=1,table.getn(messages),1 do
		if(messages[n][1] == event) then
			messages[n] = { event, channel, message };
			SOTA_SetConfigurableTextMessages(messages);
			return;
		end;
	end;
end;

--[[
--	Copy the updated frame pos to frame siblings.
--	Since: 1.2.0
--]]
function SOTA_UpdateFramePos(frame)
	local framename = frame:GetName();

	if(framename ~= "FrameConfigBidding") then
		FrameConfigBidding:SetAllPoints(frame);
	end
	if(framename ~= "FrameConfigBossDkp") then
		FrameConfigBossDkp:SetAllPoints(frame);
	end
	if(framename ~= "FrameConfigMiscDkp") then
		FrameConfigMiscDkp:SetAllPoints(frame);
	end
	if(framename ~= "FrameConfigMessage") then
		FrameConfigMessage:SetAllPoints(frame);
	end
end;


function SOTA_OpenConfigurationUI()
	ConfigurationDialogOpen = true;
	SOTA_RefreshBossDKPValues();

	SOTA_OpenBiddingConfig();
end

function SOTA_CloseConfigurationUI()
	SOTA_CloseAllConfig();

	ConfigurationDialogOpen = false;
end

function SOTA_CloseAllConfig()
	FrameConfigBidding:Hide();
	FrameConfigBossDkp:Hide();
	FrameConfigMiscDkp:Hide();
	FrameConfigMessage:Hide();
end;

function SOTA_ToggleConfigurationUI()
	if ConfigurationDialogOpen then
		SOTA_CloseConfigurationUI();
	else
		SOTA_OpenConfigurationUI();
	end;
end;

function SOTA_OpenBiddingConfig()
	SOTA_CloseAllConfig();
	FrameConfigBidding:Show();
end

function SOTA_OpenBossDkpConfig()
	SOTA_CloseAllConfig();
	FrameConfigBossDkp:Show();
end

function SOTA_OpenMiscDkpConfig()
	SOTA_CloseAllConfig();
	FrameConfigMiscDkp:Show();
end

function SOTA_OpenMessageConfig()
	SOTA_CloseAllConfig();
	FrameConfigMessage:Show();
end

function SOTA_OpenClipboard()
	local n, msg, ginfo;

	local roster = SOTA_GetGuildRosterTable();
	if not roster then
		return;
	end;

	local backdrop = {
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/GLUES/Common/Glue-Tooltip-Border",
		tile = true,
		edgeSize = 8,
		tileSize = 8,
		insets = {
			left = 5,
			right = 5,
			top = 5,
			bottom = 5,
		},
	};

	local frame = CreateFrame("Frame", "MyScrollMessageTextFrame", UIParent)
	frame:SetSize(300, 250)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("BACKGROUND")
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(0, 0, 0)
	frame.Close = CreateFrame("Button", "$parentClose", frame)
	frame.Close:SetSize(24, 24)
	frame.Close:SetPoint("TOPRIGHT")
	frame.Close:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
	frame.Close:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
	frame.Close:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight", "ADD")
	frame.Close:SetScript("OnClick", function(self)
		self:GetParent():Hide()
	end);
	frame.Select = CreateFrame("Button", "$parentSelect", frame, "UIPanelButtonTemplate")
	frame.Select:SetSize(64, 14)
	frame.Select:SetPoint("RIGHT", frame.Close, "LEFT")
	frame.Select:SetText("Mark All")
	frame.Select:SetScript("OnClick", function(self)
		self:GetParent().Text:HighlightText() -- parameters (start, end) or default all
		self:GetParent().Text:SetFocus()
	end)

	frame.SF = CreateFrame("ScrollFrame", "$parent_DF", frame, "UIPanelScrollFrameTemplate")
	frame.SF:SetPoint("TOPLEFT", frame, 12, -30)
	frame.SF:SetPoint("BOTTOMRIGHT", frame, -30, 10)
	frame.Text = CreateFrame("EditBox", nil, frame)
	frame.Text:SetMultiLine(true)
	frame.Text:SetSize(280, 220)
	frame.Text:SetPoint("TOPLEFT", frame.SF)
	frame.Text:SetPoint("BOTTOMRIGHT", frame.SF)
	frame.Text:SetMaxLetters(99999)
	frame.Text:SetFontObject(GameFontNormal)
	frame.Text:SetAutoFocus(false)
	frame.Text:SetScript("OnEscapePressed", function(self) self:ClearFocus() end) 
	frame.SF:SetScrollChild(frame.Text)


	-- { Name, DKP, Class, Rank(text), Online, Zone, Rank(value) }
	for n=1,table.getn(roster),1 do
		ginfo = roster[n];
		msg = string.format("%s,%d,%s,%s\r\n", ginfo[1], ginfo[2], ginfo[3], ginfo[4]);
		frame.Text:Insert(msg);
	end;
end;

--function SOTA_OpenBidRulesConfig()
--	SOTA_SetBidRules();
--	SOTA_CloseAllConfig();
--	FrameConfigBidRules:Show();
--end;

--function SOTA_OpenSyncCfgConfig()
--	SOTA_CloseAllConfig();
--	SOTA_RequestUpdateConfigVersion();
--	FrameConfigSyncCfg:Show();
--end;

function SOTA_OnOptionAuctionTimeChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	SOTA_CONFIG_AuctionTime = value;
	
	local valueString = "".. SOTA_CONFIG_AuctionTime;
	if SOTA_CONFIG_AuctionTime == 0 then
		valueString = "(No timer)";
	end
	
	_G[object:GetName().."Text"]:SetText(string.format("Auction Time: %s seconds", valueString))
end

function SOTA_OnOptionAuctionExtensionChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	SOTA_CONFIG_AuctionExtension = value;
	
	local valueString = "".. SOTA_CONFIG_AuctionExtension;
	if SOTA_CONFIG_AuctionExtension == 0 then
		valueString = "(No extension)";
	end
		
	_G[object:GetName().."Text"]:SetText(string.format("Auction Extension: %s seconds", valueString))
end

function SOTA_OnOptionDKPStringLengthChanged(object)
	local value = math.floor(object:GetValue());
	object:SetValueStep(1);
	object:SetValue(value);

	SOTA_CONFIG_DKPStringLength = value;
	
	local valueString = "".. SOTA_CONFIG_DKPStringLength;
	if SOTA_CONFIG_DKPStringLength == 0 then
		valueString = "(No limit)";
	end
		
	_G[object:GetName().."Text"]:SetText(string.format("DKP String Length: %s", valueString))
end


function SOTA_OnOptionMinimumDKPPenaltyChanged(object)
	local valueStep = 25;
	local value = valueStep * math.floor(object:GetValue() / valueStep);
	object:SetValueStep(valueStep);
	object:SetValue(value);

	SOTA_CONFIG_MinimumDKPPenalty = value;
	
	local valueString = "".. SOTA_CONFIG_MinimumDKPPenalty;
	if SOTA_CONFIG_MinimumDKPPenalty == 0 then
		valueString = "(None)";
	end
	
	_G[object:GetName().."Text"]:SetText(string.format("Minimum DKP penalty: %s", valueString))
end

function SOTA_RefreshBossDKPValues()
	_G["FrameConfigBossDkp_20Mans"]:SetValue(SOTA_GetBossDKPValue("20Mans"));
	_G["FrameConfigBossDkp_MoltenCore"]:SetValue(SOTA_GetBossDKPValue("MoltenCore"));
	_G["FrameConfigBossDkp_Onyxia"]:SetValue(SOTA_GetBossDKPValue("Onyxia"));
	_G["FrameConfigBossDkp_BlackwingLair"]:SetValue(SOTA_GetBossDKPValue("BlackwingLair"));
	_G["FrameConfigBossDkp_AQ40"]:SetValue(SOTA_GetBossDKPValue("AQ40"));
	_G["FrameConfigBossDkp_Naxxramas"]:SetValue(SOTA_GetBossDKPValue("Naxxramas"));
	_G["FrameConfigBossDkp_WorldBosses"]:SetValue(SOTA_GetBossDKPValue("WorldBosses"));
end

function SOTA_OnOptionBossDKPChanged(object)

	-- Since WOW 5.4 the slider API has been broken. We can circumvent this by setting and calculating the valueStep here:
	local valueStep = 100;
	local value = valueStep * math.floor(object:GetValue() / valueStep);
	local slider = object:GetName();
	object:SetValueStep(valueStep);
	object:SetValue(value);

	local valueString = "";	
	if slider == "FrameConfigBossDkp_20Mans" then
		SOTA_SetBossDKPValue("20Mans", value);
		valueString = string.format("20 mans (ZG, AQ20): %d DKP", value);
	elseif slider == "FrameConfigBossDkp_MoltenCore" then
		SOTA_SetBossDKPValue("MoltenCore", value);
		valueString = string.format("Molten Core: %d DKP", value);
	elseif slider == "FrameConfigBossDkp_Onyxia" then
		SOTA_SetBossDKPValue("Onyxia", value);
		valueString = string.format("Onyxia: %d DKP", value);
	elseif slider == "FrameConfigBossDkp_BlackwingLair" then
		SOTA_SetBossDKPValue("BlackwingLair", value);
		valueString = string.format("Blackwing Lair: %d DKP", value);
	elseif slider == "FrameConfigBossDkp_AQ40" then
		SOTA_SetBossDKPValue("AQ40", value);
		valueString = string.format("Temple of Ahn'Qiraj: %d DKP", value);
	elseif slider == "FrameConfigBossDkp_Naxxramas" then
		SOTA_SetBossDKPValue("Naxxramas", value);
		valueString = string.format("Naxxramas: %d DKP", value);
	elseif slider == "FrameConfigBossDkp_WorldBosses" then
		SOTA_SetBossDKPValue("WorldBosses", value);
		valueString = string.format("World Bosses: %d DKP", value);
	end

	_G[slider.."Text"]:SetText(valueString);
end

function SOTA_InitializeConfigSettings()
    if not SOTA_CONFIG_UseGuildNotes then
		SOTA_CONFIG_UseGuildNotes = 0;
    end
    if not SOTA_CONFIG_MinimumBidStrategy then
		SOTA_CONFIG_MinimumBidStrategy = 0;
    end
	if not SOTA_CONFIG_DKPStringLength then
		SOTA_CONFIG_DKPStringLength = 5;
	end
	if not SOTA_CONFIG_MinimumDKPPenalty then
		SOTA_CONFIG_MinimumDKPPenalty = 50;
	end

	-- Update GUI:
	if not SOTA_CONFIG_EnableOSBidding then
		SOTA_CONFIG_EnableOSBidding = 1;
	end
	if not SOTA_CONFIG_EnableZoneCheck then
		SOTA_CONFIG_EnableZoneCheck = 1;
	end
	if not SOTA_CONFIG_EnableOnlineCheck then
		SOTA_CONFIG_EnableOnlineCheck = 1;
	end
	if not SOTA_CONFIG_AllowPlayerPass then
		SOTA_CONFIG_AllowPlayerPass = 1;
	end;
	if not SOTA_CONFIG_DisableDashboard then
		SOTA_CONFIG_DisableDashboard = 1;
	end
	if not SOTA_CONFIG_OutputChannel then
		SOTA_CONFIG_OutputChannel = WARN_CHANNEL;
	end
	if not SOTA_HISTORY_DKP then
		SOTA_HISTORY_DKP = { };
	end


	if SOTA_CONFIG_EnableOSBidding == 1 then
		_G["FrameConfigBiddingMSoverOSPriority"]:SetChecked(1);
	else
		_G["FrameConfigBiddingMSoverOSPriority"]:SetChecked();
	end;

	if SOTA_CONFIG_EnableZoneCheck == 1 then
		_G["FrameConfigBiddingEnableZonecheck"]:SetChecked(1);
	else
		_G["FrameConfigBiddingEnableZonecheck"]:SetChecked();
	end;

	if SOTA_CONFIG_EnableOnlineCheck == 1 then
		_G["FrameConfigBiddingEnableOnlinecheck"]:SetChecked(1);
	else
		_G["FrameConfigBiddingEnableOnlinecheck"]:SetChecked();
	end;

	if SOTA_CONFIG_AllowPlayerPass == 1 then
		_G["FrameConfigBiddingAllowPlayerPass"]:SetChecked(1);
	else
		_G["FrameConfigBiddingAllowPlayerPass"]:SetChecked();
	end;

	if SOTA_CONFIG_DisableDashboard == 1 then
		_G["FrameConfigBiddingDisableDashboard"]:SetChecked(1);
	else
		_G["FrameConfigBiddingDisableDashboard"]:SetChecked();
	end;

	if SOTA_CONFIG_UseGuildNotes == 1 then
		_G["FrameConfigMiscDkpPublicNotes"]:SetChecked(1)
	end

	_G["FrameConfigMiscDkpMinBidStrategy".. SOTA_CONFIG_MinimumBidStrategy]:SetChecked(1)
	_G["FrameConfigMiscDkpDKPStringLength"]:SetValue(SOTA_CONFIG_DKPStringLength);
	_G["FrameConfigMiscDkpMinimumDKPPenalty"]:SetValue(SOTA_CONFIG_MinimumDKPPenalty);
	_G["FrameConfigBiddingAuctionTime"]:SetValue(SOTA_CONFIG_AuctionTime);
	_G["FrameConfigBiddingAuctionExtension"]:SetValue(SOTA_CONFIG_AuctionExtension);
	
	SOTA_RefreshBossDKPValues();

	SOTA_VerifyEventMessages();
end


function SOTA_VerifyEventMessages()

	-- Syntax: [index] = { EVENT_NAME, CHANNEL, TEXT }
	-- Channel value: 0: Off, 1: RW, 2: Raid, 3: Guild, 4: Yell, 5: Say
	local defaultMessages = { 
		{ SOTA_MSG_OnOpen			, 1, "Auction open for $i" },
		{ SOTA_MSG_OnAnnounceBid	, 2, "/w $s bid <your bid>" },
		{ SOTA_MSG_OnAnnounceMinBid	, 2, "Minimum bid: $m DKP" },
		{ SOTA_MSG_On10SecondsLeft	, 2, "10 seconds left for $i" },
		{ SOTA_MSG_On9SecondsLeft	, 2, "9 seconds left" },
		{ SOTA_MSG_On8SecondsLeft	, 0, "8 seconds left" },
		{ SOTA_MSG_On7SecondsLeft	, 0, "7 seconds left" },
		{ SOTA_MSG_On6SecondsLeft	, 0, "6 seconds left" },
		{ SOTA_MSG_On5SecondsLeft	, 0, "5 seconds left" },
		{ SOTA_MSG_On4SecondsLeft	, 0, "4 seconds left" },
		{ SOTA_MSG_On3SecondsLeft	, 2, "3 seconds left" },
		{ SOTA_MSG_On2SecondsLeft	, 2, "2 seconds left" },
		{ SOTA_MSG_On1SecondLeft	, 2, "1 second left" },
		{ SOTA_MSG_OnMainspecBid	, 1, "$b ($r) is bidding $d DKP for $i" },
		{ SOTA_MSG_OnOffspecBid		, 1, "$b is bidding $d Off-spec for $i" },
		{ SOTA_MSG_OnMainspecMaxBid	, 1, "$b ($r) went all in ($d DKP) for $i" },
		{ SOTA_MSG_OnOffspecMaxBid	, 1, "$b went all in ($d) Off-spec for $i" },
		{ SOTA_MSG_OnComplete		, 2, "$i sold to $b for $d DKP." },
		{ SOTA_MSG_OnPause			, 2, "Auction has been Paused" },
		{ SOTA_MSG_OnResume			, 2, "Auction has been Resumed" },
		{ SOTA_MSG_OnClose			, 1, "Auction for $i is over" },
		{ SOTA_MSG_OnCancel			, 1, "Auction was Cancelled" },
		{ SOTA_MSG_OnDKPAdded		, 1, "$d DKP was added to $b" },
		{ SOTA_MSG_OnDKPAddedRaid	, 1, "$d DKP was added to all players in raid" },
		{ SOTA_MSG_OnDKPAddedRange	, 1, "$d DKP has been added for $1 players in range." },
		{ SOTA_MSG_OnDKPAddedQueue	, 1, "$d DKP has been added for $1 players in range (incl $2 in queue)." },
		{ SOTA_MSG_OnDKPSubtract	, 1, "$d DKP was subtracted from $b" },
		{ SOTA_MSG_OnDKPSubtractRaid, 1, "$d DKP was subtracted from all players in raid" },
		{ SOTA_MSG_OnDKPPercent		, 1, "$1 % ($d DKP) was subtracted from $b" },
		{ SOTA_MSG_OnDKPShared		, 1, "$1 DKP was shared ($d DKP per player)" },
		{ SOTA_MSG_OnDKPSharedQueue , 1, "$1 DKP was shared ($d DKP per player plus $2 in queue)" },
		{ SOTA_MSG_OnDKPSharedRange , 1, "$1 DKP was shared for $2 players in range ($d DKP per player)" },
		{ SOTA_MSG_OnDKPSharedRangeQ, 1, "$1 DKP was shared for $2 players in range ($d DKP per player, incl $3 in queue)" },
		{ SOTA_MSG_OnDKPReplaced	, 1, "$1 was replaced with $2 ($d DKP)" }
	}

	-- Merge default messages into saved messages; in case we added some new event names.
	local messages = SOTA_GetConfigurableTextMessages();
	if not messages or table.getn(messages) == 0 then
		SOTA_SetConfigurableTextMessages(defaultMessages);
		return;
	end;

	--echo("--- Merging messages");
	for n=1,table.getn(defaultMessages), 1 do
		local foundMessage = false;
		for f=1,table.getn(messages), 1 do
			if(messages[f][1] == defaultMessages[n][1]) then
				foundMessage = true;
--				echo("Found msg: ".. messages[f][1]);
				break;
			end;
		end;

		if(not foundMessage) then
--			echo("Adding message: ".. defaultMessages[n][1]);
			messages[table.getn(messages)+1] = defaultMessages[n];
		end;
	end

	SOTA_SetConfigurableTextMessages(messages);
end;


function SOTA_HandleCheckbox(checkbox)
	local checkboxname = checkbox:GetName();

	--	Enable MS>OS priority:		
	if checkboxname == "FrameConfigBiddingMSoverOSPriority" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_EnableOSBidding = 1;
		else
			SOTA_CONFIG_EnableOSBidding = 0;
		end
		return;
	end
		
	--	Enable RQ Zonecheck:		
	if checkboxname == "FrameConfigBiddingEnableZonecheck" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_EnableZoneCheck = 1;
		else
			SOTA_CONFIG_EnableZoneCheck = 0;
		end
		return;
	end

	--	Enable RQ Onlinecheck:		
	if checkboxname == "FrameConfigBiddingEnableOnlinecheck" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_EnableOnlineCheck = 1;
		else
			SOTA_CONFIG_EnableOnlineCheck = 0;
		end
		return;
	end

	--	Allow Player Pass:
	if checkboxname == "FrameConfigBiddingAllowPlayerPass" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_AllowPlayerPass = 1;
		else
			SOTA_CONFIG_AllowPlayerPass = 0;
		end
		return;
	end

	--	Disable Dashboard:		
	if checkboxname == "FrameConfigBiddingDisableDashboard" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_DisableDashboard = 1;
			SOTA_CloseDashboard();
		else
			SOTA_CONFIG_DisableDashboard = 0;
		end
		return;
	end

	
	--	Store DKP in Public Notes:		
	if checkboxname == "FrameConfigMiscDkpPublicNotes" then
		if checkbox:GetChecked() then
			SOTA_CONFIG_UseGuildNotes = 1;
		else
			SOTA_CONFIG_UseGuildNotes = 0;
		end
		return;
	end
	
	if checkbox:GetChecked() then		
		--	Bid type:
		--	If checked, then we need to uncheck others in same group:
		if checkboxname == "FrameConfigMiscDkpMinBidStrategy0" then
			_G["FrameConfigMiscDkpMinBidStrategy1"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy2"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy3"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy4"]:SetChecked();
			SOTA_CONFIG_MinimumBidStrategy = 0;
		elseif checkboxname == "FrameConfigMiscDkpMinBidStrategy1" then
			_G["FrameConfigMiscDkpMinBidStrategy0"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy2"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy3"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy4"]:SetChecked();
			SOTA_CONFIG_MinimumBidStrategy = 1;
		elseif checkboxname == "FrameConfigMiscDkpMinBidStrategy2" then
			_G["FrameConfigMiscDkpMinBidStrategy0"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy1"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy3"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy4"]:SetChecked();
			SOTA_CONFIG_MinimumBidStrategy = 2;
		elseif checkboxname == "FrameConfigMiscDkpMinBidStrategy3" then
			_G["FrameConfigMiscDkpMinBidStrategy0"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy1"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy2"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy4"]:SetChecked();
			SOTA_CONFIG_MinimumBidStrategy = 3;			
		elseif checkboxname == "FrameConfigMiscDkpMinBidStrategy4" then
			_G["FrameConfigMiscDkpMinBidStrategy0"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy1"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy2"]:SetChecked();
			_G["FrameConfigMiscDkpMinBidStrategy3"]:SetChecked();
			SOTA_CONFIG_MinimumBidStrategy = 4;
		end
	end
end


local currentEvent;
function SOTA_OnEventMessageClick(object)	
	local event = _G[object:GetName().."Event"]:GetText();
	local channel = 1 * _G[object:GetName().."Channel"]:GetText();
	local message = _G[object:GetName().."Message"]:GetText();

	currentEvent = event;

	if not message then
		message = "";
	end

--	echo("** Event: "..event..", Channel: "..channel..", Message: "..message);

	local frame = _G["FrameEventEditor"];
	_G[frame:GetName().."Message"]:SetText(message);

	_G[frame:GetName().."CheckbuttonRW"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonRaid"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonYell"]:SetChecked();		
	_G[frame:GetName().."CheckbuttonSay"]:SetChecked();		

	if channel == 1 then
		_G[frame:GetName().."CheckbuttonRW"]:SetChecked(1);		
	elseif channel == 2 then
		_G[frame:GetName().."CheckbuttonRaid"]:SetChecked(1);		
	elseif channel == 3 then
		_G[frame:GetName().."CheckbuttonGuild"]:SetChecked(1);		
	elseif channel == 4 then
		_G[frame:GetName().."CheckbuttonYell"]:SetChecked(1);		
	elseif channel == 5 then
		_G[frame:GetName().."CheckbuttonSay"]:SetChecked(1);		
	end
	-- Yes, channel can be disabled (0) = nothing is written.
	
	FrameEventEditor:Show();
	FrameEventEditorMessage:SetFocus();
end

function SOTA_OnEventCheckboxClick(checkbox)
	local checkboxname = checkbox:GetName();
	local frame = _G["FrameEventEditor"];

	if checkboxname == "FrameEventEditorCheckbuttonRW" then
		if checkbox:GetChecked() then
			_G[frame:GetName().."CheckbuttonRaid"]:SetChecked();
			_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();
			_G[frame:GetName().."CheckbuttonYell"]:SetChecked();
			_G[frame:GetName().."CheckbuttonSay"]:SetChecked();
		end;
	elseif checkboxname == "FrameEventEditorCheckbuttonRaid" then
		if checkbox:GetChecked() then
			_G[frame:GetName().."CheckbuttonRW"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonYell"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonSay"]:SetChecked();		
		end;
	elseif checkboxname == "FrameEventEditorCheckbuttonGuild" then
		if checkbox:GetChecked() then
			_G[frame:GetName().."CheckbuttonRW"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonRaid"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonYell"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonSay"]:SetChecked();		
		end;
	elseif checkboxname == "FrameEventEditorCheckbuttonYell" then
		if checkbox:GetChecked() then
			_G[frame:GetName().."CheckbuttonRW"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonRaid"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonSay"]:SetChecked();		
		end;
	elseif checkboxname == "FrameEventEditorCheckbuttonSay" then
		if checkbox:GetChecked() then
			_G[frame:GetName().."CheckbuttonRW"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonRaid"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonGuild"]:SetChecked();		
			_G[frame:GetName().."CheckbuttonYell"]:SetChecked();		
		end;
	end;
end;

function SOTA_OnEventEditorSave()
	local event = currentEvent;
	local message = FrameEventEditorMessage:GetText();
	local channel = 0;

	local frame = _G["FrameEventEditor"];
	
	if _G[frame:GetName().."CheckbuttonRW"]:GetChecked() then
		channel = 1
	elseif _G[frame:GetName().."CheckbuttonRaid"]:GetChecked() then
		channel = 2
	elseif _G[frame:GetName().."CheckbuttonGuild"]:GetChecked() then
		channel = 3
	elseif _G[frame:GetName().."CheckbuttonYell"]:GetChecked() then
		channel = 4
	elseif _G[frame:GetName().."CheckbuttonSay"]:GetChecked() then
		channel = 5
	end;

	SOTA_SetConfigurableMessage(event, channel, message);

	SOTA_UpdateTextList();

	FrameEventEditor:Hide();
end;

function SOTA_OnEventEditorClose()
	FrameEventEditor:Hide();
end;

function SOTA_RefreshVisibleTextList(offset)
	--echo(string.format("Offset=%d", offset));
	local messages = SOTA_GetConfigurableTextMessages();
	local msgInfo;

	for n=1, SOTA_MAX_MESSAGES, 1 do
		msgInfo = messages[n + offset]
		if not msgInfo then
			msgInfo = { "", 0, "" }
		end
		
		local event = msgInfo[1];
		local channel = msgInfo[2];
		local message = msgInfo[3];
		
		--echo(string.format("-> Event=%s, Channel=%d, Text=%s", event, 1*channel, message));
		
		local frame = _G["FrameConfigMessageTableListEntry"..n];
		if(not frame) then
			echo("*** Oops, frame is nil");
			return;
		end;

		_G[frame:GetName().."Event"]:SetText(event);
		_G[frame:GetName().."Channel"]:SetText(channel);
		_G[frame:GetName().."Message"]:SetText(message);
		
		frame:Show();
	end
end

function SOTA_UpdateTextList(frame)
--	FauxScrollFrame_Update(FrameConfigMessageTableList, SOTA_MAX_MESSAGES, 10, 20);
	local messages = SOTA_GetConfigurableTextMessages();

	SOTA_VerifyEventMessages();

	FauxScrollFrame_Update(FrameConfigMessageTableList, table.getn(messages), SOTA_MAX_MESSAGES, 20);
	local offset = FauxScrollFrame_GetOffset(FrameConfigMessageTableList);
	
	SOTA_RefreshVisibleTextList(offset);
end

function SOTA_InitializeTextElements()
	local entry = CreateFrame("Button", "$parentEntry1", FrameConfigMessageTableList, "SOTA_TextTemplate");
	entry:SetID(1);
	entry:SetPoint("TOPLEFT", 4, -4);
	for n=2, SOTA_MAX_MESSAGES, 1 do
		local entry = CreateFrame("Button", "$parentEntry"..n, FrameConfigMessageTableList, "SOTA_TextTemplate");
		entry:SetID(n);
		entry:SetPoint("TOP", "$parentEntry"..(n-1), "BOTTOM");
	end
end


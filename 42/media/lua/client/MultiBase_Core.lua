----------------------------------------------------------------
-----  ▄▄▄   ▄    ▄   ▄  ▄▄▄▄▄   ▄▄▄   ▄   ▄   ▄▄▄    ▄▄▄  -----
----- █   ▀  █    █▄▄▄█    █    █   ▀  █▄▄▄█  ▀  ▄█  █ ▄▄▀ -----
----- █  ▀█  █      █      █    █   ▄  █   █  ▄   █  █   █ -----
-----  ▀▀▀▀  ▀▀▀▀   ▀      ▀     ▀▀▀   ▀   ▀   ▀▀▀   ▀   ▀ -----
----------------------------------------------------------------
--                                                            --
--   Project Zomboid Modding Commissions                      --
--   https://steamcommunity.com/id/glytch3r/myworkshopfiles   --
--                                                            --
--   ▫ Support  ꞉   https://ko-fi.com/glytch3r                --
--   ▫ Youtube  ꞉   https://www.youtube.com/@glytch3r         --
--   ▫ Github   ꞉   https://github.com/Glytch3r               --
--                                                            --
----------------------------------------------------------------
----- ▄   ▄   ▄▄▄   ▄   ▄   ▄▄▄     ▄      ▄   ▄▄▄▄  ▄▄▄▄  -----
----- █   █  █   ▀  █   █  ▀   █    █      █      █  █▄  █ -----
----- ▄▀▀ █  █▀  ▄  █▀▀▀█  ▄   █    █    █▀▀▀█    █  ▄   █ -----
-----  ▀▀▀    ▀▀▀   ▀   ▀   ▀▀▀   ▀▀▀▀▀  ▀   ▀    ▀   ▀▀▀  -----
----------------------------------------------------------------

MultiBase = MultiBase or {}


function MultiBase.getClickedSquare()
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars then return ISWorldObjectContextMenu.fetchVars.clickedSquare end
    return clickedSquare
end

function MultiBase.context(player, context, worldobjects, test)
    local pl = getSpecificPlayer(player)
    local sq = MultiBase.getClickedSquare()

    local hq = SafeHouse.getSafeHouse(sq)
    if not hq and sq:getBuilding() and sq:getBuilding():getDef() then



		local reason = SafeHouse.canBeSafehouse(sq, pl)
		if reason == "" then return end


		local toolTip = ISWorldObjectContextMenu.addToolTip()
		local cap = getText("ContextMenu_SafehouseClaim")
		context:removeOptionByName(cap)
		local option = context:addOptionOnTop(cap, worldobjects, function() MultiBase.onTakeSafeHouse(sq, pl) end)

		toolTip.description = reason
		if reason and not luautils.stringStarts(reason, getText("IGUI_Safehouse_AlreadyHaveSafehouse")) or MultiBase.isLimitRestricted(pl) then

			option.notAvailable = true
		else
			toolTip.description = "Multi Claim"
		end
		if MultiBase.isLimitRestricted(pl) then toolTip.description = "Limit Reached" end

		option.toolTip = toolTip
    end
end

Events.OnFillWorldObjectContextMenu.Remove(MultiBase.context)
Events.OnFillWorldObjectContextMenu.Add(MultiBase.context)




function MultiBase.onTakeSafeHouse(sq, pl)
	local limit = tonumber(SandboxVars.MultiBase.Limit) or 0
	if limit > 0 and MultiBase.getCount(pl) >= limit then
		pl:setHaloNote("Territory Limit Reached", 250, 40, 40, 900)
		return
	end
	local defaultTitle = "Safehouse " .. tostring(SafeHouse.getSafehouseList():size() + 1)
	local modal = ISTextBox:new(getCore():getScreenWidth() / 2 - 140, getCore():getScreenHeight() / 2 - 90, 280, 180, "Safehouse Title", defaultTitle, nil, MultiBase.onSafehouseTitle)
	modal.claimSquare = sq
	modal.claimPlayer = pl
	modal:initialise()
	modal:addToUIManager()
	modal.moveWithMouse = true
	--hq:setTitle(tostring(MultiBase.getCount(pl)));
end

function MultiBase.onSafehouseTitle(button)
	if button.internal ~= "OK" then return end
	local title = button.parent.entry:getText()
	if not title or title:gsub("%s+", "") == "" then return end
	for i = 0, SafeHouse.getSafehouseList():size() - 1 do
		if tostring(SafeHouse.getSafehouseList():get(i):getTitle()) == title then
			button.parent.claimPlayer:setHaloNote("Safehouse Title Already Exists", 250, 40, 40, 900)
			return
		end
	end
	sendSafehouseClaim(button.parent.claimSquare, button.parent.claimPlayer, title)
end





function MultiBase.getPlayerSafehouses(pl)
    local safehouses = {}
    local user = pl:getUsername()
    for i = 0, SafeHouse.getSafehouseList():size() - 1 do
        local safehouse = SafeHouse.getSafehouseList():get(i)
        if safehouse:isOwner(pl) or safehouse:getPlayers():contains(user) then
            table.insert(safehouses, safehouse)
        end
    end
    return safehouses
end

function MultiBase.openSafehouse(safehouse, pl)
    local width = 500 + getCore():getOptionFontSizeReal() * 30
    local safehouseUI = ISSafehouseUI:new((getCore():getScreenWidth() - width) / 2, getCore():getScreenHeight() / 2 - 225, width, 450, safehouse, pl)
    safehouseUI:initialise()
    safehouseUI:addToUIManager()
end

function MultiBase.teleportToSafehouse(safehouse, pl)
    pl:teleportTo(safehouse:getX(), safehouse:getY(), 0)
    if isClient() then
        SendCommandToServer("/teleportto " .. tostring(safehouse:getX()) .. "," .. tostring(safehouse:getY()) .. ",0")
    else
        pl:teleportTo(safehouse:getX(), safehouse:getY(), 0)
    end
end

function MultiBase.OpenSH(player, context, worldobjects, test)
    local pl = getSpecificPlayer(player)
    local safehouses = MultiBase.getPlayerSafehouses(pl)
    if #safehouses == 0 then return end

    if SandboxVars.MultiBase.AccessAnywhere == false then
        local clicked = MultiBase.getClickedSquare()
        local clickedSafehouse = clicked and SafeHouse.getSafeHouse(clicked)
        local playerSafehouse = pl:getSquare() and SafeHouse.getSafeHouse(pl:getSquare())
        local isInsideOwnSafehouse = playerSafehouse and (playerSafehouse:isOwner(pl) or playerSafehouse:getPlayers():contains(pl:getUsername()))
        if not clickedSafehouse and not isInsideOwnSafehouse then return end
    end

    context:removeOptionByName(getText("ContextMenu_ViewSafehouse"))

    local territoryName = #safehouses > 1 and "Territories" or "Territory"
    local limit = SandboxVars.MultiBase.Limit
    if limit and limit > 0 then
        territoryName = territoryName .. " " .. tostring(#safehouses) .. "/" .. tostring(limit)
    end

    local main = context:addOptionOnTop(territoryName)
    local safehouseMenu = ISContextMenu:getNew(context)
    context:addSubMenu(main, safehouseMenu)

    local openMenu = ISContextMenu:getNew(safehouseMenu)
    local openOption = safehouseMenu:addOption("Open Territory")
    safehouseMenu:addSubMenu(openOption, openMenu)
    for _, safehouse in ipairs(safehouses) do
        openMenu:addOption(tostring(safehouse:getTitle()), worldobjects, function()
            MultiBase.openSafehouse(safehouse, pl)
        end)
    end

    if SandboxVars.MultiBase.AllowSetSpawnPoint and getServerOptions():getBoolean("SafehouseAllowRespawn") then
        local spawnMenu = ISContextMenu:getNew(safehouseMenu)
        local spawnOption = safehouseMenu:addOption("Set Spawn Point")
        safehouseMenu:addSubMenu(spawnOption, spawnMenu)
        for _, safehouse in ipairs(safehouses) do
            spawnMenu:addOption(tostring(safehouse:getTitle()), worldobjects, function()
                for _, otherSafehouse in ipairs(safehouses) do
                    sendSafehouseChangeRespawn(otherSafehouse, pl:getUsername(), false)
                end
                sendSafehouseChangeRespawn(safehouse, pl:getUsername(), true)
            end)
        end
    end

    if SandboxVars.MultiBase.AllowTeleport or isAdmin() or tostring(pl:getAccessLevel()) == "admin" then
        local teleportMenu = ISContextMenu:getNew(safehouseMenu)
        local teleportOption = safehouseMenu:addOption("Teleport to Safehouse")
        safehouseMenu:addSubMenu(teleportOption, teleportMenu)
        for _, safehouse in ipairs(safehouses) do
            teleportMenu:addOption(tostring(safehouse:getTitle()), worldobjects, function()
                MultiBase.teleportToSafehouse(safehouse, pl)
            end)
        end
    end
end
Events.OnFillWorldObjectContextMenu.Remove(MultiBase.OpenSH)
Events.OnFillWorldObjectContextMenu.Add(MultiBase.OpenSH)

Events.OnGameStart.Add(function()
    local original = ISUserPanelUI.onOptionMouseDown
    ISUserPanelUI.onOptionMouseDown = function(self, button, x, y)
        if button.internal == "SAFEHOUSEPANEL" then
            local safehouses = MultiBase.getPlayerSafehouses(self.player)
            if #safehouses > 0 then
                local selected = safehouses[1]
                for _, safehouse in ipairs(safehouses) do
                    if safehouse:isRespawnInSafehouse(self.player:getUsername()) then
                        selected = safehouse
                        break
                    end
                end
                MultiBase.openSafehouse(selected, self.player)
                return
            end
        end
        return original(self, button, x, y)
    end

    local originalUpdateButtons = ISUserPanelUI.updateButtons
    ISUserPanelUI.updateButtons = function(self, ...)
        originalUpdateButtons(self, ...)
        if self.safehouseBtn then
            if getServerOptions():getBoolean("SafehouseAllowRespawn") then
                self.safehouseBtn.title = "Spawnpoint"
            else
                self.safehouseBtn.title = "Selected Safehouse"
            end
        end
    end
end)






Events.OnGameStart.Add(function()

	local hook = ISSafehouseUI.ReceiveSafehouseInvite
	ISSafehouseUI.ReceiveSafehouseInvite = function(safehouse, host, username)
        local pl = getPlayer() 
		if MultiBase.isLimitRestricted(pl) then
			return hook(safehouse, host, username)
		end
		if ISSafehouseUI.inviteDialogs[host] then
			if ISSafehouseUI.inviteDialogs[host]:isReallyVisible() then return end
			ISSafehouseUI.inviteDialogs[host] = nil
		end

		if not MultiBase.isLimitRestricted(pl) then
			local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 175,getCore():getScreenHeight() / 2 - 75, 350, 150, getText("IGUI_SafehouseUI_Invitation", host), true, nil, ISSafehouseUI.onAnswerSafehouseInvite);
			modal:initialise()
			modal:addToUIManager()
			modal.safehouse = safehouse;
			modal.host = host;
			modal.username = username;
			modal.moveWithMouse = true;
			ISSafehouseUI.inviteDialogs[host] = modal
		end
	end

end)

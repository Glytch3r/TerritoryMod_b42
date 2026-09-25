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


function MultiBase.onTakeSafeHouse(sq, pl)
	local building = sq and sq:getBuilding()
	local def = building and building:getDef()
	if not pl or not def then return end
	local limit = tonumber(SandboxVars.MultiBase.Limit) or 0
	if limit > 0 and MultiBase.getCount(pl) >= limit then
		pl:setHaloNote("Territory Limit Reached", 250, 40, 40, 900)
		return
	end
	MultiBase.promptString("Enter Safehouse Title:", function(target, title)
		if not title or title:gsub("%s+", "") == "" then return end
		for i = 0, SafeHouse.getSafehouseList():size() - 1 do
			if tostring(SafeHouse.getSafehouseList():get(i):getTitle()) == title then
				pl:setHaloNote("Safehouse Title Already Exists", 250, 40, 40, 900)
				return
			end
		end
		local _owner = pl:getUsername()
		local _x, _y = def:getX() - 2, def:getY() - 2
		local _w, _h = def:getW() + 4, def:getH() + 4
		sendSafezoneClaim(_owner, _x, _y, _w, _h, title)
	end, nil, pl:getPlayerNum())
end




-----------------------            ---------------------------

-----------------------            ---------------------------
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

function MultiBase.openTerritoryManager(safehouse, pl)
    local width = 500 + getCore():getOptionFontSizeReal() * 30
    local safehouseUI = TerritoryManager:new((getCore():getScreenWidth() - width) / 2, getCore():getScreenHeight() / 2 - 225, width, 450, safehouse, pl)
    safehouseUI.safehouses = MultiBase.getPlayerSafehouses(pl)
    safehouseUI:initialise()
    safehouseUI:addToUIManager()
end

MultiBase.openSafehouse = MultiBase.openTerritoryManager

TerritoryManager = ISSafehouseUI:derive("TerritoryManager")

function TerritoryManager:initialise()
    ISSafehouseUI.initialise(self)
    self.changeTitle.onclick = TerritoryManager.onClick

    self:applyTheme()

    self.territoryLabel = ISLabel:new(self.nameLbl:getRight() + 120, UI_BORDER_SPACING + 1, BUTTON_HGT,
        MultiBase.getTerritoryString(self.player), 1, 1, 1, 1, UIFont.Small, true)
    self.territoryLabel:initialise()
    self.territoryLabel:instantiate()
    self:addChild(self.territoryLabel)

    self.safehouseSelector = ISComboBox:new(self.territoryLabel:getRight() + UI_BORDER_SPACING, UI_BORDER_SPACING,
        220, BUTTON_HGT, self, TerritoryManager.onSafehouseSelected)
    self.safehouseSelector:initialise()
    self.safehouseSelector:instantiate()
    for _, safehouse in ipairs(self.safehouses or {}) do
        self.safehouseSelector:addOptionWithData(tostring(safehouse:getTitle()), safehouse)
    end
    for index, safehouse in ipairs(self.safehouses or {}) do
        if safehouse == self.safehouse then self.safehouseSelector.selected = index break end
    end
    self:addChild(self.safehouseSelector)

    self.teleportButton = ISButton:new(self.no:getX() - 120, self.no:getY(), 110, BUTTON_HGT,
        "Teleport", self, TerritoryManager.onClick)
    self.teleportButton.internal = "TELEPORT"
    self.teleportButton:initialise()
    self.teleportButton:instantiate()
    self:addChild(self.teleportButton)

    self.customOwnerButton = ISButton:new(self.changeOwnership:getX() - 125, self.changeOwnership:getY(), 120, BUTTON_HGT,
        "Custom Owner", self, TerritoryManager.onClick)
    self.customOwnerButton.internal = "CUSTOMOWNER"
    self.customOwnerButton:initialise()
    self.customOwnerButton:instantiate()
    self:addChild(self.customOwnerButton)
    self:applyTheme()
end

function TerritoryManager:applyTheme()
    local red = {r=0.75, g=0.05, b=0.05, a=1}
    local darkRed = {r=0.35, g=0.015, b=0.015, a=0.96}
    local black = {r=0.015, g=0.015, b=0.015, a=0.97}
    local hover = {r=0.55, g=0.03, b=0.03, a=1}

    self.backgroundColor = black
    self.borderColor = red
    self.buttonBorderColor = red

    for _, child in ipairs(self:getChildren()) do
        if child == self.playerList then
            child.backgroundColor = black
            child.borderColor = red
        elseif child == self.safehouseSelector then
            child.backgroundColor = darkRed
            child.borderColor = red
            child.textColor = {r=1, g=1, b=1, a=1}
        elseif child == self.respawn then
            child.textColor = {r=1, g=0.8, b=0.8, a=1}
        elseif child.backgroundColor ~= nil then
            child.backgroundColor = darkRed
            child.backgroundColorMouseOver = hover
            child.backgroundColorPressed = red
            child.borderColor = red
            child.textColor = {r=1, g=1, b=1, a=1}
        elseif child.setColor then
            child:setColor(1, 0.75, 0.75, 1)
        end
    end
    if self.territoryLabel then self.territoryLabel:setColor(1, 0.25, 0.25, 1) end
end

function TerritoryManager:onSafehouseSelected(combo)
    local safehouse = combo:getOptionData(combo.selected)
    if not safehouse then return end
    self.safehouse = safehouse
    self:populateList()
    self.respawn.selected[1] = safehouse:isRespawnInSafehouse(self.player:getUsername())
    self.territoryLabel:setName(MultiBase.getTerritoryString(self.player))
end

function TerritoryManager:onClickRespawn(clickedOption, enabled)
    sendSafehouseChangeRespawn(self.safehouse, self.player:getUsername(), enabled)
end

function TerritoryManager:updateButtons()
    ISSafehouseUI.updateButtons(self)
    self.teleportButton.enable = SandboxVars.MultiBase.AllowTeleport == true
    local canChangeOwner = self:isOwner() or self:hasPrivilegedAccessLevel()
    self.changeOwnership:setVisible(canChangeOwner)
    self.customOwnerButton.enable = SandboxVars.MultiBase.AllowCustomOwner ~= false
    self.customOwnerButton:setVisible(canChangeOwner)
end

function TerritoryManager:onClick(button)
    if button.internal == "TELEPORT" then
        if SandboxVars.MultiBase.AllowTeleport == true then
            MultiBase.teleportToSafehouse(self.safehouse, self.player)
        end
        return
    end
    if button.internal == "CHANGETITLE" then
        local modal = ISTextBox:new(self.x + 200, 200, 280, 180,
            getText("IGUI_SafehouseUI_ChangeTitle"), self.safehouse:getTitle(), nil,
            TerritoryManager.onChangeTitle)
        modal.safehouse = self.safehouse
        modal.ui = self
        modal:initialise()
        modal:addToUIManager()
        return
    end
    if button.internal == "CUSTOMOWNER" then
        if SandboxVars.MultiBase.AllowCustomOwner == false then return end
        local modal = ISModalDialog:new(0, 0, 350, 150, "Owner Username", false, self,
            TerritoryManager.onOwnerUsername)
        modal.ui = self
        modal:initialise()
        modal:addToUIManager()
        local entry = ISTextEntryBox:new("", 20, 60, 310, 25)
        entry:initialise()
        entry:instantiate()
        modal:addChild(entry)
        modal.entry = entry
        return
    end
    ISSafehouseUI.onClick(self, button)
end

function TerritoryManager.onOwnerUsername(button)
    if button.internal ~= "OK" then return end
    local ui = button.parent.ui
    local username = luautils.trim(button.parent.entry:getText() or "")
    if username == "" then return end
    local target = getPlayerFromUsername(username)
    if not target then
        ui.player:setHaloNote("Player is not online", 250, 40, 40, 900)
        return
    end
    if target:getUsername() == ui.safehouse:getOwner() then return end
    sendSafehouseChangeOwner(ui.safehouse, target:getUsername())
    ui:populateList()
end

function TerritoryManager.onChangeTitle(button)
    if button.internal ~= "OK" then return end
    local title = button.parent.entry:getText()
    if not title or title:gsub("%s+", "") == "" then return end
    local ui = button.parent.ui
    for i = 0, SafeHouse.getSafehouseList():size() - 1 do
        local safehouse = SafeHouse.getSafehouseList():get(i)
        if safehouse ~= ui.safehouse and tostring(safehouse:getTitle()) == title then
            ui.player:setHaloNote("Safehouse Title Already Exists", 250, 40, 40, 900)
            return
        end
    end
    sendSafehouseChangeTitle(ui.safehouse, title)
end

function MultiBase.teleportToSafehouse(safehouse, pl)
    pl:teleportTo(safehouse:getX(), safehouse:getY(), 0)
    if isClient() then
        SendCommandToServer("/teleportto " .. tostring(safehouse:getX()) .. "," .. tostring(safehouse:getY()) .. ",0")
    else
        pl:teleportTo(safehouse:getX(), safehouse:getY(), 0)
    end
end
-----------------------            ---------------------------
Events.OnGameStart.Add(function()
    local hook = ISUserPanelUI.onOptionMouseDown
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
                MultiBase.openTerritoryManager(selected, self.player)
                return
            end
        end
        return hook(self, button, x, y)
    end

    local hookUpdateButtons = ISUserPanelUI.updateButtons
    ISUserPanelUI.updateButtons = function(self, ...)
        hookUpdateButtons(self, ...)
        if self.safehouseBtn then
            self.safehouseBtn.title = "Territory"
        end
    end

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

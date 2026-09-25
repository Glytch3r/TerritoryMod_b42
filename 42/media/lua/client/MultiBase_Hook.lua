MultiBase = MultiBase or {}
function MultiBase.isPlayerInSafehouse(sq, pl)
    if not sq then return false end

    pl = pl or getPlayer()
    if not pl then return false end

    local safehouse = SafeHouse.getSafeHouse(sq)
    if not safehouse then return false end

    local user = pl:getUsername()
    return safehouse:isOwner(user) or safehouse:getPlayers():contains(user)
end

function MultiBase.onTerritoryPanelButton(panel, button)
    if not button or button.internal ~= "SAFEHOUSEPANEL" then return end
    local player = panel.player
    local square = player and player:getSquare()
    if not player then return end
    local current = square and SafeHouse.getSafeHouse(square)
    local safehouses = MultiBase.getPlayerSafehouses(player)
    if #safehouses == 0 then return end
    local selected
    local username = player:getUsername()
    if current and (current:isOwner(username) or current:getPlayers():contains(username)) then
        selected = current
    elseif SandboxVars.MultiBase.AccessAnywhere and SandboxVars.MultiBase.AllowSetSpawnPoint then
        for _, safehouse in ipairs(safehouses) do
            if safehouse:isRespawnInSafehouse(username) then selected = safehouse; break end
        end
    end
    if selected then
        MultiBase.openTerritoryManager(selected, player)
    else
        player:setHaloNote("Can only open panel inside your territory", 150, 250, 150, 900)
    end
end
Events.OnGameStart.Add(function()
    local hookAddPlayerClick = ISSafehouseAddPlayerUI.onClick
    ISSafehouseAddPlayerUI.onClick = function(self, button, ...)
        if self.changeOwnership and button.internal == "ADDPLAYER" then
            local limit = tonumber(SandboxVars.MultiBase.Limit) or 0
            local target = self.selectedPlayer and getPlayerFromUsername(self.selectedPlayer)
            if limit > 0 and target and MultiBase.getCount(target) >= limit then
                self.player:setHaloNote(tostring(self.selectedPlayer).." Territory Limit Reached ", 250, 40, 40, 900)
                return
            end
        end
        return hookAddPlayerClick(self, button, ...)
    end

    local hook = ISUserPanelUI.onOptionMouseDown
    ISUserPanelUI.onOptionMouseDown = function(self, button, x, y)
        if button.internal == "SAFEHOUSEPANEL" then
            local square = self.player:getSquare()
            local current = square and SafeHouse.getSafeHouse(square)
            local username = self.player:getUsername()
            local safehouses = MultiBase.getPlayerSafehouses(self.player)
            if #safehouses > 0 then
                local selected
                if current and (current:isOwner(username) or current:getPlayers():contains(username)) then
                    selected = current
                elseif SandboxVars.MultiBase.AccessAnywhere and SandboxVars.MultiBase.AllowSetSpawnPoint then
                    for _, safehouse in ipairs(safehouses) do
                        if safehouse:isRespawnInSafehouse(username) then
                            selected = safehouse
                            break
                        end
                    end
                end
                if selected then
                    MultiBase.openTerritoryManager(selected, self.player)
                else
                    self.player:setHaloNote("Can only open panel inside your territory",150,250,150,900)
                end
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
            self.safehouseBtn.onclick = MultiBase.onTerritoryPanelButton
            local player = self.player
            local square = player and player:getSquare()
            local current = square and SafeHouse.getSafeHouse(square)
            local username = player and player:getUsername()
            local inside = current and (current:isOwner(username) or current:getPlayers():contains(username))
            local safehouses = player and MultiBase.getPlayerSafehouses(player) or {}
            local fallback = false
            if SandboxVars.MultiBase.AccessAnywhere and SandboxVars.MultiBase.AllowSetSpawnPoint then
                for _, safehouse in ipairs(safehouses) do
                    if safehouse:isRespawnInSafehouse(username) then fallback = true; break end
                end
            end
            local hasSafehouses = #safehouses > 0
            self.safehouseBtn.enable = hasSafehouses and (inside or fallback)
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

Events.OnGameStart.Add(function()
    local original = ISSafehouseUI.ReceiveSafehouseInvite
    ISSafehouseUI.ReceiveSafehouseInvite = function(safehouse, host, username)
        local pl = getPlayer()
        if MultiBase.isLimitRestricted(pl) then return original(safehouse, host, username) end
        if ISSafehouseUI.inviteDialogs[host] and ISSafehouseUI.inviteDialogs[host]:isReallyVisible() then return end
        local modal = ISModalDialog:new(getCore():getScreenWidth()/2-175, getCore():getScreenHeight()/2-75, 350, 150, getText("IGUI_SafehouseUI_Invitation", host), true, nil, ISSafehouseUI.onAnswerSafehouseInvite)
        modal:initialise(); modal:addToUIManager(); modal.safehouse=safehouse; modal.host=host; modal.username=username; modal.moveWithMouse=true
        ISSafehouseUI.inviteDialogs[host]=modal
    end
end)

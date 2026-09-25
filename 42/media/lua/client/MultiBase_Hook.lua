MultiBase = MultiBase or {}
function MultiBase.isPlayerInSafehouse(sq, pl)
    if not sq then return false end

    pl = pl or getPlayer()
    if not player then return false end

    local safehouse = SafeHouse.getSafeHouse(sq)
    if not safehouse then return false end

    local user = pl:getUsername()
    return safehouse:isOwner(user) or safehouse:getPlayers():contains(user)
end
Events.OnGameStart.Add(function()
    local hook = ISUserPanelUI.onOptionMouseDown
    ISUserPanelUI.onOptionMouseDown = function(self, button, x, y)
        if button.internal == "SAFEHOUSEPANEL" then
            local square = self.player:getSquare()
            local current = square and SafeHouse.getSafeHouse(square)
            local username = self.player:getUsername()
            if not current or (not current:isOwner(username) and not current:getPlayers():contains(username)) then
                return
            end
            local safehouses = MultiBase.getPlayerSafehouses(self.player)
            if #safehouses > 0 then
                local selected = safehouses[1]
                for _, safehouse in ipairs(safehouses) do
                    if safehouse:isRespawnInSafehouse(self.player:getUsername()) then
                        selected = safehouse
                        break
                    end
                end
                local pl = getPlayer() 
                local sq = pl:getSquare() 
                if sq and MultiBase.isPlayerInSafehouse(sq, pl) then
                    MultiBase.openTerritoryManager(selected, self.player)
                else
                    pl:setHaloNote("Can only open panel when inside your territory",150,250,150,900) 
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

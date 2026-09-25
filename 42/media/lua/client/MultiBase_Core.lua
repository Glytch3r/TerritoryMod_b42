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
-----------------------            ---------------------------
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

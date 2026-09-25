MultiBase = MultiBase or {}

-----------------------            ---------------------------
function MultiBase.context(player, context, worldobjects, test)
    if SandboxVars.MultiBase.DisableTerritoryContextMenu then return end
    local pl = getSpecificPlayer(player)
    local sq = MultiBase.getClickedSquare()
    if not pl or not sq then return end

    local hq = SafeHouse.getSafeHouse(sq)
    if not hq and sq:getBuilding() and sq:getBuilding():getDef() then
        local reason = SafeHouse.canBeSafehouse(sq, pl)

        local toolTip = ISWorldObjectContextMenu.addToolTip()
        local cap = getText("ContextMenu_SafehouseClaim")
        context:removeOptionByName(cap)
        
        local option = context:addOptionOnTop(cap, worldobjects, function()
            MultiBase.onTakeSafeHouse(sq, pl)
        end)

        toolTip.description = reason
        if (reason and reason ~= "" and not luautils.stringStarts(reason, getText("IGUI_Safehouse_AlreadyHaveSafehouse"))) or MultiBase.isLimitRestricted(pl) then
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

-----------------------            ---------------------------

function MultiBase.getTerritoryString(pl)
    pl = pl or getPlayer()
    local safehouses = MultiBase.getPlayerSafehouses(pl)
    local limit = SandboxVars.MultiBase.Limit
    local territoryStr = #safehouses > 1 and "Territories" or "Territory"
    territoryStr = territoryStr .. ":  " .. tostring(#safehouses)
    if limit and limit > 0 then
        territoryStr = territoryStr .. " / " .. tostring(limit)
    end
    return territoryStr
end
function MultiBase.OpenSH(player, context, worldobjects, test)
    if SandboxVars.MultiBase.DisableTerritoryContextMenu then return end
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

    local territoryName = MultiBase.getTerritoryString(pl)
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

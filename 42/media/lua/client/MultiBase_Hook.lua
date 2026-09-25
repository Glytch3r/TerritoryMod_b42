Events.OnGameStart.Add(function()
    local original = ISUserPanelUI.onOptionMouseDown
    ISUserPanelUI.onOptionMouseDown = function(self, button, x, y)
        if button.internal == "SAFEHOUSEPANEL" then
            local safehouses = MultiBase.getPlayerSafehouses(self.player)
            if #safehouses > 0 then
                local selected = safehouses[1]
                for _, safehouse in ipairs(safehouses) do if safehouse:isRespawnInSafehouse(self.player:getUsername()) then selected=safehouse; break end end
                MultiBase.openTerritoryManager(selected,self.player); return
            end
        end
        return original(self,button,x,y)
    end
end)

local TERRITORY_UI_BORDER_SPACING = 10
local TERRITORY_BUTTON_HGT = getTextManager():getFontHeight(UIFont.Small) + 6

function MultiBase.openTerritoryManager(safehouse, pl)
    local width = 540 + getCore():getOptionFontSizeReal() * 30
    local ui = TerritoryManager:new((getCore():getScreenWidth() - width) / 2, getCore():getScreenHeight() / 2 - 225, width, 450, safehouse, pl)
    ui.safehouses = MultiBase.getPlayerSafehouses(pl)
    ui:initialise()
    ui:addToUIManager()
end

MultiBase.openSafehouse = MultiBase.openTerritoryManager
TerritoryManager = ISSafehouseUI:derive("TerritoryManager")

function TerritoryManager:initialise()
    ISSafehouseUI.initialise(self)
    self.nameLbl:setName("Safehouse")
    self.changeTitle:setTitle("Change Title")
    self.changeTitle.onclick = TerritoryManager.onClick
    --self.width / 2 - 35
    self.territoryLabel = ISLabel:new(340, TERRITORY_UI_BORDER_SPACING + TERRITORY_BUTTON_HGT + 35, TERRITORY_BUTTON_HGT, MultiBase.getTerritoryString(self.player), 1, 1, 1, 1, UIFont.Medium, true)
    self.territoryLabel:initialise(); self.territoryLabel:instantiate(); self:addChild(self.territoryLabel)

    self.safehouseSelector = ISComboBox:new(340, TERRITORY_UI_BORDER_SPACING + TERRITORY_BUTTON_HGT + 65, 220, TERRITORY_BUTTON_HGT, self, TerritoryManager.onSafehouseSelected)
    self.safehouseSelector:initialise(); self.safehouseSelector:instantiate()
    for _, safehouse in ipairs(self.safehouses or {}) do self.safehouseSelector:addOptionWithData(tostring(safehouse:getTitle()), safehouse) end
    for i, safehouse in ipairs(self.safehouses or {}) do if safehouse == self.safehouse then self.safehouseSelector.selected = i break end end
    self:addChild(self.safehouseSelector)
    self.teleportButton = ISButton:new(self.no:getX() - 120, self.no:getY(), 110, TERRITORY_BUTTON_HGT, "Teleport", self, TerritoryManager.onClick)
    self.teleportButton.internal = "TELEPORT"; self.teleportButton:initialise(); self.teleportButton:instantiate(); self:addChild(self.teleportButton)
    self:applyTheme()
end

function TerritoryManager:applyTheme()
    local red = {r=.75,g=.05,b=.05,a=1}; local darkRed = {r=.35,g=.015,b=.015,a=.96}; local black = {r=.10,g=.008,b=.008,a=.98}; local hover = {r=.55,g=.03,b=.03,a=1}
    self.backgroundColor=black; self.borderColor=red; self.buttonBorderColor=red
    for _, child in ipairs(self:getChildren()) do
        if child == self.playerList then child.backgroundColor=black; child.borderColor=red
        elseif child == self.safehouseSelector then child.backgroundColor=darkRed; child.borderColor=red; child.textColor={r=1,g=1,b=1,a=1}
        elseif child == self.respawn then child.textColor={r=1,g=.8,b=.8,a=1}
        elseif child.backgroundColor ~= nil then child.backgroundColor=darkRed; child.backgroundColorMouseOver=hover; child.backgroundColorPressed=red; child.borderColor=red; child.textColor={r=1,g=1,b=1,a=1}
        elseif child.setColor then child:setColor(.459,.490,.435,1) end
    end
    if self.territoryLabel then self.territoryLabel:setColor(1,.25,.25,1) end
end

function TerritoryManager:onSafehouseSelected(combo)
    local safehouse = combo:getOptionData(combo.selected); if not safehouse then return end
    self.safehouse=safehouse; self:populateList(); self.respawn.selected[1]=safehouse:isRespawnInSafehouse(self.player:getUsername()); self.territoryLabel:setName(MultiBase.getTerritoryString(self.player))
end
function TerritoryManager:onClickRespawn(_, enabled) sendSafehouseChangeRespawn(self.safehouse, self.player:getUsername(), enabled) end
function TerritoryManager:updateButtons()
    ISSafehouseUI.updateButtons(self); self.territoryLabel:setName(MultiBase.getTerritoryString(self.player)); self.teleportButton.enable=SandboxVars.MultiBase.AllowTeleport==true; self.changeOwnership:setVisible(self:isOwner() or self:hasPrivilegedAccessLevel())
end
function TerritoryManager:onClick(button)
    if button.internal == "TELEPORT" then if SandboxVars.MultiBase.AllowTeleport==true or MultiBase.isAdm() then MultiBase.teleportToSafehouse(self.safehouse,self.player) end; return end
    if button.internal == "CHANGETITLE" then local modal=ISTextBox:new(self.x+200,200,280,180,getText("IGUI_SafehouseUI_ChangeTitle"),self.safehouse:getTitle(),self,TerritoryManager.onChangeTitle); modal.safehouse=self.safehouse; modal:initialise(); modal:addToUIManager(); return end
    ISSafehouseUI.onClick(self,button)
end
function TerritoryManager.onChangeTitle(ui, button)
    if button.internal~="OK" then return end; local title=button.parent.entry:getText(); if not title or title:gsub("%s+","")=="" then return end
    for i=0,SafeHouse.getSafehouseList():size()-1 do local sh=SafeHouse.getSafehouseList():get(i); if sh~=ui.safehouse and tostring(sh:getTitle())==title then ui.player:setHaloNote("Safehouse Title Already Exists",250,40,40,900); return end end
    sendSafehouseChangeTitle(ui.safehouse,title)
end

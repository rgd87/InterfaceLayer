local addonName, ns = ...

--[[ This addon is inspired by Dash, which hasn't been updated since BC, so I made a more reliable alternative for myself  ]]

local Layer = CreateFrame("Frame", "InterfaceLayer", UIParent)
Layer:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

_G.BINDING_NAME_HOLD_SWITCH = "Hold Activation"
_G.BINDING_HEADER_INTERFACELAYER = "InterfaceLayer"
_G.BINDING_NAME_TOGGLE_SWITCH = "Toggle Activation"

-- _G.InterfaceLayer = Layer
local db

Layer:RegisterEvent("PLAYER_LOGIN")
Layer:RegisterEvent("PLAYER_LOGOUT")

local defaults = {
    frames = {},
    snippets = {},
    weakAuras = {},
    protectedFrames = {},
}

Layer.childFrames = {}


function Layer:PLAYER_LOGIN()
    LayerDB = LayerDB or {}
    db = LayerDB
    ns.SetupDefaults(db, defaults)

    self:Create()

    for frame in pairs(db.frames) do
        local ok = self:Reparent(frame)
        -- if not ok then
            -- db.frames[frame] = nil
        -- end
    end

    for _, snippet in ipairs(db.snippets) do
        local chunk = loadstring("return "..snippet)
        local status, frame = xpcall(chunk, function(...)
            -- print(...)
        end)
        if status then
            local ok = Layer:Reparent(frame)
        end
    end

    for waID in pairs(db.weakAuras) do
        local ok = self:ReparentWeakAura(waID)
        -- if not ok then
            -- db.frames[frame] = nil
        -- end
    end

    local loadedGroups = {}
    if WeakAuras then
        --[[
        hooksecurefunc(WeakAuras, "LoadDisplays", function(toLoad, ...)
            table.wipe(loadedGroups)

            for id, loaded in pairs(toLoad) do
                if loaded then
                    local region = WeakAuras.regions[id].region
                    local parent = region:GetParent()
                    if parent.regionType == "group" then
                        local groupName = parent.id
                        loadedGroups[groupName] = true
                    end
                end
            end

            for waID in pairs(db.weakAuras) do
                if toLoad[waID] or loadedGroups[waID] then
                    Layer:ReparentWeakAura(waID)
                end
            end
        end)
        ]]
    end

    SLASH_INTERFACELAYER1= "/layer"
    SLASH_INTERFACELAYER2= "/interfacelayer"
    SLASH_INTERFACELAYER3= "/ila"
    SlashCmdList["INTERFACELAYER"] = self.SlashCmd
end

function Layer:PLAYER_LOGOUT()
    ns.RemoveDefaults(db, defaults)
end

local blacklist = {
	InterfaceLayer = true,
	UIParent = true,
	WorldFrame = true,
}

function Layer:Reparent(frame)
    if type(frame) == "string" then
        frame = _G[frame]
    end

    if frame == nil then return end

    if not frame:IsObjectType("Frame") then
        DEFAULT_CHAT_FRAME:AddMessage(frame:GetName().."is not a frame")
        return
    end

    if blacklist[frame:GetName()] then
        DEFAULT_CHAT_FRAME:AddMessage(frame:GetName().."is blacklisted")
        return
    end

    if frame:IsProtected() then
        DEFAULT_CHAT_FRAME:AddMessage(frame:GetName().."is protected")
        return
    end

    self.childFrames[frame] = true
    frame:SetParent(self)
    -- frame:SetFrameStrata("DIALOG")
    return true
end
function Layer:ReparentWeakAura(waID)
    local waRegion = WeakAuras.regions[waID]
    if waRegion then
        local waFrame = waRegion.region
        return self:Reparent(waFrame)
    end
end

function Layer:Unparent(frame)
    if self.childFrames[frame] then
        frame:SetParent(UIParent)
        -- frame:SetFrameStrata("MEDIUM")
        self.childFrames[frame] = nil
        return true
    end
end

function Layer:RefershAllFrames()
    for frame in pairs(self.childFrames) do
        frame:SetParent(self)
    end
end

function Layer:Toggle()
    self:RefershAllFrames()
    if self:IsShown() then
        self:FadeOut()
    else
        self:FadeIn()
    end
end

function Layer:Activate()
    self:RefershAllFrames()
    self:FadeIn()
end
function Layer:Deactivate()
    self:RefershAllFrames()
    self:FadeOut()
end

function Layer:TempActivation()
    self:RefershAllFrames()
    self.texture:SetAlpha(0.2)
    self:FadeIn(nil, function()
        self:FadeOut(5, function()
            self.texture:SetAlpha(0.5)
        end)
    end)
end

local originalSetAlpha = Layer.SetAlpha
function Layer:SetAlpha(alpha)
    originalSetAlpha(self, alpha)

    for frameName in pairs(db.protectedFrames) do
        local frame = _G[frameName]
        frame:SetAlpha(alpha)
    end
end


Layer.Commands = {
    ["add"] = function(frameName)
        if Layer:Reparent(frameName) then
            db.frames[frameName] = true
        end
    end,

    ["addprotected"] = function(frameName)
        db.protectedFrames[frameName] = true
    end,

    ["addwa"] = function(waName)
        if Layer:ReparentWeakAura(waName) then
            db.weakAuras[waName] = true
        end
    end,

    ["addmouse"] = function()
        local frame = GetMouseFocus()

        if not frame then return end

        if not frame:IsObjectType("Frame") then
            print(frame:GetName(), "is not a frame")
            return
        end

        local frameName = frame:GetName()
        if not frameName then
            print("Frame has no global name and cannot be added")
        end

        if Layer:Reparent(frameName) then
            db.frames[frameName] = true
            print("Added:", frameName)
        end
    end,

    ["addsnippet"] = function(snippet)
        local chunk = loadstring("return "..snippet)
        local frame = chunk()
        if Layer:Reparent(frame) then
            table.insert(db.snippets, snippet)
            local n = #db.snippets
            print("Added at",n,"\n    ",snippet)
        end
    end,

    ["list"] = function()
        print("Layer frames:")
        for frameName in pairs(db.frames) do
            print("   ",frameName)
        end

        print("Layer snippets:")
        for i, snippet in ipairs(db.snippets) do
            print("   ",i,"-", snippet)
        end

        print("Layer weakauras:")
        for waName in pairs(db.weakAuras) do
            print("   ",waName)
        end
    end,

    ["remove"] = function(frameName)
        local frame = _G[frameName]

        if Layer:Unparent(frame) then
            db.frames[frameName] = nil
            print("Removed:", frameName)
        end
    end,

    ["removesnippet"] = function(indexString)
        local index = tonumber(indexString)
        if not index then return end
        if db.snippets[index] then
            local snippet = table.remove(db.snippets, index)
            print("Removed:", snippet)
        end
    end,

    ["removewa"] = function(waName)
        local waRegion = WeakAuras.regions[waName]
        if waRegion then
            local frame = waRegion.region

            Layer:Unparent(frame)
        end
        db.weakAuras[waName] = nil
        print("Removed:", waName)
    end,
}


function Layer.SlashCmd(msg)
    local k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then
        print([[Usage:
          |cff55ff55/layer add - add frame by its global name|r
          |cff55ff55/layer addmouse - add frame under mouse cursor|r
          |cff55ff55/layer addsnippet - add by lua snippet when not directly accessible|r
          |cff55ff55/layer addwa - add a WeakAura display or group by name|r
          |cff55ff55/layer remove <name>|r
          |cff55ff55/layer removesnippet <id>|r
          |cff55ff55/layer removewa <wa name>|r
          |cff55ff55/layer list|r
          |cff55ff55/layer remove|r
        ]])
    end
    if Layer.Commands[k] then
        Layer.Commands[k](v)
    end
end



function Layer:FadeOut(fadeTime, fadeFuncExtra)
    UIFrameFadeOut(self, fadeTime or 0.15, 1, 0)
    self.fadeInfo.finishedFunc = function()
        self:Hide()
        if fadeFuncExtra then
            fadeFuncExtra()
        end
    end
end

function Layer:FadeIn(fadeTime, fadeFuncExtra)
    self:Show()
    UIFrameFadeIn(self, fadeTime or 0.15, 0, 1)
    self.fadeInfo.finishedFunc = fadeFuncExtra
end

function Layer:Create()
    self:Hide()
    local texture = self:CreateTexture("LayerBlackoutTexture", "ARTWORK")
    texture:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    texture:SetAllPoints()
    texture:SetVertexColor(0,0,0)
    texture:SetAlpha(0.5)
    self.texture = texture

    self:ClearAllPoints()
    self:SetAllPoints(UIParent)

    self:SetFrameStrata("DIALOG")
    self:SetFrameLevel(0)

    local corner = "TOPRIGHT"

    local spot = CreateFrame("Frame", nil, UIParent)
    spot:SetWidth(2)
    spot:SetHeight(2)
    spot:SetFrameStrata("TOOLTIP")
    spot:SetPoint(corner, UIParent)
    spot:EnableMouse(true)
    spot:SetScript("OnEnter", function()
        Layer:Toggle()
    end)
end

function ns.SetupDefaults(t, defaults)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            else
                ns.SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end
function ns.RemoveDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if type(t[k]) == 'table' and type(v) == 'table' then
            ns.RemoveDefaults(t[k], v)
            if next(t[k]) == nil then
                t[k] = nil
            end
        elseif t[k] == v then
            t[k] = nil
        end
    end
    return t
end
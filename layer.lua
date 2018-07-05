local addonName, ns = ...

--[[ This addon is inspired by Dash, which hasn't been updated since BC, so I made a more reliable alternative for myself  ]]

local Layer = CreateFrame("Frame", "InterfaceLayer", UIParent)
Layer:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

-- _G.InterfaceLayer = Layer
local db

Layer:RegisterEvent("PLAYER_LOGIN")
Layer:RegisterEvent("PLAYER_LOGOUT")

local defaults = {
    frames = {},
    snippets = {},
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
        local frame = chunk()
        local ok = Layer:Reparent(frame)
    end

    SLASH_INTERFACELAYER1= "/layer"
    SLASH_INTERFACELAYER2= "/interfacelayer"
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


Layer.Commands = {
    ["add"] = function(frameName)
        if Layer:Reparent(frameName) then
            db.frames[frameName] = true
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
}


function Layer.SlashCmd(msg)
    k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then
        print([[Usage:
          |cff55ff55/layer add|r
          |cff55ff55/layer addmouse|r
          |cff55ff55/layer list|r
          |cff55ff55/layer remove|r
        ]])
    end
    if Layer.Commands[k] then
        Layer.Commands[k](v)
    end
end



function Layer:FadeOut()
    UIFrameFadeOut(self, .15, 1, 0)
    self.fadeInfo.finishedFunc = function() self:Hide() end
end

function Layer:FadeIn()
    self:Show()
    UIFrameFadeIn(self, .15, 0, 1)
end

function Layer:Create()
    self:Hide()
    self:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    self:SetBackdropColor(0,0,0,0.5)

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
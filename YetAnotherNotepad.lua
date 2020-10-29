local YAnotepad = LibStub("AceAddon-3.0"):NewAddon("YetAnotherNotepad", "AceConsole-3.0", "AceEvent-3.0")
YAnotepad:RegisterChatCommand("yanote", "ChatCommand")

local AceGUI = LibStub("AceGUI-3.0")
local QTip = LibStub("LibQTip-1.0")

local defaults = {
    char = {
        notes = {
            {"Test note\nThis is a test note", "01-02-2011", "01-03-2011"},
        },
        listWidth = 440,
        listHeight = 400,
        padWidth = 600,
        padHeight = 600,
    }
}

local List

---------------
-- Init Feed --
---------------

local function Feed_OnClick(_, button)
    YAnotepad:Show()
end

local function Feed_NoteEdit(_, id)
    YAnotepad:Edit(id)
end

local function Feed_OnEnter(anchor)
    local k, v, i, headline, line

    for k, v in QTip:IterateTooltips() do
        if( type(k) == "string" and k == "YetAnotherNotepad" ) then
            v:Release(k);
            YAnotepad.tooltip = nil
        end
    end

    YAnotepad.tooltip = QTip:Acquire("YetAnotherNotepad", 3)
    YAnotepad.tooltip:AddHeader("Notes", "Created", "Modified")
    YAnotepad.tooltip:AddSeparator()

    for i,v in ipairs(YAnotepad.db.char.notes) do
        headline = YAnotepad:GetHeadline(v[1])
        line = YAnotepad.tooltip:AddLine(headline, v[2], v[3])
        YAnotepad.tooltip:SetLineScript(line, "OnMouseDown", Feed_NoteEdit, i)
    end

    YAnotepad.tooltip:SmartAnchorTo(anchor)
    YAnotepad.tooltip:SetAutoHideDelay(0.1, anchor)
    YAnotepad.tooltip:Show()
end

function YAnotepad:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("YAnotepadDB", defaults, true);
end

local List

function YAnotepad:ChatCommand(input)
    if not input or input:trim() == "" then
        YAnotepad:Show()
    end
end

function YAnotepad:OnEnable()

end

function YAnotepad:Show()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("YetAnotherNotepad")
    frame:SetLayout("Flow")
    frame:SetWidth(self.db.char.listWidth)
    frame:SetHeight(self.db.char.listHeight)

    local cmdNew = AceGUI:Create("Button")
    cmdNew:SetText("New Note")
    cmdNew:SetWidth(100)
    cmdNew:SetCallback("OnClick", function(widget) YAnotepad:New(scroll) end);
    frame:AddChild(cmdNew)

    local group = AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    group:SetFullHeight(true)
    group:SetLayout("Fill")
    frame:AddChild(group)

    List = AceGUI:Create("ScrollFrame")
    List:SetLayout("List")
    group:AddChild(List)

    YAnotepad:PopulateNotes(List)

    frame:SetCallback("OnClose", function(widget)
        List = nil
    end)
end

function YAnotepad:PopulateNotes()
    if List ~= nil then
        List:ReleaseChildren()
        for i,v in ipairs(self.db.char.notes) do
            entry = YAnotepad:CreateEntry(i, v)
            List:AddChild(entry)
        end
    end
end

function YAnotepad:CreateEntry(id, data)
    local group = AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    group:SetHeight(32)

    local icon = AceGUI:Create("Icon")
    icon:SetImage("Interface\\ICONS\\INV_Misc_Note_01.blp")
    icon:SetImageSize(32, 32)
    icon:SetWidth(40)
    icon:SetCallback("OnClick", function(widget) YAnotepad:Edit(id) end)
    group:AddChild(icon)

    local labels = AceGUI:Create("SimpleGroup")
    labels:SetHeight(32)
    labels:SetLayout("list")

    local label = AceGUI:Create("InteractiveLabel")
    label:SetText(YAnotepad:GetHeadline(data[1]))
    label:SetFont(STANDARD_TEXT_FONT, 16)
    label:SetHeight(18)
    label:SetCallback("OnClick", function(widget) YAnotepad:Edit(id) end)
    labels:AddChild(label)

    local dates = AceGUI:Create("InteractiveLabel")
    dates:SetText("Created: " .. data[2] .. "   Modified: " .. data[3])
    dates:SetCallback("OnClick", function(widget) YAnotepad:Edit(id) end)
    labels:AddChild(dates)

    group:AddChild(labels)

    local delete = AceGUI:Create("Button")
    delete:SetText("X")
    delete:SetWidth(40)
    delete:SetCallback("OnClick", function(widget) YAnotepad:Delete(id) end)

    group:AddChild(delete)

    return group
end

function YAnotepad:New()
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("YetAnotherNotepad")
    frame:SetStatusText("")
    frame:SetLayout("Flow")
    frame:SetWidth(self.db.char.padWidth)
    frame:SetHeight(self.db.char.padHeight)

    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("")
    editbox:DisableButton(1)
    editbox:SetFullWidth(1)
    editbox:SetFullHeight(1)
    editbox:SetFocus()
    editbox:SetCallback("OnTextChanged", function(widget) YAnotepad:UpdateFrame(widget, frame) end)

    frame:AddChild(editbox)

    frame:SetCallback("OnClose", function(widget)
        if strlen(editbox:GetText()) > 0 then
            data = {editbox:GetText(), date("%m-%d-%Y"), date("%m-%d-%Y")}
            table.insert(self.db.char.notes, data)
            YAnotepad:PopulateNotes()
        end
        AceGUI:Release(widget)
    end)
end

function YAnotepad:Edit(id)
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Project Notepad")
    frame:SetStatusText("")
    frame:SetLayout("Flow")
    frame:SetWidth(self.db.char.padWidth)
    frame:SetHeight(self.db.char.padHeight)

    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("")
    editbox:DisableButton(1)
    editbox:SetFullWidth(1)
    editbox:SetFullHeight(1)
    editbox:SetFocus()
    editbox:SetCallback("OnTextChanged", function(widget) YAnotepad:UpdateFrame(widget, frame) end)

    frame:AddChild(editbox)

    local data = self.db.char.notes[id]
    editbox:SetText(data[1])
    YAnotepad:UpdateFrame(editbox, frame)

    frame:SetCallback("OnClose", function(widget)
        if data[1] ~= editbox:GetText() and id ~= nil then
            data[1] = editbox:GetText()
            data[2] = data[2]
            data[3] = date("%m-%d-%Y")
            self.db.char.notes[id] = data
            YAnotepad:PopulateNotes()
        end
        AceGUI:Release(widget)
    end)
end

function YAnotepad:Delete(id)
    table.remove(self.db.char.notes, id)
    YAnotepad:PopulateNotes()
end

function YAnotepad:UpdateFrame(widget, frame)
    frame:SetTitle(YAnotepad:GetHeadline(widget:GetText()))
    frame:SetStatusText("Length: " .. strlen(widget:GetText()))
end

function YAnotepad:GetHeadline(text)
    local headline = strsub(text, 0, strfind(text, "\n"))
    headline = gsub(headline, "\n", "")
    headline = strtrim(headline)
    return headline
end
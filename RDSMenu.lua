require 'lib.moonloader'

local imgui = require 'mimgui' -- ������������� ����������
local dlstatus = require('moonloader').download_status -- ��������������� ������ � ����������
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local mim_addons = require 'mimgui_addons'
local fa = require 'fAwesome6_solid'
local inicfg = require 'inicfg'
local memory = require 'memory'
local ffi = require 'ffi'
local sc_ok, sc = pcall(import, 'lib/scoreboard.lua')
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ## ��������� ���������� ## --
local tag = '{F576FF} [RDS] {FFFFFF}'
-- ## ��������� ���������� ## --

-- ## ������ � mimgui ## -- 
local new = imgui.new
local sw, sh = getScreenResolution()

imgui.OnInitialize(function()   
    fa.Init(32)
end)
-- ## ������ � mimgui ## -- 

local version = 1

-- ## ������ � ��������� � ����������� ## --

local elements = {
    boolean = {
        window_menu = new.bool(false),
        settings_menu = new.bool(false),
    },
    imgui = {
        select_int = 0,
    },
    int = {
        btn_size = imgui.ImVec2(85,75),
    },
}

-- ## ������ � ��������� � ����������� ## --


function showCursor(toggle)
    if toggle then
      sampSetCursorMode(CMODE_LOCKCAM)
    else
      sampToggleCursor(false)
    end
    cursorEnabled = toggle
end

function main()
    while not isSampAvailable() do wait(0) end
    
    sampAddChatMessage(tag .. '�������������� ���� Russian Drift Server ����������! �������� ���� <3', -1)
    sampAddChatMessage(tag .. '��������� ���� ����� ��� ������ ������� /mrds', -1)

    elements.boolean.window_menu[0] = true

    sampRegisterChatCommand('mrds', function()
        elements.boolean.settings_menu[0] = not elements.boolean.settings_menu[0]
    end)

    while true do
        wait(0)
        
    end
end

local RDSWindowSettings = imgui.OnFrame( 
    function() return elements.boolean.settings_menu[0] end,  
    function(player) 

        imgui.Begin('[RDS] Settings', elements.boolean.settings_menu, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)

        imgui.Text(u8'���� ��������� ����� �������� ����������������� � �������������� ����.\n��� �������, ����� ������ �� ������ ��� �����������.')
        imgui.Text(u8'����������� ����� ����� ������ (��� �������� �������������) ��� �������� ������.')

        imgui.End()  
    end
)

local RDSWindowMenu = imgui.OnFrame(
    function() return elements.boolean.window_menu[0] end, 
    function(player)

        player.HideCursor = true

        imgui.SetNextWindowPos(imgui.ImVec2((sw / 12) - 90, sh / 2.75), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

        imgui.Begin('##Menu', elements.boolean.window_menu, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)

            if elements.imgui.select_int == 0 then

                if imgui.Button(fa.ARROW_RIGHT, elements.int.btn_size) then  
                    elements.imgui.select_int = 1
                end
            end

            if elements.imgui.select_int == 1 then  
                if imgui.Button(fa.ARROW_LEFT, elements.int.btn_size) then  
                    elements.imgui.select_int = 0 
                end  
                imgui.SameLine()
                imgui.SetWindowFontScale(1.3)
                if imgui.Button("Menu", elements.int.btn_size) then  
                    sampSendChat('/mm')
                end  
                imgui.SameLine()
                if imgui.Button('TAB', elements.int.btn_size) then  
                    lua_thread.create(function()
                        sc.ActiveScoreBoard()
                    end)
                end  
            end

        imgui.End()
    end
)
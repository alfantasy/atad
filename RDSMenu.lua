require 'lib.moonloader'

local imgui = require 'mimgui' -- инициализация интерфейса
local dlstatus = require('moonloader').download_status -- контролирование версий и обновление
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local mim_addons = require 'mimgui_addons'
local fa = require 'fAwesome6_solid'
local inicfg = require 'inicfg'
local memory = require 'memory'
local ffi = require 'ffi'
local http = require('socket.http') -- работа с запросами HTTP
local ltn12 = require('ltn12') -- работа с файловой системой
local sc_ok, sc = pcall(import, 'lib/scoreboard.lua')
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ## Текстовые переменные ## --
local tag = '{F576FF} [RDS] {FFFFFF}'
-- ## Текстовые переменные ## --

-- ## Работа с mimgui ## -- 
local new = imgui.new
local sw, sh = getScreenResolution()

imgui.OnInitialize(function()   
    fa.Init(32)
end)
-- ## Работа с mimgui ## -- 

function downloadFile(url, path)
	local response = {}
	local _, status_code, _ = http.request{
	  url = url,
	  method = "GET",
	  sink = ltn12.sink.file(io.open(path, "wb")),
	  headers = {
		["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0;Win64) AppleWebkit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.82 Safari/537.36",
  
	  },
	}
	if status_code == 200 then
		return true
	else
		return false
	end
end

local version = 1
local url_update = 'https://raw.githubusercontent.com/alfantasy/atad/main/RDSMenu.lua'
local path_update = getWorkingDirectory() .. '/RDSMenu.lua'
-- ## Работа с конфигами и переменными ## --

local elements = {
    boolean = {
        window_menu = new.bool(false),
        settings_menu = new.bool(false),
    },
    imgui = {
        select_int = 0,
    },
    int = {
        btn_size = imgui.ImVec2(60,60),
    },
}

local buttons = {
    F_button = false,
    ALT_button = false,
    H_button = false, 
    TwoNumber_button = false,
}
-- ## Работа с конфигами и переменными ## --


function sampev.onSendPlayerSync(data)
    if buttons.F_button then  
        data.keysData = 16 
    end
    if data.keysData == 1024 then  
        return false
    end 
    if buttons.ALT_button then  
        data.keysData = 1024 
    end
    --sampAddChatMessage(data.keysData, -1)
end

function sampev.onSendVehicleSync(data)
    if buttons.TwoNumber_button then  
        data.keysData = 512 
    end 
    if buttons.H_button then  
        data.keysData = 2 
    end 
    --sampAddChatMessage(data.keysData, -1)
end

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
    
    sampAddChatMessage(tag .. 'Функциональное меню Russian Drift Server подгружено! Приятной игры <3', -1)
    sampAddChatMessage(tag .. 'Настроить меню можно при помощи команды /mrds', -1)

    local response = http.request(url_update)
    if response then  
        local currentVersionFile = io.open(path_update, 'r')
        local currentVersion = currentVersionFile:read('*a')
        currentVersionFile:close() 
        if response ~= currentVersion then  
            sampAddChatMessage(tag .. 'Доступно обновление RDS Menu. Обновляемся <3', -1)
            local response_download = downloadFile(url_update, path_update)
            if response_download then  
                sampAddChatMessage(tag .. 'Обновление окончено. Перезагружаю скрипты :)', -1)
                reloadScripts()
            end
        else 
            sampAddChatMessage(tag .. 'Установлена актуальная версия RDS Menu. Обновление не требуется.', -1)
        end
    end

    elements.boolean.window_menu[0] = true

    sampRegisterChatCommand('devcommand', function() 
        sampAddChatMessage(tag .. 'Закрываю диалог из-за рестарта AT', -1)
        sampSendDialogResponse(2349, 0, -1) 
    end)

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

        imgui.TextWrapped(u8'Окно позволяет также напрямую взаимодействовать с функциональном меню.При желании, прямо сейчас вы можете его передвинуть.')
        imgui.TextWrapped(u8'Удерживайте место около кнопки (все спокойно передвигается) для переноса окошка.')
        imgui.TextWrapped(u8'Обновление данного скрипта - автоматическое. Ничего сверхъестественного делать не нужно.')

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
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button("Menu", elements.int.btn_size) then  
                    sampSendChat('/mm')
                end  
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('TAB', elements.int.btn_size) then  
                    lua_thread.create(function()
                        sc.ActiveScoreBoard()
                    end)
                end  
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('F', elements.int.btn_size) then  
                    lua_thread.create(function()
                        buttons.F_button = true  
                        wait(500)
                        buttons.F_button = false
                    end)
                end
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('ALT', elements.int.btn_size) then  
                    lua_thread.create(function()
                        buttons.ALT_button = true  
                        wait(500)
                        buttons.ALT_button = false
                    end)
                end
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('2', elements.int.btn_size) then  
                    lua_thread.create(function()
                        buttons.TwoNumber_button = true  
                        wait(500)
                        buttons.TwoNumber_button = false
                    end)
                end  
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('H', elements.int.btn_size) then  
                    lua_thread.create(function()
                        buttons.H_button = true  
                        wait(500)
                        buttons.H_button = false
                    end)  
                end 
                imgui.SameLine()
                imgui.Dummy(imgui.ImVec2(5,0))
                imgui.SameLine()
                if imgui.Button('RSc', elements.int.btn_size) then  
                    sampAddChatMessage(tag .. 'Производится перезагрузка скриптов.', -1)
                    reloadScripts()
                end
            end

        imgui.End()
    end
)
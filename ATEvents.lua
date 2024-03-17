require 'lib.moonloader'

local imgui = require 'mimgui' -- инициализация интерфейса Moon ImGUI
local encoding = require 'encoding' -- работа с кодировками
local sampev = require 'lib.samp.events' -- интеграция пакетов SA:MP и происходящих/исходящих/входящих т.д. ивентов
local mim_addons = require 'mimgui_addons' -- интеграция аддонов для интерфейса mimgui
local fa = require 'fAwesome6_solid' -- работа с иконами на основе FontAwesome 6
local inicfg = require 'inicfg' -- работа с конфигом
local memory = require 'memory' -- работа с памятью напрямую
local ffi = require 'ffi' -- глобальная работа с переменными игры
local atlibs = require 'libsfor'
local toast_ok, toast = pcall(import, 'lib/mimtoasts.lua') -- интеграция уведомлений.
encoding.default = 'CP1251' -- смена кодировки на CP1251
u8 = encoding.UTF8 -- объявление кодировки U8 как рабочую, но в форме переменной (для интерфейса)

-- ## Блок текстовых переменных ## --
local tag = "{00BFFF} [AT] {FFFFFF}" -- локальная переменная, которая регистрирует тэг AT
-- ## Блок текстовых переменных ## --

-- ## mimgui ## --
local new = imgui.new

function Tooltip(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8(text))
        imgui.EndTooltip()
    end 
end

imgui.OnInitialize(function()   
    imgui.GetIO().IniFilename = nil
    fa.Init()
end)

local sw, sh = getScreenResolution()
-- ## mimgui ## --

local directIni = 'AdminTool/events.ini'

local config = inicfg.load({
    main = {
        auto_tp = false, 
    },
    bind_name = {},
    bind_text = {},
    bind_delay = {},
    bind_vdt = {},
    bind_coords = {},
}, directIni)
inicfg.save(config, directIni)

function save()
    inicfg.save(config, directIni)
end  

local elements = {
    main = {
        auto_tp = new.bool(config.main.auto_tp),
    },
    buffers = {
        name = new.char[126](),
        dt_vt = new.char[32](),
        rules = new.char[65536](),
        win_pl = new.char[32](),
        name = new.char[256](),
        text = new.char[65536](),
        delay = new.char[32](),
        vdt = new.char[32](),
        coord = new.char[32](),
    },
}

local Event = new.bool(false)

function main()
    while not isSampAvailable() do wait(0) end
    
    while true do
        wait(0)
        
    end
end
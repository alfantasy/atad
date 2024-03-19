require 'lib.moonloader'
script_properties('work-in-pause')

local imgui = require 'mimgui' -- инициализация интерфейса MoonLoader ImGUI
local encoding = require 'encoding' -- работа с кодировками
local sampev = require 'lib.samp.events' -- интеграция пакетов SA:MP и происходящих/исходящих/входящих т.д. ивентов
local mim_addons = require 'mimgui_addons' -- интеграция аддонов для интерфейса mimgui
local inicfg = require 'inicfg' -- работа с конфигом
local toast_ok, toast = pcall(import, 'lib/mimtoasts.lua') -- интеграция уведомлений.
local ffi = require 'ffi'
encoding.default = 'CP1251' -- смена кодировки на CP1251
u8 = encoding.UTF8 -- объявление кодировки U8 как рабочую, но в форме переменной (для интерфейса)

local new = imgui.new

local sw, sh = getScreenResolution()

imgui.OnInitialize(function()   
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(getWorkingDirectory() .. '/lib/mimgui/trebucbd.ttf', 24.0, _, glyph_ranges)
end)

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
-- encoding
function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end

function sampev.onServerMessage(color, text)
    chatlog = io.open(getFileName(), "r+")
    chatlog:seek("end", 0);
	chatTime = "[" .. os.date("*t").hour .. ":" .. os.date("*t").min .. ":" .. os.date("*t").sec .. "] "
    chatlog:write(enc(chatTime .. text) .. "\n")
    chatlog:flush()
	chatlog:close()
end

function string.split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end


local chat_logger_text = { }
local text_ru = { }
local accept_load_clog = false  
local chat_log_custom = new.bool(false)
local chat_find = new.char[65536]()
local tag = "{FFC900}[Chat-Logger] {FFFFFF}"
local logs_file = { }
local logs_value = { }
local name_log_select = ""
local read_file = false
local update_files = false
local combo_select = new.int(0)
local combo_selectable = imgui.new['const char*'][#logs_file](logs_file)

function getFilesInPath(path, ftype)
    local Files, SearchHandle, File = {}, findFirstFile(path.."/"..ftype)
    table.insert(Files, File)
    while File do File = findNextFile(SearchHandle) table.insert(Files, File) end
    return Files
end

function scan_logs_file()
    for line in lfs.dir(getWorkingDirectory().."/config/chatlog/") do
        if line == nil then
        elseif line:match(".+%.txt") then
            table.insert(logs_file,line:match("(.+)%.txt"))
        end
    end
end    

function getTxtFilesList(directory)
    local files = {}
    for file in io.popen('ls '..directory):lines() do
        if file:match("%.txt$") then
            table.insert(logs_file, file)
        end
    end
    combo_selectable = imgui.new['const char*'][#logs_file](logs_file)
end

function main()

    sampRegisterChatCommand('findfiles', function()
        print(getWorkingDirectory())
        files = getTxtFilesList(getWorkingDirectory() .. "/config/chatlog/")
        for i, k in ipairs(files) do  
            sampAddChatMessage("Индекс в таблице: " .. i .. " | Значение таблицы: " .. k, -1)
        end
    end)

    sampRegisterChatCommand('testing', function()
        sampAddChatMessage(getWorkingDirectory(), -1)
    end)

    sampRegisterChatCommand("createdirectory", function()
        if not doesDirectoryExist(getWorkingDirectory() .. "/config/chatlog") then  
            createDirectory(getWorkingDirectory() .. "/config/chatlog")
            toast.Show(u8"Создание базовой директории чат-логгера", toast.TYPE.INFO, 5)
        else 
            toast.Show(u8"Директория чат-логгера уже имеется.", toast.TYPE.WARN, 5)
        end  
    end)

    load_chat_log = lua_thread.create_suspended(loadChatLog)
    chatlogDirectory = getWorkingDirectory() .. "/config/chatlog"
    if not doesDirectoryExist(chatlogDirectory) then
        createDirectory(getWorkingDirectory() .. "/config/chatlog")
    end

    if toast_ok then 
        toast.Show(u8"Чат-логгер успешно запущен.", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'Чат-логгер успешно запущен. Обо всех ошибках писать @alfantasy (VK)', -1)
        sampAddChatMessage(tag .. 'Помощь по чат-логгеру (/chelp)', -1)
    end

    sampRegisterChatCommand("clog", function()
        chat_log_custom[0] = not chat_log_custom[0]
        getTxtFilesList(getWorkingDirectory() .. "/config/chatlog/")
    end)

    sampRegisterChatCommand('chelp', function()
        sampShowDialog(0, "{FFC900}Chat-Logger","{FFFFFF}Использование чат-логгера /clog","ОК", false)
    end)

    while true do  
        wait(0)

        local result, button, _, input = sampHasDialogRespond(65)
        if result then 
            if button == 1 then  
                os.remove(getWorkingDirectory() .. "/config/chatlog/" .. name_log_select)
                sampAddChatMessage(tag .. " Файл " .. name_log_select .. " был удален", -1)
                sampAddChatMessage(tag .. " Автоматически обновлю список файлов.", -1)
                logs_file = {}
                scan_logs_file()
            else 
                sampAddChatMessage(tag .. " Вы отказались от удаления файла " .. name_log_select, -1) 
            end    
        end

    end  
end

function readRussian()
    for key,v in pairs(chat_logger_text) do 
        local text = u8:encode(dec(v))
        table.insert(text_ru, text)
    end 
end        

function readChatlog_select()
    local file_check = assert(io.open(getWorkingDirectory() .. "/config/chatlog/" .. name_log_select, "r"))
    local t = file_check:read("*all")
    sampAddChatMessage(tag .. " Чтение выбранного файла.", -1)
    file_check:close() 
    t = t:gsub("{......}", "")
    local final_text = {}
    final_text = string.split(t, "\n")
    sampAddChatMessage(tag .. " Файл прочитан.", -1)
        return final_text
end

function readChatlog()
	local file_check = assert(io.open(getWorkingDirectory() .. "/config/chatlog/" .. os.date("!*t").day .. "-" .. os.date("!*t").month .. "-" .. os.date("!*t").year .. ".txt", "r"))
	local t = file_check:read("*all")
	sampAddChatMessage(tag .. " Чтение файла. ", -1)
	file_check:close()
	t = t:gsub("{......}", "")
	local final_text = {}
	final_text = string.split(t, "\n")
	sampAddChatMessage(tag .. " Файл прочитан. ", -1)
		return final_text
end

function loadChatLog()
	wait(6000)
	accept_load_clog = true
end

function getFileName()
    if not doesFileExist(getWorkingDirectory() .. "/config/chatlog/" .. os.date("!*t").day .. "-" .. os.date("!*t").month .. "-" .. os.date("!*t").year .. ".txt") then
        f = io.open(getWorkingDirectory() .. "/config/chatlog/" .. os.date("!*t").day .. "-" .. os.date("!*t").month .. "-" .. os.date("!*t").year .. ".txt","w")
        f:close()
        file = string.format(getWorkingDirectory() .. "/config/chatlog/" .. os.date("!*t").day .. "-" .. os.date("!*t").month .. "-" .. os.date("!*t").year .. ".txt")
        return file
    else
        file = string.format(getWorkingDirectory() .. "/config/chatlog/" .. os.date("!*t").day .. "-" .. os.date("!*t").month .. "-" .. os.date("!*t").year .. ".txt")
        return file  
    end
end

local chatlogFrame = imgui.OnFrame(
    function() return chat_log_custom[0] end, 
    function(player)  

        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2((sw / 4.5), sh / 4), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver)
        
        imgui.Begin(u8'Чат-логгер', chat_log_custom, imgui.WindowFlags.AlwaysAutoResize)

            if update_files == false then  
                imgui.Combo(u8"Список файлов", combo_select, combo_selectable, #logs_file)
            else 
                imgui.Text(u8"Обновление списка...")
            end
            imgui.Text(u8"Выбранным файлом является: ")
            imgui.SameLine()
            for key, v in pairs(logs_file) do  
                if combo_select[0] == key-1 then  
                    name_log_select = v
                    imgui.Text(name_log_select)
                end  
            end  
            if imgui.Button(u8"Прочитать") then  
                toast.Show(u8"Запущено чтение файла. \nОжидайте, когда файл весь декодируется.", toast.TYPE.WARN, 5)
                chat_logger_text = readChatlog_select()
                readRussian()
                read_file = true
            end  
            imgui.SameLine()
            if imgui.Button(u8"Очистка фрейма") then  
                toast.Show(u8"Окно фрейма чат-логгера очищено. \nНе забыли заскриншотить то, что хотели?", toast.TYPE.WARN, 5)
                text_ru = { }
                read_file = false  
            end  
            imgui.SameLine()
            if imgui.Button(u8"Удалить файл") then  
                sampShowDialog(65, "{FFC900}[Chat-Logger]", "Вы уверены в удалении файла: " .. name_log_select .. "?", "Удалить", "Отмена")
            end  
            imgui.SameLine()
            if imgui.Button(u8"Обновить список файлов") then  
                lua_thread.create(function()
                    update_files = true  
                    sampAddChatMessage(tag .. "Список файлов обновлен", -1)
                    wait(500)
                    logs_file = { }
                    getTxtFilesList(getWorkingDirectory() .. "/config/chatlog")
                    wait(1000)
                    update_files = false
                end)
            end
            imgui.Separator()
            if read_file == true then  
                imgui.InputText(u8"Поиск по файлу", chat_find, ffi.sizeof(chat_find))
                if ffi.string(chat_find) == "" then  
                    imgui.Text(u8"Введите текст для поиска \n")
                    imgui.Separator()
                    for key,v in pairs(text_ru) do 
                        imgui.Text(v)
                        if imgui.IsItemClicked() then
                            imgui.LogToClipboard()
                            imgui.LogText(v) -- копирование текста
                            imgui.LogFinish()
                        end
                    end 
                else 
                    for key,v in pairs(text_ru) do 
                        if v:find(ffi.string(chat_find)) ~= nil then  
                            imgui.Text(v)
                            if imgui.IsItemClicked() then
                                imgui.LogToClipboard()
                                imgui.LogText(v) -- копирование текста
                                imgui.LogFinish()
                            end
                        end 
                    end 
                end 
            end
        imgui.End() 
    end
)

function royalblue()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowPadding       = ImVec2(4, 6)
	style.WindowRounding      = 0
	style.ChildRounding = 3
	style.FramePadding        = ImVec2(5, 4)
	style.FrameRounding       = 2
	style.ItemSpacing         = ImVec2(3, 3)
	style.TouchExtraPadding   = ImVec2(0, 0)
	style.IndentSpacing       = 21
	style.ScrollbarSize       = 14
	style.ScrollbarRounding   = 16
	style.GrabMinSize         = 10
	style.GrabRounding        = 5
	style.WindowTitleAlign    = ImVec2(0.50, 0.50)
	style.ButtonTextAlign     = ImVec2(0, 0)

	colors[clr.Text] = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled] = ImVec4(0.60, 0.60, 0.60, 1.00)
	colors[clr.WindowBg] = ImVec4(0.11, 0.10, 0.11, 1.00)
	colors[clr.ChildBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PopupBg] = ImVec4(0.30, 0.30, 0.30, 1.00)
	colors[clr.Border] = ImVec4(0.86, 0.86, 0.86, 1.00)
	colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.FrameBg] = ImVec4(0.21, 0.20, 0.21, 0.60)
	colors[clr.FrameBgHovered] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.FrameBgActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.TitleBg] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.TitleBgActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.MenuBarBg] = ImVec4(0.01, 0.26, 0.37, 1.00)
	colors[clr.ScrollbarBg] = ImVec4(0.00, 0.46, 0.65, 0.00)
	colors[clr.ScrollbarGrab] = ImVec4(0.00, 0.46, 0.65, 0.44)
	colors[clr.ScrollbarGrabHovered] = ImVec4(0.00, 0.46, 0.65, 0.74)
	colors[clr.ScrollbarGrabActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.CheckMark] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.SliderGrab] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.SliderGrabActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.Button] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.ButtonHovered] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.ButtonActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.Header] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.HeaderHovered] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.HeaderActive] = ImVec4(0.00, 0.46, 0.65, 1.00)
	colors[clr.ResizeGrip] = ImVec4(1.00, 1.00, 1.00, 0.30)
	colors[clr.ResizeGripHovered] = ImVec4(1.00, 1.00, 1.00, 0.60)
	colors[clr.ResizeGripActive] = ImVec4(1.00, 1.00, 1.00, 0.90)
	colors[clr.PlotLines] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PlotLinesHovered] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PlotHistogram] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.PlotHistogramHovered] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.TextSelectedBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.ModalWindowDimBg] = ImVec4(0.00, 0.00, 0.00, 0.00)
end
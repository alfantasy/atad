require 'lib.moonloader'
require 'module.commands'

local dlstatus = require('moonloader').download_status
local fflags = require('moonloader').font_flag
local imgui = require 'mimgui' -- инициализация интерфейса Moon ImGUI
local encoding = require 'encoding' -- работа с кодировками
local sampev = require 'lib.samp.events' -- интеграция пакетов SA:MP и происходящих/исходящих/входящих т.д. ивентов
local mim_addons = require 'mimgui_addons' -- интеграция аддонов для интерфейса mimgui
local fa = require 'fAwesome6_solid' -- работа с иконами на основе FontAwesome 6
local inicfg = require 'inicfg' -- работа с конфигом
local memory = require 'memory' -- работа с памятью напрямую
local ffi = require 'ffi' -- глобальная работа с переменными игры
local http = require('socket.http') -- работа с запросами HTTP
local ltn12 = require('ltn12') -- работа с файловой системой
local atlibs = require 'libsfor' -- инициализация библиотеки InfoSecurity для AT (libsfor)
local toast_ok, toast = pcall(import, 'lib/mimtoasts.lua') -- интеграция уведомлений.
local question_ok, QuestionAnswer = pcall(import, 'QuestionAnswer.lua') -- одновременная интеграция редакции файлов
local automute_ok, AutoMuteLib = pcall(import, 'module/automute.lua') -- интеграция автомута
local other_ok, plother = pcall(import, 'module/other.lua') -- интеграция дополнительных функций
encoding.default = 'CP1251' -- смена кодировки на CP1251
u8 = encoding.UTF8 -- объявление кодировки U8 как рабочую, но в форме переменной (для интерфейса)

-- ## Блок текстовых переменных ## --
local tag = "{00BFFF} [AT] {FFFFFF}" -- локальная переменная, которая регистрирует тэг AT
-- ## Блок текстовых переменных ## --

-- ## Контролирование версий AT. Скачивание, ссылки и директории. ## --
local urls = {
	['main'] = "https://raw.githubusercontent.com/alfantasy/atad/main/AdminTool.lua",
	['libsfor'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/libsfor.lua',
	['report'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/QuestionAnswer.lua',
	['upat'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/upat.ini',
	['clogger'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/clogger.lua',
	['automute'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/module/automute.lua',
	['commands'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/module/commands.lua',
}
local paths = {
	['main'] = getWorkingDirectory() .. '/AdminTool.lua',
	['libsfor'] = getWorkingDirectory() .. '/lib/libsfor.lua',
	['report'] = getWorkingDirectory() .. '/QuestionAnswer.lua',
	['upat'] = getWorkingDirectory() .. '/upat.ini',
	['clogger'] = getWorkingDirectory() .. '/clogger.lua',
	['automute'] = getWorkingDirectory() .. '/module/automute.lua',
	['commands'] = getWorkingDirectory() .. '/module/commands.lua',
}

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

local version_control = 9
local version_text = '2.2.1'
-- ## Контролирование версий AT. Скачивание, ссылки и директории. ## --

-- ## Система конфига и переменных VARIABLE ## --
local new = imgui.new

local directIni = 'AdminTool/settings.ini'
local eventsIni = 'AdminTool/events.ini'

local config = inicfg.load({
    settings = {
        custom_recon = false,
		autologin = false,
		password_to_login = '',
		auto_online = false,
		adminforms = false, 
		autoforms = false,
		render_date = false,
    },
}, directIni)
inicfg.save(config, directIni)

local cfgevents = inicfg.load({
    bind_name = {},
    bind_text = {},
    bind_vdt = {},
    bind_coords = {},
}, eventsIni)
inicfg.save(cfgevents, eventsIni)

function EventsSave()
	inicfg.save(cfgevents, eventsIni)
	toast.Show(u8'Сохранение файла INI от ATEvents прошло успешно.', toast.TYPE.OK, 5)
	return true
end

function save()
    inicfg.save(config, directIni)
    toast.Show(u8"Сохранение настроек прошло успешно.", toast.TYPE.OK, 5)
end

local elements = {
    imgui = {
        main_window = new.bool(false),
        recon_window = new.bool(false),
        menu_selectable = new.int(0),
        btn_size = imgui.ImVec2(70,0),
		selectable = 0,
        stream = new.char[65536](),
        input_word = new.char[500](),
		bt_size = imgui.ImVec2(220,50),
		bt_size_recon = imgui.ImVec2(150,50)
    },
    boolean = {
		adminforms = new.bool(config.settings.adminforms),
		autoforms = new.bool(config.settings.autoforms),
        recon = new.bool(config.settings.custom_recon),
		autologin = new.bool(config.settings.autologin),
		auto_online = new.bool(config.settings.auto_online),
		render_date = new.bool(config.settings.render_date),
    },
	buffers = {
		password = new.char[50](config.settings.password_to_login),
		name = new.char[126](),
        rules = new.char[65536](),
        win_pl = new.char[32](),
        name = new.char[256](),
        text = new.char[65536](),
        vdt = new.char[32](),
        coord = new.char[32](),
	},
}

local show_password = false -- показать/скрыть пароль в интерфейсе
local control_spawn = false -- контроль спавна. Активируется при запуске скрипта

local access_file = 'AdminTool/accessadm.ini'
local main_access = inicfg.load({
	settings = {
		ban = false,
		mute = false, 
		jail = false,
		makeadmin = false,
		agivemoney = false,
	},
}, access_file)
inicfg.save(main_access, access_file)
-- ## Система конфига и переменных VARIABLE ## --

-- ## mimgui ## --
function Tooltip(text)
    if imgui.IsItemClicked() then
        imgui.BeginTooltip()
        imgui.Text(u8(text))
        imgui.EndTooltip()
    end 
end

imgui.OnInitialize(function()   
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(getWorkingDirectory() .. '/lib/mimgui/trebucbd.ttf', 24.0, _, glyph_ranges)
	fa.Init(24)
	imgui.GetIO().IniFilename = nil
end)

local sw, sh = getScreenResolution()
-- ## mimgui ## --

-- ## Блок переменных связанных с CustomReconMenu ## --
local info_to_player = {}
local recon_info = { "Здоровье: ", "Броня: ", "ХП машины: ", "Скорость: ", "Пинг: ", "Патроны: ", "Выстрел: ", "Тайминг выстрела: ", "Время в АФК: ", "P.Loss: ", "Уровень VIP: ", "Пассивный режим: ", "Турбо-режим: ", "Коллизия: ", 'Дрифт-мод: '}
local right_recon = new.bool(true)
local accept_load_recon = false 
local recon_id = -1
local control_to_player = false

local ids_recon = {}
local text_recon = {'STATS', 'MUTE', 'KICK', 'BAN', 'JAIL', 'CLOSE'}
for i = 190, 236 do 
	table.insert(ids_recon, i, #ids_recon+1)
end
local refresh_button_textdraw = 0
local info_textdraw_recon = 0

local select_recon = 0 
local recon_punish = 0
-- ## Блок переменных связанных с CustomReconMenu ## --

local reasons = { 
	"/mute","/jail","/iban","/ban","/kick","/skick","/sban", "/muteakk", "/offban", "/banakk"
}

local lc_lvl, lc_adm, lc_color, lc_nick, lc_id, lc_text

function main()

    if toast_ok then 
        toast.Show(u8"AdminTool инициализирован.\nДля работы с интерфейсом, введите: /tool", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'AdminTool успешно инициализирован. Активация: /tool', -1)
        print(tag .. "Отказ в подгрузке уведомлений")
    end

	local response_update_check = downloadFile(urls['upat'], paths['upat'])
	if response_update_check then 
		local response = http.request(urls['main']) 
		local currentVersionFile = io.open(paths['main'], 'r')
		local currentVersion = currentVersionFile:read("*a")
		currentVersionFile:close()
		updateIni = inicfg.load(nil, paths['upat'])
		if tonumber(updateIni.info.version) > version_control and response ~= currentVersion then  
			if toast_ok then  
				toast.Show(u8'Доступно обновление.\nAT начинает обновление автоматически.', toast.TYPE.INFO, 5)
			else 
				print(tag .. 'Отказ в подгрузке уведомлений.')
				sampAddChatMessage(tag .. 'Доступно обновление. AT начинает автообновление!', -1)
			end 
			
			local response_main = downloadFile(urls['main'], paths['main'])
			if response_main then  
				sampAddChatMessage(tag .. 'Основной скрипт АТ скачен.', -1)
			end  
			local response_lib = downloadFile(urls['libsfor'], paths['libsfor'])
			if response_lib then  
				sampAddChatMessage(tag .. 'Библиотека к АТ успешно скачена.', -1)
			end  
			local response_questans = downloadFile(urls['report'], paths['report'])
			if response_questans then  
				sampAddChatMessage(tag .. 'Скрипт для репортов скачен.', -1)
			end  
			local response_clogger = downloadFile(urls['clogger'], paths['clogger'])
			if response_clogger then  
				sampAddChatMessage(tag .. 'Чат-логгер скачен', -1)
			end
			local response_automute = downloadFile(urls['automute'], paths['automute'])
			if response_automute then
				sampAddChatMessage(tag .. 'Автомут скачен', -1)
			end
			local response_commands = downloadFile(urls['commands'], paths['commands'])
			if response_commands then
				sampAddChatMessage(tag .. 'Библиотека команд скачена', -1)
			end
			sampAddChatMessage(tag .. 'Начинаю перезагрузку скриптов!', -1)
			reloadScripts()
		else 
			if toast_ok then  
				toast.Show(u8'У Вас установлена актуальная версия АТ.\nВерсия AT: ' .. version_text, toast.TYPE.INFO, 5)
			else 
				print(tag .. 'Отказ в подгрузке уведомлений.')
				sampAddChatMessage(tag .. 'У Вас установлена актуальная версия АТ. Версия АТ: ' .. version_text, -1)
			end
		end  
		--os.remove(paths['upat'])
	end

    load_recon = lua_thread.create_suspended(loadRecon)
	send_online = lua_thread.create_suspended(drawOnline)
	draw_date = lua_thread.create_suspended(drawDate)
	send_online:run()
	draw_date:run()

	sampRegisterChatCommand('pac', function()
		sampAddChatMessage(tag .. 'Сканирование доступов. Либо в ручную, либо при AutoLogin', -1)
		sampSendChat('/access')
	end)

	for key in pairs(cmd_massive) do  
		sampRegisterChatCommand(key, function(arg)
			if #arg > 0 then  
				if cmd_massive[key].cmd == '/iban' or cmd_massive[key].cmd == '/ban' then  
					if main_access.settings.ban then  
						sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
						sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
						sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					else 
						sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					end
				end
				if cmd_massive[key].cmd == '/siban' then
					if main_access.settings.ban then
						sampSendChat(cmd_massive[key].cmd .. '' .. arg .. ' ' .. cmd_massive[key].time .. ' ' .. cmd_massive[key].reason)
					else
						sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					end
				end
				if cmd_massive[key].cmd == '/mute' then
					if main_access.settings.mute then
						if arg:find('(%d+) (%d+)') then
							id_punish, multiply_punish = arg:match('(%d+) (%d+)')
							sampSendChat(cmd_massive[key].cmd .. " " .. id_punish .. " " .. tostring(tonumber(cmd_massive[key].time)*tonumber(multiply_punish)) .. " " .. cmd_massive[key].reason .. " x" .. multiply_punish)
						else
							sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
						end
					else
						sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					end
				end
				if cmd_massive[key].cmd == '/rmute' then
					if main_access.settings.mute then
						if arg:find('(%d+) (%d+)') then
							id_punish, multiply_punish = arg:match('(%d+) (%d+)')
							sampSendChat(cmd_massive[key].cmd .. " " .. id_punish .. " " .. tostring(tonumber(cmd_massive[key].time)*tonumber(multiply_punish)) .. " " .. cmd_massive[key].reason .. " x" .. multiply_punish)
						else
							sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
						end
					else
						sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					end
				end
				if cmd_massive[key].cmd == '/jail' then  
					if main_access.settings.jail then
						if arg:find('(%d+) (%d+)') then
							id_punish, multiply_punish = arg:match('(%d+) (%d+)')
							sampSendChat(cmd_massive[key].cmd .. " " .. id_punish .. " " .. tostring(tonumber(cmd_massive[key].time)*tonumber(multiply_punish)) .. " " .. cmd_massive[key].reason .. " x" .. multiply_punish)
						else
							sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
						end
					else
						sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
					end
				end
				if cmd_massive[key].cmd == '/kick' then 
					sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].reason)
				end 
				if cmd_massive[key].cmd == '/jailakk' or cmd_massive[key].cmd == '/offban' or cmd_massive[key].cmd == '/muteakk' or cmd_massive[key].cmd == '/rmuteakk' then  
					sampSendChat(cmd_massive[key].cmd .. " " .. arg .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
				end
			end
		end)
	end
    -- ## Регистрация вспомогательных команд ## --
    sampRegisterChatCommand("u", cmd_u)
	sampRegisterChatCommand("uu", cmd_uu)
	sampRegisterChatCommand("uj", cmd_uj)
	sampRegisterChatCommand("as", cmd_as)
	sampRegisterChatCommand("stw", cmd_stw)
	sampRegisterChatCommand("ru", cmd_ru)
	sampRegisterChatCommand('rcl', function()
        toast.Show(u8"Очистка чата началась.", toast.TYPE.WARN)
        memory.fill(sampGetChatInfoPtr() + 306, 0x0, 25200)
        memory.write(sampGetChatInfoPtr() + 306, 25562, 4, 0x0)
        memory.write(sampGetChatInfoPtr() + 0x63DA, 1, 1)
    end)
	sampRegisterChatCommand('spp', function()
        local user_to_stream = playersToStreamZone()
        for _, v in pairs(user_to_stream) do 
            sampSendChat('/aspawn ' .. v)
        end
    end)
	sampRegisterChatCommand("aheal", function(id)
		lua_thread.create(function()
			sampSendClickPlayer(id, 0)
			wait(200)
			sampSendDialogResponse(500, 1, 4)
			wait(200)
			sampSendDialogResponse(500, 0, nil)
		end)
	end)
	sampRegisterChatCommand("akill", function(id)
		lua_thread.create(function()
			sampSendClickPlayer(id, 0)
			wait(200)
			sampSendDialogResponse(500, 1, 7)
			wait(200)
			sampSendDialogResponse(48, 1, _, "kill")
			wait(200)
			sampSendDialogResponse(48, 0, nil)
		end)
	end)
	sampRegisterChatCommand('sl', function(id)
		sampSendChat('/slap ' .. id)
	end)
	sampRegisterChatCommand('gh', function(id)
		sampSendChat('/gethere ' .. id)
	end)
	sampRegisterChatCommand('ib', function(id)
		sampSendChat('/iunban ' .. id)
	end)
	sampRegisterChatCommand('ubi', function(id)
		sampSendChat('/unbanip ' .. id)
	end)
	sampRegisterChatCommand('auj', function(nick)
		sampSendChat('/jailakk ' .. nick .. ' 5 Ошибка/Разджаил')
	end)
	sampRegisterChatCommand('au', function(nick)
		sampSendChat('/muteakk ' .. nick .. ' 5 Ошибка/Размут')
	end)
	sampRegisterChatCommand('aru', function(nick)
		sampSendChat('/rmuteakk ' .. nick .. ' 5 Ошибка/Размут')
	end)
    -- ## Регистрация вспомогательных команд ## --    

	sampRegisterChatCommand('checksh', function()
		sampAddChatMessage(tag .. "Текущее разрешение: X - " .. sw .. " | Y - " .. sh, -1)
		sampAddChatMessage(tag .. "Данная функция предназначена для debug разрешений окон граф.интерфейса", -1)
	end)

    sampRegisterChatCommand("tool", function()
        elements.imgui.main_window[0] = not elements.imgui.main_window[0]
        elements.imgui.menu_selectable[0] = 0
    end)

	sampRegisterChatCommand("al", function(id)
		sampSendChat("/ans " .. id .. " Уважаемый адмиинистратор! Вы забыли ввести /alogin")
		sampSendChat("/ans " .. id .. " Пожалуйста, введите /alogin в течении пяти минут.")
	end)

    while true do
        wait(0)

		if control_spawn and elements.boolean.autologin[0] then  
			sampAddChatMessage(tag .. "AutoLogin работает в течении 15 секунд после спавна.", -1)
			sampAddChatMessage(tag .. "Ожидайте...", -1)
			wait(15000)
			sampSendChat('/alogin ' .. u8:decode(config.settings.password_to_login))
			control_spawn = false
			sampSendChat('/access')
		end

        -- if isKeyJustPressed(VK_RBUTTON) and not sampIsChatInputActive() and not sampIsDialogActive() then
		-- 	imgui.ShowCursor = not imgui.ShowCursor
		-- 	wait(600)
        -- end

        if not sampIsPlayerConnected(recon_id) then  
            elements.imgui.recon_window[0] = false  
            recon_id = -1 
        end
        
    end
end

-- ## Блок функций к вспомогательным командам ## --
function cmd_u(arg)
	sampSendChat("/unmute " .. arg)
end  

function cmd_uu(arg)
    lua_thread.create(function()
        sampSendChat("/unmute " .. arg)
        
        sampSendChat("/ans " .. arg .. " Извиняемся за ошибку, наказание снято. Приятной игры")
    end)
end

function cmd_uj(arg)
    lua_thread.create(function()
        sampSendChat("/unjail " .. arg)
        
        sampSendChat("/ans " .. arg .. " Извиняемся за ошибку, наказание снято. Приятной игры")
    end)
end

function cmd_stw(arg)
	sampSendChat("/setweap " .. arg .. " 38 5000 ")
end  

function cmd_as(arg)
	sampSendChat("/aspawn " .. arg)
end

function cmd_ru(arg)
    lua_thread.create(function()
	    sampSendChat("/unrmute " .. arg)
	    sampSendChat("/ans " .. arg .. " Извиняемся за ошибку, наказание снято. Приятной игры.")
    end)
end
-- ## Блок функций к вспомогательным командам ## --


-- ## Автоматическая выдача /online ## --
function drawOnline()
    if elements.boolean.auto_online[0] then 
        while true do 
			sampAddChatMessage(tag .. "Запуск переменной AutoOnline. Ожидайте выдачи.", -1)
			wait(62000)
			sampSendChat("/online")
			wait(100)
			local c = math.floor(sampGetPlayerCount(false) / 10)
			sampSendDialogResponse(1098, 1, c - 1)
			sampSendDialogResponse(1098, 0, -1)
			wait(650)
            wait(1)
        end	
    end
end	
-- ## Автоматическая выдача /online ## --

-- ## Блок функций для пакетов SA:MP ## --
function sampev.onServerMessage(color, text)
	local check_string = string.match(text, "[^%s]+")

	lc_lvl, lc_adm, lc_color, lc_nick, lc_id, lc_text = text:match("%[A%-(%d+)%] %((.+){(.+)}%) (.+)%[(%d+)%]: {FFFFFF}(.+)")
	--lc_lvl, lc_nick, lc_id, lc_text = text:match("%[A%-(%d+)%](.+)%[(%d+)%]: {FFFFFF}(.+)")

	if text:find("%[A%] Администратор (.+)%[(%d+)%] %(%d+ level%) авторизовался в админ панели") then  
		nick, _ = text:match("%[A%] Администратор (.+)%[(%d+)%] %(%d+ level%) авторизовался в админ панели")
		if atlibs.getMyNick() == nick then  
			sampAddChatMessage(tag .. 'Начнем тест', -1)
			sampSendChat('/access')
		end  
	end

	if text:find("Вы успешно авторизовались!") then  
		if elements.boolean.autologin[0] then 
        	control_spawn = true
		end
    	return true
    end
    if text:find("Вы уже авторизованы как администратор") then  
		if elements.boolean.autologin[0] then 
			control_spawn = false   
		end
    	return true
    end
	if text:find("Необходимо авторизоваться!") then  
		if elements.boolean.autologin[0] then  
			control_spawn = true  
		end  
		return true  
	end 

	function start_forms()
		sampRegisterChatCommand('fac', function()
			lua_thread.create(function()
				sampSendChat('/a AT - Форма принята!')
				wait(500)
				sampSendChat(''..adm_form)
				adm_form = ''
			end)
		end)
		sampRegisterChatCommand('fn', function()
			sampSendChat('/a AT - Форма отклонена!')
			adm_form = ''
		end)
	end

	if elements.boolean.adminforms[0] and lc_text ~= nil then
		for k, v in ipairs(reasons) do  
			if lc_text:match(v) ~= nil then  
				if lc_text:find("/(.+) (%d+) (%d+) (.+)") or lc_text:find('/(.+) (.+) (%d+) (.+)') then  
					if lc_text:find(lc_nick) then  
						adm_form = lc_text 
					else 
						adm_form = lc_text .. ' // ' .. lc_nick  
					end 
				else 
					adm_form = ''
				end
				if #adm_form > 1 then 
					toast.Show(u8'Пришла форма! \n /fac - принять | /fn - отклонить', toast.TYPE.INFO, 5)
					sampAddChatMessage(tag .. 'Форма: ' .. adm_form, -1)
					if elements.boolean.autoforms[0] and not isGamePaused() and not isPauseMenuActive() then  
						lua_thread.create(function()
							sampSendChat('/a AT - Форма принята!')
							wait(500)
							sampSendChat(''..adm_form)
							adm_form = ''
						end) 
					elseif not isGamePaused() and not isPauseMenuActive() then  
						start_forms()
					end 
				end
			end 
		end 
	end 
	-- ## Работа с формами. Функция находится в полноценном тестировании.

	local check_nick, check_id, basic_color, check_text = string.match(text, "(.+)%((.+)%): {(.+)}(.+)") -- захват основной строчки чата и разбития её на объекты
end
-- ## Блок функций для пакетов SA:MP ## --


-- ## Функции для стабильной работы ## --
function textSplit(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

function playersToStreamZone()
	local peds = getAllChars()
	local streaming_player = {}
	local _, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	for key, v in pairs(peds) do
		local result, id = sampGetPlayerIdByCharHandle(v)
		if result and id ~= pid and id ~= tonumber(recon_id) then
			streaming_player[key] = id
		end
	end
	return streaming_player
end
-- ## Функции для стабильной работы ## --

-- ## Загрузка системы рекона ## -- 
function loadRecon()
    wait(3000)
    accept_load_recon = true
end
function sampev.onTextDrawSetString(id, text) 
    if id == info_textdraw_recon and elements.boolean.recon[0] then  
        info_to_player = textSplit(text, "~n~")
    end
end

function sampev.onSendCommand(command)
    id = string.match(command, "/re (%d+)")
	if elements.boolean.recon[0] then
		if id ~= nil then  
			control_to_player = true  
			if control_to_player then  
				load_recon:run()
				accept_load_recon = false
				elements.imgui.recon_window[0] = true 
			end 
			recon_id = id
		end
		if command == '/reoff' then  
			control_to_player = false  
			elements.imgui.recon_window[0] = false  
			recon_id = -1
			select_recon = 0
		end
	end
end


-- ## Ивент, отвечающий за диалоги. В частности, здесь полностью прописан захват доступов от команд.
function sampev.onShowDialog(id, style, title, button1, button2, text)
	if title:find(atlibs.getMyNick()) and id == 8991 then  
		lua_thread.create(function()
		text = atlibs.textSplit(text, '\n')
		newtext = nil 
		for i, v in ipairs(text) do  
			if v:find('Все виды банов') and v:find('Имеется') then  
				main_access.settings.ban = true
				inicfg.save(main_access, access_file)
			elseif v:find('Выдачу мута') and v:find('Имеется') then  
				main_access.settings.mute = true
				inicfg.save(main_access, access_file)
			elseif v:find('Выдачу тюрьмы') and v:find('Имеется') then  
				main_access.settings.jail = true
				inicfg.save(main_access, access_file)
			end
			if v:find('Все виды банов') and v:find('Отсутствует') then  
				main_access.settings.ban = false
				inicfg.save(main_access, access_file)
			elseif v:find('Выдачу мута') and v:find('Отсутствует') then  
				main_access.settings.mute = false
				inicfg.save(main_access, access_file)
			elseif v:find('Выдачу тюрьмы') and v:find('Отсутствует') then  
				main_access.settings.jail = false
				inicfg.save(main_access, access_file)
			end
		end
		sampAddChatMessage(tag .. '/access просканирован. Для просмотра своих /access, выключите повторный сканинг в настройках.', -1)
		wait(1)
		sampSendDialogResponse(8991, 0, -1)
		end)
	end
end

function sampev.onShowTextDraw(id, data)
    if elements.boolean.recon[0] then 
		if data.text:find('~g~::Health:~n~') then  
			return false
		end
		if data.text:find('REFRESH') then  
			refresh_button_textdraw = id  
			return false  
		end
		if data.text:find('(%d+) : (%d+)') then  
			info_textdraw_recon = id  
			return false
		end
		for _, v in pairs(text_recon) do  
			if data.text:find(v) then  
				if id ~= 244 then 
					return false  
				end
			end 
		end
		if data.text:find("(%d+)") then  
			if id == 2052 then  
				return false  
			end  
		end
		if ids_recon[id] then  
			return false 
		end
		if data.text:find('CLOSE') or id == 244 then  
			return true  
		end
    end
end
-- ## Загрузка системы рекона ## -- 

-- ## Рендер Date and Time ## --
function drawDate()
	font = renderCreateFont('Arial', 20, fflags.BOLD)
	if elements.boolean.render_date[0] then  
		while true do  
			renderFontDrawText(font,'{FFFFFF}' .. (os.date("%d.%m.%y | %H:%M:%S", os.time())),10,sh-30,0xCCFFFFFF)

			wait(1)
		end
	end
end
-- ## Рендер Date and Time ## --


local ReconWindow = imgui.OnFrame(
    function() return elements.imgui.recon_window[0] end, 
    function(player)
        
        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 3, sh / 1), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(100, 300), imgui.Cond.FirstUseEver)

        imgui.LockPlayer = false  

        imgui.Begin("reconmenu", elements.imgui.recon_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize)
            if control_to_player then  
                if imgui.Button(u8"Заспавнить", elements.imgui.bt_size_recon) then  
                    sampSendChat('/aspawn ' .. recon_id)
                end
				imgui.SameLine()
                if imgui.Button(u8"Обновить", elements.imgui.bt_size_recon) then  
                    -- sampSendClickTextdraw(156)
					sampSendClickTextdraw(refresh_button_textdraw)
                end
				imgui.SameLine()
                if imgui.Button(u8"Слапнуть", elements.imgui.bt_size_recon) then  
                    sampSendChat("/slap " .. recon_id)
                end
				imgui.SameLine()
                if imgui.Button(u8"Заморозить\n/Разморозить", imgui.ImVec2(150,60)) then  
                    sampSendChat("/freeze " .. recon_id)
                end
				imgui.SameLine()
                if imgui.Button(u8"Выйти", elements.imgui.bt_size_recon) then
                    sampSendChat("/reoff ")
                    control_to_player = false
                    elements.imgui.recon_window[0] = false
                end
				imgui.SetCursorPosX(imgui.GetWindowWidth() - 650)
				if imgui.Button(u8"Посадить", elements.imgui.bt_size_recon) then  
					select_recon = 1 
					recon_punish = 1
				end
				imgui.SameLine()
				if imgui.Button(u8"Забанить", elements.imgui.bt_size_recon) then  
					select_recon = 1
					recon_punish = 2
				end
				imgui.SameLine()
				if imgui.Button(u8"Кикнуть", elements.imgui.bt_size_recon) then  
					select_recon = 1
					recon_punish = 3
				end
            end
        imgui.End()

        if right_recon[0] then  
            imgui.SetNextWindowPos(imgui.ImVec2(sw - 200, sh - 310), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(350, 550), imgui.Cond.FirstUseEver)

            imgui.Begin(u8"Информация об игроке", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.MenuBar)
				if accept_load_recon then
					if not sampIsPlayerConnected(recon_id) then 
						recon_nick = '-'
					else
						recon_nick = sampGetPlayerNickname(recon_id)
					end					
					imgui.BeginMenuBar()
						if imgui.Button(fa.USER_CHECK) then  
							select_recon = 0 
						end  
						if imgui.Button(fa.BAN) then  
							select_recon = 1 
						end
					imgui.EndMenuBar()
					if select_recon == 0 then
						imgui.Text(u8"Игрок: ")
						imgui.Text(recon_nick)
						imgui.SameLine()
						imgui.Text('[' .. recon_id .. ']')
						imgui.Separator()
						for key, v in pairs(info_to_player) do  
							if key == 1 then  
								imgui.Text(u8:encode(recon_info[1]) .. " " .. info_to_player[1])
								mim_addons.BufferingBar(tonumber(info_to_player[1])/100, imgui.ImVec2(imgui.GetWindowWidth()-10, 10), false)
							end
							if key == 2 and tonumber(info_to_player[2]) ~= 0 then
								imgui.Text(u8:encode(recon_info[2]) .. " " .. info_to_player[2])
								mim_addons.BufferingBar(tonumber(info_to_player[2])/100, imgui.ImVec2(imgui.GetWindowWidth()-10, 10), false)
							end
							if key == 3 and tonumber(info_to_player[3]) ~= -1 then
								imgui.Text(u8:encode(recon_info[3]) .. " " .. info_to_player[3])
								mim_addons.BufferingBar(tonumber(info_to_player[3])/1000, imgui.ImVec2(imgui.GetWindowWidth()-10, 10), false)
							end
							if key == 4 then
								imgui.Text(u8:encode(recon_info[4]) .. " " .. info_to_player[4])
								local speed, const = string.match(info_to_player[4], "(%d+) / (%d+)")
								if tonumber(speed) > tonumber(const) then
									speed = const
								end
								mim_addons.BufferingBar((tonumber(speed)*100/tonumber(const))/100, imgui.ImVec2(imgui.GetWindowWidth()-10, 10), false)
							end
							if key ~= 1 and key ~= 2 and key ~= 3 and key ~= 4 then
								if key == 11 then  
									local lvl = string.match(info_to_player[11], "(%d+)")
									local str_lvl = ''
									if tonumber(lvl) == 0 then
										str_lvl = u8'Не имеется.'
									elseif tonumber(lvl) == 1 then
										str_lvl = u8'Обычный'
									elseif tonumber(lvl) == 2 then
										str_lvl = u8'Премиум'
									elseif tonumber(lvl) == 3 then
										str_lvl = u8'Diamond'
									elseif tonumber(lvl) == 4 then
										str_lvl = u8'Platinum'
									elseif tonumber(lvl) == 5 then
										str_lvl = u8'Personal'
									end
									imgui.Text(u8:encode(recon_info[key]) .. " " .. str_lvl)
								elseif key == 15 then  
									local chkdrv = string.match(info_to_player[15], '(.+)')
									if chkdrv == 'DISABLED' then  
										imgui.Text(u8:encode(recon_info[key]) .. " " .. u8'Отключено')
									elseif chkdrv == 'ENABLED' then
										imgui.Text(u8:encode(recon_info[key]) .. " " .. u8'Включено')
									end
								else 
									imgui.Text(u8:encode(recon_info[key]) .. " " .. info_to_player[key])
								end
							end
						end
					elseif select_recon == 1 then  
						if recon_punish == 0 then  
							imgui.Text(u8'Выберите нужное действие')
						end  
						if recon_punish == 1 then  
							imgui.Text(u8'Зарегистрированные наказания')
							for key in pairs(cmd_massive) do  
								if cmd_massive[key].cmd == "/jail" then  
									if imgui.Button(u8(cmd_massive[key].reason)) then  
										if main_access.settings.jail then
											sampSendChat(cmd_massive[key].cmd .. " " .. recon_id .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
										else 
											sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. recon_id .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
										end
									end 
								end 
							end
						end 
						if recon_punish == 2 then  
							imgui.Text(u8'Зарегистрированные наказания')
							for key in pairs(cmd_massive) do  
								if cmd_massive[key].cmd == "/ban" or cmd_massive[key].cmd == '/iban' then  
									if imgui.Button(u8(cmd_massive[key].reason)) then  
										if main_access.settings.ban then
											sampSendChat("/ans " .. recon_id .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
											sampSendChat("/ans " .. recon_id .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
											sampSendChat(cmd_massive[key].cmd .. " " .. recon_id .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
										else 
											sampSendChat('/a ' .. cmd_massive[key].cmd .. " " .. recon_id .. " " .. cmd_massive[key].time .. " " .. cmd_massive[key].reason)
										end
										recon_id = -1
									end 
								end 
							end
						end 
						if recon_punish == 3 then  
							imgui.Text(u8'Зарегистрированные наказания')
							for key in pairs(cmd_massive) do  
								if cmd_massive[key].cmd == "/kick" then  
									if imgui.Button(u8(cmd_massive[key].reason)) then  
										sampSendChat(cmd_massive[key].cmd .. " " .. recon_id .. " " .. cmd_massive[key].reason)
										recon_id = -1
									end 
								end 
							end
						end 
					end
				else 
					imgui.Text(u8'Загрузка...')
				end
            imgui.End()
        end
    end
)

local helloText = [[
Мобильный AT для работы администрации. 
Почти все пункты, используемые здесь были переведены с ПК версии.
AT был сделан alfantasyz. Группа разработчика: https://vk.com/infsy
]]

local textToMenuSelectableAutoMute = [[
Данное подокно позволяет настроить автомут под свои нужды. 
Вы можете изменить нужные файлы, 
посредством выбора необходимых файлов и внесении туда слов.
]]

local MainWindowAT = imgui.OnFrame( 
	function() return elements.imgui.main_window[0] end, 
	function (player) 

		royalblue()

		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(1280, 600), imgui.Cond.FirstUseEver)

		imgui.Begin(fa.SERVER .. ' [AT for Android]', elements.imgui.main_window)
			imgui.BeginChild('##MenuSelectable', imgui.ImVec2(250, 570), true)
				if imgui.Button(fa.HOUSE .. u8" Дом. страница", elements.imgui.bt_size) then  
					elements.imgui.menu_selectable[0] = 0
				end
				if imgui.Button(fa.USER_GEAR .. u8' Осн. функции', elements.imgui.bt_size) then
					elements.imgui.menu_selectable[0] = 1
				end
				if imgui.Button(fa.CROSSHAIRS .. u8' Трейсер пуль', elements.imgui.bt_size) then
					elements.imgui.menu_selectable[0] = 8
				end
				if imgui.Button(fa.BOOK .. u8' Автомут', elements.imgui.bt_size) then  
					elements.imgui.menu_selectable[0] = 2
				end  
				if imgui.Button(fa.LIST_OL .. u8' КМД/Наказания', elements.imgui.bt_size) then
					elements.imgui.menu_selectable[0] = 3 
				end
				if imgui.Button(fa.TABLE_LIST .. u8' Флуды', elements.imgui.bt_size) then  
					elements.imgui.menu_selectable[0] = 4 
				end
				if imgui.Button(fa.LIST .. u8' Биндер /ans', elements.imgui.bt_size) then  
					elements.imgui.menu_selectable[0] = 5
				end
				if imgui.Button(fa.USERS .. u8' Мероприятия', elements.imgui.bt_size) then  
					elements.imgui.menu_selectable[0] = 6
				end 
				if imgui.Button(fa.GEARS .. u8' Настройки', elements.imgui.bt_size) then
					elements.imgui.menu_selectable[0] = 7
				end
			imgui.EndChild() 
			imgui.SameLine()
			imgui.BeginChild('##MainSelectable', imgui.ImVec2(1000, 570), true)
				if elements.imgui.menu_selectable[0] == 8 then
					plother.ActivateBulletTrack()
				end
				if elements.imgui.menu_selectable[0] == 0 then
					imgui.TextWrapped(u8(helloText))
				end
				if elements.imgui.menu_selectable[0] == 1 then  
					if not show_password then  
						if #ffi.string(elements.buffers.password) > 0 then  
							if tonumber(ffi.string(elements.buffers.password)) then 
								imgui.StrCopy(elements.buffers.password, tostring(ffi.string(elements.buffers.password)))
							end 
						end
						if imgui.InputText('##PasswordAdmin', elements.buffers.password, ffi.sizeof(elements.buffers.password), imgui.InputTextFlags.Password) then
							config.settings.password_to_login = ffi.string(elements.buffers.password)
							inicfg.save(config, directIni)
						end
					else 
						if imgui.InputText('##PasswordAdmin', elements.buffers.password, ffi.sizeof(elements.buffers.password)) then
							config.settings.password_to_login = ffi.string(elements.buffers.password)
							inicfg.save(config, directIni)
						end
					end
					imgui.SameLine()
					if not show_password then  
						imgui.Text(fa.EYE_SLASH)
						if imgui.IsItemClicked() then  
							show_password = true  
						end  
					else 
						imgui.Text(fa.EYE)
						if imgui.IsItemClicked() then  
							show_password = false 
						end 
					end 
					imgui.SameLine()
					if imgui.Button(fa.ROTATE) then  
						imgui.StrCopy(elements.buffers.password, '')
						config.settings.password_to_login = ''
						inicfg.save(config, directIni)
					end
					imgui.Text(u8'Авто-Alogin') 
					imgui.SameLine()
					if mim_addons.ToggleButton('##AutoALogin', elements.boolean.autologin) then  
						config.settings.autologin = elements.boolean.autologin[0]
						save()
					end  
					imgui.SameLine()
					imgui.SetCursorPosX(280)
					imgui.Text(u8"Кастомное рекон-меню")
					imgui.SameLine()
					if mim_addons.ToggleButton("##CustomReconMenu", elements.boolean.recon) then  
						config.settings.custom_recon = elements.boolean.recon[0]
						save() 
					end
					AutoMuteLib.ActiveAutoMute()
					imgui.SameLine()
					imgui.SetCursorPosX(280)
					imgui.Text(u8"Авто-онлайн")
					imgui.SameLine()
					if mim_addons.ToggleButton('##AutoOnline', elements.boolean.auto_online) then  
						config.settings.auto_online = elements.boolean.auto_online[0]
						save()  
						send_online:run()
					end
					imgui.Text(u8'Адм. формы')
					imgui.SameLine()
					if mim_addons.ToggleButton('##AdminsForms', elements.boolean.adminforms) then  
						config.settings.adminforms = elements.boolean.adminforms[0]
						save() 
					end 
					imgui.SameLine()
					if imgui.Checkbox('##AutoForms', elements.boolean.autoforms) then  
						config.settings.autoforms = elements.boolean.autoforms[0]
						save() 
					end; Tooltip('Принимает формы автоматически. Рекомендовано разработчиком!')
					imgui.SameLine()
					imgui.SetCursorPosX(280)
					imgui.Text(u8'Вывод даты и времени')
					imgui.SameLine()
					if mim_addons.ToggleButton('##RenderDate', elements.boolean.render_date) then  
						config.settings.render_date = elements.boolean.render_date[0]
						save()  
					end
					plother.ActivateWH()
				end
				if elements.imgui.menu_selectable[0] == 2 then
					imgui.Text(u8(textToMenuSelectableAutoMute))
					AutoMuteLib.ReadWriteAM()
				end 
				if elements.imgui.menu_selectable[0] == 3 then
					if imgui.TreeNodeStr(u8"Наказания в онлайне") then 
						if imgui.TreeNodeStr("Ban") then  
							for key in pairs(cmd_massive) do  
								if cmd_massive[key].cmd == '/iban' or cmd_massive[key].cmd == '/ban' or cmd_massive[key].cmd == '/siban' or cmd_massive[key].cmd == '/sban'then  
									imgui.TextWrapped(u8'/'..key..u8' [ID] - ' .. u8(cmd_massive[key].reason))
									if cmd_massive[key].tip then  
										imgui.TextWrapped(u8('		' ..cmd_massive[key].tip))
									end
								end 
							end 
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/jail" then
									imgui.TextWrapped(u8'/'..key..u8' [ID] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/mute" then
									imgui.TextWrapped(u8'/'..key..u8' [ID] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr('Mute with Report') then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/rmute" then
									imgui.TextWrapped(u8'/'..key..u8' [ID] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Kick") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/kick" then
									imgui.TextWrapped(u8'/'..key..u8' [ID] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"Наказания в оффлайне") then  
						if imgui.TreeNodeStr("Ban") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/banakk" or cmd_massive[key].cmd == '/offban' or cmd_massive[key].cmd == '/banip' then
									imgui.TextWrapped(u8'/'..key..u8' [NickName] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/jailakk" or cmd_massive[key].cmd == '/jailoff' then
									imgui.TextWrapped(u8'/'..key..u8' [NickName] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/muteakk" then
									imgui.TextWrapped(u8'/'..key..u8' [NickName] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						if imgui.TreeNodeStr('Mute with Report') then
							for key in pairs(cmd_massive) do
								if cmd_massive[key].cmd == "/rmuteakk" then
									imgui.TextWrapped(u8'/'..key..u8' [NickName] - ' .. u8(cmd_massive[key].reason))
								end
							end
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"Дополнительные команды AT") then  
						for key in pairs(cmd_helper_others) do 
							imgui.TextWrapped(u8'/'..key..u8' ' .. u8(cmd_helper_others[key].reason))
							if cmd_helper_others[key].tip then  
								imgui.TextWrapped(u8(cmd_helper_others[key].tip))
							end
						end
						imgui.TreePop()
					end
				end
				if elements.imgui.menu_selectable[0] == 4 then
					showFlood_ImGUI()
				end 
				if elements.imgui.menu_selectable[0] == 5 then
					QuestionAnswer.BinderEdit()
				end
				if elements.imgui.menu_selectable[0] == 6 then
					if imgui.BeginTabBar('##EventBar') then  
						if imgui.BeginTabItem(fa.WAREHOUSE .. u8" Начальное окно") then  
							posX, posY, posZ = getCharCoordinates(PLAYER_PED)
							imgui.TextWrapped(u8"Здесь Вы можете создать мероприятие и управлять им.")
							imgui.TextWrapped(u8"Содержание окна меняется в зависимости от выбранного меню.")
							imgui.TextWrapped(u8"Кроме этого, интеграция данного окна также присутствует в открытии мероприятия.")
							imgui.TextWrapped(u8"AT Events обладает функциями управления мероприятиям в режиме RealTime.")
							imgui.TextWrapped(u8"AT Events предполагает создание своего мероприятия с нуля или использования заготовленных разработчиком.")
							imgui.Text('')
							imgui.Text(u8'Ваши корды: \nX: ' .. posX .. ' | Y: ' .. posY .. ' | Z: ' .. posZ)
							imgui.EndTabItem()
						end
						if imgui.BeginTabItem(fa.MAP_LOCATION .. u8' Создание МП') then  
							imgui.Text(u8'Данный раздел позволяет создать свое мероприятие.')
							imgui.TextWrapped(u8"Создание мероприятия через данное окно предусматривает его сохранение через кнопочку. ")
							imgui.Text(u8"Правила создаются по принципу флудов.");
							Tooltip("Текст в правилах/описание следует следующему правилу:\n1. Вводится по принципу флудов, т.е. номер цвета mess и текст. Пример: \n 6 Участие в МП могут принять все! \n 6 Запрещено пользоваться /heal, /r и /s\n2. Каждая строчка делается отдельно для правильного вывода. ")
							imgui.Separator()
							imgui.PushItemWidth(130)
							imgui.InputText(u8"Имя MP", elements.buffers.name, ffi.sizeof(elements.buffers.name))  
							imgui.PopItemWidth()
							imgui.SameLine()
							imgui.PushItemWidth(60)
							imgui.InputText(u8"/dt", elements.buffers.vdt, ffi.sizeof(elements.buffers.vdt)); Tooltip("Если сюда ничего не вводить, то виртуальный мир введется рандомно.")
							imgui.PopItemWidth()
							imgui.Separator()
							atlibs.CenterText("Правила мероприятия")
							imgui.PushItemWidth(400)
							imgui.InputTextMultiline("##RulesForEvent", elements.buffers.rules, ffi.sizeof(elements.buffers.rules), imgui.ImVec2(-1, 250))
							imgui.PopItemWidth()
							if imgui.Button(u8"Вывод правил") then  
								text = atlibs.string_split(ffi.string(elements.buffers.rules):gsub("\n", "~"), "~")
								for _, i in pairs(text) do  
									sampSendChat("/mess " .. u8:decode(i))
								end
							end; Tooltip("Кликать после начала МП для правильности проведения.")
							imgui.SameLine()
							imgui.SetCursorPosX(imgui.GetWindowWidth() - 400)
							if imgui.Button(u8"Станд.правила") then  
								sampSendChat("/mess 6 На мероприятии нельзя: /passive, /anim, /r - /s, DM, нарушать прочие правила проекта")
								sampSendChat("/mess 6 При нарушении правил, Вы будете посажены в Jail.")
							end; Tooltip("Кликать после начала МП для правильности проведения.")
							imgui.SameLine()
							imgui.SetCursorPosX(imgui.GetWindowWidth() - 200)
							if imgui.Button(u8"Начать МП") then  
								lua_thread.create(function()
									sampSendChat("/mp")
									sampSendDialogResponse(5343, 1, 15)
									wait(1)
									sampSendDialogResponse(16069, 1, 1)
									if #ffi.string(elements.buffers.vdt) > 0 then  
										sampSendDialogResponse(16070, 1, 0, u8:decode(tostring(ffi.string(elements.buffers.vdt))))
									else
										math.randomseed(os.clock())
										local dt = math.random(500, 999)
										imgui.StrCopy(elements.buffers.vdt, tostring(dt))
										sampSendDialogResponse(16070, 1, 0, tostring(dt))
									end
									sampSendDialogResponse(16069, 1, 2)
									sampSendDialogResponse(16071, 1, 0, "0")
									sampSendDialogResponse(16069, 0, 0)
									sampSendDialogResponse(5343, 1, 0)
									wait(200)
									sampSendDialogResponse(5344, 1, 0, u8:decode(tostring(ffi.string(elements.buffers.name))))
									sampSendChat("/mess 6 Уважаемые игроки! Проходит меропряитие: " .. u8:decode(tostring(ffi.string(elements.buffers.name))) .. ". Желающие: /tpmp")
									sampSendChat("/mess 6 Уважаемые игроки! Проходит меропряитие: " .. u8:decode(tostring(ffi.string(elements.buffers.name))) .. ". Желающие: /tpmp")
									wait(1)
									sampSendDialogResponse(5344, 0, 0)
									wait(1)
									sampSendDialogResponse(5343, 0, 0)
								end)
							end
							imgui.SameLine()
							if imgui.Button(fa.UPLOAD) then  
								positionX, positionY, positionZ = getCharCoordinates(playerPed)
								positionX = string.sub(tostring(positionX), 1, string.find(tostring(positionX), ".")+6)
								positionY = string.sub(tostring(positionY), 1, string.find(tostring(positionY), ".")+6)
								positionZ = string.sub(tostring(positionZ), 1, string.find(tostring(positionZ), ".")+6)
								imgui.StrCopy(elements.buffers.coord, tostring(positionX) .. "," .. tostring(positionY) .. "," .. tostring(positionZ))
								local refresh_text = ffi.string(elements.buffers.rules):gsub("\n", "~")
								table.insert(cfgevents.bind_name, ffi.string(elements.buffers.name))
								table.insert(cfgevents.bind_text, refresh_text)
								table.insert(cfgevents.bind_vdt, tostring(ffi.string(elements.buffers.vdt)))
								table.insert(cfgevents.bind_coords, ffi.string(elements.buffers.coord))
								if EventsSave() then  
									sampAddChatMessage(tag .. 'МП "' ..u8:decode(ffi.string(elements.buffers.name)).. '" успешно добавлено в Биндер!', -1)
									imgui.StrCopy(elements.buffers.name, '')
									imgui.StrCopy(elements.buffers.text, '')
									imgui.StrCopy(elements.buffers.vdt, '0')
									imgui.StrCopy(elements.buffers.coord, '0')
								end  
							end; Tooltip("Функция позволяет сохранить данное мероприятия в Биндере. \nВыставляется местоположение, откуда Вы его начали, где Вы на данный момент стоите.")

							imgui.EndTabItem()
						end 
						if imgui.BeginTabItem(fa.TERMINAL .. u8' Заготовки и биндер') then  
							imgui.TextWrapped(u8"В данном разделе можно использовать мероприятия от разработчика, либо создать свои и использовать их в дальнейшем.")
							imgui.TextWrapped(u8"Помощник по созданию. Наведите мышкой! Я могу показывать Вам сообщение помощника :D");
							Tooltip("И так. Легкое объяснение по созданию своего мероприятия. \nТекст в правилах/описание следует следующему правилу:\n1. Вводится по принципу флудов, т.е. номер цвета mess и текст. Пример: \n 6 Участие в МП могут принять все! \n 6 Запрещено пользоваться /heal, /r и /s\n2. Каждая строчка делается отдельно для правильного вывода. \n\n Координаты лучше брать из домашней страницы, либо выбирать 'Моя позиция' \n Виртуальный мир рекомендуется выбирать рандомно, при помощи кнопки скрипта \n Мероприятия стабильно редактируются, поэтому Вы все можете подстроить под себя.")
							imgui.Separator()

							if imgui.Button(u8'Создать мероприятие') then  
								imgui.StrCopy(elements.buffers.name, '')
								imgui.StrCopy(elements.buffers.vdt, '0')
								imgui.StrCopy(elements.buffers.coord, '0')
								getpos = nil 
								EditOldBind = false  
								imgui.OpenPopup('EventsBinder')
							end

							if #cfgevents.bind_name > 0 then  
								for key, bind in pairs(cfgevents.bind_name) do  
									if imgui.Button(bind .. '##' .. key) then  
										sampAddChatMessage(tag .. 'Реализую запуск вашего МП "' .. u8:decode(bind) .. '"', -1)
										lua_thread.create(function()
											if #cfgevents.bind_coords > 5 then  
												coords = atlibs.string_split(cfgevents.bind_coords[key], ',')
												setCharCoordinates(PLAYER_PED,coords[1],coords[2],coords[3])
											end  
											stream_text = atlibs.string_split(cfgevents.bind_text[key], '~')
											wait(500)
											sampSendChat('/mp')
											sampSendDialogResponse(5343, 1, 15)
											wait(1)
											sampSendDialogResponse(16069, 1, 1)
											sampSendDialogResponse(16070, 1, 0, cfgevents.bind_vdt[key])
											sampSendDialogResponse(16069, 1, 2)
											sampSendDialogResponse(16071, 1, 0, "0")
											sampSendDialogResponse(16069, 0, 0)
											sampSendDialogResponse(5343, 1, 0)
											wait(200)
											sampSendDialogResponse(5344, 1, 0, u8:decode(tostring(cfgevents.bind_name[key])))
											sampSendChat("/mess 6 Уважаемые игроки! Проходит меропряитие: " .. u8:decode(tostring(cfgevents.bind_name[key])) .. ". Желающие: /tpmp")
											sampSendChat("/mess 6 Уважаемые игроки! Проходит меропряитие: " .. u8:decode(tostring(cfgevents.bind_name[key])) .. ". Желающие: /tpmp")
											wait(1)
											sampSendDialogResponse(5344, 0, 0)
											wait(1)
											sampSendDialogResponse(5343, 0, 0)
										end)
									end  
									imgui.SameLine()
									if imgui.Button(fa.COMMENT_SLASH .. '##' .. key) then  
										EditOldBind = true  
										getpos = key 
										local returnwrapped = tostring(cfgevents.bind_text[key]):gsub('~', '\n')
										imgui.StrCopy(elements.buffers.text, returnwrapped)
										imgui.StrCopy(elements.buffers.name, tostring(cfgevents.bind_name[key]))
										imgui.StrCopy(elements.buffers.coord, tostring(cfgevents.bind_coords[key]))
										imgui.StrCopy(elements.buffers.vdt, tostring(cfgevents.bind_vdt[key]))
										imgui.OpenPopup('EventsBinder')
									end  
									imgui.SameLine()
									if imgui.Button(fa.TRASH .. '##' .. key) then  
										sampAddChatMessage(tag .. 'МП "' ..u8:decode(cfgevents.bind_name[key])..'" удалено!', -1)
										table.remove(cfgevents.bind_name, key)
										table.remove(cfgevents.bind_text, key)
										EventsSave()
									end
								end  
							else 
								imgui.TextWrapped(u8'Ни одно мероприятие не зарегистрировано. Может, создадим?')
							end

							if imgui.BeginPopupModal('EventsBinder', false, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then  
								imgui.BeginChild('##CreateEdit', imgui.ImVec2(800, 500), true)
									imgui.Text(u8"Название МП: "); imgui.SameLine()
									imgui.PushItemWidth(130)
									imgui.InputText('##name_events', elements.buffers.name, ffi.sizeof(elements.buffers.name))
									imgui.PopItemWidth()
									imgui.Text(u8"Виртуальный мир: "); Tooltip("Сейчас указание виртуального мира (отличное от 0) необходимо для создания своего мероприятия \nЛично рекомендую: указывайте от 500 до 999 рандомными значениями.\nПрименяйте в каждом своем мероприятии усредненное значение, чтобы самому не путаться.")
									imgui.SameLine()
									imgui.PushItemWidth(60)
									imgui.InputText('##dt_event', elements.buffers.vdt, ffi.sizeof(elements.buffers.vdt))
									imgui.PopItemWidth()
									imgui.SameLine()
									if imgui.Button(u8"Рандом") then  
										math.randomseed(os.clock())
										local dt = math.random(500, 999)
										imgui.StrCopy(elements.buffers.vdt, tostring(dt))
									end; Tooltip("Скрипт сам вставляет рандомный номер виртуального мира (/dt)")
									imgui.Text(u8"Координаты начала МП: ")
									imgui.SameLine()
									imgui.PushItemWidth(250)
									imgui.InputText("##CoordsEvent", elements.buffers.coord, ffi.sizeof(elements.buffers.coord))
									imgui.PopItemWidth()
									imgui.SameLine()
									if imgui.Button(u8"Моя позиция") then  
										positionX, positionY, positionZ = getCharCoordinates(playerPed)
										positionX = string.sub(tostring(positionX), 1, string.find(tostring(positionX), ".")+6)
										positionY = string.sub(tostring(positionY), 1, string.find(tostring(positionY), ".")+6)
										positionZ = string.sub(tostring(positionZ), 1, string.find(tostring(positionZ), ".")+6)
										imgui.StrCopy(elements.buffers.coord, tostring(positionX) .. "," .. tostring(positionY) .. "," .. tostring(positionZ))
									end; Tooltip("Выбирает координаты, на которых Вы сейчас находитесь. \nКоординаты укорочены приблизительно до 2-4 знаков после запятой.")
									imgui.Separator()
									imgui.Text(u8"Правила/описание МП:")
									imgui.PushItemWidth(300)
									imgui.InputTextMultiline("##EventText", elements.buffers.text, ffi.sizeof(elements.buffers.text), imgui.ImVec2(-1, 280))
									imgui.PopItemWidth()
									imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 100)
									if imgui.Button(u8'Закрыть##bind') then  
										imgui.StrCopy(elements.buffers.name, '')
										imgui.StrCopy(elements.buffers.text, '')
										imgui.StrCopy(elements.buffers.vdt, '0')
										imgui.StrCopy(elements.buffers.coord, '0')
										imgui.CloseCurrentPopup()
									end  
									imgui.SameLine()
									if #ffi.string(elements.buffers.name) > 0 and #ffi.string(elements.buffers.text) > 0 then  
										imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 1.01)
										if imgui.Button(u8'Сохранить##bind') then  
											if not EditOldBind then  
												local refresh_text = ffi.string(elements.buffers.text):gsub("\n", "~")
												table.insert(cfgevents.bind_name, ffi.string(elements.buffers.name))
												table.insert(cfgevents.bind_text, refresh_text)
												table.insert(cfgevents.bind_vdt, tostring(ffi.string(elements.buffers.vdt)))
												table.insert(cfgevents.bind_coords, ffi.string(elements.buffers.coord))
												if EventsSave() then  
													sampAddChatMessage(tag .. 'МП "' ..u8:decode(ffi.string(elements.buffers.name)).. '" успешно создано!', -1)
													imgui.StrCopy(elements.buffers.name, '')
													imgui.StrCopy(elements.buffers.text, '')
													imgui.StrCopy(elements.buffers.vdt, '0')
													imgui.StrCopy(elements.buffers.coord, '0')
												end  
												imgui.CloseCurrentPopup()
											else 
												local refresh_text = ffi.string(elements.buffers.text):gsub("\n", "~")
												table.insert(cfgevents.bind_name, getpos, ffi.string(elements.buffers.name))
												table.insert(cfgevents.bind_text, getpos, refresh_text)
												table.insert(cfgevents.bind_vdt, getpos, tostring(ffi.string(elements.buffers.vdt)))
												table.insert(cfgevents.bind_coords, getpos, ffi.string(elements.buffers.coord))
												table.remove(cfgevents.bind_name, getpos + 1)
												table.remove(cfgevents.bind_text, getpos + 1)
												table.remove(cfgevents.bind_vdt, getpos + 1)
												table.remove(cfgevents.bind_coords, getpos + 1)
												if EventsSave() then
													sampAddChatMessage(tag .. 'МП "' ..u8:decode(ffi.string(elements.buffers.name)).. '" успешно отредактировано!', -1)
													imgui.StrCopy(elements.buffers.name, '')
													imgui.StrCopy(elements.buffers.text, '')
													imgui.StrCopy(elements.buffers.vdt, '0')
													imgui.StrCopy(elements.buffers.coord, '0')
												end
												EditOldBind = false 
												imgui.CloseCurrentPopup()
											end
										end                        
									end
								imgui.EndChild()
								imgui.EndPopup()
							end

							imgui.EndTabItem()
						end
						imgui.EndTabBar()
					end 
				end
				if elements.imgui.menu_selectable[0] == 7 then
					imgui.Text(u8'В разработке....')
				end
			imgui.EndChild()
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

-- ## Блок функций-экспорта для интеграций их в основной скрипт ## --

function showFlood_ImGUI()
    local colours_mess = [[
0 - {FFFFFF}белый, {FFFFFF}1 - {000000}черный, {FFFFFF}2 - {008000}зеленый, {FFFFFF}3 - {80FF00}светло-зеленый
4 - {FF0000}красный, {FFFFFF}5 - {0000FF}синий, {FFFFFF}6 - {FDFF00}желтый, {FFFFFF}7 - {FF9000}оранжевый
8 - {B313E7}фиолетовый, {FFFFFF}9 - {49E789}бирюзовый, {FFFFFF}10 - {139BEC}голубой
11 - {2C9197}темно-зеленый, {FFFFFF}12 - {DDB201}золотой, {FFFFFF}13 - {B8B6B6}серый, {FFFFFF}14 - {FFEE8A}светло-желтый
15 - {FF9DB6}розовый, {FFFFFF}16 - {BE8A01}коричневый, {FFFFFF}17 - {E6284E}темно-розовый
]]
    imgui.Text(u8"Здесь можно использовать флуды в чат /mess для игроков.")
    imgui.Separator()
    if imgui.CollapsingHeader(u8'Напоминание цветов /mess') then  
        atlibs.TextColoredRGB('0 - {FFFFFF}белый, {FFFFFF}1 - {000000}черный, {FFFFFF}2 - {008000}зеленый, {FFFFFF}3 - {80FF00}светло-зеленый')
		atlibs.TextColoredRGB('4 - {FF0000}красный, {FFFFFF}5 - {0000FF}синий, {FFFFFF}6 - {FDFF00}желтый, {FFFFFF}7 - {FF9000}оранжевый')
		atlibs.TextColoredRGB('4 - {B313E7}фиолетовый, {FFFFFF}9 - {49E789}бирюзовый, {FFFFFF}10 - {139BEC}голубой')
		atlibs.TextColoredRGB('11 - {2C9197}темно-зеленый, {FFFFFF}12 - {DDB201}золотой, {FFFFFF}13 - {B8B6B6}серый, {FFFFFF}14 - {FFEE8A}светло-желтый')
		atlibs.TextColoredRGB('15 - {FF9DB6}розовый, {FFFFFF}16 - {BE8A01}коричневый, {FFFFFF}17 - {E6284E}темно-розовый')
    end
    if imgui.Button(u8"Основные флуды") then  
        imgui.OpenPopup('mainFloods')
    end
    if imgui.Button(u8"Флуд об GangWar") then  
        imgui.OpenPopup('FloodsGangWar')
    end 
    if imgui.Button(u8"Мероприятия /join") then  
        imgui.OpenPopup('FloodsJoinMP')
    end
    if imgui.BeginPopup('mainFloods') then  
        if imgui.Button(u8'Флуд про репорты') then
			sampSendChat("/mess 4 ===================== | Репорты | ====================")
			sampSendChat("/mess 0 Заметили читера или нарушителя?")
			sampSendChat("/mess 4 Вводите /report, пишите туда ID нарушителя/читера!")
			sampSendChat("/mess 0 Наши администраторы ответят вам и разберутся с ними. <3")
			sampSendChat("/mess 4 ===================== | Репорты | ====================")
		end
		imgui.SameLine()
		if imgui.Button(u8'Флуд про VIP') then
			sampSendChat("/mess 2 ===================== | VIP | ====================")
			sampSendChat("/mess 3 Всегда хотел смотреть на людей свыше?")
			sampSendChat("/mess 2 Тобой управляет зависть? Устрани это с помощью 10к очков.")
			sampSendChat("/mess 3 Вводи команду /sellvip и ты получишь VIP!")
			sampSendChat("/mess 2 ===================== | VIP | ====================")
		end
		if imgui.Button(u8'Флуд про оплату бизнеса/дома') then
			
			sampSendChat("/mess 5 ===================== | Банк | ====================")
			sampSendChat("/mess 10 Дом или бизнес нужно оплачивать. Как? -> ..")
			sampSendChat("/mess 0 Для этого необходимо, написать /tp, затем Разное -> Банк...")
			sampSendChat("/mess 0 ...после этого пройти в Банк, открыть счет и..")
			sampSendChat("/mess 10 ..и щелкнуть по Оплата дома или Оплата бизнеса. На этом все.")
			sampSendChat("/mess 5 ===================== | Банк | ====================")
		end
		if imgui.Button(u8'Флуд про /dt 0-990 (режим тренировки)') then
			
			sampSendChat("/mess 6 =================== | Виртуальный мир | ==================")
			sampSendChat("/mess 0 Перестрелки умотала? Обыденный ДМ, вечная стрельба..")
			sampSendChat("/mess 0 Тебе хочется отдохнуть? Это можно исправить! <3")
			sampSendChat("/mess 0 Скорее вводи /dt 0-990. Число - это виртуальный мир.")
			sampSendChat("/mess 0 Не забудьте сообщить друзьям свой мир. Удачной игры. :3")
			sampSendChat("/mess 6 =================== | Виртуальный мир  | ==================")
			
		end
		if imgui.Button(u8'Флуд про /storm') then
			
			sampSendChat("/mess 2 ===================== | Шторм | ====================")
			sampSendChat("/mess 3 Всегда хотели заработать рубли ? У вас есть возможность!")
			sampSendChat("/mess 2 Вводи команду /storm , после чего подойтите к NPC ... ")
			sampSendChat("/mess 3 ...нажмите присоединится к штурму.")
			sampSendChat("/mess 2 Когда наберётся нужное количиство игроков штурм начнётся.")
			sampSendChat("/mess 2 ===================== | Шторм | ====================")
			
		end
		if imgui.Button(u8'Флуд про /arena') then
			
			sampSendChat("/mess 7 ===================== | Арена | ====================")
			sampSendChat("/mess 0 Хочешь испытать свои навыки в стрельбе?")
			sampSendChat("/mess 7 Скорее вводи /arena, выбери свое поле боя.")
			sampSendChat("/mess 0 Перестреляй всех, победи их. Покажи, кто умеет показать себя. <3")
			sampSendChat("/mess 7 ===================== | Арена | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'Флуд про VK group') then
			
			sampSendChat("/mess 15 ===================== | ВКонтакте | ====================")
			sampSendChat("/mess 0 Всегда хотел поучаствовать в конкурсе?")
			sampSendChat("/mess 15 В твоей голове появились мысли, как улучшить сервер?")
			sampSendChat("/mess 0 Заходи в нашу группу ВКонтакте: https://vk.com/dmdriftgta")
			sampSendChat("/mess 15 ===================== | ВКонтакте | ====================")
			
		end
		if imgui.Button(u8'Флуд про автосалон') then
			
			sampSendChat("/mess 12 ===================== | Автосалон | ====================")
			sampSendChat("/mess 0 У тебя появились коины? Ты хочешь личную тачку?")
			sampSendChat("/mess 12 Вводи команду /tp -> Разное -> Автосалоны")
			sampSendChat("/mess 0 Выбирай нужный автосалон, купи машину за RDS коины. И катайся :3")
			sampSendChat("/mess 12 ===================== | Автосалон | ====================")
			
		end
		if imgui.Button(u8'Флуд про сайт RDS') then
			
			sampSendChat("/mess 8 ===================== | Донат | ====================")
			sampSendChat("/mess 15 Хочешь задонатить на свой любимый сервер RDS? :> ")
			sampSendChat("/mess 15 Ты это можешь сделать с радостью! Сайт: myrds.ru :3 ")
			sampSendChat("/mess 15 И через основателя: @empirerosso")
			sampSendChat("/mess 8 ===================== | Донат | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'Флуд про /gw') then
			
			sampSendChat("/mess 10 ===================== | Capture | ====================")
			sampSendChat("/mess 5 Тебе нравится играть за банды в GTA:SA? Они тут тоже есть! :>")
			sampSendChat("/mess 5 Сделай это с помощью /gw, едь на территорию с друзьями")
			sampSendChat("/mess 5 Чтобы начать воевать за территорию, введи команду /capture XD")
			sampSendChat("/mess 10 ===================== | Capture | ====================")
			
		end
		if imgui.Button(u8"Флуд про группу Сейчас на RDS") then
			
			sampSendChat("/mess 2 ================== | Свободная группа RDS | =================")
			sampSendChat("/mess 11 Давно хотели скинуть свои скрины, и показать другим?")
			sampSendChat("/mess 2 Попробовать продать что-нибудь, но в игре никто не отзывается?")
			sampSendChat("/mess 11 Вы можете посетить свободную группу: https://vk.com/freerds")
			sampSendChat("/mess 2 ================== | Свободная группа RDS | =================")
			
		end
		if imgui.Button(u8"Флуд про /gangwar") then 
			
			sampSendChat("/mess 16 ===================== | Сражения | ====================")
			sampSendChat("/mess 13 Хотели сразиться с другими бандами? Выпустить гнев?")
			sampSendChat("/mess 16 Вы можете себе это позволить! Можете побороть другие банды")
			sampSendChat("/mess 13 Команда /gangwar, выбираете территорию и сражаетесь за неё.")
			sampSendChat("/mess 16 ===================== | Сражения | ====================")
			
		end 
		imgui.SameLine()
		if imgui.Button(u8"Флуд про работы") then
			
			sampSendChat("/mess 14 ===================== | Работы | ====================")
			sampSendChat("/mess 13 Не хватает денег на оружие? Не хватает на машинку?")
			sampSendChat("/mess 13 Ради наших ДМеров и дрифтеров, придуманы работы для деньжат")
			sampSendChat("/mess 13 Черный день открыт, переходи /tp -> Работы")
			sampSendChat("/mess 14 ===================== | Работы | ====================")
			
		end
		if imgui.Button(u8"Флуд о моде") then  
			
			sampSendChat("/mess 13 ===================== | Мод RDS | ====================")
			sampSendChat("/mess 0 Посвящаем вас в мод RDS. Прежде всего, мы Drift Server")
			sampSendChat("/mess 13 Также у нас есть дополнения, это GangWar, DM с элементами RPG")
			sampSendChat("/mess 0 Большинство команд и все остальное указано в /help")
			sampSendChat("/mess 13 ===================== | Мод RDS | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'Флуд про /trade') then
			
			sampSendChat("/mess 9 ===================== | Трейд | ====================")
			sampSendChat("/mess 3 Хотите разные аксессуары, а долго играть не хочется и есть вирты/очки/коины/рубли?")
			sampSendChat("/mess 9 Введите /trade, подойдите к занятой лавки, спросите у человека и купите предмет.")
			sampSendChat("/mess 3 Также, справа от лавок есть NPC Арман, у него также можно что-то взять.")
			sampSendChat("/mess 9 ===================== | Трейд | ====================")
			
		end
		if imgui.Button(u8'Флуд про форум') then 
			
			sampSendChat("/mess 4 ===================== | Форум | ====================")
			sampSendChat('/mess 0 Есть жалобы на игроков/админов? Есть вопросы? Хотите играть с телефона?')
			sampSendChat('/mess 4 У нас есть форум - https://forumrds.ru. Там есть полезная инфа :D')
			sampSendChat('/mess 0 Кроме этого, там есть курилка и галерея. Веселитесь, игроки <3')
			sampSendChat("/mess 4 ===================== | Форум  | ====================")
			
		end	
		if imgui.Button(u8'Флуд про набор адм') then 
			
			sampSendChat("/mess 15 ===================== | Набор | ====================")
			sampSendChat('/mess 17 Дорогие игроки! Вы знаете правила нашего проекта?')
			sampSendChat('/mess 15 Если вы когда-то хотели стать админом, то это ваш шанс!')
			sampSendChat('/mess 17 Уже на форуме открыты заявки! Успейте подать: https://forumrds.ru')
			sampSendChat("/mess 15 ===================== | Набор | ====================")
			
		end
		if imgui.Button(u8'Спавн каров на 15 секунд') then
			
			sampSendChat("/mess 14 Уважаемые игроки. Сейчас будет респавн всего серверного транспорта")
			sampSendChat("/mess 14 Займите водительские места, и продолжайте дрифтить, наши любимые :3")
			sampSendChat("/delcarall ")
			sampSendChat("/spawncars 15 ")
			toast.Show(u8"Респавн т/с начался", toast.TYPE.INFO, 5)
			
		end
	    if imgui.Button(u8'Квесты') then
			
		    sampSendChat("/mess 8 =================| Квесты NPC |=================")
		    sampSendChat("/mess 0 Не можете найти NPC которые дают квесты? :D")
		    sampSendChat("/mess 0 И так где же их найти , - ALT(/mm) - Телепорты - ...")
		    sampSendChat("/mess 0 ...Василий Андроид, Бродяга Диман, и на каждом спавне...")
		    sampSendChat("/mess 0 ...NPC Кейн. Приятной игры на RDS <3")
		    sampSendChat("/mess 8 =================| Квесты NPC |=================")
			
		end	
	    imgui.EndPopup()
    end
    if imgui.BeginPopup('FloodsGangWar') then  
        if imgui.Button(u8"Aztecas vs Ballas") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 3 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs East Side Ballas ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 3 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Aztecas vs Groove") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 2 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs Groove Street ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 2 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		if imgui.Button(u8"Aztecas vs Vagos") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 4 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs Los Santos Vagos ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 4 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Aztecas vs Rifa") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 5 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs The Rifa ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 5 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		if imgui.Button(u8"Ballas vs Groove") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 6 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs Groove Street  ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 6 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Ballas vs Rifa") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 7 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs The Rifa ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 7 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		if imgui.Button(u8"Groove vs Rifa") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 8 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Groove Street  vs The Rifa ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 8 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Groove vs Vagos") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 9 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Groove Street vs Los Santos Vagos ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 9 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		if imgui.Button(u8"Vagos vs Rifa") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 10 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 Los Santos Vagos vs The Rifa ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 10 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Ballas vs Vagos") then  
			
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			sampSendChat("/mess 11 Игра -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs Los Santos Vagos ")
			sampSendChat("/mess 0 Помогите своим братьям, заходите через /gw за любимую банду")
			sampSendChat("/mess 11 Игра - GangWar: /gw")
			sampSendChat("/mess 13 •------------------- GangWar -------------------•")
			
		end
        imgui.EndPopup()
    end
    if imgui.BeginPopup('FloodsJoinMP') then  
        if imgui.Button(u8'Мероприятие "Дерби" ') then 
			
			sampSendChat("/mess 8 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Дерби»! Желающим: /derby")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Дерби»! Желающим: /derby")
			sampSendChat("/mess 8 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Паркур" ') then 
			
			sampSendChat("/mess 10 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Паркур»! Желающим: /parkour")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Паркур»! Желающим: /parkour")
			sampSendChat("/mess 10 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "PUBG" ') then 
			
			sampSendChat("/mess 9 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «PUBG»! Желающим: /pubg")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «PUBG»! Желающим: /pubg")
			sampSendChat("/mess 9 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "DAMAGE DM" ') then 
			
			sampSendChat("/mess 4 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «DAMAGE DEATHMATCH»! Желающим: /damagedm")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «DAMAGE DEATHMATCH»! Желающим: /damagedm")
			sampSendChat("/mess 4 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "KILL DM" ') then 
			
			sampSendChat("/mess 17 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «KILL DEATHMATCH»! Желающим: /killdm")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «KILL DEATHMATCH»! Желающим: /killdm")
			sampSendChat("/mess 17 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Дрифт гонки" ') then 
			
			sampSendChat("/mess 7 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Дрифт гонки»! Желающим: /drace")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Дрифт гонки»! Желающим: /drace")
			sampSendChat("/mess 7 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "PaintBall" ') then 
			
			sampSendChat("/mess 12 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «PaintBall»! Желающим: /paintball")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «PaintBall»! Желающим: /paintball")
			sampSendChat("/mess 12 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Зомби против людей" ') then 
			
			sampSendChat("/mess 13 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Зомби против людей»! Желающим: /zombie")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Зомби против людей»! Желающим: /zombie")
			sampSendChat("/mess 13 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Новогодняя сказка" ') then 
			
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Новогодняя сказка»! Желающим: /ny")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Новогодняя сказка»! Желающим: /ny")
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Capture Blocks" ') then 
			
			sampSendChat("/mess 16 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Capture Blocks»! Желающим: /join -> 12")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Capture Blocks»! Желающим: /join -> 12")
			sampSendChat("/mess 16 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'Мероприятие "Прятки" ') then 
			sampSendChat("/mess 11 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Прятки»! Желающим: /join -> 10 «Прятки»")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Прятки»! Желающим: /join -> 10 «Прятки»")
			sampSendChat("/mess 11 ===================| [Event-Game-RDS] |==================")
		end	
		if imgui.Button(u8'Мероприятие "Догонялки" ') then 
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Догонялки»! Желающим: /catchup")
			sampSendChat("/mess 0 [MP-/join] Проводится мероприятие «Догонялки»! Желающим: /catchup")
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
		end
        imgui.EndPopup()
    end
end
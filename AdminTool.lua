require 'lib.moonloader'

local dlstatus = require('moonloader').download_status
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
	['upat'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/upat.ini'
}

local paths = {
	['main'] = getWorkingDirectory() .. '/AdminTool.lua',
	['libsfor'] = getWorkingDirectory() .. '/lib/libsfor.lua',
	['report'] = getWorkingDirectory() .. '/QuestionAnswer.lua',
	['upat'] = getWorkingDirectory() .. '/upat.ini'
}

function downloadFile(url, path)
	local response = {}
	local _, status_code, _ = http.request{
	  url = url,
	  method = "GET",
	  sink = ltn12.sink.file(io.open(path, "w")),
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

local version_control = 1
local version_text = '1.0'
-- ## Контролирование версий AT. Скачивание, ссылки и директории. ## --

-- ## Система конфига и переменных VARIABLE ## --
local new = imgui.new

local directoryAutoMute = getWorkingDirectory() .. '/config/AdminTool/AutoMute'
local directIni = 'AdminTool/settings.ini'

local config = inicfg.load({
    settings = {
        custom_recon = false,
		autologin = false,
		password_to_login = '',
		automute_mat = false,
        automute_osk = false,
        automute_rod = false, 
        automute_upom = false, 
    },
}, directIni)
inicfg.save(config, directIni)

function save()
    inicfg.save(config, directIni)
    toast.Show(u8"Сохранение настроек прошло успешно.", toast.TYPE.OK, 5)
end

local elements = {
	settings = {
        automute_mat = new.bool(config.settings.automute_mat),
        automute_osk = new.bool(config.settings.automute_osk),
        automute_rod = new.bool(config.settings.automute_rod),
        automute_upom = new.bool(config.settings.automute_upom),
    },
    imgui = {
        main_window = new.bool(false),
        recon_window = new.bool(false),
        menu_selectable = new.int(0),
        btn_size = imgui.ImVec2(70,0),
		selectable = 0,
        stream = new.char[65536](),
        input_word = new.char[500](),
    },
    boolean = {
        recon = new.bool(config.settings.custom_recon),
		autologin = new.bool(config.settings.autologin),
    },
	buffers = {
		password = new.char[50](config.settings.password_to_login),
	},
}

local show_password = false -- показать/скрыть пароль в интерфейсе
local control_spawn = false -- контроль спавна. Активируется при запуске скрипта
-- ## Система конфига и переменных VARIABLE ## --

-- ## mimgui ## --
function Tooltip(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8(text))
        imgui.EndTooltip()
    end 
end

imgui.OnInitialize(function()   
    imgui.GetIO().IniFilename = nil
    fa.Init(20)
end)

local sw, sh = getScreenResolution()
-- ## mimgui ## --

-- ## Блок переменных связанных с CustomReconMenu ## --
local ids_recon = {479, 2056, 2052, 144, 146, 141, 2050, 155, 153, 152, 156, 154, 160, 157, 179, 165, 159, 164, 162, 161, 180, 178, 163, 169, 181, 161, 166, 170, 168, 174, 182, 172, 171, 175, 173, 150, 184, 147, 148, 151, 149, 142, 143, 184, 177, 145, 158, 167, 183, 176}
local info_to_player = {}
local recon_info = { "Здоровье: ", "Броня: ", "ХП машины: ", "Скорость: ", "Пинг: ", "Патроны: ", "Выстрел: ", "Тайминг выстрела: ", "Время в АФК: ", "P.Loss: ", "Уровень VIP: ", "Пассивный режим: ", "Турбо-режим: ", "Коллизия: "}
local right_recon = new.bool(true)
local accept_load_recon = false 
local recon_id = -1
local control_to_player = false
-- ## Блок переменных связанных с CustomReconMenu ## --

-- ## Переменные отвечающие за стримы автомута ## --
local onscene_mat = { 
    "блять", "сука", "хуй", "нахуй" 
} 
local onscene_osk = { 
    "пидр", "лох", "гандон", "уебан" 
}
local onscene_upom = {
    "аризона", "russian roleplay", "evolve", "эвольв"
}
local onscene_rod = { 
    "мать ебал", "mq", "мать в канаве", "твоя мать шлюха", "твой рот шатал", "mqq", "mmq", 'mmqq', "matb v kanave",
}
local control_onscene_mat = false -- контролирование сцены автомута "Нецензурная лексика"
local control_onscene_osk = false -- контролирование сцены автомута "Оскорбление/унижение"
local control_onscene_upom = false -- контролирование сцены автомута "Упоминание стор.проектов"
local control_onscene_rod = false -- контролирование сцены автомута "Оскорбление родных"
-- ## Переменные отвечающие за стримы автомута ## --

-- ## Функция, позволяющая правильно распределять слова и искать полноценные совпадения ## -- 
function checkMessage(msg, arg) -- под аргументом воспринимается номер нужного mainstream (от 1 до 4); Где 1 - мат, 2 - оск, 3 - упом.стор.проектов, 4 - оск род
    if msg ~= nil then -- проверка, передается ли сообщение в функцию для правильности поиска
        if arg == 1 then -- MainStream Automute-Report For "Нецензурная лексика"  
            for i, ph in ipairs(onscene_mat) do -- берется сначала массив с заполненными скриптом словами, внесенными в файл
                nmsg = atlibs.string_split(msg, " ") -- разбитие сообщения на массив по словам
                for j, word in ipairs(nmsg) do -- цикл хождения по словам внутри массива
                    if ph == atlibs.string_rlower(word) then  -- если запрещенное слово есть внутри массива, то
                        return true, ph -- возврат True и запрещенное слово
                    end  
                end  
            end  
        elseif arg == 2 then -- MainStream Automute-Report For "Оскорбление/Унижение" 
            for i, ph in ipairs(onscene_osk) do -- берется сначала массив с заполненными скриптом словами, внесенными в файл
                nmsg = atlibs.string_split(msg, " ") -- разбитие сообщения на массив по словам
                for j, word in ipairs(nmsg) do -- цикл хождения по словам внутри массива
                    if ph == atlibs.string_rlower(word) then  -- если запрещенное слово есть внутри массива, то
                        return true, ph -- возврат True и запрещенное слово
                    end  
                end  
            end
        elseif arg == 3 then -- MainStream Automute-Report For "Упоминание сторонних проектов"  
            for i, ph in ipairs(onscene_upom) do -- массив с заполненными скриптом словами из файла
                if string.find(msg, ph, 1, true) then -- поиск целиком по строке. Почему применяется данный метод? Акцент больше на предложения, нежели как в циклах выше 
                    return true, ph -- возвращаем True и запрещенное слово
                end 
            end
        elseif arg == 4 then -- MainStream Automute-Report For "Оскорбление родных" 
            for i, ph in ipairs(onscene_rod) do -- массив с заполненными скриптом словами из файла
                if string.find(msg, ph, 1, true) then -- поиск целиком по строке. Почему применяется данный метод? Акцент больше на предложения, нежели как в циклах выше 
                    return true, ph -- возвращаем True и запрещенное слово
                end 
            end 
        end  
    end
end 

function main()

    if toast_ok then 
        toast.Show(u8"AdminTool инициализирован.\nДля работы с интерфейсом, введите: /tool", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'AdminTool успешно инициализирован. Активация: /tool', -1)
        print(tag .. "Отказ в подгрузке уведомлений")
    end

	local response_update_check = downloadFile(urls['upat'], paths['upat'])
	if response_update_check then 
		updateIni = inicfg.load(nil, paths['upat'])
		if tonumber(updateIni.info.version) > version_control then  
			if toast_ok then  
				toast.Show(u8'Доступно обновление.\nAT начинает обновление автоматически.', toast.TYPE.INFO, 5)
			else 
				print(tag .. 'Отказ в подгрузке уведомлений.')
				sampAddChatMessage(tag .. 'Доступно обновление. AT начинает автообновление!')
			end 
			local response_main = downloadFile(urls['main'], paths['main'])
			if response_main then  
				sampAddChatMessage(tag .. 'Основной скрипт АТ скачен.')
			end  
			local response_lib = downloadFile(urls['libsfor'], paths['libsfor'])
			if response_lib then  
				sampAddChatMessage(tag .. 'Библиотека к АТ успешно скачена.')
			end  
			local response_questans = downloadFile(urls['report'], paths['report'])
			if response_questans then  
				sampAddChatMessage(tag .. 'Скрипт для репортов скачен.')
			end  
			sampAddChatMessage(tag .. 'Начинаю перезагрузку скриптов!')
			reloadScripts()
		else 
			if toast_ok then  
				toast.Show(u8'У Вас установлена актуальная версия АТ.\nВерсия AT: ' .. version_text, toast.TYPE.INFO, 5)
			else 
				print(tag .. 'Отказ в подгрузке уведомлений.')
				sampAddChatMessage(tag .. 'У Вас установлена актуальная версия АТ. Версия АТ: ' .. version_text, -1)
			end
		end  
		os.remove(paths['upat'])
	end

    load_recon = lua_thread.create_suspended(loadRecon)

    -- ## Регистрация команд связанные с выдачей мута в онлайне ## --
    sampRegisterChatCommand('fd', cmd_flood)
    sampRegisterChatCommand("po", cmd_popr)
    sampRegisterChatCommand("m", cmd_m)
	sampRegisterChatCommand("ok", cmd_ok)
	sampRegisterChatCommand("oa", cmd_oa)
	sampRegisterChatCommand("kl", cmd_kl)
	sampRegisterChatCommand("up", cmd_up)
	sampRegisterChatCommand("or", cmd_or)
	sampRegisterChatCommand("nm1", cmd_nm1)
	sampRegisterChatCommand("nm2", cmd_nm2)
	sampRegisterChatCommand("nm3", cmd_nm3)
	sampRegisterChatCommand("ia", cmd_ia)
	sampRegisterChatCommand("rz", cmd_rz)
	sampRegisterChatCommand("zs", cmd_zs)
    -- ## Регистрация команд связанные с выдачей мута в онлайне ## --

    -- ## Регистрация команд связанные с выдачей репорт-наказаний мута ## --
    sampRegisterChatCommand("cp", cmd_cpfd)
    sampRegisterChatCommand("rpo", cmd_report_popr)
    sampRegisterChatCommand("rrz", cmd_rrz)
    sampRegisterChatCommand("roa", cmd_roa)
    sampRegisterChatCommand("ror", cmd_ror)
    sampRegisterChatCommand("rup", cmd_rup)
    sampRegisterChatCommand("rok", cmd_rok)
    sampRegisterChatCommand("rm", cmd_rm)
    sampRegisterChatCommand("rnm", cmd_report_neadekvat)
    -- ## Регистрация команд связанных с выдачей репорт-наказаний мута ## --

    -- ## Регистрация команд сявзанных с выдачей offline-наказаний мута ## --
    sampRegisterChatCommand("am", cmd_am)
    sampRegisterChatCommand("aok", cmd_aok)
    sampRegisterChatCommand("afd", cmd_afd)
    sampRegisterChatCommand("apo", cmd_apo)
    sampRegisterChatCommand("aoa", cmd_aoa)
    sampRegisterChatCommand("aup", cmd_aup)
    sampRegisterChatCommand("anm", cmd_offline_neadekvat)
    sampRegisterChatCommand("aor", cmd_aor)
    sampRegisterChatCommand("aia", cmd_aia)
    sampRegisterChatCommand("akl", cmd_akl)
    sampRegisterChatCommand("arz", cmd_arz)
    sampRegisterChatCommand("azs", cmd_azs)
    -- ## Регистрация команд сявзанных с выдачей offline-наказаний мута ## --

    -- ## Регистрация команд сявзанных с выдачей offline-наказаний джайла ## --
    sampRegisterChatCommand("ajcw", cmd_ajcw)
    sampRegisterChatCommand("ask", cmd_ask)
    sampRegisterChatCommand("adz", cmd_adz)
    sampRegisterChatCommand("afsh", cmd_afsh)
    sampRegisterChatCommand("atd", cmd_atd)
    sampRegisterChatCommand("abag", cmd_abag)
    sampRegisterChatCommand("apk", cmd_apk)
    sampRegisterChatCommand("azv", cmd_azv)
    sampRegisterChatCommand("askw", cmd_askw)
    sampRegisterChatCommand("angw", cmd_angw)
    sampRegisterChatCommand("adbgw", cmd_adbgw)
    sampRegisterChatCommand("adgw", cmd_adgw)
    sampRegisterChatCommand("ajch", cmd_ajch)
    sampRegisterChatCommand("apmx", cmd_apmx)
    sampRegisterChatCommand("asch", cmd_asch)
    -- ## Регистрация команд сявзанных с выдачей offline-наказаний джайла ## --

    -- ## Регистрация команд связанных с выдачей наказаний джайла ## --
    sampRegisterChatCommand("sk", cmd_sk)
    sampRegisterChatCommand("dz", cmd_dz)
    sampRegisterChatCommand("jm", cmd_jm)
    sampRegisterChatCommand("td", cmd_td)
    sampRegisterChatCommand("skw", cmd_skw)
    sampRegisterChatCommand("ngw", cmd_ngw)
    sampRegisterChatCommand("dbgw", cmd_dbgw)
    sampRegisterChatCommand("fsh", cmd_fsh)
    sampRegisterChatCommand("bag", cmd_bag)
    sampRegisterChatCommand("pmx", cmd_pmx)
    sampRegisterChatCommand("pk", cmd_pk)
    sampRegisterChatCommand("zv", cmd_zv)
    sampRegisterChatCommand("jch", cmd_jch)
    sampRegisterChatCommand("dgw", cmd_dgw)
    sampRegisterChatCommand("sch", cmd_sch)
    sampRegisterChatCommand("jcw", cmd_jcw)
    sampRegisterChatCommand("tdbz", cmd_tdbz)
    -- ## Регистрация команд связанных с выдачей наказаний джайла ## --

    -- ## Регистрация команд связанные с выдачей наказаний бана ## --
    sampRegisterChatCommand("pl", cmd_pl)
    sampRegisterChatCommand("ob", cmd_ob)
    sampRegisterChatCommand("hl", cmd_hl)
    sampRegisterChatCommand("nk", cmd_nk)
    sampRegisterChatCommand('ch', cmd_ch)
    sampRegisterChatCommand("menk", cmd_menk)
    sampRegisterChatCommand("gcnk", cmd_gcnk)
    sampRegisterChatCommand("bnm", cmd_bnm)
    -- ## Регистрация команд связанные с выдачей наказаний бана ## --

    -- ## Регистрация команд сявзанных с выдачей offline-наказаний бана ## --
    sampRegisterChatCommand("aob", cmd_aob)
    sampRegisterChatCommand("ahl", cmd_ahl)
    sampRegisterChatCommand("ahli", cmd_ahli)
    sampRegisterChatCommand("apl", cmd_apl)
    sampRegisterChatCommand("ach", cmd_ach)
    sampRegisterChatCommand("achi", cmd_achi)
    sampRegisterChatCommand("ank", cmd_ank)
    sampRegisterChatCommand("amenk", cmd_amenk)
    sampRegisterChatCommand("agcnk", cmd_agcnk)
    sampRegisterChatCommand("agcnkip", cmd_agcnkip)
    sampRegisterChatCommand("rdsob", cmd_rdsob)
    sampRegisterChatCommand("rdsip", cmd_rdsip)
    sampRegisterChatCommand("abnm", cmd_abnm)
    -- ## Регистрация команд сявзанных с выдачей offline-наказаний бана ## --

    -- ## Регистрация команд связанные с выдачей наказаний кика ## --
    sampRegisterChatCommand("dj", cmd_dj)
    sampRegisterChatCommand("gnk", cmd_gnk)
    sampRegisterChatCommand("cafk", cmd_cafk)
    -- ## Регистрация команд связанные с выдачей наказаний кика ## --

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
			sampCloseCurrentDialogWithButton(0)
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
			sampCloseCurrentDialogWithButton(0)
		end)
	end)
    -- ## Регистрация вспомогательных команд ## --    

	sampRegisterChatCommand('checksh', function()
		sampAddChatMessage(tag .. "Текущее разрешение: X - " .. sw .. " | Y - " .. sh, -1)
		sampAddChatMessage(tag .. "Данная функция предназначена для debug разрешений окон граф.интерфейса", -1)
	end)

    sampRegisterChatCommand("tool", function()
        elements.imgui.main_window[0] = not elements.imgui.main_window[0]
        elements.imgui.menu_selectable = 0
    end)

	-- ## Интегрирование автомута ## --
	    -- ## Блок проверки на нахождение нужных файлов в рабочей папке ## --

	if not doesDirectoryExist(directoryAutoMute) then  
		createDirectory(directoryAutoMute)
	end  

	local file_read, file_line = io.open(getWorkingDirectory() .. "/config/AdminTool/AutoMute/mat.txt", "r"), -1
	if file_read ~= nil then  
		file_read:seek("set", 0)
		for line in file_read:lines() do  
			onscene_mat[file_line] = line  
			file_line = file_line + 1 
		end  
		file_read:close()  
	else
		file_read, file_line = io.open(directoryAutoMute.."/mat.txt", 'w'), 1
		for _, v in ipairs(onscene_mat) do  
			file_read:write(v .. "\n")
		end 
		file_read:close()
	end

	local file_read, file_line = io.open(directoryAutoMute.."/osk.txt", 'r'), 1
	if file_read ~= nil then  
		file_read:seek("set", 0)
		for line in file_read:lines() do  
			onscene_osk[file_line] = line  
			file_line = file_line + 1 
		end  
		file_read:close()  
	else 
		file_read, file_line = io.open(directoryAutoMute.."/osk.txt", 'w'), 1
		for _, v in ipairs(onscene_osk) do  
			file_read:write(v .. "\n")
		end 
		file_read:close()
	end

	local file_read, file_line = io.open(directoryAutoMute.."/rod.txt", 'r'), 1
	if file_read ~= nil then  
		file_read:seek("set", 0)
		for line in file_read:lines() do  
			onscene_rod[file_line] = line  
			file_line = file_line + 1 
		end  
		file_read:close()  
	else
		file_read, file_line = io.open(directoryAutoMute.."/rod.txt", 'w'), 1
		for _, v in ipairs(onscene_rod) do  
			file_read:write(v .. "\n")
		end 
		file_read:close()
	end

	local file_read, file_line = io.open(directoryAutoMute.."/upom.txt", 'r'), 1
	if file_read ~= nil then  
		file_read:seek("set", 0)
		for line in file_read:lines() do  
			onscene_upom[file_line] = line  
			file_line = file_line + 1 
		end  
		file_read:close()  
	else 
		file_read, file_line = io.open(directoryAutoMute.."/upom.txt", 'w'), 1
		for _, v in ipairs(onscene_upom) do  
			file_read:write(v .. "\n")
		end 
		file_read:close()
	end

		-- ## Блок проверки на нахождение нужных файлов в рабочей папке ## --

		-- ## Блок регистрирующий команды для работы с автомутом (ввод своих слов/удаление слов) ## --

	sampRegisterChatCommand("s_rod", save_rod)
	sampRegisterChatCommand("d_rod", delete_rod)

	sampRegisterChatCommand("s_upom", save_upom)
	sampRegisterChatCommand("d_upom", delete_upom)

	sampRegisterChatCommand("s_osk", save_osk)
	sampRegisterChatCommand("d_osk", delete_osk)

	sampRegisterChatCommand("s_mat", save_mat)
	sampRegisterChatCommand("d_mat", delete_mat)

		-- ## Блок регистрирующий команды для работы с автомутом (ввод своих слов/удаление слов) ## --


    while true do
        wait(0)

		if control_spawn and elements.boolean.autologin[0] then  
			sampAddChatMessage(tag .. "AutoLogin работает в течении 15 секунд после спавна.", -1)
			sampAddChatMessage(tag .. "Ожидайте...", -1)
			wait(15000)
			sampSendChat('/alogin ' .. u8:decode(config.settings.password_to_login))
			control_spawn = false
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

-- ## Блок функций, отвечающий на введенные в блоке регистра команды. Применяется к автомуту ## --
function save_rod(param)
    if param == nil then  
        return false  
    end 
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    for _, val in ipairs(onscene_rod) do  
        if atlibs.string_rlower(param) == val then  
            sampAddChatMessage(tag .. " Фраза \"" .. val .. "\" уже присутствует в списке фраз оскорбления родных.", -1)
            return false  
        end    
    end  
    local file_write, file_line = io.open(directoryAutoMute.."/rod.txt", 'w'), 1
    onscene_rod[#onscene_rod + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_rod) do  
        file_write:write(val .. "\n")
    end  
    file_write:close() 
    sampAddChatMessage(tag .. " Фраза \"" .. atlibs.string_rlower(param) .. "\" успешно добавлена в список фраз оскорблений родных", -1)
end

function delete_rod(param)
    if param == nil then  
        return false  
    end  
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/rod.txt", "w"), 1
    for i, val in ipairs(onscene_rod) do
        if val == atlibs.string_rlower(param) then
            onscene_rod[i] = nil
            control_onscene_rod = true
        else
            file_write:write(val .. "\n")
        end
    end
    file_write:close()
    if control_onscene_rod then
        sampAddChatMessage(tag .. " Фраза \"" .. atlibs.string_rlower(param) .. "\" была успешно удалено из списка фраз оскорблений родных", -1)
        control_onscene_rod = false
    else
        sampAddChatMessage(tag .. " Фразы \"" .. atlibs.string_rlower(param) .. "\" нет в списке фраз оскорблений родных", -1)
    end
end

function save_upom(param)
    if param == nil then  
        return false 
    end 
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    for _, val in ipairs(onscene_upom) do 
        if atlibs.string_rlower(param) == val then  
            sampAddChatMessage(tag .. " Фраза \"" .. val .. "\" уже присутствует в списке фраз упоминаний сторонних проектов.", -1)
            return false 
        end 
    end 
    local file_read, file_line = io.open(directoryAutoMute.. "/upom.txt", "w"), 1
    onscene_upom[#onscene_upom + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_upom) do 
        file_read:write(val .. "\n")
    end 
    file_read:close() 
    sampAddChatMessage(tag .. " Фраза \"" .. atlibs.string_rlower(param) .. "\" успешно добавлена в список фраз упоминаний сторонних проектов.", -1)
end

function delete_upom(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    local file_read, file_read = io.open(directoryAutoMute.. "/upom.txt", "w"), 1
    for i, val in ipairs(onscene_upom) do
        if val == atlibs.string_rlower(param) then
            onscene_upom[i] = nil
            control_onscene_upom = true
        else
            file_read:write(val .. "\n")
        end
    end
    file_read:close()
    if control_onscene_upom then
        sampAddChatMessage(tag .. " Фраза \"" .. atlibs.string_rlower(param) .. "\" была успешно удалено из списка фраз упоминаний сторонних проектов.", -1)
        control_onscene_upom = false
    else
        sampAddChatMessage(tag .. " Фразы \"" .. atlibs.string_rlower(param) .. "\" нет в списке фраз упоминаний сторонних проектов.", -1)
    end
end

function save_osk(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    for _, val in ipairs(onscene_osk) do
        if atlibs.string_rlower(param) == val then
            sampAddChatMessage(tag .. " Слово \"" .. val .. "\" уже присутствует в списке оскорблений/унижений.", -1)
            return false
        end
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/osk.txt", "w"), 1
    onscene_osk[#onscene_osk + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_osk) do
        file_write:write(val .. "\n")
    end
    file_write:close()
    sampAddChatMessage(tag .. " Слово \"" .. atlibs.string_rlower(param) .. "\" успешно добавлено в список оскорблений/унижений.", -1)
end

function delete_osk(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/osk.txt", "w"), 1
    for i, val in ipairs(onscene_osk) do
        if val == atlibs.string_rlower(param) then
            onscene_osk[i] = nil
            control_onscene_osk = true
        else
            file_write:write(val .. "\n")
        end
    end
    file_write:close()
    if control_onscene_osk then
        sampAddChatMessage(tag .. " Слово \"" .. atlibs.string_rlower(param) .. "\" было успешно удалено из списка оскорблений/унижений.", -1)
        control_onscene_osk = false
    else
        sampAddChatMessage(tag .. " Слова \"" .. atlibs.string_rlower(param) .. "\" нет в списке оскорблений/унижений.", -1)
    end
end

function save_mat(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    for _, val in ipairs(onscene_mat) do
        if atlibs.string_rlower(param) == val then
            sampAddChatMessage(tag .. " Слово \"" .. val .. "\" уже присутствует в списке нецензурной брани.", -1)
            return false
        end
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/mat.txt", "w"), 1
    onscene_mat[#onscene_mat + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_mat) do
        file_write:write(val .. "\n")
    end
    file_write:close()
    sampAddChatMessage(tag .. " Слово \"" .. atlibs.string_rlower(param) .. "\" успешно добавлено в список нецензурной лексики.", -1)
end

function delete_mat(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "Вы ввели пустой текст.", -1)
        return false 
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/mat.txt", "w"), 1
    for i, val in ipairs(onscene_mat) do
        if val == atlibs.string_rlower(param) then
            onscene_mat[i] = nil
            control_onscene_mat = true
        else
            file_write:write(val .. "\n")
        end
    end
    file_write:close()
    if control_onscene_mat then
        sampAddChatMessage(tag .. " Слово \"" .. atlibs.string_rlower(param) .. "\" было успешно удалено из списка нецензурной брани.", -1)
        control_onscene_mat = false
    else
        sampAddChatMessage(tag .. " Слова \"" .. atlibs.string_rlower(param) .. "\" нет в списке нецензурщины.", -1)
    end
end
-- ## Блок функций, отвечающий на введенные в блоке регистра команды. Применяется к автомуту ## --

-- ## Блок функций, отвечающий за чтение файлов автомута для ввода необходимых слов ## --
function check_files_automute(param) 
    if param == "mat" then  
        local file_check = assert(io.open(getWorkingDirectory() .. '/config/AdminTool/AutoMute/mat.txt', 'r'))
        local t = file_check:read("*all")
        file_check:close()
            return t
    elseif param == "osk" then  
        local file_check = assert(io.open(getWorkingDirectory() .. '/config/AdminTool/AutoMute/osk.txt', 'r'))
        local t = file_check:read("*all")
        file_check:close()     
            return t   
    elseif param == "oskrod" then  
        local file_check = assert(io.open(getWorkingDirectory() .. '/config/AdminTool/AutoMute/rod.txt', 'r'))
        local t = file_check:read("*all")
        file_check:close()        
            return t
    elseif param == "upomproject" then  
        local file_check = assert(io.open(getWorkingDirectory() .. '/config/AdminTool/AutoMute/upom.txt', 'r'))
        local t = file_check:read("*all")
        file_check:close()        
            return t        
    end
end
-- ## Блок функций, отвечающий за чтение файлов автомута для ввода необходимых слов ## --

-- ## Блок функций к выдачи наказаний мута ## --
function cmd_flood(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/mute " .. arg1 .. " 120 " .. " Флуд/Спам ")
        elseif arg2 == '2' then  
            sampSendChat("/mute " .. arg1 .. " 240 " .. " Флуд/Спам x2")
        elseif arg2 == '3' then  
            sampSendChat("/mute " .. arg1 .. " 360 " .. " Флуд/Спам x3")
        elseif arg2 == '4' then  
            sampSendChat("/mute " .. arg1 .. " 480 " .. " Флуд/Спам x4")
        elseif arg2 == '5' then  
            sampSendChat("/mute " .. arg1 .. " 600 " .. " Флуд/Спам x5")
        elseif arg2 == '6' then  
            sampSendChat("/mute " .. arg1 .. " 720 " .. " Флуд/Спам x6")
        elseif arg2 == '7' then  
            sampSendChat("/mute " .. arg1 .. " 840 " .. " Флуд/Спам x7")
        elseif arg2 == '8' then  
            sampSendChat("/mute " .. arg1 .. " 960 " .. " Флуд/Спам x8")
        elseif arg2 == '9' then  
            sampSendChat("/mute " .. arg1 .. " 1080 " .. " Флуд/Спам x9")
        elseif arg2 == '10' then  
            sampSendChat("/mute " .. arg1 .. " 1200 " .. " Флуд/Спам x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/mute " .. arg .. " 120 " .. " Флуд/Спам ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /fd [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end


function cmd_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/mute " .. arg1 .. " 120 " .. " Попрошайничество ")
        elseif arg2 == '2' then  
            sampSendChat("/mute " .. arg1 .. " 240 " .. " Попрошайничество x2")
        elseif arg2 == '3' then  
            sampSendChat("/mute " .. arg1 .. " 360 " .. " Попрошайничество x3")
        elseif arg2 == '4' then  
            sampSendChat("/mute " .. arg1 .. " 480 " .. " Попрошайничество x4")
        elseif arg2 == '5' then  
            sampSendChat("/mute " .. arg1 .. " 600 " .. " Попрошайничество x5")
        elseif arg2 == '6' then  
            sampSendChat("/mute " .. arg1 .. " 720 " .. " Попрошайничество x6")
        elseif arg2 == '7' then  
            sampSendChat("/mute " .. arg1 .. " 840 " .. " Попрошайничество x7")
        elseif arg2 == '8' then  
            sampSendChat("/mute " .. arg1 .. " 960 " .. " Попрошайничество x8")
        elseif arg2 == '9' then  
            sampSendChat("/mute " .. arg1 .. " 1080 " .. " Попрошайничество x9")
        elseif arg2 == '10' then  
            sampSendChat("/mute " .. arg1 .. " 1200 " .. " Попрошайничество x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/mute " .. arg .. " 120 " .. " Попрошайничество ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /po [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_zs(arg)
	if #arg > 0 then 
		sampSendChat("/mute " .. arg .. " 600 " .. " Злоуп.символами ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_m(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 300 " .. " Нецензурная лексика. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ia(arg)
	if #arg > 0 then
		sampSendChat("/mute " ..  arg .. " 2500 " .. " Выдача себя за администрацию ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_kl(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 3000 " .. " Клевета на администрацию ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_oa(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 2500 " .. " Оск/Униж.администрации  ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ok(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 400 " .. " Оскорбление/Унижение. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_nm2(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 2500 " .. " Неадекватное поведение ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_nm3(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " ..  " Неадекватное поведение ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_or(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " .. " Оскорбление/Упоминание родных ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_nm1(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 900 " .. " Неадекватное поведение ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_up(arg)
	lua_thread.create(function()
		if #arg > 0 then
			sampSendChat("/mute " .. arg .. " 1000 " .. " Упоминание сторонних проектов ")
			wait(1000)
			sampSendChat("/cc ")
			sampAddChatMessage(tag .. "Очистка чата связи с выдачей мута.")
		else 
			sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
		end
	end)
end

function cmd_rz(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " .. " Розжиг межнац. розни")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end	

-- ## Блок функций к выдаче репорт-наказаний мута ## --
function cmd_rup(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 1000 " .. " Упоминание сторонних проектов. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ror(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 5000 " .. " Оскорбление/Упоминание родных ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_cpfd(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/rmute " .. arg1 .. " 120 " .. " caps/offtop ")
        elseif arg2 == '2' then  
            sampSendChat("/rmute " .. arg1 .. " 240 " .. " caps/offtop x2")
        elseif arg2 == '3' then  
            sampSendChat("/rmute " .. arg1 .. " 360 " .. " caps/offtop x3")
        elseif arg2 == '4' then  
            sampSendChat("/rmute " .. arg1 .. " 480 " .. " caps/offtop x4")
        elseif arg2 == '5' then  
            sampSendChat("/rmute " .. arg1 .. " 600 " .. " caps/offtop x5")
        elseif arg2 == '6' then  
            sampSendChat("/rmute " .. arg1 .. " 720 " .. " caps/offtop x6")
        elseif arg2 == '7' then  
            sampSendChat("/rmute " .. arg1 .. " 840 " .. " caps/offtop x7")
        elseif arg2 == '8' then  
            sampSendChat("/rmute " .. arg1 .. " 960 " .. " caps/offtop x8")
        elseif arg2 == '9' then  
            sampSendChat("/rmute " .. arg1 .. " 1080 " .. " caps/offtop x9")
        elseif arg2 == '10' then  
            sampSendChat("/rmute " .. arg1 .. " 1200 " .. " caps/offtop x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/rmute " .. arg .. " 120 " .. " caps/offtop ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /cp [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_report_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/rmute " .. arg1 .. " 120 " .. " Попрошайничество ")
        elseif arg2 == '2' then  
            sampSendChat("/rmute " .. arg1 .. " 240 " .. " Попрошайничество x2")
        elseif arg2 == '3' then  
            sampSendChat("/rmute " .. arg1 .. " 360 " .. " Попрошайничество x3")
        elseif arg2 == '4' then  
            sampSendChat("/rmute " .. arg1 .. " 480 " .. " Попрошайничество x4")
        elseif arg2 == '5' then  
            sampSendChat("/rmute " .. arg1 .. " 600 " .. " Попрошайничество x5")
        elseif arg2 == '6' then  
            sampSendChat("/rmute " .. arg1 .. " 720 " .. " Попрошайничество x6")
        elseif arg2 == '7' then  
            sampSendChat("/rmute " .. arg1 .. " 840 " .. " Попрошайничество x7")
        elseif arg2 == '8' then  
            sampSendChat("/rmute " .. arg1 .. " 960 " .. " Попрошайничество x8")
        elseif arg2 == '9' then  
            sampSendChat("/rmute " .. arg1 .. " 1080 " .. " Попрошайничество x9")
        elseif arg2 == '10' then  
            sampSendChat("/rmute " .. arg1 .. " 1200 " .. " Попрошайничество x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/rmute " .. arg .. " 120 " .. " Попрошайничество ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /rpo [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_rm(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 300 " .. " Нецензурная лексика. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_roa(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 2500 " .. " Оск/Униж.администрации  ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_report_neadekvat(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '2' then
		    sampSendChat("/rmute " .. arg1 .. " 1800 " .. " Неадекватное поведение x2")
        elseif arg2 == '3' then  
            sampSendChat("/rmute " .. arg1 .. " 3000 " .. " Неадекватное поведение x3")
        elseif arg2 == '1' then  
            sampSendChat("/rmute " .. arg1 .. " 900 " .. " Неадекватное поведение")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/rmute " .. arg .. " 900 " .. " Неадекватное поведение")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /rnm [IDPlayer] [~Множитель (от 2-3)]", -1)
	end
end

function cmd_rok(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 400 " .. " Оскорбление/Унижение. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_rrz(arg)
	if #arg > 0 then 
		sampSendChat("/rmute " .. arg .. " 5000 " .. " Розжиг межнац. розни")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end	
-- ## Блок функций к выдаче репорт-наказаний мута ## --

-- ## Блок функций к выдачи offline-наказаний мута ## --
function cmd_azs(arg)
	if #arg > 0 then  
		sampSendChat("/muteakk"  .. arg .. " 600 " .. " Злоуп.символами")
	else  
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end 
end		

function cmd_afd(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 120 " .. " Спам/Флуд")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_apo(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 120 " .. " Попрошайничество ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_am(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 300 " .. " Нецензурная лексика.")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_aok(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 400 " .. " Оскорбление/Унижение. ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_offline_neadekvat(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '2' then
		    sampSendChat("/muteakk " .. arg1 .. " 1800 " .. " Неадекватное поведение x2")
        elseif arg2 == '3' then  
            sampSendChat("/muteakk " .. arg1 .. " 3000 " .. " Неадекватное поведение x3")
        elseif arg2 == '1' then  
            sampSendChat("/muteakk " .. arg1 .. " 900 " .. " Неадекватное поведение")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/muteakk " .. arg .. " 900 " .. " Неадекватное поведение")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /anm [IDPlayer] [~Множитель (от 2-3)]", -1)
	end
end


function cmd_aoa(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 2500 " .. " Оск/Униж.администрации ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_aor(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 5000 " .. " Оскорбление/Упоминание родных ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_aup(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 1000 " .. " Упоминание иного проекта ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end 

function cmd_aia(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 2500 " .. " Выдача себя за администратора ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_akl(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 3000 " .. " Клевета на администрацию ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_arz(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 5000 " .. " Розжиг межнац. розни ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end	
-- ## Блок функций к выдачи offline-наказаний мута ## --

-- ## Блок функций к выдачи наказаний джайла ## -- 
function cmd_sk(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " Spawn Kill")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_dz(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/jail " .. arg1 .. " 300 " .. " DM/DB in zz ")
        elseif arg2 == '2' then  
            sampSendChat("/jail " .. arg1 .. " 600 " .. " DM/DB in zz x2")
        elseif arg2 == '3' then  
            sampSendChat("/jail " .. arg1 .. " 900 " .. " DM/DB in zz x3")
        elseif arg2 == '4' then  
            sampSendChat("/jail " .. arg1 .. " 1200 " .. " DM/DB in zz x4")
        elseif arg2 == '5' then  
            sampSendChat("/jail " .. arg1 .. " 1500 " .. " DM/DB in zz x5")
        elseif arg2 == '6' then  
            sampSendChat("/jail " .. arg1 .. " 1800 " .. " DM/DB in zz x6")
        elseif arg2 == '7' then  
            sampSendChat("/jail " .. arg1 .. " 2100 " .. " DM/DB in zz x7")
        elseif arg2 == '8' then  
            sampSendChat("/jail " .. arg1 .. " 2400 " .. " DM/DB in zz x8")
        elseif arg2 == '9' then  
            sampSendChat("/jail " .. arg1 .. " 2700 " .. " DM/DB in zz x9")
        elseif arg2 == '10' then  
            sampSendChat("/jail " .. arg1 .. " 3000 " .. " DM/DB in zz x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/jail " .. arg .. " 120 " .. " DM/DB in zz ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /dz [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_td(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " DB/car in trade ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_jm(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " Нарушение правил МП ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_pmx(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " Серьезная помеха игрокам ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_skw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " SK in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_dgw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 500 " .. " Использование наркотиков in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ngw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " Использование запрещенных команд in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_dbgw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " Использование вертолета in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_fsh(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " Использование SpeedHack/FlyCar ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_bag(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " Игровой багоюз (deagle in car)")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_pk(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " Использование паркур мода ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_jch(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 3000 " .. " Использование читерского скрипта/ПО ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_zv(arg)
	if #arg > 0 then
		sampSendChat("/jail " ..  arg .. " 3000 " .. " Злоупотребление VIP`om ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_sch(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " Использование запрещенных скриптов ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_jcw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " Использование ClickWarp/Metla (ИЧС)")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_tdbz(arg)
	if #arg > 0 then  
		sampSendChat("/jail " .. arg .. " 900 " .. " ДБ с Ковшом (zz)")
	else  
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)	
	end 
end	
-- ## Блок функций к выдачи наказаний джайла ## -- 

-- ## Блок функций к выдачи offline-наказаний джайла ## -- 
function cmd_asch(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " Использование запрещенных скриптов ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_ajch(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 3000 " .. " Использование читерского скрипта/ПО ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_azv(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " ..  arg .. " 3000 " .. " Злоупотребление VIP`om ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_adgw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 500 " .. " Использование наркотиков in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_ask(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " SpawnKill ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_adz(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/prisonakk " .. arg1 .. " 300 " .. " DM/DB in zz ")
        elseif arg2 == '2' then  
            sampSendChat("/prisonakk " .. arg1 .. " 600 " .. " DM/DB in zz x2")
        elseif arg2 == '3' then  
            sampSendChat("/prisonakk " .. arg1 .. " 900 " .. " DM/DB in zz x3")
        elseif arg2 == '4' then  
            sampSendChat("/prisonakk " .. arg1 .. " 1200 " .. " DM/DB in zz x4")
        elseif arg2 == '5' then  
            sampSendChat("/prisonakk " .. arg1 .. " 1500 " .. " DM/DB in zz x5")
        elseif arg2 == '6' then  
            sampSendChat("/prisonakk " .. arg1 .. " 1800 " .. " DM/DB in zz x6")
        elseif arg2 == '7' then  
            sampSendChat("/prisonakk " .. arg1 .. " 2100 " .. " DM/DB in zz x7")
        elseif arg2 == '8' then  
            sampSendChat("/prisonakk " .. arg1 .. " 2400 " .. " DM/DB in zz x8")
        elseif arg2 == '9' then  
            sampSendChat("/prisonakk " .. arg1 .. " 2700 " .. " DM/DB in zz x9")
        elseif arg2 == '10' then  
            sampSendChat("/prisonakk " .. arg1 .. " 3000 " .. " DM/DB in zz x10")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/prisonakk " .. arg .. " 120 " .. " DM/DB in zz ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /adz [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_atd(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " DB/car in trade ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_ajm(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " Нарушение правил МП ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_apmx(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " Серьезная помеха игрокам ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_askw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " SK in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_angw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " Использование запрещенных команд in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_adbgw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " db-верт, стрельба с авт/мото/крыши in /gw ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_afsh(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " Использование SpeedHack/FlyCar ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_abag(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " Игровой багоюз (deagle in car)")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_apk(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " Использование паркур мода ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end

function cmd_ajcw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " Использование ClickWarp/Metla (ИЧС)")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NICK нарушителя! ", -1)
	end
end
-- ## Блок функций к выдачи offline-наказаний джайла ## -- 

-- ## Блок функций к выдачи наказаний бана ## -- 
function cmd_hl(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 3 " .. " Оскорбление/Унижение/Мат в хелпере")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)	
	end
end

function cmd_pl(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " Плагиат ника администратора ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ob(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " Обход прошлого бана ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end 	

function cmd_gcnk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " Банда, содержащая нецензурную лексину ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_menk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " Ник, содержающий запрещенные слова ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_ch(arg)
	if #arg > 0 then
		lua_thread.create(function()
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " Использование читерского скрипта/ПО. ")
		end)
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_nk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " Ник, содержащий нецензурную лексику ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_bnm(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " Уважаемый игрок, вы нарушали правила сервера, и если вы..")
		sampSendChat("/ans " .. arg .. " ..не согласны с наказанием, напишите жалобу на форум https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " Неадекватное поведение")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end	
-- ## Блок функций к выдачи наказаний бана ## -- 

-- ## Блок функций к выдачи offline-наказаний бана ## --
function cmd_amenk(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " Ник, содержающий запрещенные слова ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end


function cmd_ahl(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 3 " .. " Оск/Унижение/Мат в хелпере")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_ahli(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 3 " .. " Оск/Унижение/Мат в хелпере")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести IP нарушителя! ", -1)
	end
end

function cmd_aob(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. " Обход бана ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_apl(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. " Плагиат никнейма администратора")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_ach(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. "  Использование читерского скрипта/ПО ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_achi(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 7 " .. " ИЧС/ПО (ip) ") 
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести IP нарушителя! ", -1)
	end
end

function cmd_ank(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " Ник, содержащий нецензурщину ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_agcnk(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " Банда, содержит нецензурщину")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end

function cmd_agcnkip(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 7 "  .. " Банда, содержит нецензурщину (ip)")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести IP нарушителя! ", -1)
	end
end

function cmd_rdsob(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 30 " .. " Обман администрации/игроков")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести NickName нарушителя! ", -1)
	end
end	

function cmd_rdsip(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 30 " .. " Обман администрации/игроков")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести IP нарушителя! ", -1)
	end
end	

function cmd_abnm(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " Неадекватное поведение")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести IP нарушителя! ", -1)
	end
end	
-- ## Блок функций к выдачи offline-наказаний бана ## --

-- ## Блок функций к выдачи наказаний кика ## --
function cmd_dj(arg)
	if #arg > 0 then
		sampSendChat("/kick " .. arg .. " DM in Jail ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end

function cmd_gnk(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/kick " .. arg1 .. " Смените никнейм. 1/3 ")
        elseif arg2 == '2' then  
            sampSendChat("/kick " .. arg1 .. " Смените никнейм. 2/3")
        elseif arg2 == '3' then  
            sampSendChat("/kick " .. arg1 .. " Смените никнейм. 3/3")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/kick " .. arg .. " Смените никнейм. 1/3 ")
    else
        sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
        sampAddChatMessage(tag .. " Используйте: /gnk [IDPlayer] [~Множитель (от 2 до 10)]", -1)
	end
end

function cmd_cafk(arg)
	if #arg > 0 then
		sampSendChat("/kick " .. arg .. " AFK in /arena ")
	else 
		sampAddChatMessage(tag .. "Вы забыли ввести ID нарушителя! ", -1)
	end
end
-- ## Блок функций к выдачи наказаний кика ## --

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
	    sampSendChat("/rmute " .. arg .. " 5 " .. "  Mistake/Ошибка")
        
	    sampSendChat("/ans " .. arg .. " Извиняемся за ошибку, наказание снято. Приятной игры.")
    end)
end
-- ## Блок функций к вспомогательным командам ## --

-- ## Блок функций для пакетов SA:MP ## --
function sampev.onServerMessage(color, text)
	local check_string = string.match(text, "[^%s]+")

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

	local check_nick, check_id, basic_color, check_text = string.match(text, "(.+)%((.+)%): {(.+)}(.+)") -- захват основной строчки чата и разбития её на объекты

    -- ## Автомут, чей mainframe - репорты ## --
    if not isGamePaused() and not isPauseMenuActive() then  
        if text:find("Жалоба (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") then  
            local number_report, nick_rep, id_rep, text_rep = text:match("Жалоба (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") 
            sampAddChatMessage(tag .. "Пришел репорт " .. number_report .. " от " .. nick_rep .. "[" .. id_rep .. "]: " .. text_rep, -1)
            if elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_rod[0] or elements.settings.automute_rod[0] then  
                local mat_text, _ = checkMessage(text_rep, 1)
                local osk_text, _ = checkMessage(text_rep, 2)
                local upom_text, _ = checkMessage(text_rep, 3)
                local rod_text, _ = checkMessage(text_rep, 4)
                if mat_text and elements.settings.automute_mat[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | Мут ID[" .. id_rep .. "] за rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 300 Нецензурная лексика")
                end
                if osk_text and elements.settings.automute_osk[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | Мут ID[" .. id_rep .. "] за rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 400 Оск/Униж.")
                end
                if upom_text and elements.settings.automute_upom[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | Мут ID[" .. id_rep .. "] за rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 1000 Упом.стор.проектов")
                end
                if rod_text and elements.settings.automute_rod[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | Мут ID[" .. id_rep .. "] за rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 5000 Оск/Униж. родных")
                end
            end  
            return true
        end
    end
    -- ## Автомут, чей mainframe - репорты ## --

    -- ## Автомут, чей mainframe - чат ## --
    if not isGamePaused() and not isPauseMenuActive() then  
        if check_text ~= nil and check_id ~= nil and (elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_upom[0] or elements.settings.automute_rod[0]) then  
            local mat_text, _ = checkMessage(check_text, 1)
            local osk_text, _ = checkMessage(check_text, 2)
            local upom_text, _ = checkMessage(check_text, 3)
            local rod_text, _ = checkMessage(check_text, 4)
            if mat_text and elements.settings.automute_mat[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | Мут " .. check_nick .. "[" .. check_id .. "] за msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 300 Нецензурная лексика")
            end
            if osk_text and elements.settings.automute_osk[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | Мут " .. check_nick .. "[" .. check_id .. "] за msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 400 Оск/Униж.")
            end
            if upom_text and elements.settings.automute_upom[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | Мут " .. check_nick .. "[" .. check_id .. "] за msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 1000 Упом.стор.проектов")
            end
            if rod_text and elements.settings.automute_rod[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | Мут " .. check_nick .. "[" .. check_id .. "] за msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 5000 Оск/Униж. родных")
            end
            return true
        end
    end 
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
    if (id == 2056 or id == 2059) and elements.boolean.recon[0] then  
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
		end
	end
end

function sampev.onShowTextDraw(id, data)
    if elements.boolean.recon[0] then 
		if id >= 183 and id <= 226 then  
			return false 
		end
		if data.text:find('~g~::Health:~n~') then  
			return false
		end
        -- for _, i in pairs(ids_recon) do  
        --     if id == i then  
        --         return false  
        --     end 
        -- end
		if id == 2052 then  
			return false  
		end
		if id == 2059 then  
			return false  
		end
    end
end
-- ## Загрузка системы рекона ## -- 


local ReconWindow = imgui.OnFrame(
    function() return elements.imgui.recon_window[0] end, 
    function(player)
        
        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 6, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(100, 300), imgui.Cond.FirstUseEver)

        imgui.LockPlayer = false  

        imgui.Begin("reconmenu", elements.imgui.recon_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize)
            if control_to_player then  
                
                if imgui.Button(u8"Заспавнить") then  
                    sampSendChat('/aspawn ' .. recon_id)
                end
                if imgui.Button(u8"Обновить") then  
                    -- sampSendClickTextdraw(156)
					sampSendClickTextdraw(198)
                end
                if imgui.Button(u8"Слапнуть") then  
                    sampSendChat("/slap " .. recon_id)
                end
                if imgui.Button(u8"Заморозить\nРазморозить") then  
                    sampSendChat("/freeze " .. recon_id)
                end
                if imgui.Button(u8"Выйти") then
                    sampSendChat("/reoff ")
                    control_to_player = false
                    elements.imgui.recon_window[0] = false
                end
            end
        imgui.End()

        if right_recon[0] then  
            imgui.SetNextWindowPos(imgui.ImVec2(sw - 200, sh - 200), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(400, 600), imgui.Cond.FirstUseEver)

            imgui.Begin(u8"Информация об игроке", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
				if accept_load_recon then
					if not sampIsPlayerConnected(recon_id) then 
						recon_nick = '-'
					else
						recon_nick = sampGetPlayerNickname(recon_id)
					end
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
							imgui.Text(u8:encode(recon_info[key]) .. " " .. info_to_player[key])
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
AT был сделан alfantasyz.
Группа разработчика:
https://vk.com/infsy
]]

local textToMenuSelectableAutoMute = [[
Данное подокно позволяет настроить автомут под свои нужды. 
Вы можете изменить нужные файлы, 
посредством выбора необходимых файлов и внесении туда слов.
]]

local MainWindowAT = imgui.OnFrame(
    function() return elements.imgui.main_window[0] end,
    function(player) 

        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(1000, 600), imgui.Cond.FirstUseEver)

        imgui.Begin(fa.SERVER .. " [AT for Android]", elements.imgui.main_window, imgui.WindowFlags.NoResize) 
			if imgui.BeginTabBar("##MenuBar") then  
				if imgui.BeginTabItem(fa.HOUSE .. u8" Приветствие") then  
					imgui.Text(u8(helloText))
					imgui.EndTabItem()
				end  
				if imgui.BeginTabItem(fa.USER_GEAR .. u8" Основные функции") then  
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
						imgui.Text(u8"Кастомное рекон-меню")
						imgui.SameLine()
						if mim_addons.ToggleButton("##CustomReconMenu", elements.boolean.recon) then  
							config.settings.custom_recon = elements.boolean.recon[0]
							save() 
						end
						ActiveAutoMute()
					imgui.EndTabItem()
				end
				if imgui.BeginTabItem(fa.BOOK .. u8" Автомут") then  
					imgui.Text(u8(textToMenuSelectableAutoMute))
					ReadWriteAM()
					imgui.EndTabItem()
				end  
				if imgui.BeginTabItem(fa.LIST_OL .. u8" Наказания") then  

					if imgui.TreeNodeStr(u8"Наказания в онлайне") then 
						if imgui.TreeNodeStr("Ban") then  
							imgui.Text(u8"/ch [ID] - бан за читы")
							imgui.Text(u8"/pl [ID] - бан за плагиат ника админа ")
							imgui.Text(u8"/nk [ID] - бан за ник с оском/унижением")
							imgui.Text(u8"/gcnk [ID] - бан за название банды с оском/унижением")
							imgui.Text(u8"/brekl [ID] - бан за рекламе | for 18 lvl ")
							imgui.Text(u8"/hl [ID] - бан за оск в хелпере")
							imgui.Text(u8"/ob [ID] - бан за обход бана")
							imgui.Text(u8"/menk [ID] - бан за запрет.слова в нике")
							imgui.Text(u8"/bnm [ID] - бан за неадеквата")
							imgui.Text(u8"/bosk [ID] - бан за оск проекта | for 18 lvl ")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							imgui.Text(u8"/sk [ID] - jail за SK in zz")
							imgui.Text(u8"/dz [ID] [Множитель от 2 до 10] - jail за DM/DB in zz")
							imgui.Text(u8"/td [ID] - jail за DB/car in /trade")
							imgui.Text(u8"/tdbz [ID] - jail за DB с Ковшом в ЗЗ")
							imgui.Text(u8"/fsh [ID] - /jail за SH and FC")
							imgui.Text(u8"/jm [ID] - jail за нарушение правил мероприятия.")
							imgui.Text(u8"/bag [ID] - jail за багоюз")
							imgui.Text(u8"/pk [ID] - jail за паркур мод")
							imgui.Text(u8"/zv [ID] - jail за злоуп.вип")
							imgui.Text(u8"/skw [ID] - jail за SK на /gw")
							imgui.Text(u8"/ngw [ID] - jail за использование запрет.команд на /gw")
							imgui.Text(u8"/dbgw [ID] - jail за DB вертолет на /gw")
							imgui.Text(u8"/jch [ID] - jail за читы")
							imgui.Text(u8"/pmx [ID] - jail за серьезная помеха игрокам")
							imgui.Text(u8"/dgw [ID] - jail за наркотики на /gw")
							imgui.Text(u8"/sch [ID] - jail за запрещенные скрипты")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							imgui.Text(u8"/m [ID] - мут за мат | /rm - мут за мат в репорт ")
							imgui.Text(u8"/ok [ID] - мут за оскорбление/унижение")
							imgui.Text(u8"/fd [ID] [Множитель от 2 до 10] - мут за флуд/спам x1-x10")
							imgui.Text(u8"/po [ID] [Множитель от 2 до 10]- мут за попрошайку x1-x10")
							imgui.Text(u8"/oa [ID] - мут за оск.адм ")
							imgui.Text(u8"/roa [ID] - мут за оск.адм в репорт")
							imgui.Text(u8"/up [ID] - мут за упом.проекта")
							imgui.Text(u8"/rup [ID] - мут за упом.проекта в репорт")
							imgui.Text(u8"/ia [ID] - мут за выдачу себя за адм")
							imgui.Text(u8"/kl [ID] - мут за клевету на адм")
							imgui.Text(u8"/nm [ID] [Множитель от 2 до 3] - мут за неадекват. ")
							imgui.Text(u8"/rnm [ID] [Множитель от 2 до 3] - мут за неадекват в реп.")
							imgui.Text(u8"/or [ID] - мут за оск род")
							imgui.Text(u8"/rz [ID] - розжиг межнац.розни")
							imgui.Text(u8"/zs [ID] - злоупотребление символами")
							imgui.Text(u8"/ror [ID] - мут за оск род в репорт")
							imgui.Text(u8"/cp [ID] [Множитель от 2 до 10] - капс/оффтоп в репорт x1-x10")
							imgui.Text(u8"/rpo [ID] [Множитель от 2 до 10] - попрошайка в репорт x1-x10")
							imgui.Text(u8"/rkl [ID] - клевета на адм в репорт")
							imgui.Text(u8"/rrz [ID] - розжиг межнац.розни в репорт")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Kick") then  
							imgui.Text(u8"/dj [ID] - кик за dm in jail")
							imgui.Text(u8"/gnk [ID] [от 1 до 3] - кик за нецензуру в нике. \n     Второе значение отвечает за количество киков в совокупности.")
							imgui.Text(u8"/cafk [ID] - кик за афк на арене")
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"Наказания в оффлайне") then  
						if imgui.TreeNodeStr("Ban") then  
							imgui.Text(u8"/apl [NickName] - бан за плагиат ник админа")
							imgui.Text(u8"/ach [NickName] (/achi [IP]) - бан за читы (ip)")
							imgui.Text(u8"/ank [NickName] - бан за ник с оск/униж")
							imgui.Text(u8"/agcnk [NickName] - бан за название банды с оск/униж")
							imgui.Text(u8"/agcnkip [NickName] - бан по IP за название банды с оск/униж")
							imgui.Text(u8"/okpr/ip [NickName] - оск проекта")
							imgui.Text(u8"/svoakk/ip [NickName] - бан по акк/IP по рекламе")
							imgui.Text(u8"/ahl [NickName] (/achi) [IP] - бан за оск в хелпере (ip)")
							imgui.Text(u8"/aob [NickName] - бан за обход бана")
							imgui.Text(u8"/rdsob [NickName] - бан за обман адм/игроков")
							imgui.Text(u8"/rdsip [NickName] - бан по IP за обман адм/игроков")
							imgui.Text(u8"/amenk [NickName] - бан за запрет.слова в нике")
							imgui.Text(u8"/abnm  [NickName] - бан за неадеквата")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							imgui.Text(u8"/ask [NickName] - jail за SK in zz")
							imgui.Text(u8"/adz [NickName] [Множитель от 2 до 10] - jail за DM/DB in zz")
							imgui.Text(u8"/atd [NickName] - jail за DB/CAR in trade")
							imgui.Text(u8"/afsh [NickName] - jail за SH ans FC")
							imgui.Text(u8"/ajm [NickName] - jail за наруш.правил МП")
							imgui.Text(u8"/abag [NickName] - jail за багоюз")
							imgui.Text(u8"/apk [NickName] - jail за паркур мод")
							imgui.Text(u8"/azv [NickName] - jail за злоуп.вип")
							imgui.Text(u8"/askw [NickName] - jail за SK на /gw")
							imgui.Text(u8"/angw [NickName] - исп.запрет.команд на /gw")
							imgui.Text(u8"/adbgw [NickName] - jail за DB верт на /gw")
							imgui.Text(u8"/ajch [NickName] - jail за читы")
							imgui.Text(u8"/apmx [NickName] - jail за серьез.помеху")
							imgui.Text(u8"/adgw [NickName] - jail за наркотики на /gw")
							imgui.Text(u8"/asch [NickName] - jail за запрещенные скрипты")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							imgui.Text(u8"/am [NickName] - мут за мат ")
							imgui.Text(u8"/aok [NickName] - мут за оск ")
							imgui.Text(u8"/afd [NickName] - мут за флуд/спам")
							imgui.Text(u8"/apo [NickName]  - мут за попрошайку")
							imgui.Text(u8"/aoa [NickName] - мут за оск.адм")
							imgui.Text(u8"/aup [NickName] - мут за упоминание проектов")
							imgui.Text(u8"/anm [NickName] [Множитель от 2 до 3]- мут за неадеквата")
							imgui.Text(u8"/aor [NickName] - мут за оск/упом родных")
							imgui.Text(u8"/aia [NickName] - мут за выдачу себя за адм")
							imgui.Text(u8"/akl [NickName] - мут за клевету на адм")
							imgui.Text(u8"/arz [NickName] - мут за розжиг межнац.розни")
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"Дополнительные команды AT") then  
						imgui.Text(u8"/u [ID] - обычный размут")
						imgui.Text(u8"/uu [ID] - размут с сообщением в /ans")
						imgui.Text(u8"/uj [ID] - разджайлить игрока")
						imgui.Text(u8"/as [ID] - разбанить игрока")
						imgui.Text(u8"/ru [ID] - размут репорта")
						imgui.Text(u8"/rcl - очистка чата (не /cc, визуально для Вас)")
						imgui.Text(u8"/spp [ID] - заспавнить ВСЕХ игроков в зоне стрима *")
						imgui.Text(u8"     * Зона стрима - это область, в которой игра видит игроков")
						imgui.Text(u8"/aheal [ID] - отхилить игрока")
						imgui.Text(u8"/akill [ID] - убить игрока")
						imgui.TreePop()
					end
					imgui.EndTabItem()
				end 
				if imgui.BeginTabItem(fa.LIST .. u8" Биндер /ans") then   
					QuestionAnswer.BinderEdit()
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

-- ## Блок функций-экспорта для интеграций их в основной скрипт ## --
function ActiveAutoMute()
    if imgui.Button(fa.NEWSPAPER .. u8" Автомут") then  
        imgui.OpenPopup('##SettingsAutoMute')
    end  
    if imgui.BeginPopup('##SettingsAutoMute') then  
        if mim_addons.ToggleButton(u8'Автомут за мат', elements.settings.automute_mat) then  
            config.settings.automute_mat = elements.settings.automute_mat[0] 
            save()  
        end
        if mim_addons.ToggleButton(u8'Автомут за оск', elements.settings.automute_osk) then  
            config.settings.automute_osk = elements.settings.automute_osk[0]
            save() 
        end  
        if mim_addons.ToggleButton(u8'Автомут за упом.стор.проектов', elements.settings.automute_upom) then  
            config.settings.automute_upom = elements.settings.automute_upom[0]
            save()  
        end  
        if mim_addons.ToggleButton(u8'Автомут за оск родных', elements.settings.automute_rod) then  
            config.settings.automute_rod = elements.settings.automute_rod[0]
            save()  
        end
        imgui.EndPopup()
    end
end

function ReadWriteAM()
	imgui.Text(u8"Ниже представлен список файлов в виде кнопок.\nДля выбора файла, нажмите на кнопку.")
    imgui.BeginChild('##MenuRWAMF', imgui.ImVec2(230, 380), true)
        if imgui.Button(u8"Мат") then  
            elements.imgui.selectable = 1
        end  
        if imgui.Button(u8"Оск/униж") then  
            elements.imgui.selectable = 2
        end  
        if imgui.Button(u8"Упом.проектов") then  
            elements.imgui.selectable = 3
        end 
        if imgui.Button(u8"Оск родных") then  
            elements.imgui.selectable = 4
        end
    imgui.EndChild()
    imgui.SameLine()
    imgui.BeginChild('##WindowRWAMF', imgui.ImVec2(700, 380), true)
        if elements.imgui.selectable == 0 then  
            imgui.Text(u8"Редактируйте файлы аккуратно. \nКаждое Вами введенное слово будет фиксироваться \nв файле при сохранении.")
            imgui.Text(u8"На данный момент ни один файл не приведен в чтение.")
        end  
        if elements.imgui.selectable == 1 then  
            imgui.Text(u8"Для добавления/удаление слов, используйте поле ввода ниже")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
            if #ffi.string(elements.imgui.input_word) > 0 then
                if imgui.Button(u8"Добавить") then  
                    save_mat(u8:decode(ffi.string(elements.imgui.input_word)))
                end  
                if imgui.Button(u8"Удалить") then  
                    delete_mat(u8:decode(ffi.string(elements.imgui.input_word)))
                end
            end
            imgui.Separator()
            imgui.StrCopy(elements.imgui.stream, check_files_automute("mat"))
            for line in ffi.string(elements.imgui.stream):gmatch("[^\r\n]+") do  
                imgui.Text(u8(line))
            end
        end 
        if elements.imgui.selectable == 2 then  
            imgui.Text(u8"Для добавления/удаление слов, используйте поле ввода ниже")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"Добавить") then  
					save_osk(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"Удалить") then  
					delete_osk(u8:decode(ffi.string(elements.imgui.input_word)))
				end
			end
            imgui.Separator()
            imgui.StrCopy(elements.imgui.stream, check_files_automute("osk"))
            for line in ffi.string(elements.imgui.stream):gmatch("[^\r\n]+") do  
                imgui.Text(u8(line))
            end
        end 
        if elements.imgui.selectable == 3 then  
            imgui.Text(u8"Для добавления/удаление слов, используйте поле ввода ниже")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"Добавить") then  
					save_upom(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"Удалить") then  
					delete_upom(u8:decode(ffi.string(elements.imgui.input_word)))
				end
			end
            imgui.Separator()
            imgui.StrCopy(elements.imgui.stream, check_files_automute("upomproject"))
            for line in ffi.string(elements.imgui.stream):gmatch("[^\r\n]+") do  
                imgui.Text(u8(line))
            end
        end  
        if elements.imgui.selectable == 4 then  
            imgui.Text(u8"Для добавления/удаление слов, используйте поле ввода ниже")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"Добавить") then  
					save_rod(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"Удалить") then  
					delete_rod(u8:decode(ffi.string(elements.imgui.input_word)))
				end
			end
            imgui.Separator()
            imgui.StrCopy(elements.imgui.stream, check_files_automute("oskrod"))
            for line in ffi.string(elements.imgui.stream):gmatch("[^\r\n]+") do  
                imgui.Text(u8(line))
            end
        end
    imgui.EndChild()
end
-- ## Блок функций-экспорта для интеграций их в основной скрипт ## --
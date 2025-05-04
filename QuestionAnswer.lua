require 'lib.moonloader'
local imgui = require 'mimgui' -- инициализация интерфейса Moon ImGUI
local encoding = require 'encoding' -- работа с кодировками
local sampev = require 'lib.samp.events' -- интеграция пакетов SA:MP и происходящих/исходящих/входящих т.д. ивентов
local mim_addons = require 'mimgui_addons' -- интеграция аддонов для интерфейса mimgui
local fa = require 'fAwesome6_solid' -- работа с иконами на основе FontAwesome 6
local inicfg = require 'inicfg' -- работа с конфигом
local ffi = require 'ffi'
local atlibs = require 'libsfor'
local toast_ok, toast = pcall(import, 'lib/mimtoasts.lua') -- интеграция уведомлений.
encoding.default = 'CP1251' -- смена кодировки на CP1251
u8 = encoding.UTF8 -- объявление кодировки U8 как рабочую, но в форме переменной (для интерфейса)

-- ## Блок текстовых переменных ## --
local tag = "{00BFFF} [AT] {FFFFFF}" -- локальная переменная, которая регистрирует тэг AT
-- ## Блок текстовых переменных ## --

-- ## mimgui ## --
local new = imgui.new

EXPORTS = {}

function Tooltip(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(u8(text))
        imgui.EndTooltip()
    end 
end

imgui.OnInitialize(function()   
    imgui.GetIO().IniFilename = nil
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(getWorkingDirectory() .. '/lib/mimgui/trebucbd.ttf', 24.0, _, glyph_ranges)
	fa.Init(24)
end)
-- ДЛЯ ПРОВЕРКИ НАХУЙ

local sw, sh = getScreenResolution()
-- ## mimgui ## --

-- ## Система конфига и переменных VARIABLE ## --
local directIni = 'AdminTool/repsettings.ini'

local config = inicfg.load({
    main = {
        prefix_answer = false,
        prefix_for_answer = ' // Приятной игры на сервере RDS <3',
    },
    bind_name = {},
    bind_text = {},
}, directIni)
inicfg.save(config, directIni)

function save()  
    inicfg.save(config, directIni)
    return true
end

local elements = {
    repwindow = new.bool(false),
    answer = new.char[1024](),
    prefix_for_answer = new.char[256](),
    prefix_answer = new.bool(config.main.prefix_answer),
    binder_name = new.char[256](),
    binder_text = new.char[65536](),
    select_menu = 0,
    select_category = 0,
}
-- ## Система конфига и переменных VARIABLE ## --

-- ## Блок с ответами ## --
local questions = {
    ["reporton"] = {
		[u8"Игрок вышел"] = "Данный игрок покинул игру.",
        [u8"Начало работы по жалобе"] = "Начал(а) работу по вашей жалобе!",
		[u8"Иду помогать"] = "Уважаемый игрок, сейчас помогу вам!",
		[u8"Нет такой инфы у админов"] = "Данную информацию узнавайте в интернете.",
		[u8"Жалоба на админа"] = "Пишите жалобу на администратора на форум https://forumrds.ru",
		[u8"Жалоба на игрока"] = "Вы можете оставить жалобу на игрока на форум https://forumrds.ru",
        [u8"Жалоба на что-либо"] = "Вы можете оставить жалобу на форум https://forumrds.ru",
		[u8"Помогли вам"] = "Помогли вам",
		[u8"Ожидайте"] = "Ожидайте",
		[u8"Приятного времяпрепровождения"] = "Приятного времяпрепровождения на Russian Drift Server!",
		[u8"Игрок ничего не сделал"] = "Не вижу нарушений со стороны игрока",
		[u8"Игрок чист"] = " Данный игрок чист",
		[u8"Игрок не в сети"] = "Данный игрок не в сети",
		[u8"Уточнение вопрос/репорт"] = "Уточните вашу жалобу/вопрос",
		[u8"Уточнение ID"] = "Уточните ID нарушителя/читера в /report",
		[u8"Игрок наказан"] = "Данный игрок наказан",
		[u8"Проверим"] = "Проверим",
		[u8"ГМ не работает"] = "GodMode (ГодМод) на сервере не работает",
		[u8"Нет набора"] = "В данный момент набор в администрацию не проходит.",
		[u8"Сейчас сниму наказание"] = "Сейчас сниму вам наказание.",
		[u8"Баг будет исправлен"] = "Данный баг скоро будет исправлен.",
		[u8"Ошибка будет исправлена"] = "Данный ошибка скоро будет исправлена.",
		[u8"Приветствие"] = "Добрый день, уважаемый игрок.",
        [u8"Разрешено"] = "Разрешено",
		[u8"Никак"] = "Никак",
		[u8"Да"] = "Да",
		[u8"Нет"] = "Нет",
		[u8"Не запрещено"] = "Не запрещено",
		[u8"Не знаем"] = "Не знаем",
		[u8"Нельзя оффтопить"] = "Не оффтопьте",
		[u8"Не выдаем"] = "Не выдаем",
		[u8"Это баг"] = "Скорей всего - это баг",
		[u8"Перезайдите"] = "Попробуйте перезайти"

    },
	["HelpHouses"] = {
		[u8"Как добавить игрока в аренду"] = "/hpanel -> Слот1-3 -> Изменить -> Аренда дома -> Подселить соседа",
		[u8"А домик как продать"] = "/hpanel -> Слот1-3 -> Изменить -> Продать дом государству || /sellmyhouse (игроку)",
		[u8"Как купить дом"] = "Встаньте на пикап (зеленый, не красный) и нажмите F.",
        [u8"Как открыть меню дома"] = "/hpanel"
	},
	["HelpCmd"] = {
		[u8"Команды VIP`а"] = "Данную информацию можно найти в /help -> 7 пункт",
        [u8"Информация в инете"] = "Данную информацию можно узнать в интернете",
		[u8"Привелегия Premuim"] = "Данный игрок с привелегией Premuim VIP (/help -> 7)",
		[u8"Привелегия Diamond"] = "Данный игрок с привелегией Diamond VIP (/help -> 7) ",
		[u8"Привелегия Platinum"] = "Данный игрок с привелегией Platinum VIP (/help -> 7)",
		[u8"Привелегия Личный"] = "Данный игрок с привелегией «Личный» VIP (/help -> 7)",
		[u8"Команды для свадьбы"] = "Данную информацию можно найти в /help -> 8 пункт",
        [u8"Как заработать валюту"] = "Данную информацию можно найти в /help -> 14 пункт",
		[u8"Как получать админку"] = "Ожидать набор, или же /help -> 18 пункт"
	},
	["HelpGangFamilyMafia"] = {
		[u8"Как открыть меню банды"] = "/menu (/mm) - ALT/Y -> Система банд",
		[u8"Как открыть меню семьи"] = "/fpanel ",
		[u8"Как исключить игрока"] = "/guninvite (банда) || /funinvite (семья)",
		[u8"Как пригласить игрока"] = "/ginvite (банда) || /finvite (семья)",
		[u8"Как покинуть банду/семью"] = "/gleave (банда) || /fleave (семья)",
        [u8"Как выдать ранг"] = "/grank IDPlayer Ранг",
		[u8"Как покинуть мафию"] = "/leave",
		[u8"Как выдать выговор"] = "/gvig // Должна быть лидерка",
	},
	["HelpTP"] = {
		[u8"Как тп в автосалон"] = "tp -> Разное -> Автосалоны",
		[u8"Как тп в автомастерскую"] = "/tp -> Разное -> Автосалоны -> Автомастерская",
		[u8"Как тп в банк"] = "/bank || /tp -> Разное -> Банк",
		[u8"Как ваще тп"] = "/tp (по локациям), /g (/goto) id (к игроку) с VIP (/help -> 7 пункт)",
        [u8"Как тп на работы"] = "/tp -> Работы"
	},
	["HelpSellBuy"] = {
		[u8"Как продать аксы"] = "Продать аксессуары или купить можно на /trade. Чтобы продать, нажмите F около лавки",
		[u8"Как обменять валюту"] = "Чтобы обменять валюту, введите /trade, и подойдите к NPC Арману, стоит справа",
		[u8"А как продать тачку"] = "/sellmycar IDPlayer Слот1-5 Сумма || /car -> Слот1-5 -> Продать государству",
        [u8"А как продать бизнес"] = "/biz > Продать бизнес государству",
		[u8"Как передать деньги"] = "/givemoney IDPlayer money",
		[u8"Как передать очки"] = "/givescore IDPlayer score",
		[u8"Как передать рубли"] = "/giverub IDPlayer rub | С Личного VIP (/help -> 7)",
		[u8"Как передать коины"] = "/givecoin IDPlayer coin | С Личного VIP (/help -> 7)",
        [u8"Как заработать валюту"] = "Данную информацию можно найти в /help -> 14 пункт",
	},
	["HelpBuz"] = {
		[u8"Меню казино"] = "Введите /cpanel ", 
		[u8"Продать бизнес"] = "/biz > Продать бизнес государству",
		[u8"Меню бизнесмена"] = "Введите /biz ",
		[u8"Меню клуба"] = "Введите /clubpanel ",
		[u8"Управление бизнесами"] = "Введите /help -> 9",
	},
	["HelpDefault"] = {
		[u8"IP RDS 01"] = "46.174.52.246:7777",
		[u8"IP RDS 02"] = "46.174.55.87:7777",
		[u8"IP RDS 03"] = "46.174.49.170:7777",
		[u8"IP RDS 04"] = "46.174.55.169:7777",
		[u8"IP RDS 05"] = "62.122.213.75:7777",
		[u8"Сайт с цветами HTML"] = "https://colorscheme.ru/html-colors.html",
		[u8"Сайт с цветами HTML 2"] = "https://htmlcolorcodes.com",
		[u8"Как поставить цвет"] = "Цвет в коде HTML {RRGGBB}. Зеленый - 008000. Берем {} и ставим цвет перед словом {008000}Зеленый",
		[u8"Ссылка на офф.группу"] = "https://vk.com/dmdriftgta | Группа проекта",
        [u8"Ссылка на форум"] = "https://forumrds.ru | Форум проекта",
        [u8"Как оплатить дом/бизнес"] = "Оплатить бизнес/дом можно с помощью /bank или /tp -> Разное -> Банк",
		[u8"Где взять купленную машину"] = "Используйте команду /car",
		[u8"Как ограбить банк"] = 'Встать на пикап "Ограбление банка", после около ячеек нажимать на ALT и ехать на красный маркер на карте',
		[u8"Как детальки искать"] = "Детали разбросаны по всей карте. Обмен происходится на /garage",
		[u8"Как начать капт"] = "Для того, чтобы начать капт, нужно ввести /capture",
		[u8"Как пассив вкл/выкл"] = "/passive ",
		[u8"/statpl"] = "Чтобы посмотреть детали, очки, коины, рубли, вирты - /statpl",
		[u8"Смена пароля"] = "/mm -> Действия -> Сменить пароль",
		[u8"Спавн тачки"] = "/mm -> Транспортное средство -> Тип транспорта",
        [u8"Как взять оружие"] = "/menu (/mm) - ALT/Y -> Оружие",
		[u8"Как взять предметы"] = "/menu (/mm) - ALT/Y -> Предметы",
        [u8"Как открыть меню"] = "/mm (/mn) || Alt/Y",
		[u8"Как тюнить тачку"] = "/menu (/mm) - ALT/Y -> Т/С -> Тюнинг",
		[u8"Если игрок застрял"] = "/kill | /tp | /spawn",
		[u8"Как попасть на дерби/пабг"] = "/join | Есть внутриигровые команды, следите за чатом",
		[u8"Виртуальный мир"] = "/dt 0-990 / Виртуальный мир",
        [u8"Прогресс миссий/квестов"] = "/quests | /dquest | /bquest",
		[u8"Спросите у игроков"] = "Спросите у игроков."
	},
	["HelpSkins"] = {
		[u8"Сайт со скинами"] = " https://gtaxmods.com/skins-id.html.",
		[u8"Копы"] = "65-267, 280-286, 288, 300-304, 306, 307, 309-311",
		[u8"Балласы"] = "102-104",
		[u8"Грув"] = "105-107",
		[u8"Триад"] = "117-118, 120",
		[u8"Вагосы"] = "108-110",
		[u8"Ру.Мафия"] = "111-113",
		[u8"Вариосы"] = "114-116",
		[u8"Мафия"] = "124-127"
	},
	["HelpSettings"] = {
		[u8"Входы/Выходы игроков"] = "/menu (ALT/Y) -> Настройки -> 1 пункт.",
		[u8"Разрешение вызывать на дуель"] = "/menu (ALT/Y) -> Настройки -> 2 пункт.",
		[u8"On/Off Личные сообщения"] = "/menu (ALT/Y) -> Настройки -> 3 пункт.",
		[u8"Запросы на телепорт"] = "/menu (ALT/Y) -> Настройки -> 4 пункт.",
		[u8"Разрешение показывать DM Stats"] = "/menu (ALT/Y) -> Настройки -> 5 пункт.",
		[u8"Эффект при телепортации"] = "/menu (ALT/Y) -> Настройки -> 6 пункт.",
		[u8"Показывать спидометр"] = "/menu (ALT/Y) -> Настройки -> 7 пункт.",
		[u8"Показывать Drift Lvl"] = "/menu (ALT/Y) -> Настройки -> 8 пункт.",
		[u8"Спавн в доме/доме семью"] = "/menu (ALT/Y) -> Настройки -> 9 пункт.",
		[u8"Вызов главного меню"] = "/menu (ALT/Y) -> Настройки -> 10 пункт.",
		[u8"On/Off приглашение в банду"] = "/menu (ALT/Y) -> Настройки -> 11 пункт.",
		[u8"Выбор ТС на TextDraw"] = "/menu (ALT/Y) -> Настройки -> 12 пункт.",
		[u8"On/Off кейс"] = "/menu -> Настройки (ALT/Y) -> 13 пункт.",
		[u8"On/Off FPS показатель"] = "/menu (ALT/Y) -> Настройки -> 15 пункт.",
		[u8"On/Off Уведомления"] = "/menu (ALT/Y) -> Настройки -> 16 пункт",
		[u8"On/Off Уведы.акции"] = "/menu (ALT/Y) -> Настройки -> 17 пункт",
		[u8"On/Off Авто.Автор"] = "/menu (ALT/Y) -> Настройки -> 18 пункт",
		[u8"On/Off Фон.музыка при входе"] = "/menu (ALT/Y) -> Настройки -> 19 пункт",
		[u8"Кнопка гс.чата"] = "/menu (ALT/Y) -> Настройки -> 20 пункт",
	}
}
-- ## Блок с ответами ## --
function main()
    while not isSampAvailable() do wait(0) end
    
    if toast_ok then 
        toast.Show(u8"AT Reports инициализирован.", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'AdminTool Reports успешно инициализирован. Активация: /tool', -1)
        sampAddChatMessage(tag .. "Отказ в подгрузке уведомлений", -1)
    end

    while true do
        wait(0)
        
    end
end

function ToClipboard(v) 
    if imgui.IsItemClicked() then  
        setClipboardText(v)
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 2349 then  
        if text:match("Игрок: {......}(%S+)") and text:match("Жалоба:\n{......}(.*)\n\n{......}") then
            nick_rep = text:match("Игрок: {......}(%S+)")
            text_rep = text:match("Жалоба:\n{......}(.*)\n\n{......}")	
			pid_rep = atlibs.playernickname(nick_rep)
			if pid_rep == nil then  
				pid_rep = "None"
			end
            rep_text = u8:encode(text_rep)
            id_punish = rep_text:match("(%d+)")
        end
        if not elements.repwindow[0] then  
            elements.repwindow[0] = true  
        end  
        return false
    else 
        elements.repwindow[0] = false
    end
end

local ReportsAT = imgui.OnFrame( 
    function() return elements.repwindow[0] end, 
    function(player) 

        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(750, 420), imgui.Cond.FirstUseEver)

        imgui.Begin("##Reports Window", elements.repwindow, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.MenuBar)
            imgui.BeginMenuBar()
                imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5,0.5))
                imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 10)
                if imgui.Button(fa.BELL .. '##BackWind', imgui.ImVec2(50, 0)) then     
                    elements.select_menu = 0
                end 
                imgui.Spacing()
                imgui.Text(u8('     Текст репорта: ' .. u8:decode(rep_text)))
                imgui.PopStyleVar(1)
                imgui.PopStyleVar(1)
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 100))
                if elements.select_menu == 1 or elements.select_menu == 2 then  
                    if imgui.Button(fa.ARROW_LEFT .. '##BackButton', imgui.ImVec2(50,0)) then  
                        elements.select_menu = 0
                    end
                end
            imgui.EndMenuBar()
            if elements.select_menu == 0 then
                imgui.StrCopy(elements.prefix_for_answer, config.main.prefix_for_answer)
                if (nick_rep and pid_rep and rep_text) then  
                    imgui.Text(u8"Жалоба от: "); imgui.SameLine()
                    imgui.Text(nick_rep); ToClipboard(nick_rep); imgui.SameLine();
                    imgui.Text("[" .. pid_rep .. "]"); ToClipboard(pid_rep)
                    imgui.Separator()
                    imgui.Text(u8(u8:decode(rep_text)))
                    imgui.Separator()
                elseif (nick_rep == nil or pid_rep == nil or rep_text == nil or text_rep == nil) then
                    imgui.Text(u8"Жалоба не существует.")
                end	
                imgui.InputText('##Answer', elements.answer, ffi.sizeof(elements.answer))
                imgui.SameLine()
                if imgui.Button(fa.ROTATE .. ("##RefreshText//RemoveText")) then  
                    imgui.StrCopy(elements.answer, '')
                end; Tooltip("Обновляет/Удаляет содержимое текстового поля сразу.")
                imgui.SameLine()
                if imgui.Button(fa.TEXT_HEIGHT .. ("##SendColor")) then  
                    imgui.StrCopy(elements.answer, color())
                end; Tooltip("Ставит рандомный цвет перед ответом.")
                if #ffi.string(elements.answer) > 0 then  
                    imgui.SameLine()
                    if imgui.Button(fa.DOWNLOAD .. ('##SaveReport')) then  
                        imgui.StrCopy(elements.binder_text, ffi.string(elements.answer))
                        imgui.OpenPopup('BinderReport')
                    end 
                end
                if imgui.BeginPopupModal('BinderReport', false, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.BeginChild("##EditBinder", imgui.ImVec2(600, 225), true)
                    imgui.Text(u8'Название бинда:'); imgui.SameLine()
                    imgui.PushItemWidth(130)
                    imgui.InputText("##elements.binder_name", elements.binder_name, ffi.sizeof(elements.binder_name))
                    imgui.PopItemWidth()
                    imgui.PushItemWidth(100)
                    imgui.Separator()
                    imgui.Text(u8'Текст бинда:')
                    imgui.PushItemWidth(300)
                    imgui.InputTextMultiline("##elements.binder_text", elements.binder_text, ffi.sizeof(elements.binder_text), imgui.ImVec2(-1, 110))
                    imgui.PopItemWidth()
        
                    imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 100)
                    if imgui.Button(u8'Закрыть##bind1', imgui.ImVec2(100,30)) then
                        imgui.StrCopy(elements.binder_name, '')
                        imgui.StrCopy(elements.binder_text, '')
                        imgui.CloseCurrentPopup()
                    end
                    imgui.SameLine()
                    if #ffi.string(elements.binder_name) > 0 and #ffi.string(elements.binder_text) > 0 then
                        imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 1.01)
                        if imgui.Button(u8'Сохранить##bind1', imgui.ImVec2(100,30)) then
                            if not EditOldBind then
                                local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                                table.insert(config.bind_name, ffi.string(elements.binder_name))
                                table.insert(config.bind_text, refresh_text)
                                if save() then
                                    sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно создан!', -1)
                                    imgui.StrCopy(elements.binder_name, '')
                                    imgui.StrCopy(elements.binder_text, '')
                                    imgui.CloseCurrentPopup()
                                end
                            else
                                local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                                table.insert(config.bind_name, getpos, ffi.string(elements.binder_name))
                                table.insert(config.bind_text, getpos, refresh_text)
                                table.remove(config.bind_name, getpos + 1)
                                table.remove(config.bind_text, getpos + 1)
                                if save() then
                                    sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно отредактирован!', -1)
                                    imgui.StrCopy(elements.binder_name, '')
                                    imgui.StrCopy(elements.binder_text, '')
                                end
                                EditOldBind = false
                                imgui.CloseCurrentPopup()
                            end
                        end
        
                    end
                    imgui.EndChild()
                    imgui.EndPopup()
                end
                imgui.Separator()
                imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign , imgui.ImVec2(0.5, 0.5))
                if imgui.Button(fa.EYE .. u8" Работа по жб", imgui.ImVec2(250,30)) then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Начал(а) работу по вашей жалобе! ' .. u8:decode(config.main.prefix_for_answer))
                        else 
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Начал(а) работу по вашей жалобе! ')	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0, nil)
                        wait(500)
                        if tonumber(id_punish) ~= nil and id_punish ~= nil then 
                            sampSendChat("/re " .. id_punish)
                        end	
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.BAN .. u8" Наказан", imgui.ImVec2(250,30)) then  
                    lua_thread.create(function() 
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Данный игрок наказан! ' .. u8:decode(config.main.prefix_for_answer))
                        else 
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Данный игрок наказан! ')	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.COMMENT .. u8" Уточните ID", imgui.ImVec2(250,30)) then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Уточните ID нарушителя/читера в /report ' .. u8:decode(config.main.prefix_for_answer))
                        else 
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Уточните ID нарушителя/читера в /report ')	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end	
                if imgui.Button(fa.CIRCLE_INFO .. u8" Уточните жб", imgui.ImVec2(250,30)) then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Уточните вашу жалобу/вопрос ' .. u8:decode(config.main.prefix_for_answer))
                        else 
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Уточните вашу жалобу/вопрос ')	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end	
                imgui.SameLine()
                if imgui.Button(fa.SHARE .. u8' Жб на админа', imgui.ImVec2(250,30)) then
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Пишите жалобу на администратора на форум https://forumrds.ru '.. u8:decode(u8(config.main.prefix_for_answer)))
                        else
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Пишите жалобу на администратора на форум https://forumrds.ru ')
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.SHARE .. u8" Жб на игрока", imgui.ImVec2(250,30)) then
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(500)
                        if elements.prefix_answer.v then
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Пишите жалобу на игрока на форум https://forumrds.ru '.. u8:decode(u8(config.main.prefix_for_answer)))
                        else
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Пишите жалобу на игрока на форум https://forumrds.ru ')
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end) 
                end
                if imgui.Button(fa.CIRCLE_INFO .. u8' Баг на сервере', imgui.ImVec2(250,30)) then
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Напишите в тех.раздел на форуме https://forumrds.ru '.. u8:decode(u8(config.main.prefix_for_answer)))
                        else
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Напишите в тех.раздел на форуме https://forumrds.ru')
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.TOGGLE_OFF .. u8' Не в сети', imgui.ImVec2(250,30)) then
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(500)
                        if elements.prefix_answer[0] then
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Игрок не в сети. '.. u8:decode(u8(config.main.prefix_for_answer)))
                        else
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Игрок не в сети. ')
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.CLOCK .. u8' Чист/нет наруш.', imgui.ImVec2(250,30)) then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(500)
                        if elements.prefix_answer[0] then
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Не вижу нарушений со стороны игрока. '.. u8:decode(u8(config.main.prefix_for_answer)))
                        else
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Не вижу нарушений со стороны игрока. ')
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.Separator()
                imgui.SetCursorPosX(imgui.GetWindowWidth() - 600)
                if imgui.Button(fa.CIRCLE_CHECK .. u8" Передать жалобу ##SEND", imgui.ImVec2(400,30)) then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Передам ваш репорт! '.. u8:decode(config.main.prefix_for_answer))
                        else 
                            sampSendDialogResponse(2351, 1, 0, '{FFFFFF} Передам ваш репорт! ')	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        sampSendChat("/a " .. nick_rep .. "[" .. pid_rep .. "] | " .. text_rep)
                        elements.repwindow[0] = false
                    end)	
                end
                imgui.Separator()
                imgui.SetCursorPosX(imgui.GetWindowWidth() - 675)
                if imgui.Button(fa.CIRCLE_QUESTION .. u8" Ответы от AT", imgui.ImVec2(300,30)) then  
                    elements.select_menu = 1
                end
                imgui.SameLine()
                if imgui.Button(fa.CODE .. u8" Сохраненные ответы", imgui.ImVec2(300,30)) then  
                    elements.select_menu = 2
                end
                imgui.Separator()
                if imgui.Checkbox(u8"Пожелание в ответ", elements.prefix_answer) then 
                    config.main.prefix_answer = elements.prefix_answer[0]
                    save()
                end; Tooltip("Автоматически при ответе через кнопочки будет желать то, что вы зарегистрируете")
                imgui.StrCopy(elements.prefix_for_answer, config.main.prefix_for_answer)
                if imgui.InputText(u8'Ввод текста', elements.prefix_for_answer, ffi.sizeof(elements.prefix_for_answer)) then  
                    config.main.prefix_for_answer = ffi.string(elements.prefix_for_answer)
                    save()
                end
                imgui.Separator()
                if imgui.Button(u8'Ответить') then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 0)
                        wait(200)
                        if elements.prefix_answer[0] then  
                            local settext = '{FFFFFF}' .. ffi.string(elements.answer) .. ' ' .. color() .. config.main.prefix_for_answer
                            sampSendDialogResponse(2351, 1, 0, u8:decode(settext))	
                        else
                            local settext = '{FFFFFF}' .. ffi.string(elements.answer)
                            sampSendDialogResponse(2351, 1, 0, u8:decode(settext))	
                        end
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                if imgui.Button(fa.BAN .. u8" Отклонить") then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 1, 0)
                        wait(500)
                        sampSendDialogResponse(2350, 1, 1)
                        wait(500)
                        sampSendDialogResponse(2351, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.SameLine()
                imgui.SetCursorPosX(imgui.GetWindowWidth() - 130)
                if imgui.Button(fa.CLOSED_CAPTIONING .. u8" Закрыть") then  
                    lua_thread.create(function()
                        sampSendDialogResponse(2349, 0, 0)
                        wait(500)
                        sampSendDialogResponse(2348, 0, 0)
                        elements.repwindow[0] = false
                    end)
                end
                imgui.PopStyleVar(1)
            end  
            if elements.select_menu == 1 then  
                imgui.BeginChild("##menuSecond", imgui.ImVec2(250, 380), true)
                if imgui.Button(fa.OBJECT_GROUP .. u8" На кого-то/что-то") then  -- reporton key
                    elements.select_category = 1  
                end	
                if imgui.Button(fa.LIST .. u8" Команды (/help)") then  -- HelpCMD key
                    elements.select_category = 2 
                end 	
                if imgui.Button(fa.USERS .. u8" Банде/семья") then  -- HelpGangFamilyMafia key
                    elements.select_category = 3
                end	
                if imgui.Button(fa.MAP_LOCATION .. u8" Телепорты") then  -- HelpTP key
                    elements.select_category = 4
                end	
                if imgui.Button(fa.BAG_SHOPPING .. u8" Бизнесы") then  -- HelpBuz key
                    elements.select_category = 5 
                end	
                if imgui.Button(fa.MONEY_BILL .. u8" Продажа/Покупка") then  -- HelpSellBuy key
                    elements.select_category = 6 
                end	
                if imgui.Button(fa.BOLT .. u8" Настройки") then  -- HelpSettings key
                    elements.select_category = 7
                end	
                if imgui.Button(fa.HOUSE .. u8" Дома") then  -- HelpHouses key
                    elements.select_category = 8 
                end	
                if imgui.Button(fa.PERSON .. u8" Скины") then  -- HelpSkins key
                    elements.select_category = 9 
                end	
                if imgui.Button(fa.BARCODE .. u8" Остальные ответы") then  -- HelpDefault key
                    elements.select_category = 10
                end	
                imgui.Separator()
                if imgui.Button(fa.BACKWARD .. u8" Назад") then  
                    elements.select_menu = 0 
                end	
                imgui.EndChild()
                imgui.SameLine()
                imgui.BeginChild("##menuSelectable", imgui.ImVec2(460, 380), true)
                if elements.select_category == 0 then  
                    imgui.Text(u8"Заготовленные/сохраненные ответы \nтакого типа меняются \nтолько разработчиками")
                end	
                if elements.select_category == 1 then  
                    for key, v in pairs(questions) do
                        if key == "reporton" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    elements.select_category = 0
                                    elements.select_menu = 0 
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 2 then 
                    for key, v in pairs(questions) do
                        if key == "HelpCmd" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 3 then  
                    for key, v in pairs(questions) do
                        if key == "HelpGangFamilyMafia" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 4 then  
                    for key, v in pairs(questions) do
                        if key == "HelpTP" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 6 then  
                    for key, v in pairs(questions) do
                        if key == "HelpSellBuy" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 10 then  
                    for key, v in pairs(questions) do
                        if key == "HelpDefault" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 9 then  
                    for key, v in pairs(questions) do
                        if key == "HelpSkins" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                 end
                             end
                        end
                    end
                end	
                if elements.select_category == 7 then  
                    for key, v in pairs(questions) do
                        if key == "HelpSettings" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 8 then  
                    for key, v in pairs(questions) do
                        if key == "HelpHouses" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                if elements.select_category == 5 then  
                    for key, v in pairs(questions) do
                        if key == "HelpBuz" then
                            for key_2, v_2 in pairs(questions[key]) do
                                if imgui.Button(key_2) then
                                    if not elements.prefix_answer[0] then
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    else
                                        lua_thread.create(function()
                                        local settext = '{FFFFFF}' .. v_2 .. ' ' .. color() .. u8:decode(config.main.prefix_for_answer)
                                        sampSendDialogResponse(2349, 1, 0)
                                        sampSendDialogResponse(2350, 1, 0)
                                        wait(200)
                                        sampSendDialogResponse(2351, 1, 0, settext)
                                        wait(200)
                                        sampSendDialogResponse(2351, 0, 0)
                                        end)
                                    end
                                    report_ans = 0
                                end
                            end
                        end
                    end
                end	
                imgui.EndChild()
            end
            if elements.select_menu == 2 then  
                if #config.bind_name > 0 then  
                    for key, name in pairs(config.bind_name) do  
                        if imgui.Button(name .. '##' .. key) then  
                            elements.select_menu = 0 
                            SendBindReport(key)
                        end  
                    end 
                else 
                    imgui.Text(u8"Здесь пусто! :(")
                    if imgui.Button(u8"Создать бинд") then  
                        imgui.OpenPopup('BinderReport')
                    end  
                end 
                if imgui.BeginPopupModal('BinderReport', false, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then
                    imgui.BeginChild("##EditBinder", imgui.ImVec2(600, 225), true)
                    imgui.Text(u8'Название бинда:'); imgui.SameLine()
                    imgui.PushItemWidth(130)
                    imgui.InputText("##elements.binder_name", elements.binder_name, ffi.sizeof(elements.binder_name))
                    imgui.PopItemWidth()
                    imgui.PushItemWidth(100)
                    imgui.Separator()
                    imgui.Text(u8'Текст бинда:')
                    imgui.PushItemWidth(300)
                    imgui.InputTextMultiline("##elements.binder_text", elements.binder_text, ffi.sizeof(elements.binder_text), imgui.ImVec2(-1, 110))
                    imgui.PopItemWidth()
        
                    imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 100)
                    if imgui.Button(u8'Закрыть##bind1', imgui.ImVec2(100,30)) then
                        imgui.StrCopy(elements.binder_name, '')
                        imgui.StrCopy(elements.binder_text, '')
                        imgui.CloseCurrentPopup()
                    end
                    imgui.SameLine()
                    if #ffi.string(elements.binder_name) > 0 and #ffi.string(elements.binder_text) > 0 then
                        imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 1.01)
                        if imgui.Button(u8'Сохранить##bind1', imgui.ImVec2(100,30)) then
                            if not EditOldBind then
                                local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                                table.insert(config.bind_name, ffi.string(elements.binder_name))
                                table.insert(config.bind_text, refresh_text)
                                if save() then
                                    sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно создан!', -1)
                                    imgui.StrCopy(elements.binder_name, '')
                                    imgui.StrCopy(elements.binder_text, '')
                                    imgui.CloseCurrentPopup()
                                end
                            else
                                local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                                table.insert(config.bind_name, getpos, ffi.string(elements.binder_name))
                                table.insert(config.bind_text, getpos, refresh_text)
                                table.remove(config.bind_name, getpos + 1)
                                table.remove(config.bind_text, getpos + 1)
                                if save() then
                                    sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно отредактирован!', -1)
                                    imgui.StrCopy(elements.binder_name, '')
                                    imgui.StrCopy(elements.binder_text, '')
                                end
                                EditOldBind = false
                                imgui.CloseCurrentPopup()
                            end
                        end
        
                    end
                    imgui.EndChild()
                    imgui.EndPopup()
                end
                imgui.Separator()
                if imgui.Button(fa.BACKWARD .. u8" Назад") then  
                    elements.select_menu = 0 
                end
            end
        imgui.End()
    end
)

function color() -- функция, выполняющая рандомнизацию и вывод рандомного цвета с помощью специального os.time()
	mcolor = "{"
	math.randomseed( os.time() )
	for i = 1, 6 do
		local b = math.random(1, 16)
		if b == 1 then
			mcolor = mcolor .. "A"
		end
		if b == 2 then
			mcolor = mcolor .. "B"
		end
		if b == 3 then
			mcolor = mcolor .. "C"
		end
		if b == 4 then
			mcolor = mcolor .. "D"
		end
		if b == 5 then
			mcolor = mcolor .. "E"
		end
		if b == 6 then
			mcolor = mcolor .. "F"
		end
		if b == 7 then
			mcolor = mcolor .. "0"
		end
		if b == 8 then
			mcolor = mcolor .. "1"
		end
		if b == 9 then
			mcolor = mcolor .. "2"
		end
		if b == 10 then
			mcolor = mcolor .. "3"
		end
		if b == 11 then
			mcolor = mcolor .. "4"
		end
		if b == 12 then
			mcolor = mcolor .. "5"
		end
		if b == 13 then
			mcolor = mcolor .. "6"
		end
		if b == 14 then
			mcolor = mcolor .. "7"
		end
		if b == 15 then
			mcolor = mcolor .. "8"
		end
		if b == 16 then
			mcolor = mcolor .. "9"
		end
	end
	--print(mcolor)
	mcolor = mcolor .. '}'
	return mcolor
end 

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

function SendBindReport(value)
    lua_thread.create(function()
        if value ~= 1 then  
            for text_report in config.bind_text[value]:gmatch('[^~]+') do  
                sampSendDialogResponse(2349, 1, 0)
                sampSendDialogResponse(2350, 1, 0)
                wait(200)
                sampSendDialogResponse(2351, 1, 0, u8:decode(tostring(text_report))) -- обезопасим себя, предварительно перепреобразовав независимую строку в зависимую к тексту!
                wait(200)
                sampCloseCurrentDialogWithButton(1)
            end  
            value = -1
        end
    end)
end

function EXPORTS.BinderEdit()
    if imgui.Button(u8'Открыть окно взаимодействия с биндером.') then  
        imgui.OpenPopup('BinderEditEx')
    end
    if imgui.BeginPopupModal('BinderEditEx', _, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize) then
        imgui.BeginChild('##ListBinders', imgui.ImVec2(200, 480), true)
            if #config.bind_name > 0 then  
                for key, name in pairs(config.bind_name) do 
                    if imgui.Button(name.. '##' ..key) then  
                        EditOldBind = true  
                        getpos = key  
                        local returnwrapped = tostring(config.bind_text[key]):gsub('~', '\n')
                        imgui.StrCopy(elements.binder_text, returnwrapped)
                        imgui.StrCopy(elements.binder_name, tostring(config.bind_name[key]))
                    end
                    imgui.SameLine()
                    if imgui.Button(fa.TRASH.. "##"..key) then  
                        sampAddChatMessage(tag .. 'Бинд "' ..u8:decode(config.bind_name[key]) .. '" удален!', -1)
                        table.remove(config.bind_name, key)
                        table.remove(config.bind_text, key) 
                        inicfg.save(config, directIni)
                    end  
                end 
            end 
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("##EditBinder", imgui.ImVec2(500, 480), true)
            imgui.Text(u8'Название бинда:'); imgui.SameLine()
            imgui.PushItemWidth(130)
            imgui.InputText("##elements.binder_name", elements.binder_name, ffi.sizeof(elements.binder_name))
            imgui.PopItemWidth()
            imgui.PushItemWidth(100)
            imgui.Separator()
            imgui.Text(u8'Текст бинда:')
            imgui.PushItemWidth(300)
            imgui.InputTextMultiline("##elements.binder_text", elements.binder_text, ffi.sizeof(elements.binder_text), imgui.ImVec2(-1, 110))
            imgui.PopItemWidth()

            imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 100)
            if imgui.Button(u8'Закрыть##bind1', imgui.ImVec2(100,30)) then
                imgui.StrCopy(elements.binder_name, '')
                imgui.StrCopy(elements.binder_text, '')
            end
            imgui.SameLine()
            if #ffi.string(elements.binder_name) > 0 and #ffi.string(elements.binder_text) > 0 then
                imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 1.01)
                if imgui.Button(u8'Сохранить##bind1', imgui.ImVec2(100,30)) then
                    if not EditOldBind then
                        local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                        table.insert(config.bind_name, ffi.string(elements.binder_name))
                        table.insert(config.bind_text, refresh_text)
                        if save() then
                            sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно создан!', -1)
                            imgui.StrCopy(elements.binder_name, '')
                            imgui.StrCopy(elements.binder_text, '')
                        end
                    else
                        local refresh_text = ffi.string(elements.binder_text):gsub("\n", "~")
                        table.insert(config.bind_name, getpos, ffi.string(elements.binder_name))
                        table.insert(config.bind_text, getpos, refresh_text)
                        table.remove(config.bind_name, getpos + 1)
                        table.remove(config.bind_text, getpos + 1)
                        if save() then
                            sampAddChatMessage(tag .. 'Бинд"' ..u8:decode(ffi.string(elements.binder_name)).. '" успешно отредактирован!', -1)
                            imgui.StrCopy(elements.binder_name, '')
                            imgui.StrCopy(elements.binder_text, '')
                        end
                        EditOldBind = false
                    end
                end
            end
        imgui.EndChild()
        if imgui.Button(u8'Закрыть окно', imgui.ImVec2(750, 30)) then  
            imgui.CloseCurrentPopup()
        end
        imgui.End()
    end
end
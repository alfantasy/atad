require 'lib.moonloader'

local dlstatus = require('moonloader').download_status
local fflags = require('moonloader').font_flag
local imgui = require 'mimgui' -- ������������� ���������� Moon ImGUI
local encoding = require 'encoding' -- ������ � �����������
local sampev = require 'lib.samp.events' -- ���������� ������� SA:MP � ������������/���������/�������� �.�. �������
local mim_addons = require 'mimgui_addons' -- ���������� ������� ��� ���������� mimgui
local fa = require 'fAwesome6_solid' -- ������ � ������� �� ������ FontAwesome 6
local inicfg = require 'inicfg' -- ������ � ��������
local memory = require 'memory' -- ������ � ������� ��������
local ffi = require 'ffi' -- ���������� ������ � ����������� ����
local http = require('socket.http') -- ������ � ��������� HTTP
local ltn12 = require('ltn12') -- ������ � �������� ��������
local atlibs = require 'libsfor' -- ������������� ���������� InfoSecurity ��� AT (libsfor)
local toast_ok, toast = pcall(import, 'lib/mimtoasts.lua') -- ���������� �����������.
local question_ok, QuestionAnswer = pcall(import, 'QuestionAnswer.lua') -- ������������� ���������� �������� ������
encoding.default = 'CP1251' -- ����� ��������� �� CP1251
u8 = encoding.UTF8 -- ���������� ��������� U8 ��� �������, �� � ����� ���������� (��� ����������)

-- ## ���� ��������� ���������� ## --
local tag = "{00BFFF} [AT] {FFFFFF}" -- ��������� ����������, ������� ������������ ��� AT
-- ## ���� ��������� ���������� ## --

-- ## ��������������� ������ AT. ����������, ������ � ����������. ## --
local urls = {
	['main'] = "https://raw.githubusercontent.com/alfantasy/atad/main/AdminTool.lua",
	['libsfor'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/libsfor.lua',
	['report'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/QuestionAnswer.lua',
	['upat'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/upat.ini',
	['clogger'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/clogger.lua',
	['rdsmenu'] = 'https://raw.githubusercontent.com/alfantasy/atad/main/RDSMenu.lua'
}

local paths = {
	['main'] = getWorkingDirectory() .. '/AdminTool.lua',
	['libsfor'] = getWorkingDirectory() .. '/lib/libsfor.lua',
	['report'] = getWorkingDirectory() .. '/QuestionAnswer.lua',
	['upat'] = getWorkingDirectory() .. '/upat.ini',
	['clogger'] = getWorkingDirectory() .. '/clogger.lua',
	['rdsmenu'] = getWorkingDirectory() .. '/RDSMenu.lua'
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

local version_control = 5
local version_text = '1.2'
-- ## ��������������� ������ AT. ����������, ������ � ����������. ## --

-- ## ������� ������� � ���������� VARIABLE ## --
local new = imgui.new

local directoryAutoMute = getWorkingDirectory() .. '/config/AdminTool/AutoMute'
local directIni = 'AdminTool/settings.ini'
local eventsIni = 'AdminTool/events.ini'

local config = inicfg.load({
    settings = {
        custom_recon = false,
		autologin = false,
		password_to_login = '',
		automute_mat = false,
        automute_osk = false,
        automute_rod = false, 
        automute_upom = false, 
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
	toast.Show(u8'���������� ����� INI �� ATEvents ������ �������.', toast.TYPE.OK, 5)
	return true
end

function save()
    inicfg.save(config, directIni)
    toast.Show(u8"���������� �������� ������ �������.", toast.TYPE.OK, 5)
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

local show_password = false -- ��������/������ ������ � ����������
local control_spawn = false -- �������� ������. ������������ ��� ������� �������

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
-- ## ������� ������� � ���������� VARIABLE ## --

-- ## mimgui ## --
function Tooltip(text)
    if imgui.IsItemHovered() then
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
end)

local sw, sh = getScreenResolution()
-- ## mimgui ## --

-- ## ���� ���������� ��������� � CustomReconMenu ## --
local ids_recon = {479, 2056, 2052, 144, 146, 141, 2050, 155, 153, 152, 156, 154, 160, 157, 179, 165, 159, 164, 162, 161, 180, 178, 163, 169, 181, 161, 166, 170, 168, 174, 182, 172, 171, 175, 173, 150, 184, 147, 148, 151, 149, 142, 143, 184, 177, 145, 158, 167, 183, 176}
local info_to_player = {}
local recon_info = { "��������: ", "�����: ", "�� ������: ", "��������: ", "����: ", "�������: ", "�������: ", "������� ��������: ", "����� � ���: ", "P.Loss: ", "������� VIP: ", "��������� �����: ", "�����-�����: ", "��������: "}
local right_recon = new.bool(true)
local accept_load_recon = false 
local recon_id = -1
local control_to_player = false
-- ## ���� ���������� ��������� � CustomReconMenu ## --

-- ## ���������� ���������� �� ������ �������� ## --
local onscene_mat = { 
    "�����", "����", "���", "�����" 
} 
local onscene_osk = { 
    "����", "���", "������", "�����" 
}
local onscene_upom = {
    "�������", "russian roleplay", "evolve", "������"
}
local onscene_rod = { 
    "���� ����", "mq", "���� � ������", "���� ���� �����", "���� ��� �����", "mqq", "mmq", 'mmqq', "matb v kanave",
}
local control_onscene_mat = false -- ��������������� ����� �������� "����������� �������"
local control_onscene_osk = false -- ��������������� ����� �������� "�����������/��������"
local control_onscene_upom = false -- ��������������� ����� �������� "���������� ����.��������"
local control_onscene_rod = false -- ��������������� ����� �������� "����������� ������"
-- ## ���������� ���������� �� ������ �������� ## --

local reasons = { 
	"/mute","/jail","/iban","/ban","/kick","/skick","/sban", "/muteakk", "/offban", "/banakk"
}

function getMyNick()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        local nick = sampGetPlayerNickname(id)
        return nick
    end
end

-- ## �������, ����������� ��������� ������������ ����� � ������ ����������� ���������� ## -- 
function checkMessage(msg, arg) -- ��� ���������� �������������� ����� ������� mainstream (�� 1 �� 4); ��� 1 - ���, 2 - ���, 3 - ����.����.��������, 4 - ��� ���
    if msg ~= nil then -- ��������, ���������� �� ��������� � ������� ��� ������������ ������
        if arg == 1 then -- MainStream Automute-Report For "����������� �������"  
            for i, ph in ipairs(onscene_mat) do -- ������� ������� ������ � ������������ �������� �������, ���������� � ����
                nmsg = atlibs.string_split(msg, " ") -- �������� ��������� �� ������ �� ������
                for j, word in ipairs(nmsg) do -- ���� �������� �� ������ ������ �������
                    if ph == atlibs.string_rlower(word) then  -- ���� ����������� ����� ���� ������ �������, ��
                        return true, ph -- ������� True � ����������� �����
                    end  
                end  
            end  
        elseif arg == 2 then -- MainStream Automute-Report For "�����������/��������" 
            for i, ph in ipairs(onscene_osk) do -- ������� ������� ������ � ������������ �������� �������, ���������� � ����
                nmsg = atlibs.string_split(msg, " ") -- �������� ��������� �� ������ �� ������
                for j, word in ipairs(nmsg) do -- ���� �������� �� ������ ������ �������
                    if ph == atlibs.string_rlower(word) then  -- ���� ����������� ����� ���� ������ �������, ��
                        return true, ph -- ������� True � ����������� �����
                    end  
                end  
            end
        elseif arg == 3 then -- MainStream Automute-Report For "���������� ��������� ��������"  
            for i, ph in ipairs(onscene_upom) do -- ������ � ������������ �������� ������� �� �����
                if string.find(msg, ph, 1, true) then -- ����� ������� �� ������. ������ ����������� ������ �����? ������ ������ �� �����������, ������ ��� � ������ ���� 
                    return true, ph -- ���������� True � ����������� �����
                end 
            end
        elseif arg == 4 then -- MainStream Automute-Report For "����������� ������" 
            for i, ph in ipairs(onscene_rod) do -- ������ � ������������ �������� ������� �� �����
                if string.find(msg, ph, 1, true) then -- ����� ������� �� ������. ������ ����������� ������ �����? ������ ������ �� �����������, ������ ��� � ������ ���� 
                    return true, ph -- ���������� True � ����������� �����
                end 
            end 
        end  
    end
end 

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowWidth()/2-imgui.CalcTextSize(u8(text)).x/2)
    imgui.Text(u8(text))
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4
    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end
    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImVec4(r/255, g/255, b/255, a/255)
    end
    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end


-- function imgui.TextColoredRGB(text)
--     local style = imgui.GetStyle()
--     local colors = style.Colors
--     local col = imgui.Col
    
--     local designText = function(text__)
--         local pos = imgui.GetCursorPos()
--         if sampGetChatDisplayMode() == 2 then
--             for i = 1, 1 --[[������� ����]] do
--                 imgui.SetCursorPos(imgui.ImVec2(pos.x + i, pos.y))
--                 imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
--                 imgui.SetCursorPos(imgui.ImVec2(pos.x - i, pos.y))
--                 imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
--                 imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y + i))
--                 imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
--                 imgui.SetCursorPos(imgui.ImVec2(pos.x, pos.y - i))
--                 imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), text__) -- shadow
--             end
--         end
--         imgui.SetCursorPos(pos)
--     end
    
    
    
--     local text = text:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')

--     local color = colors[col.Text]
--     local start = 1
--     local a, b = text:find('{........}', start)   
    
--     while a do
--         local t = text:sub(start, a - 1)
--         if #t > 0 then
--             designText(t)
--             imgui.TextColored(color, t)
--             imgui.SameLine(nil, 0)
--         end

--         local clr = text:sub(a + 1, b - 1)
--         if clr:upper() == 'STANDART' then color = colors[col.Text]
--         else
--             clr = tonumber(clr, 16)
--             if clr then
--                 local r = bit.band(bit.rshift(clr, 24), 0xFF)
--                 local g = bit.band(bit.rshift(clr, 16), 0xFF)
--                 local b = bit.band(bit.rshift(clr, 8), 0xFF)
--                 local a = bit.band(clr, 0xFF)
--                 color = imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
--             end
--         end

--         start = b + 1
--         a, b = text:find('{........}', start)
--     end
--     imgui.NewLine()
--     if #text >= start then
--         imgui.SameLine(nil, 0)
--         designText(text:sub(start))
--         imgui.TextColored(color, text:sub(start))
--     end
-- end

local lc_lvl, lc_adm, lc_color, lc_nick, lc_id, lc_text

function main()

    if toast_ok then 
        toast.Show(u8"AdminTool ���������������.\n��� ������ � �����������, �������: /tool", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'AdminTool ������� ���������������. ���������: /tool', -1)
        print(tag .. "����� � ��������� �����������")
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
				toast.Show(u8'�������� ����������.\nAT �������� ���������� �������������.', toast.TYPE.INFO, 5)
			else 
				print(tag .. '����� � ��������� �����������.')
				sampAddChatMessage(tag .. '�������� ����������. AT �������� ��������������!', -1)
			end 
			
			local response_main = downloadFile(urls['main'], paths['main'])
			if response_main then  
				sampAddChatMessage(tag .. '�������� ������ �� ������.', -1)
			end  
			local response_lib = downloadFile(urls['libsfor'], paths['libsfor'])
			if response_lib then  
				sampAddChatMessage(tag .. '���������� � �� ������� �������.', -1)
			end  
			local response_questans = downloadFile(urls['report'], paths['report'])
			if response_questans then  
				sampAddChatMessage(tag .. '������ ��� �������� ������.', -1)
			end  
			local response_clogger = downloadFile(urls['clogger'], paths['clogger'])
			if response_clogger then  
				sampAddChatMessage(tag .. '���-������ ������', -1)
			end
			sampAddChatMessage(tag .. '������� ������������ ��������!', -1)
			reloadScripts()
		else 
			if toast_ok then  
				toast.Show(u8'� ��� ����������� ���������� ������ ��.\n������ AT: ' .. version_text, toast.TYPE.INFO, 5)
			else 
				print(tag .. '����� � ��������� �����������.')
				sampAddChatMessage(tag .. '� ��� ����������� ���������� ������ ��. ������ ��: ' .. version_text, -1)
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
		sampAddChatMessage(tag .. '������������ ��������. ���� � ������, ���� ��� AutoLogin', -1)
		sampSendChat('/access')
	end)

    -- ## ����������� ������ ��������� � ������� ���� � ������� ## --
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
    -- ## ����������� ������ ��������� � ������� ���� � ������� ## --

    -- ## ����������� ������ ��������� � ������� ������-��������� ���� ## --
    sampRegisterChatCommand("cp", cmd_cpfd)
    sampRegisterChatCommand("rpo", cmd_report_popr)
    sampRegisterChatCommand("rrz", cmd_rrz)
    sampRegisterChatCommand("roa", cmd_roa)
    sampRegisterChatCommand("ror", cmd_ror)
    sampRegisterChatCommand("rup", cmd_rup)
    sampRegisterChatCommand("rok", cmd_rok)
    sampRegisterChatCommand("rm", cmd_rm)
    sampRegisterChatCommand("rnm", cmd_report_neadekvat)
    -- ## ����������� ������ ��������� � ������� ������-��������� ���� ## --

    -- ## ����������� ������ ��������� � ������� offline-��������� ���� ## --
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
    -- ## ����������� ������ ��������� � ������� offline-��������� ���� ## --

    -- ## ����������� ������ ��������� � ������� offline-��������� ������ ## --
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
    -- ## ����������� ������ ��������� � ������� offline-��������� ������ ## --

    -- ## ����������� ������ ��������� � ������� ��������� ������ ## --
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
    -- ## ����������� ������ ��������� � ������� ��������� ������ ## --

    -- ## ����������� ������ ��������� � ������� ��������� ���� ## --
    sampRegisterChatCommand("pl", cmd_pl)
    sampRegisterChatCommand("ob", cmd_ob)
    sampRegisterChatCommand("hl", cmd_hl)
    sampRegisterChatCommand("nk", cmd_nk)
    sampRegisterChatCommand('ch', cmd_ch)
    sampRegisterChatCommand("menk", cmd_menk)
    sampRegisterChatCommand("gcnk", cmd_gcnk)
    sampRegisterChatCommand("bnm", cmd_bnm)
    -- ## ����������� ������ ��������� � ������� ��������� ���� ## --

    -- ## ����������� ������ ��������� � ������� offline-��������� ���� ## --
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
    -- ## ����������� ������ ��������� � ������� offline-��������� ���� ## --

    -- ## ����������� ������ ��������� � ������� ��������� ���� ## --
    sampRegisterChatCommand("dj", cmd_dj)
    sampRegisterChatCommand("gnk", cmd_gnk)
    sampRegisterChatCommand("cafk", cmd_cafk)
    -- ## ����������� ������ ��������� � ������� ��������� ���� ## --

    -- ## ����������� ��������������� ������ ## --
    sampRegisterChatCommand("u", cmd_u)
	sampRegisterChatCommand("uu", cmd_uu)
	sampRegisterChatCommand("uj", cmd_uj)
	sampRegisterChatCommand("as", cmd_as)
	sampRegisterChatCommand("stw", cmd_stw)
	sampRegisterChatCommand("ru", cmd_ru)
	sampRegisterChatCommand('rcl', function()
        toast.Show(u8"������� ���� ��������.", toast.TYPE.WARN)
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
    -- ## ����������� ��������������� ������ ## --    

	sampRegisterChatCommand('checksh', function()
		sampAddChatMessage(tag .. "������� ����������: X - " .. sw .. " | Y - " .. sh, -1)
		sampAddChatMessage(tag .. "������ ������� ������������� ��� debug ���������� ���� ����.����������", -1)
	end)

    sampRegisterChatCommand("tool", function()
        elements.imgui.main_window[0] = not elements.imgui.main_window[0]
        elements.imgui.menu_selectable = 0
    end)

	sampRegisterChatCommand("al", function(id)
		sampSendChat("/ans " .. id .. " ��������� ��������������! �� ������ ������ /alogin")
		sampSendChat("/ans " .. id .. " ����������, ������� /alogin � ������� ���� �����.")
	end)

	-- ## �������������� �������� ## --
	    -- ## ���� �������� �� ���������� ������ ������ � ������� ����� ## --

	if not doesDirectoryExist(directoryAutoMute) then  
		createDirectory(directoryAutoMute)
	end  

	local file_read_mat, file_line_mat = io.open(directoryAutoMute .. "/mat.txt", "r"), -1
    if file_read_mat ~= nil then  
        file_read_mat:seek("set", 0)
        for line in file_read_mat:lines() do  
            onscene_mat[file_line_mat] = line  
            file_line_mat = file_line_mat + 1 
        end  
        file_read_mat:close()  
    else
        file_read_mat, file_line_mat = io.open(directoryAutoMute.."/mat.txt", 'w'), 1
        for _, v in ipairs(onscene_mat) do  
            file_read_mat:write(v .. "\n")
        end 
        file_read_mat:close()
    end

    local file_read_osk, file_line_osk = io.open(directoryAutoMute.."/osk.txt", 'r'), 1
    if file_read_osk ~= nil then  
        file_read_osk:seek("set", 0)
        for line in file_read_osk:lines() do  
            onscene_osk[file_line_osk] = line  
            file_line_osk = file_line_osk + 1 
        end  
        file_read_osk:close()  
    else 
        file_read_osk, file_line_osk = io.open(directoryAutoMute.."/osk.txt", 'w'), 1
        for _, v in ipairs(onscene_osk) do  
            file_read_osk:write(v .. "\n")
        end 
        file_read_osk:close()
    end

    local file_read_rod, file_line_rod = io.open(directoryAutoMute.."/rod.txt", 'r'), 1
    if file_read_rod ~= nil then  
        file_read_rod:seek("set", 0)
        for line in file_read_rod:lines() do  
            onscene_rod[file_line_rod] = line  
            file_line_rod = file_line_rod + 1 
        end  
        file_read_rod:close()  
    else
        file_read_rod, file_line_rod = io.open(directoryAutoMute.."/rod.txt", 'w'), 1
        for _, v in ipairs(onscene_rod) do  
            file_read_rod:write(v .. "\n")
        end 
        file_read_rod:close()
    end

    local file_read_upom, file_line_upom = io.open(directoryAutoMute.."/upom.txt", 'r'), 1
    if file_read_upom ~= nil then  
        file_read_upom:seek("set", 0)
        for line in file_read_upom:lines() do  
            onscene_upom[file_line_upom] = line  
            file_line_upom = file_line_upom + 1 
        end  
        file_read_upom:close()  
    else 
        file_read_upom, file_line_upom = io.open(directoryAutoMute.."/upom.txt", 'w'), 1
        for _, v in ipairs(onscene_upom) do  
            file_read_upom:write(v .. "\n")
        end 
        file_read_upom:close()
    end

		-- ## ���� �������� �� ���������� ������ ������ � ������� ����� ## --

		-- ## ���� �������������� ������� ��� ������ � ��������� (���� ����� ����/�������� ����) ## --

	sampRegisterChatCommand("s_rod", save_rod)
	sampRegisterChatCommand("d_rod", delete_rod)

	sampRegisterChatCommand("s_upom", save_upom)
	sampRegisterChatCommand("d_upom", delete_upom)

	sampRegisterChatCommand("s_osk", save_osk)
	sampRegisterChatCommand("d_osk", delete_osk)

	sampRegisterChatCommand("s_mat", save_mat)
	sampRegisterChatCommand("d_mat", delete_mat)

		-- ## ���� �������������� ������� ��� ������ � ��������� (���� ����� ����/�������� ����) ## --


    while true do
        wait(0)

		if control_spawn and elements.boolean.autologin[0] then  
			sampAddChatMessage(tag .. "AutoLogin �������� � ������� 15 ������ ����� ������.", -1)
			sampAddChatMessage(tag .. "��������...", -1)
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

-- ## ���� �������, ���������� �� ��������� � ����� �������� �������. ����������� � �������� ## --
function save_rod(param)
    if param == nil then  
        return false  
    end 
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
        return false 
    end
    for _, val in ipairs(onscene_rod) do  
        if atlibs.string_rlower(param) == val then  
            sampAddChatMessage(tag .. " ����� \"" .. val .. "\" ��� ������������ � ������ ���� ����������� ������.", -1)
            return false  
        end    
    end  
    local file_write, file_line = io.open(directoryAutoMute.."/rod.txt", 'w'), 1
    onscene_rod[#onscene_rod + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_rod) do  
        file_write:write(val .. "\n")
    end  
    file_write:close() 
    sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ������� ��������� � ������ ���� ����������� ������", -1)
end

function delete_rod(param)
    if param == nil then  
        return false  
    end  
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
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
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ���� ������� ������� �� ������ ���� ����������� ������", -1)
        control_onscene_rod = false
    else
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ��� � ������ ���� ����������� ������", -1)
    end
end

function save_upom(param)
    if param == nil then  
        return false 
    end 
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
        return false 
    end
    for _, val in ipairs(onscene_upom) do 
        if atlibs.string_rlower(param) == val then  
            sampAddChatMessage(tag .. " ����� \"" .. val .. "\" ��� ������������ � ������ ���� ���������� ��������� ��������.", -1)
            return false 
        end 
    end 
    local file_read, file_line = io.open(directoryAutoMute.. "/upom.txt", "w"), 1
    onscene_upom[#onscene_upom + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_upom) do 
        file_read:write(val .. "\n")
    end 
    file_read:close() 
    sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ������� ��������� � ������ ���� ���������� ��������� ��������.", -1)
end

function delete_upom(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
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
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ���� ������� ������� �� ������ ���� ���������� ��������� ��������.", -1)
        control_onscene_upom = false
    else
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ��� � ������ ���� ���������� ��������� ��������.", -1)
    end
end

function save_osk(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
        return false 
    end
    for _, val in ipairs(onscene_osk) do
        if atlibs.string_rlower(param) == val then
            sampAddChatMessage(tag .. " ����� \"" .. val .. "\" ��� ������������ � ������ �����������/��������.", -1)
            return false
        end
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/osk.txt", "w"), 1
    onscene_osk[#onscene_osk + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_osk) do
        file_write:write(val .. "\n")
    end
    file_write:close()
    sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ������� ��������� � ������ �����������/��������.", -1)
end

function delete_osk(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
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
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ���� ������� ������� �� ������ �����������/��������.", -1)
        control_onscene_osk = false
    else
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ��� � ������ �����������/��������.", -1)
    end
end

function save_mat(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
        return false 
    end
    for _, val in ipairs(onscene_mat) do
        if atlibs.string_rlower(param) == val then
            sampAddChatMessage(tag .. " ����� \"" .. val .. "\" ��� ������������ � ������ ����������� �����.", -1)
            return false
        end
    end
    local file_write, file_line = io.open(directoryAutoMute.. "/mat.txt", "w"), 1
    onscene_mat[#onscene_mat + 1] = atlibs.string_rlower(param)
    for _, val in ipairs(onscene_mat) do
        file_write:write(val .. "\n")
    end
    file_write:close()
    sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ������� ��������� � ������ ����������� �������.", -1)
end

function delete_mat(param)
    if param == nil then
        return false
    end
    if param == "" then  
        sampAddChatMessage(tag .. "�� ����� ������ �����.", -1)
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
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ���� ������� ������� �� ������ ����������� �����.", -1)
        control_onscene_mat = false
    else
        sampAddChatMessage(tag .. " ����� \"" .. atlibs.string_rlower(param) .. "\" ��� � ������ ������������.", -1)
    end
end
-- ## ���� �������, ���������� �� ��������� � ����� �������� �������. ����������� � �������� ## --

-- ## ���� �������, ���������� �� ������ ������ �������� ��� ����� ����������� ���� ## --
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
-- ## ���� �������, ���������� �� ������ ������ �������� ��� ����� ����������� ���� ## --

-- ## ���� ������� � ������ ��������� ���� ## --
function cmd_flood(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.mute then  
			if arg2 == '1' then
				sampSendChat("/mute " .. arg1 .. " 120 " .. " ����/���� ")
			elseif arg2 == '2' then  
				sampSendChat("/mute " .. arg1 .. " 240 " .. " ����/���� x2")
			elseif arg2 == '3' then  
				sampSendChat("/mute " .. arg1 .. " 360 " .. " ����/���� x3")
			elseif arg2 == '4' then  
				sampSendChat("/mute " .. arg1 .. " 480 " .. " ����/���� x4")
			elseif arg2 == '5' then  
				sampSendChat("/mute " .. arg1 .. " 600 " .. " ����/���� x5")
			elseif arg2 == '6' then  
				sampSendChat("/mute " .. arg1 .. " 720 " .. " ����/���� x6")
			elseif arg2 == '7' then  
				sampSendChat("/mute " .. arg1 .. " 840 " .. " ����/���� x7")
			elseif arg2 == '8' then  
				sampSendChat("/mute " .. arg1 .. " 960 " .. " ����/���� x8")
			elseif arg2 == '9' then  
				sampSendChat("/mute " .. arg1 .. " 1080 " .. " ����/���� x9")
			elseif arg2 == '10' then  
				sampSendChat("/mute " .. arg1 .. " 1200 " .. " ����/���� x10")
			end
		end
	elseif arg:find('(.+)') then
		if main_access.settings.mute then  
        	sampSendChat("/mute " .. arg .. " 120 " .. " ����/���� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 120 ����/����')
		end
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /fd [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end


function cmd_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.mute then 
			if arg2 == '1' then
				sampSendChat("/mute " .. arg1 .. " 120 " .. " ���������������� ")
			elseif arg2 == '2' then  
				sampSendChat("/mute " .. arg1 .. " 240 " .. " ���������������� x2")
			elseif arg2 == '3' then  
				sampSendChat("/mute " .. arg1 .. " 360 " .. " ���������������� x3")
			elseif arg2 == '4' then  
				sampSendChat("/mute " .. arg1 .. " 480 " .. " ���������������� x4")
			elseif arg2 == '5' then  
				sampSendChat("/mute " .. arg1 .. " 600 " .. " ���������������� x5")
			elseif arg2 == '6' then  
				sampSendChat("/mute " .. arg1 .. " 720 " .. " ���������������� x6")
			elseif arg2 == '7' then  
				sampSendChat("/mute " .. arg1 .. " 840 " .. " ���������������� x7")
			elseif arg2 == '8' then  
				sampSendChat("/mute " .. arg1 .. " 960 " .. " ���������������� x8")
			elseif arg2 == '9' then  
				sampSendChat("/mute " .. arg1 .. " 1080 " .. " ���������������� x9")
			elseif arg2 == '10' then  
				sampSendChat("/mute " .. arg1 .. " 1200 " .. " ���������������� x10")
			end
		end
	elseif arg:find('(.+)') then
		if main_access.settings.mute then
        	sampSendChat("/mute " .. arg .. " 120 " .. " ���������������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 120 ����������������')
		end
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /po [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_zs(arg)
	if #arg > 0 then 
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 600 " .. " �����.��������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 600 ����� ���������')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_m(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 300 " .. " ����������� �������. ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 300 mat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ia(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " ..  arg .. " 2500 " .. " ������ ���� �� ������������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 2500 ������ ���� �� ���')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_kl(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 3000 " .. " ������� �� ������������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 3000 kleveta adm')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_oa(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 2500 " .. " ���/����.�������������  ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 2500 osk adm')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ok(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 400 " .. " �����������/��������. ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 400 ���')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm2(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 2500 " .. " ������������ ��������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 2500 neadekvat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm3(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 5000 " ..  " ������������ ��������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 5000 neadekvat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_or(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 5000 " .. " �����������/���������� ������ ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 5000 ��� ������')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm1(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 900 " .. " ������������ ��������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 900 neadekvat')			
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_up(arg)
	lua_thread.create(function()
		if #arg > 0 then
			if main_access.settings.mute then 
				sampSendChat("/mute " .. arg .. " 1000 " .. " ���������� ��������� �������� ")
				wait(1000)
				sampSendChat("/cc ")
				sampAddChatMessage(tag .. "������� ���� ����� � ������� ����.", -1)
			else 
				sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
				sampSendChat('/a /mute ' .. arg .. ' 1000 ����.����.��������')
			end 
		else 
			sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
		end
	end)
end

function cmd_rz(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/mute " .. arg .. " 5000 " .. " ������ ������. �����")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /mute ' .. arg .. ' 5000 ������ ������.�����')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end	

-- ## ���� ������� � ������ ������-��������� ���� ## --
function cmd_rup(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 1000 " .. " ���������� ��������� ��������. ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 1000 ����.����.��������')
		end 
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ror(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 5000 " .. " �����������/���������� ������ ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 5000 ��� ������')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_cpfd(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.mute then
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
		end
	elseif arg:find('(.+)') then
		if main_access.settings.mute then  
        	sampSendChat("/rmute " .. arg .. " 120 " .. " caps/offtop ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 120 caps/offtop')
		end 
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /cp [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_report_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.mute then
			if arg2 == '1' then
				sampSendChat("/rmute " .. arg1 .. " 120 " .. " ���������������� ")
			elseif arg2 == '2' then  
				sampSendChat("/rmute " .. arg1 .. " 240 " .. " ���������������� x2")
			elseif arg2 == '3' then  
				sampSendChat("/rmute " .. arg1 .. " 360 " .. " ���������������� x3")
			elseif arg2 == '4' then  
				sampSendChat("/rmute " .. arg1 .. " 480 " .. " ���������������� x4")
			elseif arg2 == '5' then  
				sampSendChat("/rmute " .. arg1 .. " 600 " .. " ���������������� x5")
			elseif arg2 == '6' then  
				sampSendChat("/rmute " .. arg1 .. " 720 " .. " ���������������� x6")
			elseif arg2 == '7' then  
				sampSendChat("/rmute " .. arg1 .. " 840 " .. " ���������������� x7")
			elseif arg2 == '8' then  
				sampSendChat("/rmute " .. arg1 .. " 960 " .. " ���������������� x8")
			elseif arg2 == '9' then  
				sampSendChat("/rmute " .. arg1 .. " 1080 " .. " ���������������� x9")
			elseif arg2 == '10' then  
				sampSendChat("/rmute " .. arg1 .. " 1200 " .. " ���������������� x10")
			end
		end
	elseif arg:find('(.+)') then
		if main_access.settings.mute then  
        	sampSendChat("/rmute " .. arg .. " 120 " .. " ���������������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 120 ����������������')
		end
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /rpo [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_rm(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 300 " .. " ����������� �������. ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 300 mat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_roa(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 2500 " .. " ���/����.�������������  ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 2500 osk adm')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_report_neadekvat(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.mute then  
			if arg2 == '2' then
				sampSendChat("/rmute " .. arg1 .. " 1800 " .. " ������������ ��������� x2")
			elseif arg2 == '3' then  
				sampSendChat("/rmute " .. arg1 .. " 3000 " .. " ������������ ��������� x3")
			elseif arg2 == '1' then  
				sampSendChat("/rmute " .. arg1 .. " 900 " .. " ������������ ���������")
			end
		end
	elseif arg:find('(.+)') then
		if main_access.settings.mute then  
        	sampSendChat("/rmute " .. arg .. " 900 " .. " ������������ ���������")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 900 neadekvat')
		end
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /rnm [IDPlayer] [~��������� (�� 2-3)]", -1)
	end
end

function cmd_rok(arg)
	if #arg > 0 then
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 400 " .. " �����������/��������. ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 400 osk')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_rrz(arg)
	if #arg > 0 then 
		if main_access.settings.mute then  
			sampSendChat("/rmute " .. arg .. " 5000 " .. " ������ ������. �����")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /rmute ' .. arg .. ' 5000 ������ ������.�����')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end	
-- ## ���� ������� � ������ ������-��������� ���� ## --

-- ## ���� ������� � ������ offline-��������� ���� ## --
function cmd_azs(arg)
	if #arg > 0 then  
		sampSendChat("/muteakk"  .. arg .. " 600 " .. " �����.���������")
	else  
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end 
end		

function cmd_afd(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 120 " .. " ����/����")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_apo(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 120 " .. " ���������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_am(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 300 " .. " ����������� �������.")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_aok(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 400 " .. " �����������/��������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_offline_neadekvat(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '2' then
		    sampSendChat("/muteakk " .. arg1 .. " 1800 " .. " ������������ ��������� x2")
        elseif arg2 == '3' then  
            sampSendChat("/muteakk " .. arg1 .. " 3000 " .. " ������������ ��������� x3")
        elseif arg2 == '1' then  
            sampSendChat("/muteakk " .. arg1 .. " 900 " .. " ������������ ���������")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/muteakk " .. arg .. " 900 " .. " ������������ ���������")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /anm [IDPlayer] [~��������� (�� 2-3)]", -1)
	end
end


function cmd_aoa(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 2500 " .. " ���/����.������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_aor(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 5000 " .. " �����������/���������� ������ ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_aup(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 1000 " .. " ���������� ����� ������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end 

function cmd_aia(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 2500 " .. " ������ ���� �� �������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_akl(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 3000 " .. " ������� �� ������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_arz(arg)
	if #arg > 0 then
		sampSendChat("/muteakk " .. arg .. " 5000 " .. " ������ ������. ����� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end	
-- ## ���� ������� � ������ offline-��������� ���� ## --

-- ## ���� ������� � ������ ��������� ������ ## -- 
function cmd_sk(arg)
	if #arg > 0 then
		if main_access.settings.jail then 
			sampSendChat("/jail " .. arg .. " 300 " .. " Spawn Kill")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 Spawn Kill')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_dz(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
		if main_access.settings.jail then
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
		end
	elseif arg:find('(.+)') then
		if main_access.settings.jail then  
        	sampSendChat("/jail " .. arg .. " 300 " .. " DM/DB in zz ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 DM/DB in zz')
		end
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /dz [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_td(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 300 " .. " DB/car in trade ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 DB/car in trade')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jm(arg)
	if #arg > 0 then
		if main_access.settings.jail then
			sampSendChat("/jail " .. arg .. " 300 " .. " ��������� ������ �� ")
		else
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 ��������� ������ ��')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_pmx(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 300 " .. " ��������� ������ ������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 ������ �������')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_skw(arg)
	if #arg > 0 then
		if main_access.settings.jail then
			sampSendChat("/jail " .. arg .. " 600 " .. " SK in /gw ")
		else
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 600 SK in /gw')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_dgw(arg)
	if #arg > 0 then
		if main_access.settings.jail then
			sampSendChat("/jail " .. arg .. " 500 " .. " ������������� ���������� in /gw ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 500 nark in /gw')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ngw(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 600 " .. " ������������� ����������� ������ in /gw ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 600 CMD in /gw')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_dbgw(arg)
	if #arg > 0 then
		if main_access.settings.jail then 
			sampSendChat("/jail " .. arg .. " 600 " .. " ������������� ��������� in /gw ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 120 helicopter /gw')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_fsh(arg)
	if #arg > 0 then
		if main_access.settings.jail then 
			sampSendChat("/jail " .. arg .. " 900 " .. " ������������� SpeedHack/FlyCar ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 900 SH/FC')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_bag(arg)
	if #arg > 0 then
		if main_access.settings.jail then
			sampSendChat("/jail " .. arg .. " 300 " .. " ������� ������ (deagle in car)")
		else
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 300 Deagle in car')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_pk(arg)
	if #arg > 0 then
		if main_access.settings.jail then
			sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ������ ���� ")
		else
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 900 Parkour Mode')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jch(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 3000 " .. " ������������� ���������� �������/�� ")
		else
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 3000 ���/��')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_zv(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " ..  arg .. " 3000 " .. " ��������������� VIP`om ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 3000 zloup vip')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_sch(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ����������� �������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 900 ���')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jcw(arg)
	if #arg > 0 then
		if main_access.settings.jail then  
			sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ClickWarp/Metla (���)")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 900 ClickWarp/Metla')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_tdbz(arg)
	if #arg > 0 then  
		if main_access.settings.jail then 
			sampSendChat("/jail " .. arg .. " 900 " .. " �� � ������ (zz)")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /jail ' .. arg .. ' 900 DB kovsh (zz)')
		end
	else  
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)	
	end 
end	
-- ## ���� ������� � ������ ��������� ������ ## -- 

-- ## ���� ������� � ������ offline-��������� ������ ## -- 
function cmd_asch(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " ������������� ����������� �������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_ajch(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 3000 " .. " ������������� ���������� �������/�� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_azv(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " ..  arg .. " 3000 " .. " ��������������� VIP`om ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_adgw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 500 " .. " ������������� ���������� in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_ask(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " SpawnKill ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
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
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /adz [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_atd(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " DB/car in trade ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_ajm(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " ��������� ������ �� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_apmx(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " ��������� ������ ������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_askw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " SK in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_angw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " ������������� ����������� ������ in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_adbgw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 600 " .. " db-����, �������� � ���/����/����� in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_afsh(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " ������������� SpeedHack/FlyCar ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_abag(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 300 " .. " ������� ������ (deagle in car)")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_apk(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " ������������� ������ ���� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end

function cmd_ajcw(arg)
	if #arg > 0 then
		sampSendChat("/prisonakk " .. arg .. " 900 " .. " ������������� ClickWarp/Metla (���)")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NICK ����������! ", -1)
	end
end
-- ## ���� ������� � ������ offline-��������� ������ ## -- 

-- ## ���� ������� � ������ ��������� ���� ## -- 
function cmd_hl(arg)
	if #arg > 0 then
		if main_access.settings.ban then
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/iban " .. arg .. " 3 " .. " �����������/��������/��� � �������")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /iban ' .. arg .. ' 3 Mat in helper')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)	
	end
end

function cmd_pl(arg)
	if #arg > 0 then
		if main_access.settings.ban then
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/ban " .. arg .. " 7 " .. " ������� ���� �������������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /ban ' .. arg .. ' 7 Plaguat nick adm')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ob(arg)
	if #arg > 0 then
		if main_access.settings.ban then
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/iban " .. arg .. " 7 " .. " ����� �������� ���� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /iban ' .. arg .. ' 7 obxod')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end 	

function cmd_gcnk(arg)
	if #arg > 0 then
		if main_access.settings.ban then 
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/iban " .. arg .. " 7 " .. " �����, ���������� ����������� ������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /iban ' .. arg .. ' 7 Gang with Mat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_menk(arg)
	if #arg > 0 then
		if main_access.settings.ban then  
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/ban " .. arg .. " 7 " .. " ���, ����������� ����������� ����� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /ban ' .. arg .. ' 7 Nick with TabboWords')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ch(arg)
	if #arg > 0 then
		if main_access.settings.ban then
			lua_thread.create(function()
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/iban " .. arg .. " 7 " .. " ������������� ���������� �������/��. ")
			end)
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /iban ' .. arg .. ' 7 ���/��')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nk(arg)
	if #arg > 0 then
		if main_access.settings.ban then
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/ban " .. arg .. " 7 " .. " ���, ���������� ����������� ������� ")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /ban ' .. arg .. ' 7 Nick with Mat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_bnm(arg)
	if #arg > 0 then
		if main_access.settings.ban then 
			sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
			sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
			sampSendChat("/iban " .. arg .. " 7 " .. " ������������ ���������")
		else 
			sampAddChatMessage(tag .. '��� �������. ��������� �����', -1)
			sampSendChat('/a /iban ' .. arg .. ' 7 neadekvat')
		end
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end	
-- ## ���� ������� � ������ ��������� ���� ## -- 

-- ## ���� ������� � ������ offline-��������� ���� ## --
function cmd_amenk(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " ���, ����������� ����������� ����� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end


function cmd_ahl(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 3 " .. " ���/��������/��� � �������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_ahli(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 3 " .. " ���/��������/��� � �������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ IP ����������! ", -1)
	end
end

function cmd_aob(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. " ����� ���� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_apl(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. " ������� �������� ��������������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_ach(arg)
	if #arg > 0 then
		sampSendChat("/offban " .. arg .. " 7 " .. "  ������������� ���������� �������/�� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_achi(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 7 " .. " ���/�� (ip) ") 
	else 
		sampAddChatMessage(tag .. "�� ������ ������ IP ����������! ", -1)
	end
end

function cmd_ank(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " ���, ���������� ������������ ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_agcnk(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " �����, �������� ������������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end

function cmd_agcnkip(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 7 "  .. " �����, �������� ������������ (ip)")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ IP ����������! ", -1)
	end
end

function cmd_rdsob(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 30 " .. " ����� �������������/�������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ NickName ����������! ", -1)
	end
end	

function cmd_rdsip(arg)
	if #arg > 0 then
		sampSendChat("/banip " .. arg .. " 30 " .. " ����� �������������/�������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ IP ����������! ", -1)
	end
end	

function cmd_abnm(arg)
	if #arg > 0 then
		sampSendChat("/banakk " .. arg .. " 7 " .. " ������������ ���������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ IP ����������! ", -1)
	end
end	
-- ## ���� ������� � ������ offline-��������� ���� ## --

-- ## ���� ������� � ������ ��������� ���� ## --
function cmd_dj(arg)
	if #arg > 0 then
		sampSendChat("/kick " .. arg .. " DM in Jail ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_gnk(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '1' then
		    sampSendChat("/kick " .. arg1 .. " ������� �������. 1/3 ")
        elseif arg2 == '2' then  
            sampSendChat("/kick " .. arg1 .. " ������� �������. 2/3")
        elseif arg2 == '3' then  
            sampSendChat("/kick " .. arg1 .. " ������� �������. 3/3")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/kick " .. arg .. " ������� �������. 1/3 ")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /gnk [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_cafk(arg)
	if #arg > 0 then
		sampSendChat("/kick " .. arg .. " AFK in /arena ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end
-- ## ���� ������� � ������ ��������� ���� ## --

-- ## ���� ������� � ��������������� �������� ## --
function cmd_u(arg)
	sampSendChat("/unmute " .. arg)
end  

function cmd_uu(arg)
    lua_thread.create(function()
        sampSendChat("/unmute " .. arg)
        
        sampSendChat("/ans " .. arg .. " ���������� �� ������, ��������� �����. �������� ����")
    end)
end

function cmd_uj(arg)
    lua_thread.create(function()
        sampSendChat("/unjail " .. arg)
        
        sampSendChat("/ans " .. arg .. " ���������� �� ������, ��������� �����. �������� ����")
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
	    sampSendChat("/rmute " .. arg .. " 5 " .. "  Mistake/������")
	    sampSendChat("/ans " .. arg .. " ���������� �� ������, ��������� �����. �������� ����.")
    end)
end
-- ## ���� ������� � ��������������� �������� ## --


-- ## �������������� ������ /online ## --
function drawOnline()
    if elements.boolean.auto_online[0] then 
        while true do 
			sampAddChatMessage(tag .. "������ ���������� AutoOnline. �������� ������.", -1)
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
-- ## �������������� ������ /online ## --

-- ## ���� ������� ��� ������� SA:MP ## --
function sampev.onServerMessage(color, text)
	local check_string = string.match(text, "[^%s]+")

	lc_lvl, lc_adm, lc_color, lc_nick, lc_id, lc_text = text:match("%[A%-(%d+)%] %((.+){(.+)}%) (.+)%[(%d+)%]: {FFFFFF}(.+)")
	--lc_lvl, lc_nick, lc_id, lc_text = text:match("%[A%-(%d+)%](.+)%[(%d+)%]: {FFFFFF}(.+)")

	if text:find("%[A%] ������������� (.+)%[(%d+)%] %(%d+ level%) ������������� � ����� ������") then  
		nick, _ = text:match("%[A%] ������������� (.+)%[(%d+)%] %(%d+ level%) ������������� � ����� ������")
		if getMyNick() == nick then  
			sampAddChatMessage(tag .. '������ ����', -1)
			sampSendChat('/access')
		end  
	end

	if text:find("�� ������� ��������������!") then  
		if elements.boolean.autologin[0] then 
        	control_spawn = true
		end
    	return true
    end
    if text:find("�� ��� ������������ ��� �������������") then  
		if elements.boolean.autologin[0] then 
			control_spawn = false   
		end
    	return true
    end
	if text:find("���������� ��������������!") then  
		if elements.boolean.autologin[0] then  
			control_spawn = true  
		end  
		return true  
	end 

	function start_forms()
		sampRegisterChatCommand('fac', function()
			lua_thread.create(function()
				sampSendChat('/a AT - ����� �������!')
				wait(500)
				sampSendChat(''..adm_form)
				adm_form = ''
			end)
		end)
		sampRegisterChatCommand('fn', function()
			sampSendChat('/a AT - ����� ���������!')
			adm_form = ''
		end)
	end

	if elements.boolean.adminforms[0] and lc_text ~= nil then
		for k, v in ipairs(reasons) do  
			if lc_text:match(v) ~= nil then  
				adm_form = lc_text .. ' // ' .. lc_nick  
				toast.Show(u8'������ �����! \n /fac - ������� | /fn - ���������', toast.TYPE.INFO, 5)
				sampAddChatMessage(tag .. '�����: ' .. adm_form, -1)
				if elements.boolean.autoforms[0] and not isGamePaused() and not isPauseMenuActive() then  
					lua_thread.create(function()
						sampSendChat('/a AT - ����� �������!')
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
	-- ## ������ � �������. ������� ��������� � ����������� ������������.


	local check_nick, check_id, basic_color, check_text = string.match(text, "(.+)%((.+)%): {(.+)}(.+)") -- ������ �������� ������� ���� � �������� � �� �������

    -- ## �������, ��� mainframe - ������� ## --
    if not isGamePaused() and not isPauseMenuActive() then  
        if text:find("������ (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") then  
            local number_report, nick_rep, id_rep, text_rep = text:match("������ (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") 
            sampAddChatMessage(tag .. "������ ������ " .. number_report .. " �� " .. nick_rep .. "[" .. id_rep .. "]: " .. text_rep, -1)
            if (elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_rod[0] or elements.settings.automute_rod[0]) and main_access.settings.mute then  
                local mat_text, _ = checkMessage(text_rep, 1)
                local osk_text, _ = checkMessage(text_rep, 2)
                local upom_text, _ = checkMessage(text_rep, 3)
                local rod_text, _ = checkMessage(text_rep, 4)
                if mat_text and elements.settings.automute_mat[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | ��� ID[" .. id_rep .. "] �� rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 300 ����������� �������")
                end
                if osk_text and elements.settings.automute_osk[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | ��� ID[" .. id_rep .. "] �� rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 400 ���/����.")
                end
                if upom_text and elements.settings.automute_upom[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | ��� ID[" .. id_rep .. "] �� rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 1000 ����.����.��������")
                end
                if rod_text and elements.settings.automute_rod[0] then  
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampAddChatMessage(tag .. " | ��� ID[" .. id_rep .. "] �� rep: " .. text_rep, -1)
                    sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                    sampSendChat("/rmute " .. id_rep .. " 5000 ���/����. ������")
                end
            end  
            return true
        end
    end
    -- ## �������, ��� mainframe - ������� ## --

    -- ## �������, ��� mainframe - ��� ## --
    if not isGamePaused() and not isPauseMenuActive() then  
        if check_text ~= nil and check_id ~= nil and (elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_upom[0] or elements.settings.automute_rod[0]) and main_access.settings.mute then  
            local mat_text, _ = checkMessage(check_text, 1)
            local osk_text, _ = checkMessage(check_text, 2)
            local upom_text, _ = checkMessage(check_text, 3)
            local rod_text, _ = checkMessage(check_text, 4)
            if mat_text and elements.settings.automute_mat[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | ��� " .. check_nick .. "[" .. check_id .. "] �� msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 300 ����������� �������")
            end
            if osk_text and elements.settings.automute_osk[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | ��� " .. check_nick .. "[" .. check_id .. "] �� msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 400 ���/����.")
            end
            if upom_text and elements.settings.automute_upom[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | ��� " .. check_nick .. "[" .. check_id .. "] �� msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 1000 ����.����.��������")
            end
            if rod_text and elements.settings.automute_rod[0] then  
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " | ��� " .. check_nick .. "[" .. check_id .. "] �� msg: " .. check_text, -1)
                sampAddChatMessage('                                                                            ', -1)
                sampAddChatMessage(tag .. " ======================= | [AT] Automute-Stream | ================== ", -1)
                sampSendChat("/mute " .. check_id .. " 5000 ���/����. ������")
            end
            return true
        end
    end 
end
-- ## ���� ������� ��� ������� SA:MP ## --


-- ## ������� ��� ���������� ������ ## --
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
-- ## ������� ��� ���������� ������ ## --

-- ## �������� ������� ������ ## -- 
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


-- ## �����, ���������� �� �������. � ���������, ����� ��������� �������� ������ �������� �� ������.
function sampev.onShowDialog(id, style, title, button1, button2, text)
	if title:find(getMyNick()) and id == 8991 then  
		lua_thread.create(function()
		text = atlibs.textSplit(text, '\n')
		newtext = nil 
		for i, v in ipairs(text) do  
			if v:find('��� ���� �����') and v:find('�������') then  
				main_access.settings.ban = true
				inicfg.save(main_access, access_file)
			elseif v:find('������ ����') and v:find('�������') then  
				main_access.settings.mute = true
				inicfg.save(main_access, access_file)
			elseif v:find('������ ������') and v:find('�������') then  
				main_access.settings.jail = true
				inicfg.save(main_access, access_file)
			end
			if v:find('��� ���� �����') and v:find('�����������') then  
				main_access.settings.ban = false
				inicfg.save(main_access, access_file)
			elseif v:find('������ ����') and v:find('�����������') then  
				main_access.settings.mute = false
				inicfg.save(main_access, access_file)
			elseif v:find('������ ������') and v:find('�����������') then  
				main_access.settings.jail = false
				inicfg.save(main_access, access_file)
			end
		end
		sampAddChatMessage(tag .. '/access �������������. ��� ��������� ����� /access, ��������� ��������� ������� � ����������.', -1)
		wait(1)
		sampSendDialogResponse(8991, 0, -1)
		end)
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
-- ## �������� ������� ������ ## -- 

-- ## ������ Date and Time ## --
function drawDate()
	font = renderCreateFont('Arial', 20, fflags.BOLD)
	if elements.boolean.render_date[0] then  
		while true do  
			renderFontDrawText(font,'{FFFFFF}' .. (os.date("%d.%m.%y | %H:%M:%S", os.time())),10,sh-30,0xCCFFFFFF)

			wait(1)
		end
	end
end
-- ## ������ Date and Time ## --


local ReconWindow = imgui.OnFrame(
    function() return elements.imgui.recon_window[0] end, 
    function(player)
        
        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 6, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(100, 300), imgui.Cond.FirstUseEver)

        imgui.LockPlayer = false  

        imgui.Begin("reconmenu", elements.imgui.recon_window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize)
            if control_to_player then  
                
                if imgui.Button(u8"����������") then  
                    sampSendChat('/aspawn ' .. recon_id)
                end
                if imgui.Button(u8"��������") then  
                    -- sampSendClickTextdraw(156)
					sampSendClickTextdraw(198)
                end
                if imgui.Button(u8"��������") then  
                    sampSendChat("/slap " .. recon_id)
                end
                if imgui.Button(u8"����������\n�����������") then  
                    sampSendChat("/freeze " .. recon_id)
                end
                if imgui.Button(u8"�����") then
                    sampSendChat("/reoff ")
                    control_to_player = false
                    elements.imgui.recon_window[0] = false
                end
            end
        imgui.End()

        if right_recon[0] then  
            imgui.SetNextWindowPos(imgui.ImVec2(sw - 200, sh - 200), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
            imgui.SetNextWindowSize(imgui.ImVec2(400, 600), imgui.Cond.FirstUseEver)

            imgui.Begin(u8"���������� �� ������", nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
				if accept_load_recon then
					if not sampIsPlayerConnected(recon_id) then 
						recon_nick = '-'
					else
						recon_nick = sampGetPlayerNickname(recon_id)
					end
					imgui.Text(u8"�����: ")
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
					imgui.Text(u8'��������...')
				end
            imgui.End()
        end
    end
)

local helloText = [[
��������� AT ��� ������ �������������. 
����� ��� ������, ������������ ����� ���� ���������� � �� ������.
AT ��� ������ alfantasyz.
������ ������������:
https://vk.com/infsy
]]

local textToMenuSelectableAutoMute = [[
������ ������� ��������� ��������� ������� ��� ���� �����. 
�� ������ �������� ������ �����, 
����������� ������ ����������� ������ � �������� ���� ����.
]]

local MainWindowAT = imgui.OnFrame(
    function() return elements.imgui.main_window[0] end,
    function(player) 

        royalblue()

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(1300, 600), imgui.Cond.FirstUseEver)

        imgui.Begin(fa.SERVER .. " [AT for Android]", elements.imgui.main_window) 
			if imgui.BeginTabBar("##MenuBar") then  
				if imgui.BeginTabItem(fa.HOUSE .. u8" �����������") then  
					imgui.Text(u8(helloText))
					imgui.EndTabItem()
				end  
				if imgui.BeginTabItem(fa.USER_GEAR .. u8" �������� �������") then  
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
						imgui.Text(u8'����-Alogin') 
						imgui.SameLine()
						if mim_addons.ToggleButton('##AutoALogin', elements.boolean.autologin) then  
							config.settings.autologin = elements.boolean.autologin[0]
							save()
						end  
						imgui.SameLine()
						imgui.SetCursorPosX(400)
						imgui.Text(u8"��������� �����-����")
						imgui.SameLine()
						if mim_addons.ToggleButton("##CustomReconMenu", elements.boolean.recon) then  
							config.settings.custom_recon = elements.boolean.recon[0]
							save() 
						end
						ActiveAutoMute()
						imgui.SameLine()
						imgui.SetCursorPosX(400)
						imgui.Text(u8"����-������")
						imgui.SameLine()
						if mim_addons.ToggleButton('##AutoOnline', elements.boolean.auto_online) then  
							config.settings.auto_online = elements.boolean.auto_online[0]
							save()  
							send_online:run()
						end
						imgui.Text(u8'���������������� �����')
						imgui.SameLine()
						if mim_addons.ToggleButton('##AdminsForms', elements.boolean.adminforms) then  
							config.settings.adminforms = elements.boolean.adminforms[0]
							save() 
						end 
						imgui.SameLine()
						if imgui.Checkbox('##AutoForms', elements.boolean.autoforms) then  
							config.settings.autoforms = elements.boolean.autoforms[0]
							save() 
						end; Tooltip('��������� ����� �������������. ������������� �������������!')
						imgui.SameLine()
						imgui.SetCursorPosX(400)
						imgui.Text(u8'����� ���� � �������')
						imgui.SameLine()
						if mim_addons.ToggleButton('##RenderDate', elements.boolean.render_date) then  
							config.settings.render_date = elements.boolean.render_date[0]
							save()  
						end
					imgui.EndTabItem()
				end
				if imgui.BeginTabItem(fa.BOOK .. u8" �������") then  
					imgui.Text(u8(textToMenuSelectableAutoMute))
					ReadWriteAM()
					imgui.EndTabItem()
				end  
				if imgui.BeginTabItem(fa.LIST_OL .. u8" ���������") then  

					if imgui.TreeNodeStr(u8"��������� � �������") then 
						if imgui.TreeNodeStr("Ban") then  
							imgui.Text(u8"/ch [ID] - ��� �� ����")
							imgui.Text(u8"/pl [ID] - ��� �� ������� ���� ������ ")
							imgui.Text(u8"/nk [ID] - ��� �� ��� � �����/���������")
							imgui.Text(u8"/gcnk [ID] - ��� �� �������� ����� � �����/���������")
							imgui.Text(u8"/brekl [ID] - ��� �� ������� | for 18 lvl ")
							imgui.Text(u8"/hl [ID] - ��� �� ��� � �������")
							imgui.Text(u8"/ob [ID] - ��� �� ����� ����")
							imgui.Text(u8"/menk [ID] - ��� �� ������.����� � ����")
							imgui.Text(u8"/bnm [ID] - ��� �� ����������")
							imgui.Text(u8"/bosk [ID] - ��� �� ��� ������� | for 18 lvl ")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							imgui.Text(u8"/sk [ID] - jail �� SK in zz")
							imgui.Text(u8"/dz [ID] [��������� �� 2 �� 10] - jail �� DM/DB in zz")
							imgui.Text(u8"/td [ID] - jail �� DB/car in /trade")
							imgui.Text(u8"/tdbz [ID] - jail �� DB � ������ � ��")
							imgui.Text(u8"/fsh [ID] - /jail �� SH and FC")
							imgui.Text(u8"/jm [ID] - jail �� ��������� ������ �����������.")
							imgui.Text(u8"/bag [ID] - jail �� ������")
							imgui.Text(u8"/pk [ID] - jail �� ������ ���")
							imgui.Text(u8"/zv [ID] - jail �� �����.���")
							imgui.Text(u8"/skw [ID] - jail �� SK �� /gw")
							imgui.Text(u8"/ngw [ID] - jail �� ������������� ������.������ �� /gw")
							imgui.Text(u8"/dbgw [ID] - jail �� DB �������� �� /gw")
							imgui.Text(u8"/jch [ID] - jail �� ����")
							imgui.Text(u8"/pmx [ID] - jail �� ��������� ������ �������")
							imgui.Text(u8"/dgw [ID] - jail �� ��������� �� /gw")
							imgui.Text(u8"/sch [ID] - jail �� ����������� �������")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							imgui.Text(u8"/m [ID] - ��� �� ��� | /rm - ��� �� ��� � ������ ")
							imgui.Text(u8"/ok [ID] - ��� �� �����������/��������")
							imgui.Text(u8"/fd [ID] [��������� �� 2 �� 10] - ��� �� ����/���� x1-x10")
							imgui.Text(u8"/po [ID] [��������� �� 2 �� 10]- ��� �� ���������� x1-x10")
							imgui.Text(u8"/oa [ID] - ��� �� ���.��� ")
							imgui.Text(u8"/roa [ID] - ��� �� ���.��� � ������")
							imgui.Text(u8"/up [ID] - ��� �� ����.�������")
							imgui.Text(u8"/rup [ID] - ��� �� ����.������� � ������")
							imgui.Text(u8"/ia [ID] - ��� �� ������ ���� �� ���")
							imgui.Text(u8"/kl [ID] - ��� �� ������� �� ���")
							imgui.Text(u8"/nm [ID] [��������� �� 2 �� 3] - ��� �� ���������. ")
							imgui.Text(u8"/rnm [ID] [��������� �� 2 �� 3] - ��� �� ��������� � ���.")
							imgui.Text(u8"/or [ID] - ��� �� ��� ���")
							imgui.Text(u8"/rz [ID] - ������ ������.�����")
							imgui.Text(u8"/zs [ID] - ��������������� ���������")
							imgui.Text(u8"/ror [ID] - ��� �� ��� ��� � ������")
							imgui.Text(u8"/cp [ID] [��������� �� 2 �� 10] - ����/������ � ������ x1-x10")
							imgui.Text(u8"/rpo [ID] [��������� �� 2 �� 10] - ���������� � ������ x1-x10")
							imgui.Text(u8"/rkl [ID] - ������� �� ��� � ������")
							imgui.Text(u8"/rrz [ID] - ������ ������.����� � ������")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Kick") then  
							imgui.Text(u8"/dj [ID] - ��� �� dm in jail")
							imgui.Text(u8"/gnk [ID] [�� 1 �� 3] - ��� �� ��������� � ����. \n     ������ �������� �������� �� ���������� ����� � ������������.")
							imgui.Text(u8"/cafk [ID] - ��� �� ��� �� �����")
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"��������� � ��������") then  
						if imgui.TreeNodeStr("Ban") then  
							imgui.Text(u8"/apl [NickName] - ��� �� ������� ��� ������")
							imgui.Text(u8"/ach [NickName] (/achi [IP]) - ��� �� ���� (ip)")
							imgui.Text(u8"/ank [NickName] - ��� �� ��� � ���/����")
							imgui.Text(u8"/agcnk [NickName] - ��� �� �������� ����� � ���/����")
							imgui.Text(u8"/agcnkip [NickName] - ��� �� IP �� �������� ����� � ���/����")
							imgui.Text(u8"/okpr/ip [NickName] - ��� �������")
							imgui.Text(u8"/svoakk/ip [NickName] - ��� �� ���/IP �� �������")
							imgui.Text(u8"/ahl [NickName] (/achi) [IP] - ��� �� ��� � ������� (ip)")
							imgui.Text(u8"/aob [NickName] - ��� �� ����� ����")
							imgui.Text(u8"/rdsob [NickName] - ��� �� ����� ���/�������")
							imgui.Text(u8"/rdsip [NickName] - ��� �� IP �� ����� ���/�������")
							imgui.Text(u8"/amenk [NickName] - ��� �� ������.����� � ����")
							imgui.Text(u8"/abnm  [NickName] - ��� �� ����������")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Jail") then  
							imgui.Text(u8"/ask [NickName] - jail �� SK in zz")
							imgui.Text(u8"/adz [NickName] [��������� �� 2 �� 10] - jail �� DM/DB in zz")
							imgui.Text(u8"/atd [NickName] - jail �� DB/CAR in trade")
							imgui.Text(u8"/afsh [NickName] - jail �� SH ans FC")
							imgui.Text(u8"/ajm [NickName] - jail �� �����.������ ��")
							imgui.Text(u8"/abag [NickName] - jail �� ������")
							imgui.Text(u8"/apk [NickName] - jail �� ������ ���")
							imgui.Text(u8"/azv [NickName] - jail �� �����.���")
							imgui.Text(u8"/askw [NickName] - jail �� SK �� /gw")
							imgui.Text(u8"/angw [NickName] - ���.������.������ �� /gw")
							imgui.Text(u8"/adbgw [NickName] - jail �� DB ���� �� /gw")
							imgui.Text(u8"/ajch [NickName] - jail �� ����")
							imgui.Text(u8"/apmx [NickName] - jail �� ������.������")
							imgui.Text(u8"/adgw [NickName] - jail �� ��������� �� /gw")
							imgui.Text(u8"/asch [NickName] - jail �� ����������� �������")
							imgui.TreePop()
						end
						if imgui.TreeNodeStr("Mute") then  
							imgui.Text(u8"/am [NickName] - ��� �� ��� ")
							imgui.Text(u8"/aok [NickName] - ��� �� ��� ")
							imgui.Text(u8"/afd [NickName] - ��� �� ����/����")
							imgui.Text(u8"/apo [NickName]  - ��� �� ����������")
							imgui.Text(u8"/aoa [NickName] - ��� �� ���.���")
							imgui.Text(u8"/aup [NickName] - ��� �� ���������� ��������")
							imgui.Text(u8"/anm [NickName] [��������� �� 2 �� 3]- ��� �� ����������")
							imgui.Text(u8"/aor [NickName] - ��� �� ���/���� ������")
							imgui.Text(u8"/aia [NickName] - ��� �� ������ ���� �� ���")
							imgui.Text(u8"/akl [NickName] - ��� �� ������� �� ���")
							imgui.Text(u8"/arz [NickName] - ��� �� ������ ������.�����")
							imgui.TreePop()
						end
						imgui.TreePop()
					end
		
					if imgui.TreeNodeStr(u8"�������������� ������� AT") then  
						imgui.Text(u8"/u [ID] - ������� ������")
						imgui.Text(u8"/uu [ID] - ������ � ���������� � /ans")
						imgui.Text(u8"/uj [ID] - ����������� ������")
						imgui.Text(u8"/as [ID] - ��������� ������")
						imgui.Text(u8"/ru [ID] - ������ �������")
						imgui.Text(u8"/rcl - ������� ���� (�� /cc, ��������� ��� ���)")
						imgui.Text(u8"/spp [ID] - ���������� ���� ������� � ���� ������ *")
						imgui.Text(u8"     * ���� ������ - ��� �������, � ������� ���� ����� �������")
						imgui.Text(u8"/aheal [ID] - �������� ������")
						imgui.Text(u8"/akill [ID] - ����� ������")
						imgui.TreePop()
					end
					imgui.EndTabItem()
				end 
				if imgui.BeginTabItem(fa.TABLE_LIST .. u8' �����') then  
					showFlood_ImGUI()
					imgui.EndTabItem()
				end
				if imgui.BeginTabItem(fa.LIST .. u8" ������ /ans") then   
					QuestionAnswer.BinderEdit()
					imgui.EndTabItem()
				end
				if imgui.BeginTabItem(fa.USERS .. u8' �����������') then  
					if imgui.BeginTabBar('##EventBar') then  
						if imgui.BeginTabItem(fa.WAREHOUSE .. u8" ��������� ����") then  
							posX, posY, posZ = getCharCoordinates(PLAYER_PED)
							imgui.TextWrapped(u8"����� �� ������ ������� ����������� � ��������� ��.")
							imgui.TextWrapped(u8"���������� ���� �������� � ����������� �� ���������� ����.")
							imgui.TextWrapped(u8"����� �����, ���������� ������� ���� ����� ������������ � �������� �����������.")
							imgui.TextWrapped(u8"AT Events �������� ��������� ���������� ������������ � ������ RealTime.")
							imgui.TextWrapped(u8"AT Events ������������ �������� ������ ����������� � ���� ��� ������������� ������������� �������������.")
							imgui.Text('')
							imgui.Text(u8'���� �����: \nX: ' .. posX .. ' | Y: ' .. posY .. ' | Z: ' .. posZ)
							imgui.EndTabItem()
						end
						if imgui.BeginTabItem(fa.MAP_LOCATION .. u8' �������� ��') then  
							imgui.Text(u8'������ ������ ��������� ������� ���� �����������.')
							imgui.TextWrapped(u8"�������� ����������� ����� ������ ���� ��������������� ��� ���������� ����� ��������. ")
							imgui.Text(u8"������� ��������� �� �������� ������.");
							Tooltip("����� � ��������/�������� ������� ���������� �������:\n1. �������� �� �������� ������, �.�. ����� ����� mess � �����. ������: \n 6 ������� � �� ����� ������� ���! \n 6 ��������� ������������ /heal, /r � /s\n2. ������ ������� �������� �������� ��� ����������� ������. ")
							imgui.Separator()
							imgui.PushItemWidth(130)
							imgui.InputText(u8"��� MP", elements.buffers.name, ffi.sizeof(elements.buffers.name))  
							imgui.PopItemWidth()
							imgui.SameLine()
							imgui.PushItemWidth(60)
							imgui.InputText(u8"/dt", elements.buffers.vdt, ffi.sizeof(elements.buffers.vdt)); Tooltip("���� ���� ������ �� �������, �� ����������� ��� �������� ��������.")
							imgui.PopItemWidth()
							imgui.Separator()
							imgui.CenterText("������� �����������")
							imgui.PushItemWidth(400)
							imgui.InputTextMultiline("##RulesForEvent", elements.buffers.rules, ffi.sizeof(elements.buffers.rules), imgui.ImVec2(-1, 250))
							imgui.PopItemWidth()
							if imgui.Button(u8"����� ������") then  
								text = atlibs.string_split(ffi.string(elements.buffers.rules):gsub("\n", "~"), "~")
								for _, i in pairs(text) do  
									sampSendChat("/mess " .. u8:decode(i))
								end
							end; Tooltip("������� ����� ������ �� ��� ������������ ����������.")
							imgui.SameLine()
							imgui.SetCursorPosX(imgui.GetWindowWidth() - 400)
							if imgui.Button(u8"�����.�������") then  
								sampSendChat("/mess 6 �� ����������� ������: /passive, /anim, /r - /s, DM, �������� ������ ������� �������")
								sampSendChat("/mess 6 ��� ��������� ������, �� ������ �������� � Jail.")
							end; Tooltip("������� ����� ������ �� ��� ������������ ����������.")
							imgui.SameLine()
							imgui.SetCursorPosX(imgui.GetWindowWidth() - 200)
							if imgui.Button(u8"������ ��") then  
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
									sampSendChat("/mess 6 ��������� ������! �������� �����������: " .. u8:decode(tostring(ffi.string(elements.buffers.name))) .. ". ��������: /tpmp")
									sampSendChat("/mess 6 ��������� ������! �������� �����������: " .. u8:decode(tostring(ffi.string(elements.buffers.name))) .. ". ��������: /tpmp")
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
									sampAddChatMessage(tag .. '�� "' ..u8:decode(ffi.string(elements.buffers.name)).. '" ������� ��������� � ������!', -1)
									imgui.StrCopy(elements.buffers.name, '')
									imgui.StrCopy(elements.buffers.text, '')
									imgui.StrCopy(elements.buffers.vdt, '0')
									imgui.StrCopy(elements.buffers.coord, '0')
								end  
							end; Tooltip("������� ��������� ��������� ������ ����������� � �������. \n������������ ��������������, ������ �� ��� ������, ��� �� �� ������ ������ ������.")

							imgui.EndTabItem()
						end 
						if imgui.BeginTabItem(fa.TERMINAL .. u8' ��������� � ������') then  
							imgui.TextWrapped(u8"� ������ ������� ����� ������������ ����������� �� ������������, ���� ������� ���� � ������������ �� � ����������.")
							imgui.TextWrapped(u8"�������� �� ��������. �������� ������! � ���� ���������� ��� ��������� ��������� :D");
							Tooltip("� ���. ������ ���������� �� �������� ������ �����������. \n����� � ��������/�������� ������� ���������� �������:\n1. �������� �� �������� ������, �.�. ����� ����� mess � �����. ������: \n 6 ������� � �� ����� ������� ���! \n 6 ��������� ������������ /heal, /r � /s\n2. ������ ������� �������� �������� ��� ����������� ������. \n\n ���������� ����� ����� �� �������� ��������, ���� �������� '��� �������' \n ����������� ��� ������������� �������� ��������, ��� ������ ������ ������� \n ����������� ��������� �������������, ������� �� ��� ������ ���������� ��� ����.")
							imgui.Separator()

							if imgui.Button(u8'������� �����������') then  
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
										sampAddChatMessage(tag .. '�������� ������ ������ �� "' .. u8:decode(bind) .. '"', -1)
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
											sampSendChat("/mess 6 ��������� ������! �������� �����������: " .. u8:decode(tostring(cfgevents.bind_name[key])) .. ". ��������: /tpmp")
											sampSendChat("/mess 6 ��������� ������! �������� �����������: " .. u8:decode(tostring(cfgevents.bind_name[key])) .. ". ��������: /tpmp")
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
										sampAddChatMessage(tag .. '�� "' ..u8:decode(cfgevents.bind_name[key])..'" �������!', -1)
										table.remove(cfgevents.bind_name, key)
										table.remove(cfgevents.bind_text, key)
										EventsSave()
									end
								end  
							else 
								imgui.TextWrapped(u8'�� ���� ����������� �� ����������������. �����, ��������?')
							end

							if imgui.BeginPopupModal('EventsBinder', false, imgui.WindowFlags.NoResize + imgui.WindowFlags.AlwaysAutoResize) then  
								imgui.BeginChild('##CreateEdit', imgui.ImVec2(800, 500), true)
									imgui.Text(u8"�������� ��: "); imgui.SameLine()
									imgui.PushItemWidth(130)
									imgui.InputText('##name_events', elements.buffers.name, ffi.sizeof(elements.buffers.name))
									imgui.PopItemWidth()
									imgui.Text(u8"����������� ���: "); Tooltip("������ �������� ������������ ���� (�������� �� 0) ���������� ��� �������� ������ ����������� \n����� ����������: ���������� �� 500 �� 999 ���������� ����������.\n���������� � ������ ����� ����������� ����������� ��������, ����� ������ �� ��������.")
									imgui.SameLine()
									imgui.PushItemWidth(60)
									imgui.InputText('##dt_event', elements.buffers.vdt, ffi.sizeof(elements.buffers.vdt))
									imgui.PopItemWidth()
									imgui.SameLine()
									if imgui.Button(u8"������") then  
										math.randomseed(os.clock())
										local dt = math.random(500, 999)
										imgui.StrCopy(elements.buffers.vdt, tostring(dt))
									end; Tooltip("������ ��� ��������� ��������� ����� ������������ ���� (/dt)")
									imgui.Text(u8"���������� ������ ��: ")
									imgui.SameLine()
									imgui.PushItemWidth(250)
									imgui.InputText("##CoordsEvent", elements.buffers.coord, ffi.sizeof(elements.buffers.coord))
									imgui.PopItemWidth()
									imgui.SameLine()
									if imgui.Button(u8"��� �������") then  
										positionX, positionY, positionZ = getCharCoordinates(playerPed)
										positionX = string.sub(tostring(positionX), 1, string.find(tostring(positionX), ".")+6)
										positionY = string.sub(tostring(positionY), 1, string.find(tostring(positionY), ".")+6)
										positionZ = string.sub(tostring(positionZ), 1, string.find(tostring(positionZ), ".")+6)
										imgui.StrCopy(elements.buffers.coord, tostring(positionX) .. "," .. tostring(positionY) .. "," .. tostring(positionZ))
									end; Tooltip("�������� ����������, �� ������� �� ������ ����������. \n���������� ��������� �������������� �� 2-4 ������ ����� �������.")
									imgui.Separator()
									imgui.Text(u8"�������/�������� ��:")
									imgui.PushItemWidth(300)
									imgui.InputTextMultiline("##EventText", elements.buffers.text, ffi.sizeof(elements.buffers.text), imgui.ImVec2(-1, 280))
									imgui.PopItemWidth()
									imgui.SetCursorPosX((imgui.GetWindowWidth() - 100) / 100)
									if imgui.Button(u8'�������##bind') then  
										imgui.StrCopy(elements.buffers.name, '')
										imgui.StrCopy(elements.buffers.text, '')
										imgui.StrCopy(elements.buffers.vdt, '0')
										imgui.StrCopy(elements.buffers.coord, '0')
										imgui.CloseCurrentPopup()
									end  
									imgui.SameLine()
									if #ffi.string(elements.buffers.name) > 0 and #ffi.string(elements.buffers.text) > 0 then  
										imgui.SetCursorPosX((imgui.GetWindowWidth() - 200) / 1.01)
										if imgui.Button(u8'���������##bind') then  
											if not EditOldBind then  
												local refresh_text = ffi.string(elements.buffers.text):gsub("\n", "~")
												table.insert(cfgevents.bind_name, ffi.string(elements.buffers.name))
												table.insert(cfgevents.bind_text, refresh_text)
												table.insert(cfgevents.bind_vdt, tostring(ffi.string(elements.buffers.vdt)))
												table.insert(cfgevents.bind_coords, ffi.string(elements.buffers.coord))
												if EventsSave() then  
													sampAddChatMessage(tag .. '�� "' ..u8:decode(ffi.string(elements.buffers.name)).. '" ������� �������!', -1)
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
													sampAddChatMessage(tag .. '�� "' ..u8:decode(ffi.string(elements.buffers.name)).. '" ������� ���������������!', -1)
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
					imgui.EndTabItem()
				end 
				if imgui.BeginTabItem(fa.GEARS) then   
					if imgui.Button(u8'���������� ��������������� ����') then  
						local response_menu = downloadFile(urls['rdsmenu'], paths['rdsmenu'])
						if response_menu then  
							sampAddChatMessage(tag .. '���������� ��������������� ���� ��������� �������.')
							reloadScripts()
						end
					end
					imgui.EndTabItem()
				end
				imgui.EndTabBar()
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

-- ## ���� �������-�������� ��� ���������� �� � �������� ������ ## --
function ActiveAutoMute()
    if imgui.Button(fa.NEWSPAPER .. u8" �������") then  
        imgui.OpenPopup('##SettingsAutoMute')
    end  
    if imgui.BeginPopup('##SettingsAutoMute') then  
        if mim_addons.ToggleButton(u8'������� �� ���', elements.settings.automute_mat) then  
            config.settings.automute_mat = elements.settings.automute_mat[0] 
            save()  
        end
        if mim_addons.ToggleButton(u8'������� �� ���', elements.settings.automute_osk) then  
            config.settings.automute_osk = elements.settings.automute_osk[0]
            save() 
        end  
        if mim_addons.ToggleButton(u8'������� �� ����.����.��������', elements.settings.automute_upom) then  
            config.settings.automute_upom = elements.settings.automute_upom[0]
            save()  
        end  
        if mim_addons.ToggleButton(u8'������� �� ��� ������', elements.settings.automute_rod) then  
            config.settings.automute_rod = elements.settings.automute_rod[0]
            save()  
        end
        imgui.EndPopup()
    end
end

function ReadWriteAM()
	imgui.TextWrapped(u8"���� ����������� ������ ������ � ���� ������. ��� ������ �����, ������� �� ������.")
    imgui.BeginChild('##MenuRWAMF', imgui.ImVec2(230, 380), true)
        if imgui.Button(u8"���") then  
            elements.imgui.selectable = 1
        end  
        if imgui.Button(u8"���/����") then  
            elements.imgui.selectable = 2
        end  
        if imgui.Button(u8"����.��������") then  
            elements.imgui.selectable = 3
        end 
        if imgui.Button(u8"��� ������") then  
            elements.imgui.selectable = 4
        end
    imgui.EndChild()
    imgui.SameLine()
    imgui.BeginChild('##WindowRWAMF', imgui.ImVec2(700, 380), true)
        if elements.imgui.selectable == 0 then  
            imgui.TextWrapped(u8"������������ ����� ���������. ������ ���� ��������� ����� ����� ������������� � ����� ��� ����������.")
            imgui.Text(u8"�� ������ ������ �� ���� ���� �� �������� � ������.")
        end  
        if elements.imgui.selectable == 1 then  
            imgui.Text(u8"��� ����������/�������� ����, ����������� ���� ����� ����")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
            if #ffi.string(elements.imgui.input_word) > 0 then
                if imgui.Button(u8"��������") then  
                    save_mat(u8:decode(ffi.string(elements.imgui.input_word)))
                end  
                if imgui.Button(u8"�������") then  
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
            imgui.Text(u8"��� ����������/�������� ����, ����������� ���� ����� ����")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"��������") then  
					save_osk(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"�������") then  
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
            imgui.Text(u8"��� ����������/�������� ����, ����������� ���� ����� ����")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"��������") then  
					save_upom(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"�������") then  
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
            imgui.Text(u8"��� ����������/�������� ����, ����������� ���� ����� ����")
            imgui.InputText("##InputWord", elements.imgui.input_word, ffi.sizeof(elements.imgui.input_word))
            imgui.SameLine()
            if imgui.Button(fa.ROTATE) then  
                imgui.StrCopy(elements.imgui.input_word, '')
            end  
			if #ffi.string(elements.imgui.input_word) > 0 then
				if imgui.Button(u8"��������") then  
					save_rod(u8:decode(ffi.string(elements.imgui.input_word)))
				end  
				if imgui.Button(u8"�������") then  
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
-- ## ���� �������-�������� ��� ���������� �� � �������� ������ ## --

function showFlood_ImGUI()
    local colours_mess = [[
0 - {FFFFFF}�����, {FFFFFF}1 - {000000}������, {FFFFFF}2 - {008000}�������, {FFFFFF}3 - {80FF00}������-�������
4 - {FF0000}�������, {FFFFFF}5 - {0000FF}�����, {FFFFFF}6 - {FDFF00}������, {FFFFFF}7 - {FF9000}���������
8 - {B313E7}����������, {FFFFFF}9 - {49E789}���������, {FFFFFF}10 - {139BEC}�������
11 - {2C9197}�����-�������, {FFFFFF}12 - {DDB201}�������, {FFFFFF}13 - {B8B6B6}�����, {FFFFFF}14 - {FFEE8A}������-������
15 - {FF9DB6}�������, {FFFFFF}16 - {BE8A01}����������, {FFFFFF}17 - {E6284E}�����-�������
]]
    imgui.Text(u8"����� ����� ������������ ����� � ��� /mess ��� �������.")
    imgui.Separator()
    if imgui.CollapsingHeader(u8'����������� ������ /mess') then  
        imgui.TextColoredRGB('0 - {FFFFFF}�����, {FFFFFF}1 - {000000}������, {FFFFFF}2 - {008000}�������, {FFFFFF}3 - {80FF00}������-�������')
		imgui.TextColoredRGB('4 - {FF0000}�������, {FFFFFF}5 - {0000FF}�����, {FFFFFF}6 - {FDFF00}������, {FFFFFF}7 - {FF9000}���������')
		imgui.TextColoredRGB('4 - {B313E7}����������, {FFFFFF}9 - {49E789}���������, {FFFFFF}10 - {139BEC}�������')
		imgui.TextColoredRGB('11 - {2C9197}�����-�������, {FFFFFF}12 - {DDB201}�������, {FFFFFF}13 - {B8B6B6}�����, {FFFFFF}14 - {FFEE8A}������-������')
		imgui.TextColoredRGB('15 - {FF9DB6}�������, {FFFFFF}16 - {BE8A01}����������, {FFFFFF}17 - {E6284E}�����-�������')
    end
    if imgui.Button(u8"�������� �����") then  
        imgui.OpenPopup('mainFloods')
    end
    if imgui.Button(u8"���� �� GangWar") then  
        imgui.OpenPopup('FloodsGangWar')
    end 
    if imgui.Button(u8"����������� /join") then  
        imgui.OpenPopup('FloodsJoinMP')
    end
    if imgui.BeginPopup('mainFloods') then  
        if imgui.Button(u8'���� ��� �������') then
			sampSendChat("/mess 4 ===================== | ������� | ====================")
			sampSendChat("/mess 0 �������� ������ ��� ����������?")
			sampSendChat("/mess 4 ������� /report, ������ ���� ID ����������/������!")
			sampSendChat("/mess 0 ���� �������������� ������� ��� � ���������� � ����. <3")
			sampSendChat("/mess 4 ===================== | ������� | ====================")
		end
		imgui.SameLine()
		if imgui.Button(u8'���� ��� VIP') then
			sampSendChat("/mess 2 ===================== | VIP | ====================")
			sampSendChat("/mess 3 ������ ����� �������� �� ����� �����?")
			sampSendChat("/mess 2 ����� ��������� �������? ������� ��� � ������� 10� �����.")
			sampSendChat("/mess 3 ����� ������� /sellvip � �� �������� VIP!")
			sampSendChat("/mess 2 ===================== | VIP | ====================")
		end
		if imgui.Button(u8'���� ��� ������ �������/����') then
			
			sampSendChat("/mess 5 ===================== | ���� | ====================")
			sampSendChat("/mess 10 ��� ��� ������ ����� ����������. ���? -> ..")
			sampSendChat("/mess 0 ��� ����� ����������, �������� /tp, ����� ������ -> ����...")
			sampSendChat("/mess 0 ...����� ����� ������ � ����, ������� ���� �..")
			sampSendChat("/mess 10 ..� �������� �� ������ ���� ��� ������ �������. �� ���� ���.")
			sampSendChat("/mess 5 ===================== | ���� | ====================")
		end
		if imgui.Button(u8'���� ��� /dt 0-990 (����� ����������)') then
			
			sampSendChat("/mess 6 =================== | ����������� ��� | ==================")
			sampSendChat("/mess 0 ����������� �������? ��������� ��, ������ ��������..")
			sampSendChat("/mess 0 ���� ������� ���������? ��� ����� ���������! <3")
			sampSendChat("/mess 0 ������ ����� /dt 0-990. ����� - ��� ����������� ���.")
			sampSendChat("/mess 0 �� �������� �������� ������� ���� ���. ������� ����. :3")
			sampSendChat("/mess 6 =================== | ����������� ���  | ==================")
			
		end
		if imgui.Button(u8'���� ��� /storm') then
			
			sampSendChat("/mess 2 ===================== | ����� | ====================")
			sampSendChat("/mess 3 ������ ������ ���������� ����� ? � ��� ���� �����������!")
			sampSendChat("/mess 2 ����� ������� /storm , ����� ���� ��������� � NPC ... ")
			sampSendChat("/mess 3 ...������� ������������� � ������.")
			sampSendChat("/mess 2 ����� �������� ������ ���������� ������� ����� �������.")
			sampSendChat("/mess 2 ===================== | ����� | ====================")
			
		end
		if imgui.Button(u8'���� ��� /arena') then
			
			sampSendChat("/mess 7 ===================== | ����� | ====================")
			sampSendChat("/mess 0 ������ �������� ���� ������ � ��������?")
			sampSendChat("/mess 7 ������ ����� /arena, ������ ���� ���� ���.")
			sampSendChat("/mess 0 ����������� ����, ������ ��. ������, ��� ����� �������� ����. <3")
			sampSendChat("/mess 7 ===================== | ����� | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'���� ��� VK group') then
			
			sampSendChat("/mess 15 ===================== | ��������� | ====================")
			sampSendChat("/mess 0 ������ ����� ������������� � ��������?")
			sampSendChat("/mess 15 � ����� ������ ��������� �����, ��� �������� ������?")
			sampSendChat("/mess 0 ������ � ���� ������ ���������: https://vk.com/dmdriftgta")
			sampSendChat("/mess 15 ===================== | ��������� | ====================")
			
		end
		if imgui.Button(u8'���� ��� ���������') then
			
			sampSendChat("/mess 12 ===================== | ��������� | ====================")
			sampSendChat("/mess 0 � ���� ��������� �����? �� ������ ������ �����?")
			sampSendChat("/mess 12 ����� ������� /tp -> ������ -> ����������")
			sampSendChat("/mess 0 ������� ������ ���������, ���� ������ �� RDS �����. � ������� :3")
			sampSendChat("/mess 12 ===================== | ��������� | ====================")
			
		end
		if imgui.Button(u8'���� ��� ���� RDS') then
			
			sampSendChat("/mess 8 ===================== | ����� | ====================")
			sampSendChat("/mess 15 ������ ���������� �� ���� ������� ������ RDS? :> ")
			sampSendChat("/mess 15 �� ��� ������ ������� � ��������! ����: myrds.ru :3 ")
			sampSendChat("/mess 15 � ����� ����������: @empirerosso")
			sampSendChat("/mess 8 ===================== | ����� | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'���� ��� /gw') then
			
			sampSendChat("/mess 10 ===================== | Capture | ====================")
			sampSendChat("/mess 5 ���� �������� ������ �� ����� � GTA:SA? ��� ��� ���� ����! :>")
			sampSendChat("/mess 5 ������ ��� � ������� /gw, ��� �� ���������� � ��������")
			sampSendChat("/mess 5 ����� ������ ������� �� ����������, ����� ������� /capture XD")
			sampSendChat("/mess 10 ===================== | Capture | ====================")
			
		end
		if imgui.Button(u8"���� ��� ������ ������ �� RDS") then
			
			sampSendChat("/mess 2 ================== | ��������� ������ RDS | =================")
			sampSendChat("/mess 11 ����� ������ ������� ���� ������, � �������� ������?")
			sampSendChat("/mess 2 ����������� ������� ���-������, �� � ���� ����� �� ����������?")
			sampSendChat("/mess 11 �� ������ �������� ��������� ������: https://vk.com/freerds")
			sampSendChat("/mess 2 ================== | ��������� ������ RDS | =================")
			
		end
		if imgui.Button(u8"���� ��� /gangwar") then 
			
			sampSendChat("/mess 16 ===================== | �������� | ====================")
			sampSendChat("/mess 13 ������ ��������� � ������� �������? ��������� ����?")
			sampSendChat("/mess 16 �� ������ ���� ��� ���������! ������ �������� ������ �����")
			sampSendChat("/mess 13 ������� /gangwar, ��������� ���������� � ���������� �� ��.")
			sampSendChat("/mess 16 ===================== | �������� | ====================")
			
		end 
		imgui.SameLine()
		if imgui.Button(u8"���� ��� ������") then
			
			sampSendChat("/mess 14 ===================== | ������ | ====================")
			sampSendChat("/mess 13 �� ������� ����� �� ������? �� ������� �� �������?")
			sampSendChat("/mess 13 ���� ����� ������ � ���������, ��������� ������ ��� �������")
			sampSendChat("/mess 13 ������ ���� ������, �������� /tp -> ������")
			sampSendChat("/mess 14 ===================== | ������ | ====================")
			
		end
		if imgui.Button(u8"���� � ����") then  
			
			sampSendChat("/mess 13 ===================== | ��� RDS | ====================")
			sampSendChat("/mess 0 ��������� ��� � ��� RDS. ������ �����, �� Drift Server")
			sampSendChat("/mess 13 ����� � ��� ���� ����������, ��� GangWar, DM � ���������� RPG")
			sampSendChat("/mess 0 ����������� ������ � ��� ��������� ������� � /help")
			sampSendChat("/mess 13 ===================== | ��� RDS | ====================")
			
		end
		imgui.SameLine()
		if imgui.Button(u8'���� ��� /trade') then
			
			sampSendChat("/mess 9 ===================== | ����� | ====================")
			sampSendChat("/mess 3 ������ ������ ����������, � ����� ������ �� ������� � ���� �����/����/�����/�����?")
			sampSendChat("/mess 9 ������� /trade, ��������� � ������� �����, �������� � �������� � ������ �������.")
			sampSendChat("/mess 3 �����, ������ �� ����� ���� NPC �����, � ���� ����� ����� ���-�� �����.")
			sampSendChat("/mess 9 ===================== | ����� | ====================")
			
		end
		if imgui.Button(u8'���� ��� �����') then 
			
			sampSendChat("/mess 4 ===================== | ����� | ====================")
			sampSendChat('/mess 0 ���� ������ �� �������/�������? ���� �������? ������ ������ � ��������?')
			sampSendChat('/mess 4 � ��� ���� ����� - https://forumrds.ru. ��� ���� �������� ���� :D')
			sampSendChat('/mess 0 ����� �����, ��� ���� ������� � �������. ����������, ������ <3')
			sampSendChat("/mess 4 ===================== | �����  | ====================")
			
		end	
		if imgui.Button(u8'���� ��� ����� ���') then 
			
			sampSendChat("/mess 15 ===================== | ����� | ====================")
			sampSendChat('/mess 17 ������� ������! �� ������ ������� ������ �������?')
			sampSendChat('/mess 15 ���� �� �����-�� ������ ����� �������, �� ��� ��� ����!')
			sampSendChat('/mess 17 ��� �� ������ ������� ������! ������� ������: https://forumrds.ru')
			sampSendChat("/mess 15 ===================== | ����� | ====================")
			
		end
		if imgui.Button(u8'����� ����� �� 15 ������') then
			
			sampSendChat("/mess 14 ��������� ������. ������ ����� ������� ����� ���������� ����������")
			sampSendChat("/mess 14 ������� ������������ �����, � ����������� ��������, ���� ������� :3")
			sampSendChat("/delcarall ")
			sampSendChat("/spawncars 15 ")
			showNotification("������� �/� �������")
			
		end
	    if imgui.Button(u8'������') then
			
		    sampSendChat("/mess 8 =================| ������ NPC |=================")
		    sampSendChat("/mess 0 �� ������ ����� NPC ������� ���� ������? :D")
		    sampSendChat("/mess 0 � ��� ��� �� �� ����� , - ALT(/mm) - ��������� - ...")
		    sampSendChat("/mess 0 ...������� �������, ������� �����, � �� ������ ������...")
		    sampSendChat("/mess 0 ...NPC ����. �������� ���� �� RDS <3")
		    sampSendChat("/mess 8 =================| ������ NPC |=================")
			
		end	
	    imgui.EndPopup()
    end
    if imgui.BeginPopup('FloodsGangWar') then  
        if imgui.Button(u8"Aztecas vs Ballas") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 3 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs East Side Ballas ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 3 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Aztecas vs Groove") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 2 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs Groove Street ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 2 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		if imgui.Button(u8"Aztecas vs Vagos") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 4 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs Los Santos Vagos ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 4 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Aztecas vs Rifa") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 5 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Varios Los Aztecas vs The Rifa ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 5 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		if imgui.Button(u8"Ballas vs Groove") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 6 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs Groove Street  ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 6 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Ballas vs Rifa") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 7 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs The Rifa ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 7 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		if imgui.Button(u8"Groove vs Rifa") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 8 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Groove Street  vs The Rifa ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 8 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Groove vs Vagos") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 9 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Groove Street vs Los Santos Vagos ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 9 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		if imgui.Button(u8"Vagos vs Rifa") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 10 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 Los Santos Vagos vs The Rifa ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 10 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
		imgui.SameLine()
		if imgui.Button(u8"Ballas vs Vagos") then  
			
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			sampSendChat("/mess 11 ���� -  GangWar: /gw")
			sampSendChat("/mess 0 East Side Ballas vs Los Santos Vagos ")
			sampSendChat("/mess 0 �������� ����� �������, �������� ����� /gw �� ������� �����")
			sampSendChat("/mess 11 ���� - GangWar: /gw")
			sampSendChat("/mess 13 �------------------- GangWar -------------------�")
			
		end
        imgui.EndPopup()
    end
    if imgui.BeginPopup('FloodsJoinMP') then  
        if imgui.Button(u8'����������� "�����" ') then 
			
			sampSendChat("/mess 8 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������! ��������: /derby")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������! ��������: /derby")
			sampSendChat("/mess 8 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "������" ') then 
			
			sampSendChat("/mess 10 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �������! ��������: /parkour")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �������! ��������: /parkour")
			sampSendChat("/mess 10 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "PUBG" ') then 
			
			sampSendChat("/mess 9 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �PUBG�! ��������: /pubg")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �PUBG�! ��������: /pubg")
			sampSendChat("/mess 9 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "DAMAGE DM" ') then 
			
			sampSendChat("/mess 4 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �DAMAGE DEATHMATCH�! ��������: /damagedm")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �DAMAGE DEATHMATCH�! ��������: /damagedm")
			sampSendChat("/mess 4 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "KILL DM" ') then 
			
			sampSendChat("/mess 17 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �KILL DEATHMATCH�! ��������: /killdm")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �KILL DEATHMATCH�! ��������: /killdm")
			sampSendChat("/mess 17 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "����� �����" ') then 
			
			sampSendChat("/mess 7 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������ �����! ��������: /drace")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������ �����! ��������: /drace")
			sampSendChat("/mess 7 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "PaintBall" ') then 
			
			sampSendChat("/mess 12 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �PaintBall�! ��������: /paintball")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �PaintBall�! ��������: /paintball")
			sampSendChat("/mess 12 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "����� ������ �����" ') then 
			
			sampSendChat("/mess 13 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������ ������ �����! ��������: /zombie")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ������ ������ �����! ��������: /zombie")
			sampSendChat("/mess 13 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "���������� ������" ') then 
			
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ����������� ������! ��������: /ny")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ����������� ������! ��������: /ny")
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "Capture Blocks" ') then 
			
			sampSendChat("/mess 16 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �Capture Blocks�! ��������: /join -> 12")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �Capture Blocks�! ��������: /join -> 12")
			sampSendChat("/mess 16 ===================| [Event-Game-RDS] |==================")
			
		end	
		if imgui.Button(u8'����������� "������" ') then 
			sampSendChat("/mess 11 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �������! ��������: /join -> 10 �������")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� �������! ��������: /join -> 10 �������")
			sampSendChat("/mess 11 ===================| [Event-Game-RDS] |==================")
		end	
		if imgui.Button(u8'����������� "���������" ') then 
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ����������! ��������: /catchup")
			sampSendChat("/mess 0 [MP-/join] ���������� ����������� ����������! ��������: /catchup")
			sampSendChat("/mess 3 ===================| [Event-Game-RDS] |==================")
		end
        imgui.EndPopup()
    end
end
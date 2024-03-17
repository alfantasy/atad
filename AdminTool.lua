require 'lib.moonloader'

local dlstatus = require('moonloader').download_status
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
-- ## ��������������� ������ AT. ����������, ������ � ����������. ## --

-- ## ������� ������� � ���������� VARIABLE ## --
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
        recon = new.bool(config.settings.custom_recon),
		autologin = new.bool(config.settings.autologin),
    },
	buffers = {
		password = new.char[50](config.settings.password_to_login),
	},
}

local show_password = false -- ��������/������ ������ � ����������
local control_spawn = false -- �������� ������. ������������ ��� ������� �������
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
    imgui.GetIO().IniFilename = nil
    fa.Init(20)
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

function main()

    if toast_ok then 
        toast.Show(u8"AdminTool ���������������.\n��� ������ � �����������, �������: /tool", toast.TYPE.INFO, 5)
    else 
        sampAddChatMessage(tag .. 'AdminTool ������� ���������������. ���������: /tool', -1)
        print(tag .. "����� � ��������� �����������")
    end

	local response_update_check = downloadFile(urls['upat'], paths['upat'])
	if response_update_check then 
		updateIni = inicfg.load(nil, paths['upat'])
		if tonumber(updateIni.info.version) > version_control then  
			if toast_ok then  
				toast.Show(u8'�������� ����������.\nAT �������� ���������� �������������.', toast.TYPE.INFO, 5)
			else 
				print(tag .. '����� � ��������� �����������.')
				sampAddChatMessage(tag .. '�������� ����������. AT �������� ��������������!')
			end 
			local response_main = downloadFile(urls['main'], paths['main'])
			if response_main then  
				sampAddChatMessage(tag .. '�������� ������ �� ������.')
			end  
			local response_lib = downloadFile(urls['libsfor'], paths['libsfor'])
			if response_lib then  
				sampAddChatMessage(tag .. '���������� � �� ������� �������.')
			end  
			local response_questans = downloadFile(urls['report'], paths['report'])
			if response_questans then  
				sampAddChatMessage(tag .. '������ ��� �������� ������.')
			end  
			sampAddChatMessage(tag .. '������� ������������ ��������!')
			reloadScripts()
		else 
			if toast_ok then  
				toast.Show(u8'� ��� ����������� ���������� ������ ��.\n������ AT: ' .. version_text, toast.TYPE.INFO, 5)
			else 
				print(tag .. '����� � ��������� �����������.')
				sampAddChatMessage(tag .. '� ��� ����������� ���������� ������ ��. ������ ��: ' .. version_text, -1)
			end
		end  
		os.remove(paths['upat'])
	end

    load_recon = lua_thread.create_suspended(loadRecon)

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
    -- ## ����������� ��������������� ������ ## --    

	sampRegisterChatCommand('checksh', function()
		sampAddChatMessage(tag .. "������� ����������: X - " .. sw .. " | Y - " .. sh, -1)
		sampAddChatMessage(tag .. "������ ������� ������������� ��� debug ���������� ���� ����.����������", -1)
	end)

    sampRegisterChatCommand("tool", function()
        elements.imgui.main_window[0] = not elements.imgui.main_window[0]
        elements.imgui.menu_selectable = 0
    end)

	-- ## �������������� �������� ## --
	    -- ## ���� �������� �� ���������� ������ ������ � ������� ����� ## --

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
	elseif arg:find('(.+)') then
        sampSendChat("/mute " .. arg .. " 120 " .. " ����/���� ")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /fd [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end


function cmd_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
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
	elseif arg:find('(.+)') then
        sampSendChat("/mute " .. arg .. " 120 " .. " ���������������� ")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /po [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_zs(arg)
	if #arg > 0 then 
		sampSendChat("/mute " .. arg .. " 600 " .. " �����.��������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_m(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 300 " .. " ����������� �������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ia(arg)
	if #arg > 0 then
		sampSendChat("/mute " ..  arg .. " 2500 " .. " ������ ���� �� ������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_kl(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 3000 " .. " ������� �� ������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_oa(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 2500 " .. " ���/����.�������������  ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ok(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 400 " .. " �����������/��������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm2(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 2500 " .. " ������������ ��������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm3(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " ..  " ������������ ��������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_or(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " .. " �����������/���������� ������ ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nm1(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 900 " .. " ������������ ��������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_up(arg)
	lua_thread.create(function()
		if #arg > 0 then
			sampSendChat("/mute " .. arg .. " 1000 " .. " ���������� ��������� �������� ")
			wait(1000)
			sampSendChat("/cc ")
			sampAddChatMessage(tag .. "������� ���� ����� � ������� ����.")
		else 
			sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
		end
	end)
end

function cmd_rz(arg)
	if #arg > 0 then
		sampSendChat("/mute " .. arg .. " 5000 " .. " ������ ������. �����")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end	

-- ## ���� ������� � ������ ������-��������� ���� ## --
function cmd_rup(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 1000 " .. " ���������� ��������� ��������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ror(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 5000 " .. " �����������/���������� ������ ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
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
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /cp [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_report_popr(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
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
	elseif arg:find('(.+)') then
        sampSendChat("/rmute " .. arg .. " 120 " .. " ���������������� ")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /rpo [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_rm(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 300 " .. " ����������� �������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_roa(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 2500 " .. " ���/����.�������������  ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_report_neadekvat(arg)
    if arg:find('(.+) (.+)') then
        arg1, arg2 = arg:match('(.+) (.+)')
        if arg2 == '2' then
		    sampSendChat("/rmute " .. arg1 .. " 1800 " .. " ������������ ��������� x2")
        elseif arg2 == '3' then  
            sampSendChat("/rmute " .. arg1 .. " 3000 " .. " ������������ ��������� x3")
        elseif arg2 == '1' then  
            sampSendChat("/rmute " .. arg1 .. " 900 " .. " ������������ ���������")
        end
	elseif arg:find('(.+)') then
        sampSendChat("/rmute " .. arg .. " 900 " .. " ������������ ���������")
    else
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /rnm [IDPlayer] [~��������� (�� 2-3)]", -1)
	end
end

function cmd_rok(arg)
	if #arg > 0 then
		sampSendChat("/rmute " .. arg .. " 400 " .. " �����������/��������. ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_rrz(arg)
	if #arg > 0 then 
		sampSendChat("/rmute " .. arg .. " 5000 " .. " ������ ������. �����")
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
		sampSendChat("/jail " .. arg .. " 300 " .. " Spawn Kill")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
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
        sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
        sampAddChatMessage(tag .. " �����������: /dz [IDPlayer] [~��������� (�� 2 �� 10)]", -1)
	end
end

function cmd_td(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " DB/car in trade ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jm(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " ��������� ������ �� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_pmx(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " ��������� ������ ������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_skw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " SK in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_dgw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 500 " .. " ������������� ���������� in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ngw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " ������������� ����������� ������ in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_dbgw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 600 " .. " ������������� ��������� in /gw ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_fsh(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " ������������� SpeedHack/FlyCar ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_bag(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 300 " .. " ������� ������ (deagle in car)")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_pk(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ������ ���� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jch(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 3000 " .. " ������������� ���������� �������/�� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_zv(arg)
	if #arg > 0 then
		sampSendChat("/jail " ..  arg .. " 3000 " .. " ��������������� VIP`om ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_sch(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ����������� �������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_jcw(arg)
	if #arg > 0 then
		sampSendChat("/jail " .. arg .. " 900 " .. " ������������� ClickWarp/Metla (���)")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_tdbz(arg)
	if #arg > 0 then  
		sampSendChat("/jail " .. arg .. " 900 " .. " �� � ������ (zz)")
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
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 3 " .. " �����������/��������/��� � �������")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)	
	end
end

function cmd_pl(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " ������� ���� �������������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ob(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " ����� �������� ���� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end 	

function cmd_gcnk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " �����, ���������� ����������� ������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_menk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " ���, ����������� ����������� ����� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_ch(arg)
	if #arg > 0 then
		lua_thread.create(function()
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " ������������� ���������� �������/��. ")
		end)
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_nk(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/ban " .. arg .. " 7 " .. " ���, ���������� ����������� ������� ")
	else 
		sampAddChatMessage(tag .. "�� ������ ������ ID ����������! ", -1)
	end
end

function cmd_bnm(arg)
	if #arg > 0 then
		sampSendChat("/ans " .. arg .. " ��������� �����, �� �������� ������� �������, � ���� ��..")
		sampSendChat("/ans " .. arg .. " ..�� �������� � ����������, �������� ������ �� ����� https://forumrds.ru")
		sampSendChat("/iban " .. arg .. " 7 " .. " ������������ ���������")
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

-- ## ���� ������� ��� ������� SA:MP ## --
function sampev.onServerMessage(color, text)
	local check_string = string.match(text, "[^%s]+")

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

	local check_nick, check_id, basic_color, check_text = string.match(text, "(.+)%((.+)%): {(.+)}(.+)") -- ������ �������� ������� ���� � �������� � �� �������

    -- ## �������, ��� mainframe - ������� ## --
    if not isGamePaused() and not isPauseMenuActive() then  
        if text:find("������ (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") then  
            local number_report, nick_rep, id_rep, text_rep = text:match("������ (.+) | {AFAFAF}(.+)%[(%d+)%]: (.+)") 
            sampAddChatMessage(tag .. "������ ������ " .. number_report .. " �� " .. nick_rep .. "[" .. id_rep .. "]: " .. text_rep, -1)
            if elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_rod[0] or elements.settings.automute_rod[0] then  
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
        if check_text ~= nil and check_id ~= nil and (elements.settings.automute_mat[0] or elements.settings.automute_osk[0] or elements.settings.automute_upom[0] or elements.settings.automute_rod[0]) then  
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
        imgui.SetNextWindowSize(imgui.ImVec2(1000, 600), imgui.Cond.FirstUseEver)

        imgui.Begin(fa.SERVER .. " [AT for Android]", elements.imgui.main_window, imgui.WindowFlags.NoResize) 
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
						imgui.Text(u8"��������� �����-����")
						imgui.SameLine()
						if mim_addons.ToggleButton("##CustomReconMenu", elements.boolean.recon) then  
							config.settings.custom_recon = elements.boolean.recon[0]
							save() 
						end
						ActiveAutoMute()
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
				if imgui.BeginTabItem(fa.LIST .. u8" ������ /ans") then   
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
	imgui.Text(u8"���� ����������� ������ ������ � ���� ������.\n��� ������ �����, ������� �� ������.")
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
            imgui.Text(u8"������������ ����� ���������. \n������ ���� ��������� ����� ����� ������������� \n� ����� ��� ����������.")
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
local ffi = require "ffi" -- работа с структурой памяти игры.
local gta = ffi.load('GTASA') -- загрузка основной библиотеки GTAS
local imgui = require 'mimgui' -- инициализация интерфейса Moon ImGUI
local sampev = require 'lib.samp.events' -- работа с событиями
local encoding = require 'encoding' -- работа с кодировками
local inicfg = require 'inicfg' -- работа с конфигом
local mim_addons = require 'mimgui_addons' -- интеграция аддонов для интерфейса mimgui
local memory = require 'memory' -- работа с памятью напрямую
local atlibs = require 'libsfor' -- инициализация библиотеки InfoSecurity для AT (libsfor)

encoding.default = 'CP1251' -- смена кодировки на CP1251
u8 = encoding.UTF8 -- объявление кодировки U8 как рабочую, но в форме переменной (для интерфейса)

function isMonetLoader() return MONET_VERSION ~= nil end -- проверка наличия MonetLoader

-- ## Блок текстовых переменных ## --
local tag = "{00BFFF} [AT] {FFFFFF}" -- локальная переменная, которая регистрирует тэг AT
-- ## Блок текстовых переменных ## --

EXPORTS = {}

local new = imgui.new 

local config_locate = 'AdminTool/other.ini'

local testBullets = {
    ['my']    = { clock = os.clock(), alpha = 0 },
    ['other'] = { clock = os.clock(), alpha = 0 },
}

local bullets = {
    {
        clock = 0,
        timer = 0,
        col4 = { [0]=0,[1]=0,[2]=0,[3]=0 },
        alpha = 0,
        origin = { x = 0, y = 0, z = 0 },
        target = { x = 0, y = 0, z = 0 },
        transition = 0,
        thickness = 0,
        circle_radius = 0,
        step_alpha = 1,
        degree_polygon = 0,
        draw_polygon = false,
    }
}

local config = inicfg.load({
    main = {
        wallhack = false, 
    },
    settings = {
        enabled_bullets_in_screen = true,
        warning_new_tracer = true,
    },
    radius_render_in_stream = {
        is_active = false,
        distance = 20,
    },
    warning_wallshot = {
        obj = true,
        veh = true,
        build = true
    },
    my_bullets = {
        draw = true,
        draw_polygon = true,
        thickness = 1.4,
        timer = 3,
        step_alpha = 0.01,
        circle_radius = 4,
        degree_polygon = 15,
        transition = 0.2,
    },
    my_bullets_col_vec4_stats = { 0.8, 0.8, 0.8, 0.7 },
    my_bullets_col_vec4_ped = { 1.0, 0.4, 0.4, 0.7 },
    my_bullets_col_vec4_car = { 0.8, 0.8, 0.0, 0.7 },
    my_bullets_col_vec4_dynam = { 0.0, 0.8, 0.8, 0.7 },
    my_bullets_col_vec4_test = { 0.8, 0.8, 0.8, 0.7 },
    my_bullets_col_vec4_unknown = { 1.0, 0.0, 1.0, 1.0 },
    other_bullets = {
        draw = true,
        draw_polygon = true,
        thickness = 1.4,
        timer = 3,
        step_alpha = 0.01,
        circle_radius = 4,
        degree_polygon = 15,
        transition = 0.2,
    },
    other_bullets_col_vec4_stats = { 0.8, 0.8, 0.8, 0.7 },
    other_bullets_col_vec4_ped = { 1.0, 0.4, 0.4, 0.7 },
    other_bullets_col_vec4_car = { 0.8, 0.8, 0.0, 0.7 },
    other_bullets_col_vec4_dynam = { 0.0, 0.8, 0.8, 0.7 },
    other_bullets_col_vec4_warn_obj = { 0.6, 0.4, 0.9, 0.9 },
    other_bullets_col_vec4_warn_veh = { 0.6, 0.4, 0.9, 0.9 },
    other_bullets_col_vec4_warn_build = { 0.6, 0.4, 0.9, 0.9 },
    other_bullets_col_vec4_test = { 0.8, 0.8, 0.8, 0.7 },
    other_bullets_col_vec4_unknown = { 1.0, 0.0, 1.0, 1.0 },
    default = {
        version = 3,
    }
}, config_locate)
inicfg.save(config, config_locate)

local ig = {
    version = new.int(config.default.version),
    settings = {
        enabled_bullets_in_screen = new.bool(config.settings.enabled_bullets_in_screen),
        warning_new_tracer = new.bool(config.settings.warning_new_tracer),
        radius_render_in_stream = {
            is_active = new.bool(config.radius_render_in_stream.is_active),
            distance = new.int(config.radius_render_in_stream.distance),
        },
        warning_wallshot = {
            obj = new.bool(config.warning_wallshot.obj),
            veh = new.bool(config.warning_wallshot.veh),
            build = new.bool(config.warning_wallshot.build),
        }
    },
    my_bullets = {
        draw = new.bool(config.my_bullets.draw),
        draw_polygon = new.bool(config.my_bullets.draw_polygon),
        thickness = new.float(config.my_bullets.thickness),
        timer = new.float(config.my_bullets.timer),
        step_alpha = new.float(config.my_bullets.step_alpha),
        circle_radius = new.float(config.my_bullets.circle_radius),
        degree_polygon = new.int(config.my_bullets.degree_polygon),
        transition = new.float(config.my_bullets.transition),
        col_vec4 = {
            stats = new.float[4](config.my_bullets_col_vec4_stats),
            ped = new.float[4](config.my_bullets_col_vec4_ped),
            car = new.float[4](config.my_bullets_col_vec4_car),
            dynam = new.float[4](config.my_bullets_col_vec4_dynam),
            test = new.float[4](config.my_bullets_col_vec4_test),
            unknown = new.float[4](config.my_bullets_col_vec4_unknown),
        }
    },
    other_bullets = {
        draw = new.bool(config.other_bullets.draw),
        draw_polygon = new.bool(config.other_bullets.draw_polygon),
        thickness = new.float(config.other_bullets.thickness),
        timer = new.float(config.other_bullets.timer),
        step_alpha = new.float(config.other_bullets.step_alpha),
        circle_radius = new.float(config.other_bullets.circle_radius),
        degree_polygon = new.int(config.other_bullets.degree_polygon),
        transition = new.float(config.other_bullets.transition),
        col_vec4 = {
            stats = new.float[4](config.other_bullets_col_vec4_stats),
            ped = new.float[4](config.other_bullets_col_vec4_ped),
            car = new.float[4](config.other_bullets_col_vec4_car),
            dynam = new.float[4](config.other_bullets_col_vec4_dynam),
            warn_obj = new.float[4](config.other_bullets_col_vec4_warn_obj),
            warn_veh = new.float[4](config.other_bullets_col_vec4_warn_veh),
            warn_build = new.float[4](config.other_bullets_col_vec4_warn_build),
            test = new.float[4](config.other_bullets_col_vec4_test),
            unknown = new.float[4](config.other_bullets_col_vec4_unknown),
        }
    }
}

local function bringFloatTo(from, dest, start_time, duration)
    local timer = os.clock() - start_time
    if timer >= 0 and timer <= duration then
      local count = timer / (duration / 100)
      return from + (count * (dest - from) / 100)
    end
    return (timer > duration) and dest or from
end

local function getFixScreenPos(pos1, pos2, distance)
    distance = math.abs(distance)
    local direct = { x = pos2.x - pos1.x, y = pos2.y - pos1.y, z = pos2.z - pos1.z }
    local length = math.sqrt(direct.x * direct.x + direct.y * direct.y + direct.z * direct.z)
    direct = { x = direct.x / length, y = direct.y / length, z = direct.z / length }
    local newPos = { x = pos1.x + direct.x * distance, y = pos1.y + direct.y * distance, z = pos1.z + direct.z * distance }
    return newPos
end
  
local function getDistancePosition(plPos, distance)
    if not ig.settings.radius_render_in_stream.is_active[0] then return true end
  
    local myPos = { getCharCoordinates(PLAYER_PED) }
    local dist_ped = getDistanceBetweenCoords3d(plPos.x, plPos.y, plPos.z, myPos[1], myPos[2], myPos[3])
  
    if dist_ped <= distance then
        return true
    else
        return false
    end
end

local function getColorTargetType(target, ig)
    if     target == 0 then return ig.col_vec4.stats
    elseif target == 1 then return ig.col_vec4.ped
    elseif target == 2 then return ig.col_vec4.car
    elseif target == 3 then return ig.col_vec4.dynam
    elseif target == 4 then return ig.col_vec4.dynam 
    else
      if ig.settings.warning_new_tracer[0] then
        chat.log('Появился новый нераспознованный трейсер %d. Сообщите разработчику @alfantasy в VK', target)
      end
      return ig.col_vec4.unknown
    end
end

local function drawTestBullet(DL, tip, ig)  
    local p = imgui.GetCursorScreenPos()
    local indent = 11
    local size = {
        min = {
            x = p.x + indent - 2,
            y = p.y + indent
        },
        max = {
            x = p.x + imgui.GetWindowContentRegionWidth() - indent + 2,
            y = p.y + indent
        }
    }

    if testBullets[tip].alpha <= 0 then  
        testBullets[tip].clock = os.clock()
        testBullets[tip].alpha = ig.col_vec4.test[3]
    end

    testBullets[tip] = {
        clock = testBullets[tip].clock,
        timer = ig.timer[0],
        col4 = ig.col_vec4.test,
        alpha = testBullets[tip].alpha,
        origin = {x = size.min.x, y = size.min.y},
        target = {x = size.max.x, y = size.max.y},
        transition = ig.transition[0],
        thickness = ig.thickness[0],
        circle_radius = ig.circle_radius[0],
        step_alpha = ig.step_alpha[0],
        degree_polygon = ig.degree_polygon[0],
        draw_polygon = ig.draw_polygon[0],
    }

    local target_offset = {
        x = bringFloatTo(testBullets[tip].origin.x, testBullets[tip].target.x, testBullets[tip].clock, testBullets[tip].transition),
        y = bringFloatTo(testBullets[tip].origin.y, testBullets[tip].target.y, testBullets[tip].clock, testBullets[tip].transition)
    }

    local oX, oY = testBullets[tip].origin.x, testBullets[tip].origin.y
    local tX, tY = target_offset.x, target_offset.y

    local col4u32 = imgui.ImVec4(testBullets[tip].col4[0], testBullets[tip].col4[1], testBullets[tip].col4[2], testBullets[tip].alpha)

    if ig.draw[0] then
        DL:AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(tX, tY), imgui.GetColorU32Vec4(col4u32), testBullets[tip].thickness)
        if ig.draw_polygon[0] then
            DL:AddCircleFilled(imgui.ImVec2(tX, tY), testBullets[tip].circle_radius, imgui.GetColorU32Vec4(col4u32), testBullets[tip].degree_polygon)
        end
    end

    if (os.clock() - testBullets[tip].clock > ig.timer[0]) and (testBullets[tip].alpha > 0) then
        testBullets[tip].alpha = testBullets[tip].alpha - testBullets[tip].step_alpha
    end
end

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end  

local elements = {
    wallhack = new.bool(config.main.wallhack),
}

function save() 
    inicfg.save(config, config_locate)
    return true
end

ffi.cdef[[
  typedef struct RwV3d {
    float x, y, z;
  } RwV3d;
  // void CPed::GetBonePosition(CPed *this, RwV3d *posn, uint32 bone, bool calledFromCam) - Mangled name
  void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz, RwV3d* posn, uint32_t bone, bool calledFromCam);
]]

function getBonePosition(ped, bone)
    local pedptr = ffi.cast('void*', getCharPointer(ped))
    local posn = ffi.new('RwV3d[1]')
    gta._ZN4CPed15GetBonePositionER5RwV3djb(pedptr, posn, bone, false)
    return posn[0].x, posn[0].y, posn[0].z
end

local bones = { 3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2 }
local sw, sh = getScreenResolution()
local font = renderCreateFont("Arial", 12, 1 + 4) -- P.S. in MonetLoader only Arial Bold is available (every font is defaulted to it)

function main()
    while not isSampAvailable() do wait(0) end

    sampAddChatMessage(tag .. 'Скрипт с дополнительными функциями инициализирован.', -1)

    while true do
        wait(0)
        
        if elements.wallhack[0] then
            for _, char in ipairs(getAllChars()) do
                local result, id = sampGetPlayerIdByCharHandle(char)
                if result and isCharOnScreen(char) then
                    local opaque_color = bit.bor(bit.band(sampGetPlayerColor(id), 0xFFFFFF), 0xFF000000)
                    for _, bone in ipairs(bones) do
                        local x1, y1, z1 = getBonePosition(char, bone)
                        local x2, y2, z2 = getBonePosition(char, bone + 1)
                        local r1, sx1, sy1 = convert3DCoordsToScreenEx(x1, y1, z1)
                        local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
                        if r1 and r2 then
                        renderDrawLine(sx1, sy1, sx2, sy2, 3, opaque_color)
                        end
                    end
        
                    local x1, y1, z1 = getBonePosition(char, 2)
                    local r1, sx1, sy1 = convert3DCoordsToScreenEx(x1, y1, z1)
                    if r1 then
                        local x2, y2, z2 = getBonePosition(char, 41)
                        local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
                        if r2 then
                            renderDrawLine(sx1, sy1, sx2, sy2, 3, opaque_color)
                        end
                    end
                    if r1 then
                        local x2, y2, z2 = getBonePosition(char, 51)
                        local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
                        if r2 then
                            renderDrawLine(sx1, sy1, sx2, sy2, 3, opaque_color)
                        end
                    end

                    local hx, hy, hz = getBonePosition(char, 5)
                    local hr, headx, heady = convert3DCoordsToScreenEx(hx, hy, hz + 0.25)
                    if hr then
                        local nickname = sampGetPlayerNickname(id)
                        local nametag = nickname .. ' [' .. tostring(id) .. '] - {FF0000}' .. string.format("%.0f", sampGetPlayerHealth(id)) .. 'hp {BBBBBB}' .. string.format("%.0f", sampGetPlayerArmor(id)) .. 'ap'
                        local nametag_len = renderGetFontDrawTextLength(font, nametag)
                        local nametag_x = headx - nametag_len / 2
                        local nametag_y = heady - renderGetFontDrawHeight(font)
                        renderFontDrawText(font, nametag, nametag_x, nametag_y, opaque_color)
                    end
                end
            end
        end
    end
end

function EXPORTS.ActivateWH()
    imgui.Text('WallHack')
    imgui.SameLine()
    if mim_addons.ToggleButton('##WallHack', elements.wallhack) then
        config.main.wallhack = elements.wallhack[0]
        save() 
    end 
end

function EXPORTS.ActivateBulletTrack()
    local sizeX = imgui.GetWindowContentRegionWidth() - imgui.GetStyle().WindowPadding.x - imgui.GetStyle().ItemSpacing.x
    local sl = imgui.SameLine
    local sniw = imgui.SetNextItemWidth
    local DL = imgui.GetWindowDrawList()
    local indentWidth = 130

    do
        if imgui.TreeNodeStr(u8'Настройка своих пуль') then
            imgui.Separator()
            imgui.BeginGroup()
                sniw(indentWidth); imgui.DragFloat(u8'Время задержки трейсера##mySettings',        ig.my_bullets.timer,          0.01,  0.01,  10,  u8'%.2f сек')
                sniw(indentWidth); imgui.DragFloat(u8'Время появление до попадании##mySettings',   ig.my_bullets.transition,     0.01,  0,     2,   u8'%.2f сек')
                sniw(indentWidth); imgui.DragFloat(u8'Шаг исчезнование##mySettings',               ig.my_bullets.step_alpha,     0.001, 0.001, 0.5, u8'%.3f шаг')
                sniw(indentWidth); imgui.DragFloat(u8'Толщина линий##mySettings',                  ig.my_bullets.thickness,      0.1,   1,     10,  u8'%.2f мм')
                sniw(indentWidth); imgui.DragFloat(u8'Размер окончания трейсера##mySettings',      ig.my_bullets.circle_radius,  0.2,   0,     15,  u8'%.2f радиус')
                sniw(indentWidth); imgui.DragInt(  u8'Количество углов на окончаниях##mySettings', ig.my_bullets.degree_polygon, 0.2,   3,     40,  u8'%d угол')
            imgui.EndGroup(); sl(_, 20);
            imgui.BeginGroup()
                imgui.Checkbox(u8'Отрисовка своих пуль', ig.my_bullets.draw)
                imgui.Checkbox(u8'Окончания у линий', ig.my_bullets.draw_polygon)
                imgui.ColorEdit4('##mySettings__Player', ig.my_bullets.col_vec4.ped,   imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Игрок')
                imgui.ColorEdit4('##mySettings__Car',    ig.my_bullets.col_vec4.car,   imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Машина')
                imgui.ColorEdit4('##mySettings__Stats',  ig.my_bullets.col_vec4.stats, imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Статический объект')
                imgui.ColorEdit4('##mySettings__Dynam',  ig.my_bullets.col_vec4.dynam, imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Динамический объект')
                imgui.ColorEdit4('##mySettings__Test',   ig.my_bullets.col_vec4.test,  imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Тестовый трейсер')
            imgui.EndGroup()
            imgui.Separator()
            imgui.Text(' ')
            drawTestBullet(DL, 'my', ig.my_bullets)
            imgui.Text(' ')
            imgui.Separator()
            imgui.TreePop()
        end
        if imgui.TreeNodeStr(u8'Настройка чужих пуль') then
            imgui.Separator()
            imgui.BeginGroup()
                sniw(indentWidth); imgui.DragFloat(u8'Время задержки трейсера##otherSettings',        ig.other_bullets.timer,          0.01,  0.01,  10,  u8'%.2f сек')
                sniw(indentWidth); imgui.DragFloat(u8'Время появление до попадании##otherSettings',   ig.other_bullets.transition,     0.01,  0,     2,   u8'%.2f сек')
                sniw(indentWidth); imgui.DragFloat(u8'Шаг исчезнование##otherSettings',               ig.other_bullets.step_alpha,     0.001, 0.001, 0.5, u8'%.3f шаг')
                sniw(indentWidth); imgui.DragFloat(u8'Толщина линий##otherSettings',                  ig.other_bullets.thickness,      0.1,   1,     10,  u8'%.2f мм')
                sniw(indentWidth); imgui.DragFloat(u8'Размер окончания трейсера##otherSettings',      ig.other_bullets.circle_radius,  0.2,   0,     15,  u8'%.2f радиус')
                sniw(indentWidth); imgui.DragInt(  u8'Количество углов на окончаниях##otherSettings', ig.other_bullets.degree_polygon, 0.2,   3,     40,  u8'%d угол')
            imgui.EndGroup(); sl(_, 20);
            imgui.BeginGroup()
                imgui.Checkbox(u8'Отрисовку чужих пуль',    ig.other_bullets.draw)
                imgui.Checkbox(u8'Окончания у линий',       ig.other_bullets.draw_polygon)
                imgui.ColorEdit4('##otherSettings__Player', ig.other_bullets.col_vec4.ped,   imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Игрок')
                imgui.ColorEdit4('##otherSettings__Car',    ig.other_bullets.col_vec4.car,   imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Машина')
                imgui.ColorEdit4('##otherSettings__Stats',  ig.other_bullets.col_vec4.stats, imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Статический объект')
                imgui.ColorEdit4('##otherSettings__Dynam',  ig.other_bullets.col_vec4.dynam, imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Динамический объект')
                imgui.ColorEdit4('##otherSettings__Test',   ig.other_bullets.col_vec4.test,  imgui.ColorEditFlags.NoInputs); sl(); imgui.Text(u8'Тестовый трейсер')
            imgui.EndGroup()
            imgui.Separator()
            imgui.Text(' ')
                drawTestBullet(DL, 'other', ig.other_bullets)
            imgui.Text(' ')
            imgui.Separator()
            imgui.TreePop()
        end
        if imgui.TreeNodeStr(u8'Глобальные настройки') then
            imgui.Checkbox(u8'Проходить трейсер пули сквозь экран (нестабильно)', ig.settings.enabled_bullets_in_screen)
            imgui.Checkbox(u8'Сообщить в чате, если трейсер не распознан', ig.settings.warning_new_tracer)
            imgui.Checkbox(u8'Ограничить радиус', ig.settings.radius_render_in_stream.is_active)
            if ig.settings.radius_render_in_stream.is_active[0] then
                sl(); sniw(100); imgui.DragInt('##globalSettings__RadiusRender', ig.settings.radius_render_in_stream.distance, 0.1, 5, 300, u8'%d метров')
            end
            imgui.TreePop()
        end
        imgui.NewLine()   
        if imgui.Button(u8'Сохранить', imgui.ImVec2(sizeX/3, 0)) then  
            config.settings.enabled_bullets_in_screen = ig.settings.enabled_bullets_in_screen[0]
            config.settings.warning_new_tracer = ig.settings.warning_new_tracer[0]
            config.radius_render_in_stream.is_active = ig.settings.radius_render_in_stream.is_active[0]
            config.radius_render_in_stream.distance = ig.settings.radius_render_in_stream.distance[0]
            config.warning_wallshot.obj = ig.settings.warning_wallshot.obj[0]
            config.warning_wallshot.veh = ig.settings.warning_wallshot.veh[0]
            config.warning_wallshot.build = ig.settings.warning_wallshot.build[0]
            config.my_bullets.draw = ig.my_bullets.draw[0]
            config.my_bullets.draw_polygon = ig.my_bullets.draw_polygon[0]
            config.my_bullets.thickness = ig.my_bullets.thickness[0]
            config.my_bullets.timer = ig.my_bullets.timer[0]
            config.my_bullets.step_alpha = ig.my_bullets.step_alpha[0]
            config.my_bullets.circle_radius = ig.my_bullets.circle_radius[0]
            config.my_bullets.degree_polygon = ig.my_bullets.degree_polygon[0]
            config.my_bullets.transition = ig.my_bullets.transition[0]
            config.my_bullets_col_vec4_stats = { ig.my_bullets.col_vec4.stats[0], ig.my_bullets.col_vec4.stats[1], ig.my_bullets.col_vec4.stats[2], ig.my_bullets.col_vec4.stats[3] }
            config.my_bullets_col_vec4_ped = { ig.my_bullets.col_vec4.ped[0], ig.my_bullets.col_vec4.ped[1], ig.my_bullets.col_vec4.ped[2], ig.my_bullets.col_vec4.ped[3] }
            config.my_bullets_col_vec4_car = { ig.my_bullets.col_vec4.car[0], ig.my_bullets.col_vec4.car[1], ig.my_bullets.col_vec4.car[2], ig.my_bullets.col_vec4.car[3] }
            config.my_bullets_col_vec4_dynam = { ig.my_bullets.col_vec4.dynam[0], ig.my_bullets.col_vec4.dynam[1], ig.my_bullets.col_vec4.dynam[2], ig.my_bullets.col_vec4.dynam[3] }
            config.my_bullets_col_vec4_test = { ig.my_bullets.col_vec4.test[0], ig.my_bullets.col_vec4.test[1], ig.my_bullets.col_vec4.test[2], ig.my_bullets.col_vec4.test[3] }
            config.my_bullets_col_vec4_unknown = { ig.my_bullets.col_vec4.unknown[0], ig.my_bullets.col_vec4.unknown[1], ig.my_bullets.col_vec4.unknown[2], ig.my_bullets.col_vec4.unknown[3] }
            config.other_bullets.draw = ig.other_bullets.draw[0]
            config.other_bullets.draw_polygon = ig.other_bullets.draw_polygon[0]
            config.other_bullets.thickness = ig.other_bullets.thickness[0]
            config.other_bullets.timer = ig.other_bullets.timer[0]
            config.other_bullets.step_alpha = ig.other_bullets.step_alpha[0]
            config.other_bullets.circle_radius = ig.other_bullets.circle_radius[0]
            config.other_bullets.degree_polygon = ig.other_bullets.degree_polygon[0]
            config.other_bullets.transition = ig.other_bullets.transition[0]
            config.other_bullets_col_vec4_stats = { ig.other_bullets.col_vec4.stats[0], ig.other_bullets.col_vec4.stats[1], ig.other_bullets.col_vec4.stats[2], ig.other_bullets.col_vec4.stats[3] }
            config.other_bullets_col_vec4_ped = { ig.other_bullets.col_vec4.ped[0], ig.other_bullets.col_vec4.ped[1], ig.other_bullets.col_vec4.ped[2], ig.other_bullets.col_vec4.ped[3] }
            config.other_bullets_col_vec4_car = { ig.other_bullets.col_vec4.car[0], ig.other_bullets.col_vec4.car[1], ig.other_bullets.col_vec4.car[2], ig.other_bullets.col_vec4.car[3] }
            config.other_bullets_col_vec4_dynam = { ig.other_bullets.col_vec4.dynam[0], ig.other_bullets.col_vec4.dynam[1], ig.other_bullets.col_vec4.dynam[2], ig.other_bullets.col_vec4.dynam[3] }
            config.other_bullets_col_vec4_test = { ig.other_bullets.col_vec4.test[0], ig.other_bullets.col_vec4.test[1], ig.other_bullets.col_vec4.test[2], ig.other_bullets.col_vec4.test[3] }
            config.other_bullets_col_vec4_warn_obj = { ig.other_bullets.col_vec4.warn_obj[0], ig.other_bullets.col_vec4.warn_obj[1], ig.other_bullets.col_vec4.warn_obj[2], ig.other_bullets.col_vec4.warn_obj[3] }
            config.other_bullets_col_vec4_warn_veh = { ig.other_bullets.col_vec4.warn_veh[0], ig.other_bullets.col_vec4.warn_veh[1], ig.other_bullets.col_vec4.warn_veh[2], ig.other_bullets.col_vec4.warn_veh[3] }
            config.other_bullets_col_vec4_warn_build = { ig.other_bullets.col_vec4.warn_build[0], ig.other_bullets.col_vec4.warn_build[1], ig.other_bullets.col_vec4.warn_build[2], ig.other_bullets.col_vec4.warn_build[3] }
            config.other_bullets_col_vec4_unknown = { ig.other_bullets.col_vec4.unknown[0], ig.other_bullets.col_vec4.unknown[1], ig.other_bullets.col_vec4.unknown[2], ig.other_bullets.col_vec4.unknown[3] }
            sampAddChatMessage(tag .. 'Настройки сохранены.', -1)
            inicfg.save(config, directIni)
        end; sl();    
    end                    
end

local frameDrawList = imgui.OnFrame(function() return #bullets ~= 0 and not isPauseMenuActive() end, function()
    local DL = imgui.GetBackgroundDrawList()
  
    for i=#bullets, 1, -1 do
      local target_offset = {
        x = bringFloatTo(bullets[i].origin.x, bullets[i].target.x, bullets[i].clock, bullets[i].transition),
        y = bringFloatTo(bullets[i].origin.y, bullets[i].target.y, bullets[i].clock, bullets[i].transition),
        z = bringFloatTo(bullets[i].origin.z, bullets[i].target.z, bullets[i].clock, bullets[i].transition)
      }
  
      local _, oX, oY, oZ, _, _ = convert3DCoordsToScreenEx(bullets[i].origin.x, bullets[i].origin.y, bullets[i].origin.z, false, false)
      local _, tX, tY, tZ, _, _ = convert3DCoordsToScreenEx(target_offset.x, target_offset.y, target_offset.z, false, false)
  
      local col4u32 = imgui.ImVec4(bullets[i].col4[0], bullets[i].col4[1], bullets[i].col4[2], bullets[i].alpha)
  
      if ig.settings.enabled_bullets_in_screen[0] then
        if oZ > 0 and tZ > 0 then -- default
          DL:AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(tX, tY), imgui.GetColorU32Vec4(col4u32), bullets[i].thickness)
          if bullets[i].draw_polygon then
            DL:AddCircleFilled(imgui.ImVec2(tX, tY), bullets[i].circle_radius, imgui.GetColorU32Vec4(col4u32), bullets[i].degree_polygon)
          end
        elseif oZ <= 0 and tZ > 0 then -- fix origin coords
          local newPos = getFixScreenPos(target_offset, bullets[i].origin, tZ)
          _, oX, oY, oZ, _, _ = convert3DCoordsToScreenEx(newPos.x, newPos.y, newPos.z, false, false)
          DL:AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(tX, tY), imgui.GetColorU32Vec4(col4u32), bullets[i].thickness)
          if bullets[i].draw_polygon then DL:AddCircleFilled(imgui.ImVec2(tX, tY), bullets[i].circle_radius, imgui.GetColorU32Vec4(col4u32), bullets[i].degree_polygon) end
        elseif oZ > 0 and tZ <= 0 then -- fix target coords --! dont draw circle
          local newPos = getFixScreenPos(bullets[i].origin, target_offset, oZ)
          _, tX, tY, tZ, _, _ = convert3DCoordsToScreenEx(newPos.x, newPos.y, newPos.z, false, false)
          DL:AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(tX, tY), imgui.GetColorU32Vec4(col4u32), bullets[i].thickness)
        end
      else
        if tZ > 0 then
          if oZ > 0 then
            DL:AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(tX, tY), imgui.GetColorU32Vec4(col4u32), bullets[i].thickness)
          end
          if bullets[i].draw_polygon then
            DL:AddCircleFilled(imgui.ImVec2(tX, tY), bullets[i].circle_radius, imgui.GetColorU32Vec4(col4u32), bullets[i].degree_polygon)
          end
        end
      end
  
      -- Плавное исчезновение
      if (os.clock() - bullets[i].clock > bullets[i].timer) and (bullets[i].alpha > 0) then
        bullets[i].alpha = bullets[i].alpha - bullets[i].step_alpha
      end
  
      -- Удаляем трейсер, если альфа ниже/равна 0
      if bullets[i].alpha <= 0 then
        table.remove(bullets, i)
        if #bullets == 0 then break end
      end
    end
end)
frameDrawList.HideCursor = true

function sampev.onSendBulletSync(data) -- your player
    -- chat.log('X:%02f Y:%02f Z:%02f - [%d]', data.origin.x, data.origin.y, data.origin.z, data.targetType) -- DEBUG
    if ig.my_bullets.draw[0] and (data.center.x ~= 0 and data.center.y ~= 0 and data.center.z ~= 0) then
        local ig = ig.my_bullets
        local color = getColorTargetType(data.targetType, ig)
        bullets[#bullets+1] = {
            clock = os.clock(),
            timer = ig.timer[0],
            col4 = color,
            alpha = color[3],
            origin = { x = data.origin.x, y = data.origin.y, z = data.origin.z },
            target = { x = data.target.x, y = data.target.y, z = data.target.z },
            transition = ig.transition[0],
            thickness = ig.thickness[0],
            circle_radius = ig.circle_radius[0],
            step_alpha = ig.step_alpha[0],
            degree_polygon = ig.degree_polygon[0],
            draw_polygon = ig.draw_polygon[0],
        }
    end
end

local function getFirstAnyCharDistance(targetPos)
    local dists = {}
    for i, ped in pairs(getAllChars()) do
      local exist, playerId = sampGetPlayerIdByCharHandle(ped)
      if exist and sampIsPlayerConnected(playerId) then
        local pedPos = { getCharCoordinates(ped) }
        local nickname = sampGetPlayerNickname(playerId)
        dists[#dists+1] = {
          id = playerId,
          nickname = nickname,
          ped = ped,
          distance = getDistanceBetweenCoords3d(
            targetPos.x, targetPos.y, targetPos.z,
            pedPos[1], pedPos[2], pedPos[3]
          )
        }
      end
    end
  
    if #dists == 0 then return nil end
  
    table.sort(dists, function (a, b)
      return a.distance < b.distance
    end)
  
    return (dists[1].distance <= 3) and dists[1] or nil
end

local function checkWallShot(originId, data)
    local EEntityType = {
      NOTHING = 0,
      BUILDING = 1,
      VEHICLE = 2,
      PED = 3,
      OBJECT = 4,
      DUMMY = 5,
      NOTINPOOLS = 6,
    }
  
    local originPos = {
      x = data.origin.x,
      y = data.origin.y,
      z = data.origin.z
    }
  
    local targetPos = {
      x = data.target.x,
      y = data.target.y,
      z = data.target.z
    }
  
    local resultGlobal, colPointGlobal = processLineOfSight(
      originPos.x, originPos.y, originPos.z,
      targetPos.x, targetPos.y, targetPos.z,
      true, true, false, true, false,
      true, true, true
    )
  
    if not resultGlobal then return end
  
    local cleaning = isLineOfSightClear(
      originPos.x, originPos.y, originPos.z,
      targetPos.x, targetPos.y, targetPos.z,
      true, true, false,
      true, false
    )
  
    local targetPed, targetId, targetNickname
  
    local resultPed, colPointPed = processLineOfSight(
      originPos.x, originPos.y, originPos.z,
      targetPos.x, targetPos.y, targetPos.z,
      false, false, true, false, false,
      false, false, false
    )
  
    if not resultPed then
      local tbl = getFirstAnyCharDistance(targetPos)
      if not tbl then return end 
      targetPed = tbl.ped
      targetId = tbl.id
      targetNickname = tbl.nickname
    else
      targetPed = getCharPointerHandle(colPointPed.entity)
      targetId = select(2, sampGetPlayerIdByCharHandle(targetPed))
      targetNickname = sampGetPlayerNickname(targetId)
    end
  
    local originNickname = sampGetPlayerNickname(originId)
  
    local ig = ig.other_bullets
    local color
  
    if colPointGlobal.entityType == EEntityType.BUILDING and ig.settings.warning_wallshot.build[0] then
      -- detect wallshot in wall
      color = ig.col_vec4.warn_build
      chat.log(
        '%s[%d] нанес урона %s[%d] попадая здания',
        originNickname, originId, targetNickname, targetId
      )
    elseif colPointGlobal.entityType == EEntityType.OBJECT and ig.settings.warning_wallshot.obj[0] then
      -- detect wallshot in object
      color = ig.col_vec4.warn_obj
      local object = getObjectPointerHandle(colPointGlobal.entity)
      local objectModelId = getObjectModel(object)
      chat.log(
        '%s[%d] нанес урона %s[%d] попадая объекта [ID: %d]',
        originNickname, originId, targetNickname, targetId, objectModelId
      )
    elseif colPointGlobal.entityType == EEntityType.VEHICLE and ig.settings.warning_wallshot.veh[0] then
      -- detect wallshot in vehicle
      color = ig.col_vec4.warn_veh
      local vehicle = getVehiclePointerHandle(colPointGlobal.entity)
      local vehicleModelId = getCarModel(vehicle)
      chat.log(
        '%s[%d] нанес урона %s[%d] попадая машинки [ID: %d]',
        originNickname, originId, targetNickname, targetId, vehicleModelId
      )
    end
  
    bullets[#bullets+1] = {
      clock = os.clock(),
      timer = ig.timer[0] + 5,
      col4 = color,
      alpha = color[3],
      origin = { x = data.origin.x, y = data.origin.y, z = data.origin.z },
      target = { x = data.target.x, y = data.target.y, z = data.target.z },
      transition = ig.transition[0],
      thickness = ig.thickness[0] + 0.5,
      circle_radius = ig.circle_radius[0],
      step_alpha = ig.step_alpha[0],
      degree_polygon = ig.degree_polygon[0],
      draw_polygon = ig.draw_polygon[0],
    }
  
    return true
end

function sampev.onBulletSync(originId, data)
    if data.targetType == 1 and (
      ig.settings.warning_wallshot.obj[0] or
      ig.settings.warning_wallshot.veh[0] or
      ig.settings.warning_wallshot.build[0]
    ) and checkWallShot(originId, data) then
      return
    end
  
    if ig.other_bullets.draw[0] and (data.center.x ~= 0 and data.center.y ~= 0 and data.center.z ~= 0) and getDistancePosition(data.origin, ig.settings.radius_render_in_stream.distance[0]) then
      local ig = ig.other_bullets
      local color = getColorTargetType(data.targetType, ig)
      bullets[#bullets+1] = {
        clock = os.clock(),
        timer = ig.timer[0],
        col4 = color,
        alpha = color[3],
        origin = { x = data.origin.x, y = data.origin.y, z = data.origin.z },
        target = { x = data.target.x, y = data.target.y, z = data.target.z },
        transition = ig.transition[0],
        thickness = ig.thickness[0],
        circle_radius = ig.circle_radius[0],
        step_alpha = ig.step_alpha[0],
        degree_polygon = ig.degree_polygon[0],
        draw_polygon = ig.draw_polygon[0],
      }
    end
end
  
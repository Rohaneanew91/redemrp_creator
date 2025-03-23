local textureId = -1
local overlay_opacity = 1.0
local is_overlay_change_active = false
local SpawnCoords = {vector3(-558.71, -3775.46, 238.6), vector3(-558.56, -3776.83, 238.6)}
local CameraCoords = {vector3(-561.16, -3775.46, 238.9), vector3(-561.16, -3776.83, 238.9)}

local PromptRight
local PromptLeft
local PromptAccept
local AcitveCamera = 1
local cam
local CharacterCreatorCamera

local ChoiceGroup = GetRandomIntInRange(0, 0xffffff)
-- print('ChoiceGroup: ' .. ChoiceGroup)

function ChangeOverlays(name, visibility, tx_id, tx_normal, tx_material, tx_color_type, tx_opacity, tx_unk, palette_id,
    palette_color_primary, palette_color_secondary, palette_color_tertiary, var, opacity)
    for k, v in pairs(overlay_all_layers) do
        if v.name == name then
            v.visibility = visibility
            if visibility ~= 0 then
                v.tx_normal = tx_normal
                v.tx_material = tx_material
                v.tx_color_type = tx_color_type
                v.tx_opacity = tx_opacity
                v.tx_unk = tx_unk
                if tx_color_type == 0 then
                    v.palette = color_palettes[palette_id][1]
                    v.palette_color_primary = palette_color_primary
                    v.palette_color_secondary = palette_color_secondary
                    v.palette_color_tertiary = palette_color_tertiary
                end
                if name == "shadows" or name == "eyeliners" or name == "lipsticks" then
                    v.var = var
                    v.tx_id = overlays_info[name][1].id
                else
                    v.var = 0
                    v.tx_id = overlays_info[name][tx_id].id
                end
                v.opacity = opacity
            end
        end
    end

end

function GetHeadIndex(ped)
    local numComponents = Citizen.InvokeNative(0x90403E8107B60E81, ped)
    if not numComponents then return false end
        for i=0, numComponents-1, 1 do
            local componentCategory = Citizen.InvokeNative(0x9b90842304c938a7, ped, i, 0, Citizen.ResultAsInteger())
            if componentCategory == `heads` then
                return i
            end
        end
	return false
end

function ApplyOverlays(overlayTarget)
    if IsPedMale(overlayTarget) then
        current_texture_settings = texture_types["male"]
    else
        current_texture_settings = texture_types["female"]
    end
    if textureId ~= -1 then
        Citizen.InvokeNative(0xB63B9178D0F58D82, textureId) -- reset texture
        Citizen.InvokeNative(0x6BEFAA907B076859, textureId) -- remove texture
    end
    local index = GetHeadIndex(overlayTarget)
    local _, albedo, normal, material = GetMetaPedAssetGuids(ped, index)
    textureId = Citizen.InvokeNative(0xC5E7204F322E49EB, albedo, normal, material); -- create texture
    for k, v in pairs(overlay_all_layers) do
        if v.visibility ~= 0 then
            local overlay_id = Citizen.InvokeNative(0x86BB5FF45F193A02, textureId, v.tx_id, v.tx_normal, v.tx_material,
                v.tx_color_type, v.tx_opacity, v.tx_unk); -- create overlay
            if v.tx_color_type == 0 then
                Citizen.InvokeNative(0x1ED8588524AC9BE1, textureId, overlay_id, v.palette); -- apply palette
                Citizen.InvokeNative(0x2DF59FFE6FFD6044, textureId, overlay_id, v.palette_color_primary,
                    v.palette_color_secondary, v.palette_color_tertiary) -- apply palette colours
            end
            Citizen.InvokeNative(0x3329AAE2882FC8E4, textureId, overlay_id, v.var); -- apply overlay variant
            Citizen.InvokeNative(0x6C76BC24F8BB709A, textureId, overlay_id, v.opacity); -- apply overlay opacity
        end
    end
    while not Citizen.InvokeNative(0x31DC8D3F216D8509, textureId) do -- wait till texture fully loaded
        Citizen.Wait(0)
    end
    Citizen.InvokeNative(0x92DAABA2C1C10B0E, textureId) -- update texture
    Citizen.InvokeNative(0x8472A1789478F82F, textureId) -- reset texture
    Citizen.InvokeNative(0x0B46E25761519058, overlayTarget, GetHashKey("heads"), textureId) -- apply texture to current component in category "heads"
    Citizen.InvokeNative(0xCC8CA3E88256E58F, overlayTarget, 0, 1, 1, 1, false); -- refresh ped components
    -- --print(PlayerPedId() , overlayTarget)
    -- Citizen.InvokeNative(0x0B46E25761519058, overlayTarget, GetHashKey("heads"), textureId) -- apply texture to current component in category "heads"
    -- Citizen.InvokeNative(0x92DAABA2C1C10B0E, textureId) -- update texture
    -- Citizen.InvokeNative(0xCC8CA3E88256E58F, overlayTarget, 0, 1, 1, 1, false); -- refresh ped components
end

function LoadModel(target, model)
    local _model = GetHashKey(model)
    while not HasModelLoaded(_model) do
        Wait(1)
        modelrequest(_model)
    end
    Citizen.InvokeNative(0xED40380076A31506, PlayerId(), _model, false)
    if IsPedMale(PlayerPedId()) then
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4,PlayerPedId(),0,0)
    else
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4,PlayerPedId(),7,true)
    end
    NativeUpdatePedVariation(PlayerPedId())
end

function SpawnPeds()
    local SpawnedPeds = {}
    local maleHash = GetHashKey("mp_male")
    local femaleHash = GetHashKey("mp_female")
    modelrequest(maleHash)
    while not HasModelLoaded(maleHash) do
        Wait(1)
    end
    modelrequest(femaleHash)
    while not HasModelLoaded(femaleHash) do
        Wait(1)
    end

    SpawnedPeds[1] = CreatePed(maleHash, SpawnCoords[1], 102.0, true, true, 0, 0)
    while not DoesEntityExist(SpawnedPeds[1]) do
        Wait(1)
    end

    SpawnedPeds[2] = CreatePed(femaleHash, SpawnCoords[2], 102.0, true, true, 0, 0)
    while not DoesEntityExist(SpawnedPeds[2]) do
        Wait(1)
    end

    for i = 1, 2 do

        NetworkSetEntityInvisibleToNetwork(SpawnedPeds[i], true)
        SetEntityAsMissionEntity(SpawnedPeds[i], true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, SpawnedPeds[i], true)
        if i == 1 then
            Citizen.InvokeNative(0x77FF8D35EEC6BBC4, SpawnedPeds[i], 3, 0)
        else
            Citizen.InvokeNative(0x77FF8D35EEC6BBC4, SpawnedPeds[i], 7, true)
        end

        NativeUpdatePedVariation(SpawnedPeds[i])
        SetEntityInvincible(SpawnedPeds[i], true)
        SetEntityCanBeDamagedByRelationshipGroup(SpawnedPeds[i], false, GetHashKey("PLAYER"))
        if IsPedMale(SpawnedPeds[i]) then
            NativeSetPedComponentEnabled(SpawnedPeds[i], ComponentsMale["BODIES_LOWER"][10], false, true, true)
        else
            NativeSetPedComponentEnabled(SpawnedPeds[i], ComponentsFemale["BODIES_LOWER"][10], false, true, true)
        end
        NativeUpdatePedVariation(SpawnedPeds[i])

    end

    return SpawnedPeds
end

function DeletePeds(SpawnedPeds)
    for i = 1, 2 do
        DeleteEntity(SpawnedPeds[i])
    end
end

function StartRightPrompt()
    Citizen.CreateThread(function()
        local str = "Right"
        PromptRight = PromptRegisterBegin()
        PromptSetControlAction(PromptRight, 0xDEB34313)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(PromptRight, str)
        PromptSetEnabled(PromptRight, true)
        PromptSetVisible(PromptRight, true)
        PromptSetHoldMode(PromptRight, true)
        PromptSetGroup(PromptRight, ChoiceGroup)
        PromptRegisterEnd(PromptRight)

    end)
end

function StartLeftPrompt()
    Citizen.CreateThread(function()
        local str = "Left"
        PromptLeft = PromptRegisterBegin()
        PromptSetControlAction(PromptLeft, 0xA65EBAB4)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(PromptLeft, str)
        PromptSetEnabled(PromptLeft, true)
        PromptSetVisible(PromptLeft, true)
        PromptSetHoldMode(PromptLeft, true)
        PromptSetGroup(PromptLeft, ChoiceGroup)
        PromptRegisterEnd(PromptLeft)

    end)
end

function StartAcceptPrompt()
    Citizen.CreateThread(function()
        local str = "Accept"
        PromptAccept = PromptRegisterBegin()
        PromptSetControlAction(PromptAccept, 0x2CD5343E)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(PromptAccept, str)
        PromptSetEnabled(PromptAccept, true)
        PromptSetVisible(PromptAccept, true)
        PromptSetHoldMode(PromptAccept, true)
        PromptSetGroup(PromptAccept, ChoiceGroup)
        PromptRegisterEnd(PromptAccept)

    end)
end
Citizen.CreateThread(function()
    StartRightPrompt()
    StartLeftPrompt()
    StartAcceptPrompt()
end)

function StartSelectCam()
    DoScreenFadeOut(1000)
    Wait(1000)
    SetEntityCoords(PlayerPedId(), -563.99, -3776.72, 237.60)
    Wait(2000)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", CameraCoords[1].x, CameraCoords[1].y, CameraCoords[1].z, 0, 0,
        0, GetGameplayCamFov())
    PointCamAtCoord(cam, SpawnCoords[1])
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, false)
    Wait(1000)
    DoScreenFadeIn(1000)
    DisplayRadar(false)
    return LightAndCam()
end

function LightAndCam()
    while cam do
        Wait(0)
        DrawLightWithRange(-561.36, SpawnCoords[AcitveCamera].y, SpawnCoords[AcitveCamera].z + 1, 255, 255, 255, 5.5,
            25.0)
        local SelectString = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", "Choose a character",
            Citizen.ResultAsLong())
        Citizen.InvokeNative(0xFA233F8FE190514C, SelectString)
        Citizen.InvokeNative(0xE9990552DEC71600)
        local ChoiceGroupName = CreateVarString(10, 'LITERAL_STRING', "Choose")
        PromptSetActiveGroupThisFrame(ChoiceGroup, ChoiceGroupName)
        if PromptHasHoldModeCompleted(PromptLeft) then
            if AcitveCamera ~= 1 then
                AcitveCamera = 1
                MoveSelectCamera(CameraCoords[1])
            end
        end
        if PromptHasHoldModeCompleted(PromptRight) then
            if AcitveCamera ~= 2 then
                AcitveCamera = 2
                MoveSelectCamera(CameraCoords[2])
            end
        end
        if PromptHasHoldModeCompleted(PromptAccept) then
            StartCharacterCreatorCamera()
        end
    end
    local blank = Citizen.InvokeNative(0xFA925AC00EB830B9, 10, "LITERAL_STRING", " ", Citizen.ResultAsLong())
    Citizen.InvokeNative(0xFA233F8FE190514C, blank)
    Citizen.InvokeNative(0xE9990552DEC71600)
    return AcitveCamera
end

function MoveSelectCamera(c)
    local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", c.x, c.y, c.z, 0, 0, 0, GetGameplayCamFov())
    SetCamActive(cam2, true)
    SetCamActiveWithInterp(cam2, cam, 750)
    PointCamAtCoord(cam2, SpawnCoords[AcitveCamera])
    Wait(150)
    SetCamActive(cam, false)
    DestroyCam(cam)
    cam = cam2
end
local CharacterCreatorCamera

function CreatorLight()
    Citizen.CreateThread(function()
        while CharacterCreatorCamera do
            Wait(0)
            DrawLightWithRange(-560.133, -3780.92, 238.6, 255, 255, 255, 10.5, 50.0)
            if IsDisabledControlPressed(0, 0x06052D11) then
                local heading = GetEntityHeading(PlayerPedId())
                SetEntityHeading(PlayerPedId(), heading + 2)
            end
            if IsDisabledControlPressed(0, 0x110AD1D2) then
                local heading = GetEntityHeading(PlayerPedId())
                SetEntityHeading(PlayerPedId(), heading - 2)
            end
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
        end
    end)
end

-- EZC74cSnnr

function StartCharacterCreatorCamera()
    SetEntityCoords(PlayerPedId(), -558.32, -3781.11, 237.60)
    SetEntityHeading(PlayerPedId(), 102.0)
    local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", -558.84, -3779.27, 238.6, 0, 0, 0, GetGameplayCamFov())
    SetCamActive(cam2, true)
    SetCamActiveWithInterp(cam2, cam, 1000)
    PointCamAtCoord(cam2, -558.32, -3781.11, 238.60)
    Wait(750)
    SetCamActive(cam, false)
    DestroyCam(cam)
    cam = nil
    CharacterCreatorCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", -560.133, -3780.92, 238.6, 0, 0, 0,
        GetGameplayCamFov())
    SetCamActive(CharacterCreatorCamera, true)
    SetCamActiveWithInterp(CharacterCreatorCamera, cam2, 1000)
    PointCamAtCoord(CharacterCreatorCamera, -558.32, -3781.11, 238.60)
    CreatorLight()

end

function MoveCharacterCreatorCamera(x, y, z)
    local cam2 = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", x, y, z, 0, 0, 0, GetGameplayCamFov())
    SetCamActive(cam2, true)
    SetCamActiveWithInterp(cam2, CharacterCreatorCamera, 750)
    PointCamAtCoord(cam2, -558.32, -3781.11, z)
    Wait(150)
    SetCamActive(CharacterCreatorCamera, false)
    DestroyCam(CharacterCreatorCamera)
    CharacterCreatorCamera = cam2
end

function EndCharacterCreatorCam()
    RenderScriptCams(false, true, 1000, true, false)
    DestroyCam(CharacterCreatorCamera, false)
    CharacterCreatorCamera = nil
    DisplayHud(true)
    DisplayRadar(true)
    DestroyAllCams(true)
    -- FreezeEntityPosition(PlayerPedId() , false)
end

function GetHashHead(aMale,num,color)
    color = color or 1
    num = num or 1
    if color == 1 then color = 1
    elseif color == 2 then color = 4
    elseif color == 3 then color = 3
    elseif color == 4 then color = 5
    elseif color == 5 then color = 2
    elseif color == 6 then color = 6
    end
    if aMale then
        if num == 16 then num = 18
            elseif num == 17 then num = 21
            elseif num == 18 then num = 22
            elseif num == 19 then num = 25
            elseif num == 20 then num = 28
            end
        else
            if num == 17 then num = 20
            elseif num == 18 then num = 22
            elseif num == 19 then num = 27
            elseif num == 20 then num = 28
        end
    end
    local suffix = ("%03d"):format(num or 1)..'_V_'..("%03d"):format(color or 1)
    local sex = (aMale == true) and "M" or "F"
    return GetHashKey(('CLOTHING_ITEM_%s_HEAD_%s'):format(sex,suffix))
end

function LoadBody(target, data)
    local output = GetSkinColorFromBodySize(tonumber(data.body_size), tonumber(data.skin_tone))
    local torso
    local legs
    local head
    local headNum = math.ceil((data.head or 1)/6)
    if IsPedMale(target) then
        head = GetHashHead(true,headNum,data.skin_tone)
        torso = ComponentsMale["BODIES_UPPER"][output]
        legs = ComponentsMale["BODIES_LOWER"][output]
    else
        head = GetHashHead(false,headNum,data.skin_tone)
        torso = ComponentsFemale["BODIES_UPPER"][output]
        legs = ComponentsFemale["BODIES_LOWER"][output]
    end
    NativeSetPedComponentEnabled(target, tonumber(torso), false, true, true)
    NativeSetPedComponentEnabled(target, tonumber(legs), false, true, true)
    NativeSetPedComponentEnabled(target, tonumber(head), false, true, true)
end

function GetSkinColorFromBodySize(body, color)
    if body == 1 then
        if color == 1 then
            return 7
        elseif color == 2 then
            return 10
        elseif color == 3 then
            return 9
        elseif color == 4 then
            return 11
        elseif color == 5 then
            return 8
        elseif color == 6 then
            return 12
        end
    elseif body == 2 then
        if color == 1 then
            return 1
        elseif color == 2 then
            return 4
        elseif color == 3 then
            return 3
        elseif color == 4 then
            return 5
        elseif color == 5 then
            return 2
        elseif color == 6 then
            return 6
        end
    elseif body == 3 then
        if color == 1 then
            return 13
        elseif color == 2 then
            return 16
        elseif color == 3 then
            return 15
        elseif color == 4 then
            return 17
        elseif color == 5 then
            return 14
        elseif color == 6 then
            return 18
        end
    elseif body == 4 then
        if color == 1 then
            return 19
        elseif color == 2 then
            return 22
        elseif color == 3 then
            return 21
        elseif color == 4 then
            return 23
        elseif color == 5 then
            return 20
        elseif color == 6 then
            return 24
        end
    elseif body == 5 then
        if color == 1 then
            return 25
        elseif color == 2 then
            return 28
        elseif color == 3 then
            return 27
        elseif color == 4 then
            return 29
        elseif color == 5 then
            return 26
        elseif color == 6 then
            return 30
        end
    else
        if color == 1 then
            return 13
        elseif color == 2 then
            return 16
        elseif color == 3 then
            return 15
        elseif color == 4 then
            return 17
        elseif color == 5 then
            return 14
        elseif color == 6 then
            return 18
        end
    end

end

function LoadHair(target, data)
    if data.hair ~= nil then
        if type(data.hair) ~= "table" then data.hair = { hash = data.hair } end
        if data.hair.model ~= nil then
            if tonumber(data.hair.model) > 0 then
                if IsPedMale(target) then
                    if hairs_list["male"]["hair"][tonumber(data.hair.model)] ~= nil then
                        if hairs_list["male"]["hair"][tonumber(data.hair.model)][tonumber(data.hair.texture)] ~= nil then
                            local hair = hairs_list["male"]["hair"][tonumber(data.hair.model)][tonumber(data.hair.texture)].hash
                            data.hair.hash = hair
                            NativeSetPedComponentEnabled(target, tonumber(hair), false, true, true)
                        end
                    end
                else
                    if hairs_list["female"]["hair"][tonumber(data.hair.model)] ~= nil then
                        if hairs_list["female"]["hair"][tonumber(data.hair.model)][tonumber(data.hair.texture)] ~=
                            nil then
                            local hair = hairs_list["female"]["hair"][tonumber(data.hair.model)][tonumber(data.hair.texture)].hash
                            data.hair.hash = hair
                            NativeSetPedComponentEnabled(target, tonumber(hair), false, true, true)
                        end
                    end
                end
            else
                Citizen.InvokeNative(0xD710A5007C2AC539, target, 0x864B03AE, 0)
                NativeUpdatePedVariation(target)
            end
        elseif data.hair.hash then
            if data.hair.hash ~= 0 then
                NativeSetPedComponentEnabled(target, tonumber(data.hair.hash), false, true, true)
            else
                Citizen.InvokeNative(0xD710A5007C2AC539, target, 0x864B03AE, 0)
                NativeUpdatePedVariation(target)
            end
        end
    end
end


function LoadBeard(target, data)
    if data.beard ~= nil then
        if type(data.beard) ~= "table" then data.beard = { hash = data.beard } end
        if data.beard.model ~= nil then
            if tonumber(data.beard.model) > 0 then
                if IsPedMale(target) then
                    if hairs_list["male"]["beard"][tonumber(data.beard.model)] ~= nil then
                        if hairs_list["male"]["beard"][tonumber(data.beard.model)][tonumber(data.beard.texture)] ~=
                            nil then
                            local beard = hairs_list["male"]["beard"][tonumber(data.beard.model)][tonumber(data.beard.texture)].hash
                            data.beard.hash = beard
                            NativeSetPedComponentEnabled(target, tonumber(beard), false, true, true)
                        end
                    end
                end
            else
                Citizen.InvokeNative(0xD710A5007C2AC539, target, 0xF8016BCA, 0)
                NativeUpdatePedVariation(target)
            end
        elseif data.beard.hash then
            if data.beard.hash ~= 0 then
                NativeSetPedComponentEnabled(target, tonumber(data.beard.hash), false, true, true)
            else
                Citizen.InvokeNative(0xD710A5007C2AC539, target, 0xF8016BCA, 0)
                NativeUpdatePedVariation(target)
            end
        end
    end
end


function LoadHead(target, data)
    local headNum = math.ceil((data.head or 1)/6)
    if IsPedMale(target) then
        local head = GetHashHead(true,headNum,data.skin_tone)
        NativeSetPedComponentEnabled(target, tonumber(head), false, true, true)
    else
        local head = GetHashHead(false,headNum,data.skin_tone)
        NativeSetPedComponentEnabled(target, tonumber(head), false, true, true)
    end
end

function LoadEyes(target, data)
    if IsPedMale(target) == 1 then
        local eyes_color = ComponentsMale["eyes"][tonumber(data.eyes_color) or 1]
        NativeSetPedComponentEnabled(target, tonumber(eyes_color), false, true, true)
    else
        local eyes_color = ComponentsFemale["eyes"][tonumber(data.eyes_color) or 1]
        -- print(GetLabelTextByHash(tonumber(eyes_color)))
        NativeSetPedComponentEnabled(target, tonumber(eyes_color), false, true, true)
    end
end

function LoadBodySize(target, data)
    Citizen.InvokeNative(0x1902C4CFCC5BE57C, target, BODY_TYPES[tonumber(data.body_size)])
    NativeUpdatePedVariation(target)
    
end

function LoadBodyWaist(target, data)
    Citizen.InvokeNative(0x1902C4CFCC5BE57C, target, WAIST_TYPES[tonumber(data.body_waist)])
    NativeUpdatePedVariation(target)
end

function LoadTeeth(target, data)
    local animf = {"mouth_looted","face_human@gen_male_timid@base"}
    RequestAnimDict(animf[2])
    while not HasAnimDictLoaded(animf[2]) do 
        Wait(1)
    end
    local a = "male"
    if not IsPedMale(target) then 
        a = "female"
    end
    local b = GetHashKey(TEETH_TYPES[a]..(data.teeth or 0))
    data.teeth = b
    NativeSetPedComponentEnabled(target, b, true, true, true)
    NativeUpdatePedVariation(target)
    SetFacialIdleAnimOverride(target, animf[2], animf[1])
    SetTimeout(2000, function()
        ClearFacialIdleAnimOverride(target)
    end)
end

function LoadFeatures(target, data)
    local feature
    for k, v in pairs(features_name) do
        feature = features[k]
        if data[v] ~= nil then
            local value = data[v] / 100
            NativeSetPedFaceFeature(target, feature, value)
        end
    end
end

function LoadHeight(target, data)
    if data.height ~= nil then
        Wait(100)
        SetPedScale(target, tonumber(data.height / 100))
    end
end

function FixIssues(target, data)
    if IsPedMale(target) then
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4, target, 0, 0)
        NativeUpdatePedVariation(target)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsMale["BODIES_UPPER"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsMale["BODIES_LOWER"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsMale["heads"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsMale["eyes"][1]), false, true, true)
        Citizen.InvokeNative(0xD710A5007C2AC539, target, 0x1D4C528A, 0)
    else
        Citizen.InvokeNative(0x77FF8D35EEC6BBC4, target, 7, true)
        NativeUpdatePedVariation(target)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsFemale["BODIES_UPPER"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsFemale["BODIES_LOWER"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsFemale["heads"][1]), false, true, true)
        NativeSetPedComponentEnabled(target, tonumber(ComponentsFemale["eyes"][1]), false, true, true)
        -- NativeSetPedComponentEnabled( target, 0x1EECD215, false, true, true)
    end
    Citizen.InvokeNative(0xD710A5007C2AC539, target, 0x3F1F01E5, 0)
    Citizen.InvokeNative(0xD710A5007C2AC539, target, 0xDA0E2C55, 0)
    NativeUpdatePedVariation(target)
end

function LoadOverlays(target, data)

    if tonumber(data.eyebrows_t) ~= nil and tonumber(data.eyebrows_op) ~= nil then
        ChangeOverlays("eyebrows", 1, tonumber(data.eyebrows_t), 0, 0, 0, 1.0, 0, tonumber(data.eyebrows_id) or 1,
            tonumber(data.eyebrows_c1) or 0, 0, 0, 0, tonumber(data.eyebrows_op / 100))
    else
        ChangeOverlays("eyebrows", 1, 1, 0, 0, 0, 1.0, 0, 10, 0, 0, 0, 0, 1.0)
    end

    if tonumber(data.scars_t) ~= nil and tonumber(data.scars_op) ~= nil then
        ChangeOverlays("scars", 1, tonumber(data.scars_t), 0, 0, 1, 1.0, 0, tonumber(0), 0, 0, 0, tonumber(0),
            tonumber(data.scars_op / 100))
    end

    if tonumber(data.ageing_t) ~= nil and tonumber(data.ageing_op) ~= nil then
        ChangeOverlays("ageing", 1, tonumber(data.ageing_t), 0, 0, 1, 1.0, 0, tonumber(0), 0, 0, 0, tonumber(0),
            tonumber(data.ageing_op / 100))
    end

    if tonumber(data.freckles_t) ~= nil and tonumber(data.freckles_op) ~= nil then
        ChangeOverlays("freckles", 1, tonumber(data.freckles_t), 0, 0, 1, 1.0, 0, tonumber(0), 0, 0, 0, tonumber(0),
            tonumber(data.freckles_op / 100))
    end

    if tonumber(data.moles_t) ~= nil and tonumber(data.moles_op) ~= nil then
        ChangeOverlays("moles", 1, tonumber(data.moles_t), 0, 0, 1, 1.0, 0, tonumber(0), 0, 0, 0, tonumber(0),
            tonumber(data.moles_op / 100))
    end

    if tonumber(data.spots_t) ~= nil and tonumber(data.spots_op) ~= nil then
        ChangeOverlays("spots", 1, tonumber(data.spots_t), 0, 0, 1, 1.0, 0, tonumber(0), 0, 0, 0, tonumber(0),
            tonumber(data.spots_op / 100))
    end

    if tonumber(data.eyeliners_t) ~= nil and tonumber(data.eyeliners_op) ~= nil then
        ChangeOverlays("eyeliners", 1, 1, 0, 0, 0, 1.0, 0, tonumber(data.eyeliners_id) or 1,
            tonumber(data.eyeliners_c1) or 0, 0, 0, tonumber(data.eyeliners_t), tonumber(data.eyeliners_op / 100))
    end

    if tonumber(data.shadows_t) ~= nil and tonumber(data.shadows_op) ~= nil then
        ChangeOverlays("shadows", 1, tonumber(1), 0, 0, 0, 1.0, 0, tonumber(data.shadows_id) or 1,
            tonumber(data.shadows_c1) or 0, 0, 0, tonumber(data.shadows_t), tonumber(data.shadows_op / 100))
    end

    if tonumber(data.lipsticks_t) ~= nil and tonumber(data.lipsticks_op) ~= nil then
        ChangeOverlays("lipsticks", 1, 1, 0, 0, 0, 1.0, 0, tonumber(data.lipsticks_id) or 1,
            tonumber(data.lipsticks_c1) or 0, tonumber(data.lipsticks_c2) or 0, 0, tonumber(data.lipsticks_t),
            tonumber(data.lipsticks_op / 100))
    end

    if tonumber(data.blush_t) ~= nil and tonumber(data.blush_op) ~= nil then
        ChangeOverlays("blush", 1, tonumber(data.blush_t), 0, 0, 0, 1.0, 0, tonumber(data.blush_id) or 1,
            tonumber(data.blush_c1) or 0, 0, 0, 0, tonumber(data.blush_op / 100))
    end

    if tonumber(data.beardstabble_t) ~= nil and tonumber(data.beardstabble_op) ~= nil then
        ChangeOverlays("beardstabble", 1, 1, 0, 0, 0, 1.0, 0, 10, 0, 0, 0, 0, tonumber(data.beardstabble_op / 100))
    end
    ApplyOverlays(target)
end

function HasBodyComponentsLoaded(target, hair, beard)
    local _target = target
    local output = true
    if not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0x378AD10C)) or
        not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0xEA24B45E)) or
        not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0x823687F5)) or
        not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0xB3966C9)) then
        output = false
    end
    if hair ~= nil then
        if hair > 0 and not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0x864B03AE)) then
            output = false
        end
    end
    if beard ~= nil then
        if beard > 0 and not Citizen.InvokeNative(0xFB4891BD7578CDC1, _target, tonumber(0xF8016BCA)) then
            output = false
        end
    end
    if not Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, _target) then
        output = false
    end
    return output
end

function GetMaxTexturesForModel(category, model)
    -- print(model)
    -- print(category)
    if model == 0 then
        model = 1
    end
    if IsPedMale(PlayerPedId()) then
        return #hairs_list["male"][category][model]
    else
        return #hairs_list["female"][category][model]
    end
end

function NativeSetPedFaceFeature(ped, index, value)
    Citizen.InvokeNative(0x5653AB26C82938CF, ped, index, value)
    NativeUpdatePedVariation(ped)
end

function NativeSetPedComponentEnabled(ped, componentHash, immediately, isMp)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, componentHash, immediately, isMp, true)
    NativeUpdatePedVariation(ped)
end

function NativeHasPedComponentLoaded(ped)
    return Citizen.InvokeNative(0xA0BC8FAED8CFEB3C, ped)
end

function NativeUpdatePedVariation(ped)
    Citizen.InvokeNative(0x704C908E9C405136, ped)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
    while not NativeHasPedComponentLoaded(ped) do
        Wait(1)
    end
end

function NativeSetTextureOutfitTints(ped,category,palette,tint0,tint1,tint2)
    return Citizen.InvokeNative(0x4EFC1F8FF1AD94DE,ped,category,palette,tint0,tint1,tint2)
end

function modelrequest(model)
    Citizen.CreateThread(function()
        RequestModel(model)
    end)
end

function GetPedModel(sex)
    local model = "mp_male"
    if sex == 1 then
        model = "mp_male"
    elseif sex == 2 then
        model = "mp_female"
    end
    return model
end
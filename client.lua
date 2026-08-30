local QBCore = nil
local ESX = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local uiOpen = false

-- ====================================================================
-- LOCALES
-- Loads the language file based on Config.Language from config.lua
-- ====================================================================
function LoadLocales(lang)
    lang = lang and lang:lower():gsub("%s+", "") or "tr"
    if lang == "" then lang = "tr" end
    local resource = GetCurrentResourceName()
    local file = LoadResourceFile(resource, 'locales/' .. lang .. '.lua')
    if not file then
        file = LoadResourceFile(resource, 'locales/tr.lua')
    end
    if file then
        local chunk, err = load(file, 'locale')
        if chunk then
            local ok, data = pcall(chunk)
            if ok and data then
                return data
            end
        end
    end
    -- Safe fallback if the file cannot be loaded (default language: TR)
    return {
        playerId = "OYUNCU ID",
        vehicleCode = "ARAÇ KODU",
        plate = "PLAKA",
        plateColor = "PLAKA RENK",
        colors = {
            "Beyaz Zemin - Mavi Yazı",
            "Siyah Zemin - Sarı Yazı",
            "Mavi Zemin - Sarı Yazı",
            "Beyaz Zemin - Mavi Yazı 2",
            "Beyaz Zemin - Mavi Yazı 3",
            "North Yankton"
        },
        cancel = "IPTAL",
        give = "ARACI VER",
        errRequired = "Oyuncu ID ve araç kodu zorunludur.",
        processing = "İşleniyor..."
    }
end

local Locales = LoadLocales(Config.Language)

-- ====================================================================
-- ADMIN CHECK
-- ====================================================================
function IsPlayerAdmin(cb)
    if Config.Framework == 'qb' then
        QBCore.Functions.TriggerCallback('kasrev-givecar:isAdmin', function(ok)
            cb(ok)
        end)
    else
        ESX.TriggerServerCallback('kasrev-givecar:isAdmin', function(ok)
            cb(ok)
        end)
    end
end

-- ====================================================================
-- OPEN / CLOSE UI
-- ====================================================================
function OpenUI()
    if uiOpen then return end
    IsPlayerAdmin(function(ok)
        if not ok then
            Notify("Bu islem icin yetkiniz yok!", "error")
            return
        end
        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "open",
            lang = Config.Language,
            locales = Locales
        })
        CreateThread(PlayGiveAnim)
    end)
end

function CloseUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    StopGiveAnim()
end

-- ====================================================================
-- CHARACTER ANIMATION (PAPER - PEN)
-- ====================================================================
local animProp = nil
local animPlaying = false

function PlayGiveAnim()
    if not Config.PedAnimation then return end
    local ped = PlayerPedId()
    local dict = Config.PedAnimationDict
    local anim = Config.PedAnimationName

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

    local propModel = Config.PedProp
    if propModel and propModel ~= "" then
        local hash = GetHashKey(propModel)
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            Wait(0)
        end
        animProp = CreateObject(hash, 0, 0, 0, true, true, true)
        AttachEntityToEntity(
            animProp, ped,
            GetPedBoneIndex(ped, 36029),
            0.10, 0.02, 0.08, 10.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )
    end
    animPlaying = true
end

function StopGiveAnim()
    if not animPlaying then return end
    local ped = PlayerPedId()
    StopAnimTask(ped, Config.PedAnimationDict, Config.PedAnimationName, 1.5)
    ClearPedTasks(ped)
    if animProp and DoesEntityExist(animProp) then
        DeleteObject(animProp)
        animProp = nil
    end
    RemoveAnimDict(Config.PedAnimationDict)
    animPlaying = false
end

-- ====================================================================
-- SPAWN VEHICLE IN FRONT OF THE PLAYER (COLOR + FULL FUEL)
-- ====================================================================
RegisterNetEvent("kasrev-givecar:spawnVehicle", function(model, plate, plateColor, vehicleColor)
    local ply = PlayerPedId()
    if not DoesEntityExist(ply) then return end

    local r, g, b = 255, 255, 255
    if vehicleColor and vehicleColor ~= "" then
        local parts = {}
        for v in string.gmatch(tostring(vehicleColor), "([^,]+)") do
            parts[#parts + 1] = tonumber(v)
        end
        if parts[1] then
            r = parts[1]
            g = parts[2] or r
            b = parts[3] or r
        end
    end

    local coords = GetEntityCoords(ply)
    local heading = GetEntityHeading(ply)
    local fwd = GetOffsetFromEntityInWorldCoords(ply, 0, 5.0, 0.5)
    local spawnZ = fwd.z + 1.5

    local function placeVehicle(veh)
        if not DoesEntityExist(veh) then return end
        SetEntityCoords(veh, fwd.x, fwd.y, spawnZ, false, false, false, true)
        SetVehicleOnGroundProperly(veh)
        SetEntityHeading(veh, heading)
        SetVehicleNumberPlateText(veh, plate)
        SetVehicleNumberPlateTextIndex(veh, tonumber(plateColor) or 0)
        SetVehicleCustomPrimaryColour(veh, r, g, b)
        SetVehicleCustomSecondaryColour(veh, r, g, b)
        SetVehicleFuelLevel(veh, 100.0)
        SetEntityAsMissionEntity(veh, true, true)
        if Config.Framework == 'qb' then
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        end
    end

    if Config.Framework == 'qb' then
        QBCore.Functions.SpawnVehicle(model, function(veh)
            placeVehicle(veh)
        end, plate, vector4(fwd.x, fwd.y, spawnZ, heading), true)
    else
        local hash = GetHashKey(model)
        ESX.Game.SpawnVehicle(hash, vector3(fwd.x, fwd.y, spawnZ), heading, function(veh)
            placeVehicle(veh)
        end)
    end
end)

RegisterCommand(Config.Command, function()
    if uiOpen then
        CloseUI()
    else
        OpenUI()
    end
end)

RegisterKeyMapping(Config.Command, Config.KeyMappingDesc, 'keyboard', Config.KeyMapping)

RegisterNUICallback("exit", function(_, cb)
    CloseUI()
    cb({})
end)

-- ====================================================================
-- VEHICLE GIVE REQUEST
-- ====================================================================
RegisterNUICallback("giveCar", function(data, cb)
    local targetId = tonumber(data.targetId)
    local model = (data.model or ""):lower():gsub("%s+", "")
    local plate = (data.plate or ""):upper():gsub("%s+", "")
    local plateColor = tonumber(data.plateColor) or 0
    local vehicleColor = data.vehicleColor or "255,255,255"

    if not targetId or targetId < 1 then
        OxNotify("Oyuncu ID girilmedi.", "error")
        cb({ success = false, message = "Gecerli bir oyuncu ID girin." })
        return
    end

    if model == "" then
        OxNotify("Araç kodu girilmedi.", "error")
        cb({ success = false, message = "Arac kodunu girin." })
        return
    end

    -- Blacklisted vehicle check (client)
    if Config.BlacklistedVehicles then
        for _, blocked in ipairs(Config.BlacklistedVehicles) do
            if model == string.lower(blocked) then
                OxNotify("Bu araç yasaklı: " .. model, "error")
                cb({ success = false, message = "Bu araç yasaklı: " .. model })
                return
            end
        end
    end

    -- Client-side model validation
    if Config.Limits.ValidateModel then
        local hash = GetHashKey(model)
        if hash == 0 or not IsModelInCdimage(hash) then
            OxNotify("Araç kodu geçersiz: " .. model, "error")
            cb({ success = false, message = "Gecersiz arac kodu: " .. model })
            return
        end
    end

    if Config.Plate.AutoGenerateIfEmpty and plate == "" then
        plate = nil
    end

    TriggerServerEvent("kasrev-givecar:give", targetId, model, plate, plateColor, vehicleColor)

    cb({ success = true })
end)

-- ====================================================================
-- SERVER RESULT MESSAGES
-- ====================================================================
RegisterNetEvent("kasrev-givecar:result", function(success, message)
    SendNUIMessage({
        action = "result",
        success = success,
        message = message
    })
    Notify(message, success and "success" or "error")
    if success then
        CreateThread(function()
            Wait(600)
            CloseUI()
        end)
    end
end)

-- ====================================================================
-- HELPERS
-- ====================================================================
function Notify(msg, type)
    if Config.Framework == 'qb' then
        QBCore.Functions.Notify(msg, type, 5000)
    else
        ESX.ShowNotification(msg)
    end
end

function OxNotify(msg, type)
    local state = GetResourceState('ox_lib')
    if state == 'started' or state == 'starting' then
        exports.ox_lib:notify({
            title = 'Kasrev GiveCar',
            description = msg,
            type = type or 'inform',
            duration = 5000
        })
    else
        Notify(msg, type)
    end
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if uiOpen then
            SetNuiFocus(false, false)
        end
        StopGiveAnim()
    end
end)

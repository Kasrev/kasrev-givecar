local QBCore = nil
local ESX = nil

if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

-- ====================================================================
-- DISCORD ID CHECK
-- ====================================================================
function GetDiscordId(src)
    local discord = nil
    if Config.Framework == 'qb' then
        discord = QBCore.Functions.GetIdentifier(src, 'discord')
    else
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            if id and string.find(id, "discord:") then
                discord = id
                break
            end
        end
    end

    if not discord then return nil end
    -- "discord:123456789" -> "123456789"
    local cleaned = string.gsub(discord, "discord:", "")
    return cleaned
end

function IsDiscordAllowed(src)
    if not Config.AllowedDiscordIds or #Config.AllowedDiscordIds == 0 then
        return false
    end
    local discord = GetDiscordId(src)
    if not discord then return false end
    for _, id in ipairs(Config.AllowedDiscordIds) do
        if tostring(id) == tostring(discord) then
            return true
        end
    end
    return false
end

if Config.Framework == 'qb' then
    QBCore.Functions.CreateCallback('kasrev-givecar:isAdmin', function(source, cb)
        cb(CanGiveCar(source))
    end)
else
    ESX.RegisterServerCallback('kasrev-givecar:isAdmin', function(source, cb)
        cb(CanGiveCar(source))
    end)
end

-- ====================================================================
-- PERMISSION CHECK (Discord ID only)
-- ====================================================================
function CanGiveCar(src)
    return IsDiscordAllowed(src)
end

-- ====================================================================
-- FIND TARGET PLAYER
-- ====================================================================
function GetTarget(targetId)
    if Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(targetId)
    else
        return ESX.GetPlayerFromId(targetId)
    end
end

-- ====================================================================
-- GENERATE PLATE
-- ====================================================================
function GeneratePlate()
    math.randomseed(os.time() + math.random(1, 1000000))
    local chars = Config.Plate.Charset
    local plate = ""
    for i = 1, Config.Plate.Length do
        local r = math.random(1, #chars)
        plate = plate .. chars:sub(r, r)
    end
    if IsPlateTaken(plate) then
        return GeneratePlate()
    end
    return plate
end

function IsPlateTaken(plate)
    if Config.Framework == 'qb' then
        local result = MySQL.Sync.fetchAll("SELECT plate FROM player_vehicles WHERE plate = ?", { plate })
        return result and #result > 0
    else
        local result = MySQL.Sync.fetchAll("SELECT plate FROM owned_vehicles WHERE plate = ?", { plate })
        return result and #result > 0
    end
end

-- ====================================================================
-- GIVE VEHICLE
-- ====================================================================
local adminCooldowns = {}
local COOLDOWN_SECONDS = 5

RegisterNetEvent("kasrev-givecar:give", function(targetId, model, plate, plateColor, vehicleColor)
    local src = source
    vehicleColor = vehicleColor or "255,255,255"

    if not CanGiveCar(src) then
        TriggerClientEvent("kasrev-givecar:result", src, false, "Yetkiniz yok!")
        return
    end

    -- Spam protection (5 seconds per admin)
    local now = os.time()
    if adminCooldowns[src] and (now - adminCooldowns[src]) < COOLDOWN_SECONDS then
        local kalan = COOLDOWN_SECONDS - (now - adminCooldowns[src])
        TriggerClientEvent("kasrev-givecar:result", src, false, "Biraz bekleyin, " .. kalan .. " sn kaldı.")
        return
    end

    local target = GetTarget(targetId)
    if not target then
        TriggerClientEvent("kasrev-givecar:result", src, false, "Oyuncu bulunamadi (ID: " .. tostring(targetId) .. ")")
        return
    end

    if Config.Plate.AutoGenerateIfEmpty and (not plate or plate == "") then
        plate = GeneratePlate()
    end

    if Config.Limits.UniquePlate and IsPlateTaken(plate) then
        TriggerClientEvent("kasrev-givecar:result", src, false, "Bu plaka zaten kullanımda: " .. plate)
        return
    end

    local hash = GetHashKey(model)
    plateColor = tonumber(plateColor) or 0

    -- Blacklisted vehicle check
    if Config.BlacklistedVehicles and #Config.BlacklistedVehicles > 0 then
        for _, blocked in ipairs(Config.BlacklistedVehicles) do
            if model == string.lower(blocked) then
                TriggerClientEvent("kasrev-givecar:result", src, false, "Bu araç yasaklı: " .. model)
                return
            end
        end
    end

    -- Valid give request: start cooldown
    adminCooldowns[src] = now

    local success = false
    if Config.Framework == 'qb' then
        local citizenid = target.PlayerData.citizenid
        local license = target.PlayerData.license or (target.PlayerData.charinfo and target.PlayerData.charinfo.license)
        local charName = "ID " .. targetId
        if target.PlayerData.charinfo then
            charName = (target.PlayerData.charinfo.firstname or "") .. " " .. (target.PlayerData.charinfo.lastname or "")
            charName = charName:gsub("^%s*(.-)%s*$", "%1")
            if charName == "" then charName = "ID " .. targetId end
        end
        local props = json.encode({
            model = model,
            plate = plate,
            plateIndex = plateColor,
            fuelLevel = 100,
            customPrimaryColor = vehicleColor,
            customSecondaryColor = vehicleColor,
        })
        MySQL.Async.insert(
            "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            {
                license,
                citizenid,
                model,
                tostring(hash),
                props,
                plate,
                0,
                "pillbox"
            },
            function(insertId)
                if insertId and insertId > 0 then
                    TriggerClientEvent("kasrev-givecar:result", src, true,
                        charName .. " (" .. targetId .. ") oyuncusuna " .. model .. " (" .. plate .. ") verildi.")
                    TriggerClientEvent("kasrev-givecar:result", targetId, true,
                        "Size bir arac verildi: " .. model .. " - Plaka: " .. plate)
                    if Config.Plate.GiveMode == 'spawn' then
                        TriggerClientEvent("kasrev-givecar:spawnVehicle", targetId, model, plate, plateColor, vehicleColor)
                    end
                else
                    TriggerClientEvent("kasrev-givecar:result", src, false, "Arac verilirken hata olustu.")
                end
            end
        )
    else
        local identifier = target.getIdentifier and target:getIdentifier() or target.identifier
        local vehicleData = json.encode({
            model = model,
            plate = plate,
            plateIndex = plateColor,
            fuelLevel = 100,
            customPrimaryColor = vehicleColor,
            customSecondaryColor = vehicleColor,
        })
        MySQL.Async.insert(
            "INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)",
            {
                identifier,
                plate,
                vehicleData,
                1
            },
            function(insertId)
                if insertId and insertId > 0 then
                    TriggerClientEvent("kasrev-givecar:result", src, true,
                        target.getName and target:getName() or ("ID " .. targetId) .. " oyuncusuna " .. model .. " (" .. plate .. ") verildi.")
                    TriggerClientEvent("kasrev-givecar:result", targetId, true,
                        "Size bir arac verildi: " .. model .. " - Plaka: " .. plate)
                    if Config.Plate.GiveMode == 'spawn' then
                        TriggerClientEvent("kasrev-givecar:spawnVehicle", targetId, model, plate, plateColor, vehicleColor)
                    end
                else
                    TriggerClientEvent("kasrev-givecar:result", src, false, "Arac verilirken hata olustu.")
                end
            end
        )
    end
end)

AddEventHandler("playerDropped", function()
    adminCooldowns[source] = nil
end)

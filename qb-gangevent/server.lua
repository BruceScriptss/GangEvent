local QBCore = exports['qb-core']:GetCoreObject()

-- Variables globales
local participatingGangs = {}

RegisterCommand("startCargo", function(source)
    TriggerClientEvent('qb-gangevent:startCargoActivity', -1)
    TriggerClientEvent('qb-gangevent:notifyAllGangs', -1,
        "La actividad de cargo ha comenzado. ¡Tienen 1 minuto para unirse con /joinAct!")
end)

RegisterNetEvent('qb-gangevent:joinActivity')
AddEventHandler('qb-gangevent:joinActivity', function(gangName)
    participatingGangs[gangName] = true
    print(gangName .. " se ha unido a la actividad.")
end)

-- Función para encontrar el jugador por citizenId
function GetPlayerByCitizenId(citizenId)
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player and player.PlayerData.citizenid == citizenId then
            return player
        end
    end
    return nil
end

-- Función para otorgar la recompensa aleatoria
local function giveRandomReward(player)
    if not player then
        print("Jugador no encontrado.")
        return
    end

    -- Tabla de recompensas posibles
    local rewards = {
        { type = "baja",  item = "WEAPON_SNSPISTOL",label = "PISTOLA COMPACTA" }, -- Recompensa baja
        { type = "media", item = "WEAPON_PISTOL",label = "BERETTA" },   -- Recompensa media
        { type = "alta",  item = "WEAPON_COMBATPISTOL",label = "GLOCK" } -- Recompensa alta
    }

    -- Seleccionar una recompensa al azar
    local randomReward = rewards[math.random(1, #rewards)]

    -- Otorgar el arma al jugador
    player.Functions.AddItem(randomReward.item, 1)
    TriggerClientEvent('inventory:client:ItemBox', player.PlayerData.source, QBCore.Shared.Items[randomReward.item],
        'add')

    -- Notificar al jugador sobre la recompensa
    TriggerClientEvent('QBCore:Notify', player.PlayerData.source,
        "Has recibido una recompensa de tipo " .. randomReward.type .. ": " .. randomReward.item, "success")
    print("Recompensa de tipo " .. randomReward.type .. " otorgada: " .. randomReward.item)
end

RegisterNetEvent('qb-gangevent:announceVictory')
AddEventHandler('qb-gangevent:announceVictory', function(gangName, citizenId)
    -- Anunciar la victoria en el chat
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { "Sistema", "La organización " .. gangName .. " ha encontrado la mercancía!" }
    })

    -- Lógica para recompensar al jugador
    local player = GetPlayerByCitizenId(citizenId)
    print(player)
    if player then
        -- Dar recompensa al jugador
        giveRandomReward(player)

        print("Recompensando a " .. player.PlayerData.name .. " con $" .. reward)
    end
end)

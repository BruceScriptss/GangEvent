local QBCore = exports['qb-core']:GetCoreObject()

-- Variables globales
local locations = {
    {coords = vector3(219.1, 391.26, 104.96), name = "Ubicación 1"},
    {coords = vector3(259.23, 377.55, 103.73), name = "Ubicación 2"},
    {coords = vector3(218.02, 343.15, 104.6), name = "Ubicación 3"}
}

local correctLocationIndex
local isRewarded = false
local isSearching = false
local blips = {}
local participatingGangs = {}
local activityStarted = false
local joinTimer = 60 -- Temporizador de 1 minuto para unirse a la actividad

-- Función para crear un blip
local function createBlip(coords, sprite, color, text)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    table.insert(blips, blip) -- Guardar el blip en la tabla
end

-- Función para eliminar todos los blips
local function removeAllBlips()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip)
    end
    blips = {}
end

-- Función para reiniciar la actividad
local function resetAct()
    isSearching = false
    isRewarded = false
    correctLocationIndex = nil
    removeAllBlips()
    participatingGangs = {}
    activityStarted = false
    joinTimer = 60
end

-- Función para iniciar la actividad real
local function startActualCargoActivity()
    isSearching = true

    for _, location in ipairs(locations) do
        createBlip(location.coords, 1, 2, location.name)
    end

    Citizen.CreateThread(function()
        while isSearching do
            Wait(0)

            for i, location in ipairs(locations) do
                DrawMarker(21, location.coords.x, location.coords.y, location.coords.z + 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false, false, false, false, false)

                local playerCoords = GetEntityCoords(GetPlayerPed(-1))
                local distance = #(playerCoords - location.coords)

                if distance < 2.0 and not isRewarded then
                    DrawText3D(location.coords.x, location.coords.y, location.coords.z + 2.0, "[E] Para revisar")

                    if IsControlJustReleased(0, 38) then
                        QBCore.Functions.Progressbar("checking_location", "Revisando ubicación...", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true
                        }, {}, {}, {}, function()
                            -- Lógica de búsqueda...
                            if i == correctLocationIndex then
                                local Player = QBCore.Functions.GetPlayerData()
                                local gangName = Player.gang.name -- Obtener el nombre de la organización
                                local citizenId = Player.citizenid

                                -- Si se encontró la mercancía:
                                QBCore.Functions.Notify("¡Has encontrado la ubicación correcta!", "success")
                                isRewarded = true
                                TriggerServerEvent('qb-gangevent:announceVictory', gangName,citizenId)
                                resetAct()
                            else
                                QBCore.Functions.Notify("Esta no es la ubicación correcta.", "error")
                            end
                        end, function()
                            QBCore.Functions.Notify("Revisión cancelada.", "error")
                        end)
                    end
                end
            end
        end
    end)
end

-- Iniciar la actividad
local function startCargoActivity()
    if activityStarted then
        QBCore.Functions.Notify("La actividad ya ha comenzado.", "error")
        return
    end

    activityStarted = true
    correctLocationIndex = math.random(1, #locations)
    isRewarded = false
    isSearching = false

    TriggerServerEvent('qb-gangevent:notifyAllGangs', "¡Una nueva actividad de búsqueda de carga ha comenzado! Usa /joinAct para participar.")

    Citizen.CreateThread(function()
        for i = joinTimer, 0, -1 do
            Wait(1000)
            TriggerEvent('chat:addMessage', {
                color = {255, 0, 0},
                multiline = true,
                args = {"Sistema", "Tiempo para unirse a la actividad: " .. i .. " segundos."}
            })
            if i == 0 then
                QBCore.Functions.Notify("El tiempo para unirse a la actividad ha terminado.", "error")
                if next(participatingGangs) then
                    startActualCargoActivity()
                else
                    QBCore.Functions.Notify("No hay bandas participantes en la actividad.", "error")
                    resetAct()
                end
                break
            end
        end
    end)
end

-- Función para unirse a la actividad
RegisterCommand("joinAct", function()
    local Player = QBCore.Functions.GetPlayerData()
    local gangName = Player.gang.name -- Nombre de la banda real

    if not activityStarted then
        QBCore.Functions.Notify("La actividad no ha comenzado. Usa /startCargo primero.", "error")
        return
    end

    if not participatingGangs[gangName] then
        participatingGangs[gangName] = true
        QBCore.Functions.Notify("Te has unido a la actividad de búsqueda de carga.", "success")
        TriggerServerEvent('qb-gangevent:joinActivity', gangName)
    else
        QBCore.Functions.Notify("Ya estás participando en esta actividad.", "error")
    end
end, false)


-- Comando para iniciar la actividad
RegisterCommand("startCargo", function()
    startCargoActivity()
end, false)

-- Función para dibujar texto en 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamRelativePitch()
    local scale = 0.35 * (1 + p / 40)
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

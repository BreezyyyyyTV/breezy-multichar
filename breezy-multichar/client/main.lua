local cam = nil
local charPed = nil
local QBCore = exports['qb-core']:GetCoreObject()
isTrainMoving = false 

-- Main Thread

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if NetworkIsSessionStarted() then
			TriggerEvent('breezy-multichar:client:chooseChar')
			return
		end
	end
end)

-- Functions



local function skyCam(bool)
    TriggerEvent('qb-weathersync:client:DisableSync')
    if bool then
        DoScreenFadeIn(1000)
        SetTimecycleModifier('hud_def_blur')
        SetTimecycleModifierStrength(1.0)
        FreezeEntityPosition(PlayerPedId(), false)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0 ,0.0, Config.CamCoords.w, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    else
        SetTimecycleModifier('default')
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
        deleteTrain()
    end
end

local function openCharMenu(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "ui",
        toggle = bool,
    })
    skyCam(bool)
end

-- Events

RegisterNetEvent('breezy-multichar:client:closeNUIdefault', function() -- This event is only for no starting apartments
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Citizen.Wait(2000)
    SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    Citizen.Wait(500)
    openCharMenu()
    SetEntityVisible(PlayerPedId(), true)
    Citizen.Wait(500)
    DoScreenFadeIn(250)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('breezy-multichar:client:closeNUI', function()
    SetNuiFocus(false, false)
end)



local function DisableHudIcons()
    --exports['textUi']:DrawTextUi('hide')   
    TriggerEvent('qb-hud:client:ToggleBugMode', false)
    TriggerEvent('qb-hud:client:ToggleDevMode', false) 
    TriggerEvent('qb-hud:client:ToggleWeaponMode', false) 
    TriggerEvent('qb-hud:client:ToggleDrunkMode', false) 
end

RegisterNetEvent('breezy-multichar:client:chooseChar', function()
   DisableHudIcons() 
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Citizen.Wait(1000)
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Citizen.Wait(1000)
    end
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Citizen.Wait(1500)
    ShutdownLoadingScreen() 
    ShutdownLoadingScreenNui()
    spawnTrain()
    openCharMenu(true)
end)

-- NUI Callbacks

RegisterNUICallback('closeUI', function()
    openCharMenu(false)
end)

RegisterNUICallback('disconnectButton', function()
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    deleteTrain()
    TriggerServerEvent('breezy-multichar:server:disconnect')
end)

RegisterNUICallback('selectCharacter', function(data)
    local cData = data.cData
    DoScreenFadeOut(10)
    TriggerServerEvent('breezy-multichar:server:loadUserData', cData)
    openCharMenu(false)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
end)

RegisterNUICallback('cDataPed', function(data)
    local cData = data.cData  
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if cData ~= nil then
        QBCore.Functions.TriggerCallback('breezy-multichar:server:getSkin', function(model, data)
            model = model ~= nil and tonumber(model) or false
            if model ~= nil then
                Citizen.CreateThread(function()
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Citizen.Wait(0)
                    end
                    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
                    local  RandomAnimins = {     
                        "WORLD_HUMAN_HANG_OUT_STREET",
                        "WORLD_HUMAN_STAND_IMPATIENT",
                        "WORLD_HUMAN_STAND_MOBILE",
                        "WORLD_HUMAN_SMOKING_POT",
                        "WORLD_HUMAN_LEANING",
                        "WORLD_HUMAN_DRUG_DEALER_HARD"
                    }
                    local PlayAnimin = RandomAnimins[math.random(#RandomAnimins)] 
                    SetPedCanPlayAmbientAnims(charPed, true)
                    TaskStartScenarioInPlace(charPed, PlayAnimin, 0, true)
                    SetPedComponentVariation(charPed, 0, 0, 0, 2)
                    FreezeEntityPosition(charPed, false)
                    SetEntityInvincible(charPed, true)
                    PlaceObjectOnGroundProperly(charPed)
                    SetBlockingOfNonTemporaryEvents(charPed, true)
                    data = json.decode(data)
                    TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
                end)
            else
                Citizen.CreateThread(function()
                    local randommodels = {
                        "mp_m_freemode_01",
                        "mp_f_freemode_01",
                        -- "np_m_character_select",
                        -- "np_f_character_select",
                    }
                    local model = GetHashKey(randommodels[math.random(1, #randommodels)])
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Citizen.Wait(0)
                    end
                    charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
                    SetPedComponentVariation(charPed, 0, 0, 0, 2)
                    FreezeEntityPosition(charPed, false)
                    SetEntityInvincible(charPed, true)
                    PlaceObjectOnGroundProperly(charPed)
                    SetBlockingOfNonTemporaryEvents(charPed, true)
                end)
            end
        end, cData.citizenid)
    else
        Citizen.CreateThread(function()
            local randommodels = {
                "mp_m_freemode_01",
                "mp_f_freemode_01",
                -- "np_m_character_select",
                -- "np_f_character_select",
            }
            local model = GetHashKey(randommodels[math.random(1, #randommodels)])
            RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(0)
            end
            charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98, Config.PedCoords.w, false, true)
            SetPedComponentVariation(charPed, 0, 0, 0, 2)
            FreezeEntityPosition(charPed, false)
            SetEntityInvincible(charPed, true)
            PlaceObjectOnGroundProperly(charPed)
            SetBlockingOfNonTemporaryEvents(charPed, true)
        end)
    end
end)

RegisterNUICallback('setupCharacters', function()
    QBCore.Functions.TriggerCallback("breezy-multichar:server:setupCharacters", function(result)
        SendNUIMessage({
            action = "setupCharacters",
            characters = result
        })
    end)
end)

RegisterNUICallback('removeBlur', function()
    SetTimecycleModifier('default')
end)

RegisterNUICallback('createNewCharacter', function(data)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "Male" then
        cData.gender = 0
    elseif cData.gender == "Female" then
        cData.gender = 1
    end
    TriggerServerEvent('breezy-multichar:server:createCharacter', cData)
    Citizen.Wait(500)
end)

RegisterNUICallback('removeCharacter', function(data)
    TriggerServerEvent('breezy-multichar:server:deleteCharacter', data.citizenid)
    TriggerEvent('breezy-multichar:client:chooseChar')
    DeleteEntity(charPed)
end)







function spawnTrain()
	local tempmodel = GetHashKey("metrotrain")
	RequestModel(tempmodel)
	while not HasModelLoaded(tempmodel) do
		RequestModel(tempmodel)
		Citizen.Wait(0)
	end
    local coords = vector3(-3948.49,2036.35,499.1)
    vehicle = CreateVehicle(tempmodel, coords, 160.0, false, false)
    FreezeEntityPosition(vehicle, true)
    local heading = GetEntityHeading(vehicle)
    local coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -11.0, 0.0)
    vehicleBack = CreateVehicle(tempmodel, coords, 158.0, false, false)
    FreezeEntityPosition(vehicleBack, true)
    AttachEntityToEntity(vehicleBack , vehicle , 51 , 0.0, -11.0, 0.0, 180.0, 180.0, 0.0, false, false, false, false, 0, true)
    Citizen.CreateThread(function()
    	isTrainMoving = true
	    for i=1,100 do
	    	local posoffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 0.0, 0.0)
	    	local setpos = VecLerp(-3948.49,2036.35,499.1, -3957.58,2008.75, 499.1, i/100, true)
	    	SetEntityCoords(vehicle,setpos)
	  		Wait(15)
	    end
	    isTrainMoving = false
	end)
end

function deleteTrain()
	if vehicle ~= nil then
		DeleteEntity(vehicle)
		DeleteEntity(vehicleBack)
	end
end

function VecLerp(x1, y1, z1, x2, y2, z2, l, clamp)
    if clamp then
        if l < 0.0 then l = 0.0 end
        if l > 1.0 then l = 1.0 end
    end
    local x = Lerp(x1, x2, l)
    local y = Lerp(y1, y2, l)
    local z = Lerp(z1, z2, l)
    return vector3(x, y, z)
end

function Lerp(a, b, t)
    return a + (b - a) * t
end

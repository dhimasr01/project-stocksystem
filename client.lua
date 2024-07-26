local QBCore = exports['qb-core']:GetCoreObject()
local Config = Config or {}

-- Function to create NPC and setup qb-target
function CreateShopNPC()
    local pedModel = Config.NPC.model
    local pedHash = GetHashKey(pedModel)

    RequestModel(pedHash)
    while not HasModelLoaded(pedHash) do
        Wait(1)
    end

    local ped = CreatePed(4, pedHash, Config.NPC.coords, Config.NPC.heading, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "project-stock:openMenu",
                icon = "fas fa-shopping-basket",
                label = "Open Shop",
            },
        },
        distance = 2.5,
    })
    
    if Config.NPC.blip then
        -- Create Blip
        local blip = AddBlipForCoord(Config.NPC.coords)
        SetBlipSprite(blip, Config.NPC.blip.sprite)
        SetBlipColour(blip, Config.NPC.blip.color)
        SetBlipScale(blip, Config.NPC.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.NPC.blip.text)
        EndTextCommandSetBlipName(blip)
    else
        print("Blip configuration missing in Config.NPC")
    end

end



-- Example function to open shop menu
function OpenShopMenu()
    local shopItems = {
        {header = "Project Stock", isMenuHeader = true}, -- Header
        {header = "Buy Items", txt = "", params = {event = "project-stock:openBuyMenu"}},
        {header = "Sell Items", txt = "", params = {event = "project-stock:openSellMenu"}},
        {header = "Close", txt = "", params = {event = "qb-menu:client:closeMenu"}}
    }
    
    exports['qb-menu']:openMenu(shopItems)
end

-- Function to open buy menu
function OpenBuyMenu()
    -- Request stock data from server
    TriggerServerEvent('project-stock:getStock')
end

-- Function to open sell menu
function OpenSellMenu()
    local sellItems = {
        {header = "Sell Items", isMenuHeader = true}, -- Header
    }

    for item, info in pairs(Config.Items) do
        table.insert(sellItems, {
            header = info.label,
            txt = "$" .. info.sellPrice .. " each",
            params = {event = "project-stock:selectQuantity", args = {type = "sell", item = item, price = info.sellPrice}}
        })
    end

    table.insert(sellItems, {header = "Back", txt = "", params = {event = "project-stock:openMenu"}})
    
    exports['qb-menu']:openMenu(sellItems)
end

-- Function to select quantity
RegisterNetEvent('project-stock:selectQuantity', function(data)
    local type = data.type
    local item = data.item
    local price = data.price

    local dialog = exports['qb-input']:ShowInput({
        header = 'Select Quantity',
        submitText = 'Submit',
        inputs = {
            {
                text = 'Quantity', -- text you want to be displayed as a place holder
                name = 'quantity', -- name of the input should be unique otherwise it might override
                type = 'number', -- type of the input
                isRequired = true -- If it is required or not
            }
        }
    })
    
    if dialog ~= nil then
        local quantity = tonumber(dialog.quantity)
        if quantity > 0 then
            if type == "buy" then
                TriggerServerEvent('project-stock:buyItem', {item = item, price = price, quantity = quantity})
            else
                TriggerServerEvent('project-stock:sellItem', {item = item, price = price, quantity = quantity})
            end
        else
            QBCore.Functions.Notify('Invalid quantity', 'error')
        end
    end
end)

-- Event to receive stock data from server and open buy menu
RegisterNetEvent('project-stock:receiveStock', function(stockData)
    local buyItems = {
        {header = "Buy Items", isMenuHeader = true}, -- Header
    }
    
    for item, info in pairs(Config.Items) do
        local stock = stockData[item] or 0
        table.insert(buyItems, {
            header = info.label,
            txt = "$" .. info.buyPrice .. " each (Stock: " .. stock .. ")",
            params = {event = "project-stock:selectQuantity", args = {type = "buy", item = item, price = info.buyPrice}}
        })
    end
    
    table.insert(buyItems, {header = "Back", txt = "", params = {event = "project-stock:openMenu"}})
    
    exports['qb-menu']:openMenu(buyItems)
end)

-- Create NPC when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CreateShopNPC()
    end
end)

-- Create NPC when player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateShopNPC()
end)

-- Event to open shop menu
RegisterNetEvent('project-stock:openMenu', function()
    OpenShopMenu()
end)

-- Event to open buy menu
RegisterNetEvent('project-stock:openBuyMenu', function()
    OpenBuyMenu()
end)

-- Event to open sell menu
RegisterNetEvent('project-stock:openSellMenu', function()
    OpenSellMenu()
end)

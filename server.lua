local QBCore = exports['qb-core']:GetCoreObject()
local Config = Config or {}

-- Fungsi untuk inisialisasi item di database
local function InitializeItems()
    for itemName, itemData in pairs(Config.Items) do
        MySQL.Async.fetchScalar('SELECT COUNT(*) FROM stocksystem WHERE item = @item', {
            ['@item'] = itemName
        }, function(count)
            if count == 0 then
                MySQL.Async.execute('INSERT INTO stocksystem (item, stock) VALUES (@item, @stock)', {
                    ['@item'] = itemName,
                    ['@stock'] = 0
                })
                print("Added item: " .. itemName .. " to the database.")
            end
        end)
    end
end

-- Event untuk menangani pembelian item
RegisterServerEvent('project-stock:buyItem')
AddEventHandler('project-stock:buyItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = data.item
    local price = data.price
    local quantity = data.quantity
    local totalCost = price * quantity
    local money = Player.Functions.GetMoney('cash')

    MySQL.Async.fetchScalar('SELECT stock FROM stocksystem WHERE item = @item', {
        ['@item'] = item
    }, function(stock)
        if stock and stock >= quantity then
            if money >= totalCost then
                Player.Functions.RemoveMoney('cash', totalCost)
                Player.Functions.AddItem(item, quantity)
                MySQL.Async.execute('UPDATE stocksystem SET stock = stock - @quantity WHERE item = @item', {
                    ['@item'] = item,
                    ['@quantity'] = quantity
                })
                TriggerClientEvent('QBCore:Notify', src, 'You bought ' .. quantity .. ' ' .. item .. ' for $' .. totalCost, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You do not have enough money', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Not enough stock', 'error')
        end
    end)
end)

-- Event untuk menangani penjualan item
RegisterServerEvent('project-stock:sellItem')
AddEventHandler('project-stock:sellItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local item = data.item
    local price = data.price
    local quantity = data.quantity
    local totalPrice = price * quantity
    local itemCount = Player.Functions.GetItemByName(item)

    if itemCount and itemCount.amount >= quantity then
        Player.Functions.RemoveItem(item, quantity)
        Player.Functions.AddMoney('cash', totalPrice)
        MySQL.Async.execute('UPDATE stocksystem SET stock = stock + @quantity WHERE item = @item', {
            ['@item'] = item,
            ['@quantity'] = quantity
        })
        TriggerClientEvent('QBCore:Notify', src, 'You sold ' .. quantity .. ' ' .. item .. ' for $' .. totalPrice, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You do not have enough items to sell', 'error')
    end
end)

-- Event untuk mendapatkan data stok
RegisterServerEvent('project-stock:getStock')
AddEventHandler('project-stock:getStock', function()
    local src = source
    MySQL.Async.fetchAll('SELECT item, stock FROM stocksystem', {}, function(result)
        local stockData = {}
        for i=1, #result, 1 do
            stockData[result[i].item] = result[i].stock
        end
        TriggerClientEvent('project-stock:receiveStock', src, stockData)
    end)
end)

-- Inisialisasi item di database saat resource dimulai
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        InitializeItems()
    end
end)

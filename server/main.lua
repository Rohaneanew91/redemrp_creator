RedEM = exports["redem_roleplay"]:RedEM()


-- Begin conversion commands & events
-- These three commands &  events are to convert beards, hair & teeth indexes in your database into hashes. Remove them & their accompanying client events if you do not intend to convert them. They are optional and exist only to make other creators lives a little easier when making character creation scripts.
RegisterCommand("fixOldBeards", function(src, args, raw)
    MySQL.query("SELECT * FROM skins", {}, function(results)
        TriggerClientEvent("fixOldBeards:doConversion", src, results)
    end)
end)

RegisterNetEvent("fixOldBeards:saveConverted")
AddEventHandler("fixOldBeards:saveConverted", function(updates)
    for _, record in ipairs(updates) do
        MySQL.update("UPDATE skins SET skin = ? WHERE id = ?", { record.json, record.id })
    end
    print("Fix Old Beards Complete")
end)

RegisterCommand("fixOldHair", function(src, args, raw)
    MySQL.query("SELECT * FROM skins", {}, function(results)
        TriggerClientEvent("fixOldHair:doConversion", src, results)
    end)
end)

RegisterNetEvent("fixOldHair:saveConverted")
AddEventHandler("fixOldHair:saveConverted", function(updates)
    for _, record in ipairs(updates) do
        MySQL.update("UPDATE skins SET skin = ? WHERE id = ?", { record.json, record.id })
    end
    print("Fix Old Hair Complete")
end)

RegisterCommand("fixOldTeeth", function(src, args, raw)
    MySQL.query("SELECT * FROM skins", {}, function(results)
        TriggerClientEvent("fixOldTeeth:doConversion", src, results)
    end)
end)

RegisterNetEvent("fixOldTeeth:saveConverted")
AddEventHandler("fixOldTeeth:saveConverted", function(updates)
    for _, record in ipairs(updates) do
        MySQL.update("UPDATE skins SET skin = ? WHERE id = ?", { record.json, record.id })
    end
    print("Fix Old Teeth Complete")
end)
-- End Conversion Commands

RegisterServerEvent('rdr_creator:SaveSkin', function(skin)
    local _source = source
    local encode = json.encode(skin)
    local user = RedEM.GetPlayer(_source)
    if user then
        MySQL.query("SELECT * FROM skins WHERE `identifier`=@identifier AND `charid`=@charid;", {identifier = user.identifier, charid = user.charid}, function(skins)
            if skins[1] then
                MySQL.update("UPDATE skins SET `skin`=@skin WHERE `identifier`=@identifier AND `charid`=@charid", {skin = encode, identifier = user.identifier, charid = user.charid})
            else
                MySQL.update("INSERT INTO skins (`identifier`, `charid`, `skin`) VALUES (@identifier, @charid, @skin);", { identifier = user.identifier, charid = user.charid, skin = encode })
            end
        end)
    end
end)

RegisterServerEvent("rdr_creator:server:TryCreator", function()
    local _source = source
    local user = RedEM.GetPlayer(_source)    
    if user then
        if user.money >= 30 then
            user.RemoveMoney(30)
            TriggerClientEvent("rdr_creator:OpenCreator",_source)
        end
    end
end)

RegisterServerEvent('rdr_creator:SaveHair', function(hair, beard)
    local _source = source
    local user = RedEM.GetPlayer(_source)    
    if user then
        MySQL.query("SELECT * FROM skins WHERE `identifier`=@identifier AND `charid`=@charid;", {identifier = user.identifier, charid = user.charid}, function(skins)
            if skins[1] then
                local skin = skins[1].skin
                if skin then
                    local decoded = json.decode(skin)
                    decoded.hair = hair
                    decoded.beard = beard
                    MySQL.update("UPDATE skins SET `skin`=@skin WHERE `identifier`=@identifier AND `charid`=@charid", {skin = json.encode(decoded), identifier = user.identifier, charid = user.charid})
                end
            end
        end)
    end
end)

RegisterServerEvent('RedEM:server:LoadSkin', function(isCommand)
    local _source = source
    local user = RedEM.GetPlayer(_source)
    if user then
        MySQL.query("SELECT * FROM skins WHERE `identifier`=@identifier AND `charid`=@charid;", {identifier = user.identifier, charid = user.charid}, function(skins)
            if skins[1] then
                local skin = skins[1].skin
                local decoded = json.decode(skin)
                if isCommand then
                    TriggerClientEvent("RedEM:client:ApplySkinCommand", _source, decoded)
                else
                    TriggerClientEvent("RedEM:client:ApplySkin", _source, decoded)
                end
            else
                TriggerClientEvent("rdr_creator:OpenCreator",_source)
            end
        end)
    end
end)

RegisterServerEvent('rdr_creator:SetPlayerBucket', function(b)
    local _source = source
    SetPlayerRoutingBucket(_source, b)
end)

RegisterServerEvent("RedEM:server:DeleteSkin", function(charid)
    local _source = source
    local id = RedEM.Functions.GetIdentifier(_source, "steam")
    MySQL.query("DELETE FROM skins WHERE `identifier`=@identifier AND `charid`=@charid;", {identifier = id, charid = charid})
end)

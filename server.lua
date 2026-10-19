-- Alleen serverconsole, zonder spelers en met schrijvende resources gestopt.
-- Eerst databaseback-up maken. "controle" schrijft niets; "uitvoeren" is transactioneel.
local running = false
local blockedResources = {'ts_nlplates', 'ox_inventory', 'jg-dealerships', 'jg-advancedgarages',
    'MrNewbVehicleKeys', 'es_extended'}
local function quoted(name) return '`' .. name:gsub('`', '``') .. '`' end
local function normalize(s) return s:match('^%s*(.-)%s*$'):upper() end
local plateNames = {plate=true, vehicleplate=true, vehicle_plate=true, license_plate=true, licenseplate=true}
local jsonFields = {
    owned_vehicles = {vehicle=true, glovebox=true, trunk=true},
    users = {inventory=true},
    ox_inventory = {data=true},
}

RegisterCommand('ts_nlplates_spaties', function(src, args)
    if src ~= 0 then return end
    if running then return print('[migratie] Er loopt al een opdracht.') end
    if args[1] ~= 'controle' and args[1] ~= 'uitvoeren' then
        return print('[migratie] Gebruik: ts_nlplates_spaties controle | uitvoeren')
    end
    if #GetPlayers() > 0 then return print('[migratie] STOP: er zijn spelers online.') end
    for _, name in ipairs(blockedResources) do
        local state = GetResourceState(name)
        if state == 'started' or state == 'starting' then
            return print('[migratie] STOP: stop eerst resource ' .. name)
        end
    end
    running = true
    local ok, err = pcall(function()
        local schema = MySQL.query.await([[
            SELECT c.TABLE_NAME AS tbl, c.COLUMN_NAME AS col, c.DATA_TYPE AS kind, t.ENGINE AS engine
            FROM information_schema.COLUMNS c
            JOIN information_schema.TABLES t ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
            WHERE c.TABLE_SCHEMA = DATABASE() AND t.TABLE_TYPE = 'BASE TABLE'
        ]])
        local tables, plateColumns, textColumns = {}, {}, {}
        for _, c in ipairs(schema) do
            tables[c.tbl] = tables[c.tbl] or {}
            tables[c.tbl][c.col] = c
            if plateNames[c.col:lower()] then plateColumns[#plateColumns+1] = c end
            local keyTable = c.tbl:lower():find('key',1,true) or c.tbl:lower():find('lock',1,true)
            local isText = c.kind == 'json' or c.kind:find('text',1,true) or c.kind == 'varchar'
            if isText and ((jsonFields[c.tbl] and jsonFields[c.tbl][c.col]) or keyTable) then
                textColumns[#textColumns+1] = c
            end
        end
        assert(tables.owned_vehicles and tables.owned_vehicles.plate and tables.owned_vehicles.vehicle,
            'owned_vehicles/plate/vehicle ontbreekt')
        local mapping = {}
        for _, name in ipairs({'owned_vehicles','ts_nlplates_numbers','ts_nlplates_documents','ts_nlplates_business_vehicles'}) do
            if tables[name] and tables[name].plate then
                local rows = MySQL.query.await('SELECT DISTINCT plate FROM ' .. quoted(name))
                for _, row in ipairs(rows) do
                    local old = normalize(row.plate or '')
                    if old:match('^[A-Z]%-%d%d%d%-[A-Z][A-Z]$') then
                        mapping[old] = old:gsub('%-', ' ')
                    end
                end
            end
        end
        local plan, count = {}, 0
        local function add(column, query, values)
            assert(column.engine == 'InnoDB', 'Tabel ' .. column.tbl .. ' is niet InnoDB; geen veilige rollback mogelijk')
            plan[#plan+1] = {query=query, values=values}
        end
        for old, new in pairs(mapping) do
            count = count + 1
            print(('[migratie] %s -> %s'):format(old,new))
            for _, c in ipairs(plateColumns) do
                local tableName, col = quoted(c.tbl), quoted(c.col)
                local existing = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. tableName .. ' WHERE ' .. col .. ' = ?', {old})
                if tonumber(existing) > 0 then
                    local conflict = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. tableName .. ' WHERE ' .. col .. ' = ?', {new})
                    assert(tonumber(conflict) == 0, 'Kentekenbotsing in ' .. c.tbl .. '.' .. c.col .. ': ' .. new)
                    add(c, 'UPDATE ' .. tableName .. ' SET ' .. col .. ' = ? WHERE ' .. col .. ' = ?', {new,old})
                end
            end
            for _, c in ipairs(textColumns) do
                local t, col = quoted(c.tbl), quoted(c.col)
                -- Exacte JSON-stringwaarden én JSON-sleutels; geen willekeurige tekstvervanging.
                local oldToken, newToken = '"' .. old .. '"', '"' .. new .. '"'
                local matches = MySQL.scalar.await('SELECT COUNT(*) FROM ' .. t .. ' WHERE LOCATE(?, ' .. col .. ') > 0', {oldToken})
                if tonumber(matches) > 0 then
                    add(c,'UPDATE ' .. t .. ' SET ' .. col .. ' = REPLACE(' .. col .. ', ?, ?) WHERE LOCATE(?, ' .. col .. ') > 0',
                        {oldToken,newToken,oldToken})
                end
            end
            -- Vehicle props blijven gelijk aan de primaire kentekenkolom, ook als props afweken.
            local c = tables.owned_vehicles.vehicle
            local invalid = MySQL.scalar.await(
                'SELECT COUNT(*) FROM owned_vehicles WHERE plate = ? AND (vehicle IS NULL OR JSON_VALID(vehicle) = 0)', {old})
            assert(tonumber(invalid) == 0, 'Ongeldige vehicle-JSON voor ' .. old)
            add(c, "UPDATE owned_vehicles SET vehicle = JSON_SET(vehicle, '$.plate', ?) WHERE plate = ?", {new,new})
            if tables.ox_inventory and tables.ox_inventory.name then
                for _, prefix in ipairs({'glove','trunk'}) do
                    local oldName, newName = prefix .. old, prefix .. new
                    local found = MySQL.scalar.await('SELECT COUNT(*) FROM ox_inventory WHERE name = ?', {oldName})
                    if tonumber(found) > 0 then
                        local conflict = MySQL.scalar.await('SELECT COUNT(*) FROM ox_inventory WHERE name = ?', {newName})
                        assert(tonumber(conflict) == 0, 'Stash bestaat al: ' .. newName)
                        add(tables.ox_inventory.name,'UPDATE ox_inventory SET name = ? WHERE name = ?', {newName,oldName})
                    end
                end
            end
        end
        if count == 0 then return print('[migratie] Geen oude ts_nlplates-kentekens gevonden.') end
        print(('[migratie] %s kentekens, %s updates. Spelers en resources moeten gestopt blijven.'):format(count,#plan))
        print('[migratie] Meegenomen: plate-kolommen, ESX voertuig-JSON, inventarissen en JSON-stringwaarden in key/lock-tabellen.')
        print('[migratie] Niet meegenomen: KVP-bestanden, hashes, versleutelde of externe opslag. Controleer zulke koppelingen afzonderlijk.')
        if args[1] == 'controle' then return print('[migratie] Controle klaar; niets gewijzigd. Maak een databaseback-up voordat je uitvoert.') end
        assert(MySQL.transaction.await(plan), 'Transactie mislukt; databasewijzigingen teruggedraaid')
        print('[migratie] Omzetting geslaagd. Herstart nu de volledige server; verwijder deze hulpresource uit server.cfg.')
    end)
    running = false
    if not ok then print('[migratie] AFGEBROKEN: ' .. tostring(err)) end
end, false)

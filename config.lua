Config = {}
Config.Version = '1.0.0'
Config.Command = 'ts_nlplates_spaties'
-- Deze resources mogen tijdens controle en uitvoering niet actief zijn.
-- Voeg eigen garages, sleutel- en andere database-schrijvende resources toe.
Config.BlockedResources = {
    'ts_nlplates', 'ox_inventory', 'jg-dealerships', 'jg-advancedgarages',
    'MrNewbVehicleKeys', 'es_extended'
}
Config.SourceTables = {'owned_vehicles', 'ts_nlplates_numbers', 'ts_nlplates_documents', 'ts_nlplates_business_vehicles'}
Config.PlateColumns = {plate=true, vehicleplate=true, vehicle_plate=true, license_plate=true, licenseplate=true}
Config.JsonFields = {
    owned_vehicles = {vehicle=true, glovebox=true, trunk=true},
    users = {inventory=true},
    ox_inventory = {data=true},
}
-- Tekstkolommen in tabellen met deze woorden worden ook gecontroleerd.
Config.KeyTableTerms = {'key', 'lock'}
Config.StashPrefixes = {'glove', 'trunk'}

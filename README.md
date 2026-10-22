# ts_nlplates_migrate 1.0.1

Eenmalige offline hulpresource voor oude ts_nlplates-kentekens zoals `A-123-BC`.
Zet deze om naar `A 123 BC`. Maakt geen nieuwe kentekens aan en is geen
vervanging voor ts_nlplates. Configversie: 1.0.0.

## Gebruik

1. Maak een volledige databaseback-up en plan onderhoud. Blokkeer nieuwe
   verbindingen via je hosting/onderhoudsinstellingen; alleen spelers kicken is niet genoeg.
2. Laat alle spelers vertrekken. Stop ESX, inventory, garages, dealership,
   sleutels en alle overige resources/processen die voertuiggegevens schrijven.
3. Controleer `config.lua`: voeg eigen schrijvende resources toe aan
   `BlockedResources`. De lijst kan externe databaseprocessen niet detecteren.
4. Laat oxmysql actief. Plaats deze volledige map als `ts_nlplates_migrate`
   en start hem handmatig vanuit de serverconsole.
5. Voer `ts_nlplates_spaties controle` uit in de serverconsole. Dit leest alleen.
   Los eventuele botsingen of ongeldige gegevens eerst op en controleer opnieuw.
6. Voer na controle en back-up `ts_nlplates_spaties uitvoeren` uit.
7. Controleer het resultaat en herstart de volledige server. Haal deze
   tijdelijke hulpresource uit je automatische startlijst.

Er wordt nooit automatisch gemigreerd bij het starten. Spelers kunnen de
commando's niet uitvoeren. `Config.Command` kan de commandonaam wijzigen.

## Bereik en grenzen

Bronkentekens komen uit `SourceTables`. Kolommen met namen uit `PlateColumns`
worden databasebreed gecontroleerd. `JsonFields` selecteert inventaris- en
voertuiggegevens; tekstkolommen in tabellen met `KeyTableTerms` worden eveneens
onderzocht. `StashPrefixes` bepaalt de ox_inventory-stashnamen.
`owned_vehicles.plate` en `owned_vehicles.vehicle` blijven verplicht voor ESX.

De migratie verwerkt exacte, ongeëscapete JSON-tokens voor de oude kentekens.
KVP, hashes, versleutelde gegevens, anders gecodeerde JSON-tokens, afwijkende
hoofdletters/spaties in verwijzingen en externe opslag worden niet volledig
afgedekt. Controleer eigen integraties afzonderlijk. Niet-canonieke bronkentekens
worden geweigerd zodat ze niet stilzwijgend gedeeltelijk worden verwerkt.

Wijzigingen gaan in één oxmysql-transactie. Betrokken tabellen moeten InnoDB
gebruiken. Kenteken- en stashbotsingen breken de planning af. De resource
controleert spelers en actieve resources aan het begin én vlak vóór uitvoering.
Dit is geen databasebrede vergrendeling: houd onderhoud actief tot de herstart.

## Bridge

Geen ts_bridge- of ESX-afhankelijkheid toegevoegd: deze onderhoudstool moet
juist kunnen draaien terwijl de normale schrijvende resources gestopt zijn.
Alleen oxmysql is vereist. Er is geen periodieke versiecheck nodig voor deze
handmatig gebruikte, tijdelijke resource.

## Wijzigingen 1.0.1

- Instellingen gecentraliseerd in config.lua met versie- en structuurcontrole.
- Tweede offlinecontrole vóór de transactie; ook stoppende resources blokkeren.
- Niet-canonieke bronkentekens expliciet geweigerd.
- Eigen installatiehandleiding in plaats van de oude bundelhandleiding.

## Tests

Tests gebruiken nagebootste FiveM/oxmysql-functies. Ze controleren toegang,
controlemodus, offlinevoorwaarden, planning, botsingen en transactiefouten.
Geen echte FiveM/MySQL-migratie uitgevoerd. Test op een databasekopie voordat je
productiegegevens migreert.

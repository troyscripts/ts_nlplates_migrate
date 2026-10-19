# Volledig GitHub-releasepakket

- ts_nlplates 1.0.6 — volledig, inclusief client/server, SQL, HTML, textures, streambestand, itemicoon, webhookconfig en voertuigmodeltabel.
- ts_bridge 1.0.2 — volledig, inclusief bestaande functies, voertuigadapters, kaart-PNG-renderer en webhooktransport.
- ts_nlplates_migrate — optionele eenmalige hulp voor oude streepjeskentekens.

## Uploaden

Upload de INHOUD van ts_nlplates naar de root van jouw ts_nlplates-repository. Upload de INHOUD van ts_bridge naar de root van jouw bestaande bridge-repository (de checker gebruikt troyscripts/ts_brigde). De serverresourcenaam blijft ts_bridge. Er is niets door ons gepubliceerd; dit is het pakket om zelf te uploaden.

De migratiehulp kan als extra download bij de nlplates-release worden aangeboden. De runtime-resources hoeven niet in één repository. Beide READMEs en installatiehandleidingen zijn ook zelfstandig leesbaar.

De standaardconfiguraties bevatten geen ingevulde webhook-URLs. Houd deze openbare templates leeg en stel echte URLs alleen op je server in. Neem bij bijwerken je eigen prijs, providers en andere instellingen over. Beide resourceversies zijn ongewijzigd ten opzichte van de laatst werkende webhookupdate; configschema's zijn nlplates 1.0.3 en bridge 0.0.6.

JG, ox_inventory, ESX en MrNewbVehicleKeys zijn externe dependencies en worden niet meegepubliceerd. De vereiste wijzigingen staan als snippets in de nlplates-README. Het itemicoon en itemfragment staan in ts_nlplates/install.

## Validatie

De gebruiker heeft bevestigd dat de modelafbeelding-webhook werkt. Voor deze bundeling is de runtimecode behouden; alleen documentatie, lege centrale webhookroutes en installatiebestanden zijn bijgewerkt. De bestaande lokale syntax-, renderer-, routing- en fallbacktests zijn gebruikt. Er is geen nieuwe live servertest of GitHub-publicatie uitgevoerd.

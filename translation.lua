Translate = function(locale, ...)
    if ... then
        return Translation[Config.Locale][locale]:format(...)
    end
    
    return Translation[Config.Locale][locale]
end

Translation = {
    ['de'] = {
        -- General
        ['no_player_nearby'] = 'Kein Spieler in der Nähe',
        ['no_vehicle_nearby'] = 'Kein Fahrzeug in der Nähe',
        ['no_item_found'] = 'Du hast nicht das benötigte Item',
        ['no_permissions'] = 'Du hast keine Berechtigung dafür!',
        ['not_vehicle_owner'] = 'Das Fahrzeug gehört dir nicht!',
        ['refreshed_keys'] = 'Du hast deine Schlüssel aktualisiert',
        ['key_added'] = 'Du hast einen Schlüssel für das Kennzeichen %s erhalten',
        ['key_removed'] = 'Dir wurde der Schlüssel für das Kennzeichen %s entfernt',
        ['exchange_success'] = 'Die Fahrzeugschlösser wurden erfolgreich ausgetauscht',
        ['not_in_distance'] = 'Das Fahrzeug ist nicht in Reichweite',
        ['not_in_distance_plate'] = 'Das Fahrzeug mit dem Kennzeichen ~g~%s~s~ ist nicht in Reichweite',
        ['give_secondary_key'] = 'Du hast jemandem einen Zweitschlüssel für das Kennzeichen ~b~%s~s~ gegeben',
        ['give_key'] = 'Du hast jemandem deinen ~b~%s~s~ für das Kennzeichen ~b~%s~s~ gegeben',
        ['not_has_key'] = 'Du hast keinen Schlüssel für dieses Fahrzeug!',
        
        -- Targets
        ['(un)lock_vehicle'] = 'Fahrzeug auf-/ zuschließen',
        ['seat_dside_f'] = 'Fahrersitz einsteigen',
        ['seat_pside_f'] = 'Beifahrersitz einsteigen',
        ['seat_dside_r'] = 'Hinten Links einsteigen',
        ['seat_pside_r'] = 'Hinten Rechts einsteigen',
        ['seat_r'] = 'Ladefläche einsteigen',

        -- Key Names
        ['primary'] = 'Hauptschlüssel',
        ['secondary'] = 'Zweitschlüssel',
        ['temporary'] = 'Temporärer Schlüssel',

        -- Vehicle
        ['vehicle_lock'] = 'Fahrzeug ~b~%s~s~ mit dem Kennzeichen ~b~%s~s~ ~r~abgeschlossen~s~',
        ['vehicle_unlock'] = 'Fahrzeug ~b~%s~s~ mit dem Kennzeichen ~b~%s~s~ ~g~aufgeschlossen~s~',

        -- Menu Locksmith
        ['menu_open_locksmith'] = 'Drücke ~g~E~s~ um %s zu öffnen',
        ['menu_open_locksmith_textui'] = 'Drücke E um %s zu öffnen',
        ['menu_locksmith_title'] = 'Schlüsseldienst',
        ['menu_locksmith_exchangelocks'] = 'Fahrzeugschlösser austauschen',

        -- Menu Keys
        ['menu_vehicle_keys'] = 'Fahrzeugschlüssel',
        ['menu_primary_keys'] = 'Permanente Schlüssel',
        ['menu_secondary_keys'] = 'Zweit Schlüssel',
        ['menu_temporary_keys'] = 'Temporäre Schlüssel',
        ['menu_give_secondary_keys'] = 'Gebe Zweitschlüssel',
        ['menu_exchange_locks'] = 'Fahrzeugschlösser austauschen',
        ['menu_transfer_vehicle'] = 'Übergebe Fahrzeug',
        ['menu_no_keys_available'] = 'Keine Schlüssel gefunden',

        -- Dialog
        ['dialog_title'] = 'Verkaufe Fahrzeug: %s - %s',
        ['dialog_confirm'] = 'Bestätigen',
        ['dialog_cancel'] = 'Abbrechen',
        ['dialog_price'] = 'Preis',
        ['dialog_price_desc'] = 'Gebe den Fahrzeugpreis ein',
        ['diablog_buy_title'] = 'Fahrzeug Kaufen?',
        ['diablog_buy_desc'] = 'Möchtest du %s wirklich für $%s kaufen?',
        ['dialog_not_enough_money'] = 'Du hast nicht genug Geld auf dem Konto',
        ['dialog_not_enough_money2'] = 'Der Spieler hat nicht genug Geld auf dem Konto',
        ['transfer_seller_unavailable'] = 'Der Verkäufer ist nicht mehr verfügbar',
        ['transfer_too_far'] = 'Ihr seid zu weit voneinander entfernt',
    },
    ['en'] = {
        -- General
        ['no_player_nearby'] = 'No nearby Players found',
        ['no_vehicle_nearby'] = 'No nearby vehicles found',
        ['no_item_found'] = 'You don\'t have the required item',
        ['no_permissions'] = 'You don\'t have permission to do that!',
        ['not_vehicle_owner'] = 'The vehicle does not belong to you!',
        ['refreshed_keys'] = 'You have updated your keys',
        ['key_added'] = 'You have received a key for the license plate %s',
        ['key_removed'] = 'The key for the plate %s has been removed',
        ['exchange_success'] = 'The vehicle locks were successfully replaced',
        ['not_in_distance'] = 'The vehicle is not within range',
        ['not_in_distance_plate'] = 'The vehicle with the license plate ~g~%s~s~ is not within range',
        ['give_secondary_key'] = 'You have given someone a secondary key for the license plate ~b~%s~s~',
        ['give_key'] = 'You have given someone your ~b~%s~s~ for the license plate ~b~%s~s~',
        ['not_has_key'] = 'You don\'t have a key for this vehicle!',
        
        -- Targets
        ['(un)lock_vehicle'] = '(Un)lock Vehicle',
        ['seat_dside_f'] = 'Driver Seat entry',
        ['seat_pside_f'] = 'Passenger Seat entry',
        ['seat_dside_r'] = 'Left rear entry',
        ['seat_pside_r'] = 'Right rear entry',
        ['seat_r'] = 'Loading platform entry',

        -- Key Names
        ['primary'] = 'Primary Key',
        ['secondary'] = 'Secondary Key',
        ['temporary'] = 'Temporary Key',

        -- Vehicle
        ['vehicle_lock'] = 'Vehicle ~b~%s~s~ with license plate ~b~%s~s~ ~r~locked~s~',
        ['vehicle_unlock'] = 'Vehicle ~b~%s~s~ with license plate ~b~%s~s~ ~g~unlocked~s~',

        -- Menu Locksmith
        ['menu_open_locksmith'] = 'Press ~g~E~s~ to open %s',
        ['menu_open_locksmith_textui'] = 'Press E to open %s',
        ['menu_locksmith_title'] = 'Locksmith Service',
        ['menu_locksmith_exchangelocks'] = 'Exchange Vehicle Locks',

        -- Menu Keys
        ['menu_vehicle_keys'] = 'Vehicle Keys',
        ['menu_primary_keys'] = 'Primary Keys',
        ['menu_secondary_keys'] = 'Secondary Keys',
        ['menu_temporary_keys'] = 'Temporary Keys',
        ['menu_give_secondary_keys'] = 'Give Secondary Key',
        ['menu_exchange_locks'] = 'Exchange Locks',
        ['menu_transfer_vehicle'] = 'Transfer Vehicle',
        ['menu_no_keys_available'] = 'No Keys Available',

        -- Dialog
        ['dialog_title'] = 'Sell Vehicle: %s - %s',
        ['dialog_confirm'] = 'Confirm',
        ['dialog_cancel'] = 'Cancel',
        ['dialog_price'] = 'Price',
        ['dialog_price_desc'] = 'Insert Vehicle Price',
        ['diablog_buy_title'] = 'Buy Vehicle?',
        ['diablog_buy_desc'] = 'Do you want to buy %s for $%s?',
        ['dialog_not_enough_money'] = 'You don\'t have enough money in your Bankaccount',
        ['dialog_not_enough_money2'] = 'The player does not have enough money in his Bankaccount',
        ['transfer_seller_unavailable'] = 'The seller is no longer available',
        ['transfer_too_far'] = 'You are too far away from each other',
    },
    ['hu'] = {
        -- Általános
        ['no_player_nearby'] = 'Nem található közeli játékos',
        ['no_vehicle_nearby'] = 'Nem található közeli jármű',
        ['no_item_found'] = 'Nincs meg a szükséges tárgyad',
        ['no_permissions'] = 'Nincs jogosultságod ehhez!',
        ['not_vehicle_owner'] = 'Ez a jármű nem a tiéd!',
        ['refreshed_keys'] = 'A kulcsaid frissítve lettek',
        ['key_added'] = 'Kaptál egy kulcsot a rendszámhoz: %s',
        ['key_removed'] = 'A kulcs eltávolítva a rendszámról: %s',
        ['exchange_success'] = 'A jármű zárjai sikeresen kicserélve',
        ['not_in_distance'] = 'A jármű nincs hatótávolságon belül',
        ['not_in_distance_plate'] = 'A(z) ~g~%s~s~ rendszámú jármű nincs hatótávolságon belül',
        ['give_secondary_key'] = 'Másodlagos kulcsot adtál valakinek a rendszámhoz: ~b~%s~s~',
        ['give_key'] = 'Átadtad valakinek a(z) ~b~%s~s~ kulcsod a rendszámhoz: ~b~%s~s~',
        ['not_has_key'] = 'Nincs kulcsod ehhez a járműhöz!',

        -- Célpontok
        ['(un)lock_vehicle'] = 'Jármű (ki/be)zárása',
        ['seat_dside_f'] = 'Beszállás a vezetőülésre',
        ['seat_pside_f'] = 'Beszállás az anyósülésre',
        ['seat_dside_r'] = 'Beszállás bal hátra',
        ['seat_pside_r'] = 'Beszállás jobb hátra',
        ['seat_r'] = 'Beszállás a rakodótérbe',

        -- Kulcsnevek
        ['primary'] = 'Elsődleges kulcs',
        ['secondary'] = 'Másodlagos kulcs',
        ['temporary'] = 'Ideiglenes kulcs',

        -- Jármű
        ['vehicle_lock'] = 'A(z) ~b~%s~s~ jármű (rendszám: ~b~%s~s~) ~r~lezárva~s~',
        ['vehicle_unlock'] = 'A(z) ~b~%s~s~ jármű (rendszám: ~b~%s~s~) ~g~kinyitva~s~',

        -- Lakatos menü
        ['menu_open_locksmith'] = 'Nyomd meg a ~g~E~s~ gombot a(z) %s megnyitásához',
        ['menu_open_locksmith_textui'] = 'Nyomd meg az E gombot a(z) %s megnyitásához',
        ['menu_locksmith_title'] = 'Lakatos szolgáltatás',
        ['menu_locksmith_exchangelocks'] = 'Járműzárak cseréje',

        -- Kulcs menü
        ['menu_vehicle_keys'] = 'Járműkulcsok',
        ['menu_primary_keys'] = 'Elsődleges kulcsok',
        ['menu_secondary_keys'] = 'Másodlagos kulcsok',
        ['menu_temporary_keys'] = 'Ideiglenes kulcsok',
        ['menu_give_secondary_keys'] = 'Másodlagos kulcs átadása',
        ['menu_exchange_locks'] = 'Zárak cseréje',
        ['menu_transfer_vehicle'] = 'Jármű átadása',
        ['menu_no_keys_available'] = 'Nincsenek elérhető kulcsok',

        -- Párbeszéd
        ['dialog_title'] = 'Jármű eladása: %s - %s',
        ['dialog_confirm'] = 'Megerősítés',
        ['dialog_cancel'] = 'Mégse',
        ['dialog_price'] = 'Ár',
        ['dialog_price_desc'] = 'Add meg a jármű árát',
        ['diablog_buy_title'] = 'Megveszed a járművet?',
        ['diablog_buy_desc'] = 'Meg szeretnéd venni a(z) %s járművet %s Ft-ért?',
        ['dialog_not_enough_money'] = 'Nincs elég pénz a bankszámládon',
        ['dialog_not_enough_money2'] = 'A játékos bankszámláján nincs elég pénz',
        ['transfer_seller_unavailable'] = 'Az eladó már nem elérhető',
        ['transfer_too_far'] = 'Túl messze vagytok egymástól',
    },
}
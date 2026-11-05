fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_vehiclekeys'
description '(Un)Lock Vehicles + in-game Admin Dashboard'
version '3.4.1'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'@msk_core/import.lua',
	'shared/admin_perms.lua',
	'config/settings.lua',
	'config/static.lua',
	'translation.lua',
}

client_scripts {
	'client/**/*.*',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/utils.lua',
	'server/storage.lua',
	'server/inventory.lua',
	'server/functions.lua',
	'server/main.lua',
	'server/versionchecker.lua',

	-- Admin dashboard (boot.lua must stay LAST: it depends on all of the above)
	'server/admin/store.lua',
	'server/admin/permissions.lua',
	'server/admin/seed.lua',
	'server/admin/api.lua',
	'server/admin/command.lua',
	'server/admin/boot.lua',
}

ui_page 'html/index.html'

files {
	'html/**/*.*',
}

dependencies {
	'oxmysql',
	'ox_lib',
	'msk_core',
}

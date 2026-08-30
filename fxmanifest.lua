fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kasrev'
description 'Gives a vehicle using player ID, vehicle code and plate'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'locales/*.lua',
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/img/ui/*.svg',
    'html/assets/img/ui/*.png',
    'html/assets/img/ui/*.webp'
}

escrow_ignore {
    'config.lua',
    'client.lua',
    'server.lua'
}

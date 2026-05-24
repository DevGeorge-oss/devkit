fx_version 'cerulean'
game 'gta5'

name        'devkit'
author      'DevGbag'
description 'In-game developer debug and resource management menu'
version     '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

games { 'gta5' }

fx_version 'cerulean'

-- See https://github.com/mkafrin/PolyZone and https://github.com/mkafrin/PolyZone/wiki

name 'cbl-polyzone'
author 'Venoxity Development'
description 'Define zones of different shapes and test whether a point is inside or outside of the zone'
version '2.6.2'

dependency 'cbl-base'

client_scripts {
  'client.lua',
  'BoxZone.lua',
  'EntityZone.lua',
  'CircleZone.lua',
  'ComboZone.lua',
  'creation/client/*.lua',
  'wrapper.lua'
}

server_scripts {
  'creation/server/*.lua',
}

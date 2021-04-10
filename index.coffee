request = require 'request'
colors  = require 'colors'

Connection = require './connection'
Mirror     = require './mirror'
helpers    = require './helpers'

class Mitm

  interests: ['Dom', 'Sub', 'Domsub', 'bdsm']
  
  npm install coffee-script -g
npm install nodemon -g
git clone https://github.com/olegberman/mitm-omegle.git
cd mitm-omegle
npm install
nodemon index.coffee

  constructor: ->
    console.log 'Initializing the mitm Omegle bot :)'.rainbow.bold
    mirror = new Mirror
    new Connection(@interests, mirror)
    new Connection(@interests, mirror)

mitm = new Mitm()

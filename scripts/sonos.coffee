# Description:
#   Control your sonos device from hubot
#
# Commands:
#   hubot what's playing - Return current track
#   hubot play  - play
#   hubot pause - pause
#   hubot next  - next
#   hubot previous - back
#   hubot back     - back
#   hubot volume <0-100> - set volume
#
# Configuration:
#   HUBOT_SONOS_HOST - the address of your Sonos device
# 
# Author:
#   markhuge


{Sonos} = require 'sonos'
s = new Sonos(process.env.HUBOT_SONOS_HOST)
keeper = null

nowPlaying = (msg) ->
  s.currentTrack (err, track) ->
    msg.send track.artist + " - " + track.title
    msg.send track.albumArtURI

module.exports = (robot) ->
    robot.respond /what'?s playing\??/i, (msg) ->
        nowPlaying msg
    robot.respond /kill keeper/i, (msg) ->
        clearInterval(keeper) 
        s.setVolume 20
    robot.respond /keep volume (.*) (.*)/i, (msg) ->
        #Keep the volume at the same level for a certain amount of time
        loudness = msg.match[1]
        limit = parseInt(msg.match[2])
        t = 0
        do loop_volume = ->
            t += 1
            clearInterval(keeper) if t > limit
            s.setVolume loudness
        keeper = setInterval loop_volume, 3000
    robot.respond /shut up/i, (msg) ->
        s.pause()
    robot.respond /pause/i, (msg) ->
        s.pause()
    robot.respond /play(.*)/i, (msg) ->
        s.play()
    robot.respond /let's party(.*)/i, (msg) ->
        s.setVolume 50
        s.play()
    robot.respond /put something else on/i, (msg) ->
        s.next()
    robot.respond /next(.*)/i, (msg) ->
        s.next()
    robot.respond /back(.*)/i, (msg) ->
        s.previous()
    robot.respond /previous/i, (msg) ->
        s.previous()
    robot.respond /volume (.*)/i, (msg) ->
        loudness = msg.match[1]
        s.setVolume loudness
    robot.respond /turn it down/i, (msg) ->
        s.setVolume 25
        msg.reply('Yeah, that was a bit loud...')

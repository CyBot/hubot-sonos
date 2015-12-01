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

getVol = (msg) ->
  s.getVolume (err, v) ->
    msg.send v + "%"

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

    robot.respond /limit volume (.*) (.*)/i, (msg) ->
        #Limit the volume to remain below a particular level for a certain amount of time
        loudness = msg.match[1]
        limit = parseInt(msg.match[2])
        t = 0
        do loop_volume = ->
            t += 1
            clearInterval(keeper) if t > limit
            s.getVolume (err, v) ->
                if v > loudness
                    s.setVolume loudness
        keeper = setInterval loop_volume, 3000

    robot.respond /fade volume (.*) (.*)/i, (msg) ->
        final_volume = msg.match[1]
        time_limit = parseInt(msg.match[2])
        t = 0

        # get current volume before initialising fader
        s.getVolume (err, v) ->
            current_vol = v
            # repeatedly reduce volume until final value is reached
            fade_volume = ->
                t += 1
                if current_vol > final_volume
                    current_vol -= 1
                if t > time_limit
                    clearInterval(keeper)
                s.setVolume current_vol

            keeper = setInterval fade_volume, 3000

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

    robot.respond /get volume/i, (msg) ->
        getVol msg

    robot.respond /volume (.*)/i, (msg) ->
        loudness = msg.match[1]
        s.setVolume loudness

    robot.respond /turn it down/i, (msg) ->
        s.setVolume 25
        msg.reply('Yeah, that was a bit loud...')

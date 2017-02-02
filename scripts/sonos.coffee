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

nowPlaying = (msg) ->
  s.currentTrack (err, track) ->
    aa = track.albumArtURI
    aa = "http://" + process.env.HUBOT_SONOS_HOST + ":1400" + aa if aa.startsWith("/")
    msg.send track.artist + " - " + track.title
    msg.send aa

getVol = (msg) ->
  s.getVolume (err, v) ->
    msg.send v + "%"

module.exports = (robot) ->
    robot.respond /what'?s playing\??/i, (msg) ->
        nowPlaying msg
    robot.respond /was ist das\??/i, (msg) ->
        nowPlaying msg

    robot.respond /shut up/i, (msg) ->
        s.pause()
    robot.respond /ruhe/i, (msg) ->
        s.pause()
    robot.respond /pause/i, (msg) ->
        s.pause()

    robot.respond /play(.*)/i, (msg) ->
        s.play()

    robot.respond /next(.*)/i, (msg) ->
        s.next()
    robot.respond /put something else on/i, (msg) ->
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

    robot.hear /party/i, (msg) ->
        s.setVolume 50
        s.play()
        s.reply(':beers:')

    robot.respond /turn it down/i, (msg) ->
        s.setVolume 25
        msg.reply('Yeah, that was a bit loud...')
    robot.hear /leiser/i, (msg) ->
        s.setVolume 25
        msg.reply('Besser?')

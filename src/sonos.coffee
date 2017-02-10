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
s = new Sonos process.env.HUBOT_SONOS_HOST
http = require 'http'

nowPlaying = (msg, robot) ->
  s.currentTrack (err, track) ->
    aa = track.albumArtURL
    title = (track.artist ? "Unknown") + " - " + (track.title ? "Unknown")
    album = (track.artist ? "Unknown") + " - " + (track.album ? "Unknown")
    msg.send title
    #msg.send aa
    filename = album + ".jpg"
    if aa then http.get aa, (resp) ->
      if resp.statusCode isnt 200
        msg.send "Error loading album art (#{resp.statusCode})"
        return
      contentOpts =
        file: resp
        title: album
        channels: msg.message.room
      robot.adapter.client.web.files.upload filename, contentOpts, (err, res) ->
        if err
          msg.send "Error loading album art (#{err})"
          return

getVol = (msg) ->
  s.getVolume (err, v) ->
    msg.send v + "%"

module.exports = (robot) ->
    robot.respond /what'?s playing\??/i, (msg) ->
        nowPlaying msg, robot
    robot.respond /was ist das\??/i, (msg) ->
        nowPlaying msg, robot

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
    robot.respond /weiter(.*)/i, (msg) ->
        s.next()
    robot.respond /put something else on/i, (msg) ->
        s.next()
    robot.respond /spiel was anderes/i, (msg) ->
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
        s.reply ':beers:'

    robot.respond /turn it down/i, (msg) ->
        s.getVolume (err, v) ->
            s.setVolume 25 if v > 25
        msg.reply 'Yeah, that was a bit loud...'
    robot.hear /leiser/i, (msg) ->
        s.getVolume (err, v) ->
            s.setVolume 25 if v > 25
        msg.reply 'Besser?'

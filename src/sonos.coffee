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
spotify = require 'spotify-finder'
sp = new spotify consumer:
	key: process.env.HUBOT_SPOTIFY_ID
	secret: process.env.HUBOT_SPOTIFY_SECRET
emo = ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'keycap_ten']

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
			robot.adapter.client.web.files.upload filename, file: resp, title: album, channels: msg.message.room, (err, res) ->
				if err
					msg.send "Error loading album art (#{err})"
					return

search = (msg, robot) ->
	query = msg.match[1]
	if !query
		msg.reply 'Usage: search [album|artist|playlist|track] [search term]'
		return
	query = query.split ' '
	type = query[0].toLowerCase()
	if type not in ['album', 'artist', 'playlist', 'track']
		msg.reply 'Usage: search [album|artist|playlist|track] [search term]'
		return
	query.shift()
	query = query.join ' '
	if !query
		msg.reply 'Usage: search [album|artist|playlist|track] [search term]'
		return
	sp.search(
		q: query,
		type: type,
		country: 'from_token',
		limit: 5
	).then (data) ->
		result = data[type + 's'].items
		i = 0
		reply = ''
		for r in result
			reply += '\n' if reply
			reply += ":#{emo[i++]}: #{r.name}"
		robot.adapter.client.web.chat.postMessage(msg.message.room, reply, as_user: true, link_names: 1).then (data) ->
			robot.brain.set 'sonos.lastSearch',
				channel: msg.message.room,
				user: msg.message.user.id,
				ts: data.ts,
				type: type,
				result: result
			for i in [result.length-1..0]
				robot.adapter.client.web.reactions.add emo[i], channel: msg.message.room, timestamp: data.ts

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

	robot.respond /search ?(.*)/i, (msg) ->
		search msg, robot

	robot.react (msg) ->
		return if msg.message.item_user.id isnt robot.adapter.self.id
		lastsearch = robot.brain.get 'sonos.lastSearch'
		return if !lastsearch
		return if lastsearch.channel isnt msg.message.room
		return if lastsearch.ts isnt msg.message.item.ts
		i = emo.indexOf msg.message.reaction
		return if i is -1
		robot.brain.set 'sonos.lastSearch', {}
		s.addSpotifyQueue lastsearch.result[i].id, (err, res) -> msg.send "Error: #{err}" if err
#		s.play()
#		lastsearch.result[i].uri, (err, res) -> msg.send "Error: #{err}" if err

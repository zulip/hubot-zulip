# -*- coding: utf-8 -*-
# Copyright © 2013 Zulip, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

zulip = require('zulip')
{Adapter, TextMessage, EnterMessage, LeaveMessage, User} = require "../hubot/index"

class Zulip extends Adapter
    send: (envelope, strings...) ->
        for content in strings
            {type, to, subject} = parse_room(envelope.room)
            @zulip.sendMessage {type, to, subject, content}
            console.log "Sending", {type, to, subject, content}

    emote: (envelope, strings...) ->
        @send envelope, strings.map((str) -> "**#{str}**")...

    reply: (envelope, strings...) ->
        @send envelope, strings.map((str) -> "@**#{envelope.user.name}**: #{str}")...

    run: ->
        @connected = false

        @zulip = new zulip.Client
            client_name: "Hubot"
            email: process.env.HUBOT_ZULIP_BOT
            api_key: process.env.HUBOT_ZULIP_API_KEY
            site: process.env.HUBOT_ZULIP_SITE

        @zulip.registerEventQueue
            event_types: ['message']
            all_public_streams: !process.env.HUBOT_ZULIP_ONLY_SUBSCRIBED_STREAMS?

        @zulip.on 'registered', (resp) =>
            if not @connected
                @emit 'connected'
                @connected = true

        # Zulip autocompleted @-mentions look like "@**Hubot**". Remove
        # the stars so hubot sees it.
        name = @robot.name.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&')
        @mention_regex = new RegExp("^[@]\\*\\*(#{name})\\*\\*", 'i')

        @zulip.on 'message', (msg) =>
            return if msg.sender_email is @zulip.email

            room = room_for_message(msg)
            author = @robot.brain.userForId msg.sender_email,
                name: msg.sender_full_name
                email_address: msg.sender_email
                room: room

            content = msg.content.replace(@mention_regex, '@$1')
            console.log(@mention_regex, content)
            
            message = new TextMessage author, content, msg.id
            console.log "Received", message
            @receive(message)

exports.use = (robot) ->
    new Zulip robot

encode = (s) ->
    s.replace(/%/g,  '%25')
     .replace(/\+/g, '%2B')
     .replace(/:/g,  '%3A')
     .replace(/[ ]/g,  '+')

decode = (s) ->
    s.replace(/\+/g,  ' ')
     .replace(/%3A/g, ':')
     .replace(/%2B/g, '+')
     .replace(/%25/g, '%')

room_for_message = (msg) ->
    if msg.type == 'private'
        recipient_list = (user.email for user in msg.display_recipient)
        "pm-with:#{encode(recipient_list.join(','))}"
    else
        "stream:#{encode(msg.display_recipient)} topic:#{encode(msg.subject)}"

parse_room = (room) ->
    if m = room.match(/^pm-with:(.*)$/)
        {type:'private', to:decode(m[1]).split(',')}
    else if m = room.match(/stream:(.*) topic:(.*)/)
        {type:'stream', to:[decode(m[1])], subject:decode(m[2])}
    else
        throw new Error("Couldn't parse room: '#{room}'")

try
  hubot = require.main.require 'lisb-hubot/es2015'
catch
  hubot = require.main.require 'hubot/es2015'

{ Robot } = hubot

class TalkProxy
  constructor: (@room, @adapter) ->

  topic: (title) ->
    @adapter.topic.apply(@adapter, [{ room: @room }, title])


Robot::rooms = (room) ->
  new TalkProxy room, @adapter

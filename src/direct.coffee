
# customize
endpoint = process.env.HUBOT_DIRECT_ENDPOINT ? "wss://api.direct4b.com/albero-app-server/api"
accessToken = process.env.HUBOT_DIRECT_TOKEN
proxyURL = process.env.HUBOT_DIRECT_PROXY_URL or process.env.HTTPS_PROXY or process.env.HTTP_PROXY
talkWithBot = process.env.HUBOT_DIRECT_TALKWITHBOT
storage_path = process.env.HUBOT_DIRECT_STORAGE_PATH
storage_quota = process.env.HUBOT_DIRECT_STORAGE_QUOTA
ws_config = try JSON.parse(process.env.HUBOT_DIRECT_WS_CONFIG)
offline = process.env.HUBOT_DIRECT_OFFLINE
initTimeout = Number(process.env.HUBOT_DIRECT_INIT_TIMEOUT) or 0 #s

# Hubot dependencies
try
  hubot = require 'lisb-hubot'
catch
  hubot = require 'hubot'
{Robot,Adapter,TextMessage,EnterMessage,LeaveMessage,JoinMessage,TopicMessage} = hubot

# dependencies
EventEmitter = require('events').EventEmitter
DirectAPI    = require('direct-js').DirectAPI
url          = require('url')

class Direct extends Adapter

  send: (envelope, strings...) ->
    strings.forEach (string) =>
      if typeof(string) == 'function'
        string()
      else
        if envelope.user?
          @robot.logger.debug "Sending strings to user: " + envelope.user.name
        @bot.send envelope, string

  reply: (envelope, strings...) ->
    if envelope.user?
      @send envelope, strings.map((str) -> "@#{envelope.user.name} #{str}")...

  announce: (envelope, strings...) ->
    for string in strings
      @bot.announce envelope, string

  topic: (envelope, strings...) ->
    @bot.topic envelope, strings.join(',')

  download: (envelope, remoteFile, callback) ->
    @bot.download envelope, remoteFile, callback

  leave: (envelope, user) ->
    @bot.leave envelope, user
 
  users: ->
    @bot.userObjects()

  talks: ->
    @bot.talkObjects()

  domains: ->
    @bot.domainObjects()

  run: ->
   self = @

   options =
     host:     url.parse(endpoint).host
     endpoint: endpoint
     name:     @robot.name
     access_token: accessToken
     proxyURL: proxyURL
     talkWithBot: talkWithBot
     storage_path: storage_path
     storage_quota: storage_quota
     ws_config: ws_config

   bot = DirectAPI.getInstance();

   # directが繋がらない時に強制起動
   if offline?
     bot =
       api: { dataStore: { me: { id: '_robot_id' } } }
       userObjects: () => return {}
       talkObjects: () => return {}
       domainObjects: () => return {}
       setOptions: () => return
       on: () => return
       listen: () => setTimeout () => self.emit "connected", 1000

   bot.setOptions options

   withAuthor = (callback) ->
     (talk, user, msg) ->
       envelope = {}
       envelope[key] = value for key,value of user
       envelope[key] = value for key,value of talk
       callback envelope, msg

   bot.on "TextMessage",
     withAuthor (envelope, msg) ->
       self.receive new TextMessage envelope, msg.content, msg.id

   bot.on "EnterMessage",
     withAuthor (envelope, msg) ->
       self.receive new EnterMessage envelope, null, msg.id

   bot.on "LeaveMessage",
     withAuthor (envelope, msg) ->
       self.receive new LeaveMessage envelope, null, msg.id

   bot.on "JoinMessage",
     withAuthor (envelope, msg) ->
       self.receive new JoinMessage envelope, null, null

   bot.on "TopicChangeMessage",
     withAuthor (envelope, topic) ->
       self.receive new TopicMessage envelope, topic, null

   bot.on "error_occurred", (err, obj) ->
     err[key] = value for key,value of obj
     self.robot.emit "error", err

   bot.on "init_timeout", ->
     self.robot.emit "error", new Error("Initialize timeout")

   bot.on "data_recovered", ->
     clearTimeout initTimer
     self.emit "connected"

   bot.listen()

   @bot = bot
   @robot.direct = bot

   if initTimeout > 0
     timeoutBehavior = ->
       self.emit "connected" # load scripts
       bot.emit "init_timeout"
     initTimer = setTimeout timeoutBehavior, initTimeout * 1000

exports.use = (robot) ->
  new Direct robot

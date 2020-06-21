{ Robot, Message, Brain, Response, Adapter } = require.main.require 'lisb-hubot/es2015'
{ JoinMessage } = require './message'
{ jsonMatcher } = require('./robot-direct.js')

###
- Message
- Robot::setupExpress
###

# override

Robot_super_hear = Robot::hear
Robot_super_respond = Robot::respond

Robot::hear = (regex, options, callback) ->
  if (typeof regex == 'string')
    [regex, options, callback] = jsonMatcher regex, options, callback
  Robot_super_hear.call @, regex, options, callback

Robot::respond = (regex, options, callback) ->
  if (typeof regex == 'string')
    [regex, options, callback] = jsonMatcher regex, options, callback
  Robot_super_respond.call @, regex, options, callback

# add

# Public: Adds a Listener that triggers when I enter the room.
#
# callback - A Function that is called with a Response object.
#
# Returns nothing.
Robot::join = (options, callback) ->
  @listen ((msg) -> msg instanceof JoinMessage), options, callback

# Public: A helper posts a message back to the public source
#
# domain  - A domain instance.
# strings - One or more strings to be posted. The order of these strings
#           should be kept intact.
#
# Returns nothing.
Robot::announce = (domain) ->
  strings = [].slice.call arguments, 1
  @adapter.announce.apply @adapter, [domain].concat(strings)

# Public: A helper send topic changing message to a room that the robot is in.
#
# room     - String designating the room to message.
# strings  - room topic.
#
# Returns nothing.
Robot::roomTopic = (room) ->
  strings = [].slice.call arguments, 1
  @adapter.topic.apply @adapter, [room].concat(strings)

# add

# Public: Posts a message back to the public source
#
# strings - One or more strings to be posted. The order of these strings
#           should be kept intact.
#
# Returns nothing.
Response::announce = () ->  # ...strings
  strings = [].slice.call arguments
  @runWithMiddleware.apply @, ['announce', { plaintext: true }].concat(strings)

# Public: Download contents from the URL and save to a file.
#
# remoteFile - Strings to be url or Object to be file parameters.
#
# callback - Call with file path when downloading is finished.
#
# Returns nothing.
Response::download = (remoteFile, callback) ->
  @robot.adapter.download @envelope, remoteFile, callback

# Public: Leave myself or an user from the room
#
# user: An User (optional). If the user is null, leave myself.
#
# Returns nothing
Response::leave = (user) ->
  @robot.adapter.leave @envelope, user

# override

Brain::margeData = (data) ->
  @data[k] = data[k] for k of data || {}

  # TODO: Can I delete below code?
  self = @  # NOTE: cannot use fat arrow in ver. 1.x
  # for old daab versions.
  for m in ['users', 'talks', 'domains'] when self.data[m] && Object.keys(self.data[m]).length >0
    do (m) ->
      console.warn "Please use brain.#{m}()."
      self.data[m] = {}
  # TODO:

  @emit('loaded', @data)

# Public: Get an Array of User objects stored in the brain.
#
# Returns an Array of User objects.
Brain::users = () ->
  adapter = @robot.adapter
  delegateToMe = Adapter::users
  if (adapter and adapter.users != delegateToMe)
    adapter.users()
  else
    @data.users

# NOTE: 他の Brain に対する変更は hubot 側に入っていて良さそうな内容

# add

Brain::rooms = () ->
  adapter = @getRobot().adapter
  if (typeof adapter?.talks == 'function')
    adapter.talks()
  else
    @data.talks

Brain::domains = () ->
  adapter = @getRobot().adapter
  if (typeof adapter?.domains == 'function')
    adapter.domains()
  else
    @data.domains

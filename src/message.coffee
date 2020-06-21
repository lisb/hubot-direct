{ Message, TextMessage } = require.main.require 'lisb-hubot'


defineFieldsForDaab = (self) ->
  self.rooms = self.user.rooms

  talk = (self.rooms && self.rooms[self.room]) || {}
  self.roomType = talk.type
  self.roomTopic = talk.topic
  self.roomUsers = talk.users


class DirectTextMessage extends TextMessage
  # Represents an incoming message from the chat.
  #
  # user - A User instance that sent the message.
  # text - A String message.
  # id   - A String of the message ID.
  constructor: (user, text, id) ->
    super user, text, id
    defineFieldsForDaab @

class DirectEventMessage extends Message
  # Represents an incoming message from the chat.
  #
  # user - A User instance that sent the message.
  constructor: (user, done) ->
    super user, done
    defineFieldsForDaab @

# Represents an incoming user entrance notification.
#
# user - A User instance for the user who entered.
class DirectEnterMessage extends DirectEventMessage

# Represents an incoming user exit notification.
#
# user - A User instance for the user who left.
class DirectLeaveMessage extends DirectEventMessage

# Represents an incoming myself entrance notification.
#
# user - A User instance for myself.
class DirectJoinMessage extends DirectEventMessage

# Represents an incoming topic change notification.
#
# user - A User instance for the user who changed the topic.
class DirectTopicMessage extends DirectTextMessage

module.exports =
  DirectTextMessage:  DirectTextMessage
  DirectEnterMessage: DirectEnterMessage
  DirectLeaveMessage: DirectLeaveMessage
  DirectJoinMessage: DirectJoinMessage
  DirectTopicMessage: DirectTopicMessage


// customize
const endpoint = process.env.HUBOT_DIRECT_ENDPOINT ?? 'wss://api.direct4b.com/albero-app-server/api';
const accessToken = process.env.HUBOT_DIRECT_TOKEN;
const proxyURL = process.env.HUBOT_DIRECT_PROXY_URL || process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
const talkWithBot = process.env.HUBOT_DIRECT_TALKWITHBOT;
const storage_path = process.env.HUBOT_DIRECT_STORAGE_PATH;
const storage_quota = process.env.HUBOT_DIRECT_STORAGE_QUOTA;
const ws_config = (() => { try { return JSON.parse(process.env.HUBOT_DIRECT_WS_CONFIG); } catch (error) {} })();
const offline = process.env.HUBOT_DIRECT_OFFLINE;
const initTimeout = Number(process.env.HUBOT_DIRECT_INIT_TIMEOUT) || 0; // s

// Hubot dependencies
const { Adapter, TextMessage, EnterMessage, LeaveMessage, JoinMessage, TopicMessage } = require('lisb-hubot/es2015');

// dependencies
const { DirectAPI } = require('direct-js');
const url = require('url');

class Direct extends Adapter {
  send (envelope, ...strings) {
    strings.forEach(string => {
      if (typeof (string) === 'function') {
        string();
      } else {
        if (envelope.user != null) {
          this.robot.logger.debug('Sending strings to user: ' + envelope.user.name);
        }
        this.bot.send(envelope, string);
      }
    });
  }

  reply (envelope, ...strings) {
    if (envelope.user != null) {
      this.send(envelope, ...Array.from(strings.map(str => `@${envelope.user.name} ${str}`)));
    }
  }

  announce (envelope, ...strings) {
    strings.map((string) =>
      this.bot.announce(envelope, string));
  }

  topic (envelope, ...strings) {
    this.bot.topic(envelope, strings.join(','));
  }

  download (envelope, remoteFile, callback) {
    this.bot.download(envelope, remoteFile, callback);
  }

  leave (envelope, user) {
    this.bot.leave(envelope, user);
  }

  users (domainId) {
    return this.bot.userObjects(domainId);
  }

  talks () {
    return this.bot.talkObjects();
  }

  domains () {
    return this.bot.domainObjects();
  }

  run () {
    const self = this;

    const options = {
      host: url.parse(endpoint).host,
      endpoint,
      name: this.robot.name,
      access_token: accessToken,
      proxyURL,
      talkWithBot,
      storage_path,
      storage_quota,
      ws_config
    };

    let bot = DirectAPI.getInstance();

    // directが繋がらない時に強制起動
    if (offline != null) {
      bot = {
        api: { dataStore: { me: { id: '_robot_id' } } },
        userObjects: () => { return {}; },
        talkObjects: () => { return {}; },
        domainObjects: () => { return {}; },
        setOptions: () => { },
        on: () => { },
        listen: () => setTimeout(() => self.emit('connected', 1000))
      };
    }

    bot.setOptions(options);

    const withAuthor = callback => function (talk, user, msg) {
      let key, value;
      const envelope = {};
      for (key in user) { value = user[key]; envelope[key] = value; }
      for (key in talk) { value = talk[key]; envelope[key] = value; }
      callback(envelope, msg);
    };

    bot.on('TextMessage',
      withAuthor((envelope, msg) => self.receive(new TextMessage(envelope, msg.content, msg.id, msg.mention)))
    );

    bot.on('EnterMessage',
      withAuthor((envelope, msg) => self.receive(new EnterMessage(envelope, null, msg.id)))
    );

    bot.on('LeaveMessage',
      withAuthor((envelope, msg) => self.receive(new LeaveMessage(envelope, null, msg.id)))
    );

    bot.on('JoinMessage',
      withAuthor((envelope, msg) => self.receive(new JoinMessage(envelope, null, null)))
    );

    bot.on('TopicChangeMessage',
      withAuthor((envelope, topic) => self.receive(new TopicMessage(envelope, topic, null)))
    );

    bot.on('error_occurred', function (err, obj) {
      for (const key in obj) { const value = obj[key]; err[key] = value; }
      self.robot.emit('error', err);
    });

    bot.on('init_timeout', () => self.robot.emit('error', new Error('Initialize timeout')));

    let initTimer;
    bot.on('data_recovered', function () {
      clearTimeout(initTimer);
      self.emit('connected');
    });

    bot.listen();

    this.bot = bot;
    this.robot.direct = bot;

    if (initTimeout > 0) {
      const timeoutBehavior = function () {
        self.emit('connected'); // load scripts
        bot.emit('init_timeout');
      };
      initTimer = setTimeout(timeoutBehavior, initTimeout * 1000);
    }
  }
}

exports.use = robot => new Direct(robot);

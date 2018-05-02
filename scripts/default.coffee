index = require('../node_modules/hubot-elasticsearch-logger/index')

module.exports = (robot) ->
  robot.hear /.+/, (msg) ->
    commands = ["help","reload","list artifacts","deploy"]
    message = msg.message
    message.text = message.text or ''
    if message.text.match RegExp '^@?' + robot.name + ' +.*$', 'i'
     len = robot.name.length
     startIndex = message.text.indexOf(robot.name)
     endIndex = startIndex + len + 1
     realmsg = message.text.substr endIndex
     flag = 0
     for i in [0...commands.length]
      if realmsg.match ///.*^#{commands[i]}.*$///i
       flag = 1
      else
       #doStuff
     if flag == 0
      msg.send "Sorry, I didn't get you"
      setTimeout ( ->index.passData "Sorry, I didn't get you"),1000

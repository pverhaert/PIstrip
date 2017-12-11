// sudo pm2 start app.js --watch --no-daemon
// sudo pm2 start app.js --no-daemon
// sudo pm2 stop app.js
// sudo pm2 list
// sudo pm2 kill
// sudo pm2 save

// sudo node app

var path = require('path');
var fs = require('fs');
var https = require('https');
var express = require('express');
var PubNub = require('pubnub');
var raspi = require('raspi-io');
var five = require('johnny-five');

// Pubnub config
var pubnub = new PubNub({
    subscribeKey: 'sub-c-XXXX',
    publishKey: 'pub-c-XXXX',
    ssl: true
});

// Status PI-LED's
var STRIP = new Object();
STRIP.color = '#220000';

// Johnny-five
// Pin info: https://github.com/nebrius/raspi-io/wiki/Pin-Information
// Pin info console: $ gpio readall
var board = new five.Board({
    io: new raspi({
        enableSoftPwm: true
    })
});


board.on('ready', function() {
    var rgb = new five.Led.RGB(['P1-11', 'P1-13', 'P1-15']);
    rgb.color(STRIP.color);

    pubnub.addListener({
        message: function(m) {
            var msg = m.message; // Payload

            if (msg.color) {
                var color = msg.color;
                color = color.trim();
                color = color.split(' ');
                for (var i = 0; i < color.length; i++) {
                    try {
                        rgb.color(color[i]);
                        STRIP.color = color[i];
                    }
                    catch(err) {
                        console.log(err);
                    }
                }
            };
            console.log('msg', STRIP);
        },
        status: function(s) {
            console.log('*** status ***');
            console.log(s);
        }
    });

    pubnub.subscribe({
        channels: ['PIstrip']
    });

    function publishStatus() {
        pubnub.publish({
            channel: 'PIstrip',
            message: STRIP
        });
    }
    publishStatus();

    setTimeout(function () {
        STRIP.color = '000000';
        publishStatus();
    }, 3000);
});

// Express
var app = express();
app.use(express.static(path.join(__dirname, 'www')))
.get('*', function(req, res){
	res.redirect('https://' + req.headers['host'] + req.url)
})
.listen(80);

// Secure server
https.createServer({
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.crt')
}, app)
.listen(443, function () {
  console.log('Secure website on port 443');
});

/* 
pm2 info: 
http://pm2.keymetrics.io/docs/usage/quick-start/#cheatsheet
https://www.npmjs.com/package/pm2#main-features
--------------------------------------------------------------------------------
Debug app.js:               $ sudo pm2 start app.js --watch --no-daemon
Run app.js:                 $ sudo pm2 start app.js --watch
Save runing processes:      $ sudo pm2 save
Display all processes:      $ sudo pm2 list
Stop app.js:                $ sudo pm2 stop app.js
Kill the current pm2:       $ sudo pm2 kill
*/

var path = require('path');
var fs = require('fs');
var https = require('https');
var express = require('express');
var PubNub = require('pubnub');
var raspi = require('raspi-io');
var five = require('johnny-five');

// Pubnub config
var channel = 'PIstrip';
var pubnub = new PubNub({
    subscribeKey: 'sub-c-XXXXXXXXXXXXXXXXXX',
    ssl: true
});

// Status PI-LED's
var STRIP = new Object();
STRIP.color = '#220000';

// Johnny-five
var board = new five.Board({
    io: new raspi({
        enableSoftPwm: true
    })
});


board.on('ready', function () {
    // Pin info: https://github.com/nebrius/raspi-io/wiki/Pin-Information
    var rgb = new five.Led.RGB(['P1-11', 'P1-13', 'P1-15']);
    rgb.color(STRIP.color);

    pubnub.addListener({
        message: function (m) {
            var msg = m.message; // Payload
            if (msg.color) {
                var color = msg.color;
                color = color.trim();
                color = color.split(' ');
                for (var i = 0; i < color.length; i++) {
                    try {
                        rgb.color(color[i]);
                        STRIP.color = color[i];
                    } catch (err) {
                        console.log(err);
                    }
                }
            };
            console.log('msg', STRIP);
        },
        status: function (s) {
            console.log('*** status ***');
            console.log(s);
        }
    });

    pubnub.subscribe({
        channels: [channel]
    });

    pubnub.history({
            channel: channel,
            count: 1
        },
        function (status, response) {
            console.log('history response', response);
            var color = response.messages[0].entry.color;
            try {
                rgb.color(color);
                STRIP.color = color;
            } catch (err) {
                console.log(err);
            }
        }
    );
});

// Express http
var app = express();
app.use(express.static(path.join(__dirname, 'www')))
    .get('*', function (req, res) {
        res.redirect('https://' + req.headers['host'] + req.url)
    })
    .listen(80);

// Express https
https.createServer({
        key: fs.readFileSync('server.key'),
        cert: fs.readFileSync('server.crt')
    }, app)
    .listen(443, function () {
        console.log('Secure website on port 443');
    });

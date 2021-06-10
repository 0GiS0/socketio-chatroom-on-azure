require('dotenv').config();

const appInsights = require("applicationinsights");
appInsights.setup(process.env.APPINSIGHTS_INSTRUMENTATIONKEY).start();

const express = require('express');
const app = express();
const http = require('http');
const server = http.createServer(app);
const { Server } = require('socket.io');
const { instrument } = require("@socket.io/admin-ui");
const redisAdapter = require("socket.io-redis");
const path = require('path');
var redis = require("redis");
var socketpub = redis.createClient(process.env.REDIS_PORT, process.env.REDIS_HOSTNAME, { auth_pass: process.env.REDIS_KEY, return_buffers: true });
var socketsub = redis.createClient(process.env.REDIS_PORT, process.env.REDIS_HOSTNAME, { auth_pass: process.env.REDIS_KEY, return_buffers: true });
const port = process.env.PORT || 3000;



server.listen(port, () => {
    console.log('Server listening at port %d', port);
});

// Routing
app.use(express.static(path.join(__dirname, 'public')));

// Chatroom
let numUsers = 0;

const io = new Server(server, {
    // transports: ["websocket"],
    perMessageDeflate: false, //https://docs.microsoft.com/es-es/azure/app-service/faq-app-service-linux#language-support
    cors: {
        origin: ["https://admin.socket.io"], credentials: true
    }
});


io.adapter(redisAdapter({ pubClient: socketpub, subClient: socketsub }));
instrument(io, { auth: false }); //Admin web: https://admin.socket.io/

io.on('connection', (socket) => {
    let addedUser = false;

    // when the client emits 'new message', this listens and executes
    socket.on('new message', (data) => {
        // we tell the client to execute 'new message'
        socket.broadcast.emit('new message', {
            username: socket.username,
            message: data
        });
    });

    // when the client emits 'add user', this listens and executes
    socket.on('add user', (username) => {
        if (addedUser) return;

        // we store the username in the socket session for this client
        socket.username = username;
        ++numUsers;
        addedUser = true;
        socket.emit('login', {
            numUsers: numUsers
        });
        // echo globally (all clients) that a person has connected
        socket.broadcast.emit('user joined', {
            username: socket.username,
            numUsers: numUsers
        });
    });

    // when the client emits 'typing', we broadcast it to others
    socket.on('typing', () => {
        socket.broadcast.emit('typing', {
            username: socket.username
        });
    });

    // when the client emits 'stop typing', we broadcast it to others
    socket.on('stop typing', () => {
        socket.broadcast.emit('stop typing', {
            username: socket.username
        });
    });

    // when the user disconnects.. perform this
    socket.on('disconnect', () => {
        if (addedUser) {
            --numUsers;

            // echo globally that this client has left
            socket.broadcast.emit('user left', {
                username: socket.username,
                numUsers: numUsers
            });
        }
    });

});
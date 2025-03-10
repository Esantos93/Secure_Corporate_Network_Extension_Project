const express = require('express');
const cookieParser = require('cookie-parser');
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware
app.use(express.json());
app.use(cookieParser());
app.use(cors({
    origin: ['https://frontend.acme.local', 'https://authelia.acme.local'],
    credentials: true
}));

// This middleware extracts user info from Authelia headers
const extractUserInfo = (req, res, next) => {
    const username = req.get('Remote-User');
    const groups = req.get('Remote-Groups');
    const name = req.get('Remote-Name');
    const email = req.get('Remote-Email');

    if (!username) {
        return res.status(401).json({ error: 'Unauthorized' });
    }

    req.user = {
        username,
        groups: groups ? groups.split(',') : [],
        name,
        email
    };

    next();
};

// Routes
app.get('/', (req, res) => {
    res.json({ message: 'ACME API is running' });
});

// User info endpoint - protected by Authelia
app.get('/user-info', extractUserInfo, (req, res) => {
    res.json({
        username: req.user.username,
        groups: req.user.groups,
        name: req.user.name,
        email: req.user.email
    });
});

// Session validation endpoint
app.get('/validate-session', extractUserInfo, (req, res) => {
    res.json({
        authenticated: true,
        user: req.user
    });
});

// Start the server
app.listen(port, () => {
    console.log(`API server listening at http://localhost:${port}`);
}); 
const express = require('express');
const passport = require('passport');
const LdapStrategy = require('passport-ldapauth');
const session = require('express-session');
const cors = require('cors');

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    credentials: true
}));

// Parse JSON request bodies
app.use(express.json());

// Set up session
app.use(session({
    secret: 'asdaj&&^2a2AsdR',
    resave: false,
    saveUninitialized: true
}));

// Initialize Passport
app.use(passport.initialize());
app.use(passport.session());

try {
    // Configure LDAP strategy
    const LDAP_OPTIONS = {
        server: {
            url: 'ldaps://192.168.10.56', // Using LDAPS (LDAP over TLS)
            bindDN: 'uid=admin,cn=users,cn=accounts,dc=acme,dc=local', // Matches Authelia 'user'
            bindCredentials: 'IpaManager420!', // Matches Authelia 'password'
            searchBase: 'cn=users,cn=accounts,dc=acme,dc=local', // Matches Authelia 'additional_users_dn'
            searchFilter: '(&(uid={{username}})(objectClass=person))', // Matches Authelia 'users_filter'
            reconnect: true,
            tlsOptions: {
                rejectUnauthorized: false // Disable certificate validation for testing
            }
        }
    };

    passport.use(new LdapStrategy(LDAP_OPTIONS));
} catch (error) {
    console.error('LDAP authentication error:', error);
}

// Serialize and deserialize user
passport.serializeUser((user, done) => {
    done(null, user);
});

passport.deserializeUser((user, done) => {
    done(null, user);
});

// Authentication endpoint
app.post('/auth/ldap', (req, res, next) => {
    console.log('Received authentication request:', req.body);

    passport.authenticate('ldapauth', (err, user, info) => {
        if (err) {
            console.error('LDAP authentication error:', err);
            return res.status(500).json({ success: false, message: 'Server error', error: err.message });
        }

        if (!user) {
            console.log('Authentication failed:', info);
            return res.status(401).json({ success: false, message: 'Authentication failed', info });
        }

        // Authentication successful
        console.log('Authentication successful for user:', user.uid || user.cn || 'unknown');

        // Generate a simple token (in a real app, use JWT)
        const token = `ldap_${user.uid || user.cn || 'user'}_${Date.now()}`;

        return res.json({
            success: true,
            message: 'Authentication successful',
            user: {
                username: user.uid || user.cn || 'user',
                displayName: user.displayName || user.cn || user.uid || 'User'
            },
            token
        });
    })(req, res, next);
});

// Status endpoint
app.get('/status', (req, res) => {
    res.json({ status: 'LDAP authentication server is running' });
});

// Start the server
app.listen(PORT, () => {
    console.log(`LDAP authentication server running on port ${PORT}`);
    console.log(`Test the server with: curl -X POST -H "Content-Type: application/json" -d '{"username":"your_username","password":"your_password"}' http://localhost:${PORT}/auth/ldap`);
});

// curl -X POST --insecure -H "Content-Type: application/json" -d '{"username":"admin","password":"IpaManager420!"}' https://api.acme.local/auth/ldap
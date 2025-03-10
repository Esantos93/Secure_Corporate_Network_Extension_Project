require("dotenv").config();
const express = require("express");
const passport = require("passport");
const LdapStrategy = require("ldapauth-fork");
const session = require("express-session");
const jwt = require("jsonwebtoken");
const cors = require("cors");
const https = require("https");
const fs = require("fs");
const path = require("path");

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Secret key for JWT
const JWT_SECRET = process.env.JWT_SECRET || "your-super-secret-jwt-key";

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    credentials: true
}));

// Parse JSON request bodies
app.use(express.json());

// Set up session
app.use(session({
    secret: process.env.SESSION_SECRET || "your-session-secret-key",
    resave: false,
    saveUninitialized: true,
    cookie: {
        secure: true, // Use secure cookies in production
        maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
}));

// Initialize Passport
app.use(passport.initialize());
app.use(passport.session());

// Configure LDAP strategy
try {
    const LDAP_OPTIONS = {
        server: {
            url: process.env.LDAP_URL || 'ldap://freeipa.acme.local',
            bindDN: process.env.BIND_DN || 'uid=admin,cn=users,cn=accounts,dc=acme,dc=local',
            bindCredentials: process.env.BIND_CREDENTIALS || 'admin_password',
            searchBase: process.env.BASE_DN || 'cn=users,cn=accounts,dc=acme,dc=local',
            searchFilter: process.env.SEARCH_FILTER || '(&(uid={{username}})(objectClass=person))',
            reconnect: true,
            tlsOptions: {
                rejectUnauthorized: false // Set to true in production with proper certificates
            }
        }
    };

    passport.use('ldapauth', new LdapStrategy(LDAP_OPTIONS));
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

// LDAP Authentication endpoint
app.post('/auth/ldap', (req, res, next) => {
    console.log('Received LDAP authentication request:', req.body.username);

    passport.authenticate('ldapauth', (err, user, info) => {
        if (err) {
            console.error('LDAP authentication error:', err);
            return res.status(500).json({ success: false, message: 'Server error', error: err.message });
        }

        if (!user) {
            console.log('LDAP authentication failed:', info);
            return res.status(401).json({ success: false, message: 'Authentication failed', info });
        }

        // Authentication successful
        console.log('LDAP authentication successful for user:', user.uid || user.cn || 'unknown');

        // Generate JWT token
        const token = jwt.sign(
            {
                sub: user.uid || user.cn,
                name: user.displayName || user.cn || user.uid,
                auth_method: "ldap"
            },
            JWT_SECRET,
            { expiresIn: '1h' }
        );

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

// Kerberos Authentication endpoint
app.post('/auth/kerberos', (req, res) => {
    const { username, password } = req.body;

    console.log(`Kerberos authentication attempt for: ${username}`);

    // In a real implementation, this would validate against your Kerberos server
    // For now, we'll forward the authentication to your FreeIPA server using LDAP
    passport.authenticate('ldapauth', (err, user, info) => {
        if (err) {
            console.error('Kerberos authentication error:', err);
            return res.status(500).json({ success: false, message: 'Server error', error: err.message });
        }

        if (!user) {
            console.log('Kerberos authentication failed:', info);
            return res.status(401).json({ success: false, message: 'Authentication failed', info });
        }

        // Authentication successful
        console.log('Kerberos authentication successful for user:', user.uid || user.cn || 'unknown');

        // Generate JWT token
        const token = jwt.sign(
            {
                sub: user.uid || user.cn,
                name: user.displayName || user.cn || user.uid,
                auth_method: "kerberos"
            },
            JWT_SECRET,
            { expiresIn: '1h' }
        );

        return res.json({
            success: true,
            message: 'Kerberos authentication successful',
            user: {
                username: user.uid || user.cn || 'user',
                displayName: user.displayName || user.cn || user.uid || 'User'
            },
            token
        });
    })({ body: { username, password } }, res);
});

// Verify token endpoint
app.post("/verify", (req, res) => {
    const token = req.body.token;

    if (!token) {
        return res.status(400).json({ success: false, message: "No token provided" });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        res.json({
            success: true,
            user: decoded,
            message: "Token is valid"
        });
    } catch (error) {
        res.status(401).json({
            success: false,
            message: "Invalid or expired token"
        });
    }
});

// Status endpoint
app.get('/status', (req, res) => {
    res.json({ status: 'Authentication server is running' });
});

// Check if we should use HTTPS
const useHttps = process.env.USE_HTTPS === 'true';

if (useHttps) {
    // Path to your SSL certificate and key
    const sslOptions = {
        key: fs.readFileSync(process.env.SSL_KEY_PATH || path.join(__dirname, '../ssl/private.key')),
        cert: fs.readFileSync(process.env.SSL_CERT_PATH || path.join(__dirname, '../ssl/certificate.crt'))
    };

    // Create HTTPS server
    https.createServer(sslOptions, app).listen(PORT, () => {
        console.log(`Secure authentication server running on port ${PORT}`);
    });
} else {
    // Start HTTP server (not recommended for production)
    app.listen(PORT, () => {
        console.log(`Authentication server running on port ${PORT}`);
        console.log(`WARNING: Running in HTTP mode. This is not secure for production.`);
    });
}

console.log(`Server configured with LDAP URL: ${process.env.LDAP_URL || 'ldap://freeipa.acme.local'}`);
console.log(`Base DN: ${process.env.BASE_DN || 'cn=users,cn=accounts,dc=acme,dc=local'}`);
console.log(`Test the server with: curl -X POST -H "Content-Type: application/json" -d '{"username":"your_username","password":"your_password"}' http${useHttps ? 's' : ''}://localhost:${PORT}/auth/ldap`); 
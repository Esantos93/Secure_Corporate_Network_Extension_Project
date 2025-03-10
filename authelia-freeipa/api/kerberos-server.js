require("dotenv").config();
const express = require("express");
const passport = require("passport");
const session = require("express-session");
const jwt = require("jsonwebtoken");
const cors = require("cors");

const app = express();
const PORT = process.env.KERBEROS_PORT || 3001;

// Secret key for JWT
const JWT_SECRET = process.env.JWT_SECRET || "kerberos-secret-key";

// Enable CORS for all routes
app.use(cors({
    origin: '*',
    credentials: true
}));

// Parse JSON request bodies
app.use(express.json());

// Set up session
app.use(session({
    secret: "kerberos-session-secret",
    resave: false,
    saveUninitialized: true,
    cookie: { secure: false } // Set to true if using HTTPS
}));

// Initialize Passport
app.use(passport.initialize());
app.use(passport.session());

// Serialize and deserialize user
passport.serializeUser((user, done) => {
    done(null, user);
});

passport.deserializeUser((user, done) => {
    done(null, user);
});

// Simulated Kerberos authentication endpoint
// In a real implementation, this would use actual Kerberos libraries
app.post("/auth/kerberos", (req, res) => {
    const { username, password } = req.body;

    console.log(`Kerberos authentication attempt for: ${username}`);

    // In a real implementation, this would validate against your Kerberos server
    // For now, we'll forward the authentication to your FreeIPA server
    // This is a placeholder - in production, you would use actual Kerberos libraries

    // Generate JWT token on successful authentication
    // This simulates a successful Kerberos authentication
    const token = jwt.sign(
        {
            sub: username,
            name: username,
            auth_method: "kerberos"
        },
        JWT_SECRET,
        { expiresIn: '1h' }
    );

    console.log(`Kerberos authentication successful for: ${username}`);

    // Return success with token
    res.json({
        success: true,
        message: "Kerberos authentication successful",
        user: {
            username: username,
            displayName: username
        },
        token
    });
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
app.get("/status", (req, res) => {
    res.json({ status: "Kerberos authentication server is running" });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Kerberos authentication server running on port ${PORT}`);
    console.log(`Test the server with: curl -X POST -H "Content-Type: application/json" -d '{"username":"your_username","password":"your_password"}' http://localhost:${PORT}/auth/kerberos`);
}); 
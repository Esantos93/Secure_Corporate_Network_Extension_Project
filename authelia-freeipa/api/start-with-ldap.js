const { spawn } = require('child_process');
const path = require('path');

console.log('Starting LDAP authentication server, Kerberos server, and Expo app...');

// Start LDAP server
const ldapServer = spawn('node', [path.join(__dirname, 'ldap-server.js')], {
    stdio: 'inherit'
});

console.log('LDAP server started with PID:', ldapServer.pid);

// Start Kerberos server
const kerberosServer = spawn('node', [path.join(__dirname, 'kerberos-server.js')], {
    stdio: 'inherit'
});

console.log('Kerberos server started with PID:', kerberosServer.pid);

// Start Expo app
const expoApp = spawn('npx', ['expo', 'start'], {
    stdio: 'inherit'
});

console.log('Expo app started with PID:', expoApp.pid);

// Handle process termination
process.on('SIGINT', () => {
    console.log('Shutting down...');
    ldapServer.kill('SIGINT');
    kerberosServer.kill('SIGINT');
    expoApp.kill('SIGINT');
    process.exit(0);
});

// Handle child process exit
ldapServer.on('exit', (code) => {
    console.log(`LDAP server exited with code ${code}`);
    if (code !== 0 && code !== null) {
        console.error('LDAP server crashed. Shutting down other processes...');
        kerberosServer.kill('SIGINT');
        expoApp.kill('SIGINT');
        process.exit(1);
    }
});

kerberosServer.on('exit', (code) => {
    console.log(`Kerberos server exited with code ${code}`);
    if (code !== 0 && code !== null) {
        console.error('Kerberos server crashed. Shutting down other processes...');
        ldapServer.kill('SIGINT');
        expoApp.kill('SIGINT');
        process.exit(1);
    }
});

expoApp.on('exit', (code) => {
    console.log(`Expo app exited with code ${code}`);
    if (code !== 0 && code !== null) {
        console.error('Expo app crashed. Shutting down servers...');
        ldapServer.kill('SIGINT');
        kerberosServer.kill('SIGINT');
        process.exit(1);
    }
});
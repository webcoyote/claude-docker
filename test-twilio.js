#!/usr/bin/env node

// Test script to verify Twilio SMS functionality
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_API_SECRET;
const apiKey = process.env.TWILIO_API_KEY;
const fromNumber = process.env.TWILIO_FROM_NUMBER;
const toNumber = process.env.TWILIO_TO_NUMBER;

console.log('Twilio Test Configuration:');
console.log(`Account SID: ${accountSid?.substring(0, 10)}...`);
console.log(`API Key: ${apiKey?.substring(0, 10)}...`);
console.log(`From: ${fromNumber}`);
console.log(`To: ${toNumber}`);

// Using Twilio REST API directly
const https = require('https');

const auth = Buffer.from(`${apiKey}:${authToken}`).toString('base64');
const data = new URLSearchParams({
    To: toNumber,
    From: fromNumber,
    Body: 'MCP is working! This is a test message from Claude Docker.'
});

const options = {
    hostname: 'api.twilio.com',
    port: 443,
    path: `/2010-04-01/Accounts/${accountSid}/Messages.json`,
    method: 'POST',
    headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': data.toString().length
    }
};

const req = https.request(options, (res) => {
    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
        if (res.statusCode === 201) {
            console.log('\n✅ SMS sent successfully!');
            const response = JSON.parse(body);
            console.log(`Message SID: ${response.sid}`);
            console.log(`Status: ${response.status}`);
        } else {
            console.error('\n❌ Failed to send SMS');
            console.error(`Status: ${res.statusCode}`);
            console.error(`Response: ${body}`);
        }
    });
});

req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
});

req.write(data.toString());
req.end();
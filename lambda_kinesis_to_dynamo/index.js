const AWS = require('aws-sdk');
const Readline = require('readline');
const Util = require('util');
const Rx = require('rx');

const kinesis = new AWS.Kinesis();

// called when new data is available in kinesis and stores it in a DynamoDB table
exports.handler = function(event, context, callback) {
    //console.log(JSON.stringify(event, null, 2));
    event.Records.forEach(function(record) {
        // Kinesis data is base64 encoded so decode here
        const payload = new Buffer(record.kinesis.data, 'base64').toString('ascii');
        console.log('Decoded payload:', payload);
        let person = JSON.parse(payload);
        person["fullName"] = person.lastName + ',' + person.firstName;
    });
    callback(null, "message");
};

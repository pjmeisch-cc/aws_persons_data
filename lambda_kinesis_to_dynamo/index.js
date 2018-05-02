var AWS = require('aws-sdk');
var Readline = require('readline');
var Util = require('util');
var Rx = require('rx');

var s3 = new AWS.S3();
var kinesis = new AWS.Kinesis();

// called when new data is available in kinesis and stores it in a DynamoDB table
exports.handler = function(event, context, callback) {
    //console.log(JSON.stringify(event, null, 2));
    event.Records.forEach(function(record) {
        // Kinesis data is base64 encoded so decode here
        var payload = new Buffer(record.kinesis.data, 'base64').toString('ascii');
        console.log('Decoded payload:', payload);
    });
    callback(null, "message");
};

var AWS = require('aws-sdk');
var readline = require('readline');
var util = require('util');

// get reference to S3 client
var s3 = new AWS.S3();
var kinesis = new AWS.Kinesis();

exports.handler = (event, context, callback) => {
    // Read options from the event.
    console.log("Reading options from event:\n", util.inspect(event, {depth: 5}));
    var bucket = event.Records[0].s3.bucket.name;
    // Object key may have spaces or unicode non-ASCII characters.
    var key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));

    var params = {Bucket: bucket, Key: key};
    var rl = readline.createInterface({
        input: s3.getObject(params).createReadStream()
    });

    var numLines = 0;
    rl.on('line', function (line) {

        var params = {
            Data: line,
            PartitionKey: ('person' + line).substring(0, 100),
            StreamName: process.env.KINESIS_STREAM
        };
        kinesis.putRecord(params, function (err, data) {
            if (err) {
                console.log(err, err.stack);
            }
            else console.log(data);           // successful response
        });
        // var fields = line.split(',');
        // var record = {
        //     firstName: fields[0],
        //     lastName: fields[1],
        //     city: fields[2],
        //     street: fields[3],
        //     streetNumber: fields[4]
        // };
        // console.log(util.inspect(record, {depth: 2}));
        numLines++;
    })
    .on('close', function () {
        console.log('numLines: ' + numLines);
        callback(null, 'lambda call finished, #lines: ' + numLines);
    });
}
;

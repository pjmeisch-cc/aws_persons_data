const AWS = require('aws-sdk');
const Util = require('util');

const docClient = new AWS.DynamoDB.DocumentClient();

// called when new data is available in kinesis and stores it in a DynamoDB table
exports.handler = function (event, context, callback) {
    console.log("got event:\n", Util.inspect(event, {depth: 5}));
    let numRecords = event.Records.length;
    event.Records.forEach(record => {
        // Kinesis data is base64 encoded so decode here
        const payload = new Buffer(record.kinesis.data, 'base64').toString('ascii');
        console.log('payload: ', Util.inspect(payload, {depth: 5}));

        try {
            let person = JSON.parse(payload);
            // console.log('person: ', Util.inspect(person, {depth: 3}));
            person["fullName"] = person.lastName + ',' + person.firstName;
            // console.log('person: ', Util.inspect(person, {depth: 3}));

            // put is asynchronous
            docClient.put({
                "TableName": process.env.DYNAMODB_TABLE,
                "Item": person
            }, (err, data) => {
                if (err) {
                    console.log('Error putting item into dynamodb failed: ' + err);
                }
            });
        } catch (e) {
            console.log('payload is no person');
        }
    });

    const message = `processed ${numRecords} elements.`;
    console.log(message);
    callback(null, message);
};

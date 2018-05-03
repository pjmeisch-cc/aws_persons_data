const AWS = require('aws-sdk');

const docClient = new AWS.DynamoDB.DocumentClient();

// called when new data is available in kinesis and stores it in a DynamoDB table
exports.handler = function (event, context, callback) {
    let numRecords = event.Records.length;
    event.Records.forEach(record => {
        // Kinesis data is base64 encoded so decode here
        const payload = new Buffer(record.kinesis.data, 'base64').toString('ascii');

        let person = JSON.parse(payload);
        person["fullName"] = person.lastName + ',' + person.firstName;

        // put is asynchronous
        docClient.put({
            "TableName": process.env.DYNAMODB_TABLE,
            "Item": person
        }, (err, data) => {
            if (err) {
                console.log('Error putting item into dynamodb failed: ' + err);
            }
        });
    });

    const message = `processed ${numRecords} elements.`;
    console.log(message);
    callback(null, message);
};

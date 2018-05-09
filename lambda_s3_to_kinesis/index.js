const AWS = require('aws-sdk');
const Readline = require('readline');
const Util = require('util');
const Rx = require('rx');

const s3 = new AWS.S3();
const kinesis = new AWS.Kinesis();

// the method reads data from the file that is passed in the event (comes from a S3 bucket)
// the lines must be csv with 5 fields (firstName, lastName, city, street, streetNumber). These lines
// are converted to objects and then sent to kinesis in stringified form.
exports.handler = (event, context, callback) => {
    // Read options from the event.
    console.log("Reading options from event:\n", Util.inspect(event, {depth: 5}));
    const bucket = event.Records[0].s3.bucket.name;
    // Object key may have spaces or unicode non-ASCII characters.
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));


    const readline = Readline.createInterface({
        input: s3.getObject({Bucket: bucket, Key: key}).createReadStream()
    });

    const subject = new Rx.Subject();
    // pack it in an Observable (Subject is an Observable)
    readline
        .on('line', (line) => {
            subject.onNext(line);
        })
        .on('error', (error) => {
            subject.onError(error);
        })
        .on('close', () => {
            subject.onCompleted();
        });

    const numBuffers = 0;
    const numRecords = 0;

    subject
    // convert to person object
        .map((line) => {
            const fields = line.split(',');
            if (fields.length === 5) {
                return {
                    firstName: fields[0],
                    lastName: fields[1],
                    city: fields[2],
                    street: fields[3],
                    streetNumber: fields[4]
                };
            } else {
                return null;
            }
        })
        // filter illegal objects
        .filter((person) => {
            return person !== null;
        })
        // map to kinesis data
        .map((person) => {
            return {
                Data: JSON.stringify(person),
                PartitionKey: `person-${person.lastName}`
            }
        })
        // buffer for bulk adding
        .bufferWithCount(200)
        .subscribe(
            (kinesisDataArray) => {
                numBuffers++;
                numRecords += kinesisDataArray.length;

                kinesis.putRecords(
                    {
                        Records: kinesisDataArray,
                        StreamName: process.env.KINESIS_STREAM
                    },
                    function (err, data) {
                        if (err) {
                            console.log(err, err.stack);
                        }
                    });
            },
            (error) => {
                console.log(error);
                callback(error);
            },
            () => {
                const message = `finished after ${numBuffers} buffers with a total of ${numRecords} records.`;
                console.log(message);
                callback(null, message);
            }
        );
};

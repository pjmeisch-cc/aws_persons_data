const AWS = require('aws-sdk');
const Util = require('util');

const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  console.log("got event:\n", Util.inspect(event, { depth: 5 }));
  let field = event.field;
  let value = event.value;
  console.log(`have been asked to search in ${field} for ${value}`);

  var params = {
    ExpressionAttributeValues: {
      ':v': value
    },
    KeyConditionExpression: field + ' = :v',
    TableName: process.env.DYNAMODB_TABLE
  };
  if(field === 'lastName') {
    params['IndexName'] = process.env.DYNAMODB_TABLE_INDEX2;
  }
  
  docClient.query(params, function(err, data) {
    if (err) {
      console.log("Error", err);
      callback(err);
    }
    else {
      callback(null, data.Items);
    }
  });
};


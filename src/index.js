const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event, context) => {
  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json"
  };

  try {
    switch (event.routeKey) {
      case "DELETE /layouts/{id}":
        await dynamo
          .delete({
            TableName: "Layout",
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
          
        body = `Deleted layout ${event.pathParameters.id}`;
        break;
      case "GET /layouts/{id}":
        body = await dynamo
          .get({
            TableName: "Layout",
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();       
        break;
      case "GET /layouts":
        body = await dynamo
          .scan({ TableName: "Layout" })
          .promise();
        break;
      case "PUT /layouts":
        let requestJSON = JSON.parse(event.body);

        await dynamo
          .put({
            TableName: "Layout",
            Item: {
              id: requestJSON.id,
              store_name: requestJSON.store_name,
              floors: requestJSON.floors,
            }
          })
          .promise();
        body = `Put layout ${requestJSON.id}`;
        break;
      default:
        throw new Error(`Unsupported route: "${event.routeKey}"`);
    }
  } catch (err) {
    statusCode = 400;
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers
  };
};
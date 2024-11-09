import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ExampleDynamoDBTable')

def lambda_handler(event, context):
    response = table.update_item(
        Key={
            'id': 'visitor_count'
        },
        UpdateExpression="set visitorCount = visitorCount + :inc",
        ExpressionAttributeValues={
            ':inc': 1
        },
        ReturnValues="UPDATED_NEW"
    )
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',  # Allows requests from any origin
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',  # Allowed methods
            'Access-Control-Allow-Headers': '*'  # Allowed headers
        },
        'body': str(response['Attributes']['visitorCount'])
    }
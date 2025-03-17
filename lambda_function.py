import base64
import json

def lambda_handler(event, context):
    output = []
    for record in event['records']:
        payload = base64.b64decode(record['data'])
        data = json.loads(payload)
        log_event = {
            "event": data['logEvents'][0]['message'],
            "source": data['logStream'],
            "sourcetype": "aws:cloudwatchlogs",
            "time": str(data['logEvents'][0]['timestamp'] / 1000)
        }
        output.append({
            'recordId': record['recordId'],
            'result': 'Ok',
            'data': base64.b64encode(json.dumps(log_event).encode('utf-8')).decode('utf-8')
        })
    return {'records': output}

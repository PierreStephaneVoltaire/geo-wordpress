import json

def handler(event, context):
    ireland_alb_dns = "${ireland_alb_dns}"
    singapore_alb_dns = "${singapore_alb_dns}"
    
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    try:
        country = headers.get('cloudfront-viewer-country', [{'value': 'US'}])[0]['value']
    except (KeyError, IndexError):
        country = 'US' 
    
    uri = request.get('uri', '/')
    querystring = request.get('querystring', '')
    if querystring:
        uri += f'?{querystring}'
    

    if country == 'IE':
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{ireland_alb_dns}{uri}'
                }]
            }
        }
        return response
    # Singapore, Canada, US go to Singapore ALB
    elif country in ['SG', 'CA', 'US']:
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{singapore_alb_dns}{uri}'
                }]
            }
        }
        return response
    else:
        # All other countries get denied
        response = {
            'status': '403',
            'statusDescription': 'Forbidden',
            'headers': {
                'content-type': [{
                    'key': 'Content-Type',
                    'value': 'text/plain'
                }]
            },
            'body': 'Access denied from this location'
        }
        return response
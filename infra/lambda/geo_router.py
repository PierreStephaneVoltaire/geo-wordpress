import json

def handler(event, context):
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    # Get CloudFront viewer country
    country = headers.get('cloudfront-viewer-country', [{'value': 'US'}])[0]['value']
    
    # Only Ireland goes to Ireland ALB
    # Default to Singapore, redirect Ireland to Ireland ALB
    if country == 'IE':
        # Redirect to Ireland ALB
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{ireland_alb_dns}{request["uri"]}'
                }]
            }
        }
        return response
    # Singapore, Canada, US go to Singapore ALB
    elif country in ['SG', 'CA', 'US']:
        # Redirect to Singapore ALB (default)
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{singapore_alb_dns}{request["uri"]}'
                }]
            }
        }
        return response
    else:
        # All other countries get denied
        response = {
            'status': '403',
            'statusDescription': 'Forbidden',
            'body': 'Access denied from this location'
        }
        return response
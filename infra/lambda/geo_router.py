import json

def handler(event, context):
    # Dynamic region to ALB DNS mapping
    region_alb_dns = ${jsonencode(region_alb_dns)}
    
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
    
    # Country to region mapping
    country_to_region = {
        'IE': 'ireland',
        'SG': 'singapore',
        'CA': 'singapore',
        'US': 'singapore',
    }
    
    # Get the target region based on country, default to primary region
    target_region = country_to_region.get(country, 'singapore')
    
    # Check if the target region exists in our deployment
    if target_region in region_alb_dns:
        target_alb = region_alb_dns[target_region]
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{target_alb}{uri}'
                }]
            }
        }
        return response
    else:
        # If target region doesn't exist, use the first available region
        fallback_alb = list(region_alb_dns.values())[0]
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': f'https://{fallback_alb}{uri}'
                }]
            }
        }
        return response
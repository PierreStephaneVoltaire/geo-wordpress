# Python Lambda@Edge function for geo-routing
import json

# Geo-routing configuration
REGIONS = {
%{ for region_name, config in regions ~}
    '${region_name}': {
        'region': '${config.region}',
        'countries': ${jsonencode(region_name == "singapore" ? ["SG", "MY", "TH", "ID", "VN", "PH", "KH", "LA", "MM", "BN"] : ["IE", "GB", "FR", "DE", "NL", "BE", "ES", "PT", "IT", "AT", "CH", "DK", "SE", "NO", "FI"])}
    },
%{ endfor ~}
}

DEFAULT_REGION = '${keys(regions)[0]}'

def lambda_handler(event, context):
    """
    Lambda@Edge Origin Request function for geo-routing WordPress requests
    """
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    # Get the CloudFront-Viewer-Country header
    country = None
    if 'cloudfront-viewer-country' in headers:
        country = headers['cloudfront-viewer-country'][0]['value']
    
    print(f"Request from country: {country}")
    
    # Determine the target region based on country
    target_region = DEFAULT_REGION
    
    if country:
        for region_name, config in REGIONS.items():
            if country in config['countries']:
                target_region = region_name
                break
    
    print(f"Routing to region: {target_region}")
    
    # Update the origin to the appropriate ALB
    # Note: The actual ALB domain names will be updated by Terraform
    request['origin'] = {
        'custom': {
            'domainName': f"alb-{target_region}.example.com",
            'port': 80,
            'protocol': 'http',
            'path': ''
        }
    }
    
    # Add custom headers for debugging
    request['headers']['x-routed-region'] = [
        {'key': 'X-Routed-Region', 'value': target_region}
    ]
    request['headers']['x-viewer-country'] = [
        {'key': 'X-Viewer-Country', 'value': country or 'unknown'}
    ]
    
    return request
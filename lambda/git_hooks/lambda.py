from __future__ import print_function

import json, urllib3, boto3, certifi, os, copy

# based from original source: http://eq8.herokuapp.com/tils/31-aws-lambda-to-configure-ec2-security-group-for-cloudfront-access

def lambda_handler(event, context):
    http = urllib3.PoolManager(cert_reqs='CERT_REQUIRED', ca_certs=certifi.where())
    r = http.request(
        'GET',
        'https://api.github.com/meta',
        headers={
            'User-Agent': 'Python-URLLIB3'
        })
    json_data = json.loads(r.data.decode('utf-8'))
    new_ip_ranges = json_data['hooks']

    ec2 = boto3.resource('ec2')
    security_group = ec2.SecurityGroup(os.environ.get('SG'))
    if not security_group.ip_permissions:
        current_ip_ranges = []
        current_ip_ranges443 = []
    else:
        current_ip_ranges = []
        current_ip_ranges443 = []
        for x in security_group.ip_permissions:
            if x['ToPort'] == 80:
                current_ip_ranges = [ x['CidrIp'] for x in x['IpRanges'] ]
            if x['ToPort'] == 443:
                current_ip_ranges443 = [ x['CidrIp'] for x in x['IpRanges'] ]

    for port in [ 80, 443 ]:
        params_dict = {
            u'PrefixListIds': [],
            u'FromPort': port,
            u'IpRanges': [],
            u'ToPort': port,
            u'IpProtocol': 'tcp',
            u'UserIdGroupPairs': []
        }

        authorize_dict = copy.deepcopy(params_dict)
        for ip in new_ip_ranges:
            if port == 80:
                if ip not in current_ip_ranges:
                    authorize_dict['IpRanges'].append({u'CidrIp': ip})
                auth80 = authorize_dict['IpRanges']
            if port == 443:
                if ip not in current_ip_ranges443:
                    authorize_dict['IpRanges'].append({u'CidrIp': ip})
                auth443 = authorize_dict['IpRanges']
        security_group.authorize_ingress(IpPermissions=[authorize_dict])

        revoke_dict = copy.deepcopy(params_dict)
        if port == 80:
            if len(current_ip_ranges) != 0:
                for ip in current_ip_ranges:
                    if ip not in new_ip_ranges:
                        revoke_dict['IpRanges'].append({u'CidrIp': ip})
                security_group.revoke_ingress(IpPermissions=[revoke_dict])
            else:
                revoke_dict['IpRanges'] = []

            revoke80 = revoke_dict['IpRanges']
        if port == 443:
            if len(current_ip_ranges443) != 0:
                for ip in current_ip_ranges443:
                    if ip not in new_ip_ranges:
                        revoke_dict['IpRanges'].append({u'CidrIp': ip})
                security_group.revoke_ingress(IpPermissions=[revoke_dict])
            else:
                revoke_dict['IpRanges'] = []

            revoke443 = revoke_dict['IpRanges']

    result = {'authorizedPort80': auth80, 'revokedPort80': revoke80, 'authorizedPort443': auth443, 'revokedPort443': revoke443}
    print(result)

    returndata = { "statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": "Update complete!" }
    return returndata
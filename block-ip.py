  GNU nano 6.2                                                                                     /var/ossec/active-response/bin/block-ip.py                                                                                               
#!/usr/bin/env python3
import sys
import json
import boto3

# --- CONFIGURATION ---
NACL_ID = "acl-**************"  # <--- REPLACE WITH YOUR NETWORK ACL ID
AWS_REGION = "us-east-1"      # Ensure this matches your AWS region

def main():
    # Read alert from Wazuh
    alert_json = sys.stdin.read()
    alert = json.loads(alert_json)

    # Exit if not our brute-force rule
    if alert["parameters"]["alert"]["rule"]["id"] != "100100":
        sys.exit(0)

    # Extract attacker IP
    try:
        attacker_ip = alert["parameters"]["alert"]["data"]["srcip"]
    except KeyError:
        sys.exit(0)

    # Block the IP using the AWS API
    try:
        ec2 = boto3.client('ec2', region_name=AWS_REGION)
        ec2.create_network_acl_entry(
            NetworkAclId=NACL_ID,
            RuleNumber=101,  # Use a rule number that is not in use
            Protocol='-1',   # -1 means all protocols
            RuleAction='deny',
            Egress=False,    # This is an ingress (inbound) rule
            CidrBlock=f'{attacker_ip}/32'
        )
    except Exception:
        # Fails silently if the rule already exists for this IP
        pass

if __name__ == "__main__":
    main()



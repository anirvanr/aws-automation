#!/bin/bash
#Bitbucket Whitelist IP Addresses

# CONFIG - Only edit the below lines to setup the script
# ===============================
# AWS Profile Name
profile="default"

# Port
port=443;

# VPC id
vpc_id="vpc-1a2b3c4d"

# DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
# ===============================
temp_file="$(mktemp bitbucket_ips.XXXXXX)"

## Get the list of IP Addresses from Bitbucket
curl -s https://ip-ranges.atlassian.com/ | jq .items[].cidr | sed -e 's/"//g' | grep -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$" > ${temp_file}

## Format response to separate files
split -l 60 ${temp_file} segment

## Store filename into array
segmentfile_array=(`ls -d *segment*`)

## Store array length
counter=${#segmentfile_array[@]}

for i in ${segmentfile_array[@]}
  do
    # Create security group
    echo -e "------------------------------------------------"
    echo -e "\033[32mCreating Security Group:\033[0m \033[33mBitbucketSecurityGroup${counter}\033[0m"
    echo -e "------------------------------------------------"

    # Store the security group 
    sg_id="$(aws ec2 create-security-group --group-name BitbucketSecurityGroup${counter} --description "bitbucket security group" --vpc-id ${vpc_id} --output text)"
        # Store IPs into array
        IFS=$'\n' read -d '' -r -a lines < ${i}
        fixed_ips="${lines[@]}"
        # Loop through fixed IPs
        for ip in ${fixed_ips}
        do
            echo -e "\033[32mSetting Fixed IP:\033[0m ${ip}"    
            # Add fixed IP rules
            aws ec2 authorize-security-group-ingress --profile=${profile} --protocol tcp --port ${port} --cidr ${ip} --group-id ${sg_id}
        done
    counter=$((counter-1));
  done

## Cleanup
rm -rf ${temp_file} *segment*

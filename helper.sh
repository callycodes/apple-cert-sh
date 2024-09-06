#!/bin/bash

# Take a string input from the user
echo "Please enter your project name:"
read projectName

# Create a directory with the project name
mkdir $projectName || continue

# Change to the created directory
cd $projectName

# Generate a random password
password=$(openssl rand -base64 16 | tr -d '+/' | cut -c1-16)

# Log the password
echo "Generated password: $password" > passphrase.txt

# Generate the signerKey.key file
openssl genrsa -out signerKey.key -passout pass:"${password}" 2048

# Source the .env file to get the email
if [ -f ../.env ]; then
    source ../.env
else
    echo "Error: .env file not found"
    exit 1
fi

# Check if the email was successfully read
if [ -z "$EMAIL" ]; then
    echo "Error: No email found in .env"
    exit 1
fi

# Create the file.cnf file with the email from .env
cat > file.cnf << EOF
[req]
input_password = $password
prompt = no
distinguished_name = cert_req

[cert_req]
commonName = Apple Worldwide Developer Relations Certification Authority
countryName = US
stateOrProvinceName = United States
localityName = EMPTY
organizationName = Apple Inc
organizationalUnitName = IT
emailAddress = $EMAIL
EOF

# Create the request.certSigningRequest file
openssl req -new -key signerKey.key -config file.cnf -out request.certSigningRequest
echo "1. Upload the request.certSigningRequest from the new folder at https://developer.apple.com/account/resources/identifiers/passTypeId/add/"
echo "2. Download the certificate and place it in the new folder (script looks for .cer files)"

echo "Once you've done these steps press Y to continue:"
read input
if [ "$input" == "Y" ]; then
    # Find the .cer file in the directory
    cerFile=$(ls *.cer)

    # Run the final openssl command
    openssl x509 -inform DER -outform PEM -in "$cerFile" -out signerCert.pem

    # Read and format the signerKey.key into a single line with \n replacements
    keyContent=$(cat signerKey.key | tr '\n' '\\' | sed 's/\\$/\\n/' | tr -d '\n')

    # Read and format the signerCert.pem into a single line with \n replacements
    certContent=$(cat signerCert.pem | tr '\n' '\\' | sed 's/\\$/\\n/' | tr -d '\n')

    # Use 'cat' with 'EOF' to output the formatted contents to 'output.txt'
    cat > output.txt << EOF
key
${keyContent}

cert
${certContent}
EOF
fi
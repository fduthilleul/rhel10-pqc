# Verify which crypto packages are already installed
rpm -qa | grep crypto
# Verify if there are updated packages
dnf check-update crypto-policies crypto-policies-scripts
# Display the information about these crypto packages
dnf info crypto-policies crypto-policies-scripts
# Show the system-wide crypto current setting
update-crypto-policies --show
# Show the list of OpenSSL providers
openssl list -providers
# Install the TEST-PQ crypto policies
dnf install crypto-policies-pq-preview
# Set the system wide crypto to TEST-PQ
update-crypto-policies --set DEFAULT:TEST-PQ
# Show the PQ algorithms supported for SSH
ssh -Q kex
# Update SSH Config to use these algorithms
vi /etc/ssh/ssh_config
# Add kexAlgorithms mlkem768x25519-sha256
# Restart SSHD service
systemctl restart sshd
# Connect to a server configured also with TEST-PQ using verbose mode
ssh -v root@IP address
# Generate keys, sign messages and verify signaturees
# List openSSL signature algorithms
openssl list -signature-algorithms
# Generate a private key
openssl genpkey -algorithm mldsa65 -out mldsa-privatekey.pem
# Generate a public key
openssl pkey -in mldsa-privatekey.pem -pubout -out mldsa-publickey.pem
# Sign a message
openssl dgst -sign mldsa-privatekey.pem -out signature message
# Verify the signature of the signed message
openssl dgst -verify mldsa-publickey.pem -signature signature message
# Create a post-quantum TLS certificate
openssl req \
    -x509 \
    -newkey mldsa65 \
    -keyout localhost-mldsa.key \
    -subj /CN=localhost \
    -addext subjectAltName=DNS:localhost \
    -days 30 \
    -nodes \
    -out localhost-mldsa.crt
# Establish a post quantum connection
openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key
openssl s_client -connect localhost:4433 -CAfile localhost-mldsa.crt </dev/null |& grep -E '(Peer signature type|Negotiated TLS1.3 group)'

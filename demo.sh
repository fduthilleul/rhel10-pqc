#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to prompt user to continue
prompt_continue() {
    echo -e "\n${YELLOW}Press 'y' to continue to the next step (or any other key to exit): ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Exiting demo.${NC}"
        exit 0
    fi
}

# Function to display step header
show_step() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

# Verify RHEL 10
echo -e "${BLUE}Checking Operating System...${NC}\n"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "rhel" && "${VERSION_ID%%.*}" == "10" ]]; then
        echo -e "${GREEN}✓ RHEL 10 detected: $PRETTY_NAME${NC}"
    else
        echo -e "${RED}✗ This demo requires RHEL 10${NC}"
        echo -e "${RED}  Current OS: $PRETTY_NAME${NC}"
        echo -e "${RED}  Exiting...${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Cannot detect OS version. This demo requires RHEL 10.${NC}"
    exit 1
fi

prompt_continue

# Step 1: Verify installed crypto packages
show_step "Step 1: Verify which crypto packages are already installed"
rpm -qa | grep crypto
prompt_continue

# Step 2: Check for updates
show_step "Step 2: Verify if there are updated packages"
dnf check-update crypto-policies crypto-policies-scripts
prompt_continue

# Step 3: Display package information
show_step "Step 3: Display the information about these crypto packages"
dnf info crypto-policies crypto-policies-scripts
prompt_continue

# Step 4: Show current crypto setting
show_step "Step 4: Show the system-wide crypto current setting"
update-crypto-policies --show
prompt_continue

# Step 5: Show OpenSSL providers
show_step "Step 5: Show the list of OpenSSL providers"
openssl list -providers
prompt_continue

# Step 6: Install TEST-PQ crypto policies
show_step "Step 6: Install the TEST-PQ crypto policies"
dnf install -y crypto-policies-pq-preview
prompt_continue

# Step 7: Set system wide crypto to TEST-PQ
show_step "Step 7: Set the system wide crypto to DEFAULT:TEST-PQ"
update-crypto-policies --set DEFAULT:TEST-PQ
prompt_continue

# Step 8: Show PQ algorithms for SSH
show_step "Step 8: Show the PQ algorithms supported for SSH"
ssh -Q kex
prompt_continue

# Step 9: Update SSH Config
show_step "Step 9: Update SSH Config to use PQ algorithms"
echo -e "${YELLOW}Opening SSH config file for editing...${NC}"
echo -e "${YELLOW}Add the following line after 'Host *':${NC}"
echo -e "${GREEN}    KexAlgorithms mlkem768x25519-sha256${NC}\n"
prompt_continue
vi /etc/ssh/ssh_config
prompt_continue

# Step 10: Restart SSHD service
show_step "Step 10: Restart SSHD service"
systemctl restart sshd
echo -e "${GREEN}✓ SSHD service restarted${NC}"
prompt_continue

# Step 11: Connect to remote server
show_step "Step 11: Connect to a server configured with TEST-PQ (verbose mode)"
echo -e "${YELLOW}Note: Replace 'IP_ADDRESS' with the actual server IP${NC}"
echo -e "${YELLOW}Command: ssh -v root@IP_ADDRESS${NC}\n"
echo -e "${YELLOW}Press 'y' to skip this step or enter IP address to connect:${NC}"
read -r IP_INPUT
if [[ ! $IP_INPUT =~ ^[Yy]$ ]] && [[ -n "$IP_INPUT" ]]; then
    ssh -v root@"$IP_INPUT"
fi
prompt_continue

# Step 12: Generate and verify signatures
show_step "Step 12: List OpenSSL signature algorithms"
openssl list -signature-algorithms
prompt_continue

show_step "Step 13: Generate a private key (MLDSA65)"
openssl genpkey -algorithm mldsa65 -out mldsa-privatekey.pem
echo -e "${GREEN}✓ Private key generated: mldsa-privatekey.pem${NC}"
prompt_continue

show_step "Step 14: Generate a public key"
openssl pkey -in mldsa-privatekey.pem -pubout -out mldsa-publickey.pem
echo -e "${GREEN}✓ Public key generated: mldsa-publickey.pem${NC}"
prompt_continue

show_step "Step 15: Create a test message and sign it"
echo "This is a test message for post-quantum cryptography" > message
openssl dgst -sign mldsa-privatekey.pem -out signature message
echo -e "${GREEN}✓ Message signed: signature${NC}"
prompt_continue

show_step "Step 16: Verify the signature of the signed message"
openssl dgst -verify mldsa-publickey.pem -signature signature message
prompt_continue

# Step 17: Create PQ TLS certificate
show_step "Step 17: Create a post-quantum TLS certificate"
openssl req \
    -x509 \
    -newkey mldsa65 \
    -keyout localhost-mldsa.key \
    -subj /CN=localhost \
    -addext subjectAltName=DNS:localhost \
    -days 30 \
    -nodes \
    -out localhost-mldsa.crt
echo -e "${GREEN}✓ Certificate created: localhost-mldsa.crt${NC}"
prompt_continue

# Step 18: Establish post-quantum connection
show_step "Step 18: Establish a post-quantum TLS connection"
echo -e "${YELLOW}Starting OpenSSL server in background...${NC}"
echo -e "${YELLOW}Command: openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key${NC}\n"
echo -e "${YELLOW}In another terminal, you can connect with:${NC}"
echo -e "${GREEN}openssl s_client -connect localhost:4433 -CAfile localhost-mldsa.crt${NC}\n"
echo -e "${YELLOW}Or test automatically (recommended):${NC}"
prompt_continue

# Start server in background and test
openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key &
SERVER_PID=$!
sleep 2

echo -e "\n${YELLOW}Testing connection...${NC}\n"
openssl s_client -connect localhost:4433 -CAfile localhost-mldsa.crt </dev/null 2>&1 | grep -E '(Peer signature type|Negotiated TLS1.3 group)'

# Cleanup
kill $SERVER_PID 2>/dev/null

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Demo completed successfully!${NC}"
echo -e "${GREEN}================================${NC}\n"

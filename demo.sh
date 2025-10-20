#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to prompt user to continue using y
#prompt_continue() {
#    echo -e "\n${YELLOW}Press 'y' to continue to the next step (or any other key to exit): ${NC}"
#    read -n 1 -r
#    echo
#    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#        echo -e "${RED}Exiting demo.${NC}"
#        exit 0
#    fi
#}

# Function to prompt user to continue
prompt_continue() {
    echo -e "\n${YELLOW}Press SPACE to continue to the next step (or any other key to exit): ${NC}"
    read -n 1 -r
    echo
    if [[ "$REPLY" != " " ]]; then
        echo -e "${RED}Exiting demo.${NC}"
        exit 0
    fi
}

# Function to display step header
show_step() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to display command
show_command() {
    echo -e "${GREEN}Command: ${NC}$1\n"
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

# Clean up directory
show_step "Setting up the demo"
#show_command "rm -f mldsa-privatekey.pem mldsa-publickey.pem message signature localhost-mldsa.key localhost-mldsa.crt"
rm -f mldsa-privatekey.pem mldsa-publickey.pem message signature localhost-mldsa.key localhost-mldsa.crt
echo -e "${GREEN}✓ Cleanup completed${NC}"
#prompt_continue

# Reset crypto policies to DEFAULT
#show_step "Reset: Setting crypto policy back to DEFAULT"
#show_command "update-crypto-policies --show"
CURRENT_POLICY=$(update-crypto-policies --show)
#echo "Current policy: $CURRENT_POLICY"

if [[ "$CURRENT_POLICY" != "DEFAULT" ]]; then
    echo ""
#    show_command "update-crypto-policies --set DEFAULT"
    update-crypto-policies --set DEFAULT &
    echo -e "${GREEN}✓ Crypto policy reset to DEFAULT${NC}"
else
    echo -e "${GREEN}✓ Already set to DEFAULT${NC}"
fi
#prompt_continue

# Remove crypto-policies-pq-preview if installed
#show_step "Reset: Removing crypto-policies-pq-preview if installed"
#show_command "rpm -qa | grep crypto-policies-pq-preview"
if rpm -qa | grep -q crypto-policies-pq-preview; then
    echo ""
    show_command "dnf remove -y crypto-policies-pq-preview"
    dnf remove -y crypto-policies-pq-preview
    echo -e "${GREEN}✓ Package removed${NC}"
else
    echo -e "${GREEN}✓ Package not installed${NC}"
fi
#prompt_continue

# Ask user for custom message
show_step "Setup: Enter your custom message for signing"
echo -e "${YELLOW}Please type the message that will be signed in this demo:${NC}"
read -r USER_MESSAGE
if [[ -z "$USER_MESSAGE" ]]; then
    USER_MESSAGE="This is a test message for post-quantum cryptography"
fi
echo -e "${GREEN}✓ Message saved: ${NC}$USER_MESSAGE"
#prompt_continue

# Step 1: Verify installed crypto packages
show_step "Step 1: Verify which crypto packages are already installed"
show_command "rpm -qa | grep crypto"
rpm -qa | grep crypto
prompt_continue

# Step 2: Check for updates
show_step "Step 2: Verify if there are updated packages"
show_command "dnf check-update crypto-policies crypto-policies-scripts"
dnf check-update crypto-policies crypto-policies-scripts
prompt_continue

# Step 3: Display package information
show_step "Step 3: Display the information about these crypto packages"
show_command "dnf info crypto-policies crypto-policies-scripts"
dnf info crypto-policies crypto-policies-scripts
prompt_continue

# Step 4: Show current crypto setting
show_step "Step 4: Show the system-wide crypto current setting"
show_command "update-crypto-policies --show"
update-crypto-policies --show
prompt_continue

# Step 5: Show OpenSSL providers
show_step "Step 5: Show the list of OpenSSL providers"
show_command "openssl list -providers"
openssl list -providers
prompt_continue

# Step 6: Install TEST-PQ crypto policies
show_step "Step 6: Install the TEST-PQ crypto policies"
show_command "dnf install -y crypto-policies-pq-preview"
dnf install -y crypto-policies-pq-preview
prompt_continue

# Step 7: Set system wide crypto to TEST-PQ
show_step "Step 7: Set the system wide crypto to DEFAULT:TEST-PQ"
show_command "update-crypto-policies --set DEFAULT:TEST-PQ"
update-crypto-policies --set DEFAULT:TEST-PQ
prompt_continue

# Step 8: Show PQ algorithms for SSH
show_step "Step 8: Show the PQ algorithms supported for SSH"
show_command "ssh -Q kex"
ssh -Q kex
prompt_continue

# Step 9: Update SSH Config
show_step "Step 9: Update SSH Config to use PQ algorithms"
echo -e "${YELLOW}Opening SSH config file for editing...${NC}"
echo -e "${YELLOW}Add the following line after 'Host *':${NC}"
echo -e "${GREEN}    KexAlgorithms mlkem768x25519-sha256${NC}\n"
show_command "vi /etc/ssh/ssh_config"
prompt_continue
vi /etc/ssh/ssh_config
#prompt_continue

# Step 10: Restart SSHD service
show_step "Step 10: Restart SSHD service"
show_command "systemctl restart sshd"
systemctl restart sshd
echo -e "${GREEN}✓ SSHD service restarted${NC}"
#prompt_continue

# Step 11: Connect to remote server
show_step "Step 11: Connect to a server configured with TEST-PQ (verbose mode)"
echo -e "${YELLOW}Please enter the IP address of the remote server:${NC}"
read -r IP_ADDRESS
if [[ -n "$IP_ADDRESS" ]]; then
    echo ""
    show_command "ssh -v root@$IP_ADDRESS"
    ssh -v root@"$IP_ADDRESS"
else
    echo -e "${YELLOW}Skipping SSH connection test${NC}"
fi
prompt_continue

# Step 12: Generate and verify signatures
show_step "Step 12: List OpenSSL signature algorithms"
show_command "openssl list -signature-algorithms"
openssl list -signature-algorithms
prompt_continue

show_step "Step 13: Generate a private key (MLDSA65)"
show_command "openssl genpkey -algorithm mldsa65 -out mldsa-privatekey.pem"
openssl genpkey -algorithm mldsa65 -out mldsa-privatekey.pem
echo -e "${GREEN}✓ Private key generated: mldsa-privatekey.pem${NC}"
prompt_continue

show_step "Step 14: Generate a public key"
show_command "openssl pkey -in mldsa-privatekey.pem -pubout -out mldsa-publickey.pem"
openssl pkey -in mldsa-privatekey.pem -pubout -out mldsa-publickey.pem
echo -e "${GREEN}✓ Public key generated: mldsa-publickey.pem${NC}"
prompt_continue

show_step "Step 15: Create a test message and sign it"
show_command "echo \"$USER_MESSAGE\" > message"
echo "$USER_MESSAGE" > message
echo -e "${GREEN}✓ Message file created${NC}\n"
show_command "openssl dgst -sign mldsa-privatekey.pem -out signature message"
openssl dgst -sign mldsa-privatekey.pem -out signature message
echo -e "${GREEN}✓ Message signed: signature${NC}"
prompt_continue

show_step "Step 16: Verify the signature of the signed message"
show_command "openssl dgst -verify mldsa-publickey.pem -signature signature message"
openssl dgst -verify mldsa-publickey.pem -signature signature message
prompt_continue

# Step 17: Create PQ TLS certificate
show_step "Step 17: Create a post-quantum TLS certificate"
show_command "openssl req -x509 -newkey mldsa65 -keyout localhost-mldsa.key -subj /CN=localhost -addext subjectAltName=DNS:localhost -days 30 -nodes -out localhost-mldsa.crt"
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
echo -e "${YELLOW}This will start an OpenSSL server on port 4433.${NC}"
echo -e "${YELLOW}You need to open ANOTHER TERMINAL TAB and run the client command.${NC}\n"
echo -e "${GREEN}Copy and paste this command in the new tab:${NC}"
echo -e "${CYAN}openssl s_client -connect localhost:4433 -CAfile localhost-mldsa.crt${NC}\n"
echo -e "${YELLOW}Press SPACE when ready to start the server:${NC}"
read -n 1 -r
echo

# Set up trap to handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}================================${NC}"; echo -e "${GREEN}Demo completed successfully!${NC}"; echo -e "${GREEN}================================${NC}\n"; exit 0' SIGINT

if [[ "$REPLY" == " " ]]; then
    echo ""
    show_command "openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key"
    echo -e "${GREEN}Starting server... (Press Ctrl+C to stop when done testing)${NC}\n"
    openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key
fi

show_step "What have we seen in this demo"
echo -e "${GREEN}✓ Post-quantum key exchange in SSH${NC}"
echo -e "${GREEN}✓ Post-quantum signatures${NC}"
echo -e "${GREEN}✓ Post-quantum TLS certificate${NC}"
echo -e "${GREEN}✓ Post-quantum TLS session establishment${NC}"

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Next time it will be OpenShift :-)${NC}"
echo -e "${GREEN}================================${NC}\n"

rpm -qa | grep crypto
dnf check-update crypto-policies crypto-policies-scripts
dnf info crypto-policies crypto-policies-scripts
update-crypto-policies --show
openssl list -providers
dnf install crypto-policies-pq-preview
update-crypto-policies --set DEFAULT:TEST-PQ
ssh -Q kex
vi /etc/ssh/ssh_config
# Add kexAlgorithms mlkem768x25519-sha256
systemctl restart sshd
ssh -v root@
openssl list -signature-algorithms
openssl genpkey -algorithm mldsa65 -out mldsa-privatekey.pem
openssl pkey -in mldsa-privatekey.pem -pubout -out mldsa-publickey.pem
openssl dgst -sign mldsa-privatekey.pem -out signature message
openssl dgst -verify mldsa-publickey.pem -signature signature message
openssl s_server -cert localhost-mldsa.crt -key localhost-mldsa.key
openssl s_client -connect localhost:4433 -CAfile localhost-mldsa.crt </dev/null |& grep -E '(Peer signature type|Negotiated TLS1.3 group)'

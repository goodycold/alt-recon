#!/bin/bash

DOMAIN=${1:-altschoolafrica.com}

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="scan_${DOMAIN}_${TIMESTAMP}"

mkdir -p "$OUTPUT_DIR"

echo "[+] Starting reconnaissance scan"
echo "[+] Target: $DOMAIN"
echo "[+] Output Directory: $OUTPUT_DIR"
echo

check_tool() {
if ! command -v "$1" >/dev/null 2>&1; then
echo "[!] $1 is not installed. Skipping..."
return 1
fi
return 0
}


echo "[+] Running WHOIS..."

if check_tool whois; then
whois "$DOMAIN" > "$OUTPUT_DIR/whois_report.txt" 2>&1 || 
echo "WHOIS scan failed." >> "$OUTPUT_DIR/whois_report.txt"
fi



echo "[+] Running DNS Enumeration..."

if check_tool nslookup; then
{
echo "===== A RECORD ====="
nslookup "$DOMAIN"

echo
echo "===== MX RECORD ====="
nslookup -type=mx "$DOMAIN"

echo
echo "===== NS RECORD ====="
nslookup -type=ns "$DOMAIN"

echo
echo "===== TXT RECORD ====="
nslookup -type=txt "$DOMAIN"

} > "$OUTPUT_DIR/dns_report.txt" 2>&1
fi



echo "[+] Running Passive Subdomain Enumeration..."

if check_tool amass; then
    amass enum -passive -d "$DOMAIN" > /dev/null 2>&1

    if ! amass db -names -d "$DOMAIN" > "$OUTPUT_DIR/amass_report.txt" 2>&1; then
        echo "Amass scan failed." >> "$OUTPUT_DIR/amass_report.txt"
    fi
fi



echo "[+] Running DNS Brute Force Enumeration..."

if check_tool gobuster; then

WORDLIST="/usr/share/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt"

if [ -f "$WORDLIST" ]; then
    gobuster dns \
        -d "$DOMAIN" \
        -w "$WORDLIST" \
        -o "$OUTPUT_DIR/gobuster_report.txt" \
        > /dev/null 2>&1 \
        || echo "Gobuster scan failed." >> "$OUTPUT_DIR/gobuster_report.txt"
else
    echo "Wordlist not found: $WORDLIST" \
    > "$OUTPUT_DIR/gobuster_report.txt"
fi


fi

echo "[+] Running TLS/HTTPS Analysis..."

TESTSSL_PATH="$HOME/testssl.sh/testssl.sh"

if [ -f "$TESTSSL_PATH" ]; then
    if ! bash "$TESTSSL_PATH" "$DOMAIN" > "$OUTPUT_DIR/tls_report.txt" 2>&1; then
        echo "TLS scan failed." >> "$OUTPUT_DIR/tls_report.txt"
    fi
else
    echo "testssl.sh not found at $TESTSSL_PATH" > "$OUTPUT_DIR/tls_report.txt"
fi



echo
echo "[+] Scan Complete"
echo "[+] Reports saved in:"
echo " $OUTPUT_DIR"

ls -1 "$OUTPUT_DIR"






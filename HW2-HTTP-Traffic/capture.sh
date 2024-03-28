#!/bin/bash

# Check if all arguments are provided
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <output_directory> <output_file_prefix> <num_curls> <url1> [<url2> ... <urlN>]"
    exit 1
fi

output_directory="$1"
output_file_prefix="$2"
num_curls="$3"
shift 3  # Remove the first three arguments, leaving only the URLs

# Function to get IP address from URL
get_ip_address() {
    python3 - <<END
import socket
from urllib.parse import urlparse

def get_ip_address(url):
    try:
        # Parse the URL to extract the hostname
        parsed_url = urlparse(url)
        hostname = parsed_url.hostname

        # Get the IP address
        ip_address = socket.gethostbyname(hostname)
        return ip_address
    except socket.gaierror:
        return None

print(get_ip_address("$1"))
END
}

# Function to capture traffic for a given URL
capture_traffic() {
    url="$1"
    output_file="$output_directory/$output_file_prefix-$(echo "$url" | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')"
    
    # Get host IP
    host_ip=$(get_ip_address "$url")

    # Run tcpdump command with provided inputs and save the PID
    tcpdump -i eth0 -nn -X "(tcp and host $host_ip) or udp" -w "$output_file.pcap" &
    cpdump_pid=$!
    # Wait for tcpdump to start
    sleep 2

    # Perform curl operation specified number of times
    for i in $(seq "$num_curls"); do
        curl -s "$url" > /dev/null
        sleep 1
    done

    # Kill the tcpdump process
}

# Iterate over each URL and capture traffic
for url in "$@"; do
    capture_traffic "$url"
done

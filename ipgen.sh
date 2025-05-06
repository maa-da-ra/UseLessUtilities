#!/bin/bash

# Pure Bash IP Generator

cidr_to_ips() {
    local cidr=$1
    local ip mask base_ip
    IFS=/ read -r ip mask <<< "$cidr"
    IFS=. read -r o1 o2 o3 o4 <<< "$ip"

    # Convert base IP to integer
    ip_int=$(( (o1 << 24) + (o2 << 16) + (o3 << 8) + o4 ))

    # Number of IPs = 2^(32-mask) - 2 (skip network & broadcast)
    count=$((2 ** (32 - mask)))
    start=$((ip_int + 1))
    end=$((ip_int + count - 2))

    for ((i = start; i <= end; i++)); do
        echo "$(( (i >> 24) & 255 )).$(( (i >> 16) & 255 )).$(( (i >> 8) & 255 )).$(( i & 255 ))"
    done
}

range_to_ips() {
    local part1 part2 part3 part4
    IFS=. read -r part1 part2 part3 part4 <<< "$1"

    expand_part() {
        if [[ "$1" == *-* ]]; then
            IFS=- read start end <<< "$1"
            seq $start $end
        else
            echo "$1"
        fi
    }

    for a in $(expand_part "$part1"); do
        for b in $(expand_part "$part2"); do
            for c in $(expand_part "$part3"); do
                for d in $(expand_part "$part4"); do
                    echo "$a.$b.$c.$d"
                done
            done
        done
    done
}

echo "Please specify IP range:"
echo "e.g.: 0-255.0-255.0-255.0-255[/CIDR if provided], or multiple separated by commas"
read -r ip_input

IFS=',' read -ra ip_ranges <<< "$ip_input"

echo ""
echo "Baking Addresses..."

ips=()

for r in "${ip_ranges[@]}"; do
    r=$(echo "$r" | xargs) # trim spaces
    if [[ "$r" == */* ]]; then
        mapfile -t new_ips < <(cidr_to_ips "$r")
    else
        mapfile -t new_ips < <(range_to_ips "$r")
    fi
    ips+=("${new_ips[@]}")
done

echo "Total IPs generated: ${#ips[@]}"

echo ""
read -p "Randomize sequence in output?  Y / N ? " rand_choice

if [[ "$rand_choice" =~ ^[Yy]$ ]]; then
    mapfile -t ips < <(printf "%s\n" "${ips[@]}" | awk 'BEGIN {srand()} {print rand(), $0}' | sort -n | cut -d' ' -f2-)
fi

echo ""
read -p "Please specify a name for the output file: " filename
[[ "$filename" != *.txt ]] && filename="${filename}.txt"

printf "%s\n" "${ips[@]}" > "$filename"

echo ""
echo "DONE!"

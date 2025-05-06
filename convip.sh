#!/bin/bash

# Bash IP Converter with Split Outputs per Format

to_decimal() {
    IFS='.' read -r a b c d <<< "$1"
    echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}

to_hex_octets() {
    IFS='.' read -r a b c d <<< "$1"
    printf "0x%02X.0x%02X.0x%02X.0x%02X\n" "$a" "$b" "$c" "$d"
}

to_hex_full() {
    local dec
    dec=$(to_decimal "$1")
    printf "0x%08X\n" "$dec"
}

to_octal() {
    IFS='.' read -r a b c d <<< "$1"
    printf "%04o.%04o.%04o.%04o\n" "$a" "$b" "$c" "$d"
}

reverse_from_decimal() {
    local dec=$1
    a=$(( (dec >> 24) & 255 ))
    b=$(( (dec >> 16) & 255 ))
    c=$(( (dec >> 8) & 255 ))
    d=$(( dec & 255 ))
    echo "$a.$b.$c.$d"
}

reverse_from_hex_octets() {
    IFS='.' read -r a b c d <<< "$1"
    echo "$((16#${a//0x/})).$((16#${b//0x/})).$((16#${c//0x/})).$((16#${d//0x/}))"
}

reverse_from_hex_full() {
    hex="${1//0x/}"
    dec=$((16#$hex))
    reverse_from_decimal "$dec"
}

reverse_from_octal() {
    IFS='.' read -r a b c d <<< "$1"
    echo "$((8#$a)).$((8#$b)).$((8#$c)).$((8#$d))"
}

write_output() {
    local output_file=$1
    local line=$2
    echo "$line" >> "$output_file"
}

process_ip() {
    local ip=$1
    local base=$2
    local modes=$3

    for mode in ${modes//,/ }; do
        case "$mode" in
            1) write_output "${base}_Dot.txt" "Dotted Decimal: $ip" ;;
            2) write_output "${base}_dec.txt" "$(to_decimal "$ip")" ;;
            3) write_output "${base}_HexO.txt" "$(to_hex_octets "$ip")" ;;
            4) write_output "${base}_HexF.txt" "$(to_hex_full "$ip")" ;;
            5) write_output "${base}_Oct.txt" "$(to_octal "$ip")" ;;
            6)
                if [[ "$ip" =~ ^[0-9]+$ ]]; then
                    write_output "${base}_Rev.txt" "From Decimal: $(reverse_from_decimal "$ip")"
                elif [[ "$ip" =~ ^0[xX]?[0-9a-fA-F]+$ ]]; then
                    write_output "${base}_Rev.txt" "From Hex (full): $(reverse_from_hex_full "$ip")"
                elif [[ "$ip" =~ \. && "$ip" =~ 0[xX] ]]; then
                    write_output "${base}_Rev.txt" "From Hex (octets): $(reverse_from_hex_octets "$ip")"
                elif [[ "$ip" =~ \. && "$ip" =~ ^0[0-7]+ ]]; then
                    write_output "${base}_Rev.txt" "From Octal: $(reverse_from_octal "$ip")"
                else
                    write_output "${base}_Rev.txt" "Could not reverse: $ip"
                fi
                ;;
            *) echo "[!] Unknown mode: $mode" ;;
        esac
    done
}

# ---- Prompt user ----

echo "Select conversion types (comma-separated):"
echo "1. Dotted Decimal"
echo "2. Decimal"
echo "3. Hex (per octet)"
echo "4. Hex (full)"
echo "5. Octal"
echo "6. Reverse from Decimal/Hex/Octal"
read -p "Enter your selection (e.g. 2,3,4): " selection

read -p "Enter a single IP or value (leave blank if using file): " single_ip
read -p "Or enter a filename containing multiple IPs: " ip_file

if [[ -z "$single_ip" && -z "$ip_file" ]]; then
    echo "[!] You must enter an IP or a file."
    exit 1
fi

read -p "Enter base name for output files (e.g. my_results): " basefile
[[ -z "$basefile" ]] && basefile="output"

# ---- Process all IPs ----

echo "Baking conversions..."

if [[ -n "$ip_file" && -f "$ip_file" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && process_ip "$line" "$basefile" "$selection"
    done < "$ip_file"
fi

if [[ -n "$single_ip" ]]; then
    process_ip "$single_ip" "$basefile" "$selection"
fi

echo "DONE!"

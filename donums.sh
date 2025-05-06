#!/bin/bash

# Number Generator Script

# Function to generate a sequence with preserved formatting
generate_range() {
    local start=$1
    local end=$2

    # Determine padding width from start or end
    pad_width=${#start}
    
    for ((i = 10#$start; i <= 10#$end; i++)); do
        printf "%0${pad_width}d\n" "$i"
    done
}

echo "Please provide one or more number ranges."
echo "Use either e.g. 0-999999999 OR 000000000-999999999"
echo "Multiple ranges can be defined using ',' like: 10-32,045-098"
read -r input_ranges

IFS=',' read -ra ranges <<< "$input_ranges"
numbers=()

echo ""
echo "Baking numbers..."

for range in "${ranges[@]}"; do
    range=$(echo "$range" | xargs)  # trim spaces
    IFS='-' read -r start end <<< "$range"

    if [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then
        mapfile -t range_numbers < <(generate_range "$start" "$end")
        numbers+=("${range_numbers[@]}")
    else
        echo "Invalid range: $range"
    fi
done

echo ""
echo "Total numbers generated: ${#numbers[@]}"

read -p $'\nWould you like to randomize the numbers in the output? Y / N ?\n> ' randomize

if [[ "$randomize" =~ ^[Yy]$ ]]; then
    mapfile -t numbers < <(printf "%s\n" "${numbers[@]}" | awk 'BEGIN {srand()} {print rand(), $0}' | sort -n | cut -d" " -f2-)
fi

echo ""
read -p "Please provide with a name for the output file: " filename
[[ "$filename" != *.txt ]] && filename="${filename}.txt"

printf "%s\n" "${numbers[@]}" > "$filename"

echo ""
echo "DONE!"

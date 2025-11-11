#!/bin/bash

DOMAIN="${1:-nvidia.com}"
OUTPUT_DIR="out"
INPUT_DIR="in"
BATCH_SIZE=10000

mkdir -p "$OUTPUT_DIR" "$INPUT_DIR"

subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo "" > "$OUTPUT_DIR/subdomains.txt"

cp "$OUTPUT_DIR/subdomains.txt" "$INPUT_DIR/subdomains_input.txt"
FILE_SIZE=$(awk '{print $1}' /tmp/merged.txt 2>/dev/null <<< "$(wc -l < "$INPUT_DIR/subdomains_input.txt")")

if [ "$BATCH_SIZE" -gt "$FILE_SIZE" ] 2>/dev/null; then
    BATCH_SIZE="$FILE_SIZE"
fi

if [ "$FILE_SIZE" -le 1 ] 2>/dev/null; then
    echo "1,1" > "$OUTPUT_DIR/subdomain_batch_ranges.txt"
else
    > "$OUTPUT_DIR/subdomain_batch_ranges.txt"
    for ((i=1; i<=FILE_SIZE; i+=BATCH_SIZE)); do
        end=$((i + BATCH_SIZE - 1))
        if [ $end -gt $FILE_SIZE ]; then
            end=$FILE_SIZE
        fi
        echo "$i,$end" >> "$OUTPUT_DIR/subdomain_batch_ranges.txt"
    done
fi

LINE_NUM=1
BATCH_NUM=1
mkdir -p "$OUTPUT_DIR/batch_output_2"

while IFS= read -r line; do
    if [ $(( (LINE_NUM - 1) % BATCH_SIZE )) -eq 0 ] && [ $LINE_NUM -ne 1 ]; then
        BATCH_NUM=$((BATCH_NUM + 1))
    fi
    echo "$line" >> "$OUTPUT_DIR/batch_output_2/batch_${BATCH_NUM}.txt"
    LINE_NUM=$((LINE_NUM + 1))
done < "$INPUT_DIR/subdomains_input.txt"

mkdir -p "$OUTPUT_DIR/dns_results"

for batch_file in "$OUTPUT_DIR/batch_output_2/"*.txt; do
    if [ -f "$batch_file" ]; then
        batch_name=$(basename "$batch_file" .txt)
        batch_dns_output="$OUTPUT_DIR/dns_results/${batch_name}_dns.json"
        if [ -s "$batch_file" ]; then
            dnsx -json -a -list "$batch_file" -o "$batch_dns_output" 2>/dev/null || echo "[]" > "$batch_dns_output"
        else
            echo "[]" > "$batch_dns_output"
        fi
    fi
done

> "$OUTPUT_DIR/all_dns_results.json"
for dns_file in "$OUTPUT_DIR/dns_results/"*.json; do
    if [ -f "$dns_file" ] && [ -s "$dns_file" ]; then
        cat "$dns_file" >> "$OUTPUT_DIR/all_dns_results.json"
        echo "" >> "$OUTPUT_DIR/all_dns_results.json"
    fi
done

jq -c 'select(.a and (.a | length) > 0 and .status_code != "SERVFAIL" and .status_code != "REFUSED")' "$OUTPUT_DIR/all_dns_results.json" 2>/dev/null > "$OUTPUT_DIR/successful_dns.json" || echo "" > "$OUTPUT_DIR/successful_dns.json"

jq -r '.a[]' "$OUTPUT_DIR/successful_dns.json" 2>/dev/null | grep -v 'null' | sort -u > "$OUTPUT_DIR/unique_ips.txt" || echo "" > "$OUTPUT_DIR/unique_ips.txt"

UNIQUE_IPS_COUNT=$(wc -l < "$OUTPUT_DIR/unique_ips.txt" 2>/dev/null || echo 0)

cp "$OUTPUT_DIR/unique_ips.txt" "$INPUT_DIR/ips_input.txt"
FILE_SIZE=$(awk '{print $1}' /tmp/merged.txt 2>/dev/null <<< "$(wc -l < "$INPUT_DIR/ips_input.txt")")

if [ "$BATCH_SIZE" -gt "$FILE_SIZE" ] 2>/dev/null; then
    BATCH_SIZE="$FILE_SIZE"
fi

if [ "$FILE_SIZE" -le 1 ] 2>/dev/null; then
    echo "1,1" > "$OUTPUT_DIR/ip_batch_ranges.txt"
else
    > "$OUTPUT_DIR/ip_batch_ranges.txt"
    for ((i=1; i<=FILE_SIZE; i+=BATCH_SIZE)); do
        end=$((i + BATCH_SIZE - 1))
        if [ $end -gt $FILE_SIZE ]; then
            end=$FILE_SIZE
        fi
        echo "$i,$end" >> "$OUTPUT_DIR/ip_batch_ranges.txt"
    done
fi

LINE_NUM=1
BATCH_NUM=1
mkdir -p "$OUTPUT_DIR/batch_output_1"

while IFS= read -r line; do
    if [ $(( (LINE_NUM - 1) % BATCH_SIZE )) -eq 0 ] && [ $LINE_NUM -ne 1 ]; then
        BATCH_NUM=$((BATCH_NUM + 1))
    fi
    echo "$line" >> "$OUTPUT_DIR/batch_output_1/batch_${BATCH_NUM}.txt"
    LINE_NUM=$((LINE_NUM + 1))
done < "$INPUT_DIR/ips_input.txt"

mkdir -p "$OUTPUT_DIR/port_scan_results"

PORTS="80,81,82,83,84,85,86,87,88,89,90,280,300,443,591,593,832,981,1010,1025,1099,1311,1883,2082,2095,2096,2480,2809,2875,2888,2889,3000,3128,3333,4243,4567,4711,4712,4993,5000,5001,5002,5003,5050,5104,5108,5280,5281,5601,5800,6543,7000,7001,7396,7474,8000,8001,8002,8003,8004,8005,8008,8014,8042,8060,8069,8080,8081,8082,8083,8084,8085,8086,8087,8088,8089,8090,8091,8095,8118,8123,8172,8181,8222,8243,8280,8281,8333,8337,8443,8500,8834,8880,8881,8882,8883,8884,8885,8886,8887,8888,8889,8890,8891,8892,8893,8894,8895,8896,8897,8898,8899,8983,9000,9001,9002,9003,9004,9005,9006,9043,9060,9080,9081,9082,9083,9084,9085,9086,9087,9088,9089,9090,9091,9092,9093,9094,9095,9096,9097,9098,9099,9200,9443,9502,9800,9981,10000,10243,10250,11371,12443,15672,16080,17778,18091,18092,18093,18094,20720,32000,32400,55440,55672"

for batch_file in "$OUTPUT_DIR/batch_output_1/"*.txt; do
    if [ -f "$batch_file" ]; then
        batch_name=$(basename "$batch_file" .txt)
        batch_port_output="$OUTPUT_DIR/port_scan_results/${batch_name}_ports.txt"
        if [ -s "$batch_file" ]; then
            naabu -silent -l "$batch_file" -p "$PORTS" -exclude-cdn -timeout 5000 -rate 1000 -o "$batch_port_output" 2>/dev/null || echo "" > "$batch_port_output"
        else
            echo "" > "$batch_port_output"
        fi
    fi
done

> "$OUTPUT_DIR/all_port_results.txt"
for port_file in "$OUTPUT_DIR/port_scan_results/"*.txt; do
    if [ -f "$port_file" ] && [ -s "$port_file" ]; then
        cat "$port_file" >> "$OUTPUT_DIR/all_port_results.txt"
    fi
done

OPEN_PORTS_COUNT=$(wc -l < "$OUTPUT_DIR/all_port_results.txt" 2>/dev/null || echo 0)

> "$OUTPUT_DIR/final_results.txt"

if [ -s "$OUTPUT_DIR/all_port_results.txt" ] && [ -s "$OUTPUT_DIR/successful_dns.json" ]; then
    while IFS= read -r port_line; do
        port_line=$(echo "$port_line" | xargs)
        if [[ -n "$port_line" ]]; then
            if [[ $port_line =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+)$ ]]; then
                scanned_ip="${BASH_REMATCH[1]}"
                port="${BASH_REMATCH[2]}"
                while IFS= read -r dns_line; do
                    if echo "$dns_line" | jq -e '.a[]' 2>/dev/null | grep -q "$scanned_ip"; then
                        host=$(echo "$dns_line" | jq -r '.host' 2>/dev/null)
                        if [ -n "$host" ] && [ "$host" != "null" ]; then
                            echo "${host}:${port}" >> "$OUTPUT_DIR/final_results.txt"
                        fi
                    fi
                done < <(jq -c '.' "$OUTPUT_DIR/successful_dns.json" 2>/dev/null | grep -v '^\[\]$' | jq -c '.[]' 2>/dev/null)
            fi
        fi
    done < "$OUTPUT_DIR/all_port_results.txt"
    
    if [ -s "$OUTPUT_DIR/final_results.txt" ]; then
        sort -u "$OUTPUT_DIR/final_results.txt" -o "$OUTPUT_DIR/final_results.txt"
    fi
fi

FINAL_COUNT=$(wc -l < "$OUTPUT_DIR/final_results.txt" 2>/dev/null || echo 0)

cat "$OUTPUT_DIR/final_results.txt"

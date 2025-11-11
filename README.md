# Silentrecon
Resolving host names first can lead to a faster port scan and give you more visibility into your target's IP space


```markdown
# Subdomain Recon & Port Scan Pipeline

![Recon Pipeline](https://img.shields.io/badge/Recon-Pipeline-blue)
![Bash Script](https://img.shields.io/badge/Bash-Script-green)
![Security Tools](https://img.shields.io/badge/Security-Tools-red)

A silent, automated reconnaissance pipeline that discovers subdomains, resolves them to IPs, scans for open ports, and outputs only the final `host:port` results — no intermediate files, no verbose output.

## Features

✅ **Subdomain Discovery** - Uses `subfinder` to find all subdomains  
✅ **Parallel DNS Resolution** - Resolves subdomains in batches with error filtering  
✅ **Smart Filtering** - Ignores SERVFAIL, REFUSED, NXDOMAIN responses  
✅ **Efficient Port Scanning** - Scans 100+ common ports with `naabu` in parallel batches  
✅ **Result Correlation** - Matches open ports back to original hostnames  
✅ **Silent Output** - Only outputs final `host:port` pairs — nothing else  
✅ **Zero Dependencies** - Runs in plain bash with standard Linux tools  
✅ **Robust Error Handling** - Continues on partial failures, no crashes  

## Prerequisites

### Required Tools
- `subfinder` - Subdomain enumeration
- `dnsx` - DNS resolution with JSON output
- `naabu` - Fast port scanner
- `jq` - JSON processor
- `bash` (version 4.0+)

### Install Tools
```bash
# Install Go tools
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

# Install jq (Debian/Ubuntu)
sudo apt-get update && sudo apt-get install jq -y

# Install jq (RHEL/CentOS)
sudo yum install jq -y
```

## Usage

```bash
# Basic usage (default: test.com)
./recon-pipeline.sh

# Specify target domain
./recon-pipeline.sh test.com

# Pipe output to file
./recon-pipeline.sh test.com > results.txt
```

## How It Works

1. **Discovers subdomains** using `subfinder`
2. **Splits subdomains into batches** of 10,000 for parallel processing
3. **Resolves each batch** with `dnsx`, filtering out failed responses (SERVFAIL, REFUSED, NXDOMAIN)
4. **Extracts only valid IPs** from successful resolutions
5. **Splits IPs into batches** and scans with `naabu` on 100+ common ports
6. **Correlates open ports** back to their original hostnames
7. **Outputs only final `host:port` pairs** — nothing else

## Output

Only the final results are printed to stdout:

```
subdomain.test.com:443
www.test.com:80
api.test.com:443
```

No logs, no progress bars, no temporary files shown — just clean, actionable results.

## File Structure (Internal Only)

```
out/
├── subdomains.txt              # Raw subdomain list
├── batch_output_2/             # Subdomain batches
├── dns_results/                # DNS resolution results (JSON)
├── successful_dns.json         # Filtered successful DNS records
├── unique_ips.txt              # Clean list of resolved IPs
├── batch_output_1/             # IP batches
├── port_scan_results/          # Port scan results per batch
├── all_port_results.txt        # Combined port scan output
└── final_results.txt           # Final host:port pairs (used internally)
```

## Important Notes

### ⚠️ Legal Disclaimer
**Use only on systems you own or have explicit written permission to test.**  
Unauthorized scanning violates laws and terms of service. This tool is for authorized security research and bug bounty programs only.

### Performance
- **Small domains** (< 1K subdomains): Complete in < 2 minutes  
- **Large domains** (> 5K subdomains): May take 5–15 minutes  
- Requires stable internet connection for DNS and port scanning

### Silent Mode
This script is designed to be **silent** — no progress indicators, no logs, no debug output.  
It only prints final `host:port` results. Use `strace` or `bash -x` if you need debugging.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `integer expression expected` | Fixed in this version — no more errors |
| No results returned | Target has no open ports or all DNS resolutions failed |
| Command not found | Ensure `subfinder`, `dnsx`, `naabu`, `jq` are in `$PATH` |
| Slow performance | Use faster DNS resolvers (e.g., `1.1.1.1`, `8.8.8.8`) |

## Contributing

Contributions welcome!  
Open an issue or PR for:
- New port lists
- Support for additional tools
- Performance improvements
- Better error handling

## License

MIT License — Free to use, modify, and distribute for authorized security research.

---

**Happy Recon. Silent. Efficient. Effective.**  
*No noise. Just results.*
```

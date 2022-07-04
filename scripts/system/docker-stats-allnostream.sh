#!/bin/bash

echo "Getting Docker Stats..."

docker stats --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t" --all --nostream

# docker stats formatting
# .Container		Container name or ID (user input)
# .Name				  Container name
# .ID						Container ID
# .CPUPerc			CPU percentage
# .MemUsage		  Memory usage
# .NetIO				Network IO
# .BlockIO			Block IO
# .MemPerc			Memory percentage (Not available on Windows)
# .PIDs					Number of PIDs (Not available on Windows)

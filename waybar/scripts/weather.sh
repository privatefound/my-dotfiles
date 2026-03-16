#!/bin/bash
# Fetch weather from wttr.in
# %C: Condition text
# %t: Temperature
weather_info=$(curl -s "wttr.in/?format=%C+%t")

if [[ $? -ne 0 || -z "$weather_info" ]]; then
    echo "N/A"
    exit 1
fi

# Extract condition (all except last word which is temp) and temp
condition=$(echo "$weather_info" | rev | cut -d' ' -f2- | rev)
temp=$(echo "$weather_info" | rev | cut -d' ' -f1 | rev)

# Convert condition to lowercase for easier matching
cond_lower=$(echo "$condition" | tr '[:upper:]' '[:lower:]')

# Map condition to Nerd Font icons
if [[ "$cond_lower" == *"sunny"* || "$cond_lower" == *"clear"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"partly cloudy"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"cloudy"* || "$cond_lower" == *"overcast"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"rain"* || "$cond_lower" == *"drizzle"* || "$cond_lower" == *"showers"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"snow"* || "$cond_lower" == *"sleet"* || "$cond_lower" == *"blizzard"* || "$cond_lower" == *"ice pellets"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"thunder"* ]]; then
    icon=""
elif [[ "$cond_lower" == *"mist"* || "$cond_lower" == *"fog"* || "$cond_lower" == *"haze"* ]]; then
    icon=""
else
    icon="" # Default to cloud if unknown
fi

echo "$icon $temp"

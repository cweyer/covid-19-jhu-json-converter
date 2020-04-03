# covid-19-jhu-json-converter
Converts the CSV files published by Johns Hopkins regarding Covid-19 into a cleaner JSON format.

## Background

Many people around the world are currently working a lot with statistical models regarding the COVID-19 spread. One of the most reliable and most quoted sources for infection numbers is the Johns Hopkins University in Baltimore. They update their numbers several times a day and [publish them in a CSV format](https://github.com/CSSEGISandData/COVID-19).

## What the converter does
Since for many computational tasks [JSON](https://www.json.org/json-en.html) is a more appropriate format than CSV, we wrote a converter that takes the Hopkins data from the above repo and transforms them into a single JSON array. 

Each element in the array represents a geographical area from the Hopkins data (equal to one CSV row). It also combines all three figures: infections, deaths and recoveries into a single object for each area.

## How to run
The converter is a simple ruby script that we packed into a Docker container.

You can run it directly from Docker like so:
`docker run docker.pkg.github.com/cweyer/covid-19-jhu-json-converter/covid19-csse-exporter:latest`

You can also fork this repo and run the ruby script directly. The JSON is written to `STDOUT`.
`ruby jhu2json.rb > nice.json`

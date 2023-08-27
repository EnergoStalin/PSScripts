New-Item -Type Directory -Path "data"
New-Item -Type Directory -Path "data\desktop"
New-Item -Type Directory -Path "data\home"
New-Item -Type Directory -Path "data\profiles"

foreach($line in Get-Content -Path .\names.txt -Encoding UTF8) {
  New-Item -Type Directory -Path "data\desktop\$line"
  New-Item -Type Directory -Path "data\home\$line"
  New-Item -Type Directory -Path "data\profiles\$line"
  New-Item -Type Directory -Path "data\profiles\$line.v2"
  New-Item -Type Directory -Path "data\profiles\$line.v6"
}
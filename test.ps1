# Ping example.com to check connectivity
#PING.EXE example.com

# Ping example.com only once
$var = PING.EXE -n 1 example.com

$var[0].GetType()

Write-Host "The amount of lines in the ping output is: $($var.Length)"

foreach ($line in $var) {
    Write-Host "Line: $line"
}
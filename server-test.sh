#!/usr/bin/env bash
# server-test.sh (ohne jq)
set -e

PORT=3000

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Keine Farbe

# Server starten
deno run --allow-net --allow-read src/server.ts > server.log 2>&1 &
SERVER_PID=$!
echo "Server gestartet mit PID $SERVER_PID"
sleep 2  # warten, bis der Server bereit ist

fail=0

# Hilfsfunktion für Tests
run_test() {
    description="$1"
    command="$2"
    expected="$3"

    echo "Test: $description"
    output=$(eval "$command" 2>/dev/null)

    if [[ "$expected" == "FAIL" ]]; then
        if [[ "$output" != *"NOT FOUND"* && "$output" != *"UNAUTHORIZED"* ]]; then
            echo -e "${RED}Fehler: Erwarteter Fehler, aber Test erfolgreich${NC}"
            fail=1
        else
            echo -e "${GREEN}Negativtest erfolgreich${NC}"
        fi
    else
        if [[ "$output" == *"$expected"* ]]; then
            echo -e "${GREEN}Test erfolgreich${NC}"
        else
            echo -e "${RED}Fehler: Erwartet $expected, erhalten $output${NC}"
            fail=1
        fi
    fi
}

# 1. Abrufen eines bekannten Wechselkurses (USD -> CHF)
run_test "Abrufen USD -> CHF" \
    "curl -s \"http://localhost:$PORT/rate?from=usd&to=chf\"" \
    "0.81"

# 2. Abrufen eines unbekannten Wechselkurses (Negativtest)
run_test "Abrufen unbekannter Kurs ABC -> DEF" \
    "curl -s \"http://localhost:$PORT/rate?from=abc&to=def\"" \
    "FAIL"

# 3. Konversion mit einer bekannten Währung (EUR -> CHF)
run_test "Konversion EUR -> CHF 50" \
    "curl -s \"http://localhost:$PORT/convert?from=eur&to=chf&amount=50\"" \
    "47"

# 4. Konversion in die umgekehrte Richtung (CHF -> USD)
run_test "Konversion CHF -> USD 81" \
    "curl -s \"http://localhost:$PORT/convert?from=chf&to=usd&amount=81\"" \
    "100"

# 5. Negativtest: Konversion für unbekannte Währung (ABC -> USD)
run_test "Konversion unbekannte Währung ABC -> USD" \
    "curl -s \"http://localhost:$PORT/convert?from=abc&to=usd&amount=10\"" \
    "FAIL"

# Server stoppen
kill $SERVER_PID
echo "Server gestoppt"

exit $fail

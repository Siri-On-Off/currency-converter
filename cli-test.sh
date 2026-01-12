#!/usr/bin/env bash

DENO_CMD="deno run --allow-read src/cli.ts"
RATES_FILE="exchange-rates.json"

run_test() {
    description="$1"
    command="$2"
    expected="$3"

    echo "Test: $description"
    output=$($command 2>&1)
    exit_code=$?

    if [[ "$expected" == "FAIL" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            echo "Fehler: Erwarteter Fehler, aber Test erfolgreich"
            return 1
        else
            echo "Negativtest erfolgreich"
        fi
    else
        # Ausgabe prüfen, ohne printf auf Zahl umzuwandeln
        # Entfernt ggf. Zeilenumbrüche
        output=$(echo $output | tr -d '\r\n')
        if [[ "$output" == "$expected" ]]; then
            echo "Test erfolgreich"
        else
            echo "Fehler: Erwartet $expected, erhalten $output"
            return 1
        fi
    fi
}

fail=0

run_test "USD -> CHF" "$DENO_CMD --rates $RATES_FILE --from usd --to chf --amount 100" "81"
run_test "EUR -> CHF" "$DENO_CMD --rates $RATES_FILE --from eur --to chf --amount 50" "47"
run_test "CHF -> USD" "$DENO_CMD --rates $RATES_FILE --from chf --to usd --amount 100" "123.45679012345679"
run_test "Unbekannte Währung" "$DENO_CMD --rates $RATES_FILE --from abc --to usd --amount 10" "FAIL" || fail=1

exit $fail

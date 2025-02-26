#!/usr/bin/env bash

# To run this without Elixir, remove the .pdfs from the cp and rm commands.

set -e
set -o pipefail

function convert {
    soffice \
        --headless \
        --convert-to pdf \
        --outdir $TMPDIR \
        $1
}

function filter_new_file_name {
    awk -F$TMPDIR '{print $2}' \
    | awk -F" " '{print $1}' \
    | awk -F/ '{print $2}'
}

converted_file_name=$(convert $1 | filter_new_file_name)

cp $TMPDIR/$converted_file_name.pdf $2
rm $TMPDIR/$converted_file_name.pdf

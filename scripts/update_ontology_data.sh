#!/bin/bash

source /scripts/update_data.sh

all_flag=false

while getopts 'a' opt; do
    case "$opt" in
        a) all_flag=true ;;
        ?) echo "不正なオプション: -${OPTARG}" >&2; exit 2 ;;
    esac
done

shift $((OPTIND - 1))

declare -A graph_names=(
    ["go"]="https://pubcasefinder.dbcls.jp/go"
    ["hp"]="https://pubcasefinder.dbcls.jp/rdf/ontology/hp"
    ["medgen"]="https://pubcasefinder.dbcls.jp/rdf/ontology/medgen"
    ["mondo"]="https://pubcasefinder.dbcls.jp/rdf/ontology/mondo"
    ["nando"]="https://pubcasefinder.dbcls.jp/rdf/ontology/nando"
    ["pubchem"]="https://pubcasefinder.dbcls.jp/pubchem"
)

declare -A load_files=(
    ["go"]="'/rdf_data/pcf/ontologies/go/latest', '*.owl', 'https://pubcasefinder.dbcls.jp/go'"
    ["hp"]="'/rdf_data/pcf/ontologies/hp/latest', '*.owl', 'https://pubcasefinder.dbcls.jp/rdf/ontology/hp'"
    ["medgen"]="'/rdf_data/pcf/ontologies/medgen/latest', '*.ttl', 'https://pubcasefinder.dbcls.jp/rdf/ontology/medgen'"
    ["mondo"]="'/rdf_data/pcf/ontologies/mondo/latest', '*.owl', 'https://pubcasefinder.dbcls.jp/rdf/ontology/mondo'"
    ["nando"]="'/rdf_data/pcf/ontologies/nando/latest', '*.ttl', 'https://pubcasefinder.dbcls.jp/rdf/ontology/nando'"
    ["pubchem"]="'/rdf_data/pcf/ontologies/pubchem/latest', '*.*', 'https://pubcasefinder.dbcls.jp/pubchem'"
)

declare -A data_dirs=(
    ["go"]='/rdf_data/pcf/ontologies/go/latest'
    ["hp"]='/rdf_data/pcf/ontologies/hp/latest'
    ["medgen"]='/rdf_data/pcf/ontologies/medgen/latest'
    ["mondo"]='/rdf_data/pcf/ontologies/mondo/latest'
    ["nando"]='/rdf_data/pcf/ontologies/nando/latest'
    ["pubchem"]='/rdf_data/pcf/ontologies/pubchem/latest'
)

if ${all_flag}; then
    load_data=("${!graph_names[@]}")
else
    load_data=("$@")
fi

has_data_file() {
    local dir=$1
    local file

    for file in "$dir"/*; do
        if [[ -f $file ]]; then
            return 0
        fi
    done

    return 1
}

if (( ${#load_data[@]} == 0 )); then
    echo "ロード対象の引数、または -a の指定が必要です" >&2
    exit 2
fi

for data in "${load_data[@]}"; do
    if [[ -z ${graph_names[$data]+exists} ]]; then
        echo "引数は go, hp, medgen, mondo, nando, pubchem のいずれかです" >&2
        exit 2
    fi

    if ! has_data_file "${data_dirs[$data]}"; then
        echo "ファイルが存在しません: ${data_dirs[$data]}/*" >&2
        exit 1
    fi
done

for data in "${load_data[@]}"; do
    isql_load_virtuoso "${graph_names[$data]}" "${load_files[$data]}"
done


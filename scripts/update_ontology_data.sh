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

declare -A file_patterns=(
    ["go"]='*.owl'
    ["hp"]='*.owl'
    ["medgen"]='*.ttl'
    ["mondo"]='*.owl'
    ["nando"]='*.ttl'
    ["pubchem"]='*.*'
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
    local pattern=$2
    local file

    for file in "$dir"/*; do
        if [[ ${file##*/} == $pattern && -f $file && -r $file && -s $file ]]; then
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

    if ! has_data_file "${data_dirs[$data]}" "${file_patterns[$data]}"; then
        echo "読み取り可能で空でない対象ファイルが存在しません: ${data_dirs[$data]}/${file_patterns[$data]}" >&2
        exit 1
    fi
done

for data in "${load_data[@]}"; do
    printf '=============== loading %s ===============\n' "$data"
    isql_load_virtuoso "${graph_names[$data]}" "'${data_dirs[$data]}', '${file_patterns[$data]}', '${graph_names[$data]}'" || exit $?
    printf '=============== finish loading %s ===============\n' "$data"
done


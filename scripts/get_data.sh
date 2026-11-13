#!/bin/bash

all_flag=false
ONTOLOGY_DATA_DIR=''
NANDO_DATA_DIR=''


while getopts 'o:n:a' opt; do
  case "$opt" in
    o) ONTOLOGY_DATA_DIR=${OPTARG%/} ;;
    n) NANDO_DATA_DIR=${OPTARG%/} ;;
    a) all_flag=true ;;
    ?) echo "不正なオプション: -${OPTARG}" >&2; exit 2 ;;
  esac
done

if [[ -z $ONTOLOGY_DATA_DIR ]]; then
    echo "オントロジーデータのディレクトリの指定がありません: -o"
    exit 1
fi

if [[ -z $NANDO_DATA_DIR ]]; then
    echo "NANDOのディレクトリの指定がありません: -n"
    exit 1
fi

shift $((OPTIND - 1))

get_raw_ttl_from_opendata() {
    local output=$1
    local path=$2

    wget -O "$output" "$path"
}

get_raw_zip_ttls_from_opendata() {
    local output=$1
    local path=$2
    local file

    wget --recursive --level=1 --no-parent --no-directories --accept='*.ttl.gz' --continue --directory-prefix="$output" "$path" || return 1
    for file in "${output%/}"/*.ttl.gz; do
        [[ -e $file ]] || continue
        gunzip -- "$file" || return 1
    done
}

get_raw_ttl_from_local_server() {
    local output=$1
    local path=$2

    cp "$path" "$output"
}

declare -A turtle_methods=(
    ["go"]='get_raw_ttl_from_opendata'
    ["hp"]='get_raw_ttl_from_opendata'
    ["mondo"]='get_raw_ttl_from_opendata'
    ["medgen"]='get_raw_zip_ttls_from_opendata'
    ["nando"]='get_raw_ttl_from_local_server'
    ["pubchem"]=""
)

declare -A turtle_paths=(
    ["go"]="https://current.geneontology.org/ontology/go.owl"
    ["hp"]="http://purl.obolibrary.org/obo/hp.owl"
    ["mondo"]="https://purl.obolibrary.org/obo/mondo/mondo-international.owl"
    ["medgen"]="https://rdfportal.org/pub/turtle/medgen/latest/"
    ["nando"]="${NANDO_DATA_DIR}/nando.ttl"
    ["pubchem"]=""
)

declare -A turtle_outputs=(
    ["go"]="${ONTOLOGY_DATA_DIR}/go/latest/go.owl"
    ["hp"]="${ONTOLOGY_DATA_DIR}/hp/latest/hp.owl"
    ["mondo"]="${ONTOLOGY_DATA_DIR}/mondo/latest/mondo-international.owl"
    ["medgen"]="${ONTOLOGY_DATA_DIR}/medgen/latest/"
    ["nando"]="${ONTOLOGY_DATA_DIR}/nando/latest/"
    ["pubchem"]="${ONTOLOGY_DATA_DIR}/pubchem/latest/"
)

if "$all_flag"; then
    load_data=("${!turtle_methods[@]}")
elif (( $# > 0 )); then
    load_data=("$@")
else
    echo "取得対象の引数、または -a の指定が必要です" >&2
    exit 2
fi

for data in "${load_data[@]}"; do
    if ! [[ -v turtle_methods[$data] ]]; then
        echo "引数は go, hp, mondo, medgen, nando, pubchem のいずれかです" >&2
        exit 2
    fi
done

today=$(date '+%Y%m%d')

for data in "${load_data[@]}"; do
    base_dir="${ONTOLOGY_DATA_DIR}/${data}"
    version_dir="${base_dir}/${today}"

    if ! mkdir -p "$version_dir"; then
        echo "ディレクトリを作成できません: $version_dir" >&2
        exit 1
    fi

    if [[ $data == "pubchem" ]]; then
        if ! ln -snf "$today" "${base_dir}/latest"; then
            echo "latestリンクを更新できません: ${base_dir}/latest" >&2
            exit 1
        fi

        echo "このスクリプトではpubchemのupdateをサポートしていません."
        echo "作成先: $version_dir"
        echo "pubchemのデータの管理者から新規データを受け取り、作成先へコピーしてから次の作業に進んでください."
        continue
    fi

    output=${turtle_outputs[$data]/\/latest\//\/${today}\/}
    if ! "${turtle_methods[$data]}" "$output" "${turtle_paths[$data]}"; then
        echo "データの取得に失敗しました: $data" >&2
        exit 1
    fi

    if ! ln -snf "$today" "${base_dir}/latest"; then
        echo "latestリンクを更新できません: ${base_dir}/latest" >&2
        exit 1
    fi
done

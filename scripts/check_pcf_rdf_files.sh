#!/bin/bash

if (( $# > 1 )); then
    echo "使用方法: bash $0 [RDFディレクトリ]" >&2
    exit 2
fi

data_dir=${1:-/rdf_data/pcf/rdf/latest}
required_files=(
    GenCC_Gene_Association.ttl
    HPO_ja.ttl
    MONDO_Gene_Association.ttl
    NANDO_Gene_Association.ttl
    OMIM.ttl
    OMIM_Gene_Association.ttl
    OMIM_HP_Association.ttl
    Orphanet.ttl
    Orphanet_Gene_Association.ttl
    Orphanet_HP_Association.ttl
    all_gene.ttl
)

if [[ ! -d $data_dir ]]; then
    echo "RDFディレクトリが存在しません: $data_dir" >&2
    exit 1
fi

status=0
for file in "${required_files[@]}"; do
    if [[ ! -f $data_dir/$file || ! -r $data_dir/$file || ! -s $data_dir/$file ]]; then
        echo "必須ファイルが存在しないか、読み取り不可または空です: $data_dir/$file" >&2
        status=1
    fi
done

if (( status != 0 )); then
    exit "$status"
fi

echo "必須RDFファイル11件を確認しました: $data_dir"

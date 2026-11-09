# pubcasefinder_virtuoso_updater

Docker environment for updating the Virtuoso data used by PubCaseFinder.

MySQL updates are outside the scope of this repository. See the related documentation at the end of this file.

## Prerequisites and setup

Docker with Docker Compose, Bash, `wget`, and `gunzip` are required.

```bash
cp template.env .env
```

Set at least the following values in `.env`. Use `id -u` and `id -g` to find your `UID` and `DOCKER_GID`.

Set `DBA_PASSWORD` to the Virtuoso DBA password. All database scripts use this environment variable to authenticate.

The examples below use `/rdf_data/path/to` as the host data directory. Set `RDF_DIR=/rdf_data/path/to` in `.env`; this directory is mounted at `/rdf_data` inside the container.

Start the container:

```bash
docker compose up -d
```

## Updating data

### 1. Download ontology data

Run `get_data.sh` on the host. Pass the ontology destination to `-o` and the directory containing `nando.ttl` to `-n`.

```bash
# Download all datasets
bash scripts/get_data.sh -o /rdf_data/path/to/pcf/ontologies -n /rdf_data/path/to/nando -a

# Download selected datasets
bash scripts/get_data.sh -o /rdf_data/path/to/pcf/ontologies -n /rdf_data/path/to/nando go hp mondo medgen nando
```

Valid dataset names are `go`, `hp`, `mondo`, `medgen`, `nando`, and `pubchem`. Data is saved in a date-based directory, and the `latest` symlink is updated.

PubChem data is not downloaded automatically. Obtain it from its administrator and copy it to the destination printed by the script.

### 2. Load ontologies into Virtuoso

```bash
# Load all datasets
docker compose exec virtuoso-update bash /scripts/update_ontology_data.sh -a

# Load selected datasets
docker compose exec virtuoso-update bash /scripts/update_ontology_data.sh go hp mondo
```

Before clearing any graph, the loader checks that every selected dataset has a readable, nonempty file matching its load pattern (`*.owl`, `*.ttl`, or `*.*` for PubChem).

### 3. Load PubCaseFinder RDF

Place the TTL files in `/rdf_data/path/to/pcf/rdf/<YYYYMMDD>/` on the host, create the `/rdf_data/path/to/pcf/rdf/latest` symlink pointing to that directory, and run the loader.

The loader checks that all 11 required files are readable and nonempty before clearing the graph:

```text
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
```

To run only the file check:

```bash
docker compose exec virtuoso-update bash /scripts/check_pcf_rdf_files.sh
# On the host, specify the input directory:
bash scripts/check_pcf_rdf_files.sh /rdf_data/path/to/pcf/rdf/latest
```

```bash
docker compose exec virtuoso-update bash /scripts/update_pcf_rdf.sh
```

### 4. Verify the loaded data

Display the triple count for each graph:

```bash
docker compose exec virtuoso-update bash /scripts/check_virtuoso_data.sh
```

> The loading scripts clear the existing graph before loading new data. Check the input files and `latest` symlink before running them.

## Scripts

| File | Purpose |
| --- | --- |
| `get_data.sh` | Downloads ontology data and updates `latest` |
| `update_ontology_data.sh` | Replaces ontology graphs |
| `update_pcf_rdf.sh` | Replaces the PubCaseFinder RDF graph |
| `check_pcf_rdf_files.sh` | Checks the 11 required PubCaseFinder RDF files |
| `check_virtuoso_data.sh` | Displays triple counts by graph |
| `update_data.sh` | Provides shared functions for the loading scripts |

See [index.md](index.md) for more detailed Docker operation instructions.

## Related documentation

- [PubCaseFinder Virtuoso data update procedure](https://docs.google.com/spreadsheets/d/1Mi7VOu7Ye6K5CWXbYOl2g46yuMOJuSqoJoiT8gq5T0c/edit?gid=983984758#gid=983984758)
- [PubCaseFinder MySQL update procedure](https://docs.google.com/spreadsheets/d/1Mi7VOu7Ye6K5CWXbYOl2g46yuMOJuSqoJoiT8gq5T0c/edit?gid=395055673#gid=395055673)

> [!IMPORTANT]
> Contact the DBCLS team if you cannot access the documents above.

# qsearch

`qsearch` is a local cascading file-search command for macOS and Linux:

1. exact lexical search with `rga`
2. expanded lexical search with Snowball stems (optionally LAS lemmatization)
3. confidence gate
4. semantic/hybrid fallback with `clawgrep`
5. combined file ranking

Each run keeps every stage so the retrieval process remains inspectable.

## Install

Two commands. Clone the repository into `~/scripts/qsearch`, then run its installer:

```bash
git clone https://github.com/florianbuetow/qsearch-bash.git ~/scripts/qsearch
~/scripts/qsearch/install.sh
```

`install.sh` does the whole installation:

1. makes `scripts/qsearch` executable
2. installs the dependencies you are missing (macOS via Homebrew, Debian/Ubuntu-like
   Linux via apt) — tools you already have are left untouched, so nothing you rely on
   gets upgraded behind your back
3. adds `~/scripts/qsearch/scripts` to your `PATH` in `~/.zshrc`, `~/.bashrc`,
   `~/.bash_profile`, or `~/.config/fish/config.fish`, whichever matches your shell
4. verifies every dependency and exits non-zero if a required one is missing

Then open a new shell:

```bash
qsearch --help
```

> `qsearch` finds its stopword lists next to itself, so keep the `scripts/` directory
> on your `PATH` rather than symlinking the `qsearch` file somewhere else.

### Dependencies

| Tool | Required | Used for |
| ---- | -------- | -------- |
| `rg` (ripgrep) | yes | lexical search |
| `rga` (ripgrep-all) | yes | lexical search inside rich documents |
| `stemwords` (Snowball) | yes | the default `--linguistics snowball` expansion |
| `pandoc` | no | DOCX/ODT/EPUB/FB2/IPYNB/HTML text extraction |
| `pdftotext` (poppler) | no | PDF text extraction |
| `clawgrep` | no | the semantic fallback stage |
| `las` | no | optional `--linguistics las` lemmatization |

Homebrew's `snowball` formula ships `libstemmer` and the `stemwords` example source
but no `stemwords` binary, so `install-macos-deps.sh` compiles it into
`scripts/stemwords`. That needs a C compiler — run `xcode-select --install` if the
build step reports one is missing.

The dependency installers can also be run on their own:

```bash
~/scripts/qsearch/install-macos-deps.sh
~/scripts/qsearch/install-linux-deps.sh
```

## Update

```bash
cd ~/scripts/qsearch
git pull
./install.sh
```

## Uninstall

Remove the `PATH` line you added to your shell config, then delete the clone:

```bash
rm -rf ~/scripts/qsearch
```

## Usage

```bash
qsearch "how are autonomous agents evaluated?" ~/Documents /Volumes/Archive
```

Limit file types:

```bash
qsearch --types md,txt,pdf,docx "agent evaluation" ~/Documents
```

German:

```bash
qsearch --lang de "Bewertung autonomer Agenten" ~/Documents
```

Force or disable semantic search:

```bash
qsearch --semantic always "failure handling" .
qsearch --semantic never "failure handling" .
```

## Linguistic expansion

The default is `--linguistics snowball`. This is intentionally the fast path: Snowball is small and fast enough to sit in front of `ripgrep`/`rga` on every query.

Optional LAS mode:

```bash
qsearch --linguistics las --lang de "bewertete autonome Agenten" ~/Documents
```

LAS provides lemmatization before Snowball stemming. It is optional because LAS itself is a large Java-based package and its documentation notes significant startup cost.

## Results

macOS:

```text
~/Library/Caches/qsearch/runs/YYYYMMDD-HHMMSS-PID/
```

Linux:

```text
~/.cache/qsearch/runs/YYYYMMDD-HHMMSS-PID/
```

Each run contains:

```text
00-query.txt
01-exact.txt
02-expanded.txt
03-semantic.txt
lexical-ranking.tsv
ranking.tsv
final.txt
```

`final.txt` identifies the highest-ranked file and the top matches.

## Cache layout

```text
qsearch/
  runs/        per-search evidence/results
  extracted/   cached text extracted from PDF/DOCX/etc.
  corpus/      stable symlinks used by semantic search
  clawgrep/    clawgrep embedding/model cache
```

Plain text files are not copied: the corpus uses symlinks. Rich documents are extracted to local text only when needed for the semantic stage. Extraction is refreshed when file size or modification time changes.

## Semantic document support

For semantic search:

- PDF -> `pdftotext`
- DOCX/ODT/EPUB/FB2/IPYNB/HTML -> `pandoc`
- normal text/code -> symlink to the original file

Lexical searching is performed by `rga`, so its normal adapters and cache are used as well.

## German semantic search

The lexical stages support German through German stopwords and Snowball stemming (and optional LAS lemmatization). `clawgrep` currently embeds with `BAAI/bge-small-en-v1.5`, so the semantic fallback should be treated as stronger for English than German.

## Repository layout

```text
qsearch-bash/
├── LICENSE
├── README.md
├── install.sh                  the installer you run after cloning
├── install-macos-deps.sh       Homebrew dependencies
├── install-linux-deps.sh       apt/cargo dependencies
└── scripts/                    the directory that goes on your PATH
    ├── qsearch                 the search command
    ├── stopwords-de.txt
    └── stopwords-en.txt
```

The installers live at the repository root, not in `scripts/`, so that putting
`scripts/` on your `PATH` does not also put three `install*.sh` commands on it.

## License

[MIT](LICENSE) © Florian Buetow

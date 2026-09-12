# qsearch

`qsearch` is a local cascading file-search command for macOS and Linux:

1. exact lexical search with `rga`
2. expanded lexical search with Snowball stems (optionally LAS lemmatization)
3. confidence gate
4. semantic/hybrid fallback with `clawgrep`
5. combined file ranking

Each run keeps every stage so the retrieval process remains inspectable.

## Install

### 1. Clone the repository into `~/scripts/qsearch`

```bash
mkdir -p ~/scripts
git clone https://github.com/florianbuetow/qsearch-bash.git ~/scripts/qsearch
```

### 2. Make the scripts executable

```bash
chmod +x ~/scripts/qsearch/scripts/*
```

### 3. Add QSearch to your `PATH`

Pick the section for the shell you use, run the command, then reload your shell.

#### bash

```bash
echo 'export PATH="$HOME/scripts/qsearch/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

On macOS, bash reads `~/.bash_profile` for login shells — use that file instead if
`~/.bashrc` is not sourced on your system.

#### zsh

```zsh
echo 'export PATH="$HOME/scripts/qsearch/scripts:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### fish

```fish
fish_add_path "$HOME/scripts/qsearch/scripts"
```

Older fish versions without `fish_add_path`:

```fish
echo 'set -gx PATH $HOME/scripts/qsearch/scripts $PATH' >> ~/.config/fish/config.fish
source ~/.config/fish/config.fish
```

### 4. Verify the installation

```bash
which qsearch
qsearch --help
```

`scripts/install.sh` is an optional convenience: it runs the `chmod` of step 2 and
prints the `PATH` line to add.

```bash
~/scripts/qsearch/scripts/install.sh
```

> `qsearch` finds its stopword lists next to itself, so put the `scripts/` directory
> on your `PATH` rather than symlinking the `qsearch` file somewhere else.

## Install dependencies

macOS:

```bash
~/scripts/qsearch/scripts/install-macos-deps.sh
```

On Debian/Ubuntu-like Linux:

```bash
~/scripts/qsearch/scripts/install-linux-deps.sh
```

## Update

```bash
cd ~/scripts/qsearch
git pull
chmod +x scripts/*
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
└── scripts/
    ├── qsearch                 the search command
    ├── install.sh              chmod helper + PATH hint
    ├── install-macos-deps.sh   Homebrew dependencies
    ├── install-linux-deps.sh   apt/cargo dependencies
    ├── stopwords-de.txt
    └── stopwords-en.txt
```

## License

[MIT](LICENSE) © Florian Buetow

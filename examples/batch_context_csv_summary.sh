#!/bin/zsh

# ============================
# Konfigurace
# ============================
EXAMPLES_DIR="."
LOG_FILE="$(pwd)/batch_context_csv_summary.log"
PDF_OUTPUT_DIR="$(pwd)/batch_context_csv_summary_pdfs"
TEMP_DIR="$(pwd)/temp_processing"

mkdir -p "$PDF_OUTPUT_DIR" "$TEMP_DIR"

# ============================
# Párovací seznam
# ============================
# Jediný řetězec, uvnitř je obyčejná mezera:
pairingfiles=(
  "calculations_in_the_table.tex superstore_sales_table.csv"
  "cities-of-world.tex countries.csv cities.csv"
)

# ============================
# Funkce: log
# ============================
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ============================
# Funkce: rekurzivní hledání
# ============================
find_file_in_root() {
  local name="$1"
  find "$EXAMPLES_DIR" -type f -iname "$name" | head -n 1
}

# ============================
# Start
# ============================
log "Spouštím dávkové zpracování..."

for record in "${pairingfiles[@]}"; do
  log "-----------------------------------------------------"
  log "Záznam: '$record'"

  # (z) => shell-like tokenizace
  # Ověřte, že v "calculations_in_the_table.tex superstore_sales_table.csv" je obyčejná mezera 0x20
  set -- ${(z)record}
  tex_name="$1"
  shift
  csv_list=("$@")

  log "DEBUG: token1='$tex_name', token2='${csv_list[1]}'"

  if [[ "$tex_name" != *.tex ]]; then
    log "Chyba: '$tex_name' není .tex"
    continue
  fi

  tex_path=$(find_file_in_root "$tex_name")
  if [[ -z "$tex_path" ]]; then
    log "Chyba: TEX '$tex_name' nenalezen"
    continue
  fi
  log "Nalezen TEX: $tex_path"

  base_name="$(basename "$tex_path" .tex)"
  tex_dir="$(dirname "$tex_path")"

  pushd "$tex_dir" >/dev/null
  log "Kompiluji: $tex_name"
  context --purgeall "$tex_name"
  if [[ $? -ne 0 ]]; then
    log "Chyba: Kompilace '$tex_name' selhala"
    popd >/dev/null
    continue
  fi
  found_pdf=$(find . -maxdepth 1 -type f -iname "${base_name}*.pdf" | head -n 1)
  if [[ -z "$found_pdf" || ! -s "$found_pdf" ]]; then
    log "Chyba: PDF nenalezeno pro $base_name"
    popd >/dev/null
    continue
  fi
  found_pdf="$(realpath "$found_pdf")"
  popd >/dev/null

  log "PDF vygenerováno: $found_pdf"

  # Přesun do PDF_OUTPUT_DIR
  compiled_pdf="${base_name}_compiled.pdf"
  final_compiled_pdf="$PDF_OUTPUT_DIR/$compiled_pdf"
  mv "$found_pdf" "$final_compiled_pdf"
  log "Přesunuto do: $final_compiled_pdf"

  # CSV
  csv_content=""
  if [[ ${#csv_list[@]} -gt 0 ]]; then
    csv_candidate="${csv_list[1]}"
    if [[ -n "$csv_candidate" ]]; then
      log "Hledám CSV: '$csv_candidate'"
      found_csv=$(find_file_in_root "$csv_candidate")
      if [[ -n "$found_csv" && -s "$found_csv" ]]; then
        csv_content="$(cat "$found_csv")"
        log "Nalezen CSV: $found_csv"
      else
        log "Chyba: CSV '$csv_candidate' nenalezen"
      fi
    fi
  fi

  # Vytvoření _summary.tex v TEMP_DIR
  summary_tex="$TEMP_DIR/${base_name}_summary.tex"
  log "DEBUG: Píšu do $summary_tex"

  { echo "\\setupcolors[state=start]"
    echo "\\setupurl[color=blue]"
    echo "\\setupinteraction[state=start,color=blue,contrastcolor=blue, style=normal]"
    echo "\\setuppagenumbering[state=stop]"
    echo "% \\setuplayout[backspace=1cm, width=middle,height=29cm, topspace=5mm, header=0cm, footer=5mm]"
    echo "\\setupbodyfont[regular, 9pt]"
    echo '\\setuphead[section, subject][style={\\bf}]'
    echo "% \\setuppapersize[A4,landscape]"
    echo ""
    echo "\\starttext"
    # Sekce 1
    echo "\\switchtobodyfont[11pt]"
    echo "\\section{Zdrojový kód: $tex_name}"
    echo "\\starttyping"
    cat "$tex_path"
    echo "\\stoptyping"
    echo ""

    # Sekce 2
    echo "\\switchtobodyfont[9pt]"
    if [[ -n "$csv_candidate" && -n "$csv_content" ]]; then
      echo "\\section{CSV data: $csv_candidate}"
      echo "\\starttyping"
      echo "$csv_content"
      echo "\\stoptyping"
    else
      echo "\\section{CSV data: -}"
    fi
    echo ""

    # Sekce 3 => \copypages
    echo "\\switchtobodyfont[11pt]"
    echo "\\section{Výsledná sazba: $compiled_pdf}"
    # Escapované hranaté závorky
#    log "DEBUG: Zapisuji \\copypages do _summary.tex..."
    echo '\\copypages['"$compiled_pdf"'][pages=all,scale=1000]'
#    echo '\\copypages['"$final_compiled_pdf"'][pages=all,scale=1000]'
    echo ""
    echo "\\stoptext"
  } >> "$summary_tex"

  if ! grep -q "copypages" "$summary_tex"; then
    log "CHYBA: \copypages se do $summary_tex nenapsalo!"
    continue
  fi

  log "Vytvořen dočasný zdroj: $summary_tex"

  # Zkopírujeme _compiled.pdf do TEMP_DIR
  cp "$final_compiled_pdf" "$TEMP_DIR/"

  # Kompilace shrnutí
  pushd "$TEMP_DIR" >/dev/null
  log "Kompiluji shrnutí: $(basename "$summary_tex")"
  context --purgeall "$(basename "$summary_tex")"
  if [[ $? -ne 0 ]]; then
    log "Chyba: Kompilace shrnutí selhala"
    popd >/dev/null
    continue
  fi
  summary_pdf="$TEMP_DIR/${base_name}_summary.pdf"
  if [[ ! -s "$summary_pdf" ]]; then
    log "Chyba: Shrnutí nevzniklo"
    popd >/dev/null
    continue
  fi
  popd >/dev/null
  log "Shrnutí PDF: $summary_pdf"

  # Přesun do PDF_OUTPUT_DIR
  final_summary_pdf="$PDF_OUTPUT_DIR/${base_name}_summary.pdf"
  mv "$summary_pdf" "$final_summary_pdf"
  mv "$summary_tex" "$PDF_OUTPUT_DIR/${base_name}_summary.tex"
  log "Shrnutí PDF => $final_summary_pdf"
  log "Zdroj => $PDF_OUTPUT_DIR/${base_name}_summary.tex"

done

mv "$LOG_FILE" "$PDF_OUTPUT_DIR/"
echo "Log přesunut do: $PDF_OUTPUT_DIR/$(basename "$LOG_FILE")"
echo "Zpracování dokončeno."
echo "Smazán: $TEMP_DIR/$compiled_pdf"
rm "$TEMP_DIR/$compiled_pdf"

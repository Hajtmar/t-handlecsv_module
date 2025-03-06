#!/bin/zsh

# Uložíme si výchozí adresář (odkud se skript spouští)
start_dir=$(pwd)
LOGFILE="$start_dir/compile_log.txt"

# Vytvoříme složku pdf_results, pokud ještě neexistuje
mkdir -p "$start_dir/pdf_results"

# Zaznamenáme celkový počáteční čas
overall_start=$(date +'%s.%N')

# Vytvoříme (nebo vymažeme předchozí) logovací soubor a zapíšeme datum a čas spuštění
echo "Log kompilace spuštěn: $(date +'%Y-%m-%d %H:%M:%S.%N')" > "$LOGFILE"
echo "" >> "$LOGFILE"

# Pole se seznamem adresářů
directories=(
  "Non-binding-tests"
)

# Seznam souborů, které se nesmí kompilovat
skip_list=("lib-lua.tex")

# Funkce, která zjistí, zda je zadaný prvek v poli
in_array() {
  local element
  for element in "${@:2}"; do
    if [[ "$element" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}

# Pro každý adresář provedeme:
for dir in "${directories[@]}"; do
  echo "-----------------------------------------------------" >> "$LOGFILE"
  echo "Zpracovávám adresář: $dir" | tee -a "$LOGFILE"
  echo "Adresář: $dir" >> "$LOGFILE"
  echo "Začátek zpracování adresáře: $(date +'%Y-%m-%d %H:%M:%S.%N')" >> "$LOGFILE"

  if cd "$dir"; then
    # Získáme seznam *.tex souborů
    tex_files=( *.tex )
    allowed_files=()
    if [ -e "${tex_files[1]}" ]; then
      for file in *.tex; do
        if [ -f "$file" ]; then
          if in_array "$file" "${skip_list[@]}"; then
            echo " - SKIP: $file" >> "$LOGFILE"
            echo "Přeskakuji soubor: $file"
          else
            echo " - $file" >> "$LOGFILE"
            allowed_files+=("$file")
          fi
        fi
      done

      # Pro každý soubor zvlášť provedeme kompilaci a měření času
      if [ ${#allowed_files[@]} -gt 0 ]; then
        for file in "${allowed_files[@]}"; do
          echo "-----------------------------------------------------" >> "$LOGFILE"
          echo "Kompiluji soubor: $file" | tee -a "$LOGFILE"
          file_start=$(date +'%s.%N')
          context --purgeall "$file"
          file_end=$(date +'%s.%N')
          file_duration=$(echo "$file_end - $file_start" | bc)
          echo "Kompilace souboru $file trvala: ${file_duration} sekund" >> "$LOGFILE"

          pdf_file="${file%.tex}.pdf"
          if [ -f "$pdf_file" ]; then
            echo "Přesouvám $pdf_file do $start_dir/pdf_results/" >> "$LOGFILE"
            mv "$pdf_file" "$start_dir/pdf_results/"
          else
            echo "PDF soubor $pdf_file nebyl nalezen." >> "$LOGFILE"
          fi
        done
      else
        echo "V adresáři $dir nejsou žádné soubory ke kompilaci (po vynechání zakázaných)." | tee -a "$LOGFILE"
      fi
    else
      echo " - Žádné .tex soubory nalezeny" >> "$LOGFILE"
      echo "V adresáři $dir nejsou žádné .tex soubory."
    fi
    # Vrátíme se do výchozího adresáře
    cd "$start_dir" || { echo "Nelze se vrátit do $start_dir."; exit 1; }
  else
    echo "Adresář '$dir' se nepodařilo najít nebo do něj nelze vstoupit." | tee -a "$LOGFILE"
  fi
  echo "" >> "$LOGFILE"
done

# Zaznamenáme konečný čas celkového běhu
overall_end=$(date +'%s.%N')
overall_duration=$(echo "$overall_end - $overall_start" | bc)

echo "-----------------------------------------------------" >> "$LOGFILE"
echo "Kompilace dokončena: $(date +'%Y-%m-%d %H:%M:%S.%N')" >> "$LOGFILE"
echo "Celkový čas zpracování všech souborů: ${overall_duration} sekund" | tee -a "$LOGFILE"

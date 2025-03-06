#!/bin/zsh

# Uložíme si výchozí adresář (odkud se skript spouští)
start_dir=$(pwd)
LOGFILE="$start_dir/compile_anyfiles_log.txt"

# Vytvoříme složku pdf_results, pokud ještě neexistuje
mkdir -p "$start_dir/pdf_results_anyfiles"

# Zaznamenáme celkový počáteční čas
overall_start=$(date +'%s.%N')

# Vytvoříme (nebo vymažeme předchozí) logovací soubor a zapíšeme datum a čas spuštění
echo "Log kompilace spuštěn: $(date +'%Y-%m-%d %H:%M:%S.%N')" > "$LOGFILE"
echo "" >> "$LOGFILE"

# Pole se seznamem konkrétních souborů ke kompilaci (uveďte názvy včetně přípony .tex)
files=(
#    "countriesandcities02.tex"
#    "loopstests01.tex"
#    "test-nolibrary01.tex"
#    "test-tables-hooks-001.tex"
#    "testing01.tex"
#    "testy_maker01.tex"
  # Přidejte další soubory dle potřeby
)

# Pro každý soubor provedeme:
for file in "${files[@]}"; do
  echo "-----------------------------------------------------" >> "$LOGFILE"
  echo "Hledám soubor: $file" | tee -a "$LOGFILE"

  # Najdeme soubor od výchozího adresáře; pokud by bylo více výsledků, vezmeme první
  file_path=$(find "$start_dir" -type f -name "$file" | head -n 1)

  if [[ -z "$file_path" ]]; then
    echo "Soubor $file nebyl nalezen." | tee -a "$LOGFILE"
    continue
  fi

  echo "Soubor nalezen: $file_path" >> "$LOGFILE"

  # Získáme adresář, kde se soubor nachází
  file_dir=$(dirname "$file_path")

  # Přepneme se do adresáře, kde se soubor nachází
  cd "$file_dir" || { echo "Nelze se přepnout do adresáře $file_dir" | tee -a "$LOGFILE"; continue; }

  echo "Aktuální adresář: $(pwd)" >> "$LOGFILE"
  echo "Kompiluji soubor: $file_path" | tee -a "$LOGFILE"

  # Změříme dobu kompilace pro tento soubor
  file_start=$(date +'%s.%N')
  context --purgeall "$(basename "$file_path")"
  status=$?
  file_end=$(date +'%s.%N')

  file_duration=$(echo "$file_end - $file_start" | bc)

  # Ověříme, zda vznikl PDF soubor s nenulovou velikostí
  pdf_file="${file%.tex}.pdf"
  if [ $status -eq 0 ] && [ -s "$pdf_file" ]; then
    echo "$file_path (OK)" >> "$LOGFILE"
  else
    echo "$file_path (KOMPILACE SELHALA!!!!)" >> "$LOGFILE"
  fi

  echo "Kompilace souboru $file_path trvala: ${file_duration} sekund" >> "$LOGFILE"

  # Pokud je PDF soubor v pořádku, přesuneme jej do složky pdf_results
  if [ $status -eq 0 ] && [ -s "$pdf_file" ]; then
    echo "Přesouvám $pdf_file do $start_dir/pdf_results/" >> "$LOGFILE"
    mv "$pdf_file" "$start_dir/pdf_results/"
  else
    echo "PDF soubor $pdf_file nebyl v pořádku vygenerován." >> "$LOGFILE"
  fi

  # Vrátíme se do výchozího adresáře
  cd "$start_dir" || { echo "Nelze se vrátit do $start_dir" | tee -a "$LOGFILE"; exit 1; }
  echo "" >> "$LOGFILE"
done

# Zaznamenáme konečný čas celkového běhu
overall_end=$(date +'%s.%N')
overall_duration=$(echo "$overall_end - $overall_start" | bc)
echo "-----------------------------------------------------" >> "$LOGFILE"
echo "Kompilace dokončena: $(date +'%Y-%m-%d %H:%M:%S.%N')" >> "$LOGFILE"
echo "Celkový čas zpracování všech souborů: ${overall_duration} sekund" | tee -a "$LOGFILE"


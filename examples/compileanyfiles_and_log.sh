#!/bin/zsh

# Uložíme si výchozí adresář (odkud se skript spouští)
start_dir=$(pwd)
LOGFILE="$start_dir/compile_anyfiles_log.txt"

# Konfigurovatelná cesta, kam se budou přesouvat výsledné PDF soubory
pdf_dest="$start_dir/pdf_results_anyfiles"

# Vytvoříme cílovou složku, pokud ještě neexistuje
mkdir -p "$pdf_dest"

# Zaznamenáme celkový počáteční čas
overall_start=$(date +'%s.%N')

# Vytvoříme (nebo vymažeme předchozí) logovací soubor a zapíšeme datum a čas spuštění
echo "Log kompilace spuštěn: $(date +'%Y-%m-%d %H:%M:%S.%N')" > "$LOGFILE"
echo "" >> "$LOGFILE"

# Seznam konkrétních souborů ke kompilaci (včetně přípony .tex)
files=(
     calculations_in_the_table.tex # specialities - kompilovat jako test funkčnosti.
     cities-of-world.tex # specialities - kompilovat jako test funkčnosti.
     cities-of-world-another-solutions.tex  # specialities - kompilovat jako test funkčnosti.
     2m4CM_programme.tex # kompilovat jako test funkčnosti.
     big_test_of_library_macros.tex # kompilovat jako test funkčnosti.
#     m3TE_programme.tex
#     listofparticipants-ctm_and_te.tex
#     test01-general.tex
#     cykly-test-008.tex
#     cykly-test-007.tex
#     test02-hooks.tex

#    letter01.tex
#    testy_maker01.tex
    #countriesandcities.tex
    #loopstests01.tex
    #test-nolibrary01.tex
    #test-tables-hooks-001.tex
    #testing01.tex
    #testy_maker01.tex
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
  # Jméno souboru bez přípony .tex
  pdf_base=$(basename "$file_path" .tex)

  # Přepneme se do adresáře, kde se soubor nachází
  cd "$file_dir" || {
    echo "Nelze se přepnout do adresáře $file_dir" | tee -a "$LOGFILE"
    continue
  }

  echo "Aktuální adresář: $(pwd)" >> "$LOGFILE"
  echo "Kompiluji soubor: $file_path" | tee -a "$LOGFILE"

  # Změříme dobu kompilace
  file_start=$(date +'%s.%N')
  context --purgeall "$pdf_base.tex"
  compile_status=$?   # <-- přejmenováno z 'status' na 'compile_status'
  file_end=$(date +'%s.%N')
  file_duration=$(echo "$file_end - $file_start" | bc)

  # Vypíšeme, jaké PDF soubory v adresáři vznikly
  echo "PDF soubory v aktuálním adresáři po kompilaci:" >> "$LOGFILE"
  ls -l *.pdf 2>/dev/null >> "$LOGFILE"

  # Ověříme, zda vznikl PDF soubor s očekávaným názvem a nenulovou velikostí
  pdf_file="$pdf_base.pdf"

  if [ $compile_status -eq 0 ] && [ -s "$pdf_file" ]; then
    echo "$file_path (OK)" >> "$LOGFILE"
  else
    echo "$file_path (KOMPILACE SELHALA!!!!)" >> "$LOGFILE"
  fi

  echo "Kompilace souboru $file_path trvala: ${file_duration} sekund" >> "$LOGFILE"

  # Pokud je PDF soubor v pořádku, přesuneme jej do složky pdf_dest
  if [ $compile_status -eq 0 ] && [ -s "$pdf_file" ]; then
    echo "Přesouvám $pdf_file do $pdf_dest/" >> "$LOGFILE"
    mv "$pdf_file" "$pdf_dest/"
    if [ $? -eq 0 ]; then
      echo "Přesun PDF souboru byl úspěšný." >> "$LOGFILE"
    else
      echo "Přesun PDF souboru selhal." >> "$LOGFILE"
    fi
  else
    echo "PDF soubor $pdf_file nebyl v pořádku vygenerován (nebo se jmenuje jinak)." >> "$LOGFILE"
  fi

  # Vrátíme se do výchozího adresáře
  cd "$start_dir" || {
    echo "Nelze se vrátit do $start_dir" | tee -a "$LOGFILE"
    exit 1
  }
  echo "" >> "$LOGFILE"
done

# Zaznamenáme konečný čas celkového běhu
overall_end=$(date +'%s.%N')
overall_duration=$(echo "$overall_end - $overall_start" | bc)
echo "-----------------------------------------------------" >> "$LOGFILE"
echo "Kompilace dokončena: $(date +'%Y-%m-%d %H:%M:%S.%N')" >> "$LOGFILE"
echo "Celkový čas zpracování všech souborů: ${overall_duration} sekund" | tee -a "$LOGFILE"


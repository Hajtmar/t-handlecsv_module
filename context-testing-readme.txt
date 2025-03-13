Testovací příklady nejvyšší kvality:

Nejlépe provést testy pomocí skriptů:
compileanyfiles_and_log.sh  -- kompilace vybraných souborů
compileall_and_log.sh       -- kompilace všech (s možností vybrat těch, co nekompilovat)

Zatím vybrané jsou zapsány ve skriptu: compileanyfiles_and_log.sh

Např. tyto:
     calculations_in_table01.tex ## kompilovat jako test funkčnosti.
     2m4CM_programme.tex
     m3TE_programme.tex
     listofparticipants-ctm_and_te.tex
     test01-general.tex
     cykly-test-008.tex
     cykly-test-007.tex
     test02-hooks.tex
     countriesandcities03.tex
    countriesandcities02.tex # je zajímavé, že tento soubor nejde zkompilovat tímto skriptem, nicméně přímo ve složce ano...
    letter01.tex
    testy_maker01.tex

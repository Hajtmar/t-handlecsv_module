#!/bin/bash
# Skript pro kompilaci více souborů v adresáři

context --purgeall cykly-01.tex
context --purgeall cykly-noexpand-01.tex
context --purgeall cykly-test-006.tex
context --purgeall cykly-test-007.tex
context --purgeall cykly-test-008.tex
context --purgeall loopstests01.tex
context --purgeall test-tables-002.tex
context --purgeall test-tables-hooks-002.tex
context --purgeall test01-general.tex
context --purgeall test01-noheader.tex
context --purgeall test02-hooks.tex
context --purgeall test01-speccolnames.tex
context --purgeall test03-handlecsv-tools.tex

deltemp.sh

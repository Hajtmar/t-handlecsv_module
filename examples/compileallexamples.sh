#!/bin/bash
# Skript pro kompilaci souborů v Examples adresáři

context --purgeall --mode=davka --arguments="pathtocsv=Calculations_in_tables/" --result=pdf_results/calculations_in_table01.pdf Calculations_in_tables/calculations_in_table01.tex
context --purgeall --mode=davka --arguments="pathtocsv=Calculations_in_tables/" --result=pdf_results/calculations_in_table02.pdf Calculations_in_tables/calculations_in_table02.tex












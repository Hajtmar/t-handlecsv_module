#!/bin/bash
# Skript pro kompilaci souborů v Examples adresáři

context --purgeall --mode=davka decision_on_admission-using_letter_module.tex
context --purgeall --mode=davka idcards.tex
context --purgeall --mode=davka invitation_card.tex
deltemp.sh


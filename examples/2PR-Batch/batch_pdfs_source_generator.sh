for f in *.csv; do
  context --autopdf --purgeall --result="generated_from_${f}" --arguments="csvfilename=${f}" source_generator.tex
done

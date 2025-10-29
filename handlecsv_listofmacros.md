# Complete Listing of Macros in the Latest Optimized Version (t‑handlecsv.lua v2025.02.25)

Tato verze knihovny implementuje přibližně 112 maker (včetně aliasů) a zachovává kompatibilitu s původní verzí. Níže je uveden kategorizovaný seznam maker s anglickými popisy, který můžete použít jako základ pro dokumentaci.

---

## State and Configuration Macros

- **`\ifissetheader` / `\ifnotsetheader`**
  Conditionals to test whether a CSV header is set.

- **`\ifEOF` / `\ifnotEOF`**
  Conditionals indicating if the end-of-file has been reached.

- **`\ifemptyline` / `\ifnotemptyline`**
  Conditionals testing whether the current CSV line is empty.

- **`\ifemptylinesmarking` / `\ifemptylinesnotmarking`**
  Conditionals reflecting whether empty lines are being marked.

- **`\setheader`**
  Sets the CSV header flag (updates internal state and global macros).

- **`\unsetheader`** (alias: `\resetheader`)
  Unsets the CSV header flag.

- **`\setsep{<separator>}`**
  Sets the field separator used when parsing CSV files.

- **`\unsetsep`** (alias: `\resetsep`)
  Resets the CSV field separator to its default value.

- **`\setfiletoscan{<filename>}`**
  Specifies the CSV file to be processed.

- **`\setcurrentcsvfile[<filename>]`**
  Sets (and returns) the current CSV file name.

---

## Global CSV Information

- **`\csvfilename` / `\currentcsvfile`**
  Returns the name of the currently processed CSV file.

- **`\numrows`**
  Returns the number of rows in the current CSV table.

- **`\numrowsof[<filename>]`**
  Returns the number of rows in a specified CSV file.

- **`\numcols`**
  Returns the number of columns in the current CSV file.

- **`\numcolsof[<filename>]`**
  Returns the number of columns in the specified CSV file.

- **`\numemptyrows`**
  Returns the number of empty rows in the CSV.

- **`\numnotemptyrows`**
  Returns the number of non-empty rows in the CSV.

---

## Expression and String Utilities

- **`\thenumexpr{<expression>}`**
  Evaluates a numerical expression (using TeX’s `\numexpr`).

- **`\addto\macro{<text>}` / `\eaddto\macro{<text>}`**
  Appends text to a macro (non-expanded and expanded versions).

- **Internal Lua function `H.trim(s)`**
  Trims leading and trailing whitespace from a string.

---

## Accessing CSV Cell Content

- **`\getcsvcell[<column>,<row>]`**
  Retrieves the content of the specified cell in the CSV.

- **`\csvcell[<column>,<row>]`**
  Alias for `\getcsvcell`, with automatic row-number evaluation.

- **`\currentcsvcell{<column>}`** (alias: `\currcell`)
  Retrieves the content of the cell in the current row for the specified column.

- **`\nextcsvcell{<column>}`** (alias: `\nextcell`)
  Retrieves the cell content from the next row.

- **`\previouscsvcell{<column>}`** (alias: `\prevcell`)
  Retrieves the cell content from the previous row.

- **`\colname[<column number>]`**
  Returns the header (or default XLS) name of the given column.

- **`\xlscolname[<column number>]`**
  Returns the Excel-style designation (e.g. A, B, …).

- **`\cxlscolname[<column number>]`**
  Returns the column name prefixed with 'c' (e.g. cA, cB, …).

- **`\texcolname[<column number>]`**
  Returns a TeX-safe version of the column name.

- **`\columncontent[<column>]`**
  Retrieves the content of the given column in the current row.

- **`\numberxlscolname[<xlsname>]`**
  Converts an Excel-style column name to a numeric index.

- **`\replacecontentin{<col>}{<find>}{<replace>}`**
  Performs a substitution in the cell content of the current row.

---

## Row Pointer and Counter Macros

- **`\linepointer`** (aliases: `\lineno`, `\sernumline`)
  Returns the current row pointer.

- **`\resetlinepointer` / `\resetlinepointerof[<csvfile>]`**
  Resets the row pointer to the beginning of the CSV.

- **`\setlinepointer{<number>}`**
  Sets the row pointer to a specified line.

- **`\savelineno`** (alias: `\savelinepointer`)
  Saves the current row pointer value.

- **`\setsavedlineno`** (alias: `\setsavedlinepointer`)
  Restores the saved row pointer value.

- **`\numline`**
  Returns the current internal line counter.

- **`\setnumline{<number>}`**
  Sets the internal line counter.

- **`\resetnumline`**
  Resets the internal line counter to zero.

- **`\addtonumline{<number>}`**
  Increments the internal line counter by a specified value.

- **`\indexofnotemptyline{<number>}`**
  Returns the index of a non-empty row.

- **`\indexofemptyline{<number>}`**
  Returns the index of an empty row.

- **`\markemptylines` / `\notmarkemptylines` / `\resetmarkemptylines` / `\removeemptylines`**
  Macra pro označení a správu prázdných řádků.

- **`\nextlineof[<csvfile>]`, `\prevlineof[<csvfile>]`, `\nextline`, `\prevline`**
  Pohyb mezi řádky (bez načítání obsahu).

- **`\nextnumline`**
  Inkrementuje čítač řádků.

- **`\nextrowof[<csvfile>]`, `\prevrowof[<csvfile>]`, `\nextrow`, `\prevrow`**
  Pohyb ukazatele a načítání řádku.

- **`\exitlooptest`**
  Podmínka pro ukončení cyklu (kontrola EOF).

---

## File Handling Macros

- **`\opencsvfile`** (volitelný parametr filename)
  Otevře CSV soubor a inicializuje interní proměnné.

- **`\closecsvfile{<filename>}`**
  Zavře otevřený CSV soubor.

- **`\readline`**
  Načte aktuální řádek CSV.

- **`\readlineof[<csvfile>]{<number>}`**
  Načte specifikovaný řádek z daného CSV souboru.

---

## Cycle (Loop) Macros

- **`\doloopfromto{<from>}{<to>}{<action>}`**
  Provede danou akci pro řádky od počáteční do koncové hodnoty.

- **`\doloopforall`** (nebo `\doloopforall{<action>}`)
  Provede akci pro všechny řádky CSV.

- **`\doloopaction`**
  Obecné makro pro provádění akce v cyklu s volitelnými parametry pro počáteční a koncový řádek.

- **`\doloopif{<val1>}{<operator>}{<val2>}{<action>}`**
  Podmíněný cyklus, který provede akci, pokud splní porovnávací podmínku.
  (Makro `\doloopifnum` je synonymem pro číselné porovnání.)

- **`\doloopuntil{<val1>}{<val2>}{<action>}`** (alias: `\repeatuntil`)
  Opakuje akci, dokud není podmínka splněna.

- **`\doloopwhile{<val1>}{<val2>}{<action>}`** (alias: `\whiledo`)
  Opakuje akci, pokud je podmínka pravdivá.

- **`\filelineaction{<filename>}`**
  Provede definovanou akci pro každý řádek CSV souboru specifikovaného jménem.

- **`\doloopfornext{<number>}{<action>}`**
  Provede akci pro následující daný počet řádků od aktuálního ukazatele.

---

## Internal and Helper Macros

- **`\readandprocessparameters#1#2#3#4`**
  Interní makro pro zpracování parametrů cyklů. Normalizuje porovnávací operátory (např. převádí `=<` na `<=`, `=>` na `>=`, `<>` na `~=`) a při porovnávání hodnot automaticky rozlišuje, zda se jedná o číselné nebo textové hodnoty.
  *Poznámka:* Výstup je uložen do makra `\paroperator`.

- **`\replacecontentin{<col>}{<find>}{<replace>}`**
  Provede náhradu textu v buňce CSV v aktuálním řádku.

---

## Summary

Tato sada maker poskytuje kompletní rozhraní pro práci s CSV soubory v ConTeXtu, zahrnující nastavení, čtení, navigaci a zpracování obsahu pomocí cyklů. Optimalizovaná verze se zaměřuje na efektivitu (použití `tex.sprint` z Lua), robustnost (ochrana proti indexaci nil hodnot) a flexibilitu (normalizace operátorů pomocí makra `\readandprocessparameters`).

---

### Example Usage

```tex
\opencsvfile{data.csv}
\numrows % Vypíše počet řádků v data.csv
\readline % Načte aktuální řádek a aktualizuje odpovídající makra
\doloopfromto{1}{\numrows}{\lineaction} % Provede definovanou akci pro všechny řádky

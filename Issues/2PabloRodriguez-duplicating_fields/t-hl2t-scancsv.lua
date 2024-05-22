

-- 
-- 
-- debug=io.open("debug.txt","w+")
-- 
-- function texsprint(parametr)
-- debug:write(parametr)
-- end
-- 
-- 



thirddata = thirddata or { }

thirddata.scancsv = { -- Global variables
    gUserCSVSeparator=';',  -- the most widely used field separator in CSV tables
    gUserCSVLeftDelimiter='', --  most widely used left field "quoter" in CSV tables
    gUserCSVRightDelimiter='', -- and right field "quoter"
    gUserCSVHeader=false, -- CSV file is by default considered as a CSV file without the header (in header are treated as column names of macros
    gUserColumnNumbering='XLS',  -- Something other than the XLS or undefined variable value (eg commenting that line) to set the Roman numbering ...
    -- gCSVHeader, --
    -- gDel, --
    -- gLq, --
    -- gRq, --
    gCSVFile=nil, --
    gCSV={}, --
    gCSVField={}, --
    gNumLine=0, --
    gLineNo=0, --
    gNumRows=0, --
    gNumCols=0, --
    gFile2Scan=nil,--
    gIfEOF=false, --
    gIfNotEOF=true --
}


--  Default value is saved  in glob. variable gUserCSVHeader (default FALSE)
if thirddata.scancsv.gCSVHeader == nil then thirddata.scancsv.gCSVHeader = thirddata.scancsv.gUserCSVHeader end


function thirddata.scancsv.ParseCSVLine (line,sep)
  -- Source: http://lua-users.org/wiki/LuaCsv
  -- Lua Csv
  -- Here's some resources on parsing CSV files in Lua.
  -- Programming in Lua - [1] - has has example code for parsing CSV files.
  -- [LuaCSV] is a C module for reading CSV
  -- CsvUtils - some utility functions
  -- The Lua Unofficial FAQ, has an entry "How to read CSV data?" [2]
  -- Parser in Lua
  -- A simple parser for comma-separated-value (.csv) files:
  -- Last edited September 21, 2010 2:55 am GMT (diff)
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos)
				if (c == '"') then txt = txt..'"' end
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end
		end
	end
	return res
end



function thirddata.scancsv.parsecsvdata(string2parse, delimiter, leftquoter, rightquoter)
	-- Function for "parsing" of records (rows) CSV table
	-- Input text string (line read) is "chopped" for each field
	-- The only required input parameter is 'string2parse'. The remaining three parameters not set up as a separator, and separators used either a global variable gDel, and gLq gRq or use default values
	-- The result is an array of separate chains
	-- When there are global variables gDel, and gLq gRq user, set to default values. The user can change any default values depending on the values used in its most common applications
	thirddata.scancsv.gDel = (thirddata.scancsv.gDel == nil) and thirddata.scancsv.gUserCSVSeparator or thirddata.scancsv.gDel 	-- Pokud není glob. neznámá gDel nastavena, použije se defaultní hodnota ';' (středník).
	thirddata.scancsv.gLq = (thirddata.scancsv.gLq == nil) and thirddata.scancsv.gUserCSVLeftDelimiter or thirddata.scancsv.gLq -- Pokud není glob. neznámá gLq (left delimiter) nastavena, použije se defaultní hodnota '' (prázdný řetězec)
	thirddata.scancsv.gRq = (thirddata.scancsv.gRq == nil) and thirddata.scancsv.gUserCSVRightDelimiter or thirddata.scancsv.gRq -- Pokud není glob. neznámá gRq (right delimiter) nastavena, použije se defaultní hodnota '' (prázdný řetězec)
  -- Setting parameter values that are not in a function call that is set when the function thirddata.scancsv.parsecsvdata (string2parse) with only one parameter
	local delimiter = (delimiter == nil) and thirddata.scancsv.gDel or delimiter -- if not set in the separator is used
	local leftquoter = (leftquoter == nil) and thirddata.scancsv.gLq or leftquoter
	local rightquoter = (rightquoter == nil) and thirddata.scancsv.gRq or rightquoter
	-- own processing chain ...
	local result={}
		if leftquoter ~= '' and rightquoter ~= '' then -- When items are in the line defined by left and right delimiter (ie a kind of parenthesis), for example, "field1", "field2" or {field1}, {field2} .. etc.
			string.gsub(string2parse, leftquoter.."(.-)"..rightquoter, function(a) table.insert(result,a) end ) -- It is seen that in this case nor the matter separator, each bracketed strings are separated from each other
		else -- When only the fields separator no defining characteristics - the delimiter (in this case, unfortunately, not using a splitter as a separate character in any field)
  		--
      -- old version : -- result=string.split(string2parse,delimiter) -- then just input string is splited ie chop into separate parts
		  --
      -- in a new version is thirddata function ParseCSVLine used (this function solves the case when some items are in quotes and others are not)
      result=thirddata.scancsv.ParseCSVLine (string2parse,delimiter)
    end
	return result  -- function returns an array containing the result separated by a single row array CSV record
end



function thirddata.scancsv.getnumrows(file)
	local inpcsvfile=thirddata.scancsv.csvfilename(file)
	local numrows=0	
	for line in io.lines(inpcsvfile) do numrows=numrows+1 end
  -- The header not to take
	if thirddata.scancsv.gCSVHeader then numrows=numrows-1 end
	thirddata.scancsv.gNumRows=numrows -- gNumRows is global variable
return numrows
end -- of thirddata.scancsv.getnumrows(file)



function thirddata.scancsv.opencsvfile(file) -- Open CSV tabule, inicialize variables
	 local inpcsvfile=thirddata.scancsv.csvfilename(file)
	 local numrows=thirddata.scancsv.getnumrows(inpcsvfile) -- Getting number of rows
	-- gCSVFile, gCSV ..... global variables
	-- Based on the values of global variable gUserColumnNumbering after opening a file creates a list of macros:
	-- either \cA, \cB, \cC, ..., \cAA, \cAB, ... tj. ala Excel (gUserColumnNumbering='XLS' - default setting)
	-- or \cI, \cII, \cIII atd. tj. římskými číslicemi (gUserColumnNumbering= other than 'XLS')
	-- Use of these TeX macros that can be accessed in the ConTeXt line items.
	-- Then there is a possibility to define your own macros by constructing \let\mojemakro\cA etc.
	-- Moreover, after calling this function retrieves the first line of the CSV file (ie CSV header table) and
	-- then take the field names, which you will receive in ConTeXt to individual items CSV table
	-- for example: If the CSV table headers: Name;Surname;... etc.
	-- get data from CSV table in Lua due gCSV.Name, gCSV.Surname etc.
	-- and in ConTeXt due \Name, \Surname, etc.
	-- If you are in the 1st line of characters that can not be in the name of TeX macros and automatically
	-- macro names adjusted to fair value (removes, digits, etc. ..)
	context.setgvalue("csvfilename",tostring(inpcsvfile)) -- \csvfilename macro defining
  context.setgvalue("numrows",tostring(numrows)) -- \numrows macro defining
	thirddata.scancsv.gCSVFile=io.open(inpcsvfile,"r")
	local csvline=thirddata.scancsv.gCSVFile:read() -- read 1st row, when gCSVHeader=TRUE, then first row is not data row
	thirddata.scancsv.gCSV=thirddata.scancsv.parsecsvdata(csvline) --   load field of names of columns
  	thirddata.scancsv.gNumCols=#thirddata.scancsv.gCSV
  context.setgvalue("numcols",#thirddata.scancsv.gCSV) --  \numcols macro defining 	- number of columns of CSV table
	-- from these data to create an associative array where the "index " are the names of columns
	-- After reading the first CSV table row for each field defines the TeX macro with the same name as the name field.
	-- The content of macro initializes the same value (for testing non-empty values before cycle).
	-- for example for header of CSV file:
	-- Surname;Name;BirthDate;BirthPlace;Sex;Country;ZIP;Street
	-- se vytvoří inicializační makra \def\Surname{Surname}, \def\Name{Name}, etc.
	-- This is because the names of macros to use to create buffers, macros, etc
	for i = 1, #thirddata.scancsv.gCSV do 	-- for all fields from header
      context.setvalue("c"..thirddata.scancsv.ar2colnum(i),thirddata.scancsv.gCSV[i]) -- automatic creating TeX macros \cI, \cII, etc and creating of contents
      context.setgvalue(thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'\\c'..thirddata.scancsv.ar2colnum(i))
      -- In this columns macros are "hooks")
		context.setvalue("hc"..thirddata.scancsv.ar2colnum(i),'{\\bch'..thirddata.scancsv.gCSV[i]..'\\ech}')	-- context.setvalue("hc"..thirddata.scancsv.ar2colnum(i),'\{\\bch'..thirddata.scancsv.gCSV[i]..'\\ech\}') -- automatic creating TeX macros \hcI, \hcII, etc and creating 'hooked' contents
	   context.setgvalue('h'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'{\\bch\\c'..thirddata.scancsv.ar2colnum(i)..'\\ech}') -- macro is closed to group \bch ... \ech -- context.setgvalue('h'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'\{\\bch\\c'..thirddata.scancsv.ar2colnum(i)..'\\ech\}') -- macro is closed to group \bch ... \ech
  end -- for i=1, #gCSV
	thirddata.scancsv.gCSVFile:close();
	thirddata.scancsv.gNumLine=0 -- This global variable contains the line number currently reading row
   thirddata.scancsv.gLineNo=0 -- This global variable contains the actual line of CSV file 
  thirddata.scancsv.gCSVFile=io.open(inpcsvfile,"r")
	thirddata.scancsv.readlinefromcsv(true);	
		if thirddata.scancsv.gCSVHeader then
 			thirddata.scancsv.readlinefromcsv(true); -- this is data line
	 		thirddata.scancsv.gNumLine=1 -- This global variable contains the line number currently reading row
         thirddata.scancsv.gLineNo=1 -- This global variable contains the actual line of CSV file
	  end
  context.setgvalue("numline",thirddata.scancsv.gNumLine) --  \numline macro defining. This macro contains a number of the currently loaded row for use in a ConTeXt
  context.setgvalue("lineno",thirddata.scancsv.gLineNo) --  \lineno macro defining. This macro contains a number of the actual row of CSV table
  thirddata.scancsv.gCSVField={} -- Experimental ... create an array to store the act. field values from the currently loaded row ...
	context([[\global\EOFfalse]])
 	context([[\global\notEOFtrue]])
  gIfEOF=false
  gIfNotEOF=true
end -- of thirddata.scancsv.opencsvfile(file)


function thirddata.scancsv.fillvaluesintomacros(i,csvlinei)
-- This function fill data into macros
--  
if csvlinei=='' then 
	context.setevalue('previousc'..thirddata.scancsv.ar2colnum(i), '')
	context.setgvalue('c'..thirddata.scancsv.ar2colnum(i), '') -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically 			
   context.setgvalue('hc'..thirddata.scancsv.ar2colnum(i),'\\bch \\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
   -- Adding additional values for testing...
   context.setevalue(thirddata.scancsv.tmn("previous"..thirddata.scancsv.gCSV[i]),'') 
   context.setgvalue(thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'')
   context.setgvalue('h'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'\\bch \\ech')
else
	context.setevalue('previousc'..thirddata.scancsv.ar2colnum(i), "\\c"..thirddata.scancsv.ar2colnum(i))
	context.setgvalue('c'..thirddata.scancsv.ar2colnum(i), csvlinei) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically 			
   context.setgvalue('hc'..thirddata.scancsv.ar2colnum(i),'\\bch '..csvlinei..'\\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
   -- Adding additional values for testing...
   context.setevalue(thirddata.scancsv.tmn("previous"..thirddata.scancsv.gCSV[i]),'\\'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i])) 
   context.setgvalue(thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),csvlinei)
   context.setgvalue('h'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'\\bch '..csvlinei..'\\ech')
end
--
end -- of thirddata.scancsv.fillvaluesintomacros()


function thirddata.scancsv.readlinefromcsv(deftexmacros)
-- Parameter deftexmacros=TRUE ensure to create TeX macros containing  row data
-- When deftexmacros=FALSE - columns data are not defined
-- After calling this function remains in an associative array CSV the content of reading line
-- the data in a CSV table are available via Lua variables gCSV.Name, gCSV.Surname, gCSV.BirthDate etc
	local csvline=thirddata.scancsv.gCSVFile:read() -- read row
	if csvline ~= nil -- While it is not the last row
	then
			thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine+1
         thirddata.scancsv.gLineNo=thirddata.scancsv.gLineNo+1
			context.setgvalue("numline", thirddata.scancsv.gNumLine) -- change the definition of a macro with the number of the acttual loaded line to use ConTeXt
         context.setgvalue("lineno", thirddata.scancsv.gLineNo) -- change the definition of a macro with the number of the acttual line of CSV table
      csvline=thirddata.scancsv.parsecsvdata(csvline) -- parse row
		 	for i = 1, #csvline do 	-- create an associative array: the index column names
		 	  -- Experimental row:
				thirddata.scancsv.gCSVField[thirddata.scancsv.ar2xls(i)]=csvline[i] -- Fill the column field from the act. line data
		 	  --thirddata.scancsv.gCSVField[i]=csvline[i] -- not used
				thirddata.scancsv.gCSV[thirddata.scancsv.gCSV[i]]=csvline[i] -- values are data from a CSV row of the table column
			  if deftexmacros then -- set the current contents of macro when deftexmacros = TRUE
					thirddata.scancsv.fillvaluesintomacros(i,csvline[i])
-- 			 context.setevalue('previousc'..thirddata.scancsv.ar2colnum(i), "\\c"..thirddata.scancsv.ar2colnum(i))
-- 			 context.setgvalue('c'..thirddata.scancsv.ar2colnum(i), csvline[i]) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically 			
--           context.setgvalue('hc'..thirddata.scancsv.ar2colnum(i),'\\bch '..csvline[i]..'\\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
--            -- Adding additional values for testing...
--           context.setevalue(thirddata.scancsv.tmn("previous"..thirddata.scancsv.gCSV[i]),'\\'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i])) 
--           context.setgvalue(thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),csvline[i])
--           context.setgvalue('h'..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i]),'\\bch '..csvline[i]..'\\ech')
        end -- if deftexmacros
			end -- for
    context([[\global\EOFfalse]])
  	context([[\global\notEOFtrue]])
    gIfEOF=false
    gIfNotEOF=true
	 return(true)  -- continue
	else
	   context([[\global\EOFtrue]])
	   context([[\global\notEOFfalse]])
	 	 gIfEOF=true
     gIfNotEOF=false
     return(false) -- end of cycle
	end -- if csvline ~= nil
end

function thirddata.scancsv.csvreport(file) -- Listing report informations about opening a CSV file
	local inpcsvfile=thirddata.scancsv.csvfilename(file)
 	local coldelim = thirddata.scancsv.gDel or ""
	local lquot = thirddata.scancsv.gLq or ""
	local rquot = thirddata.scancsv.gRq or ""
  thirddata.scancsv.opencsvfile(inpcsvfile)
	infomakra=[[\crlf ]]
	for i = 1, #thirddata.scancsv.gCSV do 	-- for all fields in header
		local makroname=[[{\bf\backslash ]]..thirddata.scancsv.tmn(thirddata.scancsv.gCSV[i])..[[}]]
		  headercolnames = [[{\bf\backslash c]]..thirddata.scancsv.ar2colnum(i)..[[}=]]..makroname..[[, ]]
			infomakra=infomakra..headercolnames -- list generating
	  end -- for i=1, #gCSV
		-- Kvůli nastavení na zač.
		thirddata.scancsv.gCSVFile=io.open(inpcsvfile,"r")
		local csvline=thirddata.scancsv.gCSVFile:read() -- read 1st row (contains header with column names)
	infomakra=infomakra..'\\par'   -- infomakra=infomakra..'\par'  -- closing of opened group
local string2print=[[\title{Current CSV file report}
Input CSV file: {\bf ]]..'\\csvfilename'..[[} \crlf
Separator (delimiter) and "quoters" see Lua variables {\tt gDel}, {\tt gLq} a  {\tt gRq}\crlf
Current settings of delimiters and quoters:    {\tt ]]..lquot..[[field1]]..rquot..coldelim..lquot..[[field2]]..rquot..coldelim..lquot..[[field3]]..rquot..coldelim..[[...}\crlf
Number of columns in a table:  {\bf]]..'\\numcols'..[[}\crlf
Number of rows in the table:  {\bf ]]..'\\numrows'..[[}\crlf
Macros supplying columns data in each row of table:  ]]..infomakra..[[
\crlf
Additional predefined macros: \crlf
{\bf\backslash csvfilename} -- name of open CSV file ({\bf]]..'\\csvfilename'..[[})\crlf
{\bf\backslash numcols} -- number of table columns ({\bf]]..'\\numcols'..[[})\crlf
{\bf\backslash numrows} -- number of table lines ({\bf]]..'\\numrows'..[[})\crlf
{\bf\backslash numline} -- number of the currently loaded row (for use in print reports) \crlf
{\bf\backslash lineno} -- number of the actual loaded row of CSV table \crlf
{\bf\backslash csvreport} -- prints the report on file open \crlf
{\bf\backslash printline} -- lists the current CSV row table in a condensed form \crlf
{\bf\backslash printall} -- CSV output table in a condensed form \crlf
{\bf\backslash setfiletoscan}{{\it filename}} -- setting of name of CSV file\crlf
{\bf\backslash opencsvfile}{{\it filename}} -- open CSV table\crlf
{\bf\backslash setheader} -- set a header flag\crlf
{\bf\backslash resetheader} -- unset a header flag\crlf
{\bf\backslash nextrow} -- next row of CSV table (with test of EOF)\crlf
{\bf\backslash setsep}{{\it delimiter}} -- set delimiter of columns\crlf
{\bf\backslash resetsep} -- unset to default values\crlf
{\bf\backslash setld}{{\it delimiter}} -- set left quoter\crlf
{\bf\backslash resetld} -- unset left quoter to default values\crlf
{\bf\backslash setrd}{{\it delimiter}} -- set right quoter\crlf
{\bf\backslash resetrd} -- unset right quoter to default values\crlf
{\bf\backslash blinehook} -- begin line hook macro (process before first column value of each row)\crlf
{\bf\backslash elinehook} -- end line hook macro (process after last column value of each row)\crlf
{\bf\backslash bfilehook} -- begin file hook macro (process before whole file processing)\crlf
{\bf\backslash efilehook} -- end file hook macro (process after whole file processing)\crlf
\vfill\break ]]
thirddata.scancsv.string2context(string2print)
end -- thirddata.scancsv.csvreport()


function thirddata.scancsv.tmn(s) -- TeX Macro Name. Name of TeX macro should not contain forbidden characters
	if string.len(s) == 0 then s='nil' end -- When the parameter 's' does not contain any character that is not the separator character, it is necessary to create macro name
  maxdelkamakra=20 -- if the first string in line longer "than is healthy, so about 20 characters is sufficient
  -- ATTENTION! In the case that 1st CSV table row header that is a different column for content, which coincides with the first 'maxdelkamakra' characters, the names of macros in different columns are the same (ie, the macro will give the correct result for the column)
	diachar=  {"á","ä","č","ď","é","ě","í","ň","ó","ř","š","ť","ú","ů","ý","ž","Á","Ä","Č","Ď","É","Ě","Í","Ň","Ó","Ř","Š","Ť","Ú","Ů","Ý","Ž"}
	asciichar={"a","a","c","d","e","e","i","n","o","r","s","t","u","u","y","z","A","A","C","D","E","E","I","N","O","R","S","T","U","U","Y","Z"}
	for i=1, 32 do
		s=string.gsub(s, diachar[i], asciichar[i]) -- change diakritics chars
	end
	--s=string.gsub(s, "%d", "n") -- replace the numbers in name
	-- For 0-9 to replace the letter O or Roman numerals
	s=string.gsub(s, "0", "O") -- replace the numbers in name
	s=string.gsub(s, "1", "I") -- replace the numbers in name
	s=string.gsub(s, "2", "II") --
	s=string.gsub(s, "3", "III") --
	s=string.gsub(s, "4", "IV") --
	s=string.gsub(s, "5", "V") --
	s=string.gsub(s, "6", "VI") --
	s=string.gsub(s, "7", "VII") --
	s=string.gsub(s, "8", "VIII") --
	s=string.gsub(s, "9", "IX") --
	s=string.gsub(s, "%A", "x") -- Finally still removes all nealfabetic characters that were left there
  if string.len(s) > maxdelkamakra+1 then s=string.sub(s, 1, maxdelkamakra) end -- to limit the maximum length of a macro
return s
end


function thirddata.scancsv.ar2xls(arnum) -- convert number to Excel name column
   -- For more than 703 columns (ie column A to ZZ) should be a function to modify
   -- Excel 2003 can handle only up to the column IV!
	 local podil=math.floor(arnum/26)
   local zbytek = math.mod(arnum,26)
   podil = podil   - (math.mod(arnum,26)==0 and 1 or 0)
	 zbytek = zbytek + (math.mod(arnum,26)==0 and 26 or 0)
   local ctl =''
	 if arnum < 703 then
			 if podil > 0 then
			   ctl=string.char(64+podil)
			 end
			 ctl = ctl .. string.char(64+zbytek)
 	 else
    ctl = 'overZZ'
	 end
 return ctl
end


function thirddata.scancsv.ar2colnum(arnum) -- According to the settings glob. variable returns the column designation of TeX macros
	-- generated TeX macros referring to values in columns are numbered a`la EXCEL ie cA, cB, ..., cAA, etc
	-- or a`la roman number ie. cI, cII, cIII, cIV, ..., cXVIII, etc
	-- if it is "romannumbers" setting, then columns wil numbered by Romna else ala Excel
	if string.lower(thirddata.scancsv.gUserColumnNumbering) == 'xls' then
		return thirddata.scancsv.ar2xls(arnum) --  a la EXCEL
	else
      return string.upper(converters.romannumerals(arnum)) -- a la big ROMAN - convert Arabic numbers to big Roman. Used for "numbering" column in the TeX macros
   end
end



function thirddata.scancsv.printline() -- lists the current CSV row table (needed to define macro \printline)
	-- for i=1,table.maxn(thirddata.scancsv.gCSV) do
	for i=1,#thirddata.scancsv.gCSV do
    context([[\c]]..thirddata.scancsv.ar2colnum(i)..thirddata.scancsv.gDel..[[ ]])
	end
end


function thirddata.scancsv.csvfilename(file) -- In the absence of the file name to use the global variable
	 thirddata.scancsv.gFile2Scan = (file ~= nil) and file or thirddata.scancsv.gFile2Scan
	 thirddata.scancsv.gFile2Scan = (thirddata.scancsv.gFile2Scan == nil) and file or thirddata.scancsv.gFile2Scan
   local file = (file ~= nil) and file or thirddata.scancsv.gFile2Scan
   return file
end


function thirddata.scancsv.printall() -- lists all the csv table (necessary to define macros \printall)
 thirddata.scancsv.opencsvfile()
 context.bTABLE()
 		while thirddata.scancsv.readlinefromcsv(true) do -- until the end of the input CSV file
      context.bTR()
			--for i=1,table.maxn(thirddata.scancsv.gCSV) do
		  for i=1,#thirddata.scancsv.gCSV do
  			context.bTD()
        context(thirddata.scancsv.gCSVField[thirddata.scancsv.ar2xls(i)]) -- Writing real values ...
        context.eTD()
			end
			context.eTR()
		end -- of while
context.eTABLE()
end


interfaces.definecommand {
    name      = "printline",
    macro     = thirddata.scancsv.printline,
}

interfaces.definecommand {
    name      = "printall",
    macro     = thirddata.scancsv.printall,
}


interfaces.definecommand {
    name      = "csvreport",
    macro     = thirddata.scancsv.csvreport,
}


function thirddata.scancsv.paramcontrol(from, to)
		local tempnumrows=thirddata.scancsv.gNumRows
    local tempfrom=from
    local tempto=to
		local temptemp=0
 
	  if tempfrom==nil then tempfrom=1 end
	  if tempto==nil then tempto=tempnumrows end
	
		-- When both parameters are negative, set from 0-MAX
		if tempfrom<0 then tempfrom=1 end
		if tempto<0 then tempto=tempnumrows end
 
    if tempfrom>tempto then
			temptemp=tempfrom
			tempfrom=tempto
			tempto=temptemp
		end
				
		if tempto>tempnumrows then tempto=tempnumrows end
		if tempfrom>tempnumrows then tempfrom=1 end
		tempfromI=tempfrom-1

		tex.count.scancsvtempfrom=tempfrom
		tex.count.scancsvtempfromI=tempfromI
		tex.count.scancsvtempto=tempto
end -- function thirddata.scancsv.paramcontrol(from, to)


interfaces.definecommand {
    name      = "paramcontrol",
    macro     = thirddata.scancsv.paramcontrol,
    arguments = {
        { "content", "number" },
        { "content", "number" }
    }
}


function thirddata.scancsv.setfiletoscan(filetoscan)
 thirddata.scancsv.gFile2Scan=filetoscan
end

interfaces.definecommand {
    name      = "setfiletoscan",
    macro     = thirddata.scancsv.setfiletoscan,
    arguments = {
        { "content", "string" }
    }
}



function thirddata.scancsv.setheader()
 thirddata.scancsv.gCSVHeader=true
end

interfaces.definecommand {
    name      = "setheader",
    macro     = thirddata.scancsv.setheader,
}

function thirddata.scancsv.resetheader()
 thirddata.scancsv.gCSVHeader=false
end

interfaces.definecommand {
    name      = "resetheader",
    macro     = thirddata.scancsv.resetheader,
}


function thirddata.scancsv.setsep(sep)
  thirddata.scancsv.gDel=sep
end

interfaces.definecommand {
    name      = "setsep",
    macro     = thirddata.scancsv.setsep,
    arguments = {
        { "content", "string" }
    }
}


function thirddata.scancsv.resetsep()
  thirddata.scancsv.gDel=thirddata.scancsv.gUserCSVSeparator
end

interfaces.definecommand {
    name      = "resetsep",
    macro     = thirddata.scancsv.resetsep,
}



function thirddata.scancsv.setld(ld)
  thirddata.scancsv.gLq=ld
end

interfaces.definecommand {
    name      = "setld",
    macro     = thirddata.scancsv.setld,
    arguments = {
        { "content", "string" }
    }
}

function thirddata.scancsv.resetld()
  thirddata.scancsv.gLq=thirddata.scancsv.gUserCSVLeftDelimiter
end

interfaces.definecommand {
    name      = "resetld",
    macro     = thirddata.scancsv.resetld,
}


function thirddata.scancsv.setrd(rd)
  thirddata.scancsv.gRq=rd
end

interfaces.definecommand {
    name      = "setrd",
    macro     = thirddata.scancsv.setrd,
    arguments = {
        { "content", "string" }
    }
}


function thirddata.scancsv.resetrd()
  thirddata.scancsv.gRq=thirddata.scancsv.gUserCSVRightDelimiter
end

interfaces.definecommand {
    name      = "resetrd",
    macro     = thirddata.scancsv.resetrd,
}


function thirddata.scancsv.setroman()
  thirddata.scancsv.gUserColumnNumbering=''
end

interfaces.definecommand {
    name      = "setroman",
    macro     = thirddata.scancsv.setroman,
}

function thirddata.scancsv.setxls()
  thirddata.scancsv.gUserColumnNumbering='XLS'
end

interfaces.definecommand {
    name      = "setxls",
    macro     = thirddata.scancsv.setxls,
}


function thirddata.scancsv.nextrow()
  thirddata.scancsv.readlinefromcsv(true) --then
end

interfaces.definecommand {
    name      = "nextrow",
    macro     = thirddata.scancsv.nextrow,
}



function thirddata.scancsv.resethooks() 
 context([[\letvalue{blinehook}=\relax
   \letvalue{elinehook}=\relax
   \letvalue{bfilehook}=\relax
   \letvalue{efilehook}=\relax
   \letvalue{bch}=\relax
   \letvalue{ech}=\relax]])
end


interfaces.definecommand {
    name      = "resethooks",
    macro     = thirddata.scancsv.resethooks,
}



function thirddata.scancsv.string2context(str2ctx)
  local s=str2ctx
  s=string.gsub(s, "%%(.-)\n", "\n")  -- remove TeX comments from string. From % character to the end of line
  -- s=string.gsub(s, '\n', "")
  context(s)
  -- texsprint(s) -- for debugging ...
end





function thirddata.scancsv.doloopfromto(from, to, action)
   thirddata.scancsv.opencsvfile()
   context.bfilehook()
   thirddata.scancsv.paramcontrol(from,to)

   local scancsvtempfrom=tex.count.scancsvtempfrom
   local scancsvtempfromI=tex.count.scancsvtempfromI
   local scancsvtempto=tex.count.scancsvtempto
 
      thirddata.scancsv.gNumLine=1-scancsvtempfromI
      
    if scancsvtempfrom>0 then
       for i=1, scancsvtempfromI do
        thirddata.scancsv.nextrow()
       end
      end
 
       
    if scancsvtempfrom<scancsvtempto then
       for i=scancsvtempfrom, scancsvtempto do
         context.blinehook()
         context(action)
         context.elinehook()
         thirddata.scancsv.nextrow()
       end
    else
     context.blinehook()
     context(action)
     context.elinehook()
    end
   context.efilehook()
end -- function thirddata.scancsv.doloopfromto


-- %% \ doloopfromto{3}{7}{\action}  % do \action macro from 3 to 7 lines
interfaces.definecommand {
    name      = "doloopfromto",
    macro     = thirddata.scancsv.doloopfromto,
    arguments = {
        { "content", "number" },
        { "content", "number" },
        { "content", "string" }
    }
}








local string2print=[[
\resethooks
\setvalue{ermessage}{The \backslash lineaction macro is undefined!\crlf}
\letvalue{lineaction}=\ermessage
\letvalue{numrows}=\relax
\newif\ifEOF
\newif\ifnotEOF
\newcount\scancsvtempfrom
\newcount\scancsvtempfromI
\newcount\scancsvtempto

% CONTEXT MACRO DEFINITIONS

% Open CSV file. Syntax: \opencsvfile or \opencsvfile{filename}.
\def\opencsvfile{%
    \dosingleempty\doopencsvfile%
}

\def\doopencsvfile[#1]{%
	\dosinglegroupempty\dodoopencsvfile
}

\def\dodoopencsvfile#1{%
    \iffirstargument
    \ctxlua{thirddata.scancsv.opencsvfile("#1")}
   \else
	 \ctxlua{thirddata.scancsv.opencsvfile()}
   \fi
}

% not used ...\def\openheadercsvfile#1{\ctxlua{thirddata.scancsv.gCSVHeader=true}\opencsvfile{#1}}


% ACTIONS IN CYCLES (DEFINITIONS)


% 1. \doloopfromto{from}{to}{action}  % this macro is defining in LUA section
% do action "action" from line "from" to line "to" of open CSV file 


% 2. \doloopforall  % implicit do \lineaction for all lines of open CSV table
% \doloopforall{\action}  % do \action macro for all lines of open CSV table
\def\doloopforall{\dosinglegroupempty\doloopforAll}

\def\doloopforAll#1{%
  \doifsomethingelse{#1}{%1 args.
	\doloopfromto{-1}{-1}{#1}%
	}{%
	\doloopfromto{-1}{-1}{\lineaction}%
	}%
}%


% 3. \doloopaction % implicit use \lineaction macro
% \doloopaction{\action} % use \action macro for all lines of open CSV file
% \doloopaction{\action}{4} % use \action macro for first 4 lines
% \doloopaction{\action}{2}{5} % use \action macro for lines from 2 to 5
\def\doloopaction{\dotriplegroupempty\doloopAction}


\def\doloopAction#1#2#3{%
\opencsvfile%
\doifsomethingelse{#3}{%3 args.
	\doloopfromto{#2}{#3}{#1}% if 3 arguments then do #1 macro from #2 line to  #3 line
	}{%
	\doifsomethingelse{#2}{%2 args.
	\doloopfromto{1}{#2}{#1}% if 2 arguments then do #1 macro for first #2 lines
	}%
	{\doifsomethingelse{#1}{% 1 arg.
		\doloopfromto{-1}{-1}{#1}%
		}{% if without arguments then do \lineaction macro for all lines 
		\doloopfromto{-1}{-1}{\lineaction}%
		}%
	}%	
	}%
}%



% 4. \doloopif{value1}{[compare_operator]}{value2}{macro_for_doing} % [compareoperators] <, >, ==(eq), ~=(neq), >=, <=, in, until, while 
% actions for rows of open CSV file which are responded of condition  
\def\doloopif#1#2#3#4{%
    \opencsvfile%
    \bfilehook%
    \def\paroperator{#2}
    %  operator '==' is for strings comparing converted to 'eq' operator 
    \ctxlua{if '#2'=="==" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') 
     then context('\\def\\paroperator{eq}')  
     end;}
    %  operator '~=' is for strings comparing converted to 'neq' operator
    \ctxlua{if '#2'=="~=" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') 
     then context('\\def\\paroperator{neq}')  
     end;}
    % and now process actual operator 
    \processaction[\paroperator][%
     <=>{% {number1}{<}{number2} ... Less 
     \doloop{%
    	\edef\tempiv{#4}%
      \ctxlua{if #1<#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}%
      \nextrow%
   	  \ifEOF\exitloop\fi%
     }%
     },% end < ... Less
     >=>{% {number1}{>}{number2} ... Greater 
     \doloop{%
    	\edef\tempiv{#4}%
    	\ctxlua{if #1>#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}\nextrow\ifEOF\exitloop\fi%
     }%
     },% end > ... Greater
     ===>{% {number1}{==}{number2} ... Equal
     \doloop{%
       \edef\tempiv{#4}%
    	 \ctxlua{if #1==#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}\nextrow\ifEOF\exitloop\fi%
     }%
     },% end == ... Equal
     ~==>{% {number1}{~=}{number2} ... Not Equal
     \doloop{%
       \edef\tempiv{#4}%
    	 \ctxlua{if #1~=#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}\nextrow\ifEOF\exitloop\fi%
     }%
     },% end ~= ... Not Equal
     >==>{% {number1}{>=}{number2} ... GreaterOrEqual 
     \doloop{%
       \edef\tempiv{#4}%
    	 \ctxlua{if #1>=#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}\nextrow\ifEOF\exitloop\fi%
     }
     },% end >=  ... GreaterOrEqual
     <==>{% {number1}{<=}{number2} ... LessOrEqual 
     \doloop{%
       \edef\tempiv{#4}%
    	 \ctxlua{if #1<=#3 then context('\\blinehook \\tempiv\\elinehook') else thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1 end}\nextrow\ifEOF\exitloop\fi%
     }%
     },% end <= ... LessOrEqual 
     eq=>{%  command {string1}{==}{string2} is converted to command command {string1}{eq}{string2} ... string1 is equal string2 
     \doloop{%
 		\edef\tempi{#1}%
 		\edef\tempii{#3}%
 		\edef\tempiii{#4}%
       \ifx\tempi\tempii\blinehook \tempiii\elinehook\else\ctxlua{thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1;}\fi\nextrow\ifEOF\exitloop\fi%
     }%
     },%  end eq
     neq=>{%  command {string1}{~=}{string2} is converted to command command {string1}{neq}{string2} ... string1 is not equal string2  
     \doloop{%
  		\edef\tempi{#1}%
  		\edef\tempii{#3}%
  		\edef\tempiii{#4}%
      \ifx\tempi\tempii\ctxlua{thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1;}\else\blinehook \tempiii\elinehook\fi\nextrow\ifEOF\exitloop\fi%
     }%
     },% end neq
     in=>{% {substring}{in}{string} ... substring is contained inside string 
     \doloop{%
 		 \edef\tempi{#1}%
 		 \edef\tempii{#3}%
 		 \edef\tempiii{#4}%
       \doifincsnameelse{\tempi}{\tempii}{\blinehook \tempiii\elinehook}{\ctxlua{thirddata.scancsv.gNumLine=thirddata.scancsv.gNumLine-1;}}\nextrow\ifEOF\exitloop\fi%
     }
     }, % end in
     until=>{% {substring}{until}{string} ... % List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all record
      \doloop{
        \edef\tempi{#1}
        \edef\tempii{#3}
        \edef\tempiii{#4}
        % \ifx\tempi\tempii\exitloop\else\ifEOF\exitloop\else \blinehook \tempiii \elinehook\nextrow\fi\fi% recent version
        \ifx\tempi\tempii\exitloop\else\ifEOF\exitloop\else\blinehook \tempiii\elinehook\nextrow\fi\fi% new version
     }%
     }, % end until % the comma , is very important here!!!
     while=>{% {string}{while}{string} ... % List all, while the test is  met. When first which not met then just quit. If first is not met, will list no record
     \doloop{%
	   \edef\tempi{#1}
	   \edef\tempii{#3}
      \edef\tempiii{#4}
	   \ifx\tempi\tempii\blinehook \tempiii\elinehook\nextrow\else\exitloop\fi%
   	\ifEOF\exitloop\fi%
     }%
     }, % end while % the comma , is very important here!!!
     test=>{% {string}{while}{string} ... % List all, while the test is  met. When first which not met then just quit. If first is not met, will list no record
     \doloop{%
	   \edef\tempi{#1}
	   \edef\tempii{#3}
      \edef\tempiii{#4}
	   \ifx\tempi\tempii\blinehook \tempiii\elinehook\nextrow\else\exitloop\fi%
   	\ifEOF\exitloop\fi%
     }%
     }, % end test % the comma , is very important here!!!
    ]% end of \processaction
  \efilehook%
} % end of \doloopif


% 5. 
\def\filelineaction{\dotriplegroupempty\dofilelineaction}

\def\dofilelineaction#1#2#3{
	\doifelsenothing{#1}
	{\opencsvfile\doloopaction%0 parameter - open actual CSV file and do action
	}
	{\doifelsenothing{#2}
	{\opencsvfile{#1}\doloopaction%1 parameter - parameter = filename
	}
	{\doifelsenothing{#3}
	{\opencsvfile{#1}\doloopaction{\lineaction}{#2}%2 parameters, 1st parameter = filename, 2nd parameter = num of lines
	}
	{\opencsvfile{#1}\doloopaction{\lineaction}{#2}{#3}%3 parameters, 1st parameter = filename, 2nd parameter = from line, 3rd parameter = to line
	}}}
} 

\letvalue{doloopifnum}=\doloopif %\doloopifnum{value1}{[compare_operator]}{value2}{macro_for_doing} % [compareoperators] ==, ~=, >, <, >=, <=
\def\doloopuntil#1#2#3{\doloopif{#1}{until}{#2}{#3}}% \doloopuntil{\Trida}{3.A}{\tableaction}  % List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all records.
\def\doloopwhile#1#2#3{\doloopif{#1}{while}{#2}{#3}}% \doloopwhile{\Trida}{3.A}{\tableaction}  % List when the test is met, other just quit. 


 


]]

thirddata.scancsv.string2context(string2print)


-- Temporary ... for debugging




-- function thirddata.scancsv.getargvalue(arg)
-- if type(tonumber(arg))=='number' then
--   value=tex.round(arg)
-- else
--   if token.csname_name(token.create(arg)) == arg then
--      value=arg
--    else
--      value=arg
--   end
-- end
-- return value
-- end


-- function thirddata.scancsv.texmacroisdefined(macroname) -- check whether TeX is a defined macroname macro
-- -- function is used to test whether the user has defined the macro \lineaction. If not, it needs to define the default value
-- 	if token.csname_name(token.create(macroname)) == macroname then
-- 		return true
--  	else
-- 		return false
-- 	end
-- end


-- function thirddata.scancsv.resethooks() 
--  context([[\let\blinehook\relax
--    \let\elinehook\relax
--    \let\bfilehook\relax
--    \let\efilehook\relax
--    \let\bch\relax
--    \let\ech\relax]])
-- end

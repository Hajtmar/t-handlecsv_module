-- %D \module
-- %D   [     file=t-handlecsvcells.lua,
-- %D      version=2016.02.15,
-- %D        title=handlecsvcells module,
-- %D     subtitle=CSV file handling cells,
-- %D       author=Jaroslav Hajtmar,
-- %D         date=\currentdate,
-- %D    copyright=Jaroslav Hajtmar,handlecsvcells
-- %D        email=hajtmar@gyza.cz,
-- %D      license=GNU General Public License]
--
-- %C Copyright (C) 2011  Jaroslav Hajtmar
-- %C
-- %C This program is free software: you can redistribute it and/or modify
-- %C it under the terms of the GNU General Public License as published by
-- %C the Free Software Foundation, either version 3 of the License, or
-- %C (at your option) any later version.
-- %C
-- %C This program is distributed in the hope that it will be useful,
-- %C but WITHOUT ANY WARRANTY; without even the implied warranty of
-- %C MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- %C GNU General Public License for more details.
-- %C
-- %C You should have received a copy of the GNU General Public License
-- %C along with this program.  If not, see <http://www.gnu.org/licenses/>.


-- use a feature that is part of the /texmf-dist/tex/context/base/util-prs.lua

thirddata = thirddata or { }

thirddata.handlecsvcells = { -- Global variables
--	 gCSVSeparator
    gUserCSVSeparator=';',  -- the most widely used field separator in CSV tables
--  gCSVQuoter
    gUserCSVQuoter='"', --
--	 gCSVHeader
	 gUserCSVHeader=false, -- CSV file is by default considered as a CSV file without the header (in header are treated as column names of macros
--	 gUserUseHooks=false, -- In default setting is not use "hooks" when process CSV file
    gUserColumnNumbering='XLS',  -- Something other than the XLS or undefined variable value (eg commenting that line) to set the Roman numbering ...
    gNumLine=0, --
    gNumRows=0, -- global variable  - save number of rows of csv table
    gNumCols=0, -- global variable  - save number of columns of csv table
    gCurrentLinePointer=0, -- ie. CSV line number ie. number of the currently processed row
    gCurrentlyProcessedCSVFile=nil,
    gColumnNames={}, -- array with column names (readings from header of CSV file)
    gColNames={}, -- associative array with column names for indexing use f.e. gColNames['Firstname']=1, etc...
	 gTableRows={}, -- array of contents of cells of CSV table -> gTableRows[row][column]
	 gTableRowsIndex={}, -- array of flags of lines of CSV table -> gTableEmptyRowsIndex[i]= true or false
--  gMarkingEmptyLines
--    gUserMarkingEmptyLines=false, -- if true, then module mark empty rows in CSV file else module accept empty lines as regular lines
--	 gTableEmptyRows={}, -- array of indexes of empty lines of CSV table -> gTableEmptyRows[1]= 3 etc
--	 gTableNotEmptyRows={}, -- array of indexes of nonempty lines of CSV table -> gTableNotEmptyRows[1]= 3 etc
--	 gNumEmptyRows=0, -- number of empty rows
--	 gCSVHandleBuffer={}, -- temporary buffer
-- NEW variables
	 g_gTableRows={}, -- array of contents of cells of CSV table -> g_gTableRows[csvfilename][row][column]
     g_gNumLine={}, -- global variable -      g_gNumLine['csvfilename']=0
     g_gNumRows={}, -- global variable  - save number of rows of csv table: g_gNumRows['csvfilename']=0
     g_gNumCols={}, -- global variable  - save number of columns of csv table: g_gNumCols['csvfilename']=0
     g_gCurrentLinePointer={}, -- ie. CSV line number ie. number of the currently processed row: g_gCurrentLinePointer['csvfilename']=0
     g_gColumnNames={}, -- array with column names (readings from header of CSV file): g_gColumnNames['csvfilename']
     g_gColNames={}, -- associative array with column names for indexing use f.e. g_gColNames['csvfilename']['Firstname']=1, etc...
	 g_gTableRows={}, -- array of contents of cells of CSV table -> g_gTableRows['csvfilename'][row][column]
	 g_gTableRowsIndex={}, -- array of flags of lines of CSV table -> g_gTableEmptyRowsIndex['csvfilename'][i]= true or false

}

local setmacro = interfaces.setmacro or ""

-- Initialize global variables etc.

----  Default value is saved  in glob. variable gUseHooks (default is FALSE)
--if thirddata.handlecsvcells.gUseHooks == nil then thirddata.handlecsvcells.gUseHooks = thirddata.handlecsvcells.gUserUseHooks end
--  Default value is saved  in glob. variable gUserCSVHeader (default FALSE)
if thirddata.handlecsvcells.gCSVHeader == nil then thirddata.handlecsvcells.gCSVHeader = thirddata.handlecsvcells.gUserCSVHeader end
--  Default value is saved  in glob. variable gCSVSeparator (default COMMA)
if thirddata.handlecsvcells.gCSVSeparator == nil then thirddata.handlecsvcells.gCSVSeparator = thirddata.handlecsvcells.gUserCSVSeparator end
--  Default value is saved  in glob. variable gCSVSeparator (default ")
if thirddata.handlecsvcells.gCSVQuoter == nil then thirddata.handlecsvcells.gCSVQuoter = thirddata.handlecsvcells.gUserCSVQuoter end
----  Default value is saved  in glob. variable gMarkingEmptyLines (default is FALSE)
--if thirddata.handlecsvcells.gMarkingEmptyLines==nil then thirddata.handlecsvcells.gMarkingEmptyLines = thirddata.handlecsvcells.gUserMarkingEmptyLines end


-- Tools block: Contain auxiliary functions and tools


function thirddata.handlecsvcells.texmacroisdefined(macroname) -- check whether macroname macro is defined  in ConTeXt
-- function is used to test whether the user has defined the macro \macroname. If not, it needs to define any default value
  return token.get_cmdname(token.create(macroname)) ~= "undefined_cs"
end


-- tool function ParseCSVLine is defined for compatibility. Parsing string (or line).
function thirddata.handlecsvcells.ParseCSVLine(line,sep)
	local mycsvsplitter = utilities.parsers.rfc4180splitter{
	    separator = sep,
	    quote = '"',
	    strict=true, -- add 15.2.2016
	}
	local list = mycsvsplitter(line) inspect(list)
	return list[1]
end


function thirddata.handlecsvcells.tmn(s) -- TeX Macro Name. Name of TeX macro should not contain forbidden characters
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


function thirddata.handlecsvcells.xls2ar(colname) -- convert Excel column name (like A, B, ... AA, AB, ...) into serial number of column (A->1, B->2, ...)
   -- No for more than 702 columns (ie last column parametr for this function is ZZ)
   -- for example Excel 2003 can handle only up to the column IV!
	local colnumber=0
	local colname=colname:upper()
	for i=1, string.len(colname) do
	 local onechar = string.sub(colname,i,i)
	 colnumber=26*colnumber + (string.byte(onechar) - string.byte('A') + 1)
	end
 return colnumber
end



function thirddata.handlecsvcells.ar2xls(arnum) -- convert number to Excel name column
   -- For more than 703 columns (ie column A to ZZ) should be a function to modify
   -- Excel 2003 can handle only up to the column IV!
	local part=math.floor(arnum/26)
   local remainder = math.mod(arnum,26)
   part = part   - (math.mod(arnum,26)==0 and 1 or 0)
	remainder = remainder + (math.mod(arnum,26)==0 and 26 or 0)
   local ctl =''
	 if arnum < 703 then
			 if part > 0 then
			   ctl=string.char(64+part)
			 end
			 ctl = ctl .. string.char(64+remainder)
 	 else
    ctl = 'overZZ'
	 end
 return ctl
end


function thirddata.handlecsvcells.ar2colnum(arnum) -- According to the settings glob. variable returns the column designation of TeX macros
	-- generated TeX macros referring to values in columns are numbered a`la EXCEL ie cA, cB, ..., cAA, etc
	-- or a`la roman number ie. cI, cII, cIII, cIV, ..., cXVIII, etc
	-- if it is "romannumbers" setting, then columns wil numbered by Romna else ala Excel
	if string.lower(thirddata.handlecsvcells.gUserColumnNumbering) == 'xls' then
		return thirddata.handlecsvcells.ar2xls(arnum) --  a la EXCEL
	else
      return string.upper(converters.romannumerals(arnum)) -- a la big ROMAN - convert Arabic numbers to big Roman. Used for "numbering" column in the TeX macros
   end
end



-- Main functions and macros:

--function thirddata.handlecsvcells.hookson()
-- thirddata.handlecsvcells.gUseHooks=true
--end

--function thirddata.handlecsvcells.hooksoff()
-- thirddata.handlecsvcells.gUseHooks=false
--end

--function thirddata.handlecsvcells.setfiletoscan(filetoscan)
-- thirddata.handlecsvcells.gCurrentlyProcessedCSVFile=filetoscan
--end


function thirddata.handlecsvcells.setheader()
 thirddata.handlecsvcells.gCSVHeader=true
 context([[\global\issetheadertrue%]])
 context([[\global\notsetheaderfalse%]])
end


function thirddata.handlecsvcells.unsetheader()
 thirddata.handlecsvcells.gCSVHeader=false
 context([[\global\issetheaderfalse%]])
 context([[\global\notsetheadertrue%]])
end

function thirddata.handlecsvcells.setsep(sep)
  thirddata.handlecsvcells.gCSVSeparator=sep
end

function thirddata.handlecsvcells.unsetsep()
  thirddata.handlecsvcells.gCSVSeparator=thirddata.handlecsvcells.gUserCSVSeparator
end

--function thirddata.handlecsvcells.indexofnotemptyline(sernumline)
--	context(thirddata.handlecsvcells.gTableNotEmptyRows[sernumline])
--	return thirddata.handlecsvcells.gTableNotEmptyRows[sernumline]
--end

--function thirddata.handlecsvcells.indexofemptyline(sernumline)
--	context(thirddata.handlecsvcells.gTableEmptyRows[sernumline])
--	return thirddata.handlecsvcells.gTableEmptyRows[sernumline]
--end

--function thirddata.handlecsvcells.notmarkemptylines()
-- thirddata.handlecsvcells.gMarkingEmptyLines=false
--   for row=1,thirddata.handlecsvcells.gNumRows do
--		thirddata.handlecsvcells.gTableNotEmptyRows[row]=row
--     end
--	 context([[\global\emptylinefalse%]])
--	 context([[\global\notemptylinetrue%]])
--	 context([[\global\emptylinesmarkingfalse%]])
--	 context([[\global\emptylinesnotmarkingtrue%]])
--end

--function thirddata.handlecsvcells.markemptylines()
-- thirddata.handlecsvcells.gMarkingEmptyLines=true
-- 	 local counteremptylines=0
--	 local counternotemptylines=0
--	  for row=1,thirddata.handlecsvcells.gNumRows do
--			if thirddata.handlecsvcells.testemptyrow(row) then
--				counteremptylines=counteremptylines+1
--				thirddata.handlecsvcells.gTableEmptyRows[counteremptylines]=row
--			else
--				counternotemptylines=counternotemptylines+1
--				thirddata.handlecsvcells.gTableNotEmptyRows[counternotemptylines]=row
--			end
--	  end -- for
--	  context([[\global\emptylinesmarkingtrue%]])
--	  context([[\global\emptylinesnotmarkingfalse%]])
--end


--function thirddata.handlecsvcells.resetmarkemptylines()
---- do following lines only when file contain completely empty rows and is requiring testing empty lines
--	thirddata.handlecsvcells.gMarkingEmptyLines = thirddata.handlecsvcells.gUserMarkingEmptyLines
--	 if thirddata.handlecsvcells.gMarkingEmptyLines then
--	    thirddata.handlecsvcells.markemptylines()
--	 else thirddata.handlecsvcells.notmarkemptylines()
--	 end  -- if thirddata.handlecsvcells.gMarkingEmptyLines
--end

function thirddata.handlecsvcells.handlecsvcellsfilename(filename) -- In the absence of the file name to use the global variable
	 thirddata.handlecsvcells.gCurrentlyProcessedCSVFile = (filename ~= nil) and filename or thirddata.handlecsvcells.gCurrentlyProcessedCSVFile
	 thirddata.handlecsvcells.gCurrentlyProcessedCSVFile = (thirddata.handlecsvcells.gCurrentlyProcessedCSVFile == nil) and filename or thirddata.handlecsvcells.gCurrentlyProcessedCSVFile
   local filename = (filename ~= nil) and filename or thirddata.handlecsvcells.gCurrentlyProcessedCSVFile
   return filename
end


--function thirddata.handlecsvcells.testemptyrow(lineindex)
--local linecontent=""
--local isemptyline=false
--	for column=1,thirddata.handlecsvcells.gNumCols do
--		linecontent=linecontent..thirddata.handlecsvcells.gTableRows[lineindex][column]
--	end
--	if linecontent=="" or linecontent==nil then
--		isemptyline=true
--		thirddata.handlecsvcells.gNumEmptyRows=thirddata.handlecsvcells.gNumEmptyRows+1
--	end
--	thirddata.handlecsvcells.gTableRowsIndex[lineindex]=isemptyline
-- return isemptyline
--end


--function thirddata.handlecsvcells.emptylineevaluation(lineindex)
--	if thirddata.handlecsvcells.gTableRowsIndex[lineindex] then
--	  context([[\global\emptylinetrue%]])
--	  context([[\global\notemptylinefalse%]])
--	else
--	 context([[\global\emptylinefalse%]])
--	 context([[\global\notemptylinetrue%]])
--	end
--	return thirddata.handlecsvcells.gTableRowsIndex[lineindex]
--end


--function thirddata.handlecsvcells.hooksevaluation()
--	for i=1,#thirddata.handlecsvcells.gColumnNames do
--	 if not thirddata.handlecsvcells.texmacroisdefined('bch'..thirddata.handlecsvcells.gColumnNames[i]) then
--	  context.setgvalue('bch'..thirddata.handlecsvcells.gColumnNames[i],'\\relax')
--	 end
--	 if not thirddata.handlecsvcells.texmacroisdefined('ech'..thirddata.handlecsvcells.gColumnNames[i]) then
--	  context.setgvalue('ech'..thirddata.handlecsvcells.gColumnNames[i],'\\relax')
--	 end
--	end
--end


function thirddata.handlecsvcells.opencsvfile(filetoscan) -- Open CSV tabule, inicialize variables
	-- open the table and load it into the global variable thirddata.handlecsvcells.gTableRows
	-- if the option thirddata.handlecsvcells.gCSVHeader==true is enabled, then into glob variable thirddata.handlecsvcells.gColumnNames
	-- sets the column names from the title, if not then sets XLS notation, ie. cA, cB, cC, ...
	-- into global variables thirddata.handlecsvcells.gNumRows and  thirddata.handlecsvcells.gNumCols it saves the number of rows and columns of the table
	-- if the file header and the header line does not count the number of rows in the table
	-- Additionally, they can defined ConTeXt macros  \csvfilename, \numrows a \numcols
	 local inpcsvfile=thirddata.handlecsvcells.handlecsvcellsfilename(filetoscan)
	 local currentlyprocessedcsvfile = io.loaddata(inpcsvfile)
	 local mycsvsplitter = utilities.parsers.rfc4180splitter{
    	separator = thirddata.handlecsvcells.gCSVSeparator,
    	quote = thirddata.handlecsvcells.gCSVQuoter,
    	strict = true,
		}
	 thirddata.handlecsvcells.g_gColNames[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gNumRows[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gNumCols[inpcsvfile]={}

	if thirddata.handlecsvcells.gCSVHeader then
	 thirddata.handlecsvcells.g_gTableRows[inpcsvfile], thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile,true)
	 inspect(thirddata.handlecsvcells.g_gTableRows[inpcsvfile]) -- read all rows
	 inspect(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]) -- read header of CSV file

--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- read number of columns from first line
--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]  -- when is header, then in this variable are names of columns

	else -- if thirddata.handlecsvcells.gCSVHeader
	  thirddata.handlecsvcells.g_gTableRows[inpcsvfile], thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile)
	  inspect(thirddata.handlecsvcells.g_gTableRows[inpcsvfile]) -- read all rows
	  thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]={} -- No header
	  -- ad now set column names for withoutheader situation:
--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- numbers of columns

		for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do -- for all columns
--		tex.sprint(i)
--	 	tex.sprint('+++, ')
--		tex.sprint(tostring(thirddata.handlecsvcells.ar2xls(i)))
		 -- OK, but not used: thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]=thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1][i])
		 thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		end
	end -- if thirddata.handlecsvcells.gCSVHeader


	 	for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do -- for all columns, generate column names:
--	 	tex.sprint(i)
--	 	tex.sprint(' - ')
--	 	tex.sprint(tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])), ', ')
--		tex.sprint(tostring(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]),', ')
--		tex.sprint(tostring(thirddata.handlecsvcells.ar2xls(i)),', ')
--		tex.sprint(tostring('c'..thirddata.handlecsvcells.ar2xls(i)),', ')
-- table.insert(hirddata.handlecsvcells.g_gColNames[inpcsvfile],
	 	    thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]))] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'A', 'B', etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring('c'..thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
		end

		local j=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1]

		for i=1, #thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
		j=j+1
--		tex.sprint('i: ',i,'- j:', j,'***')
		thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring('c'..thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		end


		if thirddata.handlecsvcells.gCSVHeader then
			for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
			j=j+1
			thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
			end

			for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
			j=j+1
			thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])) -- maybe TeX incorect names of columns
			end
		end

--		for i=1, #thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] do
--		tex.sprint('x ', thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i],' x')
--		end

--		for k,v in pairs(thirddata.handlecsvcells.g_gColNames[inpcsvfile]) do print(k,v) end

--		for i=1, #thirddata.handlecsvcells.g_gColNames do
--		tex.sprint('y ', thirddata.handlecsvcells.g_gColNames[inpcsvfile][i],' y')
--		end


 	 thirddata.handlecsvcells.g_gNumRows[inpcsvfile]=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile] -- Getting number of rows
  	 thirddata.handlecsvcells.g_gNumCols[inpcsvfile]=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- Getting number of columns
    context([[\global\EOFfalse%]])
  	 context([[\global\notEOFtrue%]])
  	 thirddata.handlecsvcells.resetlinepointer()	-- set pointer to begin table (first row)
--	 thirddata.handlecsvcells.setnumline(1)
--  	 thirddata.handlecsvcells.resetmarkemptylines()
--  	 if thirddata.handlecsvcells.gUseHooks then  thirddata.handlecsvcells.hooksevaluation() end
end -- of thirddata.handlecsvcells.opencsvfile(file)



function thirddata.handlecsvcells.xopencsvfile(filetoscan) -- Open CSV tabule, inicialize variables
	-- open the table and load it into the global variable thirddata.handlecsvcells.gTableRows
	-- if the option thirddata.handlecsvcells.gCSVHeader==true is enabled, then into glob variable thirddata.handlecsvcells.gColumnNames
	-- sets the column names from the title, if not then sets XLS notation, ie. cA, cB, cC, ...
	-- into global variables thirddata.handlecsvcells.gNumRows and  thirddata.handlecsvcells.gNumCols it saves the number of rows and columns of the table
	-- if the file header and the header line does not count the number of rows in the table
	-- Additionally, they can defined ConTeXt macros  \csvfilename, \numrows a \numcols
	 local inpcsvfile=thirddata.handlecsvcells.handlecsvcellsfilename(filetoscan)
	 local currentlyprocessedcsvfile = io.loaddata(inpcsvfile)
	 local mycsvsplitter = utilities.parsers.rfc4180splitter{
    	separator = thirddata.handlecsvcells.gCSVSeparator,
    	quote = thirddata.handlecsvcells.gCSVQuoter,
    	strict = true,
		}
	 thirddata.handlecsvcells.g_gColNames[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gNumRows[inpcsvfile]={}
	 thirddata.handlecsvcells.g_gNumCols[inpcsvfile]={}
	-- for current opened file:
	 thirddata.handlecsvcells.gColNames={}
	 thirddata.handlecsvcells.gColumnNames={}
	 thirddata.handlecsvcells.gNumRows={}
	 thirddata.handlecsvcells.gNumCols={}

	if thirddata.handlecsvcells.gCSVHeader then
	 thirddata.handlecsvcells.g_gTableRows[inpcsvfile], thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile,true)
	 inspect(thirddata.handlecsvcells.g_gTableRows[inpcsvfile]) -- read all rows
	 inspect(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]) -- read header of CSV file
	-- for current opened file:
	 thirddata.handlecsvcells.gTableRows, thirddata.handlecsvcells.gColumnNames = mycsvsplitter(currentlyprocessedcsvfile,true)
	 inspect(thirddata.handlecsvcells.gTableRows) -- read all rows
	 inspect(thirddata.handlecsvcells.gColumnNames) -- read header of CSV file

--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- read number of columns from first line
--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]  -- when is header, then in this variable are names of columns

	else -- if thirddata.handlecsvcells.gCSVHeader
	  thirddata.handlecsvcells.g_gTableRows[inpcsvfile], thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile)
	  inspect(thirddata.handlecsvcells.g_gTableRows[inpcsvfile]) -- read all rows
	  thirddata.handlecsvcells.g_gColumnNames[inpcsvfile]={} -- No header
	-- for current opened file:
	  thirddata.handlecsvcells.gTableRows, thirddata.handlecsvcells.gColumnNames = mycsvsplitter(currentlyprocessedcsvfile)
	  inspect(thirddata.handlecsvcells.gTableRows) -- read all rows
	  thirddata.handlecsvcells.gColumnNames={} -- No header

	  -- ad now set column names for withoutheader situation:
--	  local numcolsofinpcsvfile=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- numbers of columns

		for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do -- for all columns
--		tex.sprint(i)
--	 	tex.sprint('+++, ')
--		tex.sprint(tostring(thirddata.handlecsvcells.ar2xls(i)))
		 -- OK, but not used: thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]=thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1][i])
		 thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		 thirddata.handlecsvcells.gColumnNames[i]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		end
	end -- if thirddata.handlecsvcells.gCSVHeader


	 	for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do -- for all columns, generate column names:
--	 	tex.sprint(i)
--	 	tex.sprint(' - ')
--	 	tex.sprint(tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])), ', ')
--		tex.sprint(tostring(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]),', ')
--		tex.sprint(tostring(thirddata.handlecsvcells.ar2xls(i)),', ')
--		tex.sprint(tostring('c'..thirddata.handlecsvcells.ar2xls(i)),', ')
-- table.insert(hirddata.handlecsvcells.g_gColNames[inpcsvfile],
	 	    thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]))] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring(thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'A', 'B', etc...)
			thirddata.handlecsvcells.g_gColNames[inpcsvfile][tostring('c'..thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
			-- for current opened file:
	 	    thirddata.handlecsvcells.gColNames[tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i]))] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.gColNames[tostring(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsvcells.gColNames[tostring(thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'A', 'B', etc...)
			thirddata.handlecsvcells.gColNames[tostring('c'..thirddata.handlecsvcells.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)

		end

		local j=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1]

		for i=1, #thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
		j=j+1
--		tex.sprint('i: ',i,'- j:', j,'***')
		thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring('c'..thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		-- for current opened file:
		thirddata.handlecsvcells.gColumnNames[j]=tostring('c'..thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		end


		if thirddata.handlecsvcells.gCSVHeader then
			for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
			j=j+1
			thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
			-- for current opened file:
			thirddata.handlecsvcells.gColumnNames[j]=tostring(thirddata.handlecsvcells.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
			end

			for i=1,#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] do
			j=j+1
			thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])) -- maybe TeX incorect names of columns
			-- for current opened file:
			thirddata.handlecsvcells.gColumnNames[j]=tostring(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i])) -- maybe TeX incorect names of columns
			end
		end

--		for i=1, #thirddata.handlecsvcells.g_gColumnNames[inpcsvfile] do
--		tex.sprint('x ', thirddata.handlecsvcells.g_gColumnNames[inpcsvfile][i],' x')
--		end

--		for k,v in pairs(thirddata.handlecsvcells.g_gColNames[inpcsvfile]) do print(k,v) end

--		for i=1, #thirddata.handlecsvcells.g_gColNames do
--		tex.sprint('y ', thirddata.handlecsvcells.g_gColNames[inpcsvfile][i],' y')
--		end


 	 thirddata.handlecsvcells.g_gNumRows[inpcsvfile]=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile] -- Getting number of rows
  	 thirddata.handlecsvcells.g_gNumCols[inpcsvfile]=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- Getting number of columns
	-- for current opened file:
 	 thirddata.handlecsvcells.gNumRows=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile] -- Getting number of rows
  	 thirddata.handlecsvcells.gNumCols=#thirddata.handlecsvcells.g_gTableRows[inpcsvfile][1] -- Getting number of columns
    context([[\global\EOFfalse%]])
  	 context([[\global\notEOFtrue%]])
  	 thirddata.handlecsvcells.resetlinepointer()	-- set pointer to begin table (first row)
--	 thirddata.handlecsvcells.setnumline(1)
--  	 thirddata.handlecsvcells.resetmarkemptylines()
--  	 if thirddata.handlecsvcells.gUseHooks then  thirddata.handlecsvcells.hooksevaluation() end
end -- of thirddata.handlecsvcells.opencsvfile(file)



-- Main function. Read data, parse them etc.
function thirddata.handlecsvcells.readline(numberofline) --
	local numberofline=numberofline
	local returnpar=false
	 if type(numberofline)~= 'number' then
	 	if numberofline==nil then
	 	 numberofline=thirddata.handlecsvcells.gCurrentLinePointer
	 	 returnpar=true
	 	else numberofline = 0
		end -- if numberofline==nil
	 end --  if type(numberofline)
	 if (numberofline > 0 and numberofline <=thirddata.handlecsvcells.gNumRows) then
	 	 thirddata.handlecsvcells.gNumLine = thirddata.handlecsvcells.gNumLine + 1
	  	 thirddata.handlecsvcells.gCurrentLinePointer=numberofline
		 returnpar=true
		 thirddata.handlecsvcells.assigncontents(thirddata.handlecsvcells.gTableRows[numberofline])
		 context([[\global\EOFfalse\global\notEOFtrue%]])
	 else
		 thirddata.handlecsvcells.assigncontents('nil_line')
			if numberofline > thirddata.handlecsvcells.gNumRows then
			   context([[\global\EOFtrue\global\notEOFfalse%]])
	   	end
	 end  -- if (numberofline > 0
--	 	thirddata.handlecsvcells.emptylineevaluation(numberofline)
 return returnpar -- return true if numberofline is regular line, else return false
end -- function thirddata.handlecsvcells.readline(numberofline) --



function thirddata.handlecsvcells.createxlscommand(xlsname)
local cxlsname=tostring('col'..xlsname)
local docxlsname=tostring('docol'..xlsname)
local xlsname=tostring(''..xlsname)
		interfaces.definecommand (docxlsname, {
		    arguments = { { "option", "string" }  },
		    macro = function (opt_1)
		       if #opt_1>0 then
	context(thirddata.handlecsvcells.getcellcontent(xlsname,tonumber(opt_1)))
				 else
	context(thirddata.handlecsvcells.getcellcontent(xlsname,thirddata.handlecsvcells.gCurrentLinePointer))
				 end
		    end
			})
		interfaces.definecommand(cxlsname, {
		    macro = function ()
		      context.dosingleempty()
		      context[docxlsname]()
		    end
			})
end



-- after read of line this function put content of columns into specific TeX macros...
function thirddata.handlecsvcells.assigncontents(line) -- put data into columns macros
 	for i=1,	thirddata.handlecsvcells.gNumCols do
 		content='nil' -- 1.10.2015
 		if line ~= 'nil_line' then content = line[i] end
		local macroname=thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.gColumnNames[i])
		local purexlsname=thirddata.handlecsvcells.ar2colnum(i)
		local xlsname='c'..purexlsname
		local hookxlsname='h'..xlsname
		local macroname=thirddata.handlecsvcells.tmn(macroname)
		local hookmacroname='h'..macroname
--		if content == ' ' then tex.print('space') end
--		if content == '' then tex.print('empty') content=[[\empty]] end
 	   context.setgvalue(xlsname, content) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically
 	   -- was context.setgvalue(macroname,'\\'..xlsname) -- ie  for example \let\Name\cA
		context.setgvalue(macroname,content) -- defining automatic TeX macros  \Name, \Date, etc. (names gets from header), containing the contents of the line. Macros with names of the headers are updated automatically
	-- experimental version in next two lines:
	-- this define variants of macros \colA, \colA[8], ... and \colFirstname, \colFirstname[11] etc.
		thirddata.handlecsvcells.createxlscommand(''..purexlsname) -- create macros \colA, \colB, etc. and their variants \colA[row], ...
		context.setgvalue('col'..macroname,'\\col'..purexlsname) -- and create fullname macros \colFirstname, \colFirstname[5], etc...
		-- and now create hooks macros:
	  	if thirddata.handlecsvcells.gUseHooks then
	  	 	 context.setgvalue(hookxlsname,'\\bch\\bch'..xlsname..'\\'..xlsname..'\\ech'..xlsname..'\\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	       context.setgvalue(hookmacroname,'\\bch\\bch'..macroname..'\\'..xlsname..'\\ech'..macroname..'\\ech ') -- defining automatic TeX macros \hName, \hDate, etc. (names gets from header), containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	  	end
	end -- for i=1,
end -- function thirddata.handlecsvcells.assigncontents(line) -- put data into columns macros


-- Read data from specific cell of the csv table
function thirddata.handlecsvcells.getcellcontent(csvfile,column,row)
	-- local returnparametr='nil'  -- 1.10.2015
	local returnparametr=''  -- 9.1.2016
	local column=column
	local row=row
	if type(column)=='string' then
		local testcolumn=thirddata.handlecsvcells.g_gColNames[csvfile][column]
--		tex.sprint(testcolumn)
--		tex.sprint('*****')
		if testcolumn==nil then
		  column=thirddata.handlecsvcells.xls2ar(column)
--		  		tex.sprint(column)
--		  		tex.sprint('*****')
		else
		   column=testcolumn
		end
	end
	if type(column)=='number' and type(row)=='number' then
		if row>0 and row <=thirddata.handlecsvcells.g_gNumRows[csvfile] and column>0 and column<=thirddata.handlecsvcells.g_gNumCols[csvfile] then
	 		returnparametr=thirddata.handlecsvcells.g_gTableRows[csvfile][row][column]
		elseif row==0 then
	 		returnparametr=thirddata.handlecsvcells.g_gColumnNames[csvfile][column]
	 	end
	end

 return returnparametr
end


-- Move line pointer to next line.
function thirddata.handlecsvcells.nextline()
  if thirddata.handlecsvcells.gCurrentLinePointer > thirddata.handlecsvcells.gNumRows then
  	  thirddata.handlecsvcells.gCurrentLinePointer=thirddata.handlecsvcells.gNumRows
     context([[\global\EOFtrue%]])
     context([[\global\notEOFfalse%]])
  end
  thirddata.handlecsvcells.gCurrentLinePointer=thirddata.handlecsvcells.gCurrentLinePointer+1
end

function thirddata.handlecsvcells.nextlinex()
  if thirddata.handlecsvcells.gCurrentLinePointer > thirddata.handlecsvcells.gNumRows then
  	  thirddata.handlecsvcells.gCurrentLinePointer=thirddata.handlecsvcells.gNumRows
     context([[\global\EOFtrue%]])
     context([[\global\notEOFfalse%]])
  else
  	  thirddata.handlecsvcells.gCurrentLinePointer=thirddata.handlecsvcells.gCurrentLinePointer+1
  	  context([[\global\EOFfalse%]])
     context([[\global\notEOFtrue%]])
  end
end


function thirddata.handlecsvcells.setlinepointer(numberofline)
  thirddata.handlecsvcells.gCurrentLinePointer=numberofline
  thirddata.handlecsvcells.readline(numberofline)
end



-- Take pointer to first row of table
function thirddata.handlecsvcells.resetlinepointer()
  thirddata.handlecsvcells.setlinepointer(1)
end


function thirddata.handlecsvcells.linepointer()
  context(thirddata.handlecsvcells.gCurrentLinePointer)
end


function thirddata.handlecsvcells.setnumline(numline)
  thirddata.handlecsvcells.gNumLine=numline
end

function thirddata.handlecsvcells.resetnumline()
  thirddata.handlecsvcells.setnumline(0)
end

function thirddata.handlecsvcells.addtonumline(numline)
  thirddata.handlecsvcells.gNumLine=thirddata.handlecsvcells.gNumLine+numline
end

function thirddata.handlecsvcells.numline()
  context(thirddata.handlecsvcells.gNumLine)
end


-- Move numline pointer to next number.
function thirddata.handlecsvcells.nextnumline()
  thirddata.handlecsvcells.gNumLine=thirddata.handlecsvcells.gNumLine+1
end


function thirddata.handlecsvcells.xnumrows(csvfile)
--	local csvfile=thirddata.handlecsvcells.handlecsvcellsfilename(csvfile)
 if csvfile == '' then
  	context(thirddata.handlecsvcells.gNumRows)
  else
    context(thirddata.handlecsvcells.g_gNumRows[csvfile])
 end
end

function thirddata.handlecsvcells.numrows(csvfile)
  context(thirddata.handlecsvcells.g_gNumRows[csvfile])
end


--function thirddata.handlecsvcells.numrows(csvfile)
--  context(thirddata.handlecsvcells.g_gNumRows[csvfile])
--end


function thirddata.handlecsvcells.numemptyrows()
  context(thirddata.handlecsvcells.gNumEmptyRows)
end


function thirddata.handlecsvcells.numnotemptyrows()
  context(thirddata.handlecsvcells.gNumRows-thirddata.handlecsvcells.gNumEmptyRows)
end


function thirddata.handlecsvcells.numcols(csvfile)
  context(thirddata.handlecsvcells.g_gNumCols[csvfile])
end



-- initialize ConTeXt hooks
function thirddata.handlecsvcells.resethooks()
 context([[%
 	\letvalue{blinehook}=\relax%
   \letvalue{elinehook}=\relax%
   \letvalue{bfilehook}=\relax%
   \letvalue{efilehook}=\relax%
   \letvalue{bch}=\relax%
   \letvalue{ech}=\relax%
	]])
end



-- for safety writen
function thirddata.handlecsvcells.string2context(str2ctx)
  local s=str2ctx
  s=string.gsub(s, "%%(.-)\n", "\n")  -- remove TeX comments from string. From % character to the end of line
  -- s=string.gsub(s, '\n', "")
  context(s)
  -- texsprint(s) -- for debugging ...
end




-- ConTeXt source:
local string2print=[[%
% Auxiliary macros of Mr. Olsak for defining macros with optional parameters
\def\isnextcharA{\the\toks\ifx\tmp\next0\else1\fi\space}
\long\def\isnextchar#1#2#3{\begingroup\toks0={\endgroup#2}\toks1={\endgroup#3}%
   \let\tmp=#1\futurelet\next\isnextcharA
}

\def\sdef#1{\expandafter\def\csname#1\endcsname}

\def\optdef#1[#2]{%
   \def#1{\def\opt{#2}\isnextchar[{\csname oA:\string#1\endcsname}{\csname oB:\string#1\endcsname}}%
   \sdef{oA:\string#1}[##1]{\def\opt{##1}\csname oB:\string#1\nospaceafter\endcsname}%
   \sdef{oB:\string#1\nospaceafter}%
}
\def\nospaceafter#1{\expandafter#1\romannumeral-`\.}


% library newifs for testing during processing CSV table
\newif\ifissetheader%
\newif\ifnotsetheader%
\newif\ifEOF%
\newif\ifnotEOF%
\newif\ifemptyline%
\newif\ifnotemptyline%
\newif\ifemptylinesmarking% setting by macros \markemptylines and \notmarkemptylines
\newif\ifemptylinesnotmarking% setting by \markemptylines and \notmarkemptylines


% Macros defining above in source text:
\let\lineaction\empty% set user define macro into default value
%\def\resethooks{\ctxlua{context(thirddata.handlecsvcells.resethooks())}}
%\resethooks % -- DO IT NOW !!!
%\def\hookson{\ctxlua{thirddata.handlecsvcells.hookson()}}
%\let\usehooks\hookson % -- synonym only
%\def\hooksoff{\ctxlua{thirddata.handlecsvcells.hooksoff()}}
\def\setheader{\ctxlua{thirddata.handlecsvcells.setheader()}}
\def\unsetheader{\ctxlua{thirddata.handlecsvcells.unsetheader()}}
\let\resetheader\unsetheader % -- for compatibility
\def\setsep#1{\ctxlua{thirddata.handlecsvcells.setsep('#1')}}
\def\unsetsep{\ctxlua{thirddata.handlecsvcells.unsetsep()}}
\let\resetsep\unsetsep % -- for compatibility
%\def\setfiletoscan#1{\ctxlua{thirddata.handlecsvcells.setfiletoscan('#1');thirddata.handlecsvcells.opencsvfile()}}

% ctnum - convert to number: if parametr is not number, then return -1
\def\ctnum#1{\ctxlua{if type(tonumber('#1'))=='number' then context('#1') else context(-1) end}}%




\def\xnumrows{%
    \dosingleempty\donumrows%
}%

\def\donumrows[#1]{%
	\dosinglegroupempty\dodonumrows%
}%

\def\dodonumrows#1{%
    \iffirstargument%
    \ctxlua{context(thirddata.handlecsvcells.numrows('#1'))}%
   \else%
	\ctxlua{context(thirddata.handlecsvcells.gNumRows)}%
   \fi%
}%

%\def\numrows[#1]{\ctxlua{context(thirddata.handlecsvcells.numrows('#1'))}}

\def\numrows{\ctxlua{context(thirddata.handlecsvcells.numrows())}}
\def\numrowsof[#1]{\ctxlua{context(thirddata.handlecsvcells.numrows('#1'))}}


%\optdef\numrows[\ctxlua{context(thirddata.handlecsvcells.numrows(''))}]{\ctxlua{if type(tonumber('\opt'))=='number' then context(\ctxlua{context(thirddata.handlecsvcells.numrows(''))}) else context(thirddata.handlecsvcells.numrows('\opt')) end}}%

%\def\numrows{\futurelet\commandtoken\donumrows}
%\def\donumrows{\ifx\commandtoken[\expandafter\numrowspar\else\numrowsnopar\fi}
%\def\numrowspar[#1]{\ctxlua{context(thirddata.handlecsvcells.numrows('#1'))}}
%\def\numrowsnopar{\ctxlua{context(thirddata.handlecsvcells.numrows(''))}}



%\def\numemptyrows{\ctxlua{context(thirddata.handlecsvcells.numemptyrows())}}
%\def\numnotemptyrows{\ctxlua{context(thirddata.handlecsvcells.numnotemptyrows())}}

\def\numcols{%
    \dosingleempty\donumcols%
}%

\def\donumcols[#1]{%
	\dosinglegroupempty\dodonumcols%
}%

\def\dodonumcols#1{%
    \iffirstargument%
    \ctxlua{context(thirddata.handlecsvcells.numcols('#1'))}%
   \else%
	xxx %\ctxlua{context(thirddata.handlecsvcells.numcols('#1'))}%
   \fi%
}%


%\def\numcols[#1]{\ctxlua{context(thirddata.handlecsvcells.numcols('#1'))}}
\def\csvfilename{\ctxlua{context(thirddata.handlecsvcells.handlecsvcellsfilename())}}

% usefull tool macros :

% Pass the contents of the macro into parameter
\def\thenumexpr#1{\the\numexpr(#1+0)}
% Add content (#2) into content of macro #1
\long\def\addto#1#2{\expandafter\def\expandafter#1\expandafter{#1#2}}
% Expanded version of previous macro
\long\def\eaddto#1#2{\edef#1{#1#2}}



% Get content of specific cell of CSV table. Calling: \csvcell[csv filename,column number,row number] OR \csvcell['ColumnName',row number]
\def\getcsvcell[#1](#2,#3){\ctxlua{context(thirddata.handlecsvcells.getcellcontent('#1',#2,#3))}}%
%%%%%\def\getcsvcell[#1,#2]{\if!#2!\ctxlua{context(thirddata.handlecsvcells.getcellcontent(#1,thirddata.handlecsvcells.gCurrentLinePointer))}\else\ctxlua{context(thirddata.handlecsvcells.getcellcontent(#1,#2))}\fi}%

% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number or row number getting from macro] OR \csvcell['ColumnName',row number or row number getting from macro]
\def\csvcell[#1,#2]{\getcsvcell[#1,\the\numexpr(#2+0)]}%
%\def\csvcell\getcsvcell

% Get content of specific cell of current line of CSV table. Calling: \currentcell{column number} OR \currentcell{'ColumnName'}
\def\currentcsvcell#1{\getcsvcell[#1,\thenumexpr{\linepointer}]}%
\let\currcell\currentcsvcell

% Get content of specific cell of next line of CSV table. Calling: \nextcell{column number} OR \nextcell{'ColumnName'}
\def\nextcsvcell#1{\ifnum\linepointer<\numrows{\getcsvcell[#1,\thenumexpr{\linepointer+1}]}\fi}%
\let\nextcell\nextcsvcell

% Get content of specific cell of previous line of CSV table. Calling: \previouscell{column number} OR \previouscell{'ColumnName'}
\def\previouscsvcell#1{\ifnum\linepointer>1{\getcsvcell[#1,\thenumexpr{\linepointer-1}]}\fi}%
\let\prevcell\previouscsvcell


% Get column name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\colname[#1]{\ctxlua{context(thirddata.handlecsvcells.gColumnNames[#1])}}%

% Get index (ie serrial number) of strings columns names (own name or XLS name)
\def\indexcolname[#1]{\ctxlua{context(thirddata.handlecsvcells.gColNames[#1])}}%

% Get (alternative) XLS column name (of n-th column)
\def\xlscolname[#1]{\ctxlua{context(thirddata.handlecsvcells.ar2colnum(#1))}}%

% Get (alternative) XLS column name (of n-th column)
\def\cxlscolname[#1]{\ctxlua{context('c'..thirddata.handlecsvcells.ar2colnum(#1))}}%

% Get column TeX name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\texcolname[#1]{\ctxlua{context(thirddata.handlecsvcells.tmn(thirddata.handlecsvcells.gColumnNames[#1]))}}%


% Get content of n-th column of current row
\def\columncontent[#1]{%
\getcsvcell[#1,\linepointer]%
}%


% Get number from XLS column name (ie n-th column)
\def\numberxlscolname[#1]{\ctxlua{context(thirddata.handlecsvcells.xls2ar(#1))}}%


\def\resetlinepointer{\ctxlua{context(thirddata.handlecsvcells.resetlinepointer())}}
\let\resetlineno\resetlinepointer
\let\resetsernumline\resetlinepointer
\def\setnumline#1{\ctxlua{thirddata.handlecsvcells.setnumline(#1)}}
\def\resetnumline{\ctxlua{context(thirddata.handlecsvcells.resetnumline())}}
\def\linepointer{\ctxlua{context(thirddata.handlecsvcells.linepointer())}}
\let\lineno\linepointer
\let\sernumline\linepointer
\def\numline{\ctxlua{context(thirddata.handlecsvcells.numline())}}
\def\addtonumline#1{\ctxlua{thirddata.handlecsvcells.addtonumline(#1)}}
%\def\setlinepointer#1{\ctxlua{thirddata.handlecsvcells.setlinepointer(#1);thirddata.handlecsvcells.readline(#1)}}
\def\setlinepointer#1{\ctxlua{thirddata.handlecsvcells.setlinepointer(#1)}}
\def\indexofnotemptyline#1{\ctxlua{thirddata.handlecsvcells.indexofnotemptyline(#1)}}
\def\indexofemptyline#1{\ctxlua{thirddata.handlecsvcells.indexofemptyline(#1)}}
\def\notmarkemptylines{\ctxlua{thirddata.handlecsvcells.notmarkemptylines()}}
\def\markemptylines{\ctxlua{thirddata.handlecsvcells.markemptylines()}}
\def\resetmarkemptylines{\ctxlua{thirddata.handlecsvcells.resetmarkemptylines()}}%
\def\nextline{\ctxlua{context(thirddata.handlecsvcells.nextline())}} % -- macro for skip to next line. \nextline no read data from current line unlike \nextrow macro.
\def\nextnumline{\ctxlua{context(thirddata.handlecsvcells.nextnumline())}} % -- macro for add  numline counter.
%\def\nextrow{\readline\nextline} % -- For compatibility
\def\nextrow{\nextline\readline} % -- For compatibility (changed 2015-09-22)
\def\exitlooptest{\ifEOF\exitloop\else\nextrow\fi}




% MAIN CONTEXT MACRO DEFINITIONS

% Open CSV file. Syntax: \opencsvfile or \opencsvfile{filename}.
\def\opencsvfile{%
    \dosingleempty\doopencsvfile%
}%

\def\doopencsvfile[#1]{%
	\dosinglegroupempty\dodoopencsvfile%
}%

\def\dodoopencsvfile#1{%
    \iffirstargument%
    \ctxlua{thirddata.handlecsvcells.opencsvfile("#1")}%
   \else%
	 \ctxlua{thirddata.handlecsvcells.opencsvfile()}%
   \fi%
}%


% Read data from n-th line of CSV table. Calling without parameter read current line (pointered by global variable)
\def\readline{\dosingleempty\doreadline}%

\def\doreadline[#1]{\dosinglegroupempty\dodoreadline}%
% They must remain in such a compact form, otherwise it returns unwanted gaps !!!!
\def\dodoreadline#1{\iffirstargument\ctxlua{thirddata.handlecsvcells.readline(#1)}\else\ctxlua{thirddata.handlecsvcells.readline(thirddata.handlecsvcells.gCurrentLinePointer)}\fi}%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Complete listing macros and commands that can be used (to keep track of all defined macros):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% \ifissetheader, \ifnotsetheader
% \ifEOF, \ifnotEOF
% \ifemptyline, \ifnotemptyline
% \ifemptylinesmarking, \ifemptylinesnotmarking (they can be set by macros \markemptylines, \notmarkemptylines and \resetmarkemptylines)
% \hookson, \hooksoff
% \resethooks
% user defined hooks macros: \bfilehook, \efilehook, \blinehook, \elinehook,
% \setheader, \unsetheader, (\resetheader - compatibility synonym)
% \setsep{<columnseparator>}, \unsetsep, (\resetsep - compatibility synonym)
% \setfiletoscan{<filetoprocess>}
% \numrows, \numemptyrows, \numnotemptyrows
% \numcols
% \csvfilename
% \thenumexp{<expression>}
% \addto\anymacro{<addingnonexpandedcontent>}, \eaddto\anymacro{<addingexpandedcontent>}
% \getcsvcell[<columnnumber or columnname>,<rownumber>], \csvcell[<columnnumber or columnname>,<rownumber>]
% \currentcell{<columnnumber or columnname}, \nextcell{<columnnumber or columnname}, \previouscell{<columnnumber or columnname}
% and their synonyms \currcell{}, \nextcell{}, \prevcell{}
% \colname[numberofcolumn], \xlscolname[<numberofcolumn>], \cxlscolname[<numberofcolumn>], \texcolname[<numberofcolumn>]
% \indexcolname[<'columnname' or 'xlsname'>]
% \columncontent[<numberofcolumn> or <'columnname'> or <'xlsname'>]
% \numberxlscolname[<'xlsname'>]
% \linepointer, (\lineno, \sernumline are synonyms), \resetlinepointer, (\resetlineno, \resetsernumline are synonyms), \setlinepointer{<numberofline>}
% \numline, \setnumline{<numberofline>}, \resetnumline
% \addtonumline{<number>}
% \indexofnotemptyline{}, \indexofemptyline{}
% \nextline
% \nextnumline
% \nextrow
% \exitlooptest
% \opencsvfile, \opencsvfile{<filename>}
% \readline, \readline{<numberofline>}
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]

-- write definitions into ConTeXt:
thirddata.handlecsvcells.string2context(string2print)


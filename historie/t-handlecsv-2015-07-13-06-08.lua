-- %D \module
-- %D   [     file=t-handlecsv.lua,
-- %D      version=2015.06.14,
-- %D        title=\CONTEXT\ User Module,
-- %D     subtitle=CSV file handling,
-- %D       author=Jaroslav Hajtmar,
-- %D         date=\currentdate,
-- %D    copyright=Jaroslav Hajtmar,
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

thirddata.handlecsv = { -- Global variables
--	 gCSVSeparator
    gUserCSVSeparator=';',  -- the most widely used field separator in CSV tables
--  gCSVQuoter
    gUserCSVQuoter='"', --  
--	 gCSVHeader    
	 gUserCSVHeader=false, -- CSV file is by default considered as a CSV file without the header (in header are treated as column names of macros
	 gUserUseHooks=false, -- In default setting is not use "hooks" when process CSV file
    gUserColumnNumbering='XLS',  -- Something other than the XLS or undefined variable value (eg commenting that line) to set the Roman numbering ...
    gNumLine=0, --
    gNumRows=0, -- global variable  - save number of rows of csv table
    gNumCols=0, -- global variable  - save number of columns of csv table
    gCurrentLinePointer=0, -- vlastně CSV line number - číslo právě zpracovávaného řádku
    gCurrentlyProcessedCSVFile=nil,
    gColumnNames={}, -- array with column names (readings from header of CSV file)
    gColNames={}, -- associative array with column names for indexing use f.e. gColNames['Firstname']=1, etc...
	 gTableRows={}, -- array of contents of cells of CSV table -> gTableRows[row][column]
	 gTableRowsIndex={}, -- array of flags of lines of CSV table -> gTableEmptyRowsIndex[i]= true or false 
--  gMarkingEmptyLines 
    gUserMarkingEmptyLines=false, -- if true, then module mark empty rows in CSV file else module accept empty lines as regular lines 
	 gTableEmptyRows={}, -- array of indexes of empty lines of CSV table -> gTableEmptyRows[1]= 3 etc
	 gTableNotEmptyRows={}, -- array of indexes of nonempty lines of CSV table -> gTableNotEmptyRows[1]= 3 etc
	 gNumEmptyRows=0, -- number of empty rows
	 gCSVHandleBuffer={}, -- temporary buffer
}

local setmacro = interfaces.setmacro or ""

-- Initialize global variables etc.

--  Default value is saved  in glob. variable gUseHooks (default is FALSE)
if thirddata.handlecsv.gUseHooks == nil then thirddata.handlecsv.gUseHooks = thirddata.handlecsv.gUserUseHooks end
--  Default value is saved  in glob. variable gUserCSVHeader (default FALSE)
if thirddata.handlecsv.gCSVHeader == nil then thirddata.handlecsv.gCSVHeader = thirddata.handlecsv.gUserCSVHeader end
--  Default value is saved  in glob. variable gCSVSeparator (default COMMA)
if thirddata.handlecsv.gCSVSeparator == nil then thirddata.handlecsv.gCSVSeparator = thirddata.handlecsv.gUserCSVSeparator end
--  Default value is saved  in glob. variable gCSVSeparator (default ")
if thirddata.handlecsv.gCSVQuoter == nil then thirddata.handlecsv.gCSVQuoter = thirddata.handlecsv.gUserCSVQuoter end
--  Default value is saved  in glob. variable gMarkingEmptyLines (default is FALSE)
if thirddata.handlecsv.gMarkingEmptyLines==nil then thirddata.handlecsv.gMarkingEmptyLines = thirddata.handlecsv.gUserMarkingEmptyLines end


-- Tools block: Contain auxiliary functions and tools


function thirddata.handlecsv.texmacroisdefined(macroname) -- check whether macroname macro is defined  in ConTeXt 
-- function is used to test whether the user has defined the macro \macroname. If not, it needs to define any default value
	if token.csname_name(token.create(macroname)) == macroname then
		return true
 	else
		return false
	end
end


-- tool function ParseCSVLine is defined for compatibility. Parsing string (or line).
function thirddata.handlecsv.ParseCSVLine(line,sep)
	local mycsvsplitter = utilities.parsers.rfc4180splitter{
	    separator = sep,
	    quote = '"',
	}
	local list = mycsvsplitter(line) inspect(list) 
	return list[1]
end


function thirddata.handlecsv.tmn(s) -- TeX Macro Name. Name of TeX macro should not contain forbidden characters
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


function thirddata.handlecsv.xls2ar(colname) -- convert Excel column name (like A, B, ... AA, AB, ...) into serial number of column (A->1, B->2, ...)
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



function thirddata.handlecsv.ar2xls(arnum) -- convert number to Excel name column
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


function thirddata.handlecsv.ar2colnum(arnum) -- According to the settings glob. variable returns the column designation of TeX macros
	-- generated TeX macros referring to values in columns are numbered a`la EXCEL ie cA, cB, ..., cAA, etc
	-- or a`la roman number ie. cI, cII, cIII, cIV, ..., cXVIII, etc
	-- if it is "romannumbers" setting, then columns wil numbered by Romna else ala Excel
	if string.lower(thirddata.handlecsv.gUserColumnNumbering) == 'xls' then
		return thirddata.handlecsv.ar2xls(arnum) --  a la EXCEL
	else
      return string.upper(converters.romannumerals(arnum)) -- a la big ROMAN - convert Arabic numbers to big Roman. Used for "numbering" column in the TeX macros
   end
end



-- Main functions and macros: 

function thirddata.handlecsv.hookson()
 thirddata.handlecsv.gUseHooks=true
end

function thirddata.handlecsv.hooksoff()
 thirddata.handlecsv.gUseHooks=false
end

function thirddata.handlecsv.setfiletoscan(filetoscan)
 thirddata.handlecsv.gCurrentlyProcessedCSVFile=filetoscan
end


function thirddata.handlecsv.setheader()
 thirddata.handlecsv.gCSVHeader=true
 context([[\global\issetheadertrue%]])
 context([[\global\notsetheaderfalse%]])
end


function thirddata.handlecsv.unsetheader()
 thirddata.handlecsv.gCSVHeader=false
 context([[\global\issetheaderfalse%]])
 context([[\global\notsetheadertrue%]])
end

function thirddata.handlecsv.setsep(sep)
  thirddata.handlecsv.gCSVSeparator=sep
end

function thirddata.handlecsv.unsetsep()
  thirddata.handlecsv.gCSVSeparator=thirddata.handlecsv.gUserCSVSeparator
end

function thirddata.handlecsv.indexofnotemptyline(sernumline)
	context(thirddata.handlecsv.gTableNotEmptyRows[sernumline])
	return thirddata.handlecsv.gTableNotEmptyRows[sernumline]
end

function thirddata.handlecsv.indexofemptyline(sernumline)
	context(thirddata.handlecsv.gTableEmptyRows[sernumline])
	return thirddata.handlecsv.gTableEmptyRows[sernumline]
end

function thirddata.handlecsv.notmarkemptylines()
 thirddata.handlecsv.gMarkingEmptyLines=false
   for row=1,thirddata.handlecsv.gNumRows do
		thirddata.handlecsv.gTableNotEmptyRows[row]=row
     end
	 context([[\global\emptylinefalse%]])
	 context([[\global\notemptylinetrue%]])
	 context([[\global\emptylinesmarkingfalse%]])
	 context([[\global\emptylinesnotmarkingtrue%]])
end

function thirddata.handlecsv.markemptylines()
 thirddata.handlecsv.gMarkingEmptyLines=true
 	 local counteremptylines=0
	 local counternotemptylines=0
	  for row=1,thirddata.handlecsv.gNumRows do
			if thirddata.handlecsv.testemptyrow(row) then
				counteremptylines=counteremptylines+1
				thirddata.handlecsv.gTableEmptyRows[counteremptylines]=row
			else
				counternotemptylines=counternotemptylines+1
				thirddata.handlecsv.gTableNotEmptyRows[counternotemptylines]=row
			end
	  end -- for
	  context([[\global\emptylinesmarkingtrue%]])
	  context([[\global\emptylinesnotmarkingfalse%]])
end


function thirddata.handlecsv.resetmarkemptylines()
-- do following lines only when file contain completely empty rows and is requiring testing empty lines
	thirddata.handlecsv.gMarkingEmptyLines = thirddata.handlecsv.gUserMarkingEmptyLines
	 if thirddata.handlecsv.gMarkingEmptyLines then 
	    thirddata.handlecsv.markemptylines()
	 else thirddata.handlecsv.notmarkemptylines()
	 end  -- if thirddata.handlecsv.gMarkingEmptyLines 
end	 

function thirddata.handlecsv.handlecsvfilename(filename) -- In the absence of the file name to use the global variable
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (thirddata.handlecsv.gCurrentlyProcessedCSVFile == nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
   local filename = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
   return filename
end


function thirddata.handlecsv.testemptyrow(lineindex)
local linecontent=""
local isemptyline=false
	for column=1,thirddata.handlecsv.gNumCols do
		linecontent=linecontent..thirddata.handlecsv.gTableRows[lineindex][column]
	end
	if linecontent=="" or linecontent==nil then 
		isemptyline=true
		thirddata.handlecsv.gNumEmptyRows=thirddata.handlecsv.gNumEmptyRows+1
	end
	thirddata.handlecsv.gTableRowsIndex[lineindex]=isemptyline
 return isemptyline
end


function thirddata.handlecsv.emptylineevaluation(lineindex)
	if thirddata.handlecsv.gTableRowsIndex[lineindex] then
	  context([[\global\emptylinetrue%]])
	  context([[\global\notemptylinefalse%]])
	else
	 context([[\global\emptylinefalse%]])
	 context([[\global\notemptylinetrue%]])
	end	
	return thirddata.handlecsv.gTableRowsIndex[lineindex]
end


function thirddata.handlecsv.hooksevaluation()
	for i=1,#thirddata.handlecsv.gColumnNames do
	 -- context(i..' - '..thirddata.handlecsv.gColumnNames[i]..', ')
	 if not thirddata.handlecsv.texmacroisdefined('bch'..thirddata.handlecsv.gColumnNames[i]) then 
	  context.setgvalue('bch'..thirddata.handlecsv.gColumnNames[i],'\\relax')
	 end
	 if not thirddata.handlecsv.texmacroisdefined('ech'..thirddata.handlecsv.gColumnNames[i]) then 
	  context.setgvalue('ech'..thirddata.handlecsv.gColumnNames[i],'\\relax')
	 end
	end
end


function thirddata.handlecsv.opencsvfile(filetoscan) -- Open CSV tabule, inicialize variables
	-- otevře tabulku načte ji do globální proměnné thirddata.handlecsv.gTableRows
	-- pokud je zapnuta volba thirddata.handlecsv.gCSVHeader==true, pak do gl. proměnné thirddata.handlecsv.gColumnNames 
	-- nastaví názvy sloupců ze záhlaví, pokud ne, tak se nastaví XLS notace, tj. cA, cB, cC, ...  
	-- do proměnných  thirddata.handlecsv.gNumRows a  thirddata.handlecsv.gNumCols se uloží počty řádků a sloupců tabulky
	-- pokud je soubor s hlavičkou, tak se hlavičkový řádek nepočítá do počtu řádků tabulky
	-- Navíc se nadefinují ConTeXová makra  \csvfilename, \numrows a \numcols
	 thirddata.handlecsv.gNumEmptyRows=0
	 thirddata.handlecsv.gColNames={}
	 thirddata.handlecsv.gColumnNames={} 
	 -- thirddata.handlecsv.resetlinepointer() -- dal jsem až nakonec této funkce	-- set pointer to begin table (first row)
	 thirddata.handlecsv.resetnumline()
	 local inpcsvfile=thirddata.handlecsv.handlecsvfilename(filetoscan)
	 local currentlyprocessedcsvfile = io.loaddata(inpcsvfile)
	 local mycsvsplitter = utilities.parsers.rfc4180splitter{
    	separator = thirddata.handlecsv.gCSVSeparator,
    	quote = thirddata.handlecsv.gCSVQuoter,
    	strict = true,
		}
	if thirddata.handlecsv.gCSVHeader then
	 thirddata.handlecsv.gTableRows, thirddata.handlecsv.gColumnNames = mycsvsplitter(currentlyprocessedcsvfile,true)   
	 inspect(thirddata.handlecsv.gTableRows) 
	 inspect(thirddata.handlecsv.gColumnNames)
-- 		for i=1,#thirddata.handlecsv.gTableRows[1] do -- correst TeX name 
-- 		  thirddata.handlecsv.gColumnNames[i]=tostring(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[i]))
-- 		end
	else -- if thirddata.handlecsv.gCSVHeader
	  thirddata.handlecsv.gTableRows, thirddata.handlecsv.gColumnNames = mycsvsplitter(currentlyprocessedcsvfile)   
	  inspect(thirddata.handlecsv.gTableRows)
	  thirddata.handlecsv.gColumnNames={}
	  -- ad now set column names for withoutheader situation:
		for i=1,#thirddata.handlecsv.gTableRows[1] do
		 -- OK, but not used: thirddata.handlecsv.gColumnNames[i]=thirddata.handlecsv.tmn(thirddata.handlecsv.gTableRows[1][i])
		 thirddata.handlecsv.gColumnNames[i]=tostring(thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
		end
	end -- if thirddata.handlecsv.gCSVHeader
	 	for i=1,#thirddata.handlecsv.gTableRows[1] do
	 	   thirddata.handlecsv.gColNames[tostring(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[i]))] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsv.gColNames[tostring(thirddata.handlecsv.gColumnNames[i])] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
			thirddata.handlecsv.gColNames[tostring(thirddata.handlecsv.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'A', 'B', etc...)
			thirddata.handlecsv.gColNames[tostring('c'..thirddata.handlecsv.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
		end
		local j=#thirddata.handlecsv.gTableRows[1]
		for i=1,#thirddata.handlecsv.gTableRows[1] do
		j=j+1
		thirddata.handlecsv.gColumnNames[j]=tostring('c'..thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)		
		end
		if thirddata.handlecsv.gCSVHeader then
			for i=1,#thirddata.handlecsv.gTableRows[1] do
			j=j+1
			thirddata.handlecsv.gColumnNames[j]=tostring(thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)		
			end
			for i=1,#thirddata.handlecsv.gTableRows[1] do
			j=j+1
			thirddata.handlecsv.gColumnNames[j]=tostring(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[i])) -- maybe TeX incorect names of columns		
			end
		end			 	
 	 thirddata.handlecsv.gNumRows=#thirddata.handlecsv.gTableRows -- Getting number of rows
  	 thirddata.handlecsv.gNumCols=#thirddata.handlecsv.gTableRows[1] -- Getting number of columns
    context([[\global\EOFfalse%]])
  	 context([[\global\notEOFtrue%]])
  	 thirddata.handlecsv.resetlinepointer()	-- set pointer to begin table (first row)
  	 -- context([[\readline%]]) -- nyní už není třeba (je zakomponováno ve funkci setlinepointer ) ....
  	 thirddata.handlecsv.resetmarkemptylines()  
  	 if thirddata.handlecsv.gUseHooks then  thirddata.handlecsv.hooksevaluation() end
end -- of thirddata.handlecsv.opencsvfile(file)



-- Main function. Read data, parse them etc.
function thirddata.handlecsv.readline(numberofline) --
	local numberofline=numberofline
	local returnpar=false
	 if type(numberofline)~= 'number' then
	 	if numberofline==nil then
	 	 numberofline=thirddata.handlecsv.gCurrentLinePointer
	 	 returnpar=true
	 	else numberofline = 0
		end -- if numberofline==nil
	 end --  if type(numberofline)
	 if (numberofline > 0 and numberofline <=thirddata.handlecsv.gNumRows) then
	 	 thirddata.handlecsv.gNumLine = thirddata.handlecsv.gNumLine + 1
	  	 thirddata.handlecsv.gCurrentLinePointer=numberofline
		 returnpar=true 
		 thirddata.handlecsv.assigncontents(thirddata.handlecsv.gTableRows[numberofline])
		 context([[\global\EOFfalse\global\notEOFtrue%]])
	 else
		 thirddata.handlecsv.assigncontents('udefined_line')
			if numberofline > thirddata.handlecsv.gNumRows then
			   context([[\global\EOFtrue\global\notEOFfalse%]])
	   	end		
	 end  -- if (numberofline > 0  
	 	thirddata.handlecsv.emptylineevaluation(numberofline)		
 return returnpar -- return true if numberofline is regular line, else return false
end -- function thirddata.handlecsv.readline(numberofline) --
 
 
 
function thirddata.handlecsv.createxlscommand(xlsname)
local cxlsname=tostring('col'..xlsname)
local docxlsname=tostring('docol'..xlsname)
local xlsname=tostring(''..xlsname)
		interfaces.definecommand (docxlsname, {
		    arguments = { { "option", "string" }  },
		    macro = function (opt_1)
		       if #opt_1>0 then 
				  --  context('\\expanded{\\csvcell["'..xlsname..'",'..opt_1..']}')
				  -- setmacro(cxlsname,'\\csvcell[\''..xlsname..'\','..opt_1..']',"global")
				  -- setmacro(cxlsname,thirddata.handlecsv.getcellcontent(xlsname,opt_1),"global")
				  context('\\csvcell[\''..xlsname..'\','..opt_1..']')
				 else 
				  --  context('\\expanded{\\csvcell["'..xlsname..'",'..thirddata.handlecsv.gCurrentLinePointer..']}')
				  --setmacro(cxlsname,'\\csvcell[\''..xlsname..'\','..thirddata.handlecsv.gCurrentLinePointer..']',"global")
				  -- setmacro(cxlsname,thirddata.handlecsv.getcellcontent(xlsname,thirddata.handlecsv.gCurrentLinePointer),"global")
				  context('\\csvcell[\''..xlsname..'\','..thirddata.handlecsv.gCurrentLinePointer..']') 
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
function thirddata.handlecsv.assigncontents(line) -- put data into columns macros
 	local content='undefined' 
 	for i=1,	thirddata.handlecsv.gNumCols do
 		if line ~= 'udefined_line' then content = line[i] end
		local macroname=thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[i])
		local purexlsname=thirddata.handlecsv.ar2colnum(i)
		local xlsname='c'..purexlsname
		local hookxlsname='h'..xlsname
		local macroname=thirddata.handlecsv.tmn(macroname)
		local hookmacroname='h'..macroname
 	   context.setgvalue(xlsname, content) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically
 	   -- setmacro(xlsname, content,"global")
		context.setgvalue(macroname,'\\'..xlsname) -- ie  for example \let\Name\cA
		-- setmacro(macroname,'\\'..xlsname,"global")
		-- setmacro(macroname,content,"global")
					--	unused : was in old version:	context.setgvalue(macroname,content) -- defining automatic TeX macros  \cName, \cDate, etc. (names gets from header), containing the contents of the line. Macros with names of the headers are updated automatically
	-- experimental version in next two lines:
	-- this define variants of macros \colA, \colA[8], ... and \colFirstname, \colFirstname[11] etc.
		thirddata.handlecsv.createxlscommand(''..purexlsname) -- create macros \colA, \colB, etc. and their variants \colA[row], ...
		context.setgvalue('col'..macroname,'\\col'..purexlsname) -- and create fullname macros \colFirstname, \colFirstname[5], etc...
		-- create hooks macros:
	  	if thirddata.handlecsv.gUseHooks then
	  	 	 context.setgvalue(hookxlsname,'\\bch\\bch'..xlsname..'\\'..xlsname..'\\ech'..xlsname..'\\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	       context.setgvalue(hookmacroname,'\\bch\\bch'..macroname..'\\'..xlsname..'\\ech'..macroname..'\\ech ') -- defining automatic TeX macros \hName, \hDate, etc. (names gets from header), containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	  	end
	end -- for i=1,	
end -- function thirddata.handlecsv.assigncontents(line) -- put data into columns macros


-- Read data from specific cell of the csv table
function thirddata.handlecsv.getcellcontent(column,row)
--  utilities.parsers.settings_to_array(column)
--  utilities.parsers.settings_to_array(row)
	local returnparametr='undefined'
	local column=column
	local row=row
	if type(column)=='string' then 
		local testcolumn=thirddata.handlecsv.gColNames[column]
		if testcolumn==nil then
		  column=thirddata.handlecsv.xls2ar(column)
		else
		   column=testcolumn 
		end 
	end
	if type(column)=='number' and type(row)=='number' then 
		if row>0 and row <=thirddata.handlecsv.gNumRows and column>0 and column<=thirddata.handlecsv.gNumCols then
	 		returnparametr=thirddata.handlecsv.gTableRows[row][column]
		elseif row==0 then 
	 		returnparametr=thirddata.handlecsv.gColumnNames[column]
	 	end
	end
 return returnparametr  
end


-- Move line pointer to next line.
function thirddata.handlecsv.nextline()
  thirddata.handlecsv.gCurrentLinePointer=thirddata.handlecsv.gCurrentLinePointer+1
  if thirddata.handlecsv.gCurrentLinePointer > thirddata.handlecsv.gNumRows then
  	  thirddata.handlecsv.gCurrentLinePointer=thirddata.handlecsv.gNumRows 
     context([[\global\EOFtrue%]])
     context([[\global\notEOFfalse%]])
  end		
end


function thirddata.handlecsv.setlinepointer(numberofline)
  thirddata.handlecsv.gCurrentLinePointer=numberofline
  thirddata.handlecsv.readline(numberofline)
end



-- Take pointer to first row of table
function thirddata.handlecsv.resetlinepointer()
  thirddata.handlecsv.setlinepointer(1)
end


function thirddata.handlecsv.linepointer()
  context(thirddata.handlecsv.gCurrentLinePointer)
end


function thirddata.handlecsv.setnumline(numline)
  thirddata.handlecsv.gNumLine=numline
end

function thirddata.handlecsv.resetnumline()
  thirddata.handlecsv.setnumline(0)
end

function thirddata.handlecsv.addtonumline(numline)
  thirddata.handlecsv.gNumLine=thirddata.handlecsv.gNumLine+numline
end

function thirddata.handlecsv.numline()
  context(thirddata.handlecsv.gNumLine)
end


-- Move numline pointer to next number.
function thirddata.handlecsv.nextnumline()
  thirddata.handlecsv.gNumLine=thirddata.handlecsv.gNumLine+1		
end


function thirddata.handlecsv.numrows()
  context(thirddata.handlecsv.gNumRows)
end


function thirddata.handlecsv.numemptyrows()
  context(thirddata.handlecsv.gNumEmptyRows)
end


function thirddata.handlecsv.numnotemptyrows()
  context(thirddata.handlecsv.gNumRows-thirddata.handlecsv.gNumEmptyRows)
end


function thirddata.handlecsv.numcols()
  context(thirddata.handlecsv.gNumCols)
end



-- initialize ConTeXt hooks
function thirddata.handlecsv.resethooks() 
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
function thirddata.handlecsv.string2context(str2ctx)
  local s=str2ctx
  s=string.gsub(s, "%%(.-)\n", "\n")  -- remove TeX comments from string. From % character to the end of line
  -- s=string.gsub(s, '\n', "")
  context(s)
  -- texsprint(s) -- for debugging ...
end


function thirddata.handlecsv.doloopfromto(from, to, action)
 context[[\opencsvfile]]
 context[[\resetnumline]]
 context[[\bfilehook]]
 context[[\removeunwantedspaces]]
 local from=from
 local to=to
 local pom=to
  if from>to then to=from; from=pom end
       for i=from, to do
			context[[\blinehook]]
			context([[\readline{]]..i..[[}]]) -- context(thirddata.handlecsv.readline(i))
         context(action)
			context[[\elinehook]]
       end
context[[\removeunwantedspaces]]
context[[\efilehook]]
end -- function thirddata.handlecsv.doloopfromto



-- ConTeXt source:
local string2print=[[%
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
\def\resethooks{\ctxlua{context(thirddata.handlecsv.resethooks())}}
\resethooks % -- DO IT NOW !!!
\def\hookson{\ctxlua{thirddata.handlecsv.hookson()}}
\let\usehooks\hookson % -- synonym only
\def\hooksoff{\ctxlua{thirddata.handlecsv.hooksoff()}}
\def\setheader{\ctxlua{thirddata.handlecsv.setheader()}}
\def\unsetheader{\ctxlua{thirddata.handlecsv.unsetheader()}}
\let\resetheader\unsetheader % -- for compatibility
\def\setsep#1{\ctxlua{thirddata.handlecsv.setsep('#1')}}
\def\unsetsep{\ctxlua{thirddata.handlecsv.unsetsep()}}
\let\resetsep\unsetsep % -- for compatibility
\def\setfiletoscan#1{\ctxlua{thirddata.handlecsv.setfiletoscan('#1')}}


\def\numrows{\ctxlua{context(thirddata.handlecsv.numrows())}}
\def\numemptyrows{\ctxlua{context(thirddata.handlecsv.numemptyrows())}}
\def\numnotemptyrows{\ctxlua{context(thirddata.handlecsv.numnotemptyrows())}}
\def\numcols{\ctxlua{context(thirddata.handlecsv.numcols())}}
\def\csvfilename{\ctxlua{context(thirddata.handlecsv.handlecsvfilename())}}

% usefull tool macros : 

% Pass the contents of the macro into parameter 
\def\thenumexpr#1{\the\numexpr(#1+0)}
% Add content (#2) into content of macro #1
\long\def\addto#1#2{\expandafter\def\expandafter#1\expandafter{#1#2}}
% Expanded version of previous macro
\long\def\eaddto#1#2{\edef#1{#1#2}} 



% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number] OR \csvcell['ColumnName',row number] 
\def\getcsvcell[#1,#2]{\ctxlua{context(thirddata.handlecsv.getcellcontent(#1,#2))}}%

% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number or row number getting from macro] OR \csvcell['ColumnName',row number or row number getting from macro]
\def\csvcell[#1,#2]{\getcsvcell[#1,\the\numexpr(#2+0)]}%
%\def\csvcell\getcsvcell


% Get column name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\colname[#1]{\ctxlua{context(thirddata.handlecsv.gColumnNames[#1])}}%

% Get index (ie serrial number) of strings columns names (own name or XLS name) 
\def\indexcolname[#1]{\ctxlua{context(thirddata.handlecsv.gColNames[#1])}}%

% Get (alternative) XLS column name (of n-th column)
\def\xlscolname[#1]{\ctxlua{context(thirddata.handlecsv.ar2colnum(#1))}}%

% Get (alternative) XLS column name (of n-th column)
\def\cxlscolname[#1]{\ctxlua{context('c'..thirddata.handlecsv.ar2colnum(#1))}}%

% Get column TeX name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\texcolname[#1]{\ctxlua{context(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[#1]))}}%


% Get content of n-th column of current row 
\def\columncontent[#1]{%
\getcsvcell[#1,\linepointer]%
}%


% Get number from XLS column name (ie n-th column)
\def\numberxlscolname[#1]{\ctxlua{context(thirddata.handlecsv.xls2ar(#1))}}%


\def\resetlinepointer{\ctxlua{context(thirddata.handlecsv.resetlinepointer())}}
\let\resetlineno\resetlinepointer
\let\resetsernumline\resetlinepointer
\def\setnumline#1{\ctxlua{thirddata.handlecsv.setnumline(#1)}}
\def\resetnumline{\ctxlua{context(thirddata.handlecsv.resetnumline())}}
\def\linepointer{\ctxlua{context(thirddata.handlecsv.linepointer())}}
\let\lineno\linepointer
\let\sernumline\linepointer
\def\numline{\ctxlua{context(thirddata.handlecsv.numline())}}
\def\addtonumline#1{\ctxlua{thirddata.handlecsv.addtonumline(#1)}}
%\def\setlinepointer#1{\ctxlua{thirddata.handlecsv.setlinepointer(#1);thirddata.handlecsv.readline(#1)}}
\def\setlinepointer#1{\ctxlua{thirddata.handlecsv.setlinepointer(#1)}}
\def\indexofnotemptyline#1{\ctxlua{thirddata.handlecsv.indexofnotemptyline(#1)}}
\def\indexofemptyline#1{\ctxlua{thirddata.handlecsv.indexofemptyline(#1)}}
\def\notmarkemptylines{\ctxlua{thirddata.handlecsv.notmarkemptylines()}}
\def\markemptylines{\ctxlua{thirddata.handlecsv.markemptylines()}}
\def\resetmarkemptylines{\ctxlua{thirddata.handlecsv.resetmarkemptylines()}}%
\def\nextline{\ctxlua{context(thirddata.handlecsv.nextline())}} % -- macro for skip to next line. \nextline no read data from current line unlike \nextrow macro.
\def\nextnumline{\ctxlua{context(thirddata.handlecsv.nextnumline())}} % -- macro for add  numline counter.
\def\nextrow{\readline\nextline} % -- For compatibility
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
    \ctxlua{thirddata.handlecsv.opencsvfile(#1)}%
   \else%
	 \ctxlua{thirddata.handlecsv.opencsvfile()}%
   \fi%
}%


% Read data from n-th line of CSV table. Calling without parameter read current line (pointered by global variable) 
\def\readline{\dosingleempty\doreadline}%

\def\doreadline[#1]{\dosinglegroupempty\dodoreadline}%
% Musí zůstat v takto kompaktní podobě, jinak vrací nechtěné mezery!!!!
\def\dodoreadline#1{\iffirstargument\ctxlua{thirddata.handlecsv.readline(#1)}\else\ctxlua{thirddata.handlecsv.readline(thirddata.handlecsv.gCurrentLinePointer)}\fi}%


\def\readandprocessparameters#1#2#3#4{%
	\edef\firstparam{#1}%
	\edef\secondparam{#2}%
 	\edef\thirdparam{#3}%
 	\edef\fourthparam{#4}%
 	\edef\paroperator{#2}%
%  operator '==' is for strings comparing converted to 'eq' operator 
   \ctxlua{if '#2'=="==" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') then context('\\def\\paroperator{eq}') end}%
%  operator '~=' is for strings comparing converted to 'neq' operator
   \ctxlua{if '#2'=="~=" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') then context('\\def\\paroperator{neq}') end}% 	
}%

% MACROS FOR CYCLES PROCESSING. DO ACTIONS IN CYCLES


% v této funkci odstranit nechtěné mezery
% 1. \doloopfromto{from}{to}{action}  
% do action "action" from line "from" to line "to" of open CSV file 
\def\doloopfromto#1#2#3{\ctxlua{thirddata.handlecsv.doloopfromto([==[\thenumexpr{#1}]==],[==[\thenumexpr{#2}]==],[==[\detokenize{#3}]==])}}%
%\def\doloopfromto#1#2#3{\ctxlua{thirddata.handlecsv.doloopfromto([==[\thenumexpr{#1}]==],[==[\thenumexpr{#2}]==],[==[\expanded{#3}]==])}}%

\def\Doloopfromto#1#2#3{% old version
   {\opencsvfile}%
   {\resetnumline}%
   \bfilehook%
   \removeunwantedspaces%
	\ifnum#1<#2\dostepwiserecurse{#1}{#2}{1}{\blinehook{\readline{\recurselevel}}#3\elinehook}%
   \else\dostepwiserecurse{#1}{#2}{-1}{\blinehook{\readline{\recurselevel}}#3\elinehook}%
	\fi%
	\removeunwantedspaces%
	\efilehook%
}%
 
% 2. \doloopforall  % implicit do \lineaction for all lines of open CSV table
% \doloopforall{\action}  % do \action macro for all lines of open CSV table
\def\doloopforall{\dosinglegroupempty\doloopforAll}%

\def\doloopforAll#1{%
  \doifsomethingelse{#1}{%1 args.
	\doloopfromto{1}{\numrows}{#1}%
	}{%
	\doloopfromto{1}{\numrows}{\lineaction}%
	}%
}% 

% 3. \doloopaction % implicit use \lineaction macro
% \doloopaction{\action} % use \action macro for all lines of open CSV file
% \doloopaction{\action}{4} % use \action macro for first 4 lines
% \doloopaction{\action}{2}{5} % use \action macro for lines from 2 to 5
\def\doloopaction{\dotriplegroupempty\doloopAction}

\def\doloopAction#1#2#3{%
\opencsvfile%
\resetnumline%
\doifsomethingelse{#3}{%3 args.
	\doloopfromto{#2}{#3}{#1}% if 3 arguments then do #1 macro from #2 line to  #3 line
	}{%
	\doifsomethingelse{#2}{%2 args.
	\doloopfromto{1}{#2}{#1}% if 2 arguments then do #1 macro for first #2 lines
	}%
	{\doifsomethingelse{#1}{% 1 arg.
		\doloopfromto{1}{\numrows}{#1}%
		}{% if without arguments then do \lineaction macro for all lines 
		\doloopfromto{1}{\numrows}{\lineaction}%
		}%
	}%	
	}%
}% 


% 4. \doloopif{value1}{[compare_operator]}{value2}{macro_for_doing} % [compareoperators] <, >, ==(eq), ~=(neq), >=, <=, in, until, while 
% actions for rows of open CSV file which are responded of condition  
\def\doloopif#1#2#3#4{%
	 \readandprocessparameters{#1}{#2}{#3}{#4}%
    \opencsvfile%
    \resetnumline%
    \nextrow% must be here
    \bfilehook%
    % and now process actual operator 
    \processaction[\paroperator][%
     <=>{% {number1}{<}{number2} ... Less 
     %\doloop{\ifnum\firstparam<\thirdparam\blinehook\fourthparam\elinehook\else\addtonumline{-1}\fi\exitlooptest}%
     \doloop{\ctxlua{if #1<#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end < ... Less
     >=>{% {number1}{>}{number2} ... Greater 
     %\doloop{\ifnum#1>#3 \blinehook\fourthparam\elinehook\else\addtonumline{-1}\fi\exitlooptest}%
     \doloop{\ctxlua{if #1>#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end > ... Greater
     ===>{% {number1}{==}{number2} ... Equal
     %\doloop{\ifnum#1=#3 \blinehook{}\fourthparam{}\elinehook\else\addtonumline{-1}\fi\exitlooptest}%
     \doloop{\ctxlua{if #1==#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end == ... Equal
     ~==>{% {number1}{~=}{number2} ... Not Equal
     \doloop{\ctxlua{if #1~=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end ~= ... Not Equal
     >==>{% {number1}{>=}{number2} ... GreaterOrEqual 
     \doloop{\ctxlua{if #1>=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end >=  ... GreaterOrEqual
     <==>{% {number1}{<=}{number2} ... LessOrEqual 
     \doloop{\ctxlua{if #1<=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end <= ... LessOrEqual 
     eq=>{%  command {string1}{==}{string2} is converted to command command {string1}{eq}{string2} ... string1 is equal string2 
     %\doloop{\ifx\firstparam\thirdparam\blinehook\fourthparam\elinehook\else\addtonumline{-1}\fi\exitlooptest}%
     \doloop{\ctxlua{if '#1'=='#3' then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },%  end eq
     neq=>{%  command {string1}{~=}{string2} is converted to command command {string1}{neq}{string2} ... string1 is not equal string2  
     %\doloop{\ifx\firstparam\thirdparam\addtonumline{-1}\else\blinehook\fourthparam\elinehook\fi\exitlooptest}%
     \doloop{\ctxlua{if '#1'~='#3' then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end neq
     in=>{% {substring}{in}{string} ... substring is contained inside string
     \doloop{\doifincsnameelse{#1}{#3}{\blinehook\fourthparam\elinehook}{\addtonumline{-1}}\exitlooptest}%
     %\doloop{\ctxlua{if string.match('#1', '#3') then context('1-#1','3-#3','\\blinehook\\fourthparam\\elinehook') else context(' 1-#1',' 3-#3') thirddata.handlecsv.addtonumline(-1) end}\exitlooptest}%
     },% end in
     until=>{% {substring}{until}{string} ... % List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all record
      %\doloop{\if\firstparam\thirdparam\exitloop\else\ifEOF\exitloop\else\blinehook\fourthparam\elinehook\nextrow\fi\fi}%
      \doloop{\ctxlua{if '#1'=='#3' then context('\\exitloop') else context('\\blinehook\\fourthparam\\elinehook\\ifEOF\\exitloop\\else\\nextrow\\fi') end}}%
     },% end until % the comma , is very important here!!!
     while=>{% {string}{while}{string} ... % List all, while the test is  met. When first which not met then just quit. If first is not met, will list no record
	  %\doloop{\if\firstparam\thirdparam\blinehook\fourthparam\elinehook\nextrow\else\exitloop\fi\ifEOF\exitloop\fi}%
     \doloop{\ctxlua{if '#1'=='#3' then context('\\blinehook\\fourthparam\\elinehook\\nextrow') else context('\\exitloop\\ifEOF\\exitloop\\fi')end}}%
     },% end while % the comma , is very important here!!!
    ] % end of \processaction%
  \efilehook%
} % end of \doloopif


% specific variations of previous macro \doloopif 
\letvalue{doloopifnum}=\doloopif %\doloopifnum{value1}{[compare_operator]}{value2}{macro_for_doing}% [compareoperators] ==, ~=, >, <, >=, <= % FOR COMPATIBILITY ONLY
\def\doloopuntil#1#2#3{\doloopif{#1}{until}{#2}{#3}}% \doloopuntil{\Trida}{3.A}{\tableaction}% List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all records.
\def\doloopwhile#1#2#3{\doloopif{#1}{while}{#2}{#3}}% \doloopwhile{\Trida}{3.A}{\tableaction}% List when the test is met, other just quit. 

% 5. \filelineaction  % implicit do \lineaction for all lines of current open CSV table
% \filelineaction{filename.csv}   % do \lineaction macro for all lines of specific CSV table (filename.csv)
\def\filelineaction{\dotriplegroupempty\dofilelineaction}%

\def\dofilelineaction#1#2#3{%
	\doifelsenothing{#1}%
	{\opencsvfile\resetnumline\doloopaction%0 parameter - open actual CSV file and do action
	}%
	{\doifelsenothing{#2}%
	{\opencsvfile{#1}\resetnumline\doloopaction%1 parameter - parameter = filename
	}%
	{\doifelsenothing{#3}%
	{\opencsvfile{#1}\resetnumline\doloopaction{\lineaction}{#2}%2 parameters, 1st parameter = filename, 2nd parameter = num of lines
	}%
	{\opencsvfile{#1}\resetnumline\doloopaction{\lineaction}{#2}{#3}%3 parameters, 1st parameter = filename, 2nd parameter = from line, 3rd parameter = to line
	}}}%
}% 

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
% \readandprocessparameters#1#2#3#4 -- for internal use only 
%
%  Module predefined cycles for processing of lines CSV table:
% \doloopfromto{<fromnumblerline>}{<tonumblerline}{<\actionmacro>}
% \doloopforall, \doloopforall{<\actionmacro>}
% \doloopaction, \doloopaction{<\actionmacro>}, \doloopaction{<\actionmacro>}{<tonumblerline>}, \doloopaction{<\actionmacro>}{<fromnumblerline>}{<tonumblerline>}
% \doloopif{<value1>}{<compare_operator>}{value2}{<\actionmacro>}, (\doloopifnum{<value1>}{<compare_operator>}{value2}{<\actionmacro>} is synonym)
% \doloopuntil{<value1>}{<value2>}{<\actionmacro>} 
% \doloopwhile{<value1>}{<value2>}{<\actionmacro>} 
% \filelineaction, \filelineaction{<filename>} 

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]

-- write definitions into ConTeXt:
thirddata.handlecsv.string2context(string2print)


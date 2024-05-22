-- use a feature that is part of the util-prs.lua 

thirddata = thirddata or { }

thirddata.handlecsv = { -- Global variables
    gUserCSVSeparator=',',  -- the most widely used field separator in CSV tables
    gUserCSVQuoter='"', --  
    gUserCSVHeader=false, -- CSV file is by default considered as a CSV file without the header (in header are treated as column names of macros
    gUserColumnNumbering='XLS',  -- Something other than the XLS or undefined variable value (eg commenting that line) to set the Roman numbering ...
   -- gCSVHeader, --
   -- gCSVSeparator, --
   -- gCSVQuoter,
--    -- gLq, --
--    -- gRq, --
--    gUserRemoveEmptyRows=true, -- if true, then module remove empty rows in CSV file add 19.2.2015
--    gCSVFile=nil, --
--    gCSV={}, --
--    gCSVField={}, --
--    gLineNo=0, --
    gSerNumLine=0, -- global variable  - save serial number of process lines
    gNumRows=0, -- global variable  - save number of rows of csv table
    gNumCols=0, -- global variable  - save number of columns of csv table
--    gNumEmptyRows=0, --
    gCurrentLinePointer=0, -- vlastně CSV line number - číslo právě zpracovávaného řádku
    gCurrentlyProcessedCSVFile=nil,
    gColumnNames={}, -- array with column names (readings from header of CSV file)
    gColNames={}, -- associative array with column names for indexing use f.e. gColNames['Firstname']=1, etc...
	 gTableRows={}, -- array of contents of cells of CSV table -> gTableRows[row][column]
--    gFile2Scan=nil,--
--    gIfEOF=false, --
--    gIfNotEOF=true --
}



--  Default value is saved  in glob. variable gUserCSVHeader (default FALSE)
if thirddata.handlecsv.gCSVHeader == nil then thirddata.handlecsv.gCSVHeader = thirddata.handlecsv.gUserCSVHeader end
--  Default value is saved  in glob. variable gCSVSeparator (default COMMA)
if thirddata.handlecsv.gCSVSeparator == nil then thirddata.handlecsv.gCSVSeparator = thirddata.handlecsv.gUserCSVSeparator end
--  Default value is saved  in glob. variable gCSVSeparator (default ")
if thirddata.handlecsv.gCSVQuoter == nil then thirddata.handlecsv.gCSVQuoter = thirddata.handlecsv.gUserCSVQuoter end




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


 

function thirddata.handlecsv.setfiletoscan(filetoscan)
 thirddata.handlecsv.gCurrentlyProcessedCSVFile=filetoscan
end

interfaces.definecommand {
    name      = "setfiletoscan",
    macro     = thirddata.handlecsv.setfiletoscan,
    arguments = {
        { "content", "string" }
    }
}


function thirddata.handlecsv.setheader()
 thirddata.handlecsv.gCSVHeader=true
 context([[\global\issetheadertrue]])
 context([[\global\notsetheaderfalse]])
end

interfaces.definecommand {
    name      = "setheader",
    macro     = thirddata.handlecsv.setheader,
}

function thirddata.handlecsv.resetheader()
 thirddata.handlecsv.gCSVHeader=false
 context([[\global\issetheaderfalse]])
 context([[\global\notsetheadertrue]])
end

interfaces.definecommand {
    name      = "resetheader",
    macro     = thirddata.handlecsv.resetheader,
}

function thirddata.handlecsv.setsep(sep)
  thirddata.handlecsv.gCSVSeparator=sep
end

interfaces.definecommand {
    name      = "setsep",
    macro     = thirddata.handlecsv.setsep,
    arguments = {
        { "content", "string" }
    }
}


function thirddata.handlecsv.resetsep()
  thirddata.handlecsv.gCSVSeparator=thirddata.handlecsv.gUserCSVSeparator
end

interfaces.definecommand {
    name      = "resetsep",
    macro     = thirddata.handlecsv.resetsep,
}



function thirddata.handlecsv.csvfilename(filename) -- In the absence of the file name to use the global variable
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (thirddata.handlecsv.gCurrentlyProcessedCSVFile == nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
   local filename = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
   return filename
end


function thirddata.handlecsv.opencsvfile(filetoscan) -- Open CSV tabule, inicialize variables
	-- otevře tabulku načte ji do globální proměnné thirddata.handlecsv.gTableRows
	-- pokud je zapnuta volba thirddata.handlecsv.gCSVHeader==true, pak do gl. proměnné thirddata.handlecsv.gColumnNames 
	-- nastaví názvy sloupců ze záhlaví, pokud ne, tak se nastaví XLS notace, tj. cA, cB, cC, ...  
	-- do proměnných  thirddata.handlecsv.gNumRows a  thirddata.handlecsv.gNumCols se uloží počty řádků a sloupců tabulky
	-- pokud je soubor s hlavičkou, tak se hlavičkový řádek nepočítá do počtu řádků tabulky
	-- Navíc se nadefinují ConTeXová makra  \csvfilename, \numrows a \numcols
	 thirddata.handlecsv.resetlinepointer()
	 thirddata.handlecsv.gColNames={}
	 thirddata.handlecsv.gColumnNames={}
	 thirddata.handlecsv.resetsernumline() -- initialize counter of processing lines (add 1 in each call of readline function) 
	 thirddata.handlecsv.resetlinepointer()	-- set pointer to begin table (first row)
	 local inpcsvfile=thirddata.handlecsv.csvfilename(filetoscan)
	 local currentlyprocessedcsvfile = io.loaddata(inpcsvfile)
	 local mycsvsplitter = utilities.parsers.rfc4180splitter{
    	separator = thirddata.handlecsv.gCSVSeparator,
    	quote = thirddata.handlecsv.gCSVQuoter,
		}
	if thirddata.handlecsv.gCSVHeader then
	 thirddata.handlecsv.gTableRows, thirddata.handlecsv.gColumnNames = mycsvsplitter(currentlyprocessedcsvfile,true)   
	 inspect(thirddata.handlecsv.gTableRows) 
	 inspect(thirddata.handlecsv.gColumnNames)
	 	for i=1,#thirddata.handlecsv.gTableRows[1] do
			thirddata.handlecsv.gColNames[tostring(thirddata.handlecsv.gColumnNames[i])] = i -- for indexing use
		end
	else
	  thirddata.handlecsv.gTableRows = mycsvsplitter(currentlyprocessedcsvfile)   
	  inspect(thirddata.handlecsv.gTableRows) 
	  -- ad now set column names for withoutheader situation:
		for i=1,#thirddata.handlecsv.gTableRows[1] do
			-- OK, but not used: thirddata.handlecsv.gColumnNames[i]=thirddata.handlecsv.tmn(thirddata.handlecsv.gTableRows[1][i])
			thirddata.handlecsv.gColumnNames[i]='c'..thirddata.handlecsv.ar2xls(i) -- set XLS notation
		end
	end 
	 thirddata.handlecsv.gNumRows=#thirddata.handlecsv.gTableRows -- Getting number of rows
 	 thirddata.handlecsv.gNumCols=#thirddata.handlecsv.gTableRows[1] -- Getting number of columns
	 context.setgvalue("csvfilename",tostring(inpcsvfile)) -- \csvfilename macro defining
	 context.setgvalue("numrows",tostring(thirddata.handlecsv.gNumRows)) -- \numrows macro defining
	 context.setgvalue("numcols",tostring(thirddata.handlecsv.gNumCols)) -- \numcols macro defining
    context([[\global\EOFfalse]])
  	 context([[\global\notEOFtrue]])
end -- of thirddata.handlecsv.opencsvfile(file)



function thirddata.handlecsv.readline(numberofline) --
	local numberofline=numberofline
	local returnpar=false
	 if type(numberofline)~= 'number' then
	 	if numberofline==nil then
	 	 numberofline=thirddata.handlecsv.gCurrentLinePointer
	 	 returnpar=true
	 	else
		 numberofline = 0
		end 
	 end
	 
	 if  (numberofline > 0 and numberofline <=thirddata.handlecsv.gNumRows) then
	  		thirddata.handlecsv.gCurrentLinePointer=numberofline
			returnpar=true 
			thirddata.handlecsv.assigncontents(thirddata.handlecsv.gTableRows[numberofline])
			context([[\global\EOFfalse]])
  	 		context([[\global\notEOFtrue]])
	 else
			thirddata.handlecsv.assigncontents('udefined_line')
			if numberofline > thirddata.handlecsv.gNumRows then
			   context([[\global\EOFtrue]])
   			context([[\global\notEOFfalse]])
	   	end		
	 end   
	 thirddata.handlecsv.gSerNumLine = thirddata.handlecsv.gSerNumLine + 1
 return returnpar -- return true if numberofline is regular line, else return false
end
 

function thirddata.handlecsv.nextline()
  thirddata.handlecsv.gCurrentLinePointer=thirddata.handlecsv.gCurrentLinePointer+1
  		if thirddata.handlecsv.gCurrentLinePointer > thirddata.handlecsv.gNumRows then
			   context([[\global\EOFtrue ]])
   			context([[\global\notEOFfalse ]])
   	end		
end

interfaces.definecommand {
    name      = "nextline",
    macro     = thirddata.handlecsv.nextline,
}


function thirddata.handlecsv.setlinepointer(numline)
  thirddata.handlecsv.gCurrentLinePointer=numline
end

interfaces.definecommand {
    name      = "setlinepointer",
    arguments = {{"content", "number"},},
    macro     = thirddata.handlecsv.setlinepointer,
}

function thirddata.handlecsv.resetlinepointer()
  thirddata.handlecsv.setlinepointer(1)
end

interfaces.definecommand {
    name      = "resetlinepointer",
    macro     = thirddata.handlecsv.resetlinepointer,
}


function thirddata.handlecsv.linepointer()
  context(thirddata.handlecsv.gCurrentLinePointer)
end

interfaces.definecommand {
    name      = "linepointer",
    macro     = thirddata.handlecsv.linepointer,
}



function thirddata.handlecsv.sernumline()
  context(thirddata.handlecsv.gSerNumLine)
end

interfaces.definecommand {
    name      = "sernumline",
    macro     = thirddata.handlecsv.sernumline,
}


function thirddata.handlecsv.setsernumline(numline)
  thirddata.handlecsv.gSerNumLine=numline
end

interfaces.definecommand {
    name      = "setsernumline",
    arguments = {{"content", "number"},},
    macro     = thirddata.handlecsv.setsernumline,
}

function thirddata.handlecsv.resetsernumline()
  thirddata.handlecsv.setsernumline(0)
end

interfaces.definecommand {
    name      = "resetsernumline",
    macro     = thirddata.handlecsv.resetsernumline,
}


function thirddata.handlecsv.resethooks() 
 context([[\letvalue{blinehook}=\relax
   \letvalue{elinehook}=\relax
   \letvalue{bfilehook}=\relax
   \letvalue{efilehook}=\relax
   \letvalue{bch}=\relax
   \letvalue{ech}=\relax]])
end


interfaces.definecommand {
    name      = "resethooks",
    macro     = thirddata.handlecsv.resethooks,
}


function thirddata.handlecsv.assigncontents(line) -- put data into columns macros
 	local content='undefined' 
 	for i=1,	thirddata.handlecsv.gNumCols do
 		if line ~= 'udefined_line' then content = line[i] end
		local macroname=thirddata.handlecsv.gColumnNames[i]
 	    context.setgvalue('c'..thirddata.handlecsv.ar2colnum(i), content) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically 			
       context.setgvalue(thirddata.handlecsv.tmn(macroname),content)
	 context.setgvalue('hc'..thirddata.handlecsv.ar2colnum(i),'\\bch'..content..' \\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
    context.setgvalue('h'..thirddata.handlecsv.tmn(macroname),'\\bch'..content..' \\ech')
  	end
end


function thirddata.handlecsv.getcellcontent(column,row)
     utilities.parsers.settings_to_array(column)
     utilities.parsers.settings_to_array(row)
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


function thirddata.handlecsv.string2context(str2ctx)
  local s=str2ctx
  s=string.gsub(s, "%%(.-)\n", "\n")  -- remove TeX comments from string. From % character to the end of line
  -- s=string.gsub(s, '\n', "")
  context(s)
  -- texsprint(s) -- for debugging ...
end



local string2print=[[
\resethooks
\newif\ifissetheader
\newif\ifnotsetheader
\newif\ifEOF
\newif\ifnotEOF

% Due compatibility:
\let\unsetsep\resetsep
\let\lineno\linepointer
\let\numline\sernumline
\let\resetnumline\resetsernumline
\def\nextrow{\readline\nextline}



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
    \ctxlua{thirddata.handlecsv.opencsvfile("#1")}
   \else
	 \ctxlua{thirddata.handlecsv.opencsvfile()}
   \fi
}


% Read data from n-th line of CSV table. Calling without parameter read current line (pointered by global variable) 
\def\readline{%
    \dosingleempty\doreadline%
}

\def\doreadline[#1]{%
	\dosinglegroupempty\dodoreadline
}

\def\dodoreadline#1{%
    \iffirstargument
    \startluacode
    	thirddata.handlecsv.readline(#1)
    \stopluacode
	\else
   	\startluacode
	   	thirddata.handlecsv.readline(thirddata.handlecsv.gCurrentLinePointer)
	   \stopluacode
   \fi
}



% Get column name of n-th column of CSV table.
\def\colname[#1]{%
\startluacode%
	context(thirddata.handlecsv.gColumnNames[#1])
\stopluacode%
}

% Get index (ie serrial number) of strings columns names 
\def\indexcolname[#1]{%
\startluacode%
	context(thirddata.handlecsv.gColNames[#1])
\stopluacode%
}


% Get (alternative) XLS column name (of n-th column)
\def\xlscolname[#1]{%
\startluacode%
	context(thirddata.handlecsv.ar2colnum(#1))
\stopluacode%
}

% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number] OR \csvcell['ColumnName',row number] 
\def\csvcell[#1,#2]{
\startluacode
context(thirddata.handlecsv.getcellcontent(#1,#2))
\stopluacode
}


% ACTIONS IN CYCLES (DEFINITIONS)


% 1. \doloopfromto{from}{to}{action}  
% do action "action" from line "from" to line "to" of open CSV file 
\def\doloopfromto#1#2#3{
   \opencsvfile
   \bfilehook
	\dostepwiserecurse{#1}{#2}{1}{\blinehook\readline{\recurselevel}#3\elinehook}
	\efilehook
}
 
% 2. \doloopforall  % implicit do \lineaction for all lines of open CSV table
% \doloopforall{\action}  % do \action macro for all lines of open CSV table
\def\doloopforall{\dosinglegroupempty\doloopforAll}

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
    \opencsvfile%
    \readline
    \bfilehook%
    \def\paroperator{#2}
    %  operator '==' is for strings comparing converted to 'eq' operator 
    \startluacode
			 if '#2'=="==" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') 
	     then context('\\def\\paroperator{eq}')  
	     end
     \stopluacode
    %  operator '~=' is for strings comparing converted to 'neq' operator
    \startluacode
		 if '#2'=="~=" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') 
     then context('\\def\\paroperator{neq}')  
     end
		 \stopluacode
    % and now process actual operator 
    \processaction[\paroperator][%
     <=>{% {number1}{<}{number2} ... Less 
     \doloop{%
    	\edef\tempiv{#4}%
      \startluacode
				if #1<#3 then context('\\blinehook \\tempiv\\elinehook') end
			\stopluacode
			%
      \readline\nextline%
   	  \ifEOF\exitloop\fi%
     }%
     },% end < ... Less
     >=>{% {number1}{>}{number2} ... Greater 
     \doloop{%
    	\edef\tempiv{#4}%
    	\startluacode
				if #1>#3 then context('\\blinehook \\tempiv\\elinehook') end
			\stopluacode
			\readline\nextline\ifEOF\exitloop\fi%
     }%
     },% end > ... Greater
     ===>{% {number1}{==}{number2} ... Equal
     \doloop{%
       \edef\tempiv{#4}%
    	 \startluacode
			  if #1==#3 then context('\\blinehook \\tempiv\\elinehook') end
			 \stopluacode
			 \readline\nextline\ifEOF\exitloop\fi%
     }%
     },% end == ... Equal
     ~==>{% {number1}{~=}{number2} ... Not Equal
     \doloop{%
       \edef\tempiv{#4}%
    	  \startluacode
			   if #1~=#3 then context('\\blinehook \\tempiv\\elinehook') end
				\stopluacode
				\readline\nextline\ifEOF\exitloop\fi%
     }%
     },% end ~= ... Not Equal
     >==>{% {number1}{>=}{number2} ... GreaterOrEqual 
     \doloop{%
       \edef\tempiv{#4}%
    	 \startluacode
			  if #1>=#3 then context('\\blinehook \\tempiv\\elinehook') end
				\stopluacode
				\readline\nextline\ifEOF\exitloop\fi%
     }
     },% end >=  ... GreaterOrEqual
     <==>{% {number1}{<=}{number2} ... LessOrEqual 
     \doloop{%
       \edef\tempiv{#4}%
       \startluacode
			   if #1<=#3 then context('\\blinehook \\tempiv\\elinehook') end
			 \stopluacode
			 \readline\nextline\ifEOF\exitloop\fi%
     }%
     },% end <= ... LessOrEqual 
     eq=>{%  command {string1}{==}{string2} is converted to command command {string1}{eq}{string2} ... string1 is equal string2 
     \doloop{%
 		 \edef\tempi{#1}%
 		 \edef\tempii{#3}%
 		 \edef\tempiii{#4}%
       \ifx\tempi\tempii\blinehook \tempiii\elinehook\fi\readline\nextline\ifEOF\exitloop\fi%
     }%
     },%  end eq
     neq=>{%  command {string1}{~=}{string2} is converted to command command {string1}{neq}{string2} ... string1 is not equal string2  
     \doloop{%
  		\edef\tempi{#1}%
  		\edef\tempii{#3}%
  		\edef\tempiii{#4}%
      \ifx\tempi\tempii\else\blinehook \tempiii\elinehook\fi\readline\nextline\ifEOF\exitloop\fi%
     }%
     },% end neq
     in=>{% {substring}{in}{string} ... substring is contained inside string 
     \doloop{%
 		 \edef\tempi{#1}%
 		 \edef\tempii{#3}%
 		 \edef\tempiii{#4}%
       \doifincsnameelse{\tempi}{\tempii}{\blinehook \tempiii\elinehook}
			 \readline\nextline\ifEOF\exitloop\fi%
     }
     }, % end in
     until=>{% {substring}{until}{string} ... % List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all record
      \doloop{
        \edef\tempi{#1}
        \edef\tempii{#3}
        \edef\tempiii{#4}
        % \ifx\tempi\tempii\exitloop\else\ifEOF\exitloop\else \blinehook \tempiii \elinehook\readline\nextline\fi\fi% recent version
        \ifx\tempi\tempii\exitloop\else\ifEOF\exitloop\else\blinehook \tempiii\elinehook\readline\nextline\fi\fi% new version
     }%
     }, % end until % the comma , is very important here!!!
     while=>{% {string}{while}{string} ... % List all, while the test is  met. When first which not met then just quit. If first is not met, will list no record
     \doloop{%
	   \edef\tempi{#1}
	   \edef\tempii{#3}
      \edef\tempiii{#4}
	   \ifx\tempi\tempii\blinehook \tempiii\elinehook\readline\nextline\else\exitloop\fi%
   	\ifEOF\exitloop\fi%
     }%
     }, % end while % the comma , is very important here!!!
     test=>{% {string}{while}{string} ... % List all, while the test is  met. When first which not met then just quit. If first is not met, will list no record
     \doloop{%
	   \edef\tempi{#1}
	   \edef\tempii{#3}
      \edef\tempiii{#4}
	   \ifx\tempi\tempii\blinehook \tempiii\elinehook\readline\nextline\else\exitloop\fi%
   	\ifEOF\exitloop\fi%
     }%
     }, % end test % the comma , is very important here!!!
    ]% end of \processaction
  \efilehook%
} % end of \doloopif


-- % specific variations of previous macro \doloopif 
-- \letvalue{doloopifnum}=\doloopif %\doloopifnum{value1}{[compare_operator]}{value2}{macro_for_doing} % [compareoperators] ==, ~=, >, <, >=, <=
-- \def\doloopuntil#1#2#3{\doloopif{#1}{until}{#2}{#3}}% \doloopuntil{\Trida}{3.A}{\tableaction}  % List all, until the test is not met - then just quit. Repeat until satisfied. If it is not never met, will list all records.
-- \def\doloopwhile#1#2#3{\doloopif{#1}{while}{#2}{#3}}% \doloopwhile{\Trida}{3.A}{\tableaction}  % List when the test is met, other just quit. 
-- 



% 5. \filelineaction  % implicit do \lineaction for all lines of current open CSV table
% \filelineaction{filename.csv}   % do \lineaction macro for all lines of specific CSV table (filename.csv)
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





]]


thirddata.handlecsv.string2context(string2print)



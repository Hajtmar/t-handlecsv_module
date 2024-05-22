@echo off
for %%f in (*.tex) do (context --purgeall "%%~nf.tex") 

/* rexx GIT commit */
/* Writes timestamp in REXXN1 */
/* Read file */
path = '.\cntl\rexxn1.rex'
file=.stream~new(path) 
file~open("read") 
drop file.
i=0
do while file~lines<>0  
    i=i+1
    file.i=file~linein
end
file~close
file.0=i 
/* Write file replacing timestamp */
file~open("both replace") 
timestamp = .dateTime~new~timeOfDay
do i=1 to file.0  
    if pos("timestamp - ",file.i) > 0 then do
        file.i='/* timestamp - 'timestamp '*/'
    end   
    file~lineout(file.i)  
end
file~close
'git config --global user.email drb1972@gmail.com'
'git config --global user.name Diego' 
'git commit -a -m "c1"' 
'git push'
exit
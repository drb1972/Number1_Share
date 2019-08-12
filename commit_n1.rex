/* rexx GIT commit            */
/* Writes timestamp in REXXN1 */
/* Check Modified elements    */
drop list_update.
stem = rxqueue("Create")
call rxqueue "Set", stem
'git diff --name-only | rxqueue ' stem
i = 0
say copies('=',25)
say 'Files to COMMIT & PUSH'
say copies('=',25)
do queued()
   /* respect upper or lowercase */
   parse caseless pull line 
   ext = upper(line)
   /* Exclude this file */
   if pos('COMMIT',ext) > 0 then iterate
   i=i+1
   if pos('.REX',ext) > 0 then do
      list_update.i = line
      say list_update.i
   end
end
list_update.0 = i /* # of elements to update */

if list_update.0 > 0 then do
   do i = 1 to list_update.0 
      /* read files */
      path = list_update.i
      file=.stream~new(path) 
      file~open("read") 
      drop file.
      k=0
      do while file~lines<>0  
         k=k+1
         file.k=file~linein
      end
      file~close
      file.0=k 
      /* Write file replacing timestamp */
      file~open("both replace") 
      timestamp = .dateTime~new
      do j=1 to file.0  
         if pos("timestamp - ",file.j) > 0 then do
            file.j='/* timestamp - 'timestamp '*/'
            say list_update.j '==> is going to be updated with timestamp'
         end   
         file~lineout(file.j)  
      end
      file~close
   end
end

'git config --global user.email drb1972@gmail.com'
'git config --global user.name Diego' 
'git commit -a -m "c1"' 
'git push'
exit

/* rexx GIT commit            */
/* Writes timestamp in REXXN1 */
/* Check Modified elements    */
drop list_update.
stem = rxqueue("Create")
call rxqueue "Set", stem
'git diff --name-only | rxqueue ' stem
say copies('=',25)
say 'Files to COMMIT & PUSH'
say copies('=',25)
i = 0
do queued()
   /* respect upper or lowercase */
   parse caseless pull line 
   say line
   ext = upper(line)
   /* Exclude this file */
   if pos('COMMIT',ext) > 0 then iterate
   if pos('.REX',ext) > 0 then do
      i=i+1
      list_update.i = line
   end
end
list_update.0 = i /* # of elements to update */
say copies('=',25)

if list_update.0 > 0 then do
   do i = 1 to list_update.0 
   /*dxr*/say 'list ' list_update.i 
      /* read files */
      path = list_update.i
      file=.stream~new(path) 
      file~open("read") 
      drop line.
      k=0
      do while file~lines<>0  
         k=k+1
         line.k=file~linein
      end
      file~close
      line.0=k 
      /* Write file replacing timestamp */
      file~open("both replace") 
      timestamp = .dateTime~new
      do j=1 to line.0  
         if pos("timestamp - ",line.j) > 0 then do
            line.j='/* timestamp - 'timestamp '*/'
            say list_update.i '==> is going to be updated with timestamp'
         end   
         file~lineout(line.j)  
      end
      file~close
   end
end

'git config --global user.email drb1972@gmail.com'
'git config --global user.name Diego' 
'git commit -a -m "c1"' 
'git push'
exit

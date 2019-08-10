/* rexx - Test N1 application */
user = 'xxxxxxxx'
do forever
   say 'Write date (aaaammdd)'
   pull date
   if length(date) <> 8 | datatype(date) <> 'NUM' then do
      say 'Wrong date'
      iterate
   end
   if date <> '' then leave
end
date = "'"date"'"
command = "'RODDI01.N1.PROD.REXX(REXXN1)'"
'bright tso issue cmd --ssm "ex 'command' 'date'"'
exit

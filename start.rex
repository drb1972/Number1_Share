/* rexx - Nuber1 task runner script */
TSOID='RODDI01'
/* STEPS are:           */
/*    Alloc             */
/*    Upload            */
/*    TestT_UK (in DEV)    */
/*    Install (in PROD) */
/*    TestP_UK (in PROD)   */
arg STEP
'cls'
filename_t = TSOID||'.N1.TEST.REXX'
filename_p = TSOID||'.N1.PROD.REXX'
master_uk  = TSOID||'.N1UK.MASTER'
/* master_us  = TSOID||'.N1US.MASTER' */
interpret call STEP
Exit

ALLOC:
   say copies('=',40)
   say '>> ALLOC - Create libraries'

   say copies('=',40)
   /* Create TEST.REXX file if doesn't exist */
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   'bright zos-files list data-set "'filename_t'" | rxqueue' stem
   if QUEUED() = 0 then do
      say 'Creating ' filename_t
      'bright zos-files create data-set-partitioned "'filename_t'"'
   end
   else do
      say filename_t 'Already exists'
   end
   call rxqueue "Delete", stem

   /* Create MASTERUK file if doesn't exist */
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   'bright zos-files list data-set "'master_uk'" | rxqueue' stem
   if QUEUED() = 0 then do
      say 'Creating ' master_uk
      'bright zos-files cre ps "'master_uk'" --rl 125 --bs 1250'
   end
   else do
      say master_uk 'Already exists'
   end
   call rxqueue "Delete", stem
   
   /* Create MASTERUS file if doesn't exist 
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   'bright zos-files list data-set "'master_us'" | rxqueue' stem
   if QUEUED() = 0 then do
      say 'Creating ' master_us
      'bright zos-files cre ps "'master_us'" --rl 125 --bs 12500'
   end
   else do
      say master_us 'Already exists'
   end
   call rxqueue "Delete", stem
   */
return

UPLOAD:
   say copies('=',40)
   say '>> UOLOAD - Upload libraries'
   say copies('=',40)
   say 'Uploading 'filename_t
   'bright files ul dir-to-pds "cntl" "'filename_t'"'
   say 'Uploading 'master_uk
   'bright files ul file-to-data-set "'listUKMaster.txt'" "'master_uk'"'
   /* say 'Uploading 'master_us
   'bright files ul file-to-data-set "'listUSMaster.txt'" "'master_us'"' */
return

TESTT_UK:
   env = 'TEST'
   say copies('=',40)
   say '>> TESTT_UK - TESTING in 'env
   say copies('=',40)
   call test1 
   call test2 
return

INSTALL:
   say copies('=',40)
   say '>> INSTALL - Install in PROD'
   say copies('=',40)
   /* Create PROD.REXX file if doesn't exist */
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   'bright zos-files list data-set "'filename_p'" | rxqueue' stem
   if QUEUED() = 0 then do
      empty_prod = 'Y'
      say 'Creating ' filename_p
      'bright zos-files create data-set-partitioned "'filename_p'"'
   end
   else do
      say filename_p 'Already exists'
   end
   call rxqueue "Delete", stem

    /* Create PROD.REXX.BACKUP file if doesn't exist */
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   filename_p_b = filename_p || '.BACKUP'
   'bright zos-files list data-set "'filename_p_b'" | rxqueue' stem
   if QUEUED() = 0 then do
      say 'Creating ' filename_p_b
      'bright zos-files create data-set-partitioned "'filename_p_b'"'
   end
   else do
      say filename_p_b 'Already exists'
   end
   call rxqueue "Delete", stem

   /* Copy REXXN1 from PROD to PROD.BACKUP */
   out = rxqueue("create")
   call rxqueue "Sete",out
   'bright zos-files list all-members "'filename_p_b'" | grep REXXN1' 
   if queued() > 0 then do
      call rxqueue "Delete", out
      out = rxqueue("Create")
      call rxqueue "Set",out 
      'bright zos-extended-files copy data-set ', 
      '"'filename_p'(REXXN1)" "'filename_p_b'(REXXN1)" | rxqueue' out
      do queued()
         pull line
         parse var line 'rc:' rrc
         if rc = 0 then do 
            say 'BACKUP copy succesful'
            leave
         end     
         else do 
            say 'ERROR ' rrc 
            leave
         end
      end   
      call rxqueue "Delete", out 
   end   

   /* Copy REXXN1 from TEST to PROD */
   out = rxqueue("Create")
   call rxqueue "Set",out 
   'bright zos-extended-files copy data-set ', 
   '"'filename_t'(REXXN1)" "'filename_p'(REXXN1)" | rxqueue' out
   do queued()
      pull line
      say '>> ' line
      parse var line 'rc:' rrc
      if rc = 0 then do 
         say 'Installation succesful'
         leave
      end     
      else do 
         say 'ERROR ' rrc
         leave
      end
   end   
   call rxqueue "Delete", out 
return

TESTP_UK:
   env = 'PROD'
   say copies('=',40)
   say '>> TESTP_UK - TESTING in 'env
   say copies('=',40)
   call test1 
   call test2 
   say copies('=',40)
   if test1 = 'OK' & test2 = 'OK' then say 'Tests in 'env 'OK'
   else do
      say 'Tests in 'env 'not OK'
      say 'Launching BACKOUT to restore PROD library'
      filename_p_b = filename_p || '.BACKUP'
      /* BACKOUT */
      if env = 'PROD' & empty_prod <> 'Y' then do
         /* Copy REXXN1 from PROD.BACKUP to PROD */
         out = rxqueue("Create")
         call rxqueue "Set",out 
         'bright zos-extended-files copy data-set ', 
         '"'filename_p_b'(REXXN1)" "'filename_p'(REXXN1)" | rxqueue' out
         do queued()
            pull line
            say '>> ' line
            parse var line 'rc:' rrc
            if rc = 0 then do 
               say 'Installation succesful'
               leave
            end     
            else do 
               say 'ERROR ' rrc
               leave
            end
         end   
         call rxqueue "Delete", out 



      end 
      exit 8 /* makes Jenkins stop */
   end
return

test1:
   say copies('=',40)
   say 'Beggining Test1...'
   say copies('=',40)
   say 'Expected result for 19600826: '
   say 'UK_Title : APACHE'
   say 'UK_Artist: SHADOWS' 
   say copies('=',40)
   test1 = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'19600826'"
   call test uk_title uk_artist
   if uk_title = 'APACHE' & uk_artist = 'SHADOWS' then test1 = 'OK'
   say 'TEST1 ' test1
return

test2:
   say copies('=',40)
   say 'Beggining Test2...'
   say copies('=',40)
   say 'Expected result for 18600826: '
   say 'NULL value'
   say copies('=',40)
   test2 = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'18600826'"
   call test uk_title uk_artist
   if uk_title = '' & uk_artist = '' then test2 = 'OK'
   say 'TEST2 ' test2
return

test:
   'bright tso issue cmd --ssm "ex 'command' 'param'" | rxqueue' stem
   uk_title  = ''
   uk_artist = ''
   do queued()
      rest = ''
      pull line
      if line = 'NULL' then do
         say 'NULL value'
         leave
      end
      parse var line 'UK_TITLE :' rest
      if rest <> '' then uk_title = rest
      parse var line 'UK_ARTIST:' rest
      if rest <> '' then uk_artist = rest
      if uk_title <> '' & uk_artist <> '' then do 
         say 'Result ==> UK_Title : ' uk_title
         say 'Result ==> UK_Artist: ' uk_artist
         leave
      end
   end       
   call rxqueue "Delete", stem
return uk_title uk_artist


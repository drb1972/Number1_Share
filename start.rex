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
/* In case I change my TSO password */
/*  
'bright profiles update zosmf-profile diego-zosmf' ,
'--user roddi01 --pass xxxxxxxx'
*/
/* [dxr] 
master_us  = TSOID||'.N1US.MASTER' 
   [dxr] */
interpret call STEP
Exit

PASS:
   /* To check if Profiles & password are ok */
   sw = 'N'
   stem = rxqueue("Create")
   /*dxr*/ 'bright profiles set zosmf zosmf-sr01brs'
   call rxqueue "Set",stem
   'bright profiles list zosmf --sc' /*dxr*/
   /*'bright tso issue command "TIME" | rxqueue' stem*/
   do queued()
      pull msg
      if pos('IKJ56650I',msg) > 0 then do
         sw = 'Y' 
         leave
      end   
   end   
   if sw = 'Y' then say 'Correct TSO access'
   else do
      say 'Check your credentials'
      exit 8
   end   
   call rxqueue "Delete", stem
return

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
   
   /* Create MASTERUS file if doesn't exist */
   /* [dxr] 
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
     [dxr] */
return

UPLOAD:
   say copies('=',40)
   say '>> UPLOAD - Upload libraries'
   say copies('=',40)
   
   say 'Uploading 'filename_t
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   'bright files ul dir-to-pds' , 
      '"cntl" "'filename_t'" | rxqueue' stem
   call rxqueue "Delete",stem
   stem = rxqueue("Create")
   call rxqueue "Set",stem
   say 'Uploading 'master_uk
   'bright files ul file-to-data-set' ,
      '"'listUKMaster.txt'" "'master_uk'" | rxqueue' stem
   call rxqueue "Delete",stem
   
   /* [dxr] 
   stem = rxqueue("Create")
   call rxqueue "Set",stem
      say 'Uploading 'master_us
   'bright files ul file-to-data-set' ,
      '"'listUSMaster.txt'" "'master_us'" | rxqueue' stem 
   call rxqueue "Delete",stem
      [dxr] */
return

TESTT_UK:
   env = 'TEST'
   say copies('=',40)
   say '>> TESTT_UK - TESTING in 'env
   say copies('=',40)
   call test1_uk 
   call test2_uk
   if test1_uk = 'OK' & test2_uk = 'OK' then say 'Tests in 'env 'OK'
   else do
      say 'Tests in 'env 'not OK'
      exit 8
   end   
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
   call rxqueue "Set",out
   'bright zos-files list all-members "'filename_p'" | rxqueue' out 
   if queued() > 0 then do
      call rxqueue "Delete", out
      out = rxqueue("Create")
      call rxqueue "Set",out 
      say 'Copying REXXN1 from 'filename_p 'to 'filename_p_b
      'bright zos-extended-files copy data-set ', 
      '"'filename_p'(REXXN1)" "'filename_p_b'(REXXN1)" | rxqueue' out
      success = 'N'
      do queued()
         pull line
         if pos('CODE WAS 0',line) > 0 then do
            success = 'Y'
            leave
         end   
      end
   end   
   if success = 'Y' then say 'Successful BackUp'
   else do 
      say 'ERROR ' line
      exit 8
   end
   call rxqueue "Delete", out 
   
   /* Copy REXXN1 from TEST to PROD */
   say 'Copying REXXN1 from 'filename_t 'to 'filename_p
   out = rxqueue("Create")
   call rxqueue "Set",out 
   'bright zos-extended-files copy data-set ', 
   '"'filename_t'(REXXN1)" "'filename_p'(REXXN1)" | rxqueue' out
   success = 'N'
   do queued()
      pull line
      if pos('CODE WAS 0',line) > 0 then do
         success = 'Y'
         leave
      end
   end   
   if success = 'Y' then say 'Successful Install'
   else do 
      say 'ERROR ' line
      exit 8
   end
   call rxqueue "Delete", out 
return

TESTP_UK:
   env = 'PROD'
   say copies('=',40)
   say '>> TESTP_UK - TESTING in 'env
   say copies('=',40)
   call test1_uk
   call test2_uk
   say copies('=',40)
   if test1_uk = 'OK' & test2_uk = 'OK' then say 'Tests in 'env 'OK'
   else do
      say 'Tests in 'env 'not OK'
      /* BACKOUT */
      if env = 'PROD' then do
         filename_p_b = filename_p || '.BACKUP'
         stem = rxqueue("create")
         call rxqueue "Sete",stem
         'bright zos-files list all-members "'filename_p_b'" | rxqueue' stem 
         if queued() > 0 then do
            pull member
            if member = 'REXXN1' then do
               member_found = 'Y'
               call rxqueue "Delete", stem
               say 'Launching BACKOUT to restore PROD library'
               /* Copy REXXN1 from PROD.BACKUP to PROD */
               out = rxqueue("Create")
               call rxqueue "Set",out 
               'bright zos-extended-files copy data-set ', 
               '"'filename_p_b'(REXXN1)" "'filename_p'(REXXN1)" | rxqueue' out
               success = 'N'
               do queued()
                  pull line 
                  if pos('CODE WAS 0',line) > 0 then do
                     success = 'Y'
                     leave
                  end
               end
               if success = 'Y' then say 'BackOut successful'
               else do 
                  say 'ERROR ' line
                  exit 8
               end
            end      /* if member  */  
            call rxqueue "Delete", out 
            if member_found <> 'Y' then say 'Member not found in 'filename_p_b 
         end         /* if queued() > 0 */
         else say 'Empty BackUp library'
      end            /* if env = PROD */
      exit 8         /* makes Jenkins stop */
   end               /* if Tests not ok */
return

test1_uk:
   say copies('=',40)
   say 'Beginning Test1...'
   say copies('=',40)
   say 'Expected result for 19600826: '
   say 'UK_Title : APACHE'
   say 'UK_Artist: SHADOWS' 
   say copies('=',40)
   test1_UK = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'19600826'"
   call test_uk uk_title uk_artist
   if uk_title = 'APACHE' & uk_artist = 'SHADOWS' then test1_uk = 'OK'
   /* uncomment the following line for practice2 */
   /*
   if env = 'PROD' then test1_uk = 'KO'
   */
   say 'TEST1 ' test1_uk
return

test2_uk:
   say copies('=',40)
   say 'Beginning Test2...'
   say copies('=',40)
   say 'Expected result for 18600826: '
   say 'NULL value'
   say copies('=',40)
   test2_UK = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'18600826'"
   call test_uk uk_title uk_artist
   if uk_title = '' & uk_artist = '' then test2_uk = 'OK'
   say 'TEST2 ' test2_uk
return

test_uk:
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

/* For later use */

TESTT_US:
   env = 'TEST'
   say copies('=',40)
   say '>> TESTT_US - TESTING in 'env
   say copies('=',40)
   call test1_us
   call test2_us
   if test1_us = 'OK' & test2_us = 'OK' then say 'Tests in 'env 'OK'
   else do
      say 'Tests in 'env 'not OK'
      exit 8
   end
return

TESTP_US:
   env = 'PROD'
   say copies('=',40)
   say '>> TESTP_US - TESTING in 'env
   say copies('=',40)
   call test1_us
   call test2_us
   say copies('=',40)

   if test1_us = 'OK' & test2_us = 'OK' then say 'Tests in 'env 'OK'
   else do
      say 'Tests in 'env 'not OK'
      /* BACKOUT */
      if env = 'PROD' then do
         filename_p_b = filename_p || '.BACKUP'
         stem = rxqueue("create")
         call rxqueue "Sete",stem
         'bright zos-files list all-members "'filename_p_b'" | rxqueue' stem 
         if queued() > 0 then do
            pull member
            if member = 'REXXN1' then do
               member_found = 'Y'
               call rxqueue "Delete", stem
               say 'Launching BACKOUT to restore PROD library'
               /* Copy REXXN1 from PROD.BACKUP to PROD */
               out = rxqueue("Create")
               call rxqueue "Set",out 
               'bright zos-extended-files copy data-set ', 
               '"'filename_p_b'(REXXN1)" "'filename_p'(REXXN1)" | rxqueue' out
               success = 'N'
               do queued()
                  pull line 
                  if pos('CODE WAS 0',line) > 0 then do
                     success = 'Y'
                     leave
                  end
               end
               if success = 'Y' then say 'BackOut successful'
               else do 
                  say 'ERROR ' line
                  exit 8
               end
            end      /* if member  */  
            call rxqueue "Delete", out 
            if member_found <> 'Y' then say 'Member not found in 'filename_p_b 
         end         /* if queued() > 0 */
         else say 'Empty BackUp library'
      end            /* if env = PROD */
      exit 8         /* makes Jenkins stop */
   end               /* if Tests not ok */
return

test1_us:
   say copies('=',40)
   say 'Beginning Test1...'
   say copies('=',40)
   say 'Expected result for 19600826: '
   say "US_Title : IT'S NOW OR NEVER"
   say 'US_Artist: ELVIS PRESLEY' 
   say copies('=',40)
   test1_US = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'19600826'"
   call test_us us_title us_artist
   if us_title  = "IT'S NOW OR NEVER" & ,
      us_artist = 'ELVIS PRESLEY' then test1_us = 'OK'
   say 'TEST1 ' test1_us
return

test2_us:
   say copies('=',40)
   say 'Beggining Test2...'
   say copies('=',40)
   say 'Expected result for 18600826: '
   say 'NULL value'
   say copies('=',40)
   test2_US = 'KO'
   stem = rxqueue("Create") 
   call rxqueue "Set", stem
   command = "'RODDI01.N1."||env||".REXX(REXXN1)'"
   param   = "'18600826'"
   call test_us us_title us_artist
   if us_title = '' & us_artist = '' then test2_us = 'OK'
   say 'TEST2 ' test2_us
return

test_us:
   'bright tso issue cmd --ssm "ex 'command' 'param'" | rxqueue' stem
   us_title  = ''
   us_artist = ''
   do queued()
      rest = ''
      pull line
      if line = 'NULL' then do
         say 'NULL value'
         leave
      end
      parse var line 'US_TITLE :' rest
      if rest <> '' then us_title = rest
      parse var line 'US_ARTIST:' rest
      if rest <> '' then us_artist = rest
      if us_title <> '' & us_artist <> '' then do 
         say 'Result ==> US_Title : ' us_title
         say 'Result ==> US_Artist: ' us_artist
         leave
      end
   end       
   call rxqueue "Delete", stem
return us_title us_artist

PLUGINS:
'node --version'
'npm --version'
'bright --version'
'npm install'
/* Needed to install plugins the first time */
/*'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\zos-extended-files.tgz"'*/
/* 'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\zos-extended-jobs.tgz"'
'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\secure-credential-store.tgz"'
'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\ops.tgz"'
'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\filemasterplus.tgz"'
'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\endevor.tgz"'
'bright plugins install "C:\Users\dr891415\AppData\Roaming\CA\Brightside EE\src\cics.tgz"'
 */'bright plugins list'
return


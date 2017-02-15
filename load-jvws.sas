/****************************************************/
/*                                                  */
/*  Module purpose:                                 */
/*                                                  */
/*      Convert JVWS csv into SAS dataset           */
/*                                                  */
/****************************************************/

/*--------------------------------------------------*/
/*  1. Import CSV into SAS dataset                  */
/*--------------------------------------------------*/

FILENAME REFFILE 'D:/Seneca College/Winter 2017/ZLAS Hackathon/[ZLAS]_SAS_Big_Data_Hackathon__Problem_+_Datasets_+_Instructions/SAS Hack Competition/JVWS_untidy_dataset.csv';

PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    OUT=jvws_raw;
    GETNAMES=YES;
    GUESSINGROWS=200;
RUN;

/*--------------------------------------------------*/
/*  2. Check non-numerics in the mean_value field   */
/*--------------------------------------------------*/

proc freq data=jvws_raw;
    where not anydigit(substr(mean_value,1,1));
    table mean_value;
run;

/*--------------------------------------------------*/
/*  3. Convert non-numerics to special missing      */
/*     Prepare for transpose                        */
/*--------------------------------------------------*/

data jvws_clean;
    length varname $ 32;
    
    set jvws_raw(rename=(mean_value=mean_str));
    
    Fchar = substr( mean_str, 1, 1 );
    
    if mean_str = '..'  then mean_value = .d ;
    else if fchar = 'F' then mean_value = .f ;
    else if fchar = 'x' then mean_value = .x ;
    else                     mean_value = input( mean_str, best32. );

    if      statistic =: 'Average offered hourly wage' then varname = 'wage';
    else if statistic =: 'Job vacancies'               then varname = 'vacancy';
    
    if      repyr = 2015 then varname = cats( varname, '_2015' );
    else if repyr = 2016 then varname = cats( varname, '_2016' );

    drop mean_str;
run;

proc means data=jvws_clean n nmiss mean std;
    var mean_value;
run;

proc sort data=jvws_clean;
    by noc_code varname;
run;

/*--------------------------------------------------*/
/*  4. Transpose to final structure:                */
/*     each noc_code one row, 4 values              */
/*--------------------------------------------------*/

proc transpose data=jvws_clean(keep=noc_code varname mean_value)
    out=jvws;
    by noc_code;
    id varname;
    var mean_value;
run;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

*--- counting is easier ---;
proc freq data=jvws;
    table wage_2016 / missing;
run;

*--- arithmetic unaffected ---;
proc means data=jvws n nmiss mean std;
    var wage_2016;
run;

proc format;
    value wage
        .d = 'M1'
        .f = 'M2'
        .x = 'M3'
        0 - 10 = '0-10'
        10 - 20 = '10-20'
        20 - 30 = '20-30'
        30 - 40 = '30-40'
        40 - 50 = '40-50'
        50 - 60 = '50-60'
        60 - 70 = '60-70'
        70 - 80 = '70-80'
        80 - 90 = '80-90'
        90 - 100 = '90 - 100'
        100 - high = '100+'
    ;
run;

proc summary data=jvws missing nway;
    class wage_2016; format wage_2016 wage. ;
    output out=cnt;
run;

proc print data=cnt;
run;

proc sgplot data=jvws;
    hbar wage_2016 / datalabel ;
    format wage_2016 wage. ; 
    *yaxis type=discrete;   
run;

proc sgplot data=jvws;
    hbar wage_2016 / datalabel missing;
    format wage_2016 wage. ; 
    *yaxis type=discrete;   
run;

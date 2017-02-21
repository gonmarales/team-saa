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

FILENAME REFFILE "&apprdir/Source/JVWS_untidy_dataset.csv";

PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    OUT=jvws_raw;
    GETNAMES=YES;
    GUESSINGROWS=200;
RUN;

/*------------------------------------------------------*/
/*  2. Check non-numerics in the mean_value field       */
/*------------------------------------------------------*/

proc freq data=jvws_raw;
    where not anydigit(substr(mean_value,1,1));
    table mean_value;
run;

/*------------------------------------------------------*/
/*  3. Convert non-numerics to special missing          */
/*------------------------------------------------------*/

data jvws_clean;
    length varname $ 32;
    
    set jvws_raw(rename=(mean_value=mean_str));
    
    Fchar = substr( mean_str, 1, 1 );
    
    if mean_str = '..'  then mean_value = .d ;
    else if fchar = 'F' then mean_value = .f ;
    else if fchar = 'x' then mean_value = .x ;
    else                     mean_value = input( mean_str, best32. );

    drop mean_str;
run;

proc sort;
    by noc_code repyr;
run;

/*------------------------------------------------------*/
/*  4. Create jvws1: noc, yearly metrics as variables   */
/*------------------------------------------------------*/

*--- create variable name ---;
data temp1;
    length varname $ 32;
    
    set jvws_clean;
    
    
    if      statistic =: 'Average offered hourly wage' then varname = 'wage';
    else if statistic =: 'Job vacancies'               then varname = 'vacancy';
    
    if      repyr = 2015 then varname = cats( varname, '_2015' );
    else if repyr = 2016 then varname = cats( varname, '_2016' );
run;

*--- transpose metrics column into row ---;
proc transpose data=temp1(keep=noc_code varname mean_value)
    out=appr.jvws1(drop=_name_);
    by noc_code;
    id varname;
    var mean_value;
run;

/*------------------------------------------------------*/
/*  5. Create jvws2: noc by year, metrics as variables  */
/*------------------------------------------------------*/

*--- create variable name ---;
data temp1;
    length varname $ 32;
    
    set jvws_clean;
    
    if      statistic =: 'Average offered hourly wage' then varname = 'wage';
    else if statistic =: 'Job vacancies'               then varname = 'vacancy';
run;

*--- transpose metrics column into row ---;
proc transpose data=temp1(keep=noc_code repyr varname mean_value)
    out=appr.jvws2(drop=_name_);
    by noc_code repyr;
    id varname;
    var mean_value;
run;




/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

/*  this is all to illustrate, remove from final    */

*--- counting is easier ---;
proc freq data=appr.jvws1;
    table wage_2016 / missing;
run;

*--- arithmetic unaffected ---;
proc means data=appr.jvws1 n nmiss mean std;
    var wage_2016;
run;

*--- easier grouped summary ---;
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

proc summary data=appr.jvws1 missing nway;
    class wage_2016; format wage_2016 wage. ;
    output out=cnt;
run;

proc print data=cnt;
run;

*--- sgplot doesn not like multiple missing ---;
proc sgplot data=appr.jvws1;
    hbar wage_2016 / datalabel ;
    format wage_2016 wage. ; 
run;

*--- can interject data step to solve problem ---;

data cnt1;
    set cnt;
    cat = put( wage_2016, wage. );
run;

proc sgplot data=cnt1;
    hbar cat / response=_freq_ datalabel;
    label cat='Wage Category';
run;


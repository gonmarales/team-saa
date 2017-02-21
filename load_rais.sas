/****************************************************/
/*                                                  */
/*  Module purpose:                                 */
/*                                                  */
/*      Convert rais csv into SAS dataset           */
/*                                                  */
/****************************************************/
/*--------------------------------------------------*/
/*  1. Import CSV into SAS dataset                  */
/*--------------------------------------------------*/

FILENAME REFFILE "&apprdir\Source\RAIS_dataset_suppressed.csv";

PROC IMPORT DATAFILE=REFFILE DBMS=CSV REPLACE OUT=rais_raw;
    GETNAMES=YES;
    GUESSINGROWS=200;
RUN;

/*--------------------------------------------------*/
/*  2. Check non-numerics in the mean_value field   */
/*--------------------------------------------------*/
proc freq data=rais_raw;
    where not anydigit(substr(mean_age, 1, 1));
    table mean_age;
run;

/*--------------------------------------------------*/
/*  3. Convert non-numerics to special missing      */
/*     Prepare for transpose                        */
/*--------------------------------------------------*/
data appr.rais;
    set rais_raw(rename=(reg_status = reg_status_str mean_age=mean_age_str sd_age=sd_age_str 
        total_NA=total_NA_str total_cont=total_cont_str total_comp=total_comp_str 
        total_disc=total_disc_str mean_reg_dur=mean_reg_dur_str mean_date_reg=mean_date_reg_str));
    array var_list {7} mean_age_str sd_age_str total_NA_str total_cont_str 
        total_comp_str total_disc_str mean_reg_dur_str  ;
    array var_list_new {7} mean_age sd_age total_NA total_cont total_comp 
        total_disc mean_reg_dur ;
    
    do i=1 to 7;
        Fchar=substr(var_list[i], 1, 1);
                
        if var_list[i]='..' then
            var_list_new[i]=.d;
        else if var_list[i]='F' then
            var_list_new[i]=.f;
        else if var_list[i]='x' then
            var_list_new[i]=.x;
        else if fchar = 'N' then var_list_new[i] = .n ;
        else if fchar = '.' then var_list_new[i] = .z ;
        else
            var_list_new[i]=input(var_list[i], best32.);
    end;

    dchar = substr(mean_date_reg_str, 1, 1);
    if dchar  = 'x' then 
            mean_date_reg=.x;
    else if dchar  = '0' then mean_date_reg = .n ;
    else 
        mean_date_reg=input(mean_date_reg_str, yymmdd8.);
        format mean_date_reg date10.;
        
    if reg_status_str=: 'Already registered (beginning of report period)' then
        reg_status='Registered';
    else if reg_status_str=: 'New registration (during report period)' then
        reg_status='New';
    else if reg_status_str=: 'Reinstatement (during report period)' then
        reg_status='Reinstated';
    else if reg_status_str=: 'Not applicable' then
        reg_status='NA';

    drop mean_age_str sd_age_str reg_status_str total_NA_str total_cont_str 
        total_comp_str total_disc_str mean_reg_dur_str  mean_date_reg_str fchar dchar i;
run;

proc freq data=appr.rais;
    table reg_status / missing;
run;

/*--------------------------------------------------*/
/*  4. Format mean_age into numeric                 */
/*     bins identified from CANSIM database         */
/*--------------------------------------------------*/
proc format ;
    value f_mean_age
        .x = 'Unknown' 
        0 - 20='Under 20' 
        20 - 25='20-24' 
        25 - 30='25-29' 
        30 - 35='30-34' 
        35 - 40='35-39' 
        40 - 45='40-44' 
        45 - 50='45-49' 
        50 - 100='Above 50';
run;

proc summary data=appr.rais missing nway;
    class mean_age;
    format mean_age f_mean_age.;
    output out=cnt;
run;

title 'Frequency of Age groups';

proc sgplot data=appr.rais;
    hbar mean_age / datalabel;
    format mean_age f_mean_age.;
    *yaxis type=discrete;
run;

title 'Frequency of Age groups with missing data';

proc sgplot data=appr.rais;
    hbar mean_age / datalabel missing;
    format mean_age f_mean_age.;
    *yaxis type=discrete;
run;

title 'Frequency of Year wise data';
proc sgplot data=appr.rais;
    hbar mean_date_reg / datalabel;
    format mean_date_reg YEAR.;
run;

title 'Frequency of Year wise data with missing data';
proc sgplot data=appr.rais;
    hbarbasic mean_date_reg / datalabel missing;
    format mean_date_reg YEAR.;
run;

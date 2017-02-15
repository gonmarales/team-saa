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
FILENAME REFFILE 'D:/Seneca College/Winter 2017/ZLAS Hackathon/[ZLAS]_SAS_Big_Data_Hackathon__Problem_+_Datasets_+_Instructions/SAS Hack Competition/RAIS_dataset_suppressed.csv';

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
/*  3. Convert the date format in mean_date_field   */
/*--------------------------------------------------*/

data rais_updated;
	set rais_raw;
	mean_date_reg_str=input(mean_date_reg, yymmdd8.);
	format mean_date_reg_str date10.;
	
run;

/*--------------------------------------------------*/
/*  4. Convert non-numerics to special missing      */
/*     Prepare for transpose                        */
/*--------------------------------------------------*/
data rais;
	set rais_raw(rename=(mean_age=mean_age_str sd_age=sd_age_str 
		total_NA=total_NA_str total_cont=total_cont_str total_comp=total_comp_str 
		total_disc=total_disc_str));
	length varname $ 32;
	array var_list {6} mean_age_str sd_age_str total_NA_str total_cont_str 
		total_comp_str total_disc_str ;
	array var_list_new {6} mean_age sd_age total_NA total_cont total_comp 
		total_disc ;
	Fchar=substr(mean_age_str, 1, 1);
	
	do i=1 to 6;
		put var_list[i];
		if var_list[i]='..' then
			var_list_new[i]=.d;
		else if var_list[i]='F' then
			var_list_new[i]=.f;
		else if var_list[i]='x' then
			var_list_new[i]=.x;
		 else if mean_str = 'NaN' then mean_age = .y ;
    	else
			var_list_new[i]=input(var_list[i], best32.);
	end;

	if reg_status=: 'Already registered (beginning of report period)' then
		varname='Registered';
	else if reg_status=: 'New registration (during report period)' then
		varname='New';
	else if reg_status=: 'Reinstatement (during report period)' then
		varname='Reinstated';
	else if reg_status=: 'Not applicable' then
		varname='NA';
run;

proc freq data=rais;
	table reg_status / missing;
run;

/*--------------------------------------------------*/
/*  5. Format mean_age into numeric                 */
/*     bins identified from CANSIM database         */
/*--------------------------------------------------*/
proc format ;
	value f_mean_age
        .x='M1' 
        0 - 20='Under 20' 
        20 - 25='20-24' 
        25 - 30='25-29' 
		30 - 35='30-34' 
		35 - 40='35-39' 
		40 - 45='40-44' 
		45 - 50='45-49' 
		50 - 100='Above 50';
run;

proc summary data=rais missing nway;
	class mean_age;
	format mean_age f_mean_age.;
	output out=cnt;
run;

title 'Frequency of Age groups';

proc sgplot data=rais;
	hbar mean_age / datalabel;
	format mean_age f_mean_age.;
	*yaxis type=discrete;
run;

title 'Frequency of Age groups with missing data';

proc sgplot data=rais;
	hbar mean_age / datalabel missing;
	format mean_age f_mean_age.;
	*yaxis type=discrete;
run;


/*--------------------------------------------------*/
/*  6. Clean up data  				               */
/*          									  */
/*--------------------------------------------------*/
data raisfinal;
set rais(keep=repyr	reg_status	appr_trade_code	appr_trade_name	comp_vol	
			gender	total_reg	mean_age	sd_age	total_NA	total_cont	total_comp	
			total_disc	mean_reg_dur	mean_date_reg);
run;



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

FILENAME REFFILE "&apprdir\Source\OCTAA_chart.csv";
/*--------------------------------------------------*/
/*  2. Clean up                                     */
/*--------------------------------------------------*/
data WORK.OCTAA_RAW;
	%let _EFIERR_ = ;

	/* set the ERROR detection macro variable */
	infile REFFILE delimiter=',' MISSOVER DSD lrecl=3276 firstobs=2;
	informat appr_trade_name $42.;
	informat appr_trade_code $4.;
	informat noc_code $15.;
	informat appr_sector $6.;
	informat appr_ratio $1.;
	informat tax_train_cred $1.;
	informat fact_sheets $1.;
	informat red_seal $1.;
	informat cofq $1.;
	informat otj_hours $8.;
	informat in_class_hours best32.;
	informat train_std_year $15.;
	informat curr_std_year $15.;
	informat trade_board $1.;
	informat acad_entry_req $30.;
	format appr_trade_name $42.;
	format appr_trade_code $4.;
	format noc_code $12.;
	format appr_sector $6.;
	format appr_ratio $1.;
	format tax_train_cred $1.;
	format fact_sheets $1.;
	format red_seal $1.;
	format cofq $1.;
	format otj_hours $8.;
	format in_class_hours best12.;
	format train_std_year $15.;
	format curr_std_year $15.;
	format trade_board $1.;
	format acad_entry_req $30.;
	input appr_trade_name $
                        appr_trade_code $
                        noc_code appr_sector $
                        appr_ratio $
                        tax_train_cred $
                      	fact_sheets $
                    	red_seal $
                      	cofq $
                      	otj_hours in_class_hours 
						train_std_year $ curr_std_year$ trade_board $
                      	acad_entry_req $;

	if _ERROR_ then
		call symputx('_EFIERR_', 1);

	/* set ERROR detection macro variable */
run;

data appr.octaa;
    set octaa_raw(rename=(train_std_year=train_std_year_str curr_std_year=curr_std_year_str  
    							noc_code=noc_code_str acad_entry_req=acad_entry_req_str otj_hours=otj_hours_str));
    array var_list {4} train_std_year_str  curr_std_year_str  noc_code_str otj_hours_str;
    array var_list_new {4} train_std_year  curr_std_year  noc_code otj_hours;
    
    do i=1 to 4;
        Fchar=substr(var_list[i], 1, 1);
                
        if Fchar='..' then var_list_new[i]=.d;
        else if Fchar='x' then var_list_new[i]=.x;
        else if fchar = 'N' then var_list_new[i] = .n ;
        else if fchar = '.' then var_list_new[i] = .z ;
        else
           var_list_new[i]=input(var_list[i], best32.);
    end;

     if      indexw(acad_entry_req_str,'Qualification + 1 year') then acad_entry_req= 'C/Q+1';
     else if indexw(acad_entry_req_str,'Qualification')          then acad_entry_req= 'C/Q';
     else                                                         acad_entry_req= acad_entry_req_str;

     drop acad_entry_req train_std_year_str  curr_std_year_str  noc_code_str fchar i otj_hours_str;
run;


title 'Frequency of On-the-job training hours with missing data';

proc sgplot data=appr.octaa;
    hbar otj_hours / datalabel missing;
    format otj_hours;
    *yaxis type=discrete;
run;

proc freq data=appr.octaa;
    table _character_ / missing;
run;

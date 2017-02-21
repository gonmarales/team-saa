/****************************************************/
/*                                                  */
/*  Module purpose:                                 */
/*                                                  */
/*      Qn9 Driving factors for Completion rate     */
/*                                                  */
/****************************************************/
ods graphics / imagemap=off;

/*------------------------------------------------------*/
/*  1. Summary Statistics - understand the distribution */
/*------------------------------------------------------*/

proc univariate data=APPR.RAIS_FINAL vardef=df noprint;
	var repyr total_reg mean_age sd_age total_NA total_cont total_comp total_disc 
		mean_reg_dur mean_date_reg otj_hours in_class_hours train_std_year curr_std_year 
		noc_code wage vacancy appr_pub_tdas appr_priv_tdas comp_rate comp_rate1 comp_rate2 discon_rate otj_hours;
	histogram comp_rate comp_rate1 comp_rate2;
run;


/*------------------------------------------------------*/
/*  2. N way ANOVA - Base test with no interaction      */
/*------------------------------------------------------*/

proc glmselect data=APPR.RAIS_FINAL outdesign(addinputvars)=reg_design;
class appr_trade_name appr_trade_code comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal cofq	trade_board acad_entry_req_str;
model comp_rate=mean_age total_cont total_disc 
		mean_reg_dur in_class_hours train_std_year curr_std_year 
		 wage vacancy appr_pub_tdas	otj_hours comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal cofq	trade_board acad_entry_req_str / showpvalues selection=backward(select=bic) hierarchy=single;
run;

proc glm data =APPR.RAIS_FINAL plot(only maxpoints=none)=(diagnostics(unpack) intplot);
	class appr_trade_name appr_trade_code comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal cofq	trade_board acad_entry_req_str;
	model comp_rate= &_GLSIND / ss1 ss3 solution;
run;


/*------------------------------------------------------*/
/*  3. Forming bins to convert continuous to categorical*/
/*------------------------------------------------------*/


data appr.rais_final_binned;
	set appr.rais_final;
	length total_cont_bin $20 otj_hours_bin $20;
	
	  if mean_age = .x then mean_age_bin =  'Unknown' ;
      else if mean_age > 0 and mean_age < 20 then mean_age_bin =  'Under 20';
      else if mean_age > 20 and mean_age < 25 then mean_age_bin =  '20-24';
      else if mean_age > 25 and mean_age < 30 then mean_age_bin =  '25-29';
      else if mean_age > 30 and mean_age < 35 then mean_age_bin =  '30-34';
      else if mean_age > 35 and mean_age < 40 then mean_age_bin =  '35-39';
      else if mean_age > 40 and mean_age < 45 then mean_age_bin =  '40-44';
      else if mean_age > 45 and mean_age < 50 then mean_age_bin =  '45-49';
      else if mean_age > 50 and mean_age < 100 then mean_age_bin =  'Above 50';
      
	if total_cont = 0 then total_cont_bin = 'Not Continued';
	else if total_cont > 0  and total_cont <= 500 then total_cont_bin = '0 - 500';
	else if total_cont > 500 and total_cont <= 5000 then total_cont_bin = '500 - 5000';
	else if total_cont > 5000 and total_cont <= 10000 then total_cont_bin = '5000 - 10000';
	else total_cont_bin = 'Above 10000';
		
	if otj_hours = '0' then otj_hours_bin = 'No Hours';
	else if otj_hours > 500 and otj_hours <= 3500 then otj_hours_bin = 'Less hours(<3500)';
	else if otj_hours > 3500 and otj_hours <= 5000 then otj_hours_bin = 'Average hours(<5000)';
	else if otj_hours > 5000 and otj_hours <= 6500 then otj_hours_bin = '5000 - 6500';
	else otj_hours_bin = 'Above 9000';
	
	if wage = '0' then wage = 'No wage';
	else if wage > 11 and wage <= 15 then wage_bin = '11-15';
	else if wage > 15 and wage <= 20 then wage_bin = '15-20';
	else if wage > 20 and wage <= 25 then wage_bin = '20-25';
	else if wage > 25 and wage <= 30 then wage_bin = '25-30';
	else wage_bin = 'Above 30';	
	
	if vacancy = '0' then vacancy = 'No vacancy';
	else if vacancy > 1 and vacancy <= 300 then vacancy_bin = '1 - 300';
	else if vacancy > 300 and vacancy <= 1000 then vacancy_bin = '300 - 1000';
	else if vacancy > 1000 and vacancy <= 3000 then vacancy_bin = '1000 - 3000';
	else if vacancy > 3000 and vacancy <= 5000 then vacancy_bin = '3000 - 5000';
	else vacancy_bin = 'Above 5000';	
	
	
	
run;



/*------------------------------------------------------*/
/*  4. N way ANOVA - Binned test with no interaction      */
/*------------------------------------------------------*/
title 'PROC GLM - binned data';
title 'Relationship between Completion rate with rais_final binned';
proc glmselect data=APPR.rais_final_binned outdesign(addinputvars)=reg_design;
class comp_vol gender appr_sector mean_age_bin otj_hours_bin 
		appr_ratio tax_train_cred fact_sheets vacancy_bin red_seal wage_bin otj_hours_bin 
		trade_board mean_age_bin;
model comp_rate=mean_age_bin total_disc 
		mean_reg_dur in_class_hours train_std_year curr_std_year 
		 wage_bin vacancy_bin appr_pub_tdas	otj_hours_bin comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal trade_board/ showpvalues selection=backward(select=bic) hierarchy=single;
run;

proc glm data =APPR.rais_final_binned plot(only maxpoints=none)=(diagnostics(unpack) intplot);
	class comp_vol gender appr_sector mean_age_bin otj_hours_bin 
		appr_ratio tax_train_cred fact_sheets vacancy_bin red_seal wage_bin otj_hours_bin 
		trade_board mean_age_bin;
	model comp_rate= &_GLSIND / ss1 ss3 solution;
run;


/*------------------------------------------------------*/
/*  5. N way ANOVA - Base test with interaction      	*/
/*------------------------------------------------------*/
data appr.rais_interaction;
	set appr.rais_final_binned(keep=comp_rate appr_trade_code comp_vol gender reg_status appr_sector	
		appr_ratio tax_train_cred fact_sheets vacancy_bin red_seal wage_bin otj_hours_bin trade_board acad_entry_req_str total_cont_bin
mean_reg_dur in_class_hours curr_std_year noc_code wage_bin
								vacancy_bin appr_pub_tdas otj_hours_bin comp_vol reg_status appr_sector
								appr_ratio fact_sheets trade_board total_cont_bin);
run;

title 'PROC GLM - binned data';
title 'Relationship between Completion rate with interactions';
proc glmselect data=APPR.rais_final_binned outdesign(addinputvars)=reg_design;
class repyr appr_trade_code comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal vacancy_bin wage_bin 
		otj_hours_bin trade_board acad_entry_req_str;
model comp_rate=mean_age  
		mean_reg_dur in_class_hours curr_std_year 
		noc_code wage_bin  appr_pub_tdas otj_hours_bin comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal trade_board 
		acad_entry_req_str gender*red_seal appr_sector*vacancy_bin 
		red_seal*wage_bin red_seal*vacancy_bin 
		/ showpvalues selection=backward(select=bic) hierarchy=single;
run;

proc glm data =APPR.rais_final_binned plot(only maxpoints=none)=(diagnostics(unpack) intplot);
	class repyr appr_trade_code comp_vol gender appr_sector vacancy_bin wage_bin otj_hours_bin
		appr_ratio tax_train_cred fact_sheets red_seal cofq	trade_board acad_entry_req_str;
	model comp_rate= &_GLSIND / ss1 ss3 solution;
run;


/*-----------------------------------------------------------------------*/
/*  5. N way ANOVA - Binned test with interaction  and Transformation    */
/*-----------------------------------------------------------------------*/


data appr.rais_final_transformed;
	set appr.rais_final_binned;
	
	comp_rate1 = comp_rate * 100;
	if comp_rate1 = 0 then comp_rate2 = 0;
	else comp_rate2 = log(comp_rate1);
	
	discon_rate1 = discon_rate * 100;
	if discon_rate1 = 0 then discon_rate2 = 0;
	else discon_rate2 = log(discon_rate1);
	
run;

title 'PROC GLM - transformed data';
title 'Relationship between Completion rate with interactions';
proc glmselect data=APPR.rais_final_transformed outdesign(addinputvars)=reg_design;
class repyr appr_trade_code comp_vol gender appr_sector	
		appr_ratio tax_train_cred cofq fact_sheets red_seal vacancy_bin wage_bin 
		otj_hours_bin trade_board;
model discon_rate2=mean_age  
		mean_reg_dur in_class_hours curr_std_year 
		 wage_bin  appr_pub_tdas otj_hours_bin comp_vol gender appr_sector	
		appr_ratio tax_train_cred cofq  fact_sheets red_seal trade_board 
		 gender*red_seal appr_sector*vacancy_bin 
		red_seal*wage_bin red_seal*vacancy_bin 
		/ showpvalues selection=backward(select=bic) hierarchy=single;
run;

proc glm data =APPR.rais_final_transformed plot(only maxpoints=none)=(diagnostics(unpack) intplot);
	class repyr appr_trade_code comp_vol gender appr_sector vacancy_bin wage_bin otj_hours_bin
		appr_ratio tax_train_cred cofq fact_sheets red_seal cofq	trade_board;
	model discon_rate2= &_GLSIND / ss1 ss3 solution;
run;



/*-------------------------------------------*/
/*  6. Logistic - Binned data 				*/
/*------------------------------- -----------*/


data appr.rais_final_logistic;
	set appr.rais_final_binned;
	comp_rate1 = comp_rate * 100;
	if comp_rate1 = 0 then comp_rate_binary = 0;
	else comp_rate_binary = 1;
run;

proc logistic data=appr.rais_final_logistic  plots(unpack maxpoints=none)=all;
class appr_trade_code comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal vacancy_bin wage_bin 
		otj_hours_bin trade_board acad_entry_req_str;
model comp_rate_binary(event = '1') =  
		mean_reg_dur in_class_hours curr_std_year 
		noc_code wage_bin vacancy_bin appr_pub_tdas	otj_hours_bin comp_vol gender appr_sector	
		appr_ratio tax_train_cred fact_sheets red_seal trade_board
		 / link=logit technique=fisher rsquare lackfit ctable stb expb corrb pcorr;
run;

quit;
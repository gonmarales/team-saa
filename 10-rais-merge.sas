/*  merge rais and octaa    */

proc sort data=appr.rais;
    by appr_trade_code;
run;

proc freq;
    tables appr_trade_code / missing;
run;

proc sort data=appr.octaa;
    by appr_trade_code;
run;

proc freq;
    tables appr_trade_code / missing;
run;

data rais1;
    merge appr.rais(in=in_rais) appr.octaa(in=in_octaa) end=eof;
    by appr_trade_code;

    if      in_rais=1 and in_octaa=0 and first.appr_trade_code then put 'No octaa  ' appr_trade_code;
    else if in_rais=0 and in_octaa=1 and first.appr_trade_code then put 'No Rais   ' appr_trade_code;

    if in_rais then output;
run;

/*  merge rais and jvws    */

proc sort data=rais1;
    by noc_code;
run;

proc freq;
    tables noc_code / missing;
run;

proc sort data=appr.jvws2;
    by noc_code;
run;

proc freq;
    tables noc_code / missing;
run;

data rais2015;
    merge rais1(in=in_rais) appr.jvws2(in=in_jvws ) end=eof;
    by noc_code;

    if      in_rais=1 and in_jvws=0 and first.noc_code then put 'No jvws  ' noc_code;
    else if in_rais=0 and in_jvws=1 and first.noc_code then put 'No Rais  ' noc_code;

    if in_rais then output;
run;


/*  merge rais and appren */

proc sort data=rais2015;
    by appr_trade_code;
run;

proc freq;
    tables appr_trade_code / missing;
run;

proc sort data=appr.appren;
    by appr_trade_code;
run;

proc freq;
    tables appr_trade_code / missing;
run;

data appr.raisfinal_2015;
    merge rais2015(in=in_rais where=(total_reg > 5)) appr.appren(in=in_appren) end=eof;
    by appr_trade_code;

    if      in_rais=1 and in_appren=0 and first.appr_trade_code then put 'No appren ' appr_trade_code;
    else if in_rais=0 and in_appren=1 and first.appr_trade_code then put 'No Rais  ' appr_trade_code;

    if in_rais then output;
run;


data appr.rais_final;
	set appr.raisfinal_2015;
	
	comp_rate = total_comp/total_reg;
	discon_rate = total_disc/total_reg;
	comp_rate1 = comp_rate * 100;
	
run;

proc export data=appr.rais_final   dbms=xlsx   outfile="&apprdir/data/maesdfinal.xlsx"   replace;
run;







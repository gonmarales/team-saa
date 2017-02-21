/****************************************************/
/*                                                  */
/*  Module purpose:                                 */
/*                                                  */
/*      Convert appren csv into SAS dataset           */
/*                                                  */
/****************************************************/
/*--------------------------------------------------*/
/*  1. Import CSV into SAS dataset                  */
/*--------------------------------------------------*/

PROC SQL;
CREATE TABLE WORK.query AS
SELECT repyr , appr_trade_code , appr_sponsors_str , appr_pub_tdas , appr_priv_tdas , Fchar FROM _TEMP0.appren;
RUN;
QUIT;

PROC DATASETS NOLIST NODETAILS;
CONTENTS DATA=WORK.query OUT=WORK.details;
RUN;

PROC PRINT DATA=WORK.details;
RUN;
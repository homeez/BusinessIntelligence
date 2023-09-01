/* Generated Code (IMPORT) */
/* Source File: heart_2020_cleaned.csv */
/* Source Path: /home/u63281916/sasuser.v94/Group Assessment */
/* Code generated on: 4/29/23, 8:09 PM */

%web_drop_table(WORK.IMPORT);


FILENAME REFFILE '/home/u63273316/sasuser.v94/Group Project/heart_2020_cleaned.csv';

PROC IMPORT DATAFILE=REFFILE
	DBMS=CSV
	OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT; RUN;

/* checking for missing values */

/* Using PROC FREQ to check for missing values accross the categorical variables*/
proc freq data=WORK.IMPORT;
  tables _all_ / missing;
run;

/* Using PROC MEANS to check for missing values accross the numerical variables */
proc means data=WORK.IMPORT nmiss;
run;

/* using proc means to get the descriptive statistics for the numerical variables */
PROC MEANS DATA=WORK.IMPORT N MEAN MEDIAN STD MIN MAX;
  VAR BMI PhysicalHealth MentalHealth SleepTime;
RUN;

/* using proc means to get the descriptive statistics for the categorical variables */
PROC FREQ DATA=WORK.IMPORT;
  TABLES HeartDisease Smoking AlcoholDrinking Stroke DiffWalking Sex AgeCategory Race Diabetic PhysicalActivity GenHealth Asthma KidneyDisease SkinCancer;
RUN;
/* Checking the presence of heart disease against risk factors*/

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Smoking / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR AlcoholDrinking / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Stroke / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR DiffWalking / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Sex / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR AgeCategory / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Race / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Diabetic / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR PhysicalActivity / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR GenHealth / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR Asthma / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR KidneyDisease / GROUP=HeartDisease;
RUN;

PROC SGPLOT DATA=WORK.IMPORT;
  VBAR SkinCancer / GROUP=HeartDisease;
RUN;

/* Histogram */
proc univariate data=WORK.IMPORT;
var BMI PhysicalHealth MentalHealth SleepTime;
histogram /normal;
run;


/*Regrouping The Age Category*/
data WORK.IMPORT; set WORK.IMPORT;
	if AgeCategory='18-24' then agecatnum=21;
	if AgeCategory='25-29' then agecatnum=27;
	if AgeCategory='30-34' then agecatnum=32;
	if AgeCategory='35-39' then agecatnum=37;
	if AgeCategory='40-44' then agecatnum=42;
	if AgeCategory='45-49' then agecatnum=47;
	if AgeCategory='50-54' then agecatnum=52;
	if AgeCategory='55-59' then agecatnum=57;
	if AgeCategory='60-64' then agecatnum=62;
	if AgeCategory='65-69' then agecatnum=67;
	if AgeCategory='70-74' then agecatnum=72;
	if AgeCategory='75-79' then agecatnum=77;
	if AgeCategory='80 or older' then agecatnum=85;
	if Diabetic='Yes (during pregnancy)' then Diabetic='No';
	if Race='Ameri' then Race='White';
	if Race='Other' then Race='White';

run;

data WORK.IMPORT; set WORK.IMPORT;
age = agecatnum/5;
age2 = age*age;
run;



proc freq data=WORK.IMPORT nlevels;
        table BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth PhysicalActivity DiffWalking Sex agecatnum Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer Sex*Stroke / noprint;
run;

/* Downsampling the dataset*/
proc surveyselect data = WORK.IMPORT 
	out = WORK.IMPORT_sample
	method = SRS rep = 1 
	sampsize = 5000 
	seed = 12345;
run;

/* Logistic Regression Analysis to model the probability of heart disease */
proc genmod descending data=WORK.IMPORT;
class Smoking(ref="No") AlcoholDrinking(ref="No") Stroke(ref="No") DiffWalking(ref="No") Sex agecatnum(ref='21') Race Diabetic(ref="No")
GenHealth(ref="Poor") Asthma(ref="No") KidneyDisease(ref="No") SkinCancer(ref="No") PhysicalActivity(ref="No");
model HeartDisease = BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer / dist=bin link=logit ;
output out=temp p=pred upper=ucl lower=lcl;
run;

ods graphics on;

/* Performing the logistic regression analysis*/
proc logistic descending data=WORK.IMPORT_sample plots=oddsratio;
class Smoking(ref="No") AlcoholDrinking(ref="No") Stroke(ref="No") DiffWalking(ref="No") Sex agecatnum(ref='21') Race Diabetic(ref="No")
GenHealth(ref="Poor") Asthma(ref="No") KidneyDisease(ref="No") SkinCancer(ref="No") PhysicalActivity(ref="No") / param=ref;
 model HeartDisease = BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking Sex age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer / selection=backward lackfit aggregate=(BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking Sex age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer) outroc=classif1;
output out = prob PREDPROBS=I;
store logiModel;
run;

title "Predicted Probabilities of Heart Disease";

proc plm source=logiModel;
	effectplot slicefit(x=age sliceby=GenHealth plotby=Smoking);
	effectplot slicefit(x=age sliceby=Sex plotby=Smoking);
	effectplot slicefit(x=age sliceby=Sex plotby=Stroke);
	effectplot slicefit(x=age sliceby=Stroke plotby=Sex);
	effectplot slicefit(x=age sliceby=Stroke plotby=Smoking);
	effectplot slicefit(x=age sliceby=GenHealth plotby=Stroke);
run;

ods graphics off;



%web_open_table(WORK.IMPORT);
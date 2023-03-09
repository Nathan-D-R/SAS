/* Name: Nathan D. Riley

Class: Applied Econometrics 1

Term: Spring 2023
Project Step 2



Notes

Continous variables: income, wkswork, age

Discrete variables: year, nchild, id

Categorical variables: statefips, male, raceethnic, ed, marst, occ, ind */
/* Preparation Step */
/* Capture the outputs in an excel file for easier processing */
ODS EXCEL FILE="~/MySAS/Project2.xlsx";

/* Specify the path to the directory containing db1.sas7bdat */
LIBNAME _temp "~/my_shared_file_links/u47408605/Data/";

/* Import the data from db1.sas7bdat */
DATA db1;
	SET _temp.db1;
RUN;

/* Formatting for State (statefips) */
/* I have no clue how to do this more efficiently */
PROC FORMAT;
	VALUE state_fmt 1="Alabama" 2="Alaska" 4="Arizona" 5="Arkansas" 6="California" 
		8="Colorado" 9="Connecticut" 10="Delaware" 11="District of Columbia" 
		12="Florida" 13="Georgia" 15="Hawaii" 16="Idaho" 17="Illinois" 18="Indiana" 
		19="Iowa" 20="Kansas" 21="Kentucky" 22="Louisiana" 23="Maine" 24="Maryland" 
		25="Massachusetts" 26="Michigan" 27="Minnesota" 28="Mississippi" 
		29="Missouri" 30="Montana" 31="Nebraska" 32="Nevada" 33="New Hampshire" 
		34="New Jersey" 35="New Mexico" 36="New York" 37="North Carolina" 
		38="North Dakota" 39="Ohio" 40="Oklahoma" 41="Oregon" 42="Pennsylvania" 
		44="Rhode Island" 45="South Carolina" 46="South Dakota" 47="Tennessee" 
		48="Texas" 49="Utah" 50="Vermont" 51="Virginia" 53="Washington" 
		54="West Virginia" 55="Wisconsin" 56="Wyoming";
RUN;

/* Formatting for Gender (male) */
PROC FORMAT;
	VALUE gender_fmt 0='Female' 1='Male';
RUN;

/* Formatting for Race (raceethinc) */
PROC FORMAT;
	VALUE race_fmt 1='White' 2='Black' 3='Asian' 4='Hispanic' 5='Other';
RUN;

/* Formatting for Education (ed) */
PROC FORMAT;
	VALUE ed_fmt 1='Less than high school' 2='High school graduate' 
		3='Some college' 4='College graduate' 5='Graduate degree';
RUN;

PROC FORMAT;
	VALUE marst_fmt 1='Married, spouse present' 2='Married, spouse absent' 
		3='Separated' 4='Divorced' 5='Widowed' 6='Never married/single';
RUN;

/* Part A: Descriptive Summary*/
/* Table 1: for continuous/discrete variables, report: total number of observations (N), mean, standard deviation (SD), minimum (Min), and maximum (Max).

/* Do not use: year, id, statefips, occ, and ind. */
PROC MEANS DATA=db1 STACKODSOUTPUT;
	VAR income wkswork age nchild income;
RUN;

/*Table 2: For categorical variables, report the number of observations and percentage of individuals in each category. */
PROC FREQ DATA=db1;
	TABLES male raceethnic ed marst / NOCUM;
	FORMAT male gender_fmt. raceethnic race_fmt. ed ed_fmt. marst marst_fmt.;
RUN;

/* Part B: Geological Dispersion of the Sample */
/* Specify the table we want to analyze and make a new dataset */
PROC FREQ DATA=db1 NOPRINT;
	TABLE statefips / OUT=state_counts(keep=statefips count percent) NOCUM;
RUN;

/* Makes a new variable called count_num */
DATA state_counts;
	SET state_counts;
	count_num=INPUT(count, 5.);
RUN;

/* We sort count_num in descending to process in the next two steps */
PROC SORT DATA=state_counts;
	BY DESCENDING count;
RUN;

/* Print the top 5 States (1 to 5) */
PROC PRINT DATA=state_counts (FIRSTOBS=1 OBS=5) NOOBS;
	TITLE "Top 5 States by Observation Count";
	VAR statefips count percent;
	FORMAT statefips state_fmt.;
RUN;

/* Print the bottom 5 states (47 to 51) */
/* It is imporant to note DC is in the dataset so it is out of 51 */
PROC PRINT DATA=state_counts (FIRSTOBS=47 OBS=51) NOOBS;
	TITLE "Bottom 5 States by Observation Count";
	VAR statefips count percent;
	FORMAT statefips state_fmt.;
RUN;

/* Part C: The Relationship Between Income and Education */
/* Create a vertical bar chart of average income per eduaction level. */
PROC SGPLOT DATA=db1;
	TITLE "Average Income by Eduaction Level";
	VBAR ed / RESPONSE=income STAT=mean DATALABEL;
	XAXIS LABEL='Education Level';
	YAXIS LABEL='Average Income';
	FORMAT ed ed_fmt. income dollar.2;
RUN;

PROC SORT DATA=db1;
	BY ed;
RUN;

PROC MEANS DATA=db1 NONOBS;
	CLASS ed;
	VAR income;
	FORMAT ed ed_fmt.;
RUN;

/* Part D: Gender Gap in Pay*/
/* Step 1: Sort the data by raceethnic and male */
PROC SORT DATA=db1;
	BY raceethnic male;
RUN;

/* Step 2: Calculate the average income by raceethnic and male */
PROC MEANS DATA=db1 NOPRINT;
	CLASS raceethnic male;
	VAR income;
	OUTPUT OUT=means(DROP=_type_ _freq_) MEAN=;
RUN;

/* Step 3: Merge the male and female means by raceethnic */
DATA income_diff;
	MERGE means(where=(male=1) rename=(income=men_income)) means(where=(male=0) 
		rename=(income=women_income));
	BY raceethnic;
	income_diff=men_income - women_income;

	IF _STATPRB > 0.1 THEN
		significance=' ';
	ELSE IF _STATPRB <=0.1 AND _STATPRB > 0.05 THEN
		significance='*';
	ELSE IF _STATPRB <=0.05 AND _STATPRB > 0.01 THEN
		significance='**';
	ELSE IF _STATPRB <=0.01 THEN
		significance='***';
RUN;

/* Note that I am putting stars in a new column, so it is easier to edit the excel file. */
/* Step 4: Print the table */
PROC PRINT DATA=income_diff NOOBS;
	TITLE "Income by Race and Gender";
	VAR raceethnic men_income women_income income_diff significance;
	FORMAT men_income women_income income_diff dollar.2 raceethnic race_fmt.;
	LABEL raceethnic='Race' men_income='Avg. Income of Men' 
		women_income='Avg. Income of Women' income_diff='Difference in Avg. Income' 
		significance='Significance';
RUN;

/* Capture the outputs in an excel file for easier processing */
ODS EXCEL CLOSE;

# #!/usr/bin/python
# use `conda activate doac` to run this
# just some exploratory code right now
import pandas as pd;
from scipy import stats;
import numpy as np;

patvarFilename="../out/DOAC/all/bleeding.patvars"
df = pd.read_csv(patvarFilename,
                 sep="\t", 
                 names=["pid", "age", "yearsDeceased", "sex", "caucasion", "ethnic", "married", "religion", "zip", "zippath", "AEFlag"]);
# set global variables:
popTotalPatients      =df['pid'].count()
casesTotalPatients    =df.loc[df['AEFlag']==2,'pid'].count();
controlsTotalPatients =df.loc[df['AEFlag']==1,'pid'].count();

def compare_dist(df, cases, controls, census, colname, tagname):
    #
    popTotalCurrent=df[df[colname]==1].describe().loc['count','age'];
    casesTotalCurrent=cases[cases[colname]==1].describe().loc['count','age'];
    controlsTotalCurrent=controls[controls[colname]==1].describe().loc['count','age'];
    #
    pval=popTotalCurrent/popTotalPatients;
    #
    allSig=stats.binom_test(popTotalCurrent, n=popTotalPatients, p=census, alternative='two-sided')
    casesSig=stats.binom_test(casesTotalCurrent, n=AETotalPatients, p=pval, alternative='two-sided');
    controlsSig=stats.binom_test(controlsTotalCurrent, n=AETotalPatients, p=pval, alternative='two-sided');
    #
    print(tagname+":");
    fmtstr="pvals:\n all:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)\n cases:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)\n controls:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)";
    print("census={}%,our population={:3.1f}%".format(census*100, 100*pval));
    print(fmtstr.format(allSig, (census*100), (100*popTotalCurrent/popTotalPatients),
                        casesSig, (pval*100), (100*casesTotalCurrent/AETotalPatients),
                        controlsSig, (pval*100), (100*controlsTotalCurrent/AETotalPatients)  ));

def welch_ttest(x, y): 
    ## Welch-Satterthwaite Degrees of Freedom ##
    dof = (x.var()/x.size + y.var()/y.size)**2 / ((x.var()/x.size)**2 / (x.size-1) + (y.var()/y.size)**2 / (y.size-1))
    #
    t, p = stats.ttest_ind(x, y, equal_var = False)
    #
    print("\n",
          f"Welch's t-test= {t:.4f}", "\n",
          f"p-value = {p:.4f}", "\n",
          f"Welch-Satterthwaite Degrees of Freedom= {dof:.4f}")
    
def proportion_unknown(colName, unknownIdx):
    casesTotalUnknown = df.loc[(unknownIdx)&(df['AEFlag']==2),colName].count();
    controlsTotalUnknown=df.loc[(unknownIdx)&(df['AEFlag']==1),colName].count();
    if(casesTotalUnknown == 0 or controlsTotalUnknown == 0):
        print('Unknown(counts)\t{:s}:\tcases={:d}\tcontrols={:d}'.
              format(colName,
                     casesTotalUnknown, 
                     controlsTotalUnknown));
    else:
        print('Unknown(%-age)\t{:s}:\tcases={:3.2f}%\tcontrols={:3.2f}%'.
              format(colName,
                     100*casesTotalUnknown/casesTotalPatients,
                     100*controlsTotalUnknown/controlsTotalPatients));


print("***Proportion unknown***");
# xxx filter unknown's from religion, married first?
# xxx  - 2x as many unknown's in controls in both religion and married
# xxx find out what is 'unknown' correlated with and control for *that*
proportion_unknown('sex',          (df['sex']=='NB')); # not M or F
proportion_unknown('caucasion',         (df['caucasion']=='7')|(df['caucasion']=='8')); # unknown or refused
proportion_unknown('ethnic',       (df['ethnic']=='3')|(df['ethnic']=='4')); # unknown or refused
#  ethnic includes 'NAIS', this is not in the codings
proportion_unknown('married',      (df['married']=='6')|(df['married']=='unknown'));
proportion_unknown('religion',     (df['religion']=='NOT')|(df['religion']=='REF')|(df['religion']=='UNKNOWN'));

#                 names=["pid", "age", "yearsDeceased", "sex", "caucasion", "ethnic", "married", "religion", "zip", "zippath", "AEFlag"]);

# AGE:
# the following shows a rough distribution of years people were born, which appears to be normal around 1946.5 (min,max=1903,2015)
# cut -d, -f 3 /data/CSV/GONZ_DOAC/patient_dimension.csv|awk -F'/' '{print $1}'|sort -g|uniq -c
# but our ages (computed to account also for death) might have some errors based on incorrectly reported deaths
# ages: (seems to be normal around 72.5, min,max=4,116, one with 0 years old)
# cut -d, -f 3 /data/CSV/GONZ_DOAC/patient_dimension.csv|sed 's/"//'|awk -F'/' '{print 2019-$1}'|sort -g|uniq -c
# also:
#  one of the patients is marked as having died a month before born in 1966; latest observations are in 2016, may be error in deceased year
#  rules could be added to the mapper to find and correct these (and flag for record keepers)

exit();

#
# convert from categorical strongs to binary integers:
#
df.loc[df['sex']=='M','sex']=0;
df.loc[df['sex']=='F','sex']=1;

df.loc[df['caucasion']!='1','caucasion']=0;
df.loc[df['caucasion']!=0,'caucasion']=1;

df.loc[df['married']=='1','married']='single';
df.loc[df['married']=='107','married']='domestic partner';
df.loc[df['married']=='2','married']='married';
df.loc[df['married']=='3','married']='legally separaed';
df.loc[df['married']=='4','married']='divorced';
df.loc[df['married']=='5','married']='widowed';
df.loc[df['married']=='6','married']='unknown';
df.loc[df['married']=='unknown','married']='unknown';

print(df.head());
aestats=df[df["AEFlag"]==2].describe();
AETotalPatients=int(aestats.loc["count","pid"]);
print("Total adverse events [4338] = " + str(AETotalPatients) );

cases = df[(df['AEFlag'] == 2)]
#cases=df[df["AEFlag"]==2]
print("*********CASES",end="");
numCases=cases.describe().loc['count','age']
print("["+str(numCases)+"]");
print(cases.describe().loc[['mean','min','max'],'age':'yearsDeceased']);
print("Age: (W test statistic, p-value):" + str(stats.shapiro(cases['age'])) );
print("Years Deceased: (W test statistic, p-value):" + str(stats.shapiro(cases['yearsDeceased'])) );

controls=df[(df["AEFlag"]==1)].sample(n=AETotalPatients, random_state=2)
print("*****CONTROLS",end="");
numControls=controls.describe().loc['count','age']
print("["+str(numControls)+"]");
print(controls.describe().loc[['mean','min','max'],'age':'yearsDeceased']);
print("Age: (W test statistic, p-value):" + str(stats.shapiro(controls['age'])) );
print("Years Deceased: (W test statistic, p-value):" + str(stats.shapiro(controls['yearsDeceased'])) );


print("***MARITAL STATUS***");
print("---cases:");
print(cases.groupby(["married"]).size().sort_values());
print("---controls:");
print(controls.groupby(["married"]).size().sort_values());
print("---all:");
print(df.groupby(["married"]).size().sort_values());
print("*********");

cases.loc[cases['married']!='married','married']=0;
cases.loc[cases['married']!=0,'married']=1;
#controls.loc[cases['married']!='married','married']=0;
#controls.loc[cases['married']!=0,'married']=1;



print();
print("My T-test on age:",end="");
welch_ttest(cases['age'], controls['age']);

print("T-test on age:" + str(stats.ttest_ind(cases['age'], controls['age'], equal_var = False)));

print();


print("---Binomial tests, low p-val means we reject the hypothesis that the observed mean is within the expected range): ");
print("   In other words, low p-val means the population isn't balanced");
print("The original value is {:d}% controls, so the pval for controls should be low.".format(int(100*(popTotalPatients-AETotalPatients)/popTotalPatients)));

print();
compare_dist(df=df, cases=cases, controls=controls, census=.508, colname="sex", tagname="FEMALE");
print();
compare_dist(df=df, cases=cases, controls=controls, census=.72, colname="caucasion", tagname="CAUCASION");
print();
#compare_dist(df=df, cases=cases, controls=controls, census=.52, colname="married", tagname="MARRIED");
print();
compare_dist(df=df, cases=cases, controls=controls, census=.34, colname="religion", tagname="RELIGION");
print("---cases:");
print(cases.groupby(["religion"]).size().sort_values().tail(10));
print("---controls:");
print(controls.groupby(["religion"]).size().sort_values().tail(10));
print("---all:");
print(df.groupby(["religion"]).size().sort_values().tail(10));

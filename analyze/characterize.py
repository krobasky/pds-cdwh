# #!/usr/bin/python
# use `conda activate doac` to run this
# just some exploratory code right now
import pandas as pd;
from scipy import stats;
import numpy as np;

def compare_dist(df, cases, controls, census, colname, tagname):

    popTotalCurrent=df[df[colname]==1].describe().loc['count','age'];
    casesTotalCurrent=cases[cases[colname]==1].describe().loc['count','age'];
    controlsTotalCurrent=controls[controls[colname]==1].describe().loc['count','age'];

    pval=popTotalCurrent/popTotalPatients;

    allSig=stats.binom_test(popTotalCurrent, n=popTotalPatients, p=census, alternative='two-sided')
    casesSig=stats.binom_test(casesTotalCurrent, n=AETotalPatients, p=pval, alternative='two-sided');
    controlsSig=stats.binom_test(controlsTotalCurrent, n=AETotalPatients, p=pval, alternative='two-sided');

    print(tagname+":");
    fmtstr="pvals:\n all:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)\n cases:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)\n controls:\t{:1.2f}(exp:{:3.1f}%,obs:{:3.1f}%)";
    print("census={}%,our population={:3.1f}%".format(census*100, 100*pval));
    print(fmtstr.format(allSig, (census*100), (100*popTotalCurrent/popTotalPatients),
                        casesSig, (pval*100), (100*casesTotalCurrent/AETotalPatients),
                        controlsSig, (pval*100), (100*controlsTotalCurrent/AETotalPatients)  ));


def welch_ttest(x, y): 
    ## Welch-Satterthwaite Degrees of Freedom ##
    dof = (x.var()/x.size + y.var()/y.size)**2 / ((x.var()/x.size)**2 / (x.size-1) + (y.var()/y.size)**2 / (y.size-1))
    
    t, p = stats.ttest_ind(x, y, equal_var = False)
    
    print("\n",
          f"Welch's t-test= {t:.4f}", "\n",
          f"p-value = {p:.4f}", "\n",
          f"Welch-Satterthwaite Degrees of Freedom= {dof:.4f}")
    


patvarFilename="../out/DOAC/all/bleeding.patvars"
df = pd.read_csv(patvarFilename,
                 sep="\t", 
                 names=["pid", "age", "yearsDeceased", "sex", "caucasion", "ethnic", "married", "religion", "zip", "zippath", "AEFlag"]);

popTotalPatients=int(df.describe().loc['count','age']);

#
# convert from categorical strongs to binary integers:
#
df.loc[df['sex']=='M','sex']=0;
df.loc[df['sex']=='F','sex']=1;

df.loc[df['caucasion']!='1','caucasion']=0;
df.loc[df['caucasion']!=0,'caucasion']=1;

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
compare_dist(df=df, cases=cases, controls=controls, census=.34, colname="religion", tagname="RELIGION");

print(cases.groupby(["religion"]).size().sort_values().tail(10));
print(df.groupby(["religion"]).size().sort_values().tail(10));

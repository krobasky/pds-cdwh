# #!/usr/bin/python
# use `conda activate doac` to run this
# just some exploratory code right now
import pandas as pd;
#import DataFrame from pandas;
import numpy as np;
patvarFilename="../out/DOAC/all/bleeding.patvars"
df = pd.read_csv(patvarFilename,
                 sep="\t", 
                 names=["pid", "age", "yearsDead", "sex", "race", "ethnic", "married", "religion", "zip", "zippath", "AEFlag"]);
print(df.head());
aestats=df[df["AEFlag"]==2].describe();
total_aes=aestats.loc["count","pid"]
print("Total adverse events [4338] = " + str(total_aes) );

cases=df[df["AEFlag"]==2]
print("*********CASES",end="");
numCases=cases.describe().loc['count','age']
print("["+str(numCases)+"]");
print(cases.describe().loc[['mean','min','max'],'age':'yearsDead']);

controls=df[df["AEFlag"]==1].sample(n=int(total_aes), random_state=1)
print("*****CONTROLS",end="");
numControls=controls.describe().loc['count','age']
print("["+str(numControls)+"]");
print(controls.describe().loc[['mean','min','max'],'age':'yearsDead']);


print("Female: cases, controls");
totalFemaleCases=cases[cases["sex"]=="F"].describe().loc['count','age'];
totalFemaleControls=controls[controls["sex"]=="F"].describe().loc['count','age'];
print("" + str(int(100*totalFemaleCases/cases.describe().loc['count','age']))+"%",end="");
print(", " + str(int(100*totalFemaleControls/controls.describe().loc['count','age']))+"%");

print("Caucasion: cases, controls");
totalCauCases=cases[cases["race"]=="1"].describe().loc['count','age'];
totalCauControls=controls[controls["race"]=="1"].describe().loc['count','age'];
print("" + str(int(100*totalCauCases/cases.describe().loc['count','age']))+"%", end="");
print(", " + str(int(100*totalCauControls/controls.describe().loc['count','age']))+"%");

relstr="NOT"
totalNonRelCases=cases[cases["religion"]==relstr].describe().loc['count','age'];
totalNonRelControls=controls[controls["religion"]==relstr].describe().loc['count','age'];
print("Religion - "+relstr+"["+str(totalNonRelCases)+","+str(totalNonRelControls)+"] : cases, controls");
#print("Religion - "+relstr+": cases, controls");
print("" + str(int(100*totalNonRelCases/cases.describe().loc['count','age']))+"%", end="");
print(", " + str(int(100*totalNonRelControls/controls.describe().loc['count','age']))+"%");

relstr="UNKNOWN"
totalNonRelCases=cases[cases["religion"]==relstr].describe().loc['count','age'];
totalNonRelControls=controls[controls["religion"]==relstr].describe().loc['count','age'];
print("Religion - "+relstr+"["+str(totalNonRelCases)+","+str(totalNonRelControls)+"] : cases, controls");
print("" + str(int(100*totalNonRelCases/cases.describe().loc['count','age']))+"%", end="");
print(", " + str(int(100*totalNonRelControls/controls.describe().loc['count','age']))+"%");

cases.groupby(["religion"]).size()
x=cases.groupby(["religion"]).size()
#print(x.sort_values())
#print(x.sort_values().tail())

controls.groupby(["religion"]).size()
x=controls.groupby(["religion"]).size()

# -------

df = pd.read_csv("tmp.csv", sep='\t', 
                 names=["species","count", "mean", "std","min", "twentyfive", "seventyfive",  "max"]);
print(df.head());

#df.groupby("species")['petal_length'].describe();
#setosa = df[(df['species'] == 'Iris-setosa')]
#virginica = df[(df['species'] == 'Iris-virginica')]
#
#from scipy import stats;
#stats.shapiro(setosa['petal_length'])
#
#print(stats.shapiro(setosa['petal_length']))

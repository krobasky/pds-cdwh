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
#print(df[df["AEFlag"]==1,"AEFlag"].describe());
print(df[df["AEFlag"]==2].describe());
controls=df[df["AEFlag"]==2].sample(n=4338, random_state=1)
cases=df[df["AEFlag"]==1]

df[df["AEFlag"]==1].describe();
df[df["AEFlag"]==2].describe();
controls=df[df["AEFlag"]==2].sample(n=4338, random_state=1)
cases=df[df["AEFlag"]==1]
cases.describe()
controls.describe()
controls.head()
controls[controls["race"]=="1"].describe()
controls[controls["race"]!="1"].describe()
cases[cases["race"]=="1"].describe()
cases[cases["race"]!="1"].describe()
cases[cases["sex"]=="F"].describe()
cases[cases["sex"]=="M"].describe()
controls[controls["sex"]=="F"].describe()
controls[controls["sex"]=="M"].describe()
controls["religion"].describe()
#controls["religion"].types
controls.groupby(["religion"]).size()
x=controls.groupby(["religion"]).size()
x.head()
x.sort_values()
y=cases.groupby(["religion"]).size()
controls["religion"].describe()
controls.head()
controls["religion"].describe()
x.sort_values().tail()
y.sort_values().tail()
controls.groupby(["sex"]).size()
cases.groupby(["sex"]).size()
cases.groupby(["race"]).size()
controls.groupby(["race"]).size()
cases.groupby(["race"]).size()
controls.groupby(["religion"]).size()
y.sort_values().tail()
x.sort_values().tail()
contrAge=controls.groupby(["age"]).size()
caseAge=cases.groupby(["age"]).size()
contrAge.sort_values().tail()
caseAge.sort_values().tail()
contrDeath=controls.groupby(["age"]).size()
cases.head()
caseDeath=cases.groupby(["yearsDead"]).size()
contDeath=controls.groupby(["yearsDead"]).size()
caseDeath.sort_values().tail()
contDeath.sort_values().tail()
contDeath.describe()
caseDeath.describe()
cases["yearsDead"].describe()
controls["yearsDead"].describe()
sum(controls["yearsDead"])
sum(cases["yearsDead"])
cases[cases["yearsDead"]>0].describe()
controls[controls["yearsDead"]>0].describe()
controls["age"].describe()
cases["age"].describe()
cases.corr()




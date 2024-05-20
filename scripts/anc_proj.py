#if true; then
#${PYTHON} <<__EOF_PYTHON_SCRIPT
import sys
import pandas as pd
import os
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
from sklearn.model_selection import cross_val_score
from sklearn.ensemble import HistGradientBoostingClassifier, IsolationForest

pca_1kg_fname = sys.argv[1]		#"${pca_1kg_project}.sscore"
pca_top_fname = sys.argv[2]		#"${pca_top_project}.sscore"
df_1kg = pd.read_table(pca_1kg_fname)
df_top = pd.read_table(pca_top_fname)
project = sys.argv[3]

# Predict ancestry for all samples.
cols = [f"PC{i}_AVG" for i in [1,2,3,4]]
X = df_1kg[cols].values
y = df_1kg["SuperPop"].values
scores = cross_val_score(HistGradientBoostingClassifier(), X, y, cv=5)
print(f"CV prediction scores: {scores}")
clf = HistGradientBoostingClassifier().fit(X, y)
top_pop = clf.predict(df_top[cols].values)
df_top["SuperPop"] = top_pop
print(f"Populations predicted for all samples: {df_top.SuperPop.value_counts()}")

# Indentify outliers.
clf = IsolationForest()
df_top["CORE"] = True
for pop in df_1kg["SuperPop"].unique():
    i_pop = df_top["SuperPop"] == pop
    X = df_top.loc[i_pop, cols]
    i_pop_1kg = df_1kg["SuperPop"] == pop
    X_1kg = df_1kg.loc[i_pop_1kg, cols]
    X_merged = pd.concat([X,X_1kg]) 
    survive = clf.fit_predict(X_merged)[:len(X)]
    df_top.loc[i_pop,"CORE"] = (survive == 1)

print(f'Core samples vs outliers: {df_top["CORE"].value_counts()}')
print(f'Populations predicted for core samples: {df_top.loc[df_top.CORE,"SuperPop"].value_counts()}')

#outf = project".ancestries.txt"
df_top.to_csv(f"{project}.ancestries.txt", sep='\t', index=False)
#print(f"File with ancestries saved to: {outf}")

# Produce plots.
fig, axs = plt.subplots(2,3, figsize=(14,7), sharex=True, constrained_layout=True)
hue_order = list(sorted(df_1kg["SuperPop"].unique()))
fig.suptitle("All samples (top row) vs Core samples (bottom row)")
sns.scatterplot(data=df_top, x="PC1_AVG", y="PC2_AVG", hue="SuperPop", ax=axs[0,0], hue_order=hue_order)
sns.scatterplot(data=df_top, x="PC3_AVG", y="PC4_AVG", hue="SuperPop", ax=axs[0,1], hue_order=hue_order)
sns.scatterplot(data=df_top, x="PC5_AVG", y="PC6_AVG", hue="SuperPop", ax=axs[0,2], hue_order=hue_order)
sns.scatterplot(data=df_top.loc[df_top.CORE,:], x="PC1_AVG", y="PC2_AVG", hue="SuperPop", ax=axs[1,0], hue_order=hue_order)
sns.scatterplot(data=df_top.loc[df_top.CORE,:], x="PC3_AVG", y="PC4_AVG", hue="SuperPop", ax=axs[1,1], hue_order=hue_order)
sns.scatterplot(data=df_top.loc[df_top.CORE,:], x="PC5_AVG", y="PC6_AVG", hue="SuperPop", ax=axs[1,2], hue_order=hue_order)
#outf = project".ancestries.png"
plt.savefig(f"{project}.ancestries.png", facecolor='w', dpi=300)
#print(f"Figure save to: {outf}.")
#__EOF_PYTHON_SCRIPT
#fi

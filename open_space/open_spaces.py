# Import dependencies

import pandas as pd
import numpy as np
import openpyxl
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from sklearn.cluster import KMeans
from open_space_functions import *



###### A: Import datasets

# Open Spaces and Housing
vpa_path = './datasets/VPA_Open_Space.csv'
vpa_df = pd.read_csv(vpa_path)

housing_path = './datasets/Affordable lettings by local government area - March Quarter 2021.xlsx'
housing_df = pd.read_excel(housing_path, sheet_name=None, engine='openpyxl')

# Third dataset: Scrape Wikipedia

# Scrape information from Wikipedia about the 31 metropolitan LGA's
#wiki_df = wiki_LGA(write=True)
wiki_df = pd.read_csv('LGA_list.csv')



###### B: Cleaning

# Housing: the last sheet is of interest
sheets = list(housing_df.keys())
housing_df = housing_df[sheets[-1]]

# Housing: set columns and index
housing_df = housing_df.set_index(housing_df.iloc[:,0])
housing_df.columns = housing_df.iloc[1,:]

# Both: LGA naming must be consistent across both datasets
t = vpa_df[vpa_df.loc[:, 'LGA']=='MORNINGTON'].index
vpa_df.loc[t, 'LGA'] = 'mornington peninsula'
housing_df.rename(index={"Mornington Penin'a":'Mornington Peninsula'},
                  inplace=True)

# Both: convert LGA names to lower case
vpa_df['LGA'] = vpa_df['LGA'].str.lower()
housing_df = housing_df.set_index(housing_df.index.str.lower())

# Match LGA keys from datasets with full names
lga_keys = list(set(vpa_df.loc[:, 'LGA']))
lga_names = match_names(wiki_df['Name'], lga_keys)

# Wiki data: Index consistent with other datasets
wiki_df = wiki_df.merge(lga_names, on='Name')
wiki_df = wiki_df.set_index('Key')




###### C: Cleaning Open Spaces dataset

# Drop rows with 'planned' status - incomplete data
vpa_df = vpa_df.drop(vpa_df[vpa_df['OS_STATUS']=='Planned'].index)
# Drop rows for Mitchell Shire, this is a regional LGA
vpa_df = vpa_df.drop(vpa_df[vpa_df['LGA']=='mitchell'].index)
# Drop rows which are cemeteries
vpa_df = vpa_df.drop(vpa_df[vpa_df['OS_CATEGOR']=='Cemeteries'].index)

# Remove extra columns, and those with lots of missing data
to_drop = ['FID', 'VM_PARCEL_', 'VM_PARCE_1', 'DATA_SOURC', 'MANAGER_TY',
           'OS_STATUS', 'VEAC_ID', 'WATER_BODY','COASTAL', 'MANAGER_NA',
           'Image_URL', 'SUBREGION', 'VPA_ID', 'SHAPE_Length', 'SHAPE_Area',
           'OS_CATEG_2', 'OWNER_TYPE', 'PARK_NAME', 'OWNER_NAME']
vpa_df = vpa_df.drop(to_drop, axis=1)
vpa_df.index = range(0,len(vpa_df))




###### D: Get Housing data

mar19 = housing_month('Mar 2019', housing_df, wiki_df)
jun19 = housing_month('Jun 2019', housing_df, wiki_df)
sep19 = housing_month('Sep 2019', housing_df, wiki_df)
dec19 = housing_month('Dec 2019', housing_df, wiki_df)
avg19 = (mar19['Affordable %'] + jun19['Affordable %'] +
         sep19['Affordable %'] + dec19['Affordable %'])/4


###### E: Clustering open spaces

# Convert ordinal/categorical values to numerical
vpa_df.loc[vpa_df['OS_ACCESS']=='Open', 'OS_ACCESS'] = 1
vpa_df.loc[vpa_df['OS_ACCESS']=='Limited', 'OS_ACCESS'] = 0.67
vpa_df.loc[vpa_df['OS_ACCESS']=='Highly Limited', 'OS_ACCESS'] = 0.33
vpa_df.loc[vpa_df['OS_ACCESS']=='Closed', 'OS_ACCESS'] = 0

vpa_df.loc[vpa_df['OS_CATEGOR'].isin(
    ['Parks and gardens','Sportsfields and organised recreation',
     'Recreation corridor', 'Conservation reserves',
     'Natural and semi-natural open space']
    ), 'OS_CATEGOR'] = 1
vpa_df.loc[vpa_df['OS_CATEGOR'].isin(
    ['Tertiary institutions', 'Government schools',
     'Non-government schools', 'Civic squares and promenades',
     'Public housing reserves']
    ), 'OS_CATEGOR'] = 0.67
vpa_df.loc[vpa_df['OS_CATEGOR'].isin(
    ['Transport reservations', 'Services and utilities reserves']
    ), 'OS_CATEGOR'] = 0.33
vpa_df.loc[vpa_df['OS_CATEGOR'].isin(
    ['Cemeteries']
    ), 'OS_CATEGOR'] = 0

vpa_df.loc[vpa_df['OS_TYPE']=='Public open space', 'OS_TYPE'] = 1
vpa_df.loc[vpa_df['OS_TYPE']=='Private open space', 'OS_TYPE'] = 0.5
vpa_df.loc[vpa_df['OS_TYPE']=='Restricted public land', 'OS_TYPE'] = 0



# Clustering and aggregating open spaces

cl = np.array(vpa_df[['OS_TYPE','OS_ACCESS','OS_CATEGOR']])
cl = KMeans(n_clusters=3, random_state=0).fit(cl)
cl = pd.Series(cl.labels_, name='Quality')

vpa_df = pd.concat([vpa_df, cl], axis=1)

# Evaluate clusters and assign High, Medium, Low
c0 = vpa_df.loc[vpa_df['Quality']==0]
c1 = vpa_df.loc[vpa_df['Quality']==1]
c2 = vpa_df.loc[vpa_df['Quality']==2]

c0 = ((sum(c0['OS_TYPE'] + c0['OS_CATEGOR'] + c0['OS_ACCESS']))/(3*len(c0)), 0)
c1 = ((sum(c1['OS_TYPE'] + c1['OS_CATEGOR'] + c1['OS_ACCESS']))/(3*len(c1)), 1)
c2 = ((sum(c2['OS_TYPE'] + c2['OS_CATEGOR'] + c2['OS_ACCESS']))/(3*len(c2)), 2)
s_cl = sorted([c0,c1,c2], reverse=True)
s_cl = [i[1] for i in s_cl]

vpa_df.loc[vpa_df['Quality']==s_cl[0], 'Quality']='High'
vpa_df.loc[vpa_df['Quality']==s_cl[1], 'Quality']='Medium'
vpa_df.loc[vpa_df['Quality']==s_cl[2], 'Quality']='Low'

# Initialise low, medium, high labels
lo = dict.fromkeys(wiki_df.index, 0)
med = dict.fromkeys(wiki_df.index, 0)
hi = dict.fromkeys(wiki_df.index, 0)

# Aggregate vpa_df over 31 LGA's
for i in range(0, len(vpa_df)):
    row = vpa_df.iloc[i, :]
    if row['Quality']=='High':
        hi[row['LGA']] += row['HA']/100
    elif row['Quality']=='Medium':
        med[row['LGA']] += row['HA']/100
    elif row['Quality']=='Low':
        lo[row['LGA']] += row['HA']/100
    



###### G: Joining datasets

# Combine into dataframe
lo, med, hi = pd.Series(lo), pd.Series(med), pd.Series(hi)
space_agg = pd.concat([lo, med, hi], axis=1)
space_agg = space_agg.sort_index()

# Express open space as a proportion of LGA area
normalised = space_agg.divide(wiki_df['Size'].sort_index(), axis=0)*100

space_agg = pd.concat([space_agg, normalised], axis=1)
space_agg.columns = ['Low km^2', 'Medium km^2', 'High km^2',
                     'Low %', 'Medium %', 'High %']

# Join open space with housing data and LGA title
metro_df = space_agg.merge(avg19, left_index=True, right_index=True)
metro_df = metro_df.merge(wiki_df[['Name', 'Region']], left_index=True, right_index=True)




###### H: Open Spaces - weighted score

weighted_sum = pd.Series(.5*metro_df['Low %'] + .75*metro_df['Medium %'] + metro_df['High %'],
                         index=metro_df.index, name='Weighted Score')

metro_w_df = metro_df.drop(['Low %', 'Medium %', 'High %', 
                                   'Low km^2', 'Medium km^2', 'High km^2'], axis=1)

metro_w_df = metro_w_df.merge(weighted_sum, left_index=True, right_index=True)


# Table
table_df = metro_w_df.loc[:, ['Name', 'Affordable %', 'Weighted Score', 'Region']]
table_df = table_df.round(2)
table_df.to_csv('spaces_housing_summary.csv')

# Setup for further analysis
metro_df = metro_df.sort_values(['Region', 'Name'])
metro_w_df = metro_w_df.sort_values(['Region', 'Name'])

inner = metro_w_df.loc[metro_df['Region']=='Inner Melbourne']
met = metro_w_df.loc[metro_df['Region']=='Metropolitan Melbourne']
outer = metro_w_df.loc[metro_df['Region']=='Outer Metropolitan']




###### I: Visualisations
'''
# Clustering 3D plot
x=np.array(vpa_df['OS_CATEGOR'])
x = x + np.random.randn(len(x))*.035
y=np.array(vpa_df['OS_ACCESS'])
y = y + np.random.randn(len(y))*.035
z = np.array(vpa_df['OS_TYPE'])
z = z + np.random.randn(len(z))*.035

fig = plt.figure(figsize = (10, 7))
ax = plt.axes(projection ="3d")
ax.scatter(x[cl==s_cl[0]], y[cl==s_cl[0]], z[cl==s_cl[0]], c='#336B3F')
ax.scatter(x[cl==s_cl[1]], y[cl==s_cl[1]], z[cl==s_cl[1]], c='#FDB813')
ax.scatter(x[cl==s_cl[2]], y[cl==s_cl[2]], z[cl==s_cl[2]], c='#F17022')

plt.title('Open Spaces: K-Means Clustering', fontweight='bold')
ax.set_xlabel('Category', fontweight='bold')
ax.set_ylabel('Access', fontweight='bold')
ax.set_zlabel('Type', fontweight='bold')

plt.savefig('figures/3DScatter.png')


# Barchart 1

fig, ax = plt.subplots(figsize = (12,10))

plt.bar(np.arange(len(metro_df.index)), metro_df['High %'], 
        bottom=metro_df['Low %']+metro_df['Medium %'], color='#336B3F') 
plt.bar(np.arange(len(metro_df.index)), metro_df['Medium %'], bottom=metro_df['Low %'], color='#FDB813')
plt.bar(np.arange(len(metro_df.index)), metro_df['Low %'], color='#F17022') 

plt.subplots_adjust(bottom=0.275)
ax.set_axisbelow(True)
ax.grid(axis='y')

plt.xticks(np.arange(len(metro_df.index)), metro_df['Name'], rotation=90, size=12)
plt.yticks(size=14)
plt.ylabel("Percentage of LGA area", size=16)
plt.legend(['High', 'Medium','Low'], fontsize='large')
plt.title('Low, Medium, and High Quality Open Space Relative to Area', size=20, pad=20)

plt.savefig('figures/spaces_by_lga.png')

# Barchart 2

fig, ax = plt.subplots(figsize = (12,10))

colours = ['#0AB27E']*len(inner) + ['#1D51B1']*len(met) + ['#9B009C']*len(outer)

plt.bar(np.arange(len(metro_w_df.index)), metro_w_df['Weighted Score'],
        color=colours)

plt.subplots_adjust(bottom=0.275)
ax.set_axisbelow(True)
ax.grid(axis='y')

plt.xticks(np.arange(len(metro_df.index)), metro_df['Name'], rotation=90, size=12)
plt.yticks(size=14)
plt.ylabel("Percentage of LGA area", size=16)
legend_elements = [Patch(facecolor='#0AB27E', label='Inner'),
                   Patch(facecolor='#1D51B1', label='Metropolitan'),
                   Patch(facecolor='#9B009C', label='Outer')]
                   
plt.legend(handles=legend_elements, fontsize='large')
plt.title('Open Space Score for each LGA', size=20, pad=20)

plt.savefig('figures/spaces_by_lga_weighted.png')

# Housing boxplot

fig, ax = plt.subplots(figsize = (10,7.5))

plt.boxplot([inner['Affordable %'],
             met['Affordable %'],
             outer['Affordable %']], 
            widths=[.8,.8,.8])

plt.xticks([1,2,3],['Inner Melbourne','Metropolitan','Outer Metropolitan'], size=14)
plt.ylabel('Percentage of all rentals that are affordable', size=16)
plt.yticks(size=12)
plt.title("Affordable Rentals in Melbourne LGA's: by Region", size=18, pad=18)

plt.savefig('figures/inner_metro_outer.png')

# Scatterplot 1

fig, ax = plt.subplots(figsize = (8,7.5))

plt.scatter(inner['Weighted Score'], inner['Affordable %'], color='#0AB27E')
plt.scatter(met['Weighted Score'], met['Affordable %'], color='#1D51B1')
plt.scatter(outer['Weighted Score'], outer['Affordable %'], color='#9B009C')

plt.xlabel('Open space (weighted score out of 100)', size=16)
plt.ylabel('Percentage of rentals that are affordable', size=16)
plt.xticks(size=12)
plt.yticks(size=12)
plt.legend(['Inner', 'Metropolitan', 'Outer'], fontsize='large')
plt.title('Affordable Rentals vs Open Space by LGA', size=18, pad=20)

ax.set_axisbelow(True)
ax.grid(which='major')
plt.xlim(0,70)
plt.ylim(0,35)

plt.savefig('figures/housing_all_LGA_scatter.png')

# Scatterplot 2

fig, ax = plt.subplots(figsize = (8,7.5))

plt.scatter(inner['Weighted Score'], inner['Affordable %'],
            color='#0AB27E')
plt.scatter(met['Weighted Score'], met['Affordable %'],
            color='#1D51B1')
#plt.scatter(outer['Weighted Score'], outer['Affordable %'],
#            color='#9B009C')

plt.xlabel('Open Space (Weighted score out of 100)', size=14)
plt.ylabel('Percentage of rentals that are affordable', size=14)
plt.xlim(0,30)
plt.ylim(0,5)


plt.title('Affordable Rentals vs Open Space by LGA (Outer omitted)', size=18, pad=20)
plt.legend(['Inner', 'Metropolitan'], fontsize='large')
ax.set_axisbelow(True)
ax.grid(which='major')
plt.savefig('figures/housing_inner_metro_scatter.png')


# Double line chart

metro_w_s_df = metro_w_df.sort_values('Weighted Score')

fig, ax1 = plt.subplots(figsize = (15,7))
ax2 = ax1.twinx()
plt.subplots_adjust(bottom=0.41)

ax1.plot(metro_w_s_df['Affordable %'], marker='.', markersize=15, color='#7200B0')
ax2.plot(metro_w_s_df['Weighted Score'], marker = ".", markersize=15, color='#336B3F')

plt.xticks(np.arange(len(metro_w_s_df.index)), labels=metro_w_s_df['Name'])
plt.title("Affordable Rentals in LGA's Sorted by Open Space Score", size=20, pad=20)
ax1.tick_params(axis='x', labelrotation=90, labelsize=13)

ax1.set_ylabel('Percentage of rentals: affordable', size=15, labelpad=13)
ax2.set_ylabel('Open Space Score', size=15, labelpad=13)
ax1.tick_params(axis='y', labelsize=13)
ax2.tick_params(axis='y', labelsize=13)

plt.legend(['Open Space', 'Affordable Rentals'])


plt.savefig('figures/line-line.png')
'''




###### J: Checking for correlation

# Calculate Pearson's
excl_outer = pd.concat([inner, met],axis=0)

pearson_dict = {
    'Inner': calc_pearson(inner['Affordable %'], inner['Weighted Score']),
    'Metro': calc_pearson(met['Affordable %'], met['Weighted Score']),
    'Outer': calc_pearson(outer['Affordable %'], outer['Weighted Score']),
    'All': calc_pearson(metro_w_df['Affordable %'], metro_w_df['Weighted Score']),
    'Excl. Outer': calc_pearson(excl_outer['Affordable %'], excl_outer['Weighted Score'])
}
pearson_regions = pd.Series(pearson_dict)
p = pearson_regions.to_frame("Pearson's Coefficient")
p.to_csv('pearson.csv')

# Calculate Mutual Information
mi_dict = {
    'Inner': mutual_information(inner),
    'Metro': mutual_information(met),
    'Outer': mutual_information(outer),
    'All': mutual_information(metro_w_df),
    'Excl. Outer': mutual_information(excl_outer)
}
mi_regions = pd.Series(mi_dict)
mi = mi_regions.to_frame('Normalised Mutual Information')
mi.to_csv('mutual_information.csv')

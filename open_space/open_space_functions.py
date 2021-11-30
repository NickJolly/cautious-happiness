import pandas as pd
import numpy as np
import requests
import re
from bs4 import BeautifulSoup
import unicodedata
from sklearn.metrics.cluster import normalized_mutual_info_score


def wiki_LGA(filename='LGA_list.csv', write=False):
    ''' A function to scrape LGA's data from Wikipedia,
    Figures are drawn from the 2018 census data. 
    Can write a CSV file with columns Name, Region, Size, Population.
    Also returns this information as a dataframe. '''

    # Get and parse the Wikipedia page
    url = 'https://en.wikipedia.org/wiki/Local_government_areas_of_Victoria'
    page = requests.get(url)
    soup = BeautifulSoup(page.text, 'html.parser')

    # Find and process the table listing Metropolitan LGA's
    table = soup.find('tbody')
    rows = table.findAll('tr')

    LGA_list = []
    for row in rows[1:]:
        cells = row.findAll('td')
        # Pull relevant info
        name = unicodedata.normalize('NFKD', cells[0].text.strip())
        region = unicodedata.normalize('NFKD', cells[2].text.strip())
        size = unicodedata.normalize('NFKD', cells[4].text.strip())
        pop = unicodedata.normalize('NFKD', cells[5].text.strip())

        # Only keep digits
        size = re.sub(r'[^\d]', '', size)
        size = int(size)
        pop = re.sub(r'[^\d]', '', pop)
        pop = int(pop)

        # Calculate population density people/km^2
        dens = round(pop/size, 1)
        
        LGA_list.append([name, region, size, pop, dens])

    # Construct and write a csv
    col_names = ['Name', 'Region', 'Size', 'Population', 'Density']
    df = pd.DataFrame(LGA_list, columns=col_names)

    if write:
        df.to_csv(filename, index=False)
    return(df)





def match_names(A1, A2):
    ''' Takes as input 2 lists of 'formal' and 'informal' LGA names. 
    names. This function looks for matches, and returns a dictionary of
    informal: formal pairs. '''
    
    pairs = {}
    for n1 in A1:
        temp = n1.lower()
        temp = temp.split()
        temp = temp[2:]
        temp = ' '.join(temp)
        for n2 in A2:
            if temp == n2:
                pairs[n2] = n1

    return pd.DataFrame(pairs.items(), columns=['Key', 'Name'])





def housing_month(col_name, housing_df, wiki_df):
    ''' This function takes as input a 'month year' column name, and returns
    the number and percentage of affordable housing in each LGA at that point in
    time. '''
    
    arr = housing_df.columns==col_name
    ind = arr.nonzero()[0][0]
    df = pd.concat([housing_df.iloc[:, ind], housing_df.iloc[:, ind+1]*100], axis=1)
    df.columns = ['Affordable #', 'Affordable %']
    metro = pd.Series(df.index.isin(wiki_df.index), name='Metro')
    metro.index = df.index
    df = df.merge(metro, left_index=True, right_index=True, how='outer')
    
    df = df.drop('metro')
    df = df.drop('non-metro')
    df = df.drop('table total')

    return df.iloc[2:81, :]




def calc_pearson(x, y):
    ''' Takes two pandas Series as input, and returns the Pearson coefficient'''
    x = np.array(x)
    y = np.array(y)
    x_bar = np.mean(x)
    y_bar = np.mean(y)
    
    n = sum((x-x_bar)*(y-y_bar))
    d = np.sqrt(sum((x-x_bar)*(x-x_bar))*sum((y-y_bar)*(y-y_bar)))
    
    return(n/d)


def mutual_information(df, n_bins=5):


    # Discretise open space score and affordability %
    n = len(df)
    afford, spaces = [0]*n, [0]*n
    bins = range(0, n_bins)

    bin_width = max(df['Weighted Score'])/n_bins
    for i in range(0, n):
        j = 0
        k = -1
        while df['Weighted Score'][i] >= j :
            j += bin_width
            k += 1
        if k == n_bins:
            k -= 1
        spaces[i] = k

    bin_width = max(df['Affordable %'])/n_bins
    for i in range(0, n):
        j = 0
        k = -1
        while df['Affordable %'][i] >= j :
            j += bin_width
            k += 1
        if k == n_bins:
            k -= 1
        afford[i] = k
        
    d = pd.DataFrame({'Space': spaces, 'Affordable': afford,
         'Name': df['Name'], 'Region': df['Region']})

    return normalized_mutual_info_score(afford, spaces)

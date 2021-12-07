import requests
import pandas as pd
import unicodedata



def scrape_nasa(url, filename=None):
    page = requests.get(url)
    df = pd.read_html(page.text, index_col=0, header=0)
    df = df[0]
    df = df.iloc[0:-1,:]
    df = df.transpose()
    

    if filename:
        df.to_csv(filename)
    
    return df

nasa = 'https://nssdc.gsfc.nasa.gov/planetary/factsheet/'
df = scrape_nasa(nasa, 'planets.csv')


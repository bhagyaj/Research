import networkx as nx
import pandas as pd


df = pd.read_csv('Karachi_Edgelist.csv',delimiter=',')

G = nx.from_pandas_edgelist(df, 'START_NODE', 'END_NODE', edge_attr='LENGTH')
print(nx.shortest_path(G, 1, 600, weight='LENGTH'))

import pandas as pd
import networkx as nx

df = pd.read_csv('network.csv',
				header = None, names =['n1', 'n2', 'weight'])

G = nx.from_pandas_edgelist(df, 'n1', 'n2', edge_attr ='weight')

# The Graph diagram does not show the edge weights.
# However, we can get the weights by printing all the
# edges along with the weights by the command below
print(list(G.edges(data = True)))

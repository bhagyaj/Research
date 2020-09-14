import networkx as nx
import pandas as pd
from minizinc import Instance, Model, Solver,Result,Status
import numpy as np
import ast


class Store(object):
    def __init__(self):
        self.prev_pathsteps = []
        self.maxcount = 10
        self.count = 0
        self.orders = 0
        self.pathct = 0
        self.prev_optimal = []
        self.previous = []
        self.optimal = []
        self.order_data = []
        self.Edges = []
        self.pathstep = []
        self.pathlen = []
        self.maxpath = 0
        self.G = nx.DiGraph()
        self.modified=[]

    def add_instance(self, instance):
        self.orders = instance["orderct"]
        self.pathct = instance["pathct"]
        self.prev_pathsteps = [None] * self.pathct
        self.prev_optimal = [None] * self.orders
        self.order_data = np.array(instance["order"])
        self.Edges = np.array(instance["edet"])
        self.pathstep = np.array(instance["pathstep"])
        self.pathlen = np.array("pathlen")
        self.maxpath = instance["maxpath"]

    def increase_count(self):
        self.count += 1

    def set_previous(self, arr, optimal):
        self.previous = arr
        self.prev_optimal = optimal

    def set_optimal(self, optimal):
        self.optimal = optimal

    def set_prev_pathsteps(self, paths):
        self.prev_pathsteps = paths


gurobi = Solver.lookup("cbc")
grid = Model("./demand_div.mzn")
grid.add_file("./demand_div.dzn")
instance = Instance(gurobi, grid)
store = Store()
store.add_instance(instance)

df = pd.read_csv('network.csv',
				header = None, names =['n1', 'n2', 'weight'])

store.G = nx.from_pandas_edgelist(df, 'n1', 'n2', edge_attr ='weight')
def weight(i, j):
    edges = [(3, 8), (8, 13), (13, 18), (18, 23), (8, 3), (13, 8), (18, 13), (23, 18), (11, 12), (12, 13), (13, 14),
             (14, 15), (12, 11), (13, 12), (14, 13), (15, 14)]

    for touple in edges:
        if touple[0] == i and touple[1] == j:
            return 1
        else:
            return 4


def pathlencal(path):
    fullen=0
    for i in range(0,len(path)-1):
        pre_length = store.G.get_edge_data(path[i],path[i+1])
        print(pre_length)
        length = pre_length.get("weight")
        fullen+=length
    return fullen




def get_optimal():
    optimal = [None] * store.orders
    for i in range(0, store.orders):
        optimal[i] = np.array(
            nx.shortest_path(store.G, store.order_data[i, 0], store.order_data[i, 1], weight='weight'))
        print(pathlencal(optimal[i]))
        #  nx.bidirectional_dijkstra(store.G,store.order_data[i,0],store.order_data[i,1],weight='length'))
        # nx.dijkstra_path(store.G, store.order_data[i, 0], store.order_data[i, 1], weight='length'))
        # nx.johnson(store.G, store.order_data[i, 0], store.order_data[i, 1], weight="length"))
    return optimal


def callminizinc(inst):
    # Find and print all intermediate solutions
    return inst.solve(intermediate_solutions=True)


def capacity_of_edge(edge):
    return store.Edges[edge - 1, 2]


def fill_to_capacity(a1, a2, path_vertices, usage, path_steps):
    capacity = 0.0
    edge = 0
    for i in range(0, len(path_vertices)):
        arr = path_vertices[i]
        ps = path_steps[i]
        for j in range(0, len(path_vertices[i]) - 1):
            if arr[j] == a1 and arr[j + 1] == a2:
                print(arr[j])
                print(usage[i])
                capacity = capacity + float(usage[i])
                edge = ps[j]

    if capacity == capacity_of_edge(edge):
        return 1
    else:
        return 0


def commonedge(usage, path_vertices, path_steps):
    # ordered_paths=order_paths(path_vertices)
    common_edges = [];
    for i in range(0, len(path_vertices)):
        arr = path_vertices[i]
        for j in range(0, len(path_vertices[i]) - 1):
            if (arr[j], arr[j + 1]) not in common_edges and fill_to_capacity(arr[j], arr[j + 1], path_vertices, usage,
                                                                             path_steps):
                common_edges.append((arr[j], arr[j + 1]))
    return common_edges


def compare_path(o_path, arr):
    for i in range(0, len(arr)):
        print(o_path)
        print(arr[i])
        if samepath(o_path, arr[i]):
            return 1
    return 0


def newWeight(element_one, element_two):
    init_length = weight(element_one, element_two)
    pre_length = store.G.get_edge_data(element_one, element_two)
    print(pre_length)
    length = pre_length.get("weight")
    store.G.remove_edge(element_one, element_two)
    iterations = (length - init_length) / 10
    if iterations <= (store.maxcount / 2):
        new_len = length + 1
    else:
        new_len = length - 1
    print(new_len)
    return new_len


def modifyEdges(edges):
    for index, tuple in enumerate(edges):
        element_one = tuple[0]
        element_two = tuple[1]
        store.G.add_edge(element_one, element_two, weight=newWeight(element_one, element_two))


def get_newpath(opt):
    new_path = []
    for i in range(0, len(opt) - 1):
        for j in range(0, len(store.Edges)):
            if store.Edges[j, 0] == opt[i] and store.Edges[j, 1] == opt[i + 1]:
                new_path.append(j + 1)

    return new_path


def exists_new(new_path):
    for i in range(0, len(store.pathstep)):
        if samepath(store.pathstep[i], new_path):
            return 1
    return 0


def modify_paths(new_path,child):
    lenth = len(new_path)
    np.append(store.pathlen, lenth)
    if lenth < store.maxpath:
        for i in range(0, store.maxpath - lenth):
            new_path.append(0)
    print("new_path")
    print(new_path)
    np.append(np.array(instance["pathstep"]), new_path)
    store.pathct += 1
    child["pathlen"]=np.array(store.pathlen)
    # child["pathstep"]=np.array(store.pathstep)
    child["pathct"]= store.pathct


def addPathToInstance(child):
    store.set_prev_pathsteps(store.pathstep)
    for i in range(0, store.orders):
        if not samepath(store.prev_optimal[i], store.optimal[i]):
            new_path = get_newpath(store.optimal[i])
            print(new_path)
            if not (exists_new(new_path)):
                modify_paths(new_path,child)




def new_paths():
    for i in range(0, store.orders):
        if not samepath(store.prev_optimal[i], store.optimal[i]):
            return 1
    return 0


def modify(usage, path_vertices, path_steps,child):
    store.increase_count()
    store.set_previous(path_vertices, store.optimal)
    edges = commonedge(usage, path_vertices, path_steps)
    print(edges)
    modifyEdges(edges)
    print(store.G.get_edge_data(3, 8))
    store.set_optimal(get_optimal())
    print(store.prev_optimal)
    print(store.optimal)
    if not new_paths():
        print("no new paths")
        exit_handler(3)
    else:
        addPathToInstance(child)
    return


def exit_handler(x):
    return {
        0: exit("No new results generated"),
        1: exit("Optimal found"),
        2: exit("maximum iterations made"),
        3: exit("no new path generated")
    }.get(x, "invalid exit call")


def check_optmal(arr):
    for i in range(0, store.orders):
        if not compare_path(store.optimal[i], arr):
            return 0
    return 1


def iterator(usage, path_vertices, path_steps,child):
    print("in iterator")
    if check_optmal(path_vertices):
        exit_handler(1)

    elif store.count == store.maxcount:
        print("couldn't find optimal")
        exit_handler(2)

    else:
        modify(usage, path_vertices, path_steps,child)
        print("new path count")
        print(child["pathct"])
        result = callminizinc(child)
        checker(result)


def samepath(prev_path, path):
    if len(prev_path) == len(path):
        return (np.array(prev_path) == np.array(path)).all()
    else:
        return 0


# print(opt_pathsteps)
def matcher(usage, path_vertices, path_steps,child):
    if len(store.previous) != len(path_vertices):
        iterator(usage, path_vertices, path_steps,child)
    for i in range(0, len(path_vertices)):
        if not samepath(store.previous[i], path_vertices[i]):
            iterator(usage, path_vertices, path_steps,child)
    exit_handler(1)


def format_result(format):
    arr = []
    for i in range(1, len(format) - 1):
        paths = format[i]
        a = np.fromstring(paths[1:-1], dtype=np.int, sep=',')
        arr.append(a)
    return arr


def convert_array(st_arr):
    arr = []
    for i in range(0, len(st_arr) - 1):
        paths = st_arr[i]
        a = np.fromstring(paths[1:-1], dtype=np.int, sep=',')
        arr.append(a)
    return arr


def conversion(st_arr):
    arr = st_arr.split(",")
    return np.array(arr)


def checker(result):
    res: Result = result
    print(res.solution)
    print(res.status)
    while res.status.has_solution():
        with instance.branch() as child:
            print(result.solution[0])
            # output = str(result.solution[0]).split("\n")
            output = str(result.solution[0]).split("path_steps")
            format = output[0].split("\n")
            path_s = output[1]
            usage = ast.literal_eval(format[0])
            path_vertices = format_result(format)
            # ae = conversion(path_s)
            # print(ae)
            path_steps = ast.literal_eval(path_s)
            print(usage)
            # print()
            print(path_steps[0])
            if store.count == 0:
                print("went to iterator")
                iterator(usage, path_vertices, path_steps,child)
            else:
                matcher(usage, path_vertices, path_steps,child)





store.set_optimal(get_optimal())
print("first optimal")
print(store.optimal)
checker(callminizinc(instance))

# order_data = np.array(instance["order"])
# print(order_data)
# for i in range(0,instance["orderct"]):
#     print(nx.shortest_path(G,order_data[i,0],order_data[i,1]))
# #     return optimal

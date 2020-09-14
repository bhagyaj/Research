from minizinc import Instance, Model, Solver,Result,Status
import pandas as pd
import numpy as np

gurobi = Solver.lookup("cbc")
grid = Model("./demand_div.mzn")
grid.add_file("./demand_div.dzn")
instance = Instance(gurobi, grid)
result = instance.solve()
res: Result = result
while res.status.has_solution():
    with instance.branch() as child:
        child["pathstep"]=list(instance["pathstep"])
        child["pathct"]=1
        child["pathlen"]=list(instance["pathlen"])
        child.solve()

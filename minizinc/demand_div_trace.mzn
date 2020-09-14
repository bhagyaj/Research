include "demand_div.mzn";
include "globals.mzn";

constraint forall(o in Order,p in Path where usage[o,p]!= 0.0)(
 trace("\(o)\n"++
" \(row(pathstep,p))\n")
);


function array [int] of int: vertices_par(Path: p) = [start_par(pathstep[p, 1])] ++ [end_par(pathstep[p, i])|i in 1..pathlen[p]];

output["\([o|o in Order])\n"] ++

% ["\([start_par(pathstep[p,i])|i in Pathindex where i <= pathlen[p]])"|o in Order,p in Path where fix(usage[o,p])!=0.0]


["\(vertices_par(p))"|o in Order, p in Path where fix(usage[o,p])!=0.0]++
["\n\(end_par(pathstep[10, 5]))"]

% ["\([start_par(pathstep[p,1])[end_par(pathstep[p,i])|i in Pathindex where i <= pathlen[p] ]|p in Path])"|o in Order]
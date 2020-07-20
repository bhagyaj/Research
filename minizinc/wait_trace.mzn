include "joined2.mzn";

constraint forall (e in EDGE) (
  let {
    set of CITY: src = { c | c in CITY where e in outgoing[c] };
    set of CITY: dest = { c | c in CITY where e in incoming[c] };
  } in
  trace("\(e): \(src) -> \(dest) [\(capacity[e])]\n")
  );

output
  ["\([c | c in CITY])\n"] ++
  [
  "\([ sum (f in FLOW, e in incoming[c]) (path_demand[f,t,e]) | c in CITY ])\n"
  | t in TIME ] ++
  ["\([e | e in EDGE])\n"] ++
  [
  "\([ sum (f in FLOW) (path_demand[f, t, e]) | e in EDGE])\n"
  | t in TIME ]
%   ++["\n\(path_demand[1, 0, e])"]++["\n\(path_demand[2, 0, m])"]
  ++["\n\(sumOfIn_par(1,0,B))"]++["\n\(sumOfOut_par(1,1,B))\n"]
  ++["\([run[f]|f in FAIL])\n"]
  ++["\([startT[f]|f in FAIL])\n"]
%   ++["\(withinblocked(3,0))\n"]
%   ++["\n Wait \n"]++

%  ["\([c | c in CITY])\n"] ++
%   [
%   "\([ sum (f in FLOW, e in incoming[c]) (wait[f,t,e]) | c in CITY ])\n"
%   | t in TIME ] ++
%   ["\([e | e in EDGE])\n"] ++
%   [
%   "\([ sum (f in FLOW) (wait[f, t, e]) | e in EDGE])\n"
%   | t in TIME ] 

include "wait.mzn";

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

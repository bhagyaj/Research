include  "globals.mzn";
include "joined2.dzn";
enum CITY;
enum EDGE;
int: noEdges;
array[CITY] of set of EDGE: incoming;
array[CITY] of set of EDGE: outgoing;
array[EDGE] of int: capacity;
int: MAX_CAP = max(capacity);
int: flows = 2;
set of int: FLOW = 1..flows;
int: fails;
set of int: FAIL = 1..fails;
int: range = noEdges+tot;
set of int: TIME = 0..range;

set of int: PATHS = 1..noEdges;
array[FLOW] of CITY: start = [A,B];
array[FLOW] of CITY: end = [E,H];
array[FAIL] of CITY: fail_points;
array[FLOW] of int: demand = [300,100];
array[FLOW,TIME,EDGE] of var 0..MAX_CAP:path_demand;
% array[FLOW,TIMES,EDGE] of var 0..MAX_CAP:path_demand;
set of EDGE: self_edges;
var int:total_distance;


enum RESOURCE;
array[RESOURCE] of int: L; %resource limit
array[RESOURCE,FAIL] of int: res;
array[FAIL] of int: duration;
int: tot = sum(duration);
set of int: TIMES= 0..tot+noEdges;
array[FAIL] of var TIMES: startT;
array[FAIL] of var TIMES: run = [startT[f]+duration[f]|f in FAIL];
var TIMES: makespan = max(t in FAIL)(startT[t]+duration[t]); 


constraint forall(r in RESOURCE)(cumulative(startT,duration,[res[r,t]|t in FAIL],L[r])); %cumulative constraint
constraint forall(f in FLOW)(sum(t in TIME)(sumOfOutPath(f,t,start[f]))=demand[f]);  %valid start
constraint forall(f in FLOW)(sum(t in TIME)(sumOfIn(f,t,end[f]))=demand[f]);  %valid end
constraint forall(f in FLOW)(forall(e in incoming[start[f]], t in TIME)(path_demand[f,t,e]!=0 -> e in self_edges)); %no incoming is allowed for source except wait
constraint forall(f in FLOW) ( sum(t in TIME)(sumOfOut(f,t,end[f])) = 0); %no outgoing is allowed from destination
constraint forall(e in EDGE,t in TIME)(sum(i in FLOW)(path_demand[i,t,e])<=capacity[e]); 
constraint forall(f in FLOW)(forall(c in CITY diff {end[f]})(forall(t in 0..range-1)( sumOfIn(f,t,c)=sumOfOut(f,t+1,c)))); %conservation of flow
constraint forall(i in FAIL)(forall(f in FLOW, e in incoming[fail_points[i]],t in 0..range-1)(if withinblocked(i,t) then path_demand[f,t,e]=0 else sumOfIn(f,t,fail_points[i])=sumOfOut(f,t+1,fail_points[i]) endif)); %fail points skipped
constraint forall(i in FAIL)(forall(f in FLOW, e in outgoing[fail_points[i]],t in 0..range-1)(if withinblocked(i,t) then path_demand[f,t,e]=0 else sumOfIn(f,t,fail_points[i])=sumOfOut(f,t+1,fail_points[i]) endif));
constraint total_distance = sum(path_demand)div flows;
solve:: seq_search([
       int_search([path_demand[f,t,e]| f in FLOW, e in EDGE, t in TIME],smallest,indomain_min),
       int_search([run[f]| f in FAIL],smallest,indomain_min) ])
        minimize total_distance+makespan;
        
function var int: sumOfIn(int: f, int: t, CITY: c)= sum(e in incoming[c])(path_demand[f,t,e]);
function var int: sumOfOut(int: f, int: t, CITY: c)= sum(e in outgoing[c])(path_demand[f,t,e]);
function var int: sumOfOutPath(int: f, int: t, CITY: c)= sum(e in outgoing[c] diff self_edges)(path_demand[f,t,e]);
function int: sumOfIn_par(int: f, int: t, CITY: c)= sum(e in incoming[c])(fix(path_demand[f,t,e]));
function int: sumOfOut_par(int: f, int: t, CITY: c)= sum(e in outgoing[c])(fix(path_demand[f,t,e]));
% predicate withinblocked(int: i, int: t)= if i=1 then t<= run[i] else t<= run[i] /\ t>= run[i-1] endif;
predicate withinblocked(int: i, int: t) = t>= start[i] /\ t<=run[i];
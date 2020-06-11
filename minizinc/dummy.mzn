include  "globals.mzn";
include "timeRoute.dzn";
enum CITY;
enum EDGE;
int: noEdges;
array[CITY] of set of EDGE: incoming;
array[CITY] of set of EDGE: outgoing;
array[EDGE] of int: capacity;
int: MAX_CAP = max(capacity);
int: flows = 2;
set of int: FLOW = 1..flows;
int: fails =1;
set of int: FAIL = 1..fails;
set of int: TIME = 0..noEdges;
set of int: PATHS = 1..noEdges;
array[FLOW] of CITY: start = [A,B];
array[FLOW] of CITY: end = [E,H];
array[FAIL] of CITY: fail_points = [D];
array[FLOW] of int: demand = [200,100];
array[FLOW,TIME,EDGE] of var 0..MAX_CAP:path_demand;
var int:total_distance;

constraint forall(i in FLOW) (sum (e in outgoing[start[i]]) (path_demand[i,0,e])=demand[i]); %valid start
constraint forall(f in FLOW)(sumOfIn(f,0,end[f])=0);  %valid end
constraint forall(f in FLOW)(sum(t in TIME)(sumOfIn(f,t,end[f]))=demand[f]);  %valid end
constraint forall(e in EDGE,t in TIME)(sum(i in FLOW)(path_demand[i,t,e])<=capacity[e]);  %valid capacity
constraint forall(f in FLOW) ( sum(t in TIME)(sumOfIn(f,t,start[f])) = 0); %no incoming is allowed for source
constraint forall(f in FLOW) ( sum(t in TIME)(sumOfOut(f,t,end[f])) = 0); %no outgoing is allowed from destination
constraint forall(i in FLOW)(forall(c in CITY diff {start[i], end[i]})(forall(t in 0..noEdges-1)(if t=0  then sumOfOut(i,t,c)=0 else sumOfIn(i,t,c)=sumOfOut(i,t+1,c) endif))); %conservation of flow


constraint forall(i in FAIL)(forall(f in FLOW, e in incoming[fail_points[i]],t in TIME)(path_demand[i,t,e]=0)); %fail points skipped
constraint forall(i in FAIL)(forall(f in FLOW, e in outgoing[fail_points[i]],t in TIME)(path_demand[i,t,e]=0));
constraint total_distance = sum(path_demand)div flows;
solve::int_search([path_demand[f,t,e]| f in FLOW, e in EDGE, t in TIME],smallest,indomain_min)
        minimize total_distance;


function var int: sumOfIn(int: f, int: t, CITY: c)= sum(e in incoming[c])(path_demand[f,t,e]);
function var int: sumOfOut(int: f, int: t, CITY: c)= sum(e in outgoing[c])(path_demand[f,t,e]);
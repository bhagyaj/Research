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
array[FLOW] of int: demand = [300,100];
array[FLOW,TIME,EDGE] of var 0..MAX_CAP:path_demand;
var int:total_distance;

constraint forall(f in FLOW) ( sum (e in outgoing[start[f]]) (path_demand[f,0,e]) = overload(f)); %wait at start
constraint forall(f in FLOW) ( sum (e in outgoing[start[f]],t in TIME where path_demand[f,t,e]!=0) (path_demand[f,t,e]) = demand[f]); %valid start
constraint forall(f in FLOW)(sum(e in incoming[end[f]],t in TIME where path_demand[f,t,e]!=0)(path_demand[f,t,e])=demand[f]);  %valid end
constraint forall(f in FLOW)(forall(c in CITY diff {start[f], end[f]})(forall(t in 1..noEdges-1)(sum(e in outgoing[c])(path_demand[f,t+1,e])=wait(c,t,f))));  %onservation of flow with wait
constraint forall(i in FAIL)(forall(f in FLOW, e in incoming[fail_points[i]],t in TIME)(path_demand[f,t,e]=0)); %fail points skipped
constraint forall(i in FAIL)(forall(f in FLOW, e in outgoing[fail_points[i]],t in TIME)(path_demand[f,t,e]=0));
constraint total_distance = sum(path_demand)div flows;
solve::int_search([path_demand[f,t,e]| f in FLOW, e in EDGE, t in TIME],smallest,indomain_min)
        minimize total_distance;
        
predicate needwait(CITY: c, int: t,int: flow)= sum(e in incoming[c])(path_demand[flow,t,e]) > outgoing_capacity(flow);

predicate fail_point(EDGE: e) = forall(i in FAIL)(e in incoming[fail_points[i]] \/  e in outgoing[fail_points[i]]);

function int: overload(int: i) = if demand[i] > outgoing_capacity(i) then outgoing_capacity(i)  else demand[i] endif;

function int: outgoing_capacity(int: i) =  sum(e in outgoing[start[i]] where not fail_point(e))(capacity[e]);

function var int: wait(CITY: c, int: t,int: flow) = if needwait(c,t,flow) then outgoing_capacity(flow) else sum(e in incoming[c])(path_demand[flow,t,e]) endif;



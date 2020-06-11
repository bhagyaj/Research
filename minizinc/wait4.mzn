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
array[FLOW,TIME] of var 0..MAX_CAP: wait_0;  %store waiting at time 0
array[FLOW,TIME,EDGE] of var 0..MAX_CAP:wait;
var int: wait_at_0;
var int:total_distance;

% constraint forall(f in FLOW) (forall(t in TIME) (if t=0 then wait_0[f,t] = demand[f]-sumOfOut(f,t,start[f])  else wait_0[f,t-1]= sumOfOut(f,t,start[f]) + wait_0[f,t] endif)); %wait at start
constraint forall(f in FLOW)(wait_0[f,0] = demand[f]-sumOfOut(f,0,start[f]));
constraint forall(f in FLOW, t in TIME where t!=0) (wait_0[f,t] = wait_0[f,t-1]- sumOfOut(f,t,start[f])); 
constraint forall(f in FLOW) ( sum (e in outgoing[start[f]],t in TIME) (path_demand[f,t,e]) = demand[f]); %valid start
constraint forall(f in FLOW)(sumOfIn(f,0,end[f])=0);  %valid end
constraint forall(f in FLOW)(sum(t in TIME)(sumOfIn(f,t,end[f]))=demand[f]);  %valid end
constraint forall(f in FLOW) ( sum (e in incoming[start[f]],t in TIME) (path_demand[f,t,e]) = 0); %no incoming is allowed for source
constraint forall(f in FLOW) ( sum (e in outgoing[end[f]],t in TIME) (path_demand[f,t,e]) = 0); %no outgoing is allowed from destination
constraint forall(e in EDGE,t in TIME)(sum(i in FLOW)(path_demand[i,t,e])<=capacity[e]); 
constraint forall(e in EDGE,t in 1..noEdges)(sum(i in FLOW)(wait[i,t,e])<=capacity[e]); 
constraint forall(f in FLOW)(forall(c in CITY diff {start[f], end[f]})(forall(t in 0..noEdges-1)(if t=0 then  sumOfOut(f,t,c)=0 /\  sumOfInWait(f,t,c)=0 else sumOfIn(f,t,c)=sumOfOut(f,t+1,c)+sumOfInWait(f,t+1,c) endif))); %conservation of flow
% constraint forall(f in FLOW)(forall(c in CITY diff {start[f], end[f]})(forall(t in 0..noEdges-1)(sumOfIn(f,t,c)=sumOfOut(f,t+1,c)+sumOfInWait(f,t+1,c) )));
constraint forall(i in FAIL)(forall(f in FLOW, e in incoming[fail_points[i]],t in TIME)(path_demand[f,t,e]=0)); %fail points skipped
constraint forall(i in FAIL)(forall(f in FLOW, e in outgoing[fail_points[i]],t in TIME)(path_demand[f,t,e]=0));
constraint forall(i in FAIL)(forall(f in FLOW, e in incoming[fail_points[i]],t in 1..noEdges)(wait[f,t,e]=0)); %fail points skipped
constraint forall(i in FAIL)(forall(f in FLOW, e in outgoing[fail_points[i]],t in 1..noEdges)(wait[f,t,e]=0));
constraint wait_at_0=sum(wait_0);
% constraint total_distance = (sum(path_demand)+sum(wait)+wait_at_0)div flows;
constraint total_distance = (sum(path_demand)+sum(wait)+sum(wait_0))div flows;
solve:: seq_search([
       int_search([path_demand[f,t,e]| f in FLOW, e in EDGE, t in TIME],smallest,indomain_min),
       int_search([wait_0[f,t]| f in FLOW, t in TIME],smallest,indomain_min),
       int_search([wait[f,t,e]| f in FLOW,e in EDGE, t in 1..noEdges],smallest,indomain_min) ])
        minimize total_distance;
        
 
        
function var int: sumOfIn(int: f, int: t, CITY: c)= sum(e in incoming[c])(path_demand[f,t,e]);
function var int: sumOfOut(int: f, int: t, CITY: c)= sum(e in outgoing[c])(path_demand[f,t,e]);
function var int: sumOfInWait(int: f, int: t, CITY: c)= sum(e in incoming[c])(wait[f,t,e]);




% Data and data checks, definitions and functions to make things easier to read
include "table.mzn";

int:vertexct; %no.of vertices
set of int: Vertex = 1..vertexct;

int:orderct; %no.of orders
set of int: Order = 1..orderct ;
enum Oindex = {orig,dest,demand} ;
array [Order,Oindex] of int : order ;
constraint assert(forall(o in Order)(order[o,orig] in Vertex /\ order[o,dest] in Vertex),"Ill defined order") ;
function Vertex: orig(Order:o) = order[o,orig] ;
function Vertex: dest(Order:o) = order[o,dest] ;
function Vertex: demand(Order:o) = order[o,demand] ;

int:edgect; %no.of edges
set of int: Edge = 1..edgect;  % We need the dummy edge otherwise the objective definition fails
enum Eindex = {start,end,cap,len,cost} ;
array[Edge,Eindex] of int: edet ;
constraint assert(forall(e in Edge)(edet[e,start] in Vertex /\ edet[e,end] in Vertex) ,"Illdefined edge") ;
function var Vertex: start(var Edge:e) = edet[e,start] ;
function Vertex: start_par(Edge:e) = edet[e,start] ;
function var Vertex: end(var Edge:e) = edet[e,end] ;
function Vertex: end_par(Edge:e) = edet[e,end] ;
function var Vertex: cap(var Edge:e) = edet[e,cap] ;
function  0..40: len( Edge:e) = edet[e,len] ;
function var 0..50: cost(var Edge:e) = edet[e,cost] ;

int:pathct ;
set of int:Path = 1..pathct;
int:maxpath ;
int: MAX_CAPACITY;
set of int:Pathindex = 1..maxpath ;
array [Path,Pathindex] of 0..edgect: pathstep ; 
array[Path] of 0..maxpath:pathlen ; 
array[Order,Path] of var 0.0..MAX_CAPACITY: usage;
constraint assert( (forall( p in Path, i in Pathindex)(i<=pathlen[p] -> pathstep[p,i] in Edge)),"Ill defined path length") ;
constraint assert((forall (p in Path, i in Pathindex)(i>pathlen[p] -> pathstep[p,i] =0)),"Ill defined path length") ;

constraint forall(o in Order,p in Path)(usage[o,p]<=path_capacity(p));
constraint forall(o in Order)(sum(p in Path)(usage[o,p])= demand(o));

constraint forall(o in Order)(forall(p in Path)(usage[o,p]!=0.0 -> start(pathstep[p,1])=orig(o))); %valid start
constraint forall(o in Order)(forall(p in Path)(usage[o,p]!=0.0 -> end(pathstep[p,pathlen[p]]) = dest(o))); %valid end
% constraint forall(e in Edge)(sum(o in Order,p in Path where usage[o,p]!=0.0)(sum(i in Pathindex where i <= pathlen[p])((pathstep[p,i]=e)*usage[o,p]))<=cap(e)); %capacity
constraint forall(e in Edge)(sum (o in Order, p in Path where exists (i in 1..pathlen[p]) (pathstep[p,i]=e)) (usage[o, p]) <= cap(e));

% var int: tot_cost=sum(o in Order)(pathcost(select[o]));
var 0.0..10000.0: obj=sum(o in Order,p in Path)(usage[o,p] * pathlength(p));

solve minimize obj;

output["\([usage[o,p]|o in Order, p in Path where fix(usage[o,p])!=0.0 ])\n"]++
["\(vertices_par(p))\n"|o in Order, p in Path where fix(usage[o,p])!=0.0]++
["path_steps \n"]++
["\(pathsteps_par(p)),"|o in Order, p in Path where fix(usage[o,p])!=0.0]
;

function array [int] of int: vertices_par(Path: p) = [start_par(pathstep[p, 1])] ++ [end_par(pathstep[p, i])|i in 1..pathlen[p]];
function array [int] of int: pathsteps_par(Path: p) = [pathstep[p, i]|i in 1..pathlen[p]];
function int: pathlength( int: p)=sum(i in Pathindex ) (if i <= pathlen[p] then len(pathstep[p,i]) else 0 endif);
function var int: pathcost(var int: p)=sum(i in Pathindex ) (if i <= pathlen[p] then cost(pathstep[p,i]) else 0 endif);
function var int: path_capacity(int: p)=min(i in 1..pathlen[p])(cap(pathstep[p,i]));

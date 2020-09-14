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
function var Vertex: start_par(Edge:e) = edet[e,start] ;
function var Vertex: end(var Edge:e) = edet[e,end] ;
function var Vertex: cap(var Edge:e) = edet[e,cap] ;
function var 0..10: len(var Edge:e) = edet[e,len] ;
function var 0..10: cost(var Edge:e) = edet[e,cost] ;

int:pathct ;
set of int:Path = 1..pathct;
int:maxpath ;
set of int:Pathindex = 1..maxpath ;
array [Path,Pathindex] of 0..edgect: pathstep ; 
array[Path] of 0..maxpath:pathlen ; 
array[Order] of var Path: select;
constraint assert( (forall( p in Path, i in Pathindex)(i<=pathlen[p] -> pathstep[p,i] in Edge)),"Ill defined path length") ;
constraint assert((forall (p in Path, i in Pathindex)(i>pathlen[p] -> pathstep[p,i] =0)),"Ill defined path length") ;


constraint forall(o in Order)(start(pathstep[select[o],1])=orig(o)); %valid start
constraint forall(o in Order)(end(pathstep[select[o],pathlen[select[o]]]) = dest(o)); %valid end
constraint forall(e in Edge)(sum(o in Order)(sum(i in Pathindex where i <= pathlen[select[o]])((pathstep[select[o],i]=e)*demand(o)))<=cap(e)); %capacity

% var int: tot_cost=sum(o in Order)(pathcost(select[o]));
var int: obj=sum(o in Order)(pathlength(select[o]));

solve minimize obj;

output["pathlengths- "++"\([pathlen[p]|p in Path])\n", "selected paths- "++"\(select)\n"]++["newly generated paths- \(p) "++"\([pathstep[p,i]|i in Pathindex])\n"|p in Path];

function var int: pathlength(var int: p)=sum(i in Pathindex ) (if i <= pathlen[p] then len(pathstep[p,i]) else 0 endif);
function var int: pathcost(var int: p)=sum(i in Pathindex ) (if i <= pathlen[p] then cost(pathstep[p,i]) else 0 endif);

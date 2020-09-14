include "globals.mzn"; 

int: rows;
int: cols;

array[1..rows,1..cols] of int: m;

% decision variables
array[1..cols] of var 0..1: x; % the selected columns (1: selected)
var 1..cols: z = sum(x); % number of selected columns 

solve minimize z;
% solve satisfy;
% solve :: int_search(x, first_fail, indomain_min, complete) satisfy;

constraint
  forall(r1,r2 in 1..rows where r1 < r2) (
    sum([ x[j]*(m[r1,j] != m[r2,j]) | j in 1..cols]) >= 1
  )

;

output [
  "z: \(z)\n",
  "x: \(x)\n",
  "rows: \(rows)\ncols: \(cols)\n"
]
++
[
  show([m[r,c] | c in 1..cols where fix(x[c]) = 1]) ++ "\n"
  | r in 1..rows
]
;
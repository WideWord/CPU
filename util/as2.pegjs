File = ws* p:Prog ws* { return p; }

Prog
    = h:Line ws* t:Prog { return [h].concat(t); }
    / '' { return []; }
   
Line
    = c:Command ws* ';' { return { command: c }; }
    / l:LabelDecl { return { label: l }; }


Command
    = to:Storage ws* '=' ws* a:Storage ws* op:BinOp ws* b:Storage
    { return { type: 'binop', op: op, a: a, b: b }; }
    / to:Storage ws* '=' ws* from:Storage
    { return { type: 'assign', to: to, from: from }; }
    / (Conditional ws*)? type:('jump'/'call') ws+ addr:LabelInst
    { return { type: type, addr: { label: addr } }; }
    / 'cmp' ws+ a:Register ws* ',' ws* b:Storage
    { return { type: 'cmp', a: a, b: b }; }
    / 'data' ws+ (MemSizeQualifer ws+)? Data

Data = int

BinOp = '+' / '-'

Storage
    = size:MemSizeQualifer ws* '[' ws* base:MemBase offset:(ws* o:MemOffset { return o; })? ws* ']'
    { return { mem: { size: size, base: base, offset: offset } }; }
    / r:Register { return { reg: r }; }
    / c:constant { return { constant: c }; }

MemBase
    = r:Register { return { reg: r }; }
    / l:LabelInst { return { label: l }; }
MemOffset = s:('+' / '-') ws* c:int { if (s == '+') return c; else return -c; }

MemSizeQualifer = s:('signed' ws+)? size:('word' { return 2; } / 'byte' { return 1; } / '' { return 4; })
{ return { bytes: size, signed: s != null }; }

Register = '#' n:int { return n; }

Conditional = 'if' ws+ Condition

Condition
    = 'equal'
    / 'not equal'
    / 'less'
    / 'greater'
    / 'signed' ws+ 'less'
    / 'signed' ws+ 'greater'

LabelDecl 
    = name:id ws* ':' { return { type: 'global', name: name }; }
    / '.' ws* name:id ws* ':' { return { type: 'local', name: name }; }

LabelInst
    = '.' name:id { return '.' + name; }
    / glob:id '.' loc:id { return glob + '.' + loc; }
    / name:id { return name; }

id = h:[a-zA-Z_&] t:[a-zA-Z_&0-9]* { return [h].concat(t).join(""); }
constant = int / '-' ws* int
int = d:[0-9]+ { return parseInt(d.join("")); }
ws = [ \t\n]

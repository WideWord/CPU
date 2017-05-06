File = ws* p:Prog ws* { return p; }

Prog
    = h:Line ws* t:Prog { return [h].concat(t); }
    / '' { return []; }
   
Line
    = c:Command ws* ';' { return { command: c }; }
    / l:LabelDecl { return { label: l }; }
    / '//' [^\n]* '\n' { return {}; }


Command
    = to:Storage ws* '=' ws* a:Storage ws* op:BinOp ws* b:Storage
    { return { type: 'binop', to: to, op: op, a: a, b: b }; }
    / to:Storage ws* '=' ws* op:UnOp ws* a:Storage ws*
    { return { type: 'unop', to: to, op: op, a: a }; }
    / to:Storage ws* '=' ws* from:Storage
    { return { type: 'assign', to: to, from: from }; }
    / c:(c:Conditional ws* { return c; })? type:('jump'/'call') ws+ addr:LabelInst
    { return { type: type, addr: { label: addr }, condition: c }; }
    / c:(c:Conditional ws* { return c; })? 'ret'
    { return { type: 'ret', condition: c }; }
    / 'cmp' ws+ a:Register ws* ',' ws* b:Storage
    { return { type: 'cmp', a: { reg: a }, b: b }; }
    / 'data' ws+ (MemSizeQualifer ws+)? Data
    / to:Storage ws* '+=' ws* c:int
    { return { type: '+=', to: to, value: { constant: c } }; }
    / to:Storage ws* '-=' ws* c:int
    { return { type: '+=', to: to, value: { constant: -c } }; }
    
Data = int

BinOp = '+' / '-' / '^' / '&' / '|'
UnOp = '~'

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

Register 
    = '#' n:int { return n; }
    / '#sp' { return 30; }
    / '#flags' { return 31; }

Conditional = 'if' ws+ c:Condition { return c; }

Condition
    = 'equal' { return 1; }
    / 'not' ws+ 'equal' { return 2 + 4; }
    / 'less' { return 2; }
    / 'greater' { return 4; }
    / 'signed' ws+ 'less' { return 8; }
    / 'signed' ws+ 'greater' { return 16; }

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

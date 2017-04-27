Prog = lines:Line* { 
    let result = [];
    let labels = {};
    for (const line of lines) {
        if (Array.isArray(line)) {
            result = result.concat(line);
        } else if (line.label) {
            labels[line.label] = result.length;
        }
    }
    for (const i in result) {
        if (result[i].inst) {
            result[i] = (labels[result[i].inst] >> (result[i].byte * 8)) & 0xFF;
        }
    }
    return result;
}

Line
    = ws* c:Command ws* ';' ws* { return c; }
    / ws* id:LabelIdentifier ws* ':' ws* { return { label: id }; }
    
Command
    = r:Register ws* '=' ws* a:Register ws* op:BinaryOp ws* b:Register { return [op, r, a, b] }
    / r:Register ws* '=' ws* a:Register { return [0x0, r, a, 0x0] }
    / r:Register ws* '=' ws* '~' ws* a:Register { return [0x6, r, a, 0x0] }
    / r:Register ws* '=' ws* c:Constant { 
        const rc = c & 0xFFFFFFFF;
        let result = [0x10, r, rc & 0xFF, (rc >> 8) & 0xFF];
        if ((c >> 16) != 0) {
            result = result.concat([0x12, r, (rc >> 16) & 0xFF, (rc >> 24) & 0xFF]);
        }
        return result;
    }
    / r:Register ws* '=' ws* id:LabelIdentifier {
        return [0x10, r, { inst: id, byte: 0 }, { inst: id, byte: 1 }];
    }
    / r:Register ws* '+=' ws* c:Constant {
        const rc = c & 0xFFFF;
        return [0x13, r, rc & 0xFF, (rc >> 8) & 0xFF];
    }
    / r:Register ws* '-=' ws* c:Constant {
        const rc = -c & 0xFFFF;
        return [0x13, r, rc & 0xFF, (rc >> 8) & 0xFF];
    }
    / "compare" ws+ r: Register ws* "," ws* a:Register { return [0x14, r, a, 0x0]; }
    / "compare" ws+ r: Register ws* "," ws* c:Constant {
        const rc = c & 0xFFFF;
        return [0x16, r, rc & 0xFF, (rc >> 8) & 0xFF];
    }
    / 'byte' ws* '[' ws* a:Register ws* ']' ws* '=' ws* r:Register { return [0x25, r, a, 0x0]; }
    / 'word' ws* '[' ws* a:Register ws* ']' ws* '=' ws* r:Register { return [0x26, r, a, 0x0]; }
    / '[' ws* a:Register ws* ']' ws* '=' ws* r:Register { return [0x27, r, a, 0x0]; }
    / 'byte' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x25, r, a, c & 0xFF]; }
    / 'word' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x26, r, a, c & 0xFF]; }
    / '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x27, a, r, c & 0xFF]; }
    / 'byte' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x25, r, a, -c & 0xFF]; }
    / 'word' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x26, r, a, -c & 0xFF]; }
    / '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' ws* '=' ws* r:Register { return [0x27, a, r, -c & 0xFF]; }
    
    / r:Register  ws* '=' ws* 'byte' ws* '[' ws* a:Register ws* ']' { return [0x20, r, a, 0x0]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'byte' ws* '[' ws* a:Register ws* ']' { return [0x21, r, a, 0x0]; }
    / r:Register  ws* '=' ws* 'word' ws* '[' ws* a:Register ws* ']' { return [0x22, r, a, 0x0]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'word' ws* '[' ws* a:Register ws* ']' { return [0x23, r, a, 0x0]; }
    / r:Register  ws* '=' ws* '[' ws* a:Register ws* ']' { return [0x24, r, a, 0x0]; }
    
    / r:Register  ws* '=' ws* 'byte' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' { return [0x20, r, a, c & 0xFF]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'byte' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' { return [0x21, r, a, c & 0xFF]; }
    / r:Register  ws* '=' ws* 'word' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' { return [0x22, r, a, c & 0xFF]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'word' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' { return [0x23, r, a, c & 0xFF]; }
    / r:Register  ws* '=' ws* '[' ws* a:Register ws* '+' ws* c:Constant ws* ']' { return [0x24, r, a, c & 0xFF]; }
    
    / r:Register  ws* '=' ws* 'byte' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' { return [0x20, r, a, -c & 0xFF]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'byte' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' { return [0x21, r, a, -c & 0xFF]; }
    / r:Register  ws* '=' ws* 'word' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' { return [0x22, r, a, -c & 0xFF]; }
    / r:Register  ws* '=' ws* 'signed' ws+ 'word' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' { return [0x23, r, a, -c & 0xFF]; }
    / r:Register  ws* '=' ws* '[' ws* a:Register ws* '-' ws* c:Constant ws* ']' { return [0x24, r, a, -c & 0xFF]; }
    
    / cond:ConditionPostfix 'jump' ws+ r:Register { return [0x30, r, 0, cond]; }
    / cond:ConditionPostfix 'jump' ws+ '+' ws* c:Constant {
        const cr = c & 0xFFFF;
        return [0x31, cr & 0xFF, (cr >> 8) & 0xFF, cond];
    }
    / cond:ConditionPostfix 'jump' ws+ '-' ws* c:Constant {
        const cr = -c & 0xFFFF;
        return [0x31, cr & 0xFF, (cr >> 8) & 0xFF, cond]; 
    }
    / cond:ConditionPostfix 'jump' ws+ 'local' ws+ c:Constant {
        const cr = c & 0xFFFF;
        return [0x32, cr & 0xFF, (cr >> 8) & 0xFF, cond]; 
    }
    
    / cond:ConditionPostfix 'jump' ws+ id:LabelIdentifier {
        return [0x32, { inst: id, byte: 0 }, { inst: id, byte: 1 }, cond];
    }
    
    / cond:ConditionPostfix 'call' ws+ r:Register { return [0x33, r, 0, cond]; }
    / cond:ConditionPostfix 'call' ws+ '+' ws* c:Constant {
        const cr = c & 0xFFFF;
        return [0x34, cr & 0xFF, (cr >> 8) & 0xFF, cond];
    }
    / cond:ConditionPostfix 'call' ws+ '-' ws* c:Constant {
        const cr = -c & 0xFFFF;
        return [0x34, cr & 0xFF, (cr >> 8) & 0xFF, cond]; 
    }
    / cond:ConditionPostfix 'call' ws+ 'local' ws+ c:Constant {
        const cr = c & 0xFFFF;
        return [0x35, cr & 0xFF, (cr >> 8) & 0xFF, cond]; 
    }
    / cond:ConditionPostfix 'call' ws+ id:LabelIdentifier {
        return [0x35, { inst: id, byte: 0 }, { inst: id, byte: 1 }, cond];
    }
    
    / cond:ConditionPostfix 'ret' { return [0x36, 0, 0, cond]; }
    
    / 'nop' { return [0x0, 0x0, 0x0, 0x0]; }
    
    
ConditionPostfix = cond:('if' ws+ c:Condition ws+ { return c; })? { if (cond) return cond; else return 0; }

Condition
    = ('==' / 'equal') { return 0x1 }
    / ('>' / 'greater') { return 0x2 }
    / ('<' / 'less') { return 0x4; }
    / ('!=' / 'not' ws+ 'equal') { return 0x2 | 0x4; }
    / ('>=' / 'not' ws+ 'less') { return 0x2 | 0x1; }
    / ('<=' / 'not' ws+ 'greater') { return 0x4 | 0x1; }
    / 'signed' ws+ ('>' / 'greater') { return 0x8; }
    / 'signed' ws+ ('<' / 'less') { return 0x16; }
    / 'signed' ws+ ('>=' / 'not' ws+ 'less') { return 0x8 | 0x1; }
    / 'signed' ws+ ('<=' / 'not' ws+ 'greater') { return 0x16 | 0x1; }
    
Register "register"
    = '#' digits:[0-9]+ { return parseInt(digits.join("")); }
    / ('#sp' / '#SP') { return 254; }
    / ('#flags' / '#FLAGS') { return 255; }

BinaryOp 
    = '+' { return 0x1; }
    / '-' { return 0x2; }
    / '&' { return 0x3; }
    / '|' { return 0x4; }
    / '^' { return 0x5; }

Constant
    = '0x' digits:[a-fA-F0-9]+ { return parseInt(digits.join(""), 16); }
    / digits:[0-9]+ { return parseInt(digits.join("")); }
    
LabelIdentifier = head:[a-zA-Z_] tail:[a-zA-Z0-9_]* { return head + tail.join("") };

ws = [ \t\n]
const fs = require('fs');
const proc = require('process');
const parser = require('./parser');


const filename = proc.argv[2];

const code = fs.readFileSync(filename, 'utf8');

const ast = parser.parse(code);

let program = [];
let labels = {};
let currentGlobalLabel = null;

function lab(label) {
	if (label[0] === '.') {
		return currentGlobalLabel + label;
	} else {
		return label;
	}
}

for (const line of ast) {
	if (line.label) {
		const label = line.label;
		if (label.type === 'global') {
			labels[label.name] = program.length;
			currentGlobalLabel = label.name;
		} else {
			labels[currentGlobalLabel + '.' + label.name] = program.length;
		}
	}
	if (line.command) {
		const command = line.command;
		if (command.type === 'assign') {
			if (command.to.reg !== undefined && command.from.reg !== undefined) {
				program.push(0);
				program.push(command.to.reg);
				program.push(command.from.reg);
				program.push(0);
			} else if (command.to.reg !== undefined && command.from.constant !== undefined) {
				if (command.from.constant <= 0xFFFF && command.from.constant >= 0) {
					program.push(0x10);
					program.push(command.to.reg);
					program.push(command.from.constant & 0xFF);
					program.push((command.from.constant >> 8) & 0xFF);
				} else {
					const rc = command.from.constant & 0xFFFFFFFF;
					program.push(0x10);
					program.push(command.to.reg);
					program.push(rc & 0xFF);
					program.push((rc >> 8) & 0xFF);
					program.push(0x12);
					program.push(command.to.reg);
					program.push((rc >> 16) & 0xFF);
					program.push((rc >> 24) & 0xFF);
				}
			} else if (command.to.reg !== undefined && command.from.mem !== undefined) {
				if (command.from.mem.base.reg !== undefined) {
					if (command.from.mem.size.bytes == 1 && !command.from.mem.size.signed) {
						program.push(0x20);
					} else if (command.from.mem.size.bytes == 1 && command.from.mem.size.signed) {
						program.push(0x21);
					} else if (command.from.mem.size.bytes == 2 && !command.from.mem.size.signed) {
						program.push(0x22);
					} else if (command.from.mem.size.bytes == 2 && command.from.mem.size.signed) {
						program.push(0x23);
					} else if (command.from.mem.size.bytes == 4) {
						program.push(0x24);
					}
					program.push(command.to.reg);
					program.push(command.from.mem.base.reg);
					program.push((command.from.mem.offset || 0) & 0xFF);
				} else if (command.from.mem.base.label !== undefined) {
					if (command.from.mem.size.bytes == 1 && !command.from.mem.size.signed) {
						program.push(0x28);
					} else if (command.from.mem.size.bytes == 1 && command.from.mem.size.signed) {
						program.push(0x29);
					} else if (command.from.mem.size.bytes == 2 && !command.from.mem.size.signed) {
						program.push(0x2A);
					} else if (command.from.mem.size.bytes == 2 && command.from.mem.size.signed) {
						program.push(0x2B);
					} else if (command.from.mem.size.bytes == 4) {
						program.push(0x2C);
					}
					program.push(command.to.reg);
					program.push({ label: lab(command.from.mem.base.label), byte: 0, rel: -2 + 4 - (command.from.mem.offset || 0)});
					program.push({ label: lab(command.from.mem.base.label), byte: 1, rel: -3 + 4 - (command.from.mem.offset || 0)});
				}
			} else if (command.from.reg !== undefined && command.to.mem !== undefined) {
				if (command.to.mem.base.reg !== undefined) {
					if (command.to.mem.size.bytes == 1) {
						program.push(0x25);
					} else if (command.to.mem.size.bytes == 2) {
						program.push(0x26);
					} else if (command.to.mem.size.bytes == 4) {
						program.push(0x27);
					}
					program.push(command.from.reg);
					program.push(command.to.mem.base.reg);
					program.push((command.to.mem.offset || 0) & 0xFF);
				} else if (command.to.mem.base.label !== undefined) {
					if (command.to.mem.size.bytes == 1) {
						program.push(0x2D);
					} else if (command.to.mem.size.bytes == 2) {
						program.push(0x2E);
					} else if (command.to.mem.size.bytes == 4) {
						program.push(0x2F);
					}
					program.push(command.from.reg);
					program.push({ label: lab(command.from.mem.base.label), byte: 0, rel: -2 + 4 - (command.from.mem.offset || 0)});
					program.push({ label: lab(command.from.mem.base.label), byte: 1, rel: -3 + 4 - (command.from.mem.offset || 0)});
				}
			}
		} else if (command.type === "binop") {
			program.push({
				'+': 0x1,
				'-': 0x2,
				'&': 0x3,
				'|': 0x4,
				'^': 0x5
			}[command.op]);
			program.push(command.to.reg);
			program.push(command.a.reg);
			program.push(command.b.reg);
		} else if (command.type === "unop") {
			program.push({
				'~': 0x6
			}[command.op]);
			program.push(command.to.reg);
			program.push(command.a.reg);
			program.push(0);
		} else if (command.type === "jump") {
			program.push(0x31);
			program.push({ label: lab(command.addr.label), byte: 0, rel: -1 + 4 });
			program.push({ label: lab(command.addr.label), byte: 1, rel: -2 + 4 });
			program.push(command.condition || 0);
		} else if (command.type === "call") {
			program.push(0x34);
			program.push({ label: lab(command.addr.label), byte: 0, rel: -1 + 4 });
			program.push({ label: lab(command.addr.label), byte: 1, rel: -2 + 4 });
			program.push(command.condition || 0);
		} else if (command.type === "ret") {
			program.push(0x36);
			program.push(0);
			program.push(0);
			program.push(command.condition || 0);
		} else if (command.type === '+=') {
			program.push(0x13);
			program.push(command.to.reg);

			const rc = command.value.constant & 0xFFFF;
			program.push(rc & 0xFF);
			program.push((rc >> 8) & 0xFF);
		} else if (command.type === 'cmp') {
			if (command.b.reg !== undefined) {
				program.push(0x14);
				program.push(command.a.reg);
				program.push(command.b.reg);
				program.push(0);
			} else if (command.b.constant !== undefined) {
				const rc = command.b.constant & 0xFFFF;
				program.push(0x16);
				program.push(command.a.reg);
				program.push(rc & 0xFF);
				program.push((rc >> 8) & 0xFF);
			} else {
				throw "bad command";
			}
		} else {
			throw "bad command";
		}
	}
}

console.log(JSON.stringify(labels));

for (let i = 0; i < program.length; ++i) {
	if (program[i].label) {
		let addr = labels[program[i].label];
		console.log(JSON.stringify(program[i]));
		console.log(addr);
		if (program[i].rel) {
			addr -= (i + program[i].rel);
			console.log(addr);
		}
		addr = addr & 0xFFFF;
		console.log(addr);
		program[i] = (addr >> (program[i].byte * 8)) & 0xFF;
	}
}

var wstream = fs.createWriteStream(filename + ".bin");

if (proc.argv[3] == 'hex') {
    for (const byte of program) {
    wstream.write(byte.toString(16));
    wstream.write("\n");
}
} else {
    wstream.write(new Buffer(program));
}
wstream.end();
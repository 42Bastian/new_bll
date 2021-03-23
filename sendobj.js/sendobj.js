/* sendobj as node.js */

const SerialPort = require('serialport');
const fs = require('fs');
var defaultPort = 'COM7'
var defaultBaudrate = 62500

var argc = process.argv.length - 2
var index = 2

while ( argc > 1 ) {
    if ( process.argv[index] === '-p' && argc > 1 ){
	defaultPort = process.argv[index+1]
	argc -= 2
	index += 2
    } else if ( process.argv[index] === '-b' && argc > 1 ){
	defaultBaudrate = parseInt(process.argv[index+1])
	argc -= 2
	index += 2
    }
}
if ( process.argv[index] ) {
    var file = process.argv[index]
} else {
    console.log("Error: Missing file")
    return
}

const port = new SerialPort(defaultPort, {
    baudRate: defaultBaudrate,
    parity:'even'
})

port.on('error',function(err) {
    console.log('Error ', err.message)
})


try {
    var buffer = fs.readFileSync(file)
} catch( err ) {
    console.error(err)
    return
}
var header = Uint8Array.from([0x81, 0x50 /*P*/, 0,0, 0,0])
var len = (buffer[4]<<8) + buffer[5]-10

header[2] = buffer[2];          // destination low byte
header[3] = buffer[3];          // destination high byte
header[4] = (len >> 8) ^ 0xff   // length high byte prepared for inc
header[5] = (len & 0xff) ^ 0xff // length low byte prepared for inc
if ( !port.write(header, 'binary') ) {
    console.log("KO\n");
    return
}

buffer = buffer.slice(10);      // skip BLL header
if ( !port.write(buffer, 'binary') ) {
    console.log("KO\n");
    return
}

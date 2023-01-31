#!/usr/bin/env node

/* sendobj as node.js */

const SerialPort = require('serialport');
const fs = require('fs');
const InterByteTimeoutParser = require('@serialport/parser-inter-byte-timeout')
const  ByteLengthParser  = require('@serialport/parser-byte-length')
var defaultPort = 'COM7'
var defaultBaudrate = 62500

var argc = process.argv.length - 2
var index = 2

function done()
{
   process.exit(0);
}

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

if ( defaultBaudrate != 1000000 ){
    const parser = port.pipe(new InterByteTimeoutParser({ interval: 1}))
}

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

const parser = port.pipe(new ByteLengthParser({ length: len }))
parser.on('data', done) // event when all bytes are written.

var ok = port.write(buffer, 'binary')
if ( !ok ) {
    console.log("KO\n");
    process.exit(0);
}
port.drain();

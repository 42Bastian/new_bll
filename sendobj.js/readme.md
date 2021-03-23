# Sendobj

Send BLL files via UART/ComLynx

## Install

You should have node.js and npm installed, then do

`npm install`

to load dependencies.

## Usage

`node sendobj.js [-b <baudrate>] [-p port] filename`

Default values are COM7 and 62500Bd

On Linux you might have to prepend `sudo` depending on the rights of the serial device.

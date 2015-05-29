var http = require('http');

http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hola holita, vecinito :)\n');
}).listen(8124, "127.0.0.1");

console.log('Servidor en http://127.0.0.1:8124/');

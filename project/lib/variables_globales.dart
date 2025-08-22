
//String baseUrl = 'http://localhost:3000';

String baseUrl = 'https://backendconsultorio.onrender.com';

String usuario = 'usuario';
String clave = "clave";
String userValido = '0';

String token = 'token';
String fechaValidaToken = '';
String tenantId = 'tenantId';

String version = '1';

var map = {
    'Accept': '*/*',
    'x-tenant-id': 'Admin',
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
  };

var headers = {
  'x-tenant-id': 'admin',
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
};
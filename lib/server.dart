import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  await generateBindings(); // Run ffigen before starting the server

  // Create a shelf handler
  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(_corsMiddleware) // Add the CORS middleware
      .addHandler(_handlePostRequest);

  // Serve the handler
  var server = await shelf_io.serve(handler, 'localhost', 8080);

  print('Serving at http://${server.address.host}:${server.port}');
}

// CORS Middleware
shelf.Handler _corsMiddleware(shelf.Handler innerHandler) {
  return (shelf.Request request) async {
    // Handle CORS headers for all routes
    if (request.method == 'OPTIONS') {
      // Pre-flight request response
      return shelf.Response.ok(null, headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
    }

    // Continue processing other requests
    var response = await innerHandler(request);
    return response.change(headers: {'Access-Control-Allow-Origin': '*'});
  };
}

// Handle POST requests
Future<shelf.Response> _handlePostRequest(shelf.Request request) async {
  if (request.method == 'POST') {
    try {
      // Get the C code from the request
      var cCode = await request.readAsString();

      // Write the C code to a file
      var cFile = File('user_code.c');
      await cFile.writeAsString(cCode);

      // Run ffigen
      await generateBindings();

      // Get the generated bindings
      var bindingsFile = File('bindings.dart');

      if (!bindingsFile.existsSync()) {
        print('Error: bindings.dart not found.');
        return shelf.Response.internalServerError(
            body: 'Failed to generate bindings: bindings.dart not found.');
      }

      var bindings = await bindingsFile.readAsString();

      // Return the bindings to the user
      return shelf.Response.ok(bindings);
    } catch (e, stackTrace) {
      print('Error generating bindings: $e\n$stackTrace');
      return shelf.Response.internalServerError(
          body: 'Failed to generate bindings: $e');
    }
  } else {
    return shelf.Response(405, body: 'Only POST is allowed');
  }
}

Future<void> generateBindings() async {
  var result = await Process.run('dart', ['run', 'ffigen', '--config=ffigen_config.yaml']);

  if (result.exitCode != 0) {
    print('Error running ffigen. Exit code: ${result.exitCode}');
    print('ffigen stdout: ${result.stdout}');
    print('ffigen stderr: ${result.stderr}');
    exit(result.exitCode);
  }
}

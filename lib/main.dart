import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FFIGENPad',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Montserrat',
      ),
      home: const MyHomePage(title: 'FFIGENPad'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _codeGenerated = false;
  String? _selectedService;

  Future<void> _generateBindings() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080'),
        body: _inputController.text,
      );

      if (response.statusCode == 200) {
        setState(() {
          _outputController.text = response.body;
          _codeGenerated = true;
        });
      } else {
        print('Failed to generate bindings. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating bindings: $e');
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _outputController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  void _downloadFile() async {
    try {
      final String fileName = 'bindings.dart';
      final File file = File(fileName);
      await file.writeAsString(_outputController.text);

      final url = file.path;
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        labelText: 'Enter your C code here',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _outputController,
                      maxLines: null,
                      expands: true,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Generated bindings.dart will appear here.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Colors.teal,
                          ),
                        ),
                        suffixIcon: _codeGenerated
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: _copyToClipboard,
                            ),
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: _downloadFile,
                            ),
                          ],
                        )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateBindings,
              child: const Text('Generate bindings'),
            ),
          ],
        ),
      ),
    );
  }
}

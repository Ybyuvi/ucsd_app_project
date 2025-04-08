import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class GptSchedulePage extends StatefulWidget {
  const GptSchedulePage({super.key});

  @override
  State<GptSchedulePage> createState() => _GptSchedulePageState();
}

class _GptSchedulePageState extends State<GptSchedulePage> {
  String? _status;
  Map<String, dynamic>? _gptData;
  bool _isLoading = false;

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _status = "Uploading PDF...";
        _gptData = null;
      });

      var file = File(result.files.single.path!);
      var uri = Uri.parse("http://127.0.0.1:5000/gpt-schedule"); // Update if hosted remotely
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var decoded = json.decode(response.body);
          setState(() {
            _status = "Success!";
            _gptData = decoded["data"];
          });
        } else {
          setState(() {
            _status = "Failed: ${response.statusCode}";
            _gptData = {"error": json.decode(response.body)};
          });
        }
      } catch (e) {
        setState(() {
          _status = "Error occurred: $e";
          _gptData = null;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildResult() {
    if (_isLoading) return const CircularProgressIndicator();
    if (_gptData == null) return const Text("No data yet.");
    return Expanded(
      child: SingleChildScrollView(
        child: Text(
          const JsonEncoder.withIndent('  ').convert(_gptData),
          style: const TextStyle(fontFamily: 'Courier'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPT Schedule Extractor")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload PDF"),
            ),
            const SizedBox(height: 16),
            if (_status != null) Text(_status!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildResult(),
          ],
        ),
      ),
    );
  }
}

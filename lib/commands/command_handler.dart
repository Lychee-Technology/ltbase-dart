import 'dart:convert';
import 'dart:io';
import 'package:ltbase_client/api/client.dart';

class CommandHandler {
  final ApiClient client;

  CommandHandler(this.client);

  /// DeepPing command
  Future<void> deepping(String? echoString) async {
    final params = echoString != null ? {'echo': echoString} : <String, String>{};
    final response = await client.get('/api/v1/deepping', queryParams: params);

    if (response.isSuccess) {
      final data = response.json;
      print('✓ DeepPing successful');
      print('  Status: ${data?['status']}');
      print('  Echo: ${data?['echo']}');
      print('  Timestamp: ${data?['timestamp']}');
    } else {
      print('✗ DeepPing failed: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }

  /// Create Note command
  Future<void> createNote({
    required String userId,
    required String type,
    String? data,
    String? filePath,
  }) async {
    String noteData;

    if (filePath != null) {
      // Read from file
      final file = File(filePath);
      if (!file.existsSync()) {
        print('✗ File not found: $filePath');
        exit(1);
      }

      if (type == 'text') {
        noteData = await file.readAsString();
      } else {
        // For audio/image, read as base64
        final bytes = await file.readAsBytes();
        noteData = base64.encode(bytes);
      }
    } else if (data != null) {
      noteData = data;
    } else {
      print('✗ Either --data or --file must be provided');
      exit(1);
    }

    final body = {
      'created_by': userId,
      'type': type,
      'data': noteData,
    };

    final response = await client.post('/api/v1/notes', body: body);

    if (response.isSuccess) {
      final note = response.json;
      print('✓ Note created successfully');
      print('  Note ID: ${note?['note_id']}');
      print('  Type: ${note?['raw']?['type']}');
      print('  Created at: ${note?['created_at']}');
    } else {
      print('✗ Failed to create note: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }

  /// Get Note command
  Future<void> getNote(String noteId) async {
    final response = await client.get('/api/ai/v1/notes/$noteId');

    if (response.isSuccess) {
      final note = response.json;
      print('✓ Note retrieved successfully');
      print(JsonEncoder.withIndent('  ').convert(note));
    } else {
      print('✗ Failed to get note: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }

  /// List Notes command
  Future<void> listNotes({
    int? page,
    int? itemsPerPage,
    String? schemaName,
    String? summary,
  }) async {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (itemsPerPage != null) params['items_per_page'] = itemsPerPage.toString();
    if (schemaName != null) params['schema_name'] = schemaName;
    if (summary != null) params['summary'] = summary;

    final response = await client.get('/api/v1/notes', queryParams: params);

    if (response.isSuccess) {
      final data = response.json;
      final notes = data?['notes'] as List?;
      
      if (notes != null && notes.isNotEmpty) {
        print('✓ Found ${notes.length} note(s)');
        print(JsonEncoder.withIndent('  ').convert(data));
      } else {
        print('✓ No notes found');
      }
    } else {
      print('✗ Failed to list notes: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }

  /// Update Note command
  Future<void> updateNote(String noteId, String summary) async {
    final body = {'summary': summary};
    final response = await client.put('/api/ai/v1/notes/$noteId', body: body);

    if (response.isSuccess) {
      print('✓ Note summary updated successfully');
      final note = response.json;
      print('  Note ID: ${note?['note_id']}');
      print('  New summary: ${note?['summary']}');
    } else {
      print('✗ Failed to update note: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }

  /// Delete Note command
  Future<void> deleteNote(String noteId) async {
    final response = await client.delete('/api/ai/v1/notes/$noteId');

    if (response.isSuccess) {
      print('✓ Note deleted successfully');
      print('  Note ID: $noteId');
    } else {
      print('✗ Failed to delete note: ${response.statusCode}');
      print('  ${response.body}');
      exit(1);
    }
  }
}

import 'dart:io';
import 'package:args/args.dart';
import 'package:ltbase_client/auth/signer.dart';
import 'package:ltbase_client/api/client.dart';
import 'package:ltbase_client/commands/command_handler.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('base-url',
        help: 'API base URL', defaultsTo: 'https://api.example.com')
    ..addOption('access-key-id',
        help: 'Access Key ID (format: AK_xxx)', mandatory: true)
    ..addOption('access-secret',
        help: 'Access Secret (format: SK_xxx)', mandatory: true)
    ..addFlag('verbose',
        abbr: 'v', help: 'Show verbose output', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  // Add subcommands
  parser.addCommand('deepping', _createDeeppingParser());
  parser.addCommand('create-note', _createCreateNoteParser());
  parser.addCommand('get-note', _createGetNoteParser());
  parser.addCommand('list-notes', _createListNotesParser());
  parser.addCommand('update-note', _createUpdateNoteParser());
  parser.addCommand('delete-note', _createDeleteNoteParser());

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool || results.command == null) {
      _printUsage(parser);
      exit(0);
    }

    // Create signer and client
    final signer = AuthSigner(
      accessKeyId: results['access-key-id'] as String,
      accessSecret: results['access-secret'] as String,
    );

    final client = ApiClient(
      baseUrl: results['base-url'] as String,
      signer: signer,
      verbose: results['verbose'] as bool,
    );

    final handler = CommandHandler(client);

    // Execute command
    final command = results.command!;
    await _executeCommand(handler, command);
  } on FormatException catch (e) {
    print('Error: ${e.message}\n');
    _printUsage(parser);
    exit(1);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

ArgParser _createDeeppingParser() {
  return ArgParser()..addOption('echo', help: 'Echo string to send');
}

ArgParser _createCreateNoteParser() {
  return ArgParser()
    ..addOption('owner-id', help: 'User ID of the creator', mandatory: true)
    ..addOption('type', help: 'Note type: text|audio|image', mandatory: true)
    ..addOption('data', help: 'Note data (text or URL)')
    ..addOption('file', help: 'Read data from file (alternative to --data)');
}

ArgParser _createGetNoteParser() {
  return ArgParser()
    ..addOption('owner-id', help: 'User ID of the creator', mandatory: true)
    ..addOption('note-id', help: 'Note ID of the creator', mandatory: true);
}

ArgParser _createListNotesParser() {
  return ArgParser()
    ..addOption('owner-id', help: 'Owner ID', mandatory: true)
    ..addOption('page', help: 'Page number', defaultsTo: '1')
    ..addOption('items-per-page', help: 'Items per page', defaultsTo: '20')
    ..addOption('schema-name', help: 'Filter by schema name (exact match)')
    ..addOption('summary', help: 'Filter by summary (contains)');
}

ArgParser _createUpdateNoteParser() {
  return ArgParser()
    ..addOption('owner-id', help: 'User ID of the creator', mandatory: true)
    ..addOption('note-id', help: 'Note ID of the creator', mandatory: true)
    ..addOption('summary', help: 'New summary text', mandatory: true);
}

ArgParser _createDeleteNoteParser() {
  return ArgParser();
}

Future<void> _executeCommand(CommandHandler handler, ArgResults command) async {
  switch (command.name) {
    case 'deepping':
      await handler.deepping(command['echo'] as String?);
      break;

    case 'create-note':
      final type = command['type'] as String;
      if (type.isEmpty) {
        print('Error: Note type is required');
        exit(1);
      }

      if (!(type.startsWith('text/') ||
          type.startsWith('audio/') ||
          type.startsWith('image/'))) {
        print('Error: Invalid type. Must be one of: text/*, audio/*, image/*');
        exit(1);
      }
      await handler.createNote(
        ownerId: command['owner-id'] as String,
        type: type,
        data: command['data'] as String?,
        filePath: command['file'] as String?,
      );
      break;

    case 'get-note':
      final ownerId = command['owner-id'] as String;
      final noteId = command['note-id'] as String;
      await handler.getNote(ownerId, noteId);
      break;

    case 'list-notes':
      await handler.listNotes(
        ownerId: command['owner-id'] as String,
        page: int.tryParse(command['page'] as String),
        itemsPerPage: int.tryParse(command['items-per-page'] as String),
        schemaName: command['schema-name'] as String?,
        summary: command['summary'] as String?,
      );
      break;

    case 'update-note':
      final ownerId = command['owner-id'] as String;
      final noteId = command['note-id'] as String;

      await handler.updateNote(
        ownerId,
        noteId,
        command['summary'] as String,
      );
      break;

    case 'delete-note':
      if (command.rest.isEmpty) {
        print('Error: Note ID is required');
        print('Usage: ltbase delete-note <NOTE_ID>');
        exit(1);
      }
      await handler.deleteNote(command.rest.first);
      break;

    default:
      print('Unknown command: ${command.name}');
      exit(1);
  }
}

void _printUsage(ArgParser parser) {
  print('LTBase API Test Client\n');
  print('Usage: ltbase [OPTIONS] <COMMAND>\n');
  print('Global Options:');
  print(parser.usage);
  print('\nCommands:');
  print('  deepping              Health check with echo');
  print('  create-note           Create a new note');
  print('  get-note <NOTE_ID>    Get a note by ID');
  print('  list-notes            List notes with optional filters');
  print('  update-note <NOTE_ID> Update note summary');
  print('  delete-note <NOTE_ID> Delete a note');
  print('\nExamples:');
  print('  # Health check');
  print(
      '  ltbase --access-key-id AK_xxx --access-secret SK_xxx deepping --echo "hello"');
  print('');
  print('  # Create text note');
  print('  ltbase --access-key-id AK_xxx --access-secret SK_xxx \\');
  print('    create-note --owner-id user123 --type text --data "My note"');
  print('');
  print('  # List notes');
  print('  ltbase --access-key-id AK_xxx --access-secret SK_xxx \\');
  print('    list-notes --page 1 --items-per-page 10');
  print('');
  print('  # Get note');
  print('  ltbase --access-key-id AK_xxx --access-secret SK_xxx \\');
  print('    get-note <note-uuid>');
  print('');
  print('  # Update note');
  print('  ltbase --access-key-id AK_xxx --access-secret SK_xxx \\');
  print('    update-note <note-uuid> --summary "Updated summary"');
  print('');
  print('  # Delete note');
  print('  ltbase --access-key-id AK_xxx --access-secret SK_xxx \\');
  print('    delete-note <note-uuid>');
}

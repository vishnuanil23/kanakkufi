import 'dart:io';
import 'package:yaml/yaml.dart';

void main() async {
  final yamlFile = File('features.yaml');
  if (!yamlFile.existsSync()) {
    exit(1);
  }

  final yamlContent = loadYaml(await yamlFile.readAsString());
  final features = yamlContent['features'] as YamlList;

  for (final feature in features) {
    final name = feature['name'].toString().toLowerCase();
    generateFeatureStructure(name);
  }
}

void generateFeatureStructure(String name) {
  final basePath = Directory('lib/features/$name');

  final folders = ['presentation/widgets', 'domain/usecases', 'data'];

  for (final folder in folders) {
    Directory('${basePath.path}/$folder').createSync(recursive: true);
  }

  _generatePresentation(name, basePath);
  _generateDomain(name, basePath);
  _generateData(name, basePath);
}

void _generatePresentation(String name, Directory basePath) {
  final pascal = _toPascalCase(name);

  // Screen
  File('${basePath.path}/presentation/${name}_screen.dart').writeAsStringSync(
    '''
import 'package:flutter/material.dart';

class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: const Center(
        child: Text('$pascal Screen'),
      ),
    );
  }
}
''',
  );

  // ViewModel (Riverpod)
  File(
    '${basePath.path}/presentation/${name}_viewmodel.dart',
  ).writeAsStringSync('''
import 'package:flutter_riverpod/legacy.dart';

class ${pascal}ViewModel extends StateNotifier<void> {
  ${pascal}ViewModel() : super(null);

  // TODO: Add state & business logic
}
''');
}

void _generateDomain(String name, Directory basePath) {
  final pascal = _toPascalCase(name);

  // Entity
  File('${basePath.path}/domain/${name}_entity.dart').writeAsStringSync('''
class ${pascal}Entity {
  // TODO: Define core business entity
}
''');

  // Repository abstract
  File('${basePath.path}/domain/${name}_repository.dart').writeAsStringSync('''
abstract class ${pascal}Repository {
  // TODO: Define repository contract
}
''');

  // Usecase
  File('${basePath.path}/domain/usecases/get_$name.dart').writeAsStringSync('''
class Get${pascal}UseCase {
  // TODO: Implement usecase logic
}
''');
}

void _generateData(String name, Directory basePath) {
  final pascal = _toPascalCase(name);

  // Model
  File('${basePath.path}/data/${name}_model.dart').writeAsStringSync('''
class ${pascal}Model {
  // TODO: Map from/to Supabase JSON
}
''');

  // Repository implementation
  File('${basePath.path}/data/${name}_repository_impl.dart').writeAsStringSync(
    '''
import '../domain/${name}_repository.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  // TODO: Implement Supabase logic here
}
''',
  );

  // Remote datasource
  File(
    '${basePath.path}/data/${name}_remote_datasource.dart',
  ).writeAsStringSync('''
class ${pascal}RemoteDataSource {
  // TODO: Supabase calls go here
}
''');
}

String _toPascalCase(String input) {
  return input
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join();
}

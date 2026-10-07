import 'dart:io';

void main() {
  final file = File('lib/src/presentation/settings/settings_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    '''
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.translate, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text('Smart Typing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Divider(),
                          SizedBox(height: 8),
                          Text('Arabic Transliteration Map:'),
                          SizedBox(height: 8),
                          Expanded(''',
    '''
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.translate, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text('Smart Typing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Arabic Transliteration Map:'),
                          const SizedBox(height: 8),
                          Expanded('''
  );

  content = content.replaceFirst(
    '''
                                    decoration: BoxDecoration(color: Colors.grey.shade100),
                                    children: [
                                      Padding(padding: EdgeInsets.all(4), child: Text('Input', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Arabic', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Input', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Arabic', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ]
''',
    '''
                                    decoration: BoxDecoration(color: Colors.grey.shade100),
                                    children: const [
                                      Padding(padding: EdgeInsets.all(4), child: Text('Input', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Arabic', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Input', style: TextStyle(fontWeight: FontWeight.bold))),
                                      Padding(padding: EdgeInsets.all(4), child: Text('Arabic', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ]
'''
  );
  file.writeAsStringSync(content);
}

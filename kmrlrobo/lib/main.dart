// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_manager/file_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hide the Debug Banner
    WidgetsFlutterBinding.ensureInitialized();
    // Set the app to only allow landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      title: 'KMRLROBO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const VideoScreen(),
    );
  }
}

// Upload and Play Video on Loop
class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  VideoScreenState createState() => VideoScreenState();
}

class VideoScreenState extends State<VideoScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _showNavbar = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _tabController.dispose();
  }

  void _toggleNavbar() {
    setState(() {
      _showNavbar = !_showNavbar;
    });
  }

  void _uploadAndPlayVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      PlatformFile file = result.files.first;
      String videoPath = file.path!;
      String fileName = path.basename(videoPath);
      Directory tempDir = await getTemporaryDirectory();
      String destination = path.join(tempDir.path, fileName);
      File newVideo = File(videoPath);
      await newVideo.copy(destination);

      await _controller.pause();
      await _controller.dispose();
      _controller = VideoPlayerController.file(newVideo)
        ..initialize().then((_) {
          _controller.setLooping(true);
          _controller.play();

          _reloadApp();
        });
    }
  }

  void _reloadApp() {
    runApp(const MyApp());
  }

  void _handleTabSelection() {
    if (_tabController.index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      _tabController.animateTo(0); // Reset to the home tab
    } else if (_tabController.index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InputFieldsScreen()),
      );
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return Scaffold(
        body: GestureDetector(
          onTap: _toggleNavbar,
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
              if (_showNavbar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [
                      BoxShadow(
                          blurRadius: 20, color: Colors.black.withOpacity(.1))
                    ]),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.home), text: 'Home'),
                        Tab(icon: Icon(Icons.upload), text: 'Upload'),
                        Tab(icon: Icon(Icons.view_agenda), text: 'View'),
                        Tab(icon: Icon(Icons.send_and_archive), text: 'Test'),
                      ],
                      labelColor: const Color.fromARGB(255, 54, 244, 108),
                      unselectedLabelColor: Colors.grey,
                      onTap: (index) {
                        if (index == 1) {
                          _uploadAndPlayVideo();
                        } else if (index == 3) {
                          const InputFieldsScreen();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}

// class FileManagerController {
//   String currentPath;

//   FileManagerController({String? initialPath})
//       : currentPath = initialPath ?? '';
// }

// Display the File Structure of the device on App
class HomePage extends StatelessWidget {
  final FileManagerController controller = FileManagerController();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: controller,
      child: Scaffold(
        appBar: appBar(context),
        body: FileManager(
          controller: controller,
          builder: (context, snapshot) {
            final List<FileSystemEntity> entities = snapshot;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                FileSystemEntity entity = entities[index];
                return Card(
                  child: ListTile(
                    leading: FileManager.isFile(entity)
                        ? const Icon(Icons.feed_outlined)
                        : const Icon(Icons.folder),
                    title: Text(FileManager.basename(
                      entity,
                      showFileExtension: true,
                    )),
                    subtitle: subtitle(entity),
                    onTap: () async {
                      if (FileManager.isDirectory(entity)) {
                        // open the folder
                        controller.openDirectory(entity);

                        // delete a folder
                        // await entity.delete(recursive: true);

                        // rename a folder
                        // await entity.rename("newPath");

                        // Check weather folder exists
                        // entity.exists();

                        // get date of file
                        // DateTime date = (await entity.stat()).modified;
                      } else {
                        // delete a file
                        // await entity.delete();

                        // rename a file
                        // await entity.rename("newPath");

                        // Check weather file exists
                        // entity.exists();

                        // get date of file
                        // DateTime date = (await entity.stat()).modified;

                        // get the size of the file
                        // int size = (await entity.stat()).size;
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            _requestFilesAccessPermission();
          },
          label: const Text("Request File Access Permission"),
        ),
      ),
    );
  }

  void _requestFilesAccessPermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      // Permission granted, you can proceed with file operations
    } else if (status.isDenied) {
      openAppSettings();
      // Permission denied, handle accordingly (e.g., show an error message)
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, open app settings for the user to enable the permission manually
      openAppSettings();
    }
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
        IconButton(
          onPressed: () => createFolder(context),
          icon: const Icon(Icons.create_new_folder_outlined),
        ),
        IconButton(
          onPressed: () => sort(context),
          icon: const Icon(Icons.sort_rounded),
        ),
        IconButton(
          onPressed: () => selectStorage(context),
          icon: const Icon(Icons.sd_storage_rounded),
        )
      ],
      title: ValueListenableBuilder<String>(
        valueListenable: controller.titleNotifier,
        builder: (context, title, _) => Text(title),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await controller.goToParentDirectory();
        },
      ),
    );
  }

  Widget subtitle(FileSystemEntity entity) {
    return FutureBuilder<FileStat>(
      future: entity.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (entity is File) {
            int size = snapshot.data!.size;

            return Text(
              FileManager.formatBytes(size),
            );
          }
          return Text(
            "${snapshot.data!.modified}".substring(0, 10),
          );
        } else {
          return const Text("");
        }
      },
    );
  }

  Future<void> selectStorage(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: FutureBuilder<List<Directory>>(
          future: FileManager.getStorageList(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<FileSystemEntity> storageList = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: storageList
                        .map((e) => ListTile(
                              title: Text(
                                FileManager.basename(e),
                              ),
                              onTap: () {
                                controller.openDirectory(e);
                                Navigator.pop(context);
                              },
                            ))
                        .toList()),
              );
            }
            return const Dialog(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  sort(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                  title: const Text("Name"),
                  onTap: () {
                    controller.sortBy(SortBy.name);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("Size"),
                  onTap: () {
                    controller.sortBy(SortBy.size);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("Date"),
                  onTap: () {
                    controller.sortBy(SortBy.date);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: const Text("type"),
                  onTap: () {
                    controller.sortBy(SortBy.type);
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  createFolder(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController folderName = TextEditingController();
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: TextField(
                    controller: folderName,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Create Folder
                      await FileManager.createFolder(
                          controller.getCurrentPath, folderName.text);
                      // Open Created Folder
                      controller.setCurrentPath =
                          "${controller.getCurrentPath}/${folderName.text}";
                    } catch (e) {}

                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  child: const Text('Create Folder'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// Server Test
class InputFieldsScreen extends StatefulWidget {
  const InputFieldsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InputFieldsScreenState createState() => _InputFieldsScreenState();
}

class _InputFieldsScreenState extends State<InputFieldsScreen> {
  final TextEditingController _input1Controller = TextEditingController();
  final TextEditingController _input2Controller = TextEditingController();
  String _output1 = '';
  String _output2 = '';

  Future<void> getData(String endpoint) async {
    final response =
        await http.get(Uri.parse('http://your-flask-server/$endpoint'));
    if (response.statusCode == 200) {
      final data = response.body;
      setState(() {
        if (endpoint == 'button1') {
          _output1 = data;
        } else if (endpoint == 'button2') {
          _output2 = data;
        }
      });
    } else {
      print('Failed to fetch data');
    }
  }

  Future<void> updateData(String endpoint, String inputValue) async {
    final response = await http.post(
      Uri.parse('http://your-flask-server/$endpoint'),
      body: {'value': inputValue},
    );
    if (response.statusCode == 200) {
      print('Data updated successfully');
    } else {
      print('Failed to update data');
    }
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://your-flask-server/data'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _output1 = data['button1_value'];
        _output2 = data['button2_value'];
      });
    } else {
      print('Failed to fetch data');
    }
  }

  @override
  void dispose() {
    _input1Controller.dispose();
    _input2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Fields Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _input1Controller,
              decoration: const InputDecoration(
                labelText: 'Input Field 1',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                getData('button1');
              },
              child: const Text('Get'),
            ),
            Text(_output1),
            const SizedBox(height: 16.0),
            TextField(
              controller: _input2Controller,
              decoration: const InputDecoration(
                labelText: 'Input Field 2',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                getData('button2');
              },
              child: const Text('Get'),
            ),
            Text(_output2),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                updateData('button1', _input1Controller.text);
              },
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () {
                updateData('button2', _input2Controller.text);
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
}

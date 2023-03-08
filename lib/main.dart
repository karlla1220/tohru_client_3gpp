import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(const MyApp());

enum Hand { raised, lowered, noHand }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Tohru client",
      home: MyPage(),
    );
  }
}

class MeetingRoom {
  String name;
  bool available = true;

  MeetingRoom({required this.name});
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

final scaffoldKey = GlobalKey<ScaffoldState>();

class _MyPageState extends State<MyPage> {
  bool _isLoading = false;
  MeetingRoom currentMeetingRoom = MeetingRoom(name: "None");
  int _selectedIndex = 0;
  List<MeetingRoom> rooms = <MeetingRoom>[
    MeetingRoom(name: "RAN1_Main"),
    MeetingRoom(name: "RAN1_Brk1"),
    MeetingRoom(name: "RAN1_Brk2"),
    MeetingRoom(name: "RAN1_Off1"),
    MeetingRoom(name: "RAN1_Off2"),
  ];
  String userName = "LG - Duckhyun Bae";

  late final WebViewController webViewController;
  // Completer webViewCompleter =  Completer();

  @override
  void initState() {
    super.initState();

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) async {
            // Set false if the page finished loading.
            setState(() => {_isLoading = true});
            // webViewCompleter =  Completer();
          },
          onPageFinished: (String url) async {
            // Set true if the page finished loading.
            setState(() => {_isLoading = false});
            // webViewCompleter.complete();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://tohru.3gpp.org')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://tohru.3gpp.org'));
  }

  // Future<void> _waitWebView() {
  //   if (_isLoading) {
  //     return webViewCompleter.future;
  //   } else {
  //     webViewCompleter.complete();
  //     return Future.value();
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: WebViewWidget(controller: webViewController),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Rooms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
              ] +
              rooms
                  .where((room) => room.available)
                  .map((room) => ListTile(
                        title: Text(room.name),
                        leading: const Icon(Icons.meeting_room),
                        // Row(
                        //     mainAxisAlignment: MainAxisAlignment.start,
                        //   children: const <Widget>[ Icon(Icons.edit),SizedBox(width: 1.0),Icon(Icons.meeting_room) ],
                        // ),

                        onTap: () async {
                          Navigator.pop(context);
                          inputMeetingAndName(room);
                          // await _waitWebView();
                          applyMeetingRoomStatus();

                        },
                      ))
                  .toList() +
              <Widget>[
                const Divider(),
                ListTile(
                  // leading: Icon(Icons.person_sharp),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(Icons.edit),
                      SizedBox(width: 8.0),
                      Icon(Icons.person),
                    ],
                  ),
                  title: const Text('Set User Name'),
                  onTap: () {
                    // Go to configure page for Person
                    //
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final userNameController = TextEditingController(text: userName);
                        return AlertDialog(
                          title: const Text("Set User Name"),
                          content: TextFormField(
                            controller: userNameController,
                            // initialValue: userName,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: "User Name",
                              hintText: "Enter your user name",
                            ),
                            onFieldSubmitted: (value) {
                              setState(() {
                                userName = value;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text("Set"),
                              onPressed: () {
                                setState(() {
                                  userName = userNameController.text;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(Icons.edit),
                      SizedBox(width: 8.0),
                      Icon(Icons.meeting_room),
                    ],
                  ),
                  title: const Text('Set meeting room ID'),
                  onTap: () async {
                    List<MeetingRoom>? updatedRooms = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            MeetingRoomsConfigWidget(rooms: rooms),
                      ),
                    );
                    if (updatedRooms != null) {
                      setState(() {
                        rooms = updatedRooms;
                      });
                    }
                    else
                      {
                        setState(() {});
                      }
                  },
                ),
              ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        //has to be larger than 2
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: handStatus == Hand.raised ? const Icon(Icons.person) :
                  handStatus == Hand.lowered ? const Icon(Icons.front_hand) :
                  const Icon(Icons.do_disturb_on_outlined),
            label:  handStatus == Hand.raised ? "Lower Hand" :
                    handStatus == Hand.lowered ? "Raise Hand" :
                    "Not in Room",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: 'Refresh',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
        ],

        currentIndex: _selectedIndex,
        onTap: (index) => _onItemTapped(index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => {},
      //   tooltip: 'Refresh',
      //   child: const Icon(Icons.refresh),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  Future<void> applyMeetingRoomStatus() async {
    if (_isLoading == false) {
      Hand currentHandState =  (await checkHandStatus()) ;
      // if Hand.raised, set handRaisedBoolean to true;
      // if not Hand.raised, set handRaisedBoolean to false
      setState(()=> handStatus = currentHandState);
      if (kDebugMode) {
        print(currentHandState);
        // setState(()=> handStatus = Hand.lowered);
      }
    }
  }


  Future<void> inputMeetingAndName(MeetingRoom room) async {
    // String roomname = room.name;
    bool registered = false;
    bool loginNecessary = false;

    registered = await webViewController
        .runJavaScriptReturningResult('registered') as bool;

    if (_isLoading == false) {
      if (registered == true) {
        if (currentMeetingRoom != room) {
          webViewController.runJavaScript('MainScreen.logOut();');
          loginNecessary = true;
        }
        if (currentMeetingRoom == room) {
          if (kDebugMode) {
            print("Attempt to login in same meeting room.");
          }
        }
      }
      if (registered == false) {
        loginNecessary = true;
      }
    }
    if (loginNecessary == true) {
      webViewController.runJavaScript('''
            document.getElementById("meetingfield").value ="${room.name}";
            document.getElementById("namefield").value ="$userName";
            WelcomeScreen.join();
            ''');
      currentMeetingRoom = room;
    }
  }

  Hand handStatus = Hand.noHand;

  Future<Hand> checkHandStatus() async {
    try {
      var result = await webViewController.runJavaScriptReturningResult(
    'Boolean(document.getElementById("downbutton").childNodes.length)');
      if (result == 'null') {
         throw const FormatException("Not in a Room");
      }
      if (kDebugMode) {
        print(result);
        print(result.runtimeType);
      }

      final bool handRaised = result as bool;

      if (handRaised) {
        return Hand.raised;
      } else {
        return Hand.lowered;
      }
    } catch (e) {
      // Handle the exception here
      if (kDebugMode) {
        print('Error occurred while running JavaScript: $e');
      }
      return Hand.noHand;

    }
  }

  void _onItemTapped(int index) async {
    _selectedIndex = index;
    // inputMeetingAndName(index);

    switch (_selectedIndex) {
      case 0: // Raise Hand

        Hand currentHandState = await checkHandStatus();
        if (currentHandState != handStatus) {
          setState(()=> handStatus = currentHandState);
        } else if (currentHandState == Hand.lowered) {
          webViewController.runJavaScript("MainScreen.raise('S');");
          setState(()=> handStatus = Hand.raised);

        } else if (currentHandState == Hand.raised) {
          webViewController.runJavaScript("MainScreen.down();");
          setState(()=> handStatus = Hand.lowered);
        } else {
          setState(()=> handStatus = Hand.noHand);
        }


        break;
      case 1: // Refresh
        webViewController.reload();
        break;
      case 2: // Room ID
        scaffoldKey.currentState?.openDrawer();
        break;
    }
  }
}

class MeetingRoomsConfigWidget extends StatefulWidget {
  final List<MeetingRoom> rooms;

  const MeetingRoomsConfigWidget({super.key, required this.rooms});

  @override
  MeetingRoomsConfigWidgetState createState() =>
      MeetingRoomsConfigWidgetState();
}

class MeetingRoomsConfigWidgetState extends State<MeetingRoomsConfigWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configure Meeting Rooms")),
      body: ListView.builder(
        itemCount: widget.rooms.length,
        itemBuilder: (BuildContext context, int index) {
          return Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                  child: TextFormField(
                    initialValue: widget.rooms[index].name,
                    decoration: const InputDecoration(
                      labelText: "Meeting Room Name",
                    ),
                    onChanged: (value) {
                      setState(() {
                        widget.rooms[index].name = value;
                      });
                    },
                  ),
                ),
              ),
              Checkbox(
                value: widget.rooms[index].available,
                onChanged: (bool? value) {
                  setState(() {
                    widget.rooms[index].available = value ?? false;
                  });
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, widget.rooms);
        },
      ),
    );
  }
}

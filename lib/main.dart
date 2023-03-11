import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tohru_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tohru.dart';
import 'preference_manager.dart';

void main() => runApp(const MyApp());

enum Hand { raised, lowered, noHand }

enum LoadingState { loginWindow, loadingScreen, inRoom }

enum Apply { changed, unchanged }

void printDebug(Object? object) {
  if (kDebugMode) {
    print(object);
  }
}

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

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

final scaffoldKey = GlobalKey<ScaffoldState>();

class _MyPageState extends State<MyPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  int _progress = 0;
  static final emptyRoom = MeetingRoom(name: "None");
  MeetingRoom currentMeetingRoom = emptyRoom;
  int _selectedIndex = 0;

  //==========================================================================
  late SharedPreferences prefs;
  //--------------------------------------------------------------------------
  List<MeetingRoom> rooms = [];
  String userName = "";
  String _prefix = "";
  String _selectedOption = "";
  //==========================================================================

  void _saveAll() {
    PreferencesManager.prefix = _prefix;
    PreferencesManager.selectedOption = _selectedOption;
    PreferencesManager.userName = userName;
    PreferencesManager.rooms = rooms;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        printDebug('AppLifecycleState: resumed');
        break;
      case AppLifecycleState.inactive:
        printDebug('AppLifecycleState: inactive');
        break;
      case AppLifecycleState.detached:
        printDebug('AppLifecycleState: detached');
        webViewController.runJavaScript('MainScreen.logOut();');
        // await Future.delayed(const Duration(milliseconds: 300));
        sleep(const Duration(milliseconds: 500));
        printDebug('AppLifecycleState: logOut excuted');
        // DO SOMETHING!
        if (handStatus == Hand.raised) {
          webViewController.runJavaScript("MainScreen.down();");
        }
        break;
      case AppLifecycleState.paused:
        printDebug('AppLifecycleState: paused');
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    printDebug("Perfrom Dispose on main widget!!!");
    if (handStatus == Hand.raised) {
      webViewController.runJavaScript("MainScreen.down();");
    }
    waitPageChangedByHand([Hand.noHand, Hand.lowered]).then(
      (_) => webViewController.runJavaScript('MainScreen.logOut();'),
    );
    _saveAll();

    WidgetsBinding.instance.removeObserver(this);

    printDebug("End Dispose on main widget!!!");
    super.dispose();
  }

  late final WebViewController webViewController;

  void _loadAll() {
    userName = PreferencesManager.userName;
    _prefix = PreferencesManager.prefix;
    _selectedOption = PreferencesManager.selectedOption;
    rooms = PreferencesManager.rooms;
  }

  void _initDefaultValues() {
    PreferencesManager.setDefaults();
    _loadAll();
  }

  @override
  void initState() {
    printDebug("Perfrom init on main widget!!!");

    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PreferencesManager.init().then((_) {
      _loadAll();
    });

    webViewController = TohruWebView(
      onProgress: (int progress) {
        // Update loading bar.
        setState(() {
          _progress = progress;
        });
      },
      onPageStarted: (String url) async {
        // Set false if the page finished loading.
        printDebug("Start to load Webpage");
        setState(() => {_isLoading = true});
      },
      onPageFinished: (String url) async {
        // Set true if the page finished loading.
        printDebug("Finish to load Webpage");
        printDebug("Start to wait to load ");
        LoadingState currentPage = await waitTohruLoading(
          target: LoadingState.loadingScreen,
        );
        printDebug("end to wait to load ");
        setState(() {
          _isLoading = false;
        });
        if (currentPage == LoadingState.inRoom) {
          waitPageChangedByHand([Hand.lowered, Hand.raised]).then(
            (_) => applyMeetingRoomStatus(),
          );
        } else {
          applyMeetingRoomStatus();
        }
      },
    ).webViewController;

    printDebug("End init on main widget!!!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      // appBar: AppBar(),
      body: Container(
        //safeArea Color
        color: Colors.black,
        child: SafeArea(
          child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Visibility(
                    visible: _isLoading,
                    child: LinearProgressIndicator(
                      color: Colors.red,
                      // minHeight: 10,
                      value: _progress / 100,
                    ),
                  ),
                  Expanded(
                      child: Stack(children: [
                    WebViewWidget(controller: webViewController),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ])),
                ],
              )),
        ),
      ),
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
                        },
                      ))
                  .toList() +
              <Widget>[
                const Divider(),
                ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const <Widget>[
                      Icon(Icons.edit),
                      SizedBox(width: 8.0),
                      Icon(Icons.person),
                    ],
                  ),
                  title: const Text('Set User Name'),
                  subtitle: Text('$_prefix $userName'),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final userNameController =
                            TextEditingController(text: userName);
                        return StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return AlertDialog(
                              title: const Text("Set User Name"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile(
                                    title: const Text('F2F'),
                                    value: 'F2F',
                                    groupValue: _selectedOption,
                                    toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedOption = value ?? "None";
                                        _prefix = _prefix != '[F]' ? '[F]' : "";
                                        PreferencesManager.prefix = _prefix;
                                        PreferencesManager.selectedOption =
                                            _selectedOption;
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    title: const Text('Remote'),
                                    value: 'Remote',
                                    groupValue: _selectedOption,
                                    toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedOption = value ?? "None";
                                        _prefix = _prefix != '[R]' ? '[R]' : "";
                                        PreferencesManager.prefix = _prefix;
                                        PreferencesManager.selectedOption =
                                            _selectedOption;
                                      });
                                    },
                                  ),
                                  TextFormField(
                                    controller: userNameController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: "User Name",
                                      hintText: "Enter your user name",
                                      prefixText: _prefix,
                                    ),
                                    onFieldSubmitted: (value) {
                                      setState(() {
                                        userName = value;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  child: const Text("Set"),
                                  onPressed: () {
                                    setState(() {
                                      userName = userNameController.text;
                                      PreferencesManager.userName = userName;
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
                    );
                    setState(() {});
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
                        PreferencesManager.rooms = rooms;
                      });
                    } else {
                      setState(() {});
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Set to Default'),
                  subtitle: const Text('Name and Rooms'),
                  onTap: () => _showConfirmationDialog(),
                ),
              ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        //has to be larger than 2
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: handStatus == Hand.raised
                ? const Icon(Icons.person)
                : handStatus == Hand.lowered
                    ? const Icon(Icons.front_hand)
                    : const Icon(Icons.do_disturb_on_outlined),
            label: handStatus == Hand.raised
                ? "Lower Hand"
                : handStatus == Hand.lowered
                    ? "Raise Hand"
                    : "Not in Room",
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
        onTap: (index) async {
          await _onItemTapped(index);
          setState(() => _selectedIndex = 0);
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Default Values'),
          content: const Text(
              'Are you sure you want to set default values for name and rooms?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          _initDefaultValues();
        });
      }
    });
  }

  Future<void> inputMeetingAndName(MeetingRoom room) async {
    // String roomname = room.name;
    bool loginNecessary = false;

    await applyMeetingRoomStatus();

    if (_isLoading == false) {
      if (currentMeetingRoom != emptyRoom) {
        if (currentMeetingRoom != room) {
          if (handStatus == Hand.raised) {
            webViewController.runJavaScript("MainScreen.down();");
            await waitPageChangedByHand([Hand.lowered]);
          }

          await webViewController.runJavaScript('MainScreen.logOut();');
          //wait logout finish
          await waitTohruLoading(target: LoadingState.loginWindow);
          await waitPageChangedByHand([Hand.noHand]);
          loginNecessary = true;
        }
        if (currentMeetingRoom == room) {
          printDebug("Attempt to login in same meeting room.");
        }
      }
      if (currentMeetingRoom == emptyRoom) {
        await waitPageChangedByHand([Hand.noHand]);
        loginNecessary = true;
      }
    }
    if (loginNecessary == true) {
      webViewController.runJavaScript('''
            document.getElementById("meetingfield").value ="${room.name}";
            document.getElementById("namefield").value ="$_prefix $userName";
            WelcomeScreen.join();
            ''');
      await waitTohruLoading(target: LoadingState.inRoom);
      waitPageChangedByHand([Hand.lowered, Hand.raised]).then(
        (_) => setState(() {
          currentMeetingRoom = room;
          handStatus = Hand.lowered;
        }),
      );
    }
  }

  Hand handStatus = Hand.noHand;

  Future<Hand> checkHandStatus() async {
    try {
      // var result = await webViewController.runJavaScriptReturningResult(
      // '(downButton =>  downButton.childNodes.length > 0 ? true : (downButton !== null ? false : null))(document.getElementById("downbutton"));');

      final result = await webViewController.runJavaScriptReturningResult('''
      (() => {
        return {
          registered: registered,
          handRaised: UserInfo.hand.raised,
        };
        })()
      ''').then(
        (value) => jsonDecode(value as String),
      );
      // (UserInfo.hand.raised, resgistered);

      printDebug(result);
      printDebug(result.runtimeType);

      final bool handRaised = result["handRaised"];
      final bool registered = result["registered"];

      if (registered == false || result == 'null') {
        currentMeetingRoom = emptyRoom;
        throw const FormatException("Not in a Room");
      }

      if (handRaised) {
        return Hand.raised;
      } else {
        return Hand.lowered;
      }
    } catch (e) {
      // Handle the exception here
      printDebug('Error occurred while running JavaScript: $e');
      return Hand.noHand;
    }
  }

  Future<Apply> applyMeetingRoomStatus({bool apply = true}) async {
    if (_isLoading == false) {
      Hand currentHandState = (await checkHandStatus());
      if (handStatus != currentHandState) {
        if (apply) {
          setState(() => handStatus = currentHandState);
        }
        printDebug("Apply $currentHandState");

        return Apply.changed;
      } else {
        return Apply.unchanged;
      }
    }
    return Apply.unchanged;
  }

  Future<void> _onItemTapped(int index) async {
    _selectedIndex = index;
    // inputMeetingAndName(index);

    switch (_selectedIndex) {
      case 0: // Raise Hand

        if (await applyMeetingRoomStatus() == Apply.changed) {
          //
        } else {
          if (handStatus == Hand.lowered) {
            webViewController.runJavaScript("MainScreen.raise('S');");
            waitPageChangedByHand([Hand.raised]).then(
              (_) => setState(() => handStatus = Hand.raised),
            );
          } else if (handStatus == Hand.raised) {
            webViewController.runJavaScript("MainScreen.down();");
            waitPageChangedByHand([Hand.lowered]).then(
              (_) => setState(() => handStatus = Hand.lowered),
            );
          }
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

  Future<void> waitPageChangedByHand(final List<Hand> targetHands) async {
    int totalTimeWaited = 0;
    const int maxWaitTime = 3000; // 3 seconds in milliseconds
    while (true) {
      var downbutton = await webViewController.runJavaScriptReturningResult(
        'document.getElementById("downbutton")?.children.length',
      );
      int buttonStatus = downbutton.runtimeType != int ? -1 : downbutton as int;

      if (targetHands.contains(Hand.noHand) && buttonStatus < 0) {
        break;
      } else {
        bool isHandListLoaded =
            await webViewController.runJavaScriptReturningResult(
                    "(document.getElementById('speaker')?.textContent ?? 'LOADING...') !== 'LOADING...'")
                as bool;
        if (isHandListLoaded) {
          if (targetHands.contains(Hand.lowered) && buttonStatus == 0) {
            break;
          } else if (targetHands.contains(Hand.raised) && buttonStatus > 0) {
            break;
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 100));
      totalTimeWaited += 100;
      if (totalTimeWaited >= maxWaitTime) {
        printDebug('Timed out while waiting for hand change');
        return;
      }
    }
  }

  Future<LoadingState> waitTohruLoading(
      {final LoadingState target = LoadingState.loadingScreen}) async {
    int totalTimeWaited = 0;
    const int maxWaitTime = 10000; // 10 seconds in milliseconds
    int origin;
    while (true) {
      Object result = await webViewController.runJavaScriptReturningResult(
        'document.getElementById("origin")?.children.length',
      );
      if (result.runtimeType == int) {
        origin = result as int;
      } else {
        //String == "null" or else
        origin = -1;
      }

      if (target == LoadingState.loadingScreen && origin > 0) {
        break;
      } else if (target == LoadingState.inRoom && origin > 0 && origin < 6) {
        break;
      } else if (target == LoadingState.loginWindow &&
          origin > 0 &&
          origin > 6) {
        break;
      }

      await Future.delayed(const Duration(milliseconds: 100));
      totalTimeWaited += 100;
      if (totalTimeWaited >= maxWaitTime) {
        printDebug('Timed out while waiting for Tohru Loading');
        return LoadingState.loadingScreen;
      }
    }
    if (origin > 0 && origin < 6) {
      return LoadingState.inRoom;
    } else if (origin > 0 && origin >= 6) {
      return LoadingState.loginWindow;
    } else {
      return LoadingState.loadingScreen;
    }
  }
}

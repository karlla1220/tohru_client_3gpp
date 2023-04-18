import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tohru_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tohru.dart';
import 'preference_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

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

class _MyPageState extends State<MyPage> {
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
  String url = "";

  //==========================================================================
  void _saveAll() {
    PreferencesManager.prefix = _prefix;
    PreferencesManager.selectedOption = _selectedOption;
    PreferencesManager.userName = userName;
    PreferencesManager.rooms = rooms;
    PreferencesManager.url = url;
  }

  @override
  void dispose() {
    printDebug("Perfrom Dispose on main widget!!!");
    // if (handStatus == Hand.raised) {
    //   webViewClass.runJavaScript("MainScreen.down();");
    // }
    // waitPageChangedByHand([Hand.noHand, Hand.lowered]).then(
    //   (_) => webViewClass.runJavaScript('MainScreen.logOut();'),
    // );
    _saveAll();

    printDebug("End Dispose on main widget!!!");
    super.dispose();
  }

  late final TohruWebView webViewClass;

  void _loadAll() {
    userName = PreferencesManager.userName;
    _prefix = PreferencesManager.prefix;
    _selectedOption = PreferencesManager.selectedOption;
    rooms = PreferencesManager.rooms;
    url = PreferencesManager.url;
    printDebug(url);
  }

  void _initDefaultValues() {
    PreferencesManager.setDefaults();
    _loadAll();
  }

  @override
  void initState() {
    printDebug("Perfrom init on main widget!!!");

    super.initState();
    webViewClass = TohruWebView(
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
        printDebug("Finish to load Webpage of $url");

        //if url is about:blank, finsih to load
        // if (url == "about:blank") {
        //   setState(() => {_isLoading = false});
        //   return;
        // }

        //if url is not about:blank, wait to load

        //if url does not contain "tohru or hand or raise", finsih to load

        // if (!url.contains("tohru") &&
        //     !url.contains("hand") &&
        //     !url.contains("raise")) {
        //   setState(() => {_isLoading = false});
        //   return;
        // }

        // printDebug("Start to wait to ajax load");
        // LoadingState currentPage = await waitTohruLoading(
        //   target: LoadingState.loadingScreen,
        // );
        setState(() {
          _isLoading = false;
        });
        printDebug("end to wait to load ");

        // if (currentPage == LoadingState.inRoom) {
        //   waitPageChangedByHand([Hand.lowered, Hand.raised]).then(
        //     (_) => applyMeetingRoomStatus(),
        //   );
        // } else {
        //   waitPageChangedByHand([Hand.noHand]).then(
        //     (_) => applyMeetingRoomStatus(),
        //   );
        // }
      },
    );

    PreferencesManager.init().then((_) {
      _loadAll();
    }).then((_) => webViewClass.loadUrl(url));

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
                    webViewClass.getWebViewWidget(),
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
                SizedBox(
                  height: 120,
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Text(
                      'Rooms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
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
                      Icon(Icons.public),
                    ],
                  ),
                  title: const Text('Set URL'),
                  subtitle: Text(url),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        final urlTextController =
                            TextEditingController(text: url);
                        return AlertDialog(
                          icon: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.public),
                              Icon(Icons.front_hand),
                            ],
                          ),
                          title: const Text("Set URL"),
                          content: TextFormField(
                            controller: urlTextController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: "URL",
                              hintText: "Enter tohru URL",
                              prefix: Text('https://'),
                            ),
                            onFieldSubmitted: (value) {
                              setState(() {
                                url = value;
                                PreferencesManager.url = url;
                              });
                              webViewClass.loadUrl(url);
                              Navigator.pop(context);
                            },
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text("Set"),
                              onPressed: () {
                                setState(() {
                                  url = urlTextController.text;
                                  PreferencesManager.url = url;
                                });
                                webViewClass.loadUrl(url);
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
                    setState(() {});
                  },
                ),
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
                        String prefix = _prefix;
                        String selectedOption = _selectedOption;
                        bool isF2F = _selectedOption == "F2F";
                        bool isRemote = _selectedOption == "Remote";

                        final userNameController =
                            TextEditingController(text: userName);
                        return StatefulBuilder(
                          builder: (BuildContext context, setState) {
                            return AlertDialog(
                              title: const Text("Set User Name"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CheckboxListTile(
                                    title: const Text('F2F'),
                                    value: isF2F,
                                    // groupValue: selectedOption,
                                    // toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        isF2F = value!;
                                        if (value == true) {
                                          isRemote = false;
                                          selectedOption = "F2F";
                                          prefix = "[F]";
                                        } else {
                                          selectedOption = "None";
                                          prefix = "";
                                        }
                                      });
                                    },
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Remote'),
                                    value: isRemote,
                                    // groupValue: selectedOption,
                                    // toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        isRemote = value!;
                                        if (value == true) {
                                          isF2F = false;
                                          selectedOption = "Remote";
                                          prefix = "[R]";
                                        } else {
                                          selectedOption = "None";
                                          prefix = "";
                                        }
                                      });
                                    },
                                  ),
                                  TextFormField(
                                    controller: userNameController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: "User Name",
                                      hintText: "Enter your user name",
                                      prefixText: prefix,
                                    ),
                                    onFieldSubmitted: (value) {
                                      setState(() {
                                        userName = value;
                                        PreferencesManager.userName = userName;
                                        _prefix = prefix;
                                        _selectedOption = selectedOption;
                                        PreferencesManager.prefix = prefix;
                                        PreferencesManager.selectedOption =
                                            selectedOption;
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
                                      _prefix = prefix;
                                      _selectedOption = selectedOption;
                                      PreferencesManager.prefix = prefix;
                                      PreferencesManager.selectedOption =
                                          selectedOption;
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
                const Divider(),
                Visibility(
                  visible: (handStatus != Hand.noHand),
                  child: ListTile(
                      leading: const Icon(Icons.exit_to_app),
                      title: const Text('Log-out from Meeting room'),
                      subtitle: const Text('Hand will be lowered'),
                      onTap: () {
                        logOutFromRoomWithLoweringHand();
                        Navigator.pop(context);
                      }),
                ),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Clear cache and cookies'),
                    onTap: () {
                      webViewClass.clearCookies();
                      Navigator.pop(context);
                    }),
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

  void logOutFromRoomWithLoweringHand() async {
    await waitTohruLoading();
    await applyMeetingRoomStatus();
    if (handStatus == Hand.noHand) {
      //Do nothing. "setState()" already done in applyMeetingRoomStatus();
    } else if (handStatus != Hand.noHand) {
      if (handStatus == Hand.raised) {
        webViewClass.runJavaScript("MainScreen.down();");
        await waitPageChangedByHand([Hand.lowered]);
      }
      webViewClass
          .runJavaScript('MainScreen.logOut();')
          .then(
            // wait until screen change
            (_) => waitTohruLoading(
              target: LoadingState.loginWindow,
            ),
          )
          .then(
            // wait until no Hand verified
            (_) => waitPageChangedByHand(
              [Hand.noHand],
            ),
          )
          .then(
            //set State as not In a Room
            (_) => setState(
              () {
                handStatus = Hand.noHand;
                currentMeetingRoom = emptyRoom;
              },
            ),
          );
    }
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
    await waitTohruLoading();
    await applyMeetingRoomStatus();

    if (_isLoading == false) {
      if (currentMeetingRoom != emptyRoom) {
        if (currentMeetingRoom != room) {
          if (handStatus == Hand.raised) {
            webViewClass.runJavaScript("MainScreen.down();");
            await waitPageChangedByHand([Hand.lowered]);
          }

          await webViewClass.runJavaScript('MainScreen.logOut();');
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
      await webViewClass.runJavaScript('''
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
    final results = await Future.wait([
      webViewClass.runJavaScriptReturningResult("""
          Boolean((typeof registered) === 'boolean' ? registered : false)
          """),
      webViewClass.runJavaScriptReturningResult("""
          (typeof UserInfo !== 'undefined') && UserInfo.hand && typeof UserInfo.hand.raised === 'boolean' ? UserInfo.hand.raised : false;
          """),
    ]);
    final bool registered = results[0] as bool;
    final bool handRaised = results[1] as bool;

    if (registered == false) {
      return Hand.noHand;
    } else {}

    if (handRaised) {
      return Hand.raised;
    } else {
      return Hand.lowered;
    }
  }

  Future<Apply> applyMeetingRoomStatus({bool apply = true}) async {
    if (_isLoading == false) {
      Hand currentHandState = (await checkHandStatus());

      if (currentHandState == Hand.noHand) {
        currentMeetingRoom = emptyRoom;
      } else {}

      if (handStatus != currentHandState) {
        if (apply) {
          setState(
            () {
              handStatus = currentHandState;
            },
          );
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
            webViewClass.runJavaScript("MainScreen.raise('S');");
            waitPageChangedByHand([Hand.raised]).then(
              (_) => setState(() => handStatus = Hand.raised),
            );
          } else if (handStatus == Hand.raised) {
            webViewClass.runJavaScript("MainScreen.down();");
            waitPageChangedByHand([Hand.lowered]).then(
              (_) => setState(() => handStatus = Hand.lowered),
            );
          }
        }

        break;
      case 1: // Refresh
        webViewClass.reload();

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
      int buttonStatus = (await webViewClass.runJavaScriptReturningResult(
        'document.getElementById("downbutton")?.children?.length ?? -1',
      ) as num)
          .toInt();

      if (targetHands.contains(Hand.noHand) && buttonStatus < 0) {
        break;
      } else {
        bool isHandListLoaded = await webViewClass.runJavaScriptReturningResult(
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
    int origin = -1;
    while (true) {
      origin = (await webViewClass.runJavaScriptReturningResult(
        'document.getElementById("origin")?.children?.length ?? -1',
      ) as num)
          .toInt();

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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tohru_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tohru.dart';
import 'preference_manager.dart';
import 'package:webview_win_floating/webview.dart';

Future<void> main() async {
  WindowsWebViewPlatform.registerWith();
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
  bool hideWebView = false;
  bool _isLoading = false;
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
  void dispose() {
    printDebug("Perfrom Dispose on main widget!!!");
    // if (handStatus == Hand.raised) {
    //   webViewController.runJavaScript("MainScreen.down();");
    // }
    // waitPageChangedByHand([Hand.noHand, Hand.lowered]).then(
    //   (_) => webViewController.runJavaScript('MainScreen.logOut();'),
    // );

    logOutFromRoomWithLoweringHand();

    _saveAll();

    printDebug("End Dispose on main widget!!!");
    super.dispose();
  }

  late final TohruWebView tohruWebView;

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
    PreferencesManager.init().then((_) {
      _loadAll();
    });

    tohruWebView = TohruWebView(
      onProgress: (int progress) {
        // Update loading bar.
        // setState(() {
        //   _progress = progress;
        // });
      },
      onPageStarted: (String url) async {
        // Set false if the page finished loading.
        printDebug("Start to load Webpage");
        setState(() {
          // hideWebView = true;
          _isLoading = true;
        });
      },
      onPageFinished: (String url) async {
        // Set true if the page finished loading.
        printDebug("Finish to load Webpage");
        printDebug("Start to wait to ajax load");
        LoadingState currentPage = await waitTohruLoading(
          target: LoadingState.loadingScreen,
        );
        printDebug("end to wait to load ");
        setState(() {
          _isLoading = false;
          hideWebView = false;
        });
        if (currentPage == LoadingState.inRoom) {
          waitPageChangedByHand([Hand.lowered, Hand.raised]).then(
            (_) => applyMeetingRoomStatus(),
          );
        } else {
          waitPageChangedByHand([Hand.noHand]).then(
            (_) => applyMeetingRoomStatus(),
          );
        }
      },
    );

    printDebug("End init on main widget!!!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      // appBar: AppBar(),
      onDrawerChanged: (isOpened) => {
        if (isOpened)
          {
            setState(() {
              hideWebView = true;
            })
          }
        else
          {
            //delay to wait for drawer close animation
            //wait 0.2 sec and then set hideWebView to false
            Future.delayed(const Duration(milliseconds: 200), () => "1")
                .then((value) => setState(() {
                      hideWebView = false;
                    }))
          }
      },
      drawer: Drawer(
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
                const SizedBox(
                  height: 100,
                  child: DrawerHeader(
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
                    String selectedOption = _selectedOption;
                    String prefix = _prefix;

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
                                    groupValue: selectedOption,
                                    toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedOption = value ?? "None";
                                        prefix = prefix != '[F]' ? '[F]' : "";
                                      });
                                    },
                                  ),
                                  RadioListTile(
                                    title: const Text('Remote'),
                                    value: 'Remote',
                                    groupValue: selectedOption,
                                    toggleable: true,
                                    dense: true,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedOption = value ?? "None";
                                        prefix = prefix != '[R]' ? '[R]' : "";
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
                                      PreferencesManager.prefix = _prefix;
                                      PreferencesManager.selectedOption =
                                          _selectedOption;
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
                    } else {}
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.restart_alt),
                    title: const Text('Set to Default'),
                    subtitle: const Text('Name and Rooms'),
                    onTap: () {
                      _showConfirmationDialog();
                    }),
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
              ],
        ),
      ),
      body: Container(
        //safeArea Color
        color: Colors.black,
        child: SafeArea(
          child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Visibility(
                  //   visible: _isLoading,
                  //   child: LinearProgressIndicator(
                  //     color: Colors.red,
                  //     // minHeight: 10,
                  //     value: _progress / 100,
                  //   ),
                  // ),
                  Expanded(
                    child: Visibility(
                        visible: !hideWebView,
                        child: tohruWebView.getWebView()),
                  ),
                ],
              )),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        height: 85,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: handStatus == Hand.raised
                          ? const Icon(Icons.person)
                          : handStatus == Hand.lowered
                              ? const Icon(Icons.front_hand)
                              : const Icon(Icons.do_disturb_on_outlined),
                      iconSize: 24,
                      onPressed: () {
                        _onItemTapped(0);
                      },
                    ),
                    FittedBox(
                      fit: BoxFit.contain,
                      child: handStatus == Hand.raised
                          ? const Text(
                              "Lower Hand",
                              textAlign: TextAlign.center,
                            )
                          : handStatus == Hand.lowered
                              ? const Text(
                                  "Raise Hand",
                                  textAlign: TextAlign.center,
                                )
                              : const Text(
                                  "Not in Room",
                                  textAlign: TextAlign.center,
                                ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            iconSize: 24,
                            onPressed: () {
                              _onItemTapped(1);
                            },
                          ),
                          const FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                "Refresh",
                                textAlign: TextAlign.center,
                                textScaleFactor: 0.8,
                              )),
                        ],
                      ),
              ),
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  //reduce gap between items

                  children: [
                    IconButton(
                      icon: const Icon(Icons.meeting_room),
                      iconSize: 24,
                      onPressed: () {
                        _onItemTapped(2);
                      },
                    ),
                    const FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        "Rooms",
                        textAlign: TextAlign.center,
                        textScaleFactor: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        tohruWebView.runJavaScript("MainScreen.down();");
        await waitPageChangedByHand([Hand.lowered]);
      }
      tohruWebView
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
      } else {
        setState(() {});
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
            tohruWebView.runJavaScript("MainScreen.down();");
            await waitPageChangedByHand([Hand.lowered]);
          }

          await tohruWebView.runJavaScript('MainScreen.logOut();');
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
      await tohruWebView.runJavaScript('''
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
      tohruWebView.runJavaScriptReturningResult(
          "Boolean(typeof registered === 'boolean' ? registered : false)"),
      tohruWebView.runJavaScriptReturningResult(
          "Boolean(typeof UserInfo?.hand?.raised === 'boolean' ? UserInfo?.hand?.raised : false)"),
    ]);
    final bool registered = results[0].toString().toLowerCase() == "true";
    final bool handRaised = results[1].toString().toLowerCase() == "true";

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
            tohruWebView.runJavaScript("MainScreen.raise('S');");
            waitPageChangedByHand([Hand.raised]).then(
              (_) => setState(() => handStatus = Hand.raised),
            );
          } else if (handStatus == Hand.raised) {
            tohruWebView.runJavaScript("MainScreen.down();");
            waitPageChangedByHand([Hand.lowered]).then(
              (_) => setState(() => handStatus = Hand.lowered),
            );
          }
        }

        break;
      case 1: // Refresh
        tohruWebView.reload();

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
      var ret = await tohruWebView.runJavaScriptReturningResult(
        'document.getElementById("downbutton")?.children?.length ?? -1',
      );
      int buttonStatus = int.parse(ret.toString());

      if (targetHands.contains(Hand.noHand) && buttonStatus < 0) {
        break;
      } else {
        bool isHandListLoaded = (await tohruWebView.runJavaScriptReturningResult(
                "(document.getElementById('speaker')?.textContent ?? 'LOADING...') !== 'LOADING...'")) ==
            "true";
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
      var ret = await tohruWebView.runJavaScriptReturningResult(
        'document.getElementById("origin")?.children?.length ?? -1',
      );

      origin = int.parse(ret.toString());

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

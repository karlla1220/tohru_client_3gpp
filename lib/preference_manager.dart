import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tohru.dart';

class PreferencesManager {
  static late SharedPreferences _prefs;

  static void setDefaults() {
    _prefs.setString('userName', "Company - GivenN LastN");
    _prefs.setString('_prefix', "[F]");
    _prefs.setString('_selectedOption', "F2F");

    final roomList = [
      MeetingRoom(name: "RAN1_Main"),
      MeetingRoom(name: "RAN1_Brk1"),
      MeetingRoom(name: "RAN1_Brk2"),
      MeetingRoom(name: "RAN1_Off1"),
      MeetingRoom(name: "RAN1_Off2"),
    ].map((room) => room.toJson()).toList();

    _prefs.setStringList(
        'rooms', roomList.map((json) => jsonEncode(json)).toList());
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get userName =>
      _prefs.getString('userName') ?? 'Company - GivenN LastN';

  static set userName(String value) {
    _prefs.setString('userName', value);
  }

  static String get url => _prefs.getString('url') ?? 'about:blank';

  static set url(String value) {
    _prefs.setString('url', value);
  }

  static String get prefix => _prefs.getString('_prefix') ?? '[F]';

  static set prefix(String value) {
    _prefs.setString('_prefix', value);
  }

  static String get selectedOption =>
      _prefs.getString('_selectedOption') ?? 'F2F';

  static set selectedOption(String value) {
    _prefs.setString('_selectedOption', value);
  }

  static List<MeetingRoom> get rooms {
    List<MeetingRoom> savedRooms;
    final roomListJson = _prefs.getStringList('rooms') ?? [];
    savedRooms = roomListJson
        .map((json) => MeetingRoom.fromJson(jsonDecode(json)))
        .toList();

    if (savedRooms.isEmpty) {
      //initializer
      savedRooms = [
        MeetingRoom(name: "RAN1_Main"),
        MeetingRoom(name: "RAN1_Brk1"),
        MeetingRoom(name: "RAN1_Brk2"),
        MeetingRoom(name: "RAN1_Off1"),
        MeetingRoom(name: "RAN1_Off2"),
      ];
    }
    return savedRooms;
  }

  static set rooms(List<MeetingRoom> value) {
    final roomList = value.map((room) => room.toJson()).toList();
    _prefs.setStringList(
        'rooms', roomList.map((json) => jsonEncode(json)).toList());
  }
}

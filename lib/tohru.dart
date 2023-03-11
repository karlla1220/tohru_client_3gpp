import 'package:flutter/material.dart';

class MeetingRoom {
  String name;
  bool available;
  MeetingRoom({required this.name, this.available = true});
  factory MeetingRoom.fromJson(Map<String, dynamic> json) {
    return MeetingRoom(
      name: json['name'] ?? '',
      available: json.containsKey('available') ? json['available'] : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'available': available,
    };
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

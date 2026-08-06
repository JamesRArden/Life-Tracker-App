import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState(); 
  //When someone calls createState(), return a new _HomePageState() object
}

class _HomePageState extends State<HomePage> {
  // This list will store all the widgets/items you add

  List<String> items = [];

  @override
  void initState() {
    super.initState();
    LoadStoredTrackers();   // call async loader
  }

  Future<void> LoadStoredTrackers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("Life-Trackers");

    setState(() {
       if (saved == null) {
           items = [];
        } else {
            items = List<String>.from(jsonDecode(saved));
        }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Items Example"),
        backgroundColor: Colors.lightBlueAccent,
     ),

      // MAIN SCREEN CONTENT
      body: Center(
        child: ListView.builder(         
          itemCount: items.length,
          itemBuilder: (context, index) {
            return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                         builder: (context) => TrackerPage(trackername: items[index]),
                       ),
                  );
                },
            child: Card(
              margin: const EdgeInsets.all(10),
              color: Colors.lightBlueAccent,
              child: Padding(
                padding: const EdgeInsets.all(20),
              child: Text(
                  items[index],
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            );
          },
        ),
      ),

      // BUTTON THAT ADDS ITEMS
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newtrackernameentry(items);
        },
        
       backgroundColor: const Color.fromARGB(255, 201, 167, 218),
       splashColor: const Color.fromARGB(255, 202, 39, 189),
    
        child: const Icon(
            Icons.add,
            color: Colors.purpleAccent,
            ),
      ),
    );
  }

  void _newtrackernameentry(items) {
  String userinput = "";

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Enter new tracker name"),
        content: TextField(
          onChanged: (value) {
            userinput = value;
          },
          decoration: InputDecoration(
            hintText: "Type here...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close popup
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: ()  async {
                items.add(userinput);
                final prefs = await SharedPreferences.getInstance();
                prefs.setString("Life-Trackers", jsonEncode(items));
                
              setState(() {
             
              });

              if (!mounted) {
                return;
              }
              else{
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}
}

class TrackerPage extends StatefulWidget {
  final String trackername;

  const TrackerPage({super.key, required this.trackername});

  

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: Text(widget.trackername),
         backgroundColor: Colors.lightBlueAccent,
         ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
         },
        child: const Icon(
              Icons.add,
              color: Colors.purpleAccent,
            ),
          ),
        );
  }
}


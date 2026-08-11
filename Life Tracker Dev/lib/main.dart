import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lifetrackerapp/database.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage());
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
    LoadStoredTrackers(); // call async loader
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
        title: const Text("Life Trackers"),
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
                    builder: (context) =>
                        TrackerPage(trackername: items[index]),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.all(10),
                color: Colors.lightBlueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(items[index], style: const TextStyle(fontSize: 22)),
                      IconButton(
                        onPressed: () {
                          _trackeredit(items[index]);
                        },
                        icon: Icon(Icons.more_vert),
                      ),
                    ],
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

        child: const Icon(Icons.add, color: Colors.purpleAccent),
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
            decoration: InputDecoration(hintText: "Type here..."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close popup
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                //stores tracker name
                items.add(userinput);
                final prefs = await SharedPreferences.getInstance();
                prefs.setString("Life-Trackers", jsonEncode(items));

                setState(() {});

                if (!mounted) {
                  return;
                } else {
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

  _trackeredit(item) {
    String newtrackername = "";
    final controller = TextEditingController(text: item);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Tracker Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Name: "),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        _updatetrackername(item, value);
                      },
                      textAlign: TextAlign.center,
                      controller: controller,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text("Remove:"),
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        _deletetracker(item);
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  _deletetracker(trackername) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("Life-Trackers");

    if (saved == null) {
      items = [];
    } else {
      items = List<String>.from(jsonDecode(saved));
    }

    items.remove(trackername);

    prefs.setString("Life-Trackers", jsonEncode(items));
    setState(() {});
  }

  _updatetrackername(oldname, newname) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("Life-Trackers");

    if (saved == null) {
      items = [];
    } else {
      items = List<String>.from(jsonDecode(saved));
    }

    final index = items.indexOf(oldname);

    if (index != -1) {
      items[index] = newname;
    }

    prefs.setString("Life-Trackers", jsonEncode(items));
    setState(() {});
  }
}

class TrackerPage extends StatefulWidget {
  final String trackername;

  const TrackerPage({super.key, required this.trackername});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  final Color colourscheme = Color.fromARGB(255, 104, 196, 161);
  DateTime today = DateTime.now();
  late SimpleDate date;

  @override
  void initState() {
    super.initState();
    date = initiatedate(today);
  }

  initiatedate(DateTime today) {
    return SimpleDate(today.day, today.month, today.year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.trackername,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  child: IconButton(
                    onPressed: () {
                      date.prevmonth();
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_left, size: 50),
                  ),
                ),

                const Spacer(),

                Text(
                  "${date.month}/${date.year}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Container(
                  child: IconButton(
                    onPressed: () {
                      date.nextmonth();
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_right, size: 50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsGeometry.directional(
                top: 10,
                end: 10,
                start: 10,
              ),
              child: _calanderview(date, colourscheme, widget.trackername),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calanderview(SimpleDate currentdate,Color colour,String trackername,) {
    List<Map<String, dynamic>> monthrecords = [];

     Future<void> loadrecord() async {
      monthrecords = await _getrelatedrecords(widget.trackername, currentdate);
      setState(() {});
    }

    @override
    void initState() {
      super.initState();
      loadrecord();
    }

  

    int daysinmonth = DateUtils.getDaysInMonth(
      currentdate.year,
      currentdate.month,
    );

/*
    final List<SimpleDate> days = List.generate(
      daysinmonth,
      (index) => SimpleDate(currentdate.year, currentdate.month, index + 1),
    );
*/
   
    final List<boxcolour> days = List.generate(
      daysinmonth,
      (index) {
        SimpleDate day = SimpleDate(  index + 1, currentdate.month,currentdate.year);
        
        
       
        for (var row in monthrecords) {
          if(row["date"] == day){
              return boxcolour(day, row["value"]);
          }
        }

        return boxcolour(day, -1);
      } 
    );


    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.7,
      ),
      itemCount: daysinmonth,
      itemBuilder: (context, index) {
        final day = days[index];
        final squarecolour = colour;

        return GestureDetector(
          onTap: () => _daytapped(day, trackername),
          child: Container(
            decoration: BoxDecoration(
              color: squarecolour,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text('${day.date.day}', style: const TextStyle(fontSize: 16)),
            ),
          ),
        );
      },
    );
  }

  _daytapped(day, trackername) {
    double daywellness = 1;

    
    if(day.success != -1){
      daywellness = day.success;
    }
 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Center(child: Text("Success Meter")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Text(daywellness.toString())),
                  Slider(
                    value: daywellness,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (newValue) {
                      setStateDialog(() {
                        daywellness = newValue;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      _addrecord(trackername,daywellness,day );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
 
  _addrecord(trackername, daywellness, dateof) async {
    final db = await AppDatabase.database;

    String day = dateof.date.day.toString();
    String month = dateof.date.month.toString();
    String year = dateof.date.year.toString();
    String inputdate = "$year-$month-$day";
    await db.insert('daily_entries', {
      'date': inputdate,
      'tracker': trackername,
      'value': daywellness,
    });
  }

  _getrelatedrecords(trackername, day) async {
    final db = await AppDatabase.database;

    String month = day.date.month.toString();
    String year = day.date.year.toString();

    int daysinmonth = DateUtils.getDaysInMonth(
      day.date.year,
      day.date.month,
    );

    String firstday = "$year-$month-01";
    String lastday = "$year-$month-$daysinmonth";


    return await db.query(
      'daily_entries',
      where: 'date BETWEEN ? AND ? AND tracker LIKE ?',
      whereArgs: [firstday, lastday, trackername],
      orderBy: 'date ASC',
    );
  }
}

class SimpleDate {
  int day = 0;
  int month = 0;
  int year = 0;

  SimpleDate(int day, int month, int year) {
    this.day = day;
    this.month = month;
    this.year = year;
  }

  nextmonth() {
    if (month != 12) {
      month++;
    } else {
      year++;
      month = 1;
    }
  }

  prevmonth() {
    if (month != 1) {
      month--;
    } else {
      year--;
      month = 12;
    }
  }
}

class boxcolour {
  SimpleDate date = SimpleDate(0, 0, 0);
  int success = 0;

  boxcolour(SimpleDate date, int success) {
    this.date = date;
    this.success = success;
  }
}


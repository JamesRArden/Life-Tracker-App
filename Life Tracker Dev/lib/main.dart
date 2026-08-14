import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lifetrackerapp/database.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
                _addtracker(userinput);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  _addtracker(userinput) async {
    items.add(userinput);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("Life-Trackers", jsonEncode(items));

    final db = await AppDatabase.database;

    final basecolour1 = (Colors.blue).value;
    final basecolour2 = (Colors.purpleAccent).value;

    await db.insert('tracker_meta_data', {
      'tracker': userinput,
      'colour1': basecolour1,
      'colour2': basecolour2,
    });

    setState(() {});

    if (!mounted) {
      return;
    } else {
      Navigator.pop(context);
    }
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
  String viewtype = "monthly";
  String oppositeviewtype = "Yearly View";

  @override
  void initState() {
    super.initState();
    date = initiatedate(today);

    loadrecord();
  }

  List<Map<String, dynamic>> monthrecords = [];
  Map<String, int> yearhashmap = {};
  List<Map<String, dynamic>> trackermetadata = [];

  Color worst = Colors.blue;
  Color best = Colors.purpleAccent;

  Future<void> loadrecord() async {
    monthrecords = await _getrelatedrecordsmonth(widget.trackername, date);
    yearhashmap = await _getrelatedrecordsyear(widget.trackername, date);
    trackermetadata = await _gettrackermetadata(widget.trackername);

    final trackermetadatarecord = trackermetadata[0];

    best = Color((trackermetadatarecord['colour1'] as int));
    worst = Color((trackermetadatarecord['colour2'] as int));

    setState(() {});
  }

  initiatedate(DateTime today) {
    return SimpleDate(today.day, today.month, today.year);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          //negative velo so left swipe
          if (viewtype == "monthly") {
            date.nextmonth();
          } else {
            date.nextyear();
          }
          loadrecord();
          setState(() {});
        } else {
          //positive velo so right swipe
          if (viewtype == "monthly") {
            date.prevmonth();
          } else {
            date.prevyear();
          }
          loadrecord();
          setState(() {});
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.trackername,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == "changeview") {
                  if (viewtype == "monthly") {
                    viewtype = "yearly";
                    oppositeviewtype = "Monthly View";
                    loadrecord();
                    setState(() {});
                  } else {
                    viewtype = "monthly";
                    oppositeviewtype = "Yearly View";
                    loadrecord();
                    setState(() {});
                  }
                  setState(() {});
                } else if (value == "changecolours") {
                  _changecoloursmenue(widget.trackername);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'changeview',
                  child: Text(oppositeviewtype),
                ),
                PopupMenuItem(
                  value: 'changecolours',
                  child: Text('Change Colours'),
                ),
              ],
            ),
          ],
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
                        if (viewtype == "monthly") {
                          date.prevmonth();
                        } else {
                          date.prevyear();
                        }
                        loadrecord();
                        setState(() {});
                      },
                      icon: Icon(Icons.arrow_left, size: 50),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    viewtype == "monthly"
                        ? "${date.month}/${date.year}"
                        : "${date.year}",

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    child: IconButton(
                      onPressed: () {
                        if (viewtype == "monthly") {
                          date.nextmonth();
                        } else {
                          date.nextyear();
                        }
                        loadrecord();
                        setState(() {});
                      },
                      icon: Icon(Icons.arrow_right, size: 50),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 5, left: 10, right: 10, bottom: 5),
              child: Row(
                children: [
                  Container(child: Text("Worst")),
                  const Spacer(),
                  Container(child: Text("Best")),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [worst, best],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.directional(
                  top: 10,
                  end: 10,
                  start: 10,
                ),
                child: (viewtype == "monthly")
                    ? _calandermonthview(
                        monthrecords,
                        date,
                        worst,
                        best,
                        widget.trackername,
                      )
                    : _calanderyearview(
                        yearhashmap,
                        date,
                        worst,
                        best,
                        widget.trackername,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _calanderyearview(yearrecords, date, colourworst, colourbest, trackername) {
    SimpleDate dateiteration = SimpleDate(1, 1, date.year);
    List<List<boxcolour>> monthsofyear = List.generate(12, (_) => []);

    int daysinyear = 365;

    int daysinfeb = DateUtils.getDaysInMonth(dateiteration.year, 2);

    if (daysinfeb == 29) {
      daysinyear = 366;
    }

    for (int m = 0; m < 12; m++) {
      int daysinmonth = DateUtils.getDaysInMonth(
        dateiteration.year,
        dateiteration.month,
      );

      final List<boxcolour> days = List.generate(daysinmonth, (index) {
        SimpleDate day = SimpleDate(index + 1, (m + 1), dateiteration.year);

        /*
        for (var row in yearrecords) {
          if (row["date"] == day.tostringyyyymmdd()) {
            return boxcolour(day, row["value"]);
          }
        }
*/
        if (yearrecords.containsKey(day.tostringyyyymmdd())) {
          int value = yearrecords[day.tostringyyyymmdd()];
          return boxcolour(day, value);
        }

        return boxcolour(day, -1);
      });

      monthsofyear[m] = days;
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index1) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 0.7,
            mainAxisExtent: 15,
          ),
          itemCount: DateUtils.getDaysInMonth(date.year, (index1 + 1)),
          itemBuilder: (context, index2) {
            final day = monthsofyear[index1][index2];

            double strength = 1;
            Color colour1 = const Color.fromARGB(255, 233, 192, 168);
            Color colour2 = const Color.fromARGB(255, 233, 192, 168);

            if (day.success != -1) {
              strength = (day.success) / 10;

              colour2 = colourworst;
              colour1 = colourbest;
            }

            return Container(
              decoration: BoxDecoration(
                color: Color.lerp(colour2, colour1, strength),
                //borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
            );
          },
        );
      },
    );
  }

  _gettrackermetadata(trackername) async {
    final db = await AppDatabase.database;

    final trackermetadata = await db.query(
      'tracker_meta_data',
      where: 'tracker like ? ',
      whereArgs: [trackername],
    );

    return trackermetadata;
  }

  _changecoloursmenue(trackername) async {
    final db = await AppDatabase.database;

    final trackermetadata = await db.query(
      'tracker_meta_data',
      where: 'tracker like ? ',
      whereArgs: [trackername],
    );

    final record = trackermetadata[0];

    Color best = Color((record['colour1'] as int));
    Color worst = Color((record['colour2'] as int));

    String colour_replaced = "colour1";
    Color selected_colour_colour = best;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              content: Column(
                children: [
                  Container(
                    child: Text(
                      "Change Tracker Colours",
                      style: TextStyle(
                        fontSize: 24, // change this
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: 0,
                      left: 5,
                      right: 5,
                      bottom: 5,
                    ),
                  ),

                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setStateDialog(() {
                            colour_replaced = "colour2";
                            selected_colour_colour = worst;
                          });

                          ;
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(
                            top: 5,
                            left: 5,
                            right: 5,
                            bottom: 5,
                          ),
                          decoration: BoxDecoration(
                            color: worst,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("Worst Colour"),
                        ),
                      ),

                      const Spacer(),

                      InkWell(
                        onTap: () {
                          setStateDialog(() {
                            colour_replaced = "colour1";
                            selected_colour_colour = best;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(
                            top: 5,
                            left: 5,
                            right: 5,
                            bottom: 5,
                          ),
                          decoration: BoxDecoration(
                            color: best,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("Best Colour"),
                        ),
                      ),
                    ],
                  ),

                  ColorPicker(
                    pickerColor: selected_colour_colour,
                    onColorChanged: (color) {
                      setStateDialog(() {
                        selected_colour_colour = color;
                      });
                    },
                    paletteType: PaletteType.hsv,
                    enableAlpha: false,
                    displayThumbColor: true,
                  ),

                  Container(
                    child: IconButton(
                      onPressed: () {
                        _updatetrackercolour(
                          trackername,
                          colour_replaced,
                          selected_colour_colour.value,
                        );
                        setStateDialog(() {
                          if (colour_replaced == "colour1") {
                            best = selected_colour_colour;
                          } else {
                            worst = selected_colour_colour;
                          }
                        });
                      },
                      icon: Icon(Icons.done),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _updatetrackercolour(trackername, replacedcolour, newcolour) async {
    final db = await AppDatabase.database;

    if (replacedcolour == "colour1") {
      await db.update(
        'tracker_meta_data',
        {'colour1': newcolour},
        where: 'tracker = ?',
        whereArgs: [trackername],
      );
    } else {
      await db.update(
        'tracker_meta_data',
        {'colour2': newcolour},
        where: 'tracker = ?',
        whereArgs: [trackername],
      );
    }

    loadrecord();
    setState(() {});
  }

  _calandermonthview(
    monthrecords,
    SimpleDate currentdate,
    Color colourworst,
    Color colourbest,
    String trackername,
  ) {
    int daysinmonth = DateUtils.getDaysInMonth(
      currentdate.year,
      currentdate.month,
    );

    final List<boxcolour> days = List.generate(daysinmonth, (index) {
      SimpleDate day = SimpleDate(
        index + 1,
        currentdate.month,
        currentdate.year,
      );

      for (var row in monthrecords) {
        if (row["date"] == day.tostringyyyymmdd()) {
          return boxcolour(day, row["value"]);
        }
      }

      return boxcolour(day, -1);
    });

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

        double strength = 1;
        Color colour1 = const Color.fromARGB(255, 233, 192, 168);
        Color colour2 = const Color.fromARGB(255, 233, 192, 168);

        if (day.success != -1) {
          strength = (day.success) / 10;
          colour2 = colourworst;
          colour1 = colourbest;
        }

        return GestureDetector(
          onTap: () => _daytapped(day, trackername),
          child: Container(
            decoration: BoxDecoration(
              color: Color.lerp(colour2, colour1, strength),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                '${day.date.day}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }

  _daytapped(day, trackername) {
    double daywellness = 1;

    if (day.success != -1) {
      daywellness = (day.success).toDouble();
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
                      if (day.success != -1) {
                        _replacerecord(trackername, daywellness, day);
                      } else {
                        _addrecord(trackername, daywellness, day);
                      }
                      loadrecord();
                      setState(() {});
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

  _addrecord(trackername, daywellness, day) async {
    final db = await AppDatabase.database;

    await db.insert('daily_entries', {
      'date': day.date.tostringyyyymmdd(),
      'tracker': trackername,
      'value': daywellness,
    });
  }

  _replacerecord(trackername, daywellness, day) async {
    final db = await AppDatabase.database;

    await db.update(
      'daily_entries',
      {'value': daywellness},
      where: 'date = ?',
      whereArgs: [day.date.tostringyyyymmdd()],
    );
  }

  _getrelatedrecordsmonth(trackername, day) async {
    final db = await AppDatabase.database;

    int daysinmonth = DateUtils.getDaysInMonth(day.year, day.month);

    String firstday = SimpleDate(1, day.month, day.year).tostringyyyymmdd();
    String lastday = SimpleDate(
      daysinmonth,
      day.month,
      day.year,
    ).tostringyyyymmdd();

    final records = await db.query(
      'daily_entries',
      where: 'date BETWEEN ? AND ? AND tracker LIKE ?',
      whereArgs: [firstday, lastday, trackername],
      orderBy: 'date ASC',
    );

    return records;
  }
}

_getrelatedrecordsyear(trackername, day) async {
  final db = await AppDatabase.database;

  String firstday = SimpleDate(1, 1, day.year).tostringyyyymmdd();
  String lastday = SimpleDate(31, 12, day.year).tostringyyyymmdd();

  final records = await db.query(
    'daily_entries',
    where: 'date BETWEEN ? AND ? AND tracker LIKE ?',
    whereArgs: [firstday, lastday, trackername],
    orderBy: 'date ASC',
  );

  Map<String, int> yearhashmap = {};

  for (var row in records) {
    final String date = row["date"] as String;
    final int value = row["value"] as int;

    yearhashmap[date] = value;
  }

  return yearhashmap;
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

  tostringyyyymmdd() {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
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

  nextyear() {
    year++;
  }

  prevyear() {
    year--;
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

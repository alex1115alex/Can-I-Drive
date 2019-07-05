import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert' show json;
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

//void main() => runApp(new DrinkApp());

void main() {
  runApp(MaterialApp(
    home: DrinkApp(),
  ));
}

class Drink {
  //a drink stores a name, ABV, volume, and time drank
  String name;
  double abv;
  double volume;
  DateTime time;
  String timeString;

  Drink(String nameInput, double abvInput, double volumeInput,
      DateTime timeInput) {
    name = nameInput;
    abv = abvInput;
    volume = volumeInput;
    time = timeInput;
    timeString = time.toString();
  }

  Drink.fromJson(Map<String, dynamic> m) {
    name = m['mName'];
    abv = m['mAbv'];
    volume = m['mVolume'];
    timeString = m['mTime'];
    time = DateTime.parse(timeString);
  }

  String get mName => name;
  double get mAbv => abv;
  double get mVolume => volume;
  String get mTime =>
      time.toString(); //convert time (type DateTime) toString() first

  Map<String, dynamic> toJson() => {
        'mName': name,
        'mAbv': abv,
        'mVolume': volume,
        'mTime': timeString,
      };

  double getBAC() //returns the bac from this drink
  {
    //weight and genderConst were here

    //determine how many hours have passed since drinking
    var now = new DateTime.now();
    Duration diff = now.difference(time);
    double hoursPassed = diff.inMinutes / 60;

    //calculate BAC
    double bac = (((abv * volume * .789) / (weight * genderConst))) -
        ((hoursPassed * (.015))/drinksList.length); //divide by drinksList length to accurately lower bac level

    print("BAC of drink: " + name + " = " + bac.toString());

    //return BAC
    return bac;
  }

  String getInfo() {
    return "(" +
        time.toString().substring(11, 16) +
        ") $name:\n $abv% - $volume ml";
  }

  String getPresetInfo() {
    return "$name\n$abv% - $volume ml";
  }
}

List<Drink> drinksList = []; //drinksList is a List that stores Drink objects
List<Drink> presetDrinksList =
    []; //presetDrinksList contains saved preset drinks

String drinkName; //Stores the drinkName
String drinkABV; //Stores the drinkABV
String drinkVolume; //Stores the drinkVolume

double threshold = 0; //default threshold = bac of 0
double weight; //my weight in grams
double
    weightInLbs; //my weight in lbs. We only use the variable to display the weight in Lbs.
double genderConst; //.68 for males, .55 for females

bool displayedNotification = true;

String titleBarText = "";

DateTime soberTime = new DateTime.now();

class MyAppBar extends AppBar {
  //final appBarHeight = MyAppBar().preferredSize.height;
}

final double appBarHeight = MyAppBar().preferredSize.height;

class SettingsPage extends MaterialPageRoute<Null> {
  SettingsPage()
      : super(builder: (BuildContext ctx) {
        SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
          return Scaffold(
            resizeToAvoidBottomPadding: false,
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text("Settings"),
              backgroundColor: Color(0xff00d368),
              elevation: 1.0,
            ),
            body: Center(
              child: Container(
                decoration: new BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  //LEFT MENU COLUMN (TEXT FIELDS AND BUTTON)
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    //Text("ENTER DRINK \n"),

                    Container(
                      //Weight entry
                      height: 55,
                      width: 120,
                      //padding: EdgeInsets.all(20.0),
                      child: TextField(
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          fillColor: Colors.white12,
                          filled: true,
                          labelText: "Weight (lbs)",
                          hintText: "$weightInLbs lbs",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: false),
                        textAlign: TextAlign.center,
                        onChanged: (text) {
                          weight = double.parse(text) *
                              453.592; //convert input from lbs to grams first
                          weightInLbs = double.parse(text);
                        },
                      ),
                    ),

                    Column(
                      children: <Widget>[
                        
                        Container(
                          //BAC threshold entry
                          height: 55,
                          width: 180,
                          //padding: EdgeInsets.all(20.0),
                          child: TextField(
                            decoration: InputDecoration(
                              fillColor: Colors.white12,
                                  filled: true,
                              labelText: "BAC Threshold",
                              hintText: "$threshold",
                              border: OutlineInputBorder(),
                            ),
                            //maxLength: 4,
                            textAlign: TextAlign.center,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            onChanged: (text) {
                              threshold = double.parse(text);
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "This should be 0.08 in the majority of the USA, or 0.0 if you're under 21.\nAlways check your local laws.\n",
                          textAlign: TextAlign.center,
                        ),

                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                          //Select MALE as gender!
                          //icon: Icon(Icons.arrow_left),
                          color: Colors.blueGrey,
                          child: const Text("Male"),
                          onPressed: () {
                            genderConst = .68;
                          },
                        ),
                        RaisedButton(
                          //Select FEMALE as gender!
                          //icon: Icon(Icons.arrow_right),
                          color: Colors.pinkAccent,
                          child: const Text("Female"),
                          onPressed: () {
                            genderConst = .55;
                          },
                        ),
                      ],
                    ),

                    RaisedButton(
                      //RESET DRINKS LIST!
                      //icon: Icon(Icons.arrow_left),
                      color: Colors.redAccent,
                      child: const Text("Reset drinks list"),
                      onPressed: () {
                        drinksList.clear();
                        //presetDrinksList.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
}

class DrinkApp extends StatefulWidget {
  @override
  _DrinkAppState createState() => new _DrinkAppState();
}

class _DrinkAppState extends State<DrinkApp> {
  //Timer for keeping the timer up-to-date. Thanks Gunter from Stackoverflow.
  Timer timer;

  //Notification thing
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    //initState run on startup
    super.initState();

    displayedNotification = true;

    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin.initialize(
        initializationSettings); //, selectNotification: onSelectNotification);

    //scheduleNotification();

    //load the save data
    loadData();

    //setup the timer
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => updateClock());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  //default messages
  String _outputBAC = "0%";
  String _timeString = "You're sober, mate";
  String _drinksString = "";

  //onselectnotification
  Future onSelectNotification(String payload) async {
    print("Notification payload: $payload");
  }

  Future scheduleNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'You can drive!',
        'Your BAC has hit $threshold.', platformChannelSpecifics,
        payload: 'item x');
  }

  void removeDeadDrinks()
  {
    if(drinksList.length > 0) //if there are multiple drinks, remove any that are out of our system
    {
      for(int i = drinksList.length - 1; i >= 0; i--)
      {
        if(drinksList[i].getBAC() <= .00001)
        {
          print("remove drink: " + drinksList[i].name);
          drinksList.removeAt(i);
          
        }
      }
    }
  }

  //add custom drink to array
  void addDrink() {
    //make sure all fields are filled in
    if (drinkName == null || drinkABV == null || drinkVolume == null) {
      return (null);
    }

    //make sure user has supplied information
    if (weight == 0 || weight == null || genderConst == null) {
      Navigator.push(context, SettingsPage());
      return (null);
    }

    removeDeadDrinks();

    var now = new DateTime.now();
    var abvDouble = double.parse(drinkABV);
    var volumeDouble = double.parse(drinkVolume);

    drinksList.add(new Drink(drinkName, abvDouble, volumeDouble, now));

    updateInfo();
  }

  //save custom drink to presets
  void saveDrink() {
    //make sure all fields are filled in
    if (drinkName == null || drinkABV == null || drinkVolume == null) {
      return (null);
    }

    var now = new DateTime.now();
    var abvDouble = double.parse(drinkABV);
    var volumeDouble = double.parse(drinkVolume);

    presetDrinksList.add(new Drink(drinkName, abvDouble, volumeDouble, now));
  }

  void addDrinkFromPresets(int index) {

    //make sure all fields are filled in
    if (drinkName == null || drinkABV == null || drinkVolume == null) {
      return (null);
    }

    //make sure user has supplied information
    if (weight == 0 || weight == null || genderConst == null) {
      Navigator.push(context, SettingsPage());
      return (null);
    }

    presetDrinksList[index].time = DateTime.now();
    removeDeadDrinks();
    drinksList.add(presetDrinksList[index]);
    updateInfo();
  }

  //like updateInfo
  void updateClock() {
    //check the timer

    //if we've already passed soberTime
    if (DateTime.now().isAfter(soberTime.add(Duration(seconds: -2)))) { //I stuck a delay of -2 seconds in there because when the app boots the soberTime is after DateTime.now() by a fraction of a second
      //print("WE ARE SOBER");

      //set the output
      setState(() => _outputBAC = ""); //was 0%
      setState(() => _timeString = "You can drive!"); //was "You're sober mate!"
      setState(() => titleBarText = "");
      setState(() => _drinksString = "");

      if (!displayedNotification) {
        displayedNotification = true;
        print("NOTIFICATION");
        scheduleNotification();
      }
    } 
    else //if soberTime is yet to come thus we're hammered
    {
      //print("NOT SOBER");
      displayedNotification = false;

      //set clock
      Duration dur = soberTime.difference(DateTime.now());
      setState(() => _timeString = dur.toString().substring(0, 7));

      //determine the totalBAC (sum of all Drink's BACs)
      double totalBAC = 0;

      //for each current drink
      for (int i = 0; i < drinksList.length; i++) {
        //calculate the BAC of this drink
        double thisBAC = drinksList[i].getBAC();

        //check if the BAC is <= 0. If it is, we need to remove it from the list of drinks!
        if(thisBAC > 0)
        {
          totalBAC += thisBAC;
        }   
      }

      setState(() => _outputBAC = totalBAC.toStringAsFixed(3) + "%");

      //set the '(# drinks)' text
      if (drinksList.length == 1) {
        setState(() => _drinksString = "(1 drink)");
      } else //drinksList is greater than 1
      {
        setState(() =>
            _drinksString = "(" + drinksList.length.toString() + " drinks)");
      }
    }
  }

  void updateInfo() {
    //determine the totalBAC (sum of all Drink's BACs)
    double totalBAC = 0;
    for (int i = 0; i < drinksList.length; i++) {
      totalBAC += drinksList[i].getBAC();
      print("totalbac: $totalBAC");
    }

    if (totalBAC > threshold) //If our BAC is greater than the threshold, print BAC information
    {
      //update the percentage immediately
      //setState(() => _outputBAC = totalBAC.toStringAsFixed(10) + "%");

      //update soberTime
      int mins = (((totalBAC - threshold) / .015) * 60).round();
      soberTime = DateTime.now().add(Duration(minutes: mins));

      //update the title bar to display the sober time
      setState(
          () => titleBarText = "- " + soberTime.toString().substring(11, 16));

      updateClock();
    } else //totalBAC is under threshold
    {
      //set outputBAC to empty string
      //setState(() => _outputBAC = "");

      //update soberTime to now
      soberTime = DateTime.now();

      //update titleBar
      setState(() => titleBarText = "");

      updateClock();
    }

    //save data
    saveData();
  }

  final String drinksListKey = 'com.alexisraelov.canidrive.activeDrinks';
  final String favoritesKey =
      'com.alexisraelov.canidrive.favorites'; // maybe use your domain + appname

  void saveData() async {
    print("SAVING DATA");
    //initialize sharedprefs object
    SharedPreferences sp = await SharedPreferences.getInstance();

    //save the drinksList array
    sp.setString(drinksListKey, json.encode(drinksList));

    //save the presetDrinksList array
    sp.setString(favoritesKey, json.encode(presetDrinksList));

    //save weight, threshold, sex
    sp.setDouble('threshold', threshold);
    sp.setDouble('weight', weight);
    sp.setDouble('genderConst', genderConst);

    print("DATA SAVED");
  }

  void loadData() async {
    print("LOADING DATA");
    SharedPreferences sp = await SharedPreferences.getInstance();

    //load drinksList
    json
        .decode(sp.getString(drinksListKey))
        .forEach((map) => drinksList.add(new Drink.fromJson(map)));

    //load presetDrinksList
    json
        .decode(sp.getString(favoritesKey))
        .forEach((map) => presetDrinksList.add(new Drink.fromJson(map)));

    //load weight, threshold, sex
    threshold = double.parse(sp.getDouble('threshold').toStringAsFixed(2));
    weight = double.parse(sp.getDouble('weight').toStringAsFixed(1));
    genderConst = sp.getDouble('genderConst');

    if (weight == null || genderConst == null) //if these settings don't exist
    {
      //pull up the settings page
      Navigator.push(context, SettingsPage());
    }

    if (weight != null) {
      weightInLbs = weight / 453.592;
    }

    //update the info
    updateInfo();

    print("DATA LOADED");
  }

  //VISUAL ASSEMBLY
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    return new MaterialApp(
      title: "Can I Drive?",
      home: new Scaffold(
        //backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: new Text("Can I Drive? $titleBarText"),
          backgroundColor: Color(0xff00D368),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              color: Colors.white,
              onPressed: () {
                Navigator.push(context, SettingsPage());
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
                  color: Colors.black,
                ),
            itemCount: drinksList.length,
            itemBuilder: (BuildContext ctxt, int index) {
              return new Dismissible(
                key: new Key(
                    drinksList[index].getInfo() + drinksList.length.toString()),
                onDismissed: (direction) {
                  //when swiped, remove the drink
                  //setState(() => drinksList.removeAt(index));
                  setState(() {
                    drinksList.removeAt(index);
                    displayedNotification = true;
                  });

                  //check for updates
                  updateInfo();
                },
                background: new Container(
                  color: Colors.red,
                ),
                child: new ListTile(
                  title: new Text(drinksList[index].getInfo()),
                ),
              );
            },
          ),
        ),
        body: OrientationBuilder(builder: (context, orientation) {
          //here we make an orientation thing so we can find the size
          //I'm not really sure why this but thanks Deven Joshi for your Flutter guide code
          final size = MediaQuery.of(context).size;

          return Container(
            //MAIN CONTAINER
            decoration: new BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.png"),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.center,
            //color: const Color(0xfffffbfa),
            child: Column(
              //Main column with data on top and menu on bottom
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Container(
                  //INFO CONTAINER

                  height: (size.height - appBarHeight) * .3,
                  child: Column(
                    children: <Widget>[

                      SizedBox(height: 20),
                      Text(
                        "$_outputBAC",
                        style: TextStyle(fontSize: 40),
                      ),
                      Text(
                        "$_timeString",
                        style: TextStyle(fontSize: 25),
                      ),
                      Text(
                        "$_drinksString",
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Container(
                  //MENU CONTAINER
                  height: (size.height - appBarHeight) * .6,
                  child: PageView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      Container(
                        width: size.width * .8,
                        padding: EdgeInsets.only(right: size.width * .2, left: size.width * .2),
                        child: ListView(
                          
                          //LEFT MENU Drink Input (TEXT FIELDS AND BUTTON)
                          //mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            Container(
                              //Drink name entry
                              height: 45,
                              width: 120,
                              //padding: EdgeInsets.only(bottom: 0.0),
                              child: TextField(
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  fillColor: Colors.white12,
                                  filled: true,
                                  labelText: "Drink name",
                                  border: OutlineInputBorder(),
                                ),
                                //maxLength: 12,
                                textAlign: TextAlign.center,
                                onChanged: (text) {
                                  drinkName = text;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              //Drink ABV entry
                              height: 45,
                              width: 120,
                              //padding: EdgeInsets.all(20.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  fillColor: Colors.white12,
                                  filled: true,
                                  labelText: "ABV",
                                  border: OutlineInputBorder(),
                                ),
                                //maxLength: 4,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                onChanged: (text) {
                                  drinkABV = text;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              //Drink Volume entry
                              height: 45,
                              width: 120,
                              //padding: EdgeInsets.all(20.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  fillColor: Colors.white12,
                                  filled: true,
                                  labelText: "Volume (ml)",
                                  border: OutlineInputBorder(),
                                ),
                                //maxLength: 4,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                onChanged: (text) {
                                  drinkVolume = text;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  //Add drink button
                                  width: 200,
                                  height: 40,
                                  child: RaisedButton(
                                    child: Text("Add Drink"),
                                    color: const Color(0xffFEEAE6),
                                    elevation: 2.0,
                                    onPressed: () {
                                      addDrink();
                                    },
                                  ),
                                ),
                                Container(
                                  //Favorite drink button
                                  width: 40,
                                  height: 40,
                                  child: RaisedButton(
                                    padding: EdgeInsets.all(9),
                                    child: Icon(Icons.star),
                                    color: const Color(0xfff9f923),
                                    elevation: 2.0,
                                    onPressed: () {
                                      saveDrink();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Text("Swipe for favorites →",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                )),
                          ],
                        ),
                        
                      ),
                      Container(
                        //RIGHT MENU Drink List (holds preset Drinks)
                        //width: 540,
                        //height: 200,

                        child: Column(
                          children: <Widget>[
                            Text(
                              "Favorites",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                    
                                separatorBuilder: (context, index) => Divider(
                                      color: Colors.black,
                                    ),
                                shrinkWrap: true,
                                itemCount: presetDrinksList.length,
                                itemBuilder: (BuildContext ctxt, int index) {
                                  return ListTile(
                                    title: Text(presetDrinksList[index]
                                        .getPresetInfo()),
                                    onTap: () {
                                      addDrinkFromPresets(index);
                                    },
                                    onLongPress: () {
                                      presetDrinksList.removeAt(index);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ), //widgets
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';
//import 'package:async/async.dart';
import 'dart:async';
import 'dart:convert' show json;
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:carousel_pro/carousel_pro.dart';

void main() => runApp(new DrinkApp());

class Drink{ //a drink stores a name, ABV, volume, and time drank
  String name;
  double abv;
  double volume;
  DateTime time;
  String timeString;

  Drink(String nameInput, double abvInput, double volumeInput, DateTime timeInput)
  {
    name = nameInput;
    abv = abvInput;
    volume = volumeInput;
    time = timeInput;
    timeString = time.toString();
  }

  Drink.fromJson(Map<String, dynamic> m)
  {
    name = m['mName'];
    abv = m['mAbv'];
    volume = m['mVolume'];
    timeString = m['mTime'];
    print("PARSE");
    print("mtime:");
    print(m['mTime']);
    print(timeString);
    time = DateTime.parse(timeString);
    print("/PARSE");
  }

  String get mName => name;
  double get mAbv => abv;
  double get mVolume => volume;
  String get mTime => time.toString(); //convert time (type DateTime) toString() first 

  Map<String, dynamic> toJson() =>
  {
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
    double bac = (((abv * volume * .789) / (weight * genderConst))  ) - (hoursPassed * (.015 / drinksList.length));
    
    //return BAC
    return bac;
  }

  String getInfo()
  {
    return "(" + time.toString().substring(11,16) + ") $name:\n $abv% - $volume ml";
  }

  String getPresetInfo()
  {
    return "$name\n$abv% - $volume ml";
  }
}

List<Drink> drinksList = new List<Drink>(); //drinksList is a List that stores Drink objects
List<Drink> presetDrinksList = new List<Drink>(); //presetDrinksList contains saved preset drinks

String drinkName; //Stores the drinkName
String drinkABV; //Stores the drinkABV
String drinkVolume; //Stores the drinkVolume

double threshold = 0; //default threshold = bac of 0
double weight = 88450.5; //my weight in grams
double genderConst = .68; //.68 for males, .55 for females

String titleBarText = "";

DateTime soberTime = new DateTime.now();

class DrinkApp extends StatefulWidget{
  @override
  _DrinkAppState createState() => new _DrinkAppState();
}

class _DrinkAppState extends State<DrinkApp> {

  //System for keeping the timer up-to-date. Thanks Gunter from Stackoverflow.
  Timer timer;
  @override
  void initState() { //initState run on startup
    super.initState();

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

  //add custom drink to array
  void addDrink() 
  {  
    //make sure all fields are filled in
    if(drinkName == null || drinkABV == null || drinkVolume == null) 
    {
      return(null);
    }

    var now = new DateTime.now();
    var abvDouble = double.parse(drinkABV);
    var volumeDouble = double.parse(drinkVolume); 

    drinksList.add(new Drink(drinkName, abvDouble, volumeDouble, now));

    updateInfo();
  }

  //save custom drink to presets
  void saveDrink()
  {
    //make sure all fields are filled in
    if(drinkName == null || drinkABV == null || drinkVolume == null) 
    {
      return(null);
    }

    var now = new DateTime.now();
    var abvDouble = double.parse(drinkABV);
    var volumeDouble = double.parse(drinkVolume); 

    presetDrinksList.add(new Drink(drinkName, abvDouble, volumeDouble, now));
  }

  void addDrinkFromPresets(int index)
  {
    presetDrinksList[index].time = DateTime.now();

    drinksList.add(presetDrinksList[index]);
    updateInfo();
  }

  //like updateInfo
  void updateClock()
  {
   //check the timer

    //if we've already passed soberTime
    if(DateTime.now().isAfter(soberTime))
    {
      //print("WE ARE SOBER");

      //set the output
      setState(() => _outputBAC = "0%");
      setState(() => _timeString = "You're sober, mate");
      setState(() => titleBarText = "");
      setState(() => _drinksString = "");
    }
    else //if soberTime is yet to come thus we're hammered
    {
      //print("NOT SOBER");

      //set clock
      Duration dur = soberTime.difference(DateTime.now());
      setState(() => _timeString = dur.toString().substring(0,7));

      //determine the totalBAC (sum of all Drink's BACs)
      double totalBAC = 0;
      for(int i = 0; i < drinksList.length; i++)
      {
        totalBAC += drinksList[i].getBAC();
      }

      setState(() => _outputBAC = totalBAC.toStringAsFixed(3) + "%");
      if(drinksList.length == 1)
      {
        setState(() => _drinksString = "(1 drink)");
      }
      else //drinksList is greater than 1
      {
        setState(() => _drinksString = "(" + drinksList.length.toString() + " drinks)");
      }
    }

  }

  void updateInfo()
  {
    
    //determine the totalBAC (sum of all Drink's BACs)
    double totalBAC = 0;
    for(int i = 0; i < drinksList.length; i++)
    {
      totalBAC += drinksList[i].getBAC();
    }
    

    if(totalBAC > threshold) //If our BAC is greater than the threshold, print BAC information
    {
      //update the percentage immediately
      //setState(() => _outputBAC = totalBAC.toStringAsFixed(10) + "%");
      

      //update soberTime
      int mins = (((totalBAC-threshold)/.015)*60).round();
      soberTime = DateTime.now().add(Duration(minutes: mins));

      //update the title bar to display the sober time
      setState(() => titleBarText = "- " + soberTime.toString().substring(11,16));

      updateClock();
    }
    else //totalBAC is under threshold
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
  final String favoritesKey = 'com.alexisraelov.canidrive.favorites'; // maybe use your domain + appname

    void saveData() async
    {
      print("SAVING DATA");
      SharedPreferences sp = await SharedPreferences.getInstance();
      sp.setString(drinksListKey, json.encode(drinksList));

      print("FAVS");
      sp.setString(favoritesKey, json.encode(presetDrinksList));
      print("DATA SAVED");
    }

    void loadData() async
    {
      print("LOADING DATA");
      SharedPreferences sp = await SharedPreferences.getInstance();
      json
         .decode(sp.getString(drinksListKey))
         .forEach((map) => drinksList.add(new Drink.fromJson(map)));

      json
         .decode(sp.getString(favoritesKey))
         .forEach((map) => presetDrinksList.add(new Drink.fromJson(map)));

      updateInfo();
      print("DATA LOADED");
    }


  //VISUAL ASSEMBLY
  @override
  Widget build(BuildContext context) {
   return new MaterialApp(
      title: "Can I Drive?",
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Can I Drive? $titleBarText"),
          backgroundColor: Color(0xff983351), 
        ),
        drawer: Drawer(
          child: 
            ListView.separated(
              separatorBuilder: (context, index) => Divider(
                color: Colors.black,
              ),
              itemCount: drinksList.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return new Dismissible(
                  key: new Key(drinksList[index].getInfo()),
                  onDismissed: (direction){

                    //when swiped, remove the drink
                    setState(() => drinksList.removeAt(index));
                    
                    //check for updates
                    updateInfo();

                    //Scaffold.of(context).showSnackBar(
                    //  new SnackBar(
                    //    content: new Text("Drink removed"),
                    //  ),
                    //); //scaffoldofcontext
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
          
          return Container(  //MAIN CONTAINER
          alignment: Alignment.center,
          color: const Color(0xfffffbfa),
          child: Column( //Main column with data on top and menu on bottom
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[ 

              Container( //INFO CONTAINER
                child: Column(
                  children: <Widget>[
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

              Container( //MENU CONTAINER
                height: size.height/3,
                width: size.width,
                child: PageView(
                  scrollDirection: Axis.horizontal,
                  //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      //width: 540,
                      child:
                    Column( //LEFT MENU COLUMN (TEXT FIELDS AND BUTTON)
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[

                        //Text("ENTER DRINK \n"),

                        Container( //Drink name entry
                          height: 45,
                          width: 120,
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: TextField(
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: "Name",
                              border: OutlineInputBorder(),
                            ),
                            //maxLength: 12,
                            textAlign: TextAlign.center,
                            onChanged: (text){
                              drinkName = text;
                            },
                          ),
                        ),

                        Container( //Drink ABV entry
                          height: 45,
                          width: 120,
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "ABV",
                              border: OutlineInputBorder(),
                            ),
                            //maxLength: 4,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (text){
                              drinkABV = text;
                            },
                          ),
                        ),

                        Container( //Drink Volume entry
                          height: 45,
                          width: 120,
                          padding: EdgeInsets.only(bottom: 20.0),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Volume",
                              border: OutlineInputBorder(),
                            ),
                            //maxLength: 4,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            onChanged: (text){
                              drinkVolume = text;
                            },
                          ),
                        ),

                        Row(
                          
                          mainAxisAlignment: MainAxisAlignment.center,
                          
                          children: <Widget>[
                            Container( //Add drink button
                              width: 200,
                              height: 40,
                              child: RaisedButton(
                                child: Text("Add Drink"),
                                color: const Color(0xffFEEAE6),
                                elevation: 2.0,
                                onPressed: ()
                                {
                                  addDrink();
                                },
                              ),
                            ),

                            Container( //Favorite drink button
                              width: 40,
                              height: 40,
                              child: RaisedButton(
                                padding: EdgeInsets.all(9),
                                child: Icon(Icons.star),
                                color: const Color(0xfff9f923),
                                elevation: 2.0,
                                onPressed: ()
                                {
                                  saveDrink();
                                },
                              ),
                            ),

                        ],),
                        
                        Container( //A SAVE button
                              width: 200,
                              height: 40,
                              child: RaisedButton(
                                child: Text("SAVE"),
                                color: const Color(0xffFEEAE6),
                                elevation: 2.0,
                                onPressed: ()
                                {
                                  saveData();
                                },
                              ),
                            ),

                            Container( //A SAVE button
                              width: 200,
                              height: 40,
                              child: RaisedButton(
                                child: Text("LODE"),
                                color: const Color(0xffFEEAE6),
                                elevation: 2.0,
                                onPressed: ()
                                {
                                  loadData();
                                },
                              ),
                            ),

                      ],
                    ),
                    ),

                    Container(
                      //width: 540,
                      child:ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                        color: Colors.black,
                      ),
                      itemCount: presetDrinksList.length,
                      itemBuilder: (BuildContext ctxt, int index) {
                        return ListTile(
                          title: Text(presetDrinksList[index].getPresetInfo()),
                          onTap: (){
                            addDrinkFromPresets(index);
                          },

                          onLongPress: (){
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
          ), //widgets
          );
        }),
      ),
    );
  }
}
import 'package:flutter/material.dart';
//import 'package:async/async.dart';
import 'dart:async';

import 'package:flutter/rendering.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'package:carousel_pro/carousel_pro.dart';

void main() => runApp(new DrinkApp());



class Drink{ //a drink stores a name, ABV, volume, and time drank
  String name;
  double abv;
  double volume;
  DateTime time;

  Drink(String nameInput, double abvInput, double volumeInput, DateTime timeInput)
  {
    name = nameInput;
    abv = abvInput;
    volume = volumeInput;
    time = timeInput;
  }

  double getBAC() //returns the bac from this drink
  {
    //weight and genderConst were here

    //determine how many hours have passed since drinking
    var now = new DateTime.now();
    Duration diff = now.difference(time);
    double hoursPassed = diff.inMinutes / 60;
    print("hrs passed: $hoursPassed");
    //calculate BAC
    double bac = (((abv * volume * .789) / (weight * genderConst))  ) - (hoursPassed * .015);
    print(bac);
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
  void initState() {
    super.initState();
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
      print("WE ARE SOBER");

      //set the output
      setState(() => _outputBAC = "0%");
      setState(() => _timeString = "You're sober, mate");
      setState(() => titleBarText = "");
    }
    else //if soberTime is yet to come thus we're hammered
    {
      print("NOT SOBER");

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
  }

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
                    drinksList.removeAt(index);
                    
                    //check for updates
                    updateInfo();

                    Scaffold.of(context).showSnackBar(
                      new SnackBar(
                        content: new Text("Drink removed"),
                      ),
                    );
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
                        

                      ],
                    ),
                    ),

                    Container(
                      //width: 540,
                      child:ListView.builder(
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
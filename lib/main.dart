import 'package:flutter/material.dart';
//import 'package:async/async.dart';
import 'dart:async';
//import 'package:shared_preferences/shared_preferences.dart';

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

    //calculate BAC
    double bac = (((abv * volume * .789) / (weight * genderConst))  ) - (hoursPassed * .015);
    print(bac);
    return bac;
  }

  String getInfo()
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
    }
    else //if soberTime is yet to come thus we're hammered
    {
      print("NOT SOBER");

      //set clock
      Duration dur = soberTime.difference(DateTime.now());
      setState(() => _timeString = dur.toString().substring(0,7));
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
      setState(() => _outputBAC = totalBAC.toStringAsFixed(5) + "%");
      

      //update soberTime
      int mins = (((totalBAC-threshold)/.015)*60).round();
      soberTime = DateTime.now().add(Duration(minutes: mins));

      updateClock();
    }
    else //totalBAC is under threshold
    {
      //set outputBAC to empty string
      //setState(() => _outputBAC = "");
      updateClock();

      //update soberTime to now
      soberTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
   return new MaterialApp(
      title: "Can I Drive?",
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Can I Drive?"),
          backgroundColor: Color(0xffFEDBD0), 
        ),
        drawer: Drawer(
          child: ListView.builder(
            itemCount: drinksList.length,
            itemBuilder: (BuildContext ctxt, int index) {
              return new Dismissible(
                key: new Key(drinksList[index].getInfo()),
                onDismissed: (direction){
                  drinksList.removeAt(index);
                  updateInfo();
                  Scaffold.of(context).showSnackBar(
                    new SnackBar(
                      content: new Text("Item dismissed"),
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
        body: Container(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
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

                        Container( //Add drink button
                          width: 200,
                          height: 40,
                          child: RaisedButton(
                            child: Text("Add Drink"),
                            color: const Color(0xffFEEAE6),
                            elevation: 4.0,
                            onPressed: ()
                            {
                              addDrink();
                            },
                          ),
                        ),

                      ],
                    ),
               
                    Text("RIGHT MENU"), //THIS WILL BE A SCROLLVIEW
                  ],
                ),
              ),
            ],
          ), //widgets
      ),
    ),
   );
  }
}
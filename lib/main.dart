import 'package:flutter/material.dart';

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
    double weight = 452.592; //my weight in grams
    double genderConst = .68; //.55 for females
    double bac = ((abv * volume * .789) / (weight * genderConst)) / 100;
    print(bac);
    return bac;
  }

  String getInfo()
  {
    return "$name\n$abv% - $volume ml";
  }
}

List<Drink> drinksList = new List<Drink>(); //drinksList is a List that stores Drink objects

String drinkName; //Stores the drinkName
String drinkABV; //Stores the drinkABV
String drinkVolume; //Stores the drinkVolume

class DrinkApp extends StatefulWidget{
  @override
  _DrinkAppState createState() => new _DrinkAppState();
}

class _DrinkAppState extends State<DrinkApp> {

  String _outputBAC = "";
  String _timeString = "";

  void addDrink()
  {
    //add drink to array
    
    if(drinkName == null || drinkABV == null || drinkVolume == null) //make sure all fields are filled in
    {
      return(null);
    }

    var now = new DateTime.now();
    var abvDouble = double.parse(drinkABV);
    var volumeDouble = double.parse(drinkVolume); 

    drinksList.add(new Drink(drinkName, abvDouble, volumeDouble, now));

    updateInfo();
  }

  void updateInfo()
  {
    double totalBAC = 0;
    for(int i = 0; i < drinksList.length; i++)
    {
      totalBAC += drinksList[i].getBAC();
    }

    if(totalBAC > 0)
    {
      setState(() => _outputBAC = totalBAC.toStringAsFixed(3));

      String hoursTillDrive = (totalBAC/.015).toStringAsFixed(2);

      setState(() => _timeString = "You can drive in $hoursTillDrive hours!");
    }
    else //totalBac == 0
    {
      setState(() => _outputBAC = "0%");
      setState(() => _timeString = "You're sober, mate");
    }
  }

  @override
  Widget build(BuildContext context) {
   return new MaterialApp(
      title: "Can I Drive?",
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("Can I Drive?"),
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
          color: const Color(0xffFEDBD0),
          child: Column( //Main column with data on top and menu on bottom
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[ 
              Container( //INFO CONTAINER
                child: Column(
                  children: <Widget>[
                    Text(
                      "$_outputBAC%",
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

                        Text("ENTER DRINK \n"),

                        Container( //Drink name entry
                          height: 45,
                          width: 120,
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
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "ABV",
                              border: OutlineInputBorder(),
                            ),
                            maxLength: 4,
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
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Volume",
                              //border: OutlineInputBorder(),
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
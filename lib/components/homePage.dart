import 'dart:convert';
// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart' as gc;
// import 'package:geocoder/geocoder.dart';

import 'package:app3/helpers/weather.dart';
import 'package:app3/components/searchForm.dart';
import 'package:app3/components/weatherCard.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

//TODO отображение процесса получения геолокации
//TODO отображение процесса получения погоды
//TODO отображение ошибок  получения геолокации
//TODO отображение ошибок получения погоды
//TODO выводить больше информации о месте погоды (страна, координаты)
//TODO возможность запросить погоду по текущим координатам

class _HomePageState extends State<HomePage> {
  final Geolocator _geo = Geolocator()..forceAndroidLocationManager;
  Position _position;
  String _city;
  int _temp;
  String _icon;
  String _desc;
  Color _color;
  WeatherFetch _weatherFetch = new WeatherFetch();

  @override
  void initState() {
    _city = "test";
    _temp = 0;
    _icon = "04n";
    _color = Colors.white;
    super.initState();
    _getCurrent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Search(parentCallback: _changeCity),
                  Text(
                    _city,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'OpenSans'),
                  ),
                  if (_city != "")
                    WeatherCard(
                      feel: _desc,
                      temperature: _temp,
                      iconCode: _icon,
                    )
                ])),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, 1.0],
                    colors: [_color, Colors.white]))));
  }

  /* Render data */
  void updateData(weatherData) {
    debugPrint('###weatherData ' + jsonEncode(weatherData));
    setState(() {
      if (weatherData != null) {
        //{"temp":10.49,"feels_like":5.54,"temp_min":10,"temp_max":11,"pressure":1009,"humidity":61}
        _temp = weatherData['main']['temp'].toInt();
        _icon = weatherData['weather'][0]['icon'];
        _desc = weatherData['main']['feels_like'].toString();
        _color = _getBackgroudColor(_temp);
      } else {
        _temp = 0;
        _city = "In the middle of nowhere";
        _icon = "04n";
      }
    });
  }

  _getCurrent() {
    _geo
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      debugPrint('###position ' + position.toString());
      setState(() {
        _position = position;
      });
      _getCityAndWeather();
    }).catchError((e) {
      print('### ошибка получения позиции: ' + e);
    });
  }

  _getCityAndWeather() async {
    try {
      //get place name
      List<Placemark> p = await _geo.placemarkFromCoordinates(
          _position.latitude, _position.longitude);
      Placemark place = p[0];
      debugPrint('###place ' + jsonEncode(place));

      //get weather info
      var dataDecoded = await _weatherFetch.getWeatherByCoord(
          _position.latitude, _position.longitude);
      updateData(dataDecoded);
      setState(() {
        _city = "${place.locality}";
      });
    } catch (e) {
      print('### ошибка получения погоды по координатам: ' + e);
    }
  }

  _getBackgroudColor(temp) {
    if (temp > 25) return Colors.orange;
    if (temp > 15) return Colors.yellow;
    if (temp <= 0) return Colors.blue;
    return Colors.green;
  }

  _changeCity(city) async {
    debugPrint('###city ' + city);
    try {
      //get weather info
      var dataDecoded = await _weatherFetch.getWeatherByName(city);
      updateData(dataDecoded);
      setState(() {
        _city = city;
      });
    } catch (e) {
      print('### ошибка получения погоды по городу: ' + e);
    }
  }
}

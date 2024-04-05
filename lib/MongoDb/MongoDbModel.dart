import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';

MyData MyDataFromJson(String str) => MyData.fromJson(json.decode(str));

String MyDataToJson(MyData data) => jsonEncode(data.toJson());

class MyData {
  final ObjectId id;
  final String order;
  final String location;
  final double LAT;
  final double LNG;
  final String audioUrl;

  MyData({required this.order , required this.location, required this.LAT , required this.LNG , required this.audioUrl , required this.id});

  // Factory method to create a MyData instance from a Map (usually from JSON data)
  factory MyData.fromJson(Map<String, dynamic> json) =>
     MyData(
       id:json["_id"],
      order : json['Order'],
      location : json['Location'],
      LAT : json['LAT'],
      LNG : json['LNG'],
       audioUrl: json['Audio file']
    );

  Map<String , dynamic> toJson()=>{
    "_id":id,
    "order" : order,
    "location" : location,
    "LAT" : LAT,
    "LNG" : LNG,
    "audioUrl" : audioUrl
  };

  }




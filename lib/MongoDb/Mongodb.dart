import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart';

import 'constants.dart';


class MongoDatabase {

  static var db , userCollection , AccCollection , RejCollection , DelCollection;

  static connect() async {

    db = await Db.create(MONGO_URL);
    await db.open();
    userCollection = db.collection(COLLECTION_NAME);
    AccCollection = db.collection(acceptedCollection);
    RejCollection = db.collection(rejectedCollection);
    DelCollection = db.collection(deliveredCollection);

    inspect(db);
    // ignore: unused_local_variable
    var status = db.serverStatus();

    // var collection = db.collection(COLLECTION_NAME);
    // print(await collection.find().toList());


    // var document = {
    //   "_id": ObjectId(),  // Create a new ObjectId
    //   "name": "John",
    //   // ... other fields
    // };
    //
    // collection.insertOne(document);
    //
    // print(collection.findOne({"name":"John"}));
    //
    // print("done");

  }

  // static Future<String> _insert (Map<String , String> mp) async {
  //
  //   try{
  //     var result = await userCollection.insertOne(mp.toJS);
  //     if(result.isSuccess){
  //       return "Data Inserted";
  //     }else {
  //       return "Something Wrong ";
  //     }
  //   }catch(e){
  //     print("---------------------");
  //     print(e.toString());
  //   }
  //
  // }

  static Future<List<Map<String , dynamic>>> getData() async {
    final arrData = await userCollection.find().toList();
    return arrData;
  }

  static Future<List<Map<String , dynamic>>> getAcceptedData() async {
    final arrData = await AccCollection.find().toList();
    return arrData;
  }

  static Future<List<Map<String , dynamic>>> getRejectedData() async {
    final arrData = await RejCollection.find().toList();
    return arrData;
  }

  static Future<List<Map<String , dynamic>>> getDeliveredData() async {
    final arrData = await DelCollection.find().toList();
    return arrData;
  }

}
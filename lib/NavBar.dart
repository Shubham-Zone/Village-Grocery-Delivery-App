import 'package:flutter/material.dart';
import 'package:flutter_projects/AboutUs/About_Us.dart';
import 'package:flutter_projects/AboutUs/ContactUs.dart';
import 'package:flutter_projects/AboutUs/FollowUS.dart';
import 'package:flutter_projects/FoodStatus.dart';
import 'package:flutter_projects/fetchLocation.dart';
import 'package:flutter_projects/main.dart';
import 'getlocation.dart';



class NavBar extends StatefulWidget {
  final int idx;
  const NavBar(this.idx , {Key? key}) : super(key: key);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {

  late int index;

  // Define a list of page widgets.
  List pages = [
    const MyHomePage(title: "T&T"),
    const FoodStatus(),
    const AboutUsPage(),
    const FollowUsPage(),
    // const ContactUsPage(),

    // const CurrentLoc()
    // const LocationWidget(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the index with the provided 'idx'.
    index = widget.idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBarTheme(
        data:  const NavigationBarThemeData(
          indicatorColor: Colors.green,
        ),
        child: NavigationBar(
          selectedIndex: index,
          elevation: 8,
          height: MediaQuery.of(context).size.height * 0.085,
          onDestinationSelected: (index)=>
          setState(() => this.index = index),
          destinations: const[
            NavigationDestination(
                icon: Icon(Icons.home),
                label: "Home"
            ),
            NavigationDestination(
                icon: Icon(Icons.timer),
                label: "Track order"
            ),
            NavigationDestination(
                icon: Icon(Icons.computer),
                label: "About us"
            ),
            NavigationDestination(
                icon: Icon(Icons.person),
                label: "Follow"
            ),
            // NavigationDestination(
            //     icon: Icon(Icons.contact_page),
            //     label: "Contact"
            // ),
          ],
        ),
      ),
    );
  }
}

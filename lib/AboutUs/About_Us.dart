import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {

  late DatabaseReference myImg;
  String imgUrl="";

  @override
  void initState() {
    myImg=FirebaseDatabase.instance.ref("DeveloperDetails");
    myImg.onValue.listen((DatabaseEvent event) {
      setState(() {
        imgUrl=event.snapshot.child("img").value.toString();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  'Our Story',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "🌾 Serving Undeveloped Areas 🏡\n\n"
                        "🛒 Simplify Ordering - No Typing!\n"
                        "✅ Access Essential Goods Easily\n"
                        "🚚 Convenience at Your Doorstep\n\n"
                        "Join Us in Bringing Simplicity to Your Village!",
                    textAlign: TextAlign.center, // Center align the text
                    style: TextStyle(fontSize: 18),
                  ),

                ),
                const SizedBox(height: 20),
                const Text(
                  'Developer',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children:  [
                      CachedNetworkImage(
                        imageUrl: imgUrl,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Meet Our Developer\n"
                            "------------------\n"
                            "👨‍💻 Shubham Kumar\n"
                            "🎓 BSc (Hons) in Computer Science, DU\n"
                            "📚 Pursuing MCA at YMCA, Faridabad\n"
                            "🌐 Cross Platform Developer\n\n"
                            "Passionate about technology and dedicated to making your experience exceptional.",
                        textAlign: TextAlign.center, // Center align the text
                        style: TextStyle(fontSize: 18),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Contact Us',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'If you have any questions or feedback, please feel free to reach out to us at shubhamanuj652@gmail.com',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

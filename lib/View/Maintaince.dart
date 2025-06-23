import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class Maintenance extends StatelessWidget {
  const Maintenance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width:MediaQuery.of(context).size.width*0.5,
          height: MediaQuery.of(context).size.height*0.2,
          child: Marquee(
            text: "⚒️ Under Maintenance ⚒️  🙏 Thank You For Visit 🙏  🚧 Will Be Back Soon 🚧",
            style: TextStyle(fontSize: 20,color: Colors.black,fontStyle: FontStyle.italic,fontWeight: FontWeight.bold),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            velocity: 100.0,
            pauseAfterRound: Duration(seconds: 1),
            startPadding: 10.0,
            accelerationDuration: Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        ),
      ),
    );
  }
}

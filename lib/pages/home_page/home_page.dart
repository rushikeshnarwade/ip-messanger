import 'package:flutter/material.dart';
import 'package:ip_messanger/pages/home_page/widgets/drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  @override
  void initState() {
    super.initState();
    // getInteractions();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('IP Messanger')),
      body: ListView.builder(itemBuilder: (BuildContext context, int index) {
        
      }),
      drawer: HomePageDrawer(),
    );
  }
}

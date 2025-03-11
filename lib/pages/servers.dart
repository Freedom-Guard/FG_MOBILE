import 'package:flutter/material.dart';

class ServersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("سرورها")),
      body: Center(child: Text("صفحه سرورها", style: TextStyle(fontSize: 20))),
    );
  }
}

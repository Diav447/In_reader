import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List items = [];
  bool loading = false;
  String err = "";
  final ctrl = TextEditingController(text: "Naruto");

  @override
  void initState() { super.initState(); load("Naruto"); }

  Future<void> load(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    setState(() { loading = true; err = ""; });
    try {
      final uri = Uri.parse("https://api.jikan.moe/v4/anime?q=$q&limit=20&sfw=true");
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() { items = data["data"]; loading = false; });
      } else {
        setState(() { loading = false; err = "HTTP ${res.statusCode}"; });
      }
    } catch (e) {
      setState(() { loading = false; err = "$e"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jikan Search"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: ctrl, onSubmitted: load, decoration: const InputDecoration(hintText: "One Piece", border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => load(ctrl.text), child: const Text("Go")),
              ],
            ),
          ),
          if (err.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(err, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: loading? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final a = items[i];
                  final img = a["images"]?["jpg"]?["large_image_url"]?? "";
                  return Card(child: Column(children: [Expanded(child: Image.network(img, fit: BoxFit.cover, width: double.infinity)), Padding(padding: const EdgeInsets.all(6), child: Text(a["title"]??"", maxLines: 2, overflow: TextOverflow.ellipsis))]));
                },
              ),
          ),
        ],
      ),
    );
  }
}

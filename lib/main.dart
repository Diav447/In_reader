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
      title: 'Jikan Anime',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const AnimeHome(),
    );
  }
}

class AnimeHome extends StatefulWidget {
  const AnimeHome({super.key});
  @override
  State<AnimeHome> createState() => _AnimeHomeState();
}

class _AnimeHomeState extends State<AnimeHome> {
  List animeList = [];
  bool loading = false;
  String errorMsg = "";
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAnime("Naruto");
  }

  Future<void> fetchAnime(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() { loading = true; errorMsg = ""; animeList = []; });

    final url = Uri.parse('https://api.jikan.moe/v4/anime?q=$query&limit=20&sfw=true&order_by=popularity&sort=desc');
    try {
      // retry logic for 429
      http.Response? res;
      for (int i = 0; i < 3; i++) {
        res = await http.get(url, headers: {'User-Agent': 'ln_reader'}).timeout(const Duration(seconds: 15));
        if (res.statusCode!= 429) break;
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }

      if (res == null) throw Exception("No response");

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          animeList = data['data']?? [];
          loading = false;
          if (animeList.isEmpty) errorMsg = "Gak ketemu anime '$query' bro";
        });
      } else if (res.statusCode == 429) {
        setState(() { loading = false; errorMsg = "Jikan lagi rate limit (429), tunggu 5 detik terus search lagi"; });
      } else {
        setState(() { loading = false; errorMsg = "Error ${res!.statusCode}: ${res.body.substring(0, 100)}"; });
      }
    } catch (e) {
      setState(() { loading = false; errorMsg = "Gagal nyambung: $e\nCek internet / coba VPN"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(title: const Text("Jikan Anime Search", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.deepPurple[200], centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onSubmitted: (v) => fetchAnime(v),
              decoration: InputDecoration(
                hintText: "Cari anime... ex: One Piece",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: () => fetchAnime(searchCtrl.text)),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (errorMsg.isNotEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(errorMsg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          Expanded(
            child: loading? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text("Lagi ngambil dari Jikan...")]))
                : animeList.isEmpty && errorMsg.isEmpty? const Center(child: Text("Ketik judul anime di atas"))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: animeList.length,
                    itemBuilder: (c, i) {
                      final a = animeList[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(anime: a))),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,4))]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(18)), child: Image.network(a['images']?['jpg']?['large_image_url']?? a['images']?['jpg']?['image_url']?? '', height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey[300], child: const Icon(Icons.broken_image)))),
                            Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a['title']?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), const SizedBox(width: 4), Text("${a['score']?? '-'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), const Spacer(), Text("${a['episodes']?? '?'} eps", style: TextStyle(fontSize: 10, color: Colors.grey[600]))]),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final dynamic anime;
  const DetailPage({super.key, required this.anime});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anime['title']?? 'Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(anime['images']['jpg']['large_image_url']))),
          ),
          const SizedBox(height: 16),
          Text(anime['title']?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [Chip(label: Text("⭐ ${anime['score']?? '-'}")), Chip(label: Text(anime['status']?? '')), Chip(label: Text(anime['year']?.toString()?? anime['season']?? ''))]),
          const SizedBox(height: 16),
          const Text("Sinopsis:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(anime['synopsis']?? 'No synopsis', style: const TextStyle(height: 1.5)),
        ]),
      ),
    );
  }
}

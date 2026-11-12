/// main.dart
/// GIF Finder: searches GIPHY and shows the results.
/// Saadet Tutumlu
/// 11/11/26
///

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Paste your own key from developers.giphy.com here.
const String apiKey = "SY1HR22wwSUZGZ9tBYZz3CcyZi5P0pKE";

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController searchController = TextEditingController();

  // Strings, not ints, because they go straight into the URL.
  List<String> limitList = ["10", "25", "50"];
  String? selectedLimit = "25";
  List<Map<String, dynamic>> gifList = [];
  String statusText = "Type something and press Search.";

  /// Deletes memory when screen is gone to prevent leaks
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Builds the search URL, calls GIPHY, and keeps only the title and image URL of each GIF.
  Future<void> searchGifs() async {
    
    // encodeComponent makes spaces and symbols URL-safe, so "funny cat" works.
    String term = Uri.encodeComponent(searchController.text.trim());
    
    // Checks for empty searches, resets gifs if so
    if(term == ""){
      setState(() {
        statusText = "Please enter a search term first!";
        gifList = [];
      });
      return;
    }

    String url =
        "https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=$term&limit=$selectedLimit";
    debugPrint(url);

    // returns relevent gifs, status, and catches errors if need be
    try{
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        debugPrint("Status 200: It worked!");
        
        var jsonResponse = jsonDecode(response.body);
        List<Map<String, dynamic>> cleanedGifs = [];
        
        for (final gif in jsonResponse['data']) {
          cleanedGifs.add({
            'title': gif['title'],
            // The downsampled version: 25 full-size GIFs is ~40 MB, these are ~2 MB total.
            'imageUrl': gif['images']['fixed_width_downsampled']['url'],
          });
        }
        //debugPrint(cleanedGifs[0].toString());
        
        setState(() {
          gifList = cleanedGifs;
          statusText =
              "Found ${gifList.length} GIFs for \"${searchController.text}\"";
        });
      } 
      else {
        setState(() {
          statusText = "Error ${response.statusCode}. Check your API key.";
        });
      }
    }catch (err){
      debugPrint("Error: $err");
      setState(() {
        statusText = "Something went wrong. Check your internet connection.";
      });
    }
  }
  
  /// Draws on screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GIF Finder"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search for GIFs",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text("Results:"),
                SizedBox(width: 8),
                DropdownButton(
                  value: selectedLimit,
                  items: limitList.map((String item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLimit = value;
                    });
                  },
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint("Search btn pressed");
                    // Hide the keyboard so it isn't covering the results.
                    FocusManager.instance.primaryFocus?.unfocus();
                    await searchGifs();
                  },
                  child: Text("Search"),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(statusText),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: gifList.length,
                itemBuilder: (context, index) {
                  return GridTile(
                    footer: Container(
                      color: const Color.fromARGB(158, 15, 15, 15),
                      padding: EdgeInsets.all(2),
                      child: Text(
                        gifList[index]['title'],
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    child: Image.network(
                      gifList[index]['imageUrl'],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              )
            )
          ],
        ),
      ),
    );
  }
}
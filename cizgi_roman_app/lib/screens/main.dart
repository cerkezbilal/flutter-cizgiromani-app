import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cizgi_roman_app/model/comic.dart';
import 'package:cizgi_roman_app/screens/chapter_screen.dart';
import 'package:cizgi_roman_app/state/state_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_typeahead/cupertino_flutter_typeahead.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:convert';

import '../model/comic.dart';
import 'read_screen.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final FirebaseApp app = await Firebase.initializeApp(
    name: 'cizgi_roman_flutter',
    options: Platform.isMacOS || Platform.isIOS ?
        FirebaseOptions(
          appId: 'IOS KEY',
          apiKey: 'AIzaSyDusGhTmEwecgZwUOMkkZFHal3a-z5Je8k',
          projectId: 'cizgiromanapp',
          messagingSenderId: '343136096379',

        )
        : FirebaseOptions(
            appId: '1:343136096379:android:8e197c28ff706f287b12de',
            apiKey: 'AIzaSyDusGhTmEwecgZwUOMkkZFHal3a-z5Je8k',
            projectId: 'cizgiromanapp',
            messagingSenderId: '343136096379',

    )
  );
  runApp(ProviderScope(child: MyApp(app: app)));
}

class MyApp extends StatelessWidget {
 FirebaseApp app;
 MyApp({this.app});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      routes: {
        "/chapters":(context)=>ChapterScreen(),
        "/read":(context)=>ReadScreen()
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        primarySwatch: Colors.blue,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Çizgi Roman Uygulaması', app: app,),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key,this.app, this.title}) : super(key: key);


  final String title;
  final FirebaseApp app;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DatabaseReference _bannerRef,_comicRef;
  List<Comic> listComicFromFirebase = new List<Comic>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final FirebaseDatabase _database = FirebaseDatabase(app: widget.app);
    _bannerRef = _database.reference().child('Banners');
    _comicRef = _database.reference().child('Comic');

  }


  @override
  Widget build(BuildContext context) {

    return Consumer(
      builder: (context,watch,_){
        var searchEnable = watch(isSearch).state;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFFF44A3E),
            title:searchEnable ? TypeAheadField(
                textFieldConfiguration: TextFieldConfiguration(
                  decoration: InputDecoration(
                    hintText: 'Roman Adı veya kategori girin',
                    hintStyle: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  autofocus: false,
                  style: DefaultTextStyle.of(context).style
                    .copyWith(fontStyle: FontStyle.italic,
                  fontSize: 18,
                    color: Colors.white),
                ),
                suggestionsCallback: (searchString) async {
                  return await searchComic(searchString);
                },
                itemBuilder: (context, comic){
                  return ListTile(
                    leading: Image.network(comic.image),
                    title: Text('${comic.name}'),
                    subtitle: Text('${comic.category == null ? '':comic.category}'),
                  );
                },
                onSuggestionSelected: (comic){
                  context.read(comicSelected).state = comic;
                  Navigator.pushNamed(context, '/chapters');
                }):
            Text(widget.title, style: TextStyle(
              color: Colors.white,
            ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: ()=>context.read(isSearch).state = !context.read(isSearch).state,
              ),
            ],
          ),
          body: FutureBuilder<List<String>>(
            future: getBanners(_bannerRef),
            builder: (context,snapshot){
              if(snapshot.hasData)
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CarouselSlider(
                        items: snapshot.data.map((e) => Builder(
                            builder: (context){
                              return Image.network(e,fit: BoxFit.cover,);
                            }
                        )).toList(),
                        options: CarouselOptions(
                            autoPlay: true,
                            enlargeCenterPage: true,
                            viewportFraction: 1,
                            initialPage: 0,
                            height: MediaQuery.of(context).size.height/3
                        ) ),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(color: Color(0xFFF44A3E),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("Yeni Çizgi Roman",style: TextStyle(
                                color: Colors.white,
                              ),),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Colors.black,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(''),
                            ),
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder(
                        future: getComic(_comicRef),
                        builder:(context,snapshot){
                          if(snapshot.hasError){
                            return Center(
                              child: Text('${snapshot.error}'),
                            );
                          }else if(snapshot.hasData){
                            listComicFromFirebase = new List<Comic>();
                            snapshot.data.forEach((item) {
                              var comic = Comic.fromJson(json.decode(json.encode(item)));
                              listComicFromFirebase.add(comic);
                            });

                            return Expanded(
                              child: GridView.count(
                                crossAxisCount:2,
                                childAspectRatio: 0.8,
                                padding: EdgeInsets.all(4.0),
                                mainAxisSpacing:1.0 ,
                                crossAxisSpacing: 1.0,
                                children:  listComicFromFirebase.map((comic){
                                  return GestureDetector(
                                    onTap: (){

                                      context.read(comicSelected).state = comic;
                                      Navigator.pushNamed(context, "/chapters");

                                    },
                                    child: Card(
                                      elevation: 12,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(comic.image, fit: BoxFit.cover,),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );

                          }
                          return Center(child: CircularProgressIndicator(),);
                        }),
                  ],
                );
              else if(snapshot.hasError)
                return Center(child: Text('${snapshot.error}'),);

              return Center(
                child: CircularProgressIndicator(),
              );

            },
          ),

        );
      },
    );
  }

  Future<List<String>>getBanners(DatabaseReference bannerRef) {
    return bannerRef.once().then((snapshot) => snapshot.value.cast<String>().toList());
  }

  Future<List<dynamic>> getComic(DatabaseReference comicRef) {
    return comicRef.once().then((snapshot) => snapshot.value);
  }

 Future<List<Comic>> searchComic(String searchString) async{
    return  listComicFromFirebase.where((comic) =>
        comic.name.toLowerCase().contains(searchString.toLowerCase())//İsime göre arama
      ||
            (comic.category != null && comic.category.toLowerCase().contains(searchString.toLowerCase()))//Kategoriye göre arama
    ).toList();
 }
}

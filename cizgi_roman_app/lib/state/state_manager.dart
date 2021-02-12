import 'package:cizgi_roman_app/model/chapters.dart';
import 'package:cizgi_roman_app/model/comic.dart';
import 'package:flutter_riverpod/all.dart';

final comicSelected = StateProvider((ref)=>Comic());
final chapterSelected = StateProvider((ref) =>Chapters());
final isSearch = StateProvider((ref)=>false);

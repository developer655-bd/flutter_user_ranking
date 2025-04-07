import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_user_ranking/firebase_options.dart';
import 'package:provider/provider.dart';

import 'manager.dart';
import 'ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final rankingManager = RankingManager();
  await rankingManager.initialize();

  // Set the current user (in a real app, this would come from authentication)
  const currentUserId = 'user123';
  rankingManager.currentUserId = currentUserId;

  // Register user if needed (you'd normally do this after login)
  await rankingManager.registerUser(
    currentUserId,
    'John Smith',
    'https://placekitten.com/200/200',
  );

  runApp(
    ChangeNotifierProvider.value(value: rankingManager, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Rating App', home: const RankingDashboard());
  }
}

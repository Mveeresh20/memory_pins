import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/firebase_options.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/models/map_cordinates.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Pages/create_tapu_screen.dart';
import 'package:memory_pins_app/presentation/Pages/edit_profile_page.dart';

import 'package:memory_pins_app/presentation/Pages/home_screen.dart';
import 'package:memory_pins_app/presentation/Pages/map_view_screen.dart';
import 'package:memory_pins_app/presentation/Pages/my_pins_screen.dart';
import 'package:memory_pins_app/presentation/Pages/my_tapu_screen.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding1.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding2.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding3.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/presentation/Pages/profile_page.dart';
import 'package:memory_pins_app/presentation/Pages/saved_pins.dart';
import 'package:memory_pins_app/presentation/Pages/sign_up_page.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_detail_screen.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_pins.dart';

import 'package:memory_pins_app/services/hive_service.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Initialize Hive using our service
    await HiveService.init();

    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    // You might want to show an error screen here
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final dummyTapu = Tapus(
      id: 'johns_tapu', // IMPORTANT: This ID must match the one checked in _getDummyAttachmentsForTapu
      name: "John's Tapu", // Matches the screenshot's name
      avatarUrl: Images.profileImg, // Example profile image for the top right
      centerPinImageUrl:
          Images.aeroplaneImg, // The large central image for John's Tapu
      centerCoordinates: MapCoordinates(
          latitude: 0.0,
          longitude:
              0.0), // Keep 0,0 if the detail map is relative to center. The attachment coords will spread out.
      totalPins: 4, // Matches the screenshot's "4 Pins"
    );

    final dummyPinDetail = PinDetail(
      title: 'The Rainy Day Café',
      description:
          'I sat here for hours, listening to the rain and watching strangers rush by. That chai latte warmed more than just my hands. It was the first time in weeks I felt truly still. Maybe healing begins with little pauses like this. I hope this moment finds someone who needs it.',
      audios: [
        AudioItem(
            audioUrl: 'https://example.com/audio1.mp3', duration: '15:31'),
        AudioItem(
            audioUrl: 'https://example.com/audio2.mp3', duration: '05:15'),
      ],
      photos: [
        PhotoItem(imageUrl: Images.childUmbrella),
        PhotoItem(imageUrl: Images.childUmbrella),
        PhotoItem(imageUrl: Images.childUmbrella),
        PhotoItem(imageUrl: Images.childUmbrella),
      ],
    );
    return MultiProvider(
      providers: [
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider<PinProvider>(
          create: (_) => PinProvider(),
        ),
        ChangeNotifierProvider<TapuProvider>(
          create: (_) => TapuProvider(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Memory Pins',
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: '/onboarding1',
        routes: {
          '/home': (context) => HomeScreen(),
          '/edit-profile': (context) => EditProfilePage(),
          '/create-pin': (context) => CreatePinScreen(),
          '/my-pins': (context) => MyPinsScreen(),
          '/profile': (context) => ProfilePage(),
          '/create-tapu': (context) => CreateTapuScreen(),
          '/tapu-pins': (context) => TapuPins(),
          '/login': (context) => LoginPage(),
          '/signup': (context) => SignUpPage(),
          '/my-tapu': (context) => MyTapusScreen(),
          '/tapu-detail': (context) => TapuDetailScreen(tapu: dummyTapu),
          '/pin-detail': (context) =>
              PinDetailScreen(pinDetail: dummyPinDetail),
          '/onboarding1': (context) => Onboarding1(),
          '/onboarding3': (context) => Onboarding3(),
          '/saved-pins': (context) => SavedPins(),
          '/onboarding2': (context) => Onboarding2(),
          '/map-view': (context) => MapViewScreen(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),

        home: Onboarding1(),

        // home: PinDetailScreen(pinDetail: dummyPinDetail),

        // home:TapuDetailScreen(tapu: dummyTapu),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => MovieProvider()),
//       ],
//       child: const MovieApp(),
//     ),
//   );
// }

// class MovieApp extends StatelessWidget {
//   const MovieApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Movie App',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: Colors.red,
//         scaffoldBackgroundColor: Colors.black,
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

// class MovieProvider extends ChangeNotifier {
//   final List<dynamic> _movies = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//   int _currentPage = 1;
//   bool _hasMorePages = true;

//   List<dynamic> get movies => _movies;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   Future<void> fetchMovies({bool refresh = false}) async {
//     if (refresh) {
//       _currentPage = 1;
//       _hasMorePages = true;
//       _movies.clear();
//     }

//     if (!_hasMorePages) return;

//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedData = prefs.getString('cached_movies_$_currentPage');

//       if (cachedData != null && !refresh) {
//         _movies.addAll(json.decode(cachedData));
//         _currentPage++;
//       } else {
//         final response = await http.get(
//           Uri.parse('https://api.tvmaze.com/shows?page=$_currentPage'),
//         );

//         if (response.statusCode == 200) {
//           final newMovies = json.decode(response.body);
//           if (newMovies.isEmpty) {
//             _hasMorePages = false;
//           } else {
//             _movies.addAll(newMovies);
//             await prefs.setString('cached_movies_$_currentPage', response.body);
//             _currentPage++;
//           }
//         } else {
//           throw Exception('Failed to load movies');
//         }
//       }

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = 'An error occurred. Please try again later.';
//       notifyListeners();
//     }
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

//     _controller.forward();

//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: FadeTransition(
//           opacity: _animation,
//           child: Image.asset('assets/splash_image.png'),
//         ),
//       ),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<MovieProvider>(context, listen: false).fetchMovies();
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
//       Provider.of<MovieProvider>(context, listen: false).fetchMovies();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Netflix'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const SearchScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<MovieProvider>(
//         builder: (context, movieProvider, child) {
//           if (movieProvider.errorMessage.isNotEmpty) {
//             return Center(child: Text(movieProvider.errorMessage));
//           }

//           return RefreshIndicator(
//             onRefresh: () => movieProvider.fetchMovies(refresh: true),
//             child: GridView.builder(
//               controller: _scrollController,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 0.7,
//               ),
//               itemCount: movieProvider.movies.length + (movieProvider.isLoading ? 1 : 0),
//               itemBuilder: (context, index) {
//                 if (index == movieProvider.movies.length) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final movie = movieProvider.movies[index];
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => DetailsScreen(movie: movie),
//                       ),
//                     );
//                   },
//                   child: Card(
//                     child: Column(
//                       children: [
//                         Hero(
//                           tag: 'movie-${movie['id']}',
//                           child: Image.network(
//                             movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                             fit: BoxFit.cover,
//                             height: 200,
//                             errorBuilder: (context, error, stackTrace) {
//                               return Image.asset('assets/placeholder_image.png', height: 200);
//                             },
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text(
//                             movie['name'],
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   List<dynamic> searchResults = [];
//   bool isLoading = false;
//   String errorMessage = '';
//   Timer? _debounce;

//   Future<void> searchMovies(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//         isLoading = false;
//         errorMessage = '';
//       });
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
//       if (response.statusCode == 200) {
//         setState(() {
//           searchResults = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to search movies');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'An error occurred. Please try again.';
//       });
//     }
//   }

//   void _onSearchChanged(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       searchMovies(query);
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           style: const TextStyle(color: Colors.white),
//           decoration: const InputDecoration(
//             hintText: 'Search for a movie...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//           ),
//           onChanged: _onSearchChanged,
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//               ? Center(child: Text(errorMessage))
//               : ListView.builder(
//                   itemCount: searchResults.length,
//                   itemBuilder: (context, index) {
//                     final movie = searchResults[index]['show'];
//                     return ListTile(
//                       leading: Image.network(
//                         movie['image']?['medium'] ?? 'https://via.placeholder.com/50x70',
//                         width: 50,
//                         height: 70,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Image.asset('assets/placeholder_image.png', width: 50, height: 70);
//                         },
//                       ),
//                       title: Text(movie['name']),
//                       subtitle: Text(movie['summary'] ?? ''),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => DetailsScreen(movie: movie),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//     );
//   }
// }

// class DetailsScreen extends StatelessWidget {
//   final dynamic movie;

//   const DetailsScreen({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 300.0,
//             floating: false,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(movie['name']),
//               background: Hero(
//                 tag: 'movie-${movie['id']}',
//                 child: Image.network(
//                   movie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) {
//                     return Image.asset('assets/placeholder_image.png', fit: BoxFit.cover);
//                   },
//                 ),
//               ),
//             ),
//           ),
//           SliverList(
//             delegate: SliverChildListDelegate([
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       movie['name'],
//                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(movie['summary'] ?? 'No summary available.'),
//                     const SizedBox(height: 16),
//                     Text('Genre: ${movie['genres']?.join(', ') ?? 'N/A'}'),
//                     Text('Status: ${movie['status'] ?? 'N/A'}'),
//                     Text('Rating: ${movie['rating']?['average'] ?? 'N/A'}'),
//                   ],
//                 ),
//               ),
//             ]),
//           ),
//         ],
//       ),
//     );
//   }
// }




















// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => MovieProvider()),
//       ],
//       child: const NetflixCloneApp(),
//     ),
//   );
// }

// class NetflixCloneApp extends StatelessWidget {
//   const NetflixCloneApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Netflix Clone',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: Colors.red,
//         scaffoldBackgroundColor: Colors.black,
//         appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
//       ),
//       home: const SplashScreen(),
//     );
//   }
// }

// class MovieProvider extends ChangeNotifier {
//   final List<dynamic> _movies = [];
//   final List<dynamic> _trendingMovies = [];
//   final List<dynamic> _topRatedMovies = [];
//   List<dynamic> _previews = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//   int _currentPage = 1;
//   bool _hasMorePages = true;

//   List<dynamic> get movies => _movies;
//   List<dynamic> get trendingMovies => _trendingMovies;
//   List<dynamic> get topRatedMovies => _topRatedMovies;
//   List<dynamic> get previews => _previews;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   Future<void> fetchMovies({bool refresh = false}) async {
//     if (refresh) {
//       _currentPage = 1;
//       _hasMorePages = true;
//       _movies.clear();
//       _trendingMovies.clear();
//       _topRatedMovies.clear();
//     }

//     if (!_hasMorePages) return;

//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedData = prefs.getString('cached_movies_$_currentPage');

//       if (cachedData != null && !refresh) {
//         _movies.addAll(json.decode(cachedData));
//         _currentPage++;
//       } else {
//         final response = await http.get(
//           Uri.parse('https://api.tvmaze.com/shows?page=$_currentPage'),
//         );

//         if (response.statusCode == 200) {
//           final newMovies = json.decode(response.body);
//           if (newMovies.isEmpty) {
//             _hasMorePages = false;
//           } else {
//             _movies.addAll(newMovies);
//             await prefs.setString('cached_movies_$_currentPage', response.body);
//             _currentPage++;
//           }
//           _trendingMovies.addAll(newMovies.take(10));
//           _topRatedMovies.addAll(newMovies.reversed.take(10));
//         } else {
//           throw Exception('Failed to load movies');
//         }
//       }

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = 'An error occurred. Please try again later.';
//       notifyListeners();
//     }
//   }

//   Future<void> fetchPreviews() async {
//     try {
//       final response = await http.get(Uri.parse('https://api.tvmaze.com/shows'));
//       if (response.statusCode == 200) {
//         _previews = (json.decode(response.body) as List).take(10).toList();
//         notifyListeners();
//       } else {
//         throw Exception('Failed to load previews');
//       }
//     } catch (e) {
//       print('Error fetching previews: $e');
//     }
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

//     _controller.forward();

//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: FadeTransition(
//           opacity: _animation,
//           child: Image.asset('assets/netflix_logo.png', width: 200),
//         ),
//       ),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final movieProvider = Provider.of<MovieProvider>(context, listen: false);
//       movieProvider.fetchMovies();
//       movieProvider.fetchPreviews();
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
//       Provider.of<MovieProvider>(context, listen: false).fetchMovies();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverAppBar(
//             floating: true,
//             backgroundColor: Colors.transparent,
//             leading: Image.asset('assets/netflix_icon.png', width: 30),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.cast),
//                 onPressed: () {},
//               ),
//               IconButton(
//                 icon: const Icon(Icons.search),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const SearchScreen()),
//                   );
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.person),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//           SliverList(
//             delegate: SliverChildListDelegate([
//               const FeaturedContent(),
//               const PreviewList(),
//               MovieList(title: 'Trending Now', movieSelector: (provider) => provider.trendingMovies),
//               MovieList(title: 'Top Rated', movieSelector: (provider) => provider.topRatedMovies),
//               MovieList(title: 'Popular on Netflix', movieSelector: (provider) => provider.movies),
//             ]),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.black,
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Coming Soon'),
//           BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Downloads'),
//         ],
//       ),
//     );
//   }
// }

// class FeaturedContent extends StatelessWidget {
//   const FeaturedContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       alignment: Alignment.center,
//       children: [
//         Image.asset(
//           'assets/featured_movie.jpg',
//           height: 500,
//           width: double.infinity,
//           fit: BoxFit.cover,
//         ),
//         Positioned(
//           bottom: 40,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.play_arrow),
//                 label: const Text('Play'),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
//               ),
//               const SizedBox(width: 20),
//               ElevatedButton.icon(
//                 onPressed: () {},
//                 icon: const Icon(Icons.info_outline),
//                 label: const Text('More Info'),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.7)),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class MovieList extends StatelessWidget {
//   final String title;
//   final List<dynamic> Function(MovieProvider) movieSelector;

//   const MovieList({super.key, required this.title, required this.movieSelector});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             title,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(
//           height: 200,
//           child: Consumer<MovieProvider>(
//             builder: (context, movieProvider, child) {
//               final movies = movieSelector(movieProvider);
//               return ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: movies.length,
//                 itemBuilder: (context, index) {
//                   final movie = movies[index];
//                   return GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => DetailsScreen(movie: movie),
//                         ),
//                       );
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.all(4.0),
//                       child: Image.network(
//                         movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                         width: 130,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Image.asset('assets/placeholder_image.png', width: 130);
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   List<dynamic> searchResults = [];
//   bool isLoading = false;
//   String errorMessage = '';
//   Timer? _debounce;

//   Future<void> searchMovies(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//         isLoading = false;
//         errorMessage = '';
//       });
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
//       if (response.statusCode == 200) {
//         setState(() {
//           searchResults = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to search movies');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'An error occurred. Please try again.';
//       });
//     }
//   }

//   void _onSearchChanged(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       searchMovies(query);
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           style: const TextStyle(color: Colors.white),
//           decoration: const InputDecoration(
//             hintText: 'Search for a movie or TV show',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//           onChanged: _onSearchChanged,
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//               ? Center(child: Text(errorMessage))
//               : GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     childAspectRatio: 2 / 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: searchResults.length,
//                   itemBuilder: (context, index) {
//                     final movie = searchResults[index]['show'];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => DetailsScreen(movie: movie),
//                           ),
//                         );
//                       },
//                       child: Image.network(
//                         movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Image.asset('assets/placeholder_image.png', fit: BoxFit.cover);
//                         },
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }

// class DetailsScreen extends StatelessWidget {
//   final dynamic movie;

//   const DetailsScreen({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 300.0,
//             floating: false,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(movie['name']),
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   Image.network(
//                     movie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Image.asset('assets/placeholder_image.png', fit: BoxFit.cover);
//                     },
//                     ),
//                   const DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [Colors.transparent, Colors.black],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SliverList(
//             delegate: SliverChildListDelegate([
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // Implement play functionality
//                       },
//                       icon: const Icon(Icons.play_arrow),
//                       label: const Text('Play'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: Colors.black,
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       movie['name'],
//                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Text('${movie['rating']?['average'] ?? 'N/A'} Rating'),
//                         const SizedBox(width: 16),
//                         Text(movie['premiered']?.split('-')[0] ?? 'N/A'),
//                         const SizedBox(width: 16),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white),
//                             borderRadius: BorderRadius.circular(3),
//                           ),
//                           child: Text(movie['type'] ?? 'N/A'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _parseHtmlString(movie['summary'] ?? 'No summary available.'),
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                     const SizedBox(height: 16),
//                     Text('Starring: ${movie['_embedded']?['cast']?.map((c) => c['person']['name']).take(3).join(', ') ?? 'N/A'}'),
//                     const SizedBox(height: 8),
//                     Text('Genres: ${movie['genres']?.join(', ') ?? 'N/A'}'),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'More Like This',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       height: 200,
//                       child: Consumer<MovieProvider>(
//                         builder: (context, movieProvider, child) {
//                           final similarMovies = movieProvider.movies
//                               .where((m) => m['genres'].any((g) => movie['genres'].contains(g)))
//                               .take(10)
//                               .toList();
//                           return ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: similarMovies.length,
//                             itemBuilder: (context, index) {
//                               final similarMovie = similarMovies[index];
//                               return GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => DetailsScreen(movie: similarMovie),
//                                     ),
//                                   );
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(right: 8.0),
//                                   child: Image.network(
//                                     similarMovie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                                     width: 130,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Image.asset('assets/placeholder_image.png', width: 130);
//                                     },
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ]),
//           ),
//         ],
//       ),
//     );
//   }

//   String _parseHtmlString(String htmlString) {
//     // This is a simple method to remove HTML tags. For a more robust solution,
//     // consider using a HTML parsing package.
//     return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
//   }
// }

// class PreviewCard extends StatelessWidget {
//   final dynamic movie;

//   const PreviewCard({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailsScreen(movie: movie),
//           ),
//         );
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: NetworkImage(
//               movie['image']?['medium'] ?? 'https://via.placeholder.com/100x100',
//             ),
//           ),
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.red, width: 2),
//             ),
//             child: const CircleAvatar(
//               radius: 52,
//               backgroundColor: Colors.transparent,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PreviewList extends StatelessWidget {
//   const PreviewList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Text(
//             'Previews',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(
//           height: 110,
//           child: Consumer<MovieProvider>(
//             builder: (context, movieProvider, child) {
//               return ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: movieProvider.previews.length,
//                 itemBuilder: (context, index) {
//                   final movie = movieProvider.previews[index];
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: PreviewCard(movie: movie),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }














































// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => MovieProvider()),
//       ],
//       child: const NetflixCloneApp(),
//     ),
//   );
// }

// class NetflixCloneApp extends StatelessWidget {
//   const NetflixCloneApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Netflix Clone',
//       theme: ThemeData.dark().copyWith(
//         primaryColor: Colors.red,
//         scaffoldBackgroundColor: Colors.black,
//         appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
//       ),
//       home: const SplashScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class MovieProvider extends ChangeNotifier {
//   final List<dynamic> _movies = [];
//   final List<dynamic> _trendingMovies = [];
//   final List<dynamic> _topRatedMovies = [];
//   List<dynamic> _previews = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//   int _currentPage = 1;
//   bool _hasMorePages = true;

//   List<dynamic> get movies => _movies;
//   List<dynamic> get trendingMovies => _trendingMovies;
//   List<dynamic> get topRatedMovies => _topRatedMovies;
//   List<dynamic> get previews => _previews;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   Future<void> fetchMovies({bool refresh = false}) async {
//     if (refresh) {
//       _currentPage = 1;
//       _hasMorePages = true;
//       _movies.clear();
//       _trendingMovies.clear();
//       _topRatedMovies.clear();
//     }

//     if (!_hasMorePages) return;

//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedData = prefs.getString('cached_movies_$_currentPage');

//       if (cachedData != null && !refresh) {
//         _movies.addAll(json.decode(cachedData));
//         _currentPage++;
//       } else {
//         final response = await http.get(
//           Uri.parse('https://api.tvmaze.com/shows?page=$_currentPage'),
//         );

//         if (response.statusCode == 200) {
//           final newMovies = json.decode(response.body);
//           if (newMovies.isEmpty) {
//             _hasMorePages = false;
//           } else {
//             _movies.addAll(newMovies);
//             await prefs.setString('cached_movies_$_currentPage', response.body);
//             _currentPage++;
//           }
//           _trendingMovies.addAll(newMovies.take(10));
//           _topRatedMovies.addAll(newMovies.reversed.take(10));
//         } else {
//           throw Exception('Failed to load movies');
//         }
//       }

//       _isLoading = false;
//       notifyListeners();
//     } catch (e) {
//       _isLoading = false;
//       _errorMessage = 'An error occurred. Please try again later.';
//       notifyListeners();
//     }
//   }

//   Future<void> fetchPreviews() async {
//     try {
//       final response = await http.get(Uri.parse('https://api.tvmaze.com/shows'));
//       if (response.statusCode == 200) {
//         _previews = (json.decode(response.body) as List).take(10).toList();
//         notifyListeners();
//       } else {
//         throw Exception('Failed to load previews');
//       }
//     } catch (e) {
//       print('Error fetching previews: $e');
//     }
//   }
// }

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     );
//     _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

//     _controller.forward();

//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const HomeScreen()),
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: FadeTransition(
//           opacity: _animation,
//           child: Image.asset('assets/netflix_logo.png', width: 200),
//         ),
//       ),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final movieProvider = Provider.of<MovieProvider>(context, listen: false);
//       movieProvider.fetchMovies();
//       movieProvider.fetchPreviews();
//     });
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
//       Provider.of<MovieProvider>(context, listen: false).fetchMovies();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         controller: _scrollController,
//         slivers: [
//           SliverAppBar(
//             floating: true,
//             backgroundColor: Colors.transparent,
//             title: Text('Netflix Clone'),
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.cast),
//                 onPressed: () {},
//               ),
//               IconButton(
//                 icon: const Icon(Icons.search),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const SearchScreen()),
//                   );
//                 },
//               ),
//               IconButton(
//                 icon: const Icon(Icons.person),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//           SliverList(
//             delegate: SliverChildListDelegate([
//               const FeaturedContent(),
//               const PreviewList(),
//               MovieList(title: 'Trending Now', movieSelector: (provider) => provider.trendingMovies),
//               MovieList(title: 'Top Rated', movieSelector: (provider) => provider.topRatedMovies),
//               MovieList(title: 'Popular on Netflix', movieSelector: (provider) => provider.movies),
//             ]),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.black,
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Coming Soon'),
//           BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Downloads'),
//         ],
//       ),
//     );
//   }
// }

// class FeaturedContent extends StatelessWidget {
//   const FeaturedContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<MovieProvider>(
//       builder: (context, movieProvider, child) {
//         if (movieProvider.movies.isEmpty) {
//           return const SizedBox(height: 500, child: Center(child: CircularProgressIndicator()));
//         }
//         final featuredMovie = movieProvider.movies.first;
//         return Stack(
//           alignment: Alignment.center,
//           children: [
//             Image.network(
//               featuredMovie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
//               height: 500,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             Positioned(
//               bottom: 40,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   ElevatedButton.icon(
//                     onPressed: () {},
//                     icon: const Icon(Icons.play_arrow),
//                     label: const Text('Play'),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
//                   ),
//                   const SizedBox(width: 20),
//                   ElevatedButton.icon(
//                     onPressed: () {},
//                     icon: const Icon(Icons.info_outline),
//                     label: const Text('More Info'),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.7)),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class MovieList extends StatelessWidget {
//   final String title;
//   final List<dynamic> Function(MovieProvider) movieSelector;

//   const MovieList({super.key, required this.title, required this.movieSelector});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             title,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(
//           height: 200,
//           child: Consumer<MovieProvider>(
//             builder: (context, movieProvider, child) {
//               final movies = movieSelector(movieProvider);
//               return ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: movies.length,
//                 itemBuilder: (context, index) {
//                   final movie = movies[index];
//                   return GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => DetailsScreen(movie: movie),
//                         ),
//                       );
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.all(4.0),
//                       child: Image.network(
//                         movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                         width: 130,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             width: 130,
//                             color: Colors.grey,
//                             child: Center(child: Text(movie['name'])),
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   List<dynamic> searchResults = [];
//   bool isLoading = false;
//   String errorMessage = '';
//   Timer? _debounce;

//   Future<void> searchMovies(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//         isLoading = false;
//         errorMessage = '';
//       });
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
//       if (response.statusCode == 200) {
//         setState(() {
//           searchResults = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to search movies');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'An error occurred. Please try again.';
//       });
//     }
//   }

//   void _onSearchChanged(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       searchMovies(query);
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           style: const TextStyle(color: Colors.white),
//           decoration: const InputDecoration(
//             hintText: 'Search for a movie or TV show',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//           onChanged: _onSearchChanged,
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : errorMessage.isNotEmpty
//               ? Center(child: Text(errorMessage))
//               : GridView.builder(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     childAspectRatio: 2 / 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemCount: searchResults.length,
//                   itemBuilder: (context, index) {
//                     final movie = searchResults[index]['show'];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => DetailsScreen(movie: movie),
//                           ),
//                         );
//                       },
//                       child: Image.network(
//                         movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: Colors.grey,
//                             child: Center(child: Text(movie['name'])),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }
// class DetailsScreen extends StatelessWidget {
//   final dynamic movie;

//   const DetailsScreen({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 300.0,
//             floating: false,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(movie['name']),
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   Image.network(
//                     movie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey,
//                         child: Center(child: Text(movie['name'])),
//                       );
//                     },
//                   ),
//                   const DecoratedBox(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [Colors.transparent, Colors.black],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SliverList(
//             delegate: SliverChildListDelegate([
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // Implement play functionality
//                       },
//                       icon: const Icon(Icons.play_arrow),
//                       label: const Text('Play'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: Colors.black,
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       movie['name'],
//                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Text('${movie['rating']?['average'] ?? 'N/A'} Rating'),
//                         const SizedBox(width: 16),
//                         Text(movie['premiered']?.split('-')[0] ?? 'N/A'),
//                         const SizedBox(width: 16),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.white),
//                             borderRadius: BorderRadius.circular(3),
//                           ),
//                           child: Text(movie['type'] ?? 'N/A'),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _parseHtmlString(movie['summary'] ?? 'No summary available.'),
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                     const SizedBox(height: 16),
//                     Text('Starring: ${movie['_embedded']?['cast']?.map((c) => c['person']['name']).take(3).join(', ') ?? 'N/A'}'),
//                     const SizedBox(height: 8),
//                     Text('Genres: ${(movie['genres'] as List?)?.join(', ') ?? 'N/A'}'),
//                     const SizedBox(height: 24),
//                     const Text(
//                       'More Like This',
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//                     SizedBox(
//                       height: 200,
//                       child: Consumer<MovieProvider>(
//                         builder: (context, movieProvider, child) {
//                           final List<dynamic> movieGenres = movie['genres'] ?? [];
//                           final similarMovies = movieProvider.movies
//                               .where((m) {
//                                 final List<dynamic> genres = m['genres'] ?? [];
//                                 return genres.any((g) => movieGenres.contains(g));
//                               })
//                               .take(10)
//                               .toList();
//                           return ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: similarMovies.length,
//                             itemBuilder: (context, index) {
//                               final similarMovie = similarMovies[index];
//                               return GestureDetector(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => DetailsScreen(movie: similarMovie),
//                                     ),
//                                   );
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(right: 8.0),
//                                   child: Image.network(
//                                     similarMovie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
//                                     width: 130,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Container(
//                                         width: 130,
//                                         color: Colors.grey,
//                                         child: Center(child: Text(similarMovie['name'])),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ]),
//           ),
//         ],
//       ),
//     );
//   }

//   String _parseHtmlString(String htmlString) {
//     // This is a simple method to remove HTML tags. For a more robust solution,
//     // consider using a HTML parsing package.
//     return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
//   }
// }
// // class DetailsScreen extends StatelessWidget {
// //   final dynamic movie;

// //   const DetailsScreen({super.key, required this.movie});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: CustomScrollView(
// //         slivers: [
// //           SliverAppBar(
// //             expandedHeight: 300.0,
// //             floating: false,
// //             pinned: true,
// //             flexibleSpace: FlexibleSpaceBar(
// //           title: Text(movie['name']),
// //               background: Stack(
// //                 fit: StackFit.expand,
// //                 children: [
// //                   Image.network(
// //                     movie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
// //                     fit: BoxFit.cover,
// //                     errorBuilder: (context, error, stackTrace) {
// //                       return Container(
// //                         color: Colors.grey,
// //                         child: Center(child: Text(movie['name'])),
// //                       );
// //                     },
// //                   ),
// //                   const DecoratedBox(
// //                     decoration: BoxDecoration(
// //                       gradient: LinearGradient(
// //                         begin: Alignment.topCenter,
// //                         end: Alignment.bottomCenter,
// //                         colors: [Colors.transparent, Colors.black],
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           SliverList(
// //             delegate: SliverChildListDelegate([
// //               Padding(
// //                 padding: const EdgeInsets.all(16.0),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     ElevatedButton.icon(
// //                       onPressed: () {
// //                         // Implement play functionality
// //                       },
// //                       icon: const Icon(Icons.play_arrow),
// //                       label: const Text('Play'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.white,
// //                         foregroundColor: Colors.black,
// //                         minimumSize: const Size(double.infinity, 50),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     Text(
// //                       movie['name'],
// //                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Row(
// //                       children: [
// //                         Text('${movie['rating']?['average'] ?? 'N/A'} Rating'),
// //                         const SizedBox(width: 16),
// //                         Text(movie['premiered']?.split('-')[0] ?? 'N/A'),
// //                         const SizedBox(width: 16),
// //                         Container(
// //                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                           decoration: BoxDecoration(
// //                             border: Border.all(color: Colors.white),
// //                             borderRadius: BorderRadius.circular(3),
// //                           ),
// //                           child: Text(movie['type'] ?? 'N/A'),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 16),
// //                     Text(
// //                       _parseHtmlString(movie['summary'] ?? 'No summary available.'),
// //                       style: const TextStyle(fontSize: 16),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     Text('Starring: ${movie['_embedded']?['cast']?.map((c) => c['person']['name']).take(3).join(', ') ?? 'N/A'}'),
// //                     const SizedBox(height: 8),
// //                     Text('Genres: ${movie['genres']?.join(', ') ?? 'N/A'}'),
// //                     const SizedBox(height: 24),
// //                     const Text(
// //                       'More Like This',
// //                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
// //                     ),
// //                     const SizedBox(height: 16),
// //                     SizedBox(
// //                       height: 200,
// //                       child: Consumer<MovieProvider>(
// //                         builder: (context, movieProvider, child) {
// //                           final similarMovies = movieProvider.movies
// //                               .where((m) => m['genres'].any((g) => movie['genres'].contains(g)))
// //                               .take(10)
// //                               .toList();
// //                           return ListView.builder(
// //                             scrollDirection: Axis.horizontal,
// //                             itemCount: similarMovies.length,
// //                             itemBuilder: (context, index) {
// //                               final similarMovie = similarMovies[index];
// //                               return GestureDetector(
// //                                 onTap: () {
// //                                   Navigator.push(
// //                                     context,
// //                                     MaterialPageRoute(
// //                                       builder: (context) => DetailsScreen(movie: similarMovie),
// //                                     ),
// //                                   );
// //                                 },
// //                                 child: Padding(
// //                                   padding: const EdgeInsets.only(right: 8.0),
// //                                   child: Image.network(
// //                                     similarMovie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
// //                                     width: 130,
// //                                     fit: BoxFit.cover,
// //                                     errorBuilder: (context, error, stackTrace) {
// //                                       return Container(
// //                                         width: 130,
// //                                         color: Colors.grey,
// //                                         child: Center(child: Text(similarMovie['name'])),
// //                                       );
// //                                     },
// //                                   ),
// //                                 ),
// //                               );
// //                             },
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ]),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   String _parseHtmlString(String htmlString) {
// //     // This is a simple method to remove HTML tags. For a more robust solution,
// //     // consider using a HTML parsing package.
// //     return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
// //   }
// // }

// class PreviewCard extends StatelessWidget {
//   final dynamic movie;

//   const PreviewCard({super.key, required this.movie});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DetailsScreen(movie: movie),
//           ),
//         );
//       },
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           CircleAvatar(
//             radius: 50,
//             backgroundImage: NetworkImage(
//               movie['image']?['medium'] ?? 'https://via.placeholder.com/100x100',
//             ),
//             onBackgroundImageError: (exception, stackTrace) {
//               print('Error loading image: $exception');
//             },
//           ),
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.red, width: 2),
//             ),
//             child: const CircleAvatar(
//               radius: 52,
//               backgroundColor: Colors.transparent,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PreviewList extends StatelessWidget {
//   const PreviewList({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.all(8.0),
//           child: Text(
//             'Previews',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         SizedBox(
//           height: 110,
//           child: Consumer<MovieProvider>(
//             builder: (context, movieProvider, child) {
//               return ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: movieProvider.previews.length,
//                 itemBuilder: (context, index) {
//                   final movie = movieProvider.previews[index];
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: PreviewCard(movie: movie),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }













import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
      ],
      child: const NetflixCloneApp(),
    ),
  );
}

class NetflixCloneApp extends StatelessWidget {
  const NetflixCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflix Clone',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('android/icons8-netflix-48.png', width: 200),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      movieProvider.fetchMovies();
      movieProvider.fetchPreviews();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      Provider.of<MovieProvider>(context, listen: false).fetchMovies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            title: Image.asset('android/icons8-netflix-48.png', width: 100),
            actions: [
              IconButton(
                icon: const Icon(Icons.cast),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {},
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const FeaturedContent(),
              const PreviewList(),
              MovieList(title: 'Trending Now', movieSelector: (provider) => provider.trendingMovies),
              MovieList(title: 'Top Rated', movieSelector: (provider) => provider.topRatedMovies),
              MovieList(title: 'Popular on Netflix', movieSelector: (provider) => provider.movies),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Coming Soon'),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_downward), label: 'Downloads'),
        ],
      ),
    );
  }
}



class MovieProvider extends ChangeNotifier {
  final List<dynamic> _movies = [];
  final List<dynamic> _trendingMovies = [];
  final List<dynamic> _topRatedMovies = [];
  List<dynamic> _previews = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMorePages = true;

  List<dynamic> get movies => _movies;
  List<dynamic> get trendingMovies => _trendingMovies;
  List<dynamic> get topRatedMovies => _topRatedMovies;
  List<dynamic> get previews => _previews;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchMovies({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _movies.clear();
      _trendingMovies.clear();
      _topRatedMovies.clear();
    }

    if (!_hasMorePages) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_movies_$_currentPage');

      if (cachedData != null && !refresh) {
        _movies.addAll(json.decode(cachedData));
        _currentPage++;
      } else {
        final response = await http.get(
          Uri.parse('https://api.tvmaze.com/shows?page=$_currentPage'),
        );

        if (response.statusCode == 200) {
          final newMovies = json.decode(response.body);
          if (newMovies.isEmpty) {
            _hasMorePages = false;
          } else {
            _movies.addAll(newMovies);
            await prefs.setString('cached_movies_$_currentPage', response.body);
            _currentPage++;
          }
          _trendingMovies.addAll(newMovies.take(10));
          _topRatedMovies.addAll(newMovies.reversed.take(10));
        } else {
          throw Exception('Failed to load movies');
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred. Please try again later.';
      notifyListeners();
    }
  }

  Future<void> fetchPreviews() async {
    try {
      final response = await http.get(Uri.parse('https://api.tvmaze.com/shows'));
      if (response.statusCode == 200) {
        _previews = (json.decode(response.body) as List).take(10).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load previews');
      }
    } catch (e) {
      print('Error fetching previews: $e');
    }
  }
}

class FeaturedContent extends StatelessWidget {
  const FeaturedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        if (movieProvider.movies.isEmpty) {
          return const SizedBox(height: 500, child: Center(child: CircularProgressIndicator()));
        }
        final featuredMovie = movieProvider.movies.first;
        return Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              featuredMovie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
              height: 500,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline),
                    label: const Text('More Info'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MovieList extends StatelessWidget {
  final String title;
  final List<dynamic> Function(MovieProvider) movieSelector;

  const MovieList({super.key, required this.title, required this.movieSelector});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
          child: Consumer<MovieProvider>(
            builder: (context, movieProvider, child) {
              final movies = movieSelector(movieProvider);
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(movie: movie),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(
                        movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
                        width: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 130,
                            color: Colors.grey,
                            child: Center(child: Text(movie['name'])),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String errorMessage = '';
  Timer? _debounce;

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isLoading = false;
        errorMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('https://api.tvmaze.com/search/shows?q=$query'));
      if (response.statusCode == 200) {
        setState(() {
          searchResults = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchMovies(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search for a movie or TV show',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final movie = searchResults[index]['show'];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(movie: movie),
                          ),
                        );
                      },
                      child: Image.network(
                        movie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            child: Center(child: Text(movie['name'])),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final dynamic movie;

  const DetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(movie['name']),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    movie['image']?['original'] ?? 'https://via.placeholder.com/500x750',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: Center(child: Text(movie['name'])),
                      );
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement play functionality
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      movie['name'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${movie['rating']?['average'] ?? 'N/A'} Rating'),
                        const SizedBox(width: 16),
                        Text(movie['premiered']?.split('-')[0] ?? 'N/A'),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(movie['type'] ?? 'N/A'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _parseHtmlString(movie['summary'] ?? 'No summary available.'),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text('Starring: ${movie['_embedded']?['cast']?.map((c) => c['person']['name']).take(3).join(', ') ?? 'N/A'}'),
                    const SizedBox(height: 8),
                    Text('Genres: ${(movie['genres'] as List?)?.join(', ') ?? 'N/A'}'),
                    const SizedBox(height: 24),
                    const Text(
                      'More Like This',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: Consumer<MovieProvider>(
                        builder: (context, movieProvider, child) {
                          final List<dynamic> movieGenres = movie['genres'] ?? [];
                          final similarMovies = movieProvider.movies
                              .where((m) {
                                final List<dynamic> genres = m['genres'] ?? [];
                                return genres.any((g) => movieGenres.contains(g));
                              })
                              .take(10)
                              .toList();
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similarMovies.length,
                            itemBuilder: (context, index) {
                              final similarMovie = similarMovies[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailsScreen(movie: similarMovie),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.network(
                                    similarMovie['image']?['medium'] ?? 'https://via.placeholder.com/210x295',
                                    width: 130,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                      width: 130,
                                        color: Colors.grey,
                                        child: Center(child: Text(similarMovie['name'])),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _parseHtmlString(String htmlString) {
   
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class PreviewCard extends StatelessWidget {
  final dynamic movie;

  const PreviewCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(movie: movie),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              movie['image']?['medium'] ?? 'https://via.placeholder.com/100x100',
            ),
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: const CircleAvatar(
              radius: 52,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class PreviewList extends StatelessWidget {
  const PreviewList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Previews',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 110,
          child: Consumer<MovieProvider>(
            builder: (context, movieProvider, child) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movieProvider.previews.length,
                itemBuilder: (context, index) {
                  final movie = movieProvider.previews[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: PreviewCard(movie: movie),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

import 'features/books/presentation/screens/book_detail_screen.dart';
import 'features/books/presentation/screens/book_form_screen.dart';
import 'features/books/presentation/screens/books_list_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading Tracker',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const BooksListScreen(),
        );

      case '/book/add':
        return MaterialPageRoute(
          builder: (_) => const BookFormScreen(),
        );

      case '/book/detail':
        final bookId = settings.arguments as String?;
        if (bookId == null) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: bookId),
        );

      default:
        return _notFoundRoute();
    }
  }

  Route<dynamic> _notFoundRoute() => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Page not found.')),
        ),
      );
}
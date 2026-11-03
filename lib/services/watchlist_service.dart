import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/coin_model.dart';

class WatchlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _watchlistRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('watchlist');
  }

  // Save a coin to the signed-in user's watchlist.
  Future<bool> addCoin(Coin coin) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to save coins.');
    }

    final coinRef = _watchlistRef(user.uid).doc(coin.id);

    // Check whether this coin is already saved.
    final existingCoin = await coinRef.get();

    if (existingCoin.exists) {
      return false; // Already in the watchlist.
    }

    await coinRef.set({
      'id': coin.id,
      'name': coin.name,
      'symbol': coin.symbol,
      'image': coin.image,
      'currentPrice': coin.currentPrice,
      'priceChangePercentage24h': coin.priceChangePercentage24h,
      'marketCap': coin.marketCap,
    });

    return true; // Newly added.
  }

  // Remove a coin from the signed-in user's watchlist.
  Future<void> removeCoin(String coinId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to manage your watchlist.');
    }

    await _watchlistRef(user.uid).doc(coinId).delete();
  }

  // Listen for changes to the signed-in user's saved coins.
  Stream<List<Coin>> getWatchlist() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(<Coin>[]);
    }

    return _watchlistRef(user.uid).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Coin(
          id: data['id'] as String,
          name: data['name'] as String,
          symbol: data['symbol'] as String,
          image: data['image'] as String,
          currentPrice: (data['currentPrice'] as num).toDouble(),
          priceChangePercentage24h: (data['priceChangePercentage24h'] as num)
              .toDouble(),
          marketCap: (data['marketCap'] as num).toDouble(),
        );
      }).toList();
    });
  }
}

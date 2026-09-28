import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class PurchaseService {
  static const String productId = 'single_reading';
  static const String _baseUrl = 'https://cupwhisper-backend-180766156374.europe-west1.run.app';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> buyReadingCredit() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Store not available');
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw Exception('Product not found: ${response.notFoundIDs}');
    }

    final completer = Completer<bool>();

    _subscription = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != productId) continue;

        if (purchase.status == PurchaseStatus.pending) {
          continue;
        }

        if (purchase.status == PurchaseStatus.error ||
            purchase.status == PurchaseStatus.canceled) {
          if (!completer.isCompleted) completer.complete(false);
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          try {
            final verified = await _verifyOnServer(purchase);
            if (verified) {
              final addition = _iap
                  .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
              await addition.consumePurchase(purchase);
              if (!completer.isCompleted) completer.complete(true);
            } else {
              if (!completer.isCompleted) completer.complete(false);
            }
          } catch (_) {
            if (!completer.isCompleted) completer.complete(false);
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    });

    final product = response.productDetails.first;
    await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: false,
    );

    final result = await completer.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () => false,
    );
    await _subscription?.cancel();
    return result;
  }

  Future<bool> _verifyOnServer(PurchaseDetails purchase) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/verify-purchase'),
      headers: {'Authorization': 'Bearer $idToken'},
      body: {
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      },
    );

    return response.statusCode == 200;
  }
}

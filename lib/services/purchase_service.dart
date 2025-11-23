import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'firestore_user.dart';

class PurchaseService {
  static const String premiumProductId = "flortiq_premium";
  static final InAppPurchase _iap = InAppPurchase.instance;

  static Future<ProductDetails?> _loadPremiumProduct() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      print("IAP not supported on this platform");
      return null;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      print("Store not available.");
      return null;
    }

    final response = await _iap.queryProductDetails({premiumProductId});

    if (response.error != null || response.productDetails.isEmpty) {
      print("Product not found: $premiumProductId");
      return null;
    }

    return response.productDetails.first;
  }

  static Future<bool> buyPremium() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      print("IAP not supported on this platform (Windows/Linux).");
      return false;
    }

    final product = await _loadPremiumProduct();
    if (product == null) {
      print("Premium product not found.");
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final completer = Completer<bool>();

    late StreamSubscription<List<PurchaseDetails>> sub;
    sub = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          if (purchase.productID != premiumProductId) continue;

          switch (purchase.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
              }

              await FirestoreUser.upgradeToPremium();

              if (!completer.isCompleted) completer.complete(true);
              break;

            case PurchaseStatus.error:
            case PurchaseStatus.canceled:
              if (!completer.isCompleted) completer.complete(false);
              break;

            default:
              break;
          }
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    final result = await completer.future
        .timeout(const Duration(seconds: 60), onTimeout: () => false);

    await sub.cancel();
    return result;
  }

  static Future<ProductDetails?> getPremiumProduct() async {
    return _loadPremiumProduct();
  }

  static Future<List<ProductDetails>> getProducts() async {
    final p = await getPremiumProduct();
    if (p == null) return [];
    return [p];
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum ProStatus { initial, loading, pro, free, error }

class PurchaseState extends Equatable {
  const PurchaseState({
    this.status = ProStatus.initial,
    this.isPro = false,
    this.productDetails,
    this.errorMessage,
    this.isRestoring = false,
  });

  final ProStatus status;
  final bool isPro;
  final ProductDetails? productDetails;
  final String? errorMessage;
  final bool isRestoring;

  PurchaseState copyWith({
    ProStatus? status,
    bool? isPro,
    ProductDetails? productDetails,
    String? errorMessage,
    bool? isRestoring,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      isPro: isPro ?? this.isPro,
      productDetails: productDetails ?? this.productDetails,
      errorMessage: errorMessage,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }

  @override
  List<Object?> get props =>
      [status, isPro, productDetails, errorMessage, isRestoring];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class PurchaseCubit extends Cubit<PurchaseState> {
  PurchaseCubit() : super(const PurchaseState());

  static const _productId = 'rigsync_pro';
  static const _proKey = 'is_pro_unlocked';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> initialize() async {
    emit(state.copyWith(status: ProStatus.loading));

    // Check locally stored pro status first (offline support)
    final prefs = await SharedPreferences.getInstance();
    final localPro = prefs.getBool(_proKey) ?? false;
    if (localPro) {
      emit(state.copyWith(status: ProStatus.pro, isPro: true));
      return;
    }

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      emit(state.copyWith(status: ProStatus.free, isPro: false));
      return;
    }

    // Listen to purchase updates
    _purchaseSub = InAppPurchase.instance.purchaseStream
        .listen(_onPurchaseUpdate);

    // Load product details
    final response = await InAppPurchase.instance
        .queryProductDetails({_productId});

    if (response.productDetails.isNotEmpty) {
      emit(state.copyWith(
        status: ProStatus.free,
        productDetails: response.productDetails.first,
      ));
    } else {
      emit(state.copyWith(status: ProStatus.free));
    }
  }

  Future<void> buyPro() async {
    if (state.productDetails == null) return;
    final param = PurchaseParam(productDetails: state.productDetails!);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(isRestoring: true));
    await InAppPurchase.instance.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _unlockPro();
        }
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
    emit(state.copyWith(isRestoring: false));
  }

  Future<void> _unlockPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, true);
    emit(state.copyWith(status: ProStatus.pro, isPro: true));
  }

  Future<void> unlockProForTesting() async {
    await _unlockPro();
  }

  Future<void> resetProForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proKey);
    emit(state.copyWith(status: ProStatus.free, isPro: false));
  }

  @override
  Future<void> close() {
    _purchaseSub?.cancel();
    return super.close();
  }
}
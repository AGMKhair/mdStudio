import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/database/database_helper.dart';

class UserSubscriptionState {
  final bool isSubscribed;
  final String planType; // 'none', 'monthly', 'lifetime'
  final bool isTestMode; // Toggles between mock sandbox flows & real StoreKit/Billing library
  final DateTime? expiryDate;
  final User? user; // Firebase user for authentication status

  UserSubscriptionState({
    required this.isSubscribed,
    required this.planType,
    required this.isTestMode,
    this.expiryDate,
    this.user,
  });

  UserSubscriptionState copyWith({
    bool? isSubscribed,
    String? planType,
    bool? isTestMode,
    DateTime? expiryDate,
    User? user,
  }) {
    return UserSubscriptionState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      planType: planType ?? this.planType,
      isTestMode: isTestMode ?? this.isTestMode,
      expiryDate: expiryDate ?? this.expiryDate,
      user: user ?? this.user,
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, UserSubscriptionState>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<UserSubscriptionState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  StreamSubscription<List<PurchaseDetails>>? _iapSubscription;
  StreamSubscription<User?>? _authSubscription;

  // IAP product IDs
  static const String monthlyProductId = 'mdstudio_monthly_sub';
  static const String lifetimeProductId = 'mdstudio_lifetime_sub';

  SubscriptionNotifier()
      : super(UserSubscriptionState(
          isSubscribed: false,
          planType: 'none',
          isTestMode: kDebugMode, // Automatically set based on debug mode
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    // 1. Listen to Auth changes
    _authSubscription = _auth.authStateChanges().listen((user) async {
      state = state.copyWith(user: user);
      if (user != null) {
        // If user is logged in, load/sync subscription
        await _loadLocalSubscription();
        _syncFromFirebase(user.uid);
      } else {
        // If logged out, reset subscription state immediately
        state = state.copyWith(
          isSubscribed: false,
          planType: 'none',
          expiryDate: null,
        );
      }
    });

    // 2. Load persisted subscription state only if a user is currently logged in
    if (_auth.currentUser != null) {
      await _loadLocalSubscription();
    }

    // 3. Setup real billing streams
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _iapSubscription = purchaseUpdated.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );
  }

  Future<void> _loadLocalSubscription() async {
    final db = await DatabaseHelper.instance.database;

    // Load persisted subscription state from DB (most recent active)
    final List<Map<String, dynamic>> maps = await db.query(
      'subscriptions',
      where: 'is_active = 1',
      orderBy: 'purchase_date DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final sub = maps.first;
      final planType = sub['plan_type'];
      final expiryDate = DateTime.parse(sub['expiry_date']);
      
      // Check if expired
      if (expiryDate.isAfter(DateTime.now())) {
        state = state.copyWith(
          isSubscribed: true,
          planType: planType,
          expiryDate: expiryDate,
        );
      } else {
        // Mark as inactive in DB if expired
        await db.update(
          'subscriptions',
          {'is_active': 0},
          where: 'id = ?',
          whereArgs: [sub['id']],
        );
      }
    }
  }

  // Google Login Process
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  // Email/Password Sign Up
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      
      return _auth.currentUser;
    } catch (e) {
      debugPrint('Email Sign-Up Error: $e');
      return null;
    }
  }

  // Email/Password Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Email Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out ignored (likely no GMS): $e');
    }
    
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase Sign-Out Error: $e');
    }

    state = state.copyWith(
      user: null,
      isSubscribed: false,
      planType: 'none',
      expiryDate: null,
    );
  }

  Future<void> _syncFromFirebase(String uid) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final expiryDate = (data['expiry_date'] as Timestamp).toDate();
        final planType = data['plan_type'] as String;
        final isActive = data['is_active'] as bool;

        if (isActive && expiryDate.isAfter(DateTime.now())) {
          if (state.expiryDate == null || expiryDate.isAfter(state.expiryDate!)) {
            state = state.copyWith(
              isSubscribed: true,
              planType: planType,
              expiryDate: expiryDate,
            );
            await _saveSubscriptionToDB(planType, DateTime.now(), expiryDate, skipFirebaseSync: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Firebase sync failed: $e');
    }
  }

  @override
  void dispose() {
    _iapSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  // Purchase Subscription
  Future<bool> purchasePlan(String plan) async {
    // REQUIRE LOGIN BEFORE PURCHASE
    if (state.user == null) {
      final user = await signInWithGoogle();
      if (user == null) return false; // User cancelled or failed login
    }

    final now = DateTime.now();
    final expiry = plan == 'monthly' 
        ? now.add(const Duration(days: 30)) 
        : now.add(const Duration(days: 36500)); // Lifetime ~100 years

    if (state.isTestMode) {
      state = state.copyWith(
        isSubscribed: true, 
        planType: plan,
        expiryDate: expiry,
      );
      
      await _saveSubscriptionToDB(plan, now, expiry);
      return true;
    }

    final bool available = await _iap.isAvailable();
    if (!available) return false;

    final productId = plan == 'monthly' ? monthlyProductId : lifetimeProductId;
    final ProductDetailsResponse response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.contains(productId) || response.productDetails.isEmpty) {
      return false;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _saveSubscriptionToDB(String plan, DateTime purchaseDate, DateTime expiryDate, {bool skipFirebaseSync = false}) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.update('subscriptions', {'is_active': 0}, where: 'is_active = 1');
    
    await db.insert('subscriptions', {
      'plan_type': plan,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'is_active': 1,
    });

    if (!skipFirebaseSync && state.user != null) {
      await _syncSubscriptionToFirebase(plan, purchaseDate, expiryDate);
    }
  }

  Future<void> _syncSubscriptionToFirebase(String plan, DateTime purchaseDate, DateTime expiryDate) async {
    if (state.user == null) return;
    
    try {
      await _firestore.collection('subscriptions').doc(state.user!.uid).set({
        'email': state.user!.email,
        'display_name': state.user!.displayName,
        'plan_type': plan,
        'purchase_date': Timestamp.fromDate(purchaseDate),
        'expiry_date': Timestamp.fromDate(expiryDate),
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing to Firebase: $e');
    }
  }

  Future<void> cancelSubscription() async {
    state = state.copyWith(isSubscribed: false, planType: 'none', expiryDate: null);
    final db = await DatabaseHelper.instance.database;
    await db.update('subscriptions', {'is_active': 0});
    
    if (state.user != null) {
      await _firestore.collection('subscriptions').doc(state.user!.uid).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        final plan = purchase.productID == lifetimeProductId ? 'lifetime' : 'monthly';
        final now = DateTime.now();
        final expiry = plan == 'monthly' 
            ? now.add(const Duration(days: 30)) 
            : now.add(const Duration(days: 36500));

        state = state.copyWith(
          isSubscribed: true, 
          planType: plan,
          expiryDate: expiry,
        );
        
        await _saveSubscriptionToDB(plan, now, expiry);

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase failed: ${purchase.error}');
      }
    }
  }

  Future<bool> restorePurchases() async {
    if (state.isTestMode) {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 30));
      state = state.copyWith(
        isSubscribed: true, 
        planType: 'monthly',
        expiryDate: expiry,
      );
      await _saveSubscriptionToDB('monthly', now, expiry);
      return true;
    }

    try {
      await _iap.restorePurchases();
      return true;
    } catch (_) {
      return false;
    }
  }
}

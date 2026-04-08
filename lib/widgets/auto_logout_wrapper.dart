import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;
  /// The duration of inactivity after which the user is logged out.
  final Duration inactivityDuration;

  const AutoLogoutWrapper({
    super.key,
    required this.child,
    this.inactivityDuration = const Duration(hours: 1),
  });

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> with WidgetsBindingObserver {
  Timer? _authTimer;
  DateTime? _pausedTime;

  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoggedIn = false;
  DateTime _lastInputTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to authentication state changes
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _isLoggedIn = session != null;
      });
      
      if (_isLoggedIn) {
        _resetTimer();
      } else {
        _authTimer?.cancel();
      }
    });

    if (Supabase.instance.client.auth.currentSession != null) {
      _isLoggedIn = true;
      _resetTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    _authTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    if (!_isLoggedIn) {
      _authTimer?.cancel();
      return;
    }

    _authTimer?.cancel();
    _authTimer = Timer(widget.inactivityDuration, () => _logOutUser(isRemoteRevocation: false));
  }

  void _handleUserInteraction(PointerEvent event) {
    if (_isLoggedIn) {
      _resetTimer();
      
      // Perform a lightweight background check if they interact after 30+ seconds of reading
      final now = DateTime.now();
      if (now.difference(_lastInputTime).inSeconds > 30) {
        _lastInputTime = now;
        _checkSessionValidity();
      }
    }
  }

  Future<void> _logOutUser({bool isRemoteRevocation = false}) async {
    if (_isLoggedIn) {
      await Supabase.instance.client.auth.signOut();
      
      // Attempt to show a toast, but this might require a valid context.
      // Since wrapping the app, we can use a simpler approach or rely on router.
      // We will use toastification if available, but wrap in a try-catch to avoid unmounted errors.
      try {
        toastification.show(
          title: Text(isRemoteRevocation ? 'Session Revoked' : 'Session Expired'),
          description: Text(isRemoteRevocation ? 'You have been signed out from another device.' : 'You have been logged out due to inactivity.'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 4),
          alignment: Alignment.topCenter,
        );
      } catch (e) {
        debugPrint('AutoLogout: Failed to show toast - $e');
      }
    }
  }

  Future<void> _checkSessionValidity() async {
    if (!_isLoggedIn) return;
    try {
      // Ping the Supabase backend to ensure our exact session hasn't been revoked externally
      await Supabase.instance.client.auth.getUser();
    } catch (e) {
      if (e is AuthException || e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('AutoLogout: Session revoked remotely. Logging out.');
        await _logOutUser(isRemoteRevocation: true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Do nothing if user is not logged in
    if (Supabase.instance.client.auth.currentSession == null) return;

    if (state == AppLifecycleState.paused) {
      // App is backgrounded, record the time
      _pausedTime = DateTime.now();
      _authTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App is foregrounded, check elapsed time
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        if (elapsed >= widget.inactivityDuration) {
          _logOutUser();
        } else {
          _resetTimer();
          // Secretly verify session is still valid on the server (handles remote logouts like "Log out all other devices")
          _checkSessionValidity();
        }
      }
      _pausedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      onPointerCancel: _handleUserInteraction,
      child: widget.child,
    );
  }
}

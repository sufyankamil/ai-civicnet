import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:civic_net/services/logger_service.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
       _updateConnectionStatus(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      // Force a manual internet check regardless of what hardware reports, 
      // especially useful when the user explicitly taps "Retry"
      bool hasInternet = await _hasActualInternet();
      
      _setConnectionState(hasInternet);
    } catch (e) {
      logger.e("Couldn't check connectivity status", error: e);
    }
  }

  Future<bool> _hasActualInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    bool isConnectedByHardware = results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
    
    if (isConnectedByHardware && !_isConnected) {
       isConnectedByHardware = await _hasActualInternet();
    }
    
    _setConnectionState(isConnectedByHardware);
  }

  void _setConnectionState(bool isConnected) {
    if (mounted) {
      if (isConnected != _isConnected) {
        setState(() {
          _isConnected = isConnected;
        });

        if (!_isConnected) {
          logger.w("Device disconnected from network");
        } else {
          logger.i("Device connected to network");
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: !_isConnected,
          child: widget.child,
        ),
        if (!_isConnected)
          Positioned.fill(
            child: _NoInternetScreen(
              onRetry: _checkInitialConnectivity,
            ),
          ),
      ],
    );
  }
}

class _NoInternetScreen extends StatefulWidget {
  final Future<void> Function() onRetry;

  const _NoInternetScreen({required this.onRetry});

  @override
  State<_NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<_NoInternetScreen> {
  bool _isRetrying = false;

  void _handleRetry() async {
    setState(() => _isRetrying = true);
    // Add artificial delay so user sees feedback even if check is very fast
    await Future.delayed(const Duration(milliseconds: 800));
    await widget.onRetry();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 100,
                color: theme.primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 32),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  inherit: false,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your network settings and try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.grey.shade600,
                  inherit: false,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRetrying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Retry Connection',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

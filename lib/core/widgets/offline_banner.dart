import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, required this.internetStatus});

  final InternetStatus internetStatus;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  InternetStatus _previousStatus = InternetStatus.connected;
  Timer? _onlineTimer;

  @override
  void didUpdateWidget(covariant OfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleStatusChange(widget.internetStatus);
  }

  void _handleStatusChange(InternetStatus status) {
    // Check if we just went online
    bool showOnlineBanner =
        _previousStatus == InternetStatus.disconnected &&
        status == InternetStatus.connected;

    setState(() {
      _previousStatus = status;
    });

    if (showOnlineBanner) {
      // Clear any existing timer
      _onlineTimer?.cancel();

      // Hide the online banner after 1 second
      _onlineTimer = Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _onlineTimer = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner =
        widget.internetStatus == InternetStatus.disconnected ||
        _onlineTimer != null;

    final text = widget.internetStatus == InternetStatus.disconnected
        ? 'Offline mode'
        : 'Online';
    final color = widget.internetStatus == InternetStatus.disconnected
        ? Colors.blue
        : Colors.green;
    final icon = widget.internetStatus == InternetStatus.disconnected
        ? Icons.wifi_off
        : Icons.wifi;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: showBanner ? color : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      curve: Curves.easeInOut,
      child: showBanner
          ? SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

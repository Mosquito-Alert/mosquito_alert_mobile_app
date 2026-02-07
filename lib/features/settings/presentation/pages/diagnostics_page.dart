import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_service.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_manager.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';
import 'package:mosquito_alert_app/features/auth/presentation/state/auth_provider.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';
import 'package:mosquito_alert_app/features/fixes/data/fixes_repository.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';
import 'package:mosquito_alert_app/features/user/presentation/state/user_provider.dart';
import 'package:provider/provider.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  String _baseUrl = '';
  bool _useAuth = false;
  bool _needsGuestAccount = false;
  bool _hasAccessToken = false;
  bool _isAuthenticated = false;
  bool _hasUser = false;
  int _outboxCount = 0;
  int _offlineObservations = 0;
  int _offlineBites = 0;
  int _offlineBreedingSites = 0;
  int _offlineFixes = 0;
  InternetStatus? _internetStatus;
  String? _lastActionMessage;
  String? _dnsResult;
  String? _tcpResult;
  String? _pingResult;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final config = await AppConfig.loadConfig();
    final needsGuest = await AuthRepository.getNeedsGuestAccount();
    final accessToken = await AuthRepository.getAccessToken();

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    final outbox = OutboxService();

    int observations = 0;
    int bites = 0;
    int breedingSites = 0;
    int fixes = 0;

    try {
      observations = Hive.box('offline_observations').length;
    } catch (_) {}
    try {
      bites = Hive.box('offline_bites').length;
    } catch (_) {}
    try {
      breedingSites = Hive.box('offline_breeding_sites').length;
    } catch (_) {}
    try {
      fixes = Hive.box('offline_fixes').length;
    } catch (_) {}

    final internetStatus =
        await InternetConnection.createInstance().internetStatus;

    if (!mounted) return;
    setState(() {
      _baseUrl = config.baseUrl;
      _useAuth = config.useAuth;
      _needsGuestAccount = needsGuest;
      _hasAccessToken = (accessToken != null && accessToken.isNotEmpty);
      _isAuthenticated = authProvider.isAuthenticated;
      _hasUser = userProvider.user != null;
      _outboxCount = outbox.getAll().length;
      _offlineObservations = observations;
      _offlineBites = bites;
      _offlineBreedingSites = breedingSites;
      _offlineFixes = fixes;
      _internetStatus = internetStatus;
    });
  }

  Future<void> _testDns() async {
    try {
      final host = Uri.parse(_baseUrl).host;
      final addresses = await InternetAddress.lookup(host);
      _dnsResult = addresses.map((a) => a.address).join(', ');
    } catch (e) {
      _dnsResult = 'DNS error: $e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _testTcp() async {
    try {
      final host = Uri.parse(_baseUrl).host;
      final socket = await Socket.connect(host, 443,
          timeout: const Duration(seconds: 5));
      socket.destroy();
      _tcpResult = 'TCP 443: OK';
    } catch (e) {
      _tcpResult = 'TCP 443 error: $e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _testPing() async {
    try {
      final uri = Uri.parse(_baseUrl).resolve('ping');
      final client = HttpClient();
      client.findProxy = (_) => 'DIRECT';
      final request = await client.getUrl(uri);
      final response = await request.close();
      _pingResult = 'Ping status: ${response.statusCode}';
      await response.drain();
      client.close();
    } catch (e) {
      _pingResult = 'Ping error: $e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _triggerSync() async {
    try {
      final apiClient = context.read<MosquitoAlert>();

      final observationRepository = ObservationRepository(apiClient: apiClient);
      final biteRepository = BiteRepository(apiClient: apiClient);
      final breedingSiteRepository =
          BreedingSiteRepository(apiClient: apiClient);
      final fixesRepository = FixesRepository(apiClient: apiClient);

      final syncManager = OutboxSyncManager([
        observationRepository,
        biteRepository,
        breedingSiteRepository,
        fixesRepository,
      ]);

      final hasPending = await syncManager.syncAll();
      _lastActionMessage = hasPending
          ? 'Sync attempted: pending items remain.'
          : 'Sync attempted: no pending items.';
    } catch (e) {
      _lastActionMessage = 'Sync error: $e';
    }

    if (mounted) {
      setState(() {});
    }
    await _refresh();
  }

  Future<void> _fetchUser() async {
    try {
      await context.read<UserProvider>().fetchUser();
      _lastActionMessage = 'User fetch attempted.';
    } catch (e) {
      _lastActionMessage = 'User fetch error: $e';
    }

    if (mounted) {
      setState(() {});
    }
    await _refresh();
  }

  Future<void> _createGuest() async {
    try {
      await context.read<AuthProvider>().createGuestAccount();
      await AuthRepository.setNeedsGuestAccount(false);
      _lastActionMessage = 'Guest account creation attempted.';
    } catch (e) {
      _lastActionMessage = 'Guest creation error: $e';
    }

    if (mounted) {
      setState(() {});
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Environment'),
          _kv('Base URL', _baseUrl),
          _kv('Use Auth', _useAuth.toString()),
          _kv('Internet Status', _internetStatus?.name ?? 'unknown'),
          const SizedBox(height: 16),
          _sectionTitle('Auth & User'),
          _kv('Needs Guest Account', _needsGuestAccount.toString()),
          _kv('Has Access Token', _hasAccessToken.toString()),
          _kv('Is Authenticated', _isAuthenticated.toString()),
          _kv('User Loaded', _hasUser.toString()),
          const SizedBox(height: 16),
          _sectionTitle('Outbox'),
          _kv('Outbox Items', _outboxCount.toString()),
          _kv('Offline Observations', _offlineObservations.toString()),
          _kv('Offline Bites', _offlineBites.toString()),
          _kv('Offline Breeding Sites', _offlineBreedingSites.toString()),
          _kv('Offline Fixes', _offlineFixes.toString()),
          const SizedBox(height: 16),
          _sectionTitle('Actions'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Refresh'),
              ),
              ElevatedButton(
                onPressed: _testDns,
                child: const Text('Test DNS'),
              ),
              ElevatedButton(
                onPressed: _testTcp,
                child: const Text('Test TCP 443'),
              ),
              ElevatedButton(
                onPressed: _testPing,
                child: const Text('Test /ping'),
              ),
              ElevatedButton(
                onPressed: _triggerSync,
                child: const Text('Sync Now'),
              ),
              ElevatedButton(
                onPressed: _fetchUser,
                child: const Text('Fetch User'),
              ),
              ElevatedButton(
                onPressed: _createGuest,
                child: const Text('Create Guest'),
              ),
            ],
          ),
          if (_lastActionMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _lastActionMessage!,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          if (_dnsResult != null) ...[
            const SizedBox(height: 12),
            Text('DNS: $_dnsResult',
                style: const TextStyle(color: Colors.black54)),
          ],
          if (_tcpResult != null) ...[
            const SizedBox(height: 8),
            Text('TCP: $_tcpResult',
                style: const TextStyle(color: Colors.black54)),
          ],
          if (_pingResult != null) ...[
            const SizedBox(height: 8),
            Text('Ping: $_pingResult',
                style: const TextStyle(color: Colors.black54)),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            const Text(
              'Diagnostics are visible in debug builds only.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
